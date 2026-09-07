-- SERVICES
const LogService = game:GetService "LogService"
const Players = game:GetService "Players"

-- IMPORTED MODULES
const ProfileStoreProvider = require "@storage/DataProviders/ProfileStoreProvider"
const DataTypes = require "@types/DataTypes"
const TableTypes = require "@types/TableTypes"

-- TYPES
type Set<T> = TableTypes.Set<T>
type DataProviderInterface<T> = DataTypes.DataProviderInterface<T>
type DataProviderModuleInterface = DataTypes.DataProviderModuleInterface
type PlayerData = {} -- replace with real data
type DataProviderModule = DataProviderModuleInterface
type Session = DataTypes.Session<PlayerData>
type DataProvider = DataProviderInterface<PlayerData>

-- CONSTANTS
const DATA_TEMPLATE: PlayerData = {}
const DATASTORE_KEY = "Example"

-- PRIVATE STATE
const _dataProviderModule: DataProviderModule = ProfileStoreProvider
local _dataProvider: DataProvider
const _loadedPlayers: { [Player]: Session } = {}
const _pendingPlayers: Set<Player> = {}

-- PUBLIC MODULE
const DataService = {}

function DataService.OnInit() _dataProvider = _dataProviderModule.CreateStore(DATASTORE_KEY, DATA_TEMPLATE) end

function DataService.Load(player: Player)
    if _loadedPlayers[player] then
        LogService:Warn("[DataService] Player '{player}' has already loaded their data.", { player = player })
        return
    end
    if _pendingPlayers[player] then
        LogService:Warn("[DataService] Player '{player}' is already pending to be loaded.", { player = player })
        return
    end
    _pendingPlayers[player] = true

    const session, err = _dataProvider.Load(`{player.UserId}`, player.UserId)

    if not session then
        LogService:Warn("[DataService] Data failed to retrieve. '{err}'", { err = err })
        _pendingPlayers[player] = nil
        return
    end

    if not player:IsDescendantOf(Players) then
        session.Unload()
        LogService:Warn "[DataService] Player '{player}' left while loading data."
        _pendingPlayers[player] = nil
        return
    end

    _loadedPlayers[player] = session
    _pendingPlayers[player] = nil
end

function DataService.Unload(player: Player)
    if not _loadedPlayers[player] then return end

    _loadedPlayers[player].Unload()
    _loadedPlayers[player] = nil
end

return DataService
