-- IMPORTED MODULES
const Signal = require "@game/ReplicatedStorage/Packages/Signal"
const CombatService = require "@game/ServerScriptService/Shared/Services/CombatService"
const PlayerService = require "@game/ServerScriptService/Shared/Services/PlayerService"
const PlayerDataStore = require "@game/ServerScriptService/Shared/Stores/PlayerDataStore"

-- TYPES
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
const _records: { [Player]: CharacterRecord } = {}
const _characterAdded: Signal.Signal<CharacterRecord> = Signal.new()
const _characterDied: Signal.Signal<CharacterRecord> = Signal.new()
const _characterRemoving: Signal.Signal<CharacterRecord> = Signal.new()

-- PRIVATE FUNCTIONS
const function spawnCharacter(player: Player)
	-- LoadCharacter throws if the player has already left; that case is benign
	pcall(function()
		player:LoadCharacterAsync()
	end)
end

const function onCharacterAdded(player: Player, character: Model)
	const data = PlayerDataStore.Get(player.UserId)
	if not data then
		return
	end

	character.Parent = _characterFolder

	const humanoid = character:FindFirstChild "Humanoid" :: Humanoid?
	const humanoidRootPart = character:FindFirstChild "HumanoidRootPart"

	if not humanoid or not humanoidRootPart or not character:IsDescendantOf(workspace) then
		return
	end

	_records[player] = {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		HumanoidRootPart = humanoidRootPart :: BasePart,
	}

	CombatService.Register(character, {
		-- TODO
		-- sync with player data
		MaxHealth = 100,
		WalkSpeed = 16,
		StatusEffects = data.StatusEffects :: CombatService.StatusEffects,
	})

	humanoid.Died:Once(function()
		_characterDied:Fire(_records[player])
		task.delay(RESPAWN_DELAY, spawnCharacter, player)
	end)

	_characterAdded:Fire(_records[player])
end

const function onCharacterRemoving(player: Player)
	const record = _records[player]

	if not record then
		return
	end

	_characterRemoving:Fire(record)
	_records[player] = nil
end

const function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacterAdded, player, character)
	end)

	player.CharacterRemoving:Connect(function(character)
		onCharacterRemoving(player, character)
	end)

	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	else
		task.spawn(spawnCharacter, player)
	end
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
