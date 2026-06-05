--[=[
	SaveStore.luau
	This is where the data will live all reads/write
	to user data will be from here
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
const Charm = require(ReplicatedStorage.packages.Charm)
const TableUtil = require(ReplicatedStorage.utilities.TableUtil)

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
		return TableUtil.Dictionary.set(saves, username, save)
	end)
end

function SaveStore.RemoveSave(username: string): ()
	_setSaves(function(saves: Saves)
		return TableUtil.Dictionary.delete(saves, username)
	end)
end

return SaveStore
