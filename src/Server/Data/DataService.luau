-- SERVICES
const Players = game:GetService "Players"

-- IMPORTED MODULES
const ProfileStoreProvider = require "@storage/DataProviders/ProfileStoreProvider"
const DataTypes = require "@types/DataTypes"

-- TYPES
type DataProviderInterface<T> = DataTypes.DataProviderInterface<T>
type DataProviderModuleInterface<T> = DataTypes.DataProviderModuleInterface<T>
type PlayerData = {} -- replace with real data
type DataProviderModule = DataProviderModuleInterface<PlayerData>
type DataProvider = DataProviderInterface<PlayerData>

-- CONSTANTS
const DATASTORE_KEY = "Example"

-- PRIVATE STATE
const _dataProviderModule: DataProviderModule = ProfileStoreProvider :: DataProviderModule
local _dataProvider: DataProvider
const _loadedPlayers = {}

-- PUBLIC MODULE
const DataService = {}

function DataService.OnInit() _dataProvider = _dataProviderModule.CreateStore(DATASTORE_KEY) end

function DataService.Load(player: Player): (boolean, string)
    if _loadedPlayers[player] then return false, "Player data already loaded." end

    const success, result = _dataProvider.Load(`{player.UserId}`, player.User.Id)

    if not success then return false, "" end

    if not player:IsDescendantOf(Players) then return false, "Player left." end

    _loadedPlayers[player] = result

    return true, ""
end

function DataService.Unload(player: Player)
    if not _loadedPlayers[player] then return end

    _dataProvider.Unload(_loadedPlayers[player])

    _loadedPlayers[player] = nil
end

return DataService
