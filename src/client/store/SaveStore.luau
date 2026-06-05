--[=[
	SaveStore.luau
	This is where the data will live all reads are from
	to user data will be from here
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
const Charm = require(ReplicatedStorage.packages.Charm)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE
local _getSave, _setSave = Charm.signal(PlayerData :: PlayerData.PlayerData)

-- PRIVATE FUNCTIONS

-- MODULES
local SaveStore = {}

SaveStore.GetSave = _getSave
SaveStore.SetSave = _setSave

return SaveStore
