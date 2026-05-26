--[=[
	SaveStore.luau
	This is where the data will live all reads/write
	to user data will be from here
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
local Charm = require(ReplicatedStorage.packages.Charm)
local Sift = require(ReplicatedStorage.packages.Sift)

-- CONSTANTS

-- TYPES
type Saves = {
	[string]: PlayerData.PlayerData,
}

-- PRIVATE STATE
local _getSaves, _setSaves = Charm.signal({} :: Saves)

-- PRIVATE FUNCTIONS

-- MODULES
local SaveStore = {}

SaveStore.GetSaves = _getSaves
SaveStore.SetSaves = _setSaves

function SaveStore.GetSave(username: string)
	return _getSaves()[username]
end

function SaveStore.SetSaveData(username: string, save: PlayerData.PlayerData): ()
	_setSaves(function(saves: Saves)
		return Sift.Dictionary.set(saves, username, save)
	end)
end

function SaveStore.RemoveSave(username: string): ()
	_setSaves(function(saves: Saves)
		return Sift.Dictionary.removeKey(saves, username)
	end)
end

return SaveStore
