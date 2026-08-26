-- SERVICES
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Scythe = require "@game/ReplicatedStorage/Packages/Scythe"
const Signal = require "@game/ReplicatedStorage/Packages/Signal"
const Vow = require "@game/ReplicatedStorage/Packages/Vow"
const TableUtil = require "@game/ReplicatedStorage/Utilities/TableUtil"
const CombatService = require "@game/ServerScriptService/Shared/Services/CombatService"
const PlayerService = require "@game/ServerScriptService/Shared/Services/PlayerService"
const PlayerDataStore = require "@game/ServerScriptService/Shared/Stores/PlayerDataStore"

-- TYPES
type Scope = Scythe.Scope
type ActiveStatusEffect = CombatService.ActiveStatusEffect
type StatusEffects = CombatService.StatusEffects

export type CharacterRecord = {
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
}

-- CONSTANTS
const RESPAWN_DELAY = 5

-- PRIVATE STATE
const _characterFolder = Instance.new "Folder"
const _cleanupScopes: { [Player]: Scope } = {}
const _records: { [Player]: CharacterRecord } = {}
const _characterAdded: Signal.Signal<CharacterRecord> = Signal.new()
const _characterDied: Signal.Signal<CharacterRecord> = Signal.new()
const _characterRemoving: Signal.Signal<CharacterRecord> = Signal.new()

-- PRIVATE FUNCTIONS
-- forward declared: onCharacterAdded schedules a respawn through this, and it
-- calls back into onCharacterAdded once the character exists
local spawnCharacterAsync: (player: Player) -> ()

-- LoadCharacterAsync throws if the player has already left; that case is benign.
-- It also yields, and Vow runs its executor on the calling thread, so callers must
-- invoke this from a thread that is safe to block — use spawnCharacterAsync.
const function spawnCharacter(player: Player): Vow.Vow
	return Vow.new(function(id)
		const success, res = pcall(function()
			player:LoadCharacterAsync()
		end)

		if not success then
			Vow.reject(id, res)
			return
		end

		const character = player.Character

		if not character then
			Vow.reject(id, "No character was found associated with the player")
			return
		end

		Vow.resolve(id, character)
	end)
end

const function onCharacterAdded(player: Player, character: Model)
	if _records[player] then
		-- already handled foo
		return
	end

	const data = PlayerDataStore.Get(player.UserId)
	if not data then
		LogService:Warn("[CharacterService] {player}'s data does not exist", { player = player, character = character })
		return
	end

	character.Parent = _characterFolder

	const humanoid = character:FindFirstChild "Humanoid" :: Humanoid?
	const humanoidRootPart = character:FindFirstChild "HumanoidRootPart"

	if not humanoid or not humanoidRootPart or not character:IsDescendantOf(workspace) then
		LogService:Warn("[CharacterService] (Humanoid or HumanoidRootPart) not found or (Character: {character}) is not a descendant of workspace", {
			player = player,
			character = character,
		})
		return
	end

	_records[player] = {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		HumanoidRootPart = humanoidRootPart :: BasePart,
	}

	CombatService.Register(
		character,
		{
			-- TODO
			-- sync with player data
			MaxHealth = 100,
			WalkSpeed = 16,
			StatusEffects = data.StatusEffects :: CombatService.StatusEffects,
		}
	)

	const scope = _cleanupScopes[player]

	const updatedStatuses = {}
	for statusId, status in data.StatusEffects :: StatusEffects do
		const currentTime = os.time()

		local durationLeft: number

		if status.LastActiveSession == 0 then
			durationLeft = status.EndTime - status.StartTime
		else
			durationLeft = status.EndTime - status.LastActiveSession
		end

		if durationLeft <= 0 then
			continue
		end

		const newEndTime = currentTime + durationLeft
		updatedStatuses[statusId] = {
			StartTime = currentTime,
			EndTime = newEndTime,
			LastActiveSession = 0,
			Metadata = status.Metadata,
		} :: ActiveStatusEffect

		CombatService.ReapplyStatusEffect(character, statusId, durationLeft)
	end

	PlayerDataStore.Update(player.UserId, function(currentData)
		return TableUtil.Set(currentData, "StatusEffects", updatedStatuses)
	end)

	local diedConn: RBXScriptConnection
	diedConn = humanoid.Died:Once(function()
		_characterDied:Fire(_records[player])

		Scythe.remove(scope, diedConn)
		CombatService.Unregister(character)

		task.delay(RESPAWN_DELAY, spawnCharacterAsync, player)
	end)

	Scythe.add(scope, diedConn)

	_characterAdded:Fire(_records[player])
end

-- spawns on its own thread, then awaits and destroys the Vow so no handle leaks
spawnCharacterAsync = function(player: Player)
	task.spawn(function()
		const vow = spawnCharacter(player)
		const spawned, result = Vow.await(vow)
		Vow.destroy(vow)

		if not spawned then
			LogService:Warn("[CharacterService] Failed to spawn character: {error}", { error = tostring(result) })
			return
		end

		onCharacterAdded(player, result :: Model)
	end)
end

const function onCharacterRemoving(player: Player)
	const record = _records[player]

	PlayerDataStore.Update(player.UserId, function(data)
		const newStatusEffects = {}
		const now = os.time()

		for id, status in data.StatusEffects :: StatusEffects do
			const newStatus = TableUtil.Set(status, "LastActiveSession", now)
			newStatusEffects[id] = newStatus
		end

		return TableUtil.Set(data, "StatusEffects", newStatusEffects)
	end)

	if not record then
		return
	end

	_characterRemoving:Fire(record)
	_records[player] = nil
end

const function setupPlayer(player: Player)
	const scope = Scythe.scope()

	_cleanupScopes[player] = scope

	const addedConn = player.CharacterAdded:Connect(function(character)
		LogService:Info "[CharacterService] Handling CharacterAdded"
		onCharacterAdded(player, character)
	end)

	const removeConn = player.CharacterRemoving:Connect(function()
		LogService:Info "[CharacterService] Handling CharacterRemoving"
		onCharacterRemoving(player)
	end)

	Scythe.add(scope, addedConn)
	Scythe.add(scope, removeConn)

	if player.Character then
		LogService:Info "[CharacterService] Handling preexisting character"
		onCharacterAdded(player, player.Character)
	else
		spawnCharacterAsync(player)
	end
end

const function cleanupPlayer(player: Player)
	const scope = _cleanupScopes[player]
	if not scope then
		return
	end
	Scythe.destroy(scope)
	_cleanupScopes[player] = nil
end

-- PUBLIC MODULE
const CharacterService = {}

CharacterService.Dependencies = { "PlayerService", "CombatService" }

CharacterService.CharacterAdded = _characterAdded
CharacterService.CharacterRemoving = _characterRemoving
CharacterService.CharacterDied = _characterDied

function CharacterService.OnInit()
	_characterFolder.Name = "PlayerCharacters"
	_characterFolder.Parent = workspace
	-- character tracking only begins once PlayerService confirms data is loaded;
	-- a player whose data failed to load is kicked and never reaches here
	for _, record in PlayerService.GetAll() do
		setupPlayer(record.Player)
	end

	PlayerService.PlayerAdded:Connect(setupPlayer)
	PlayerService.PlayerRemoving:Connect(cleanupPlayer)
end

function CharacterService.Get(player: Player): CharacterRecord?
	return _records[player]
end

function CharacterService.GetAll(): { CharacterRecord }
	const records: { CharacterRecord } = {}
	for _, record in _records do
		table.insert(records, record)
	end
	return records
end

return CharacterService
