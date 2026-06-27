-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const ServerScriptService = game:GetService "ServerScriptService"

-- IMPORTED MODULES
const Signal = require(ReplicatedStorage.Packages.Signal)
const PlayerService = require(ServerScriptService.Shared.Services.PlayerService)

-- TYPES
export type CharacterRecord = {
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
}

type HumanoidModifiers = {
	WalkSpeed: number?,
	JumpHeight: number?,
	MaxHealth: number?,
	Health: number?,
	AutoRotate: boolean?,
}

-- CONSTANTS
const RESPAWN_DELAY = 5

-- PRIVATE STATE
const _records: { [Player]: CharacterRecord } = {}
const _characterAdded = Signal.new()
const _characterRemoving = Signal.new()

-- PRIVATE FUNCTIONS
const function spawnCharacter(player: Player)
	-- LoadCharacter throws if the player has already left; that case is benign
	pcall(function()
		player:LoadCharacter()
	end)
end

const function onCharacterAdded(player: Player, character: Model)
	const humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	const humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

	if not humanoid or not humanoidRootPart or not character:IsDescendantOf(workspace) then
		return
	end

	_records[player] = {
		Player = player,
		Character = character,
		Humanoid = humanoid,
		HumanoidRootPart = humanoidRootPart :: BasePart,
	}

	humanoid.Died:Connect(function()
		task.delay(RESPAWN_DELAY, spawnCharacter, player)
	end)

	_characterAdded:Fire(player)
end

const function onCharacterRemoving(player: Player)
	if not _records[player] then
		return
	end

	_characterRemoving:Fire(player)
	_records[player] = nil
end

const function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacterAdded, player, character)
	end)

	player.CharacterRemoving:Connect(function(_character)
		onCharacterRemoving(player)
	end)

	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	else
		task.spawn(spawnCharacter, player)
	end
end

-- PUBLIC MODULE
const CharacterService = {}

CharacterService.Dependencies = { "PlayerService" }

CharacterService.CharacterAdded = _characterAdded
CharacterService.CharacterRemoving = _characterRemoving

function CharacterService:OnInit()
	-- character tracking only begins once PlayerService confirms data is loaded;
	-- a player whose data failed to load is kicked and never reaches here
	for _, record in PlayerService.GetAll() do
		setupPlayer(record.Player)
	end

	PlayerService.PlayerAdded:Connect(setupPlayer)
	PlayerService.PlayerRemoving:Connect(onCharacterRemoving)
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

function CharacterService.IsAlive(player: Player): boolean
	const record = _records[player]
	if not record then
		return false
	end
	return record.Humanoid.Health > 0
end

function CharacterService.Modify(player: Player, modifiers: HumanoidModifiers)
	const record = _records[player]
	if not record then
		return
	end

	const humanoid = record.Humanoid

	if modifiers.WalkSpeed ~= nil then
		humanoid.WalkSpeed = modifiers.WalkSpeed
	end
	if modifiers.JumpHeight ~= nil then
		humanoid.JumpHeight = modifiers.JumpHeight
	end
	if modifiers.MaxHealth ~= nil then
		humanoid.MaxHealth = modifiers.MaxHealth
	end
	if modifiers.Health ~= nil then
		humanoid.Health = modifiers.Health
	end
	if modifiers.AutoRotate ~= nil then
		humanoid.AutoRotate = modifiers.AutoRotate
	end
end

return CharacterService
