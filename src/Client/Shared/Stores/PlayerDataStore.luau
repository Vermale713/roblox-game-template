-- SERVICES
const Players = game:GetService "Players"

-- IMPORTED MODULES
const Charm = require "@game/ReplicatedStorage/Packages/Charm"
const DataTemplate = require "@game/ReplicatedStorage/Data/Templates/DataTemplate"

-- TYPES
type PlayerData = DataTemplate.PlayerData
-- keyed by tostring(userId) to match the server store across the sync boundary
type PlayerDataMap = { [string]: PlayerData }

-- PRIVATE STATE
-- replica of the server signal; CharmSync.client writes incoming patches via the setter
const _getData, _setData = Charm.signal({} :: PlayerDataMap)

-- PUBLIC MODULE
const PlayerDataStore = {}

-- the setter is exposed so the replication controller can register it with CharmSync
PlayerDataStore.Setter = _setData

function PlayerDataStore.GetAll(): PlayerDataMap
	return _getData()
end

function PlayerDataStore.GetLocal(): PlayerData?
	return _getData()[tostring(Players.LocalPlayer.UserId)] or DataTemplate
end

return PlayerDataStore
