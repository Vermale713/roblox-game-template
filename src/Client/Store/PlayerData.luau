-- SERVICES
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Charm = require(ReplicatedStorage.Packages.Charm)
const PlayerDataTemplate = require(ReplicatedStorage.Data.Templates.PlayerData)

-- TYPES
type PlayerData = PlayerDataTemplate.PlayerData
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
	return _getData()[tostring(Players.LocalPlayer.UserId)]
end

return PlayerDataStore
