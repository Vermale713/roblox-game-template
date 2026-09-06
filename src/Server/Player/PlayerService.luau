-- SERVICES
const LogService = game:GetService "LogService"
const Players = game:GetService "Players"

-- IMPORTED MODULES
const Signal = require "@pkg/Signal"
const DataService = require "@server/Data/DataService"
const TableTypes = require "@types/TableTypes"

-- TYPES
type Signal<T> = Signal.Signal<T>
type Set<T> = TableTypes.Set<T>
type ReadonlySet<T> = TableTypes.ReadonlySet<T>

-- PRIVATE STATE
const _playersInSession: Set<Player> = {}
const _playerJoined: Signal<Player> = Signal.new()
const _playerRemoving: Signal<Player> = Signal.new()
const _sessionStarted: Signal<Player> = Signal.new()
const _sessionEnded: Signal<Player> = Signal.new()

-- PRIVATE FUNCTIONS
const function startSessionForPlayer(player: Player)
    -- errorable
    const success, result = DataService.Load(player)

    if not success then
        LogService:Info("[PlayerService] Data load failed. {reason}", { reason = result })
        player:Kick "Failed to load data please rejoin."
        return
    end

    _playersInSession[player] = true
    _sessionStarted:Fire(player)
end

const function endSessionForPlayer(player: Player)
    _sessionEnded:Fire(player)

    -- unerrorable
    DataService.Unload(player)

    _playersInSession[player] = nil
end

const function onPlayerJoined(player: Player)
    if _playersInSession[player] then
        LogService:Info("[PlayerService] Player '{player} has been accounted for twice.'", { player = player.Name })
        return
    end

    startSessionForPlayer(player)

    _playerJoined:Fire(player)
end

const function onPlayerRemoving(player: Player)
    if not _playersInSession[player] then
        LogService:Info(
            "[PlayerService] Player '{player} left before even being registered.'",
            { player = player.Name }
        )
        return
    end

    endSessionForPlayer(player)

    _playerRemoving:Fire(player)
end

-- PUBLIC MODULE
const PlayerService = {}

PlayerService.Dependencies = { "DataService" }

PlayerService.PlayerJoined = _playerJoined
PlayerService.PlayerRemoving = _playerRemoving
PlayerService.SessionStarted = _sessionStarted
PlayerService.SessionEnded = _sessionEnded

function PlayerService.GetPlayers(): ReadonlySet<Player> return table.clone(_playersInSession) end

function PlayerService.StartSession(player: Player)
    if _playersInSession[player] then endSessionForPlayer(player) end

    startSessionForPlayer(player)
end

function PlayerService.OnInit()
    Players.PlayerAdded:Connect(onPlayerJoined)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    for _, player in Players:GetPlayers() do
        -- i think its ok to spawn the task?
        task.spawn(onPlayerJoined, player)
    end
end

return PlayerService
