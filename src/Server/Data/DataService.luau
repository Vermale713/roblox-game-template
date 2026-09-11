--!strict
-- SERVICES
const LogService = game:GetService "LogService"
const Players = game:GetService "Players"

-- IMPORTED MODULES
const Signal = require "@pkg/Signal"
const ProfileStoreProvider = require "@storage/DataProviders/ProfileStoreProvider"
const DataTemplate = require "@templates/DataTemplate"
const DataTypes = require "@types/DataTypes"
const TableTypes = require "@types/TableTypes"

-- TYPES
type Set<T> = TableTypes.Set<T>
type Signal<T...> = Signal.Signal<T...>
type DataProviderInterface<T> = DataTypes.DataProviderInterface<T>
type DataProviderModuleInterface = DataTypes.DataProviderModuleInterface
type LoadStatus = DataTypes.LoadStatus
type PlayerData = DataTemplate.PlayerData
type DataProviderModule = DataProviderModuleInterface
type Session = DataTypes.Session<PlayerData>
type DataProvider = DataProviderInterface<PlayerData>

-- CONSTANTS
const DATA_TEMPLATE: PlayerData = DataTemplate.PlayerData
const DATASTORE_KEY = "Example"

-- PRIVATE STATE
const _dataProviderModule: DataProviderModule = ProfileStoreProvider
local _dataProvider: DataProvider
const _loadedPlayers: { [Player]: Session } = {}
const _pendingPlayers: Set<Player> = {}
const _dataChanged: Signal<Player, PlayerData> = Signal.new()

-- PRIVATE FUNCTIONS
const function onSessionEnded(player: Player, session: Session)
    if _loadedPlayers[player] ~= session then return end

    _loadedPlayers[player] = nil

    LogService:Warn(
        "[DataService] Session ended for Player '{player}' while they were still in game.",
        { player = player }
    )

    if player:IsDescendantOf(Players) then player:Kick "Your data session ended, please rejoin." end
end

-- PUBLIC MODULE
const DataService = {}

DataService.DataChanged = _dataChanged

function DataService.OnInit() _dataProvider = _dataProviderModule.CreateStore(DATASTORE_KEY, DATA_TEMPLATE) end

function DataService.GetSession(player: Player): Session? return _loadedPlayers[player] end

function DataService.Update(player: Player, updater: (PlayerData) -> ())
    const session = _loadedPlayers[player]
    if not session then return end

    if not session.IsActive() then
        LogService:Warn(
            "[DataService] Dropped an update for Player '{player}'; their data session is no longer active.",
            { player = player }
        )
        return
    end

    session.Update(updater)

    _dataChanged:Fire(player, session.Get())
end

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

    const session, err = _dataProvider.Load(`{player.UserId}`, player.UserId)

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

    session.OnEnd(function() onSessionEnded(player, session) end)

    return "Ok"
end

function DataService.Unload(player: Player)
    const session = _loadedPlayers[player]
    if not session then return end

    _loadedPlayers[player] = nil

    session.Unload()
end

return DataService
