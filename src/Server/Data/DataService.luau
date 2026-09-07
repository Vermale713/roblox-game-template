--!strict
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
type LoadStatus = DataTypes.LoadStatus
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

function DataService.Load(player: Player): LoadStatus
    if _loadedPlayers[player] then
        LogService:Warn("[DataService] Player '{player}' has already loaded their data.", { player = player })
        return "Already-Loaded"
    end
    if _pendingPlayers[player] then
        LogService:Warn("[DataService] Player '{player}' is already pending to be loaded.", { player = player })
        return "Pending"
    end
    _pendingPlayers[player] = true

    const ok, session, err = pcall(_dataProvider.Load, `{player.UserId}`, player.UserId)

    if not ok then
        LogService:Warn(
            "[DataService] Provider errored for Player '{player}'. '{err}'",
            { err = session, player = player }
        )
        _pendingPlayers[player] = nil
        return "Failed"
    end

    if not session then
        LogService:Warn(
            "[DataService] Data failed to retrieve for Player '{player}'. '{err}'",
            { err = err, player = player }
        )
        _pendingPlayers[player] = nil
        return "Failed"
    end

    if not player:IsDescendantOf(Players) then
        session.Unload()
        LogService:Warn("[DataService] Player '{player}' left while loading data.", { player = player })
        _pendingPlayers[player] = nil
        return "Left"
    end

    _loadedPlayers[player] = session
    _pendingPlayers[player] = nil

    return "Ok"
end

function DataService.Unload(player: Player)
    if not _loadedPlayers[player] then return end

    _loadedPlayers[player].Unload()
    _loadedPlayers[player] = nil
end

return DataService
