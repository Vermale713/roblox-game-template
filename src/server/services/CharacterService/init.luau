--[=[
	CharacterService.luau
	Handles creating the character and related data
]=]

-- SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
const Signal = require(ReplicatedStorage.packages.Signal)
const Character = require(ServerScriptService.services.CharacterService.classes.Character)
const GlobalTypes = require(ReplicatedStorage.types.GlobalTypes)
const UserService = require(ServerScriptService.services.UserService)
const Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES
type R15Character = GlobalTypes.R15Character
type User = UserService.User

export type Character = Character.Character

-- PRIVATE STATE
local _characterAdded = Signal.new() :: Signal.Signal<Character>
local _characterRemoving = Signal.new() :: Signal.Signal<Character>
local _spawnerConnections: { [Player]: RBXScriptConnection } = {}
local _characters: { [Player]: Character } = {}

-- PRIVATE FUNCTIONS
const function onUserAdded(user: User)
	local player = user.Player

	if _spawnerConnections[player] then
		-- Shouldn't happen but somehow double called
		return
	end

	local connection = player.CharacterAdded:Connect(function(model)
		local character = Character.new(model :: GlobalTypes.R15Character)

		_characterAdded:Fire(character)

		_characters[player] = character

		character.Humanoid.Died:Once(function()
			_characterRemoving:Fire(character)
			_characters[player] = nil
			task.wait(Players.RespawnTime)

			player:LoadCharacterAsync()
		end)
	end)

	_spawnerConnections[player] = connection

	player:LoadCharacterAsync()
end

const function onUserRemoving(user: User)
	local player = user.Player

	local connection = _spawnerConnections[player]
	if connection then
		connection:Disconnect()
	end
	_spawnerConnections[player] = nil
	_characters[player] = nil
end

-- PUBLIC MODULE
local CharacterService = {}
Loader.register("CharacterService", {
	Module = CharacterService,
	Dependencies = { "UserService" },
})

CharacterService.Characters = _characters
CharacterService.CharacterAdded = _characterAdded
CharacterService.CharacterRemoving = _characterRemoving

function CharacterService.onInit()
	UserService.UserAdded:Connect(onUserAdded)
	UserService.UserRemoving:Connect(onUserRemoving)
end

function CharacterService.onStart()
	-- idk how this would actually fare
	for _, user in UserService.Users do
		onUserAdded(user)
	end
end

return CharacterService
