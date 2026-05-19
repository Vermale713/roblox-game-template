--[=[
	CharacterService.luau
	Handles creating the character and related data
]=]

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
local Character = require(ServerScriptService.services.CharacterService.classes.Character)
local GlobalTypes = require(ReplicatedStorage.types.GlobalTypes)
local UserService = require(ServerScriptService.services.UserService)
local Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES
type R15Character = GlobalTypes.R15Character
type User = UserService.User

export type Character = Character.Character

-- PRIVATE STATE
local _spawnerConnections: { [Player]: RBXScriptConnection } = {}
local _characters: { [Player]: Character } = {}

-- PRIVATE FUNCTIONS
local function onUserAdded(user: User)
	local player = user.Player

	if _spawnerConnections[player] then
		-- Shouldn't happen but somehow double called
		return
	end

	local connection = player.CharacterAdded:Connect(function(model)
		local character = Character.new(model :: GlobalTypes.R15Character)

		_characters[player] = character

		character.Humanoid.Died:Once(function()
			_characters[player] = nil
			task.wait(Players.RespawnTime)

			player:LoadCharacterAsync()
		end)
	end)

	_spawnerConnections[player] = connection

	player:LoadCharacterAsync()
end

local function onUserRemoving(user: User)
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
