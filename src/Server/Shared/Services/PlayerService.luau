-- SERVICES
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const PlayerData = require "@game/ReplicatedStorage/Data/Templates/PlayerData"
const Signal = require "@game/ReplicatedStorage/Packages/Signal"
const Promise = require "@game/ReplicatedStorage/Packages/Promise"
const ProfileStore = require "@game/ServerScriptService/ServerPackages/ProfileStore"

-- TYPES
type PlayerData = PlayerData.PlayerData
type ProfileStoreModule = ProfileStore.ProfileStoreModule
type Store = ProfileStore.ProfileStore<PlayerData>
type Profile = ProfileStore.Profile<PlayerData>

export type PlayerRecord = {
	Player: Player,
	-- os.clock() when this session started; lets GetPlaytime include the live session
	SessionStart: number,
	Profile: Profile,
}

-- CONSTANTS
const KEY_PREFIX = if RunService:IsStudio() then "Test_" else ""

-- PRIVATE STATE
const _records: { [Player]: PlayerRecord } = {}
const _playerAdded = Signal.new()
const _playerRemoving = Signal.new()
const _store = ProfileStore.New(KEY_PREFIX .. "PlayerData", PlayerData :: never) :: Store

-- PRIVATE FUNCTIONS
const function loadProfile(player: Player)
	return Promise.new(function(resolve, reject)
		const profile = _store:StartSessionAsync(tostring(player.UserId), {
			Cancel = function()
				return not player:IsDescendantOf(Players)
			end,
		})

		if profile == nil then
			reject(`Profile returned nil for {player.Name}`)
			return
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()
		resolve(profile)
	end)
end

const function initialiseMetadata(profile: Profile)
	const data = profile.Data
	const now = os.time()

	-- JoinedAt is written once, on the first ever session
	if data.JoinedAt == 0 then
		data.JoinedAt = now
	end
	data.LastOnlineAt = now
	data.SessionCount += 1
end

const function onPlayerAdded(player: Player)
	if _records[player] then
		LogService:Warn("[PlayerService] Record already exists for {name}, skipping", {
			name = player.Name,
		})
		return
	end

	loadProfile(player)
		:andThen(function(profile: Profile)
			if not player:IsDescendantOf(Players) then
				profile:EndSession()
				return
			end

			initialiseMetadata(profile)

			const sessionStart = os.clock()

			-- bank this session's playtime into the profile right before its final
			-- save, however the session ends (leave, shutdown, or another server
			-- taking ownership). OnSessionEnd is cleanup-only and must not edit Data;
			-- OnLastSave is the documented hook for last-moment edits. The closure
			-- captures `profile`/`sessionStart` so it is independent of the records
			-- map, which onPlayerRemoving may clear before this async save runs.
			profile.OnLastSave:Connect(function()
				-- we do not use the TableUtil to edit data here
				-- because ProfileStore has wack types and will give
				-- type errors
				const clone = table.clone(profile.Data)

				clone.Playtime += math.floor(os.clock() - sessionStart)
				clone.LastOnlineAt = os.time()

				profile.Data = clone
			end)

			_records[player] = {
				Player = player,
				Profile = profile,
				SessionStart = sessionStart,
			}

			_playerAdded:Fire(player)
		end)
		:catch(function(err)
			LogService:Error("[PlayerService] Failed to load data for {name}: {error}", {
				name = player.Name,
				error = tostring(err),
			})
			player:Kick "Failed to load your data. Please rejoin."
		end)
end

const function onPlayerRemoving(player: Player)
	if not _records[player] then
		LogService:Warn("[PlayerService] No record found for {name} on PlayerRemoving", {
			name = player.Name,
		})
		return
	end

	_playerRemoving:Fire(player)

	-- EndSession triggers the final save, whose OnLastSave handler banks this
	-- session's playtime and updates LastOnlineAt (connected in onPlayerAdded)
	_records[player].Profile:EndSession()

	_records[player] = nil
end

-- PUBLIC MODULE
const PlayerService = {}

PlayerService.PlayerAdded = _playerAdded
PlayerService.PlayerRemoving = _playerRemoving

function PlayerService.OnInit()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

function PlayerService.Get(player: Player): PlayerRecord?
	return _records[player]
end

function PlayerService.GetAll(): { PlayerRecord }
	const records: { PlayerRecord } = {}
	for _, record in _records do
		table.insert(records, record)
	end
	return records
end

-- total seconds played including the current session
function PlayerService.GetPlaytime(player: Player): number?
	const record = _records[player]
	if not record then
		return nil
	end

	const liveSeconds = math.floor(os.clock() - record.SessionStart)
	return record.Profile.Data.Playtime + liveSeconds
end

function PlayerService.AddRobuxSpent(player: Player, amount: number)
	const record = _records[player]
	if not record then
		return
	end

	record.Profile.Data.RobuxSpent += amount
end

return PlayerService
