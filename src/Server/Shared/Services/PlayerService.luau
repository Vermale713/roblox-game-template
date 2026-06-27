-- SERVICES
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const ServerScriptService = game:GetService "ServerScriptService"
const RunService = game:GetService "RunService"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Signal = require(ReplicatedStorage.Packages.Signal)
const Promise = require(ReplicatedStorage.Packages.Promise)
const ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
const PlayerDataTemplate = require(ReplicatedStorage.Data.Templates.PlayerData)

-- TYPES
type PlayerData = PlayerDataTemplate.PlayerData
type ProfileStoreModule = ProfileStore.ProfileStoreModule
type Store = ProfileStore.ProfileStore<PlayerData>
type Profile = ProfileStore.Profile<PlayerData>

export type PlayerRecord = {
	Player: Player,
	Data: PlayerData,
}

-- CONSTANTS
const KEY_PREFIX = if RunService:IsStudio() then "Test_" else ""

-- PRIVATE STATE
const _records: { [Player]: PlayerRecord } = {}
const _profiles: { [Player]: Profile } = {}
const _playerAdded = Signal.new()
const _playerRemoving = Signal.new()
const _store = ProfileStore.New(KEY_PREFIX .. "PlayerData", PlayerDataTemplate :: never) :: Store

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

			_profiles[player] = profile
			_records[player] = {
				Player = player,
				Data = profile.Data,
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

	if _profiles[player] then
		_profiles[player]:EndSession()
		_profiles[player] = nil
	end

	_records[player] = nil
end

-- PUBLIC MODULE
const PlayerService = {}

PlayerService.PlayerAdded = _playerAdded
PlayerService.PlayerRemoving = _playerRemoving

function PlayerService:OnInit()
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

return PlayerService
