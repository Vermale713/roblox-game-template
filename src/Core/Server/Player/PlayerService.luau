--!strict
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

-- PRIVATE FUNCTIONS
const function startSessionForPlayer(player: Player)
    const status = DataService.Load(player)

    if status ~= "Ok" then
        if status == "Failed" then
            player:Kick "Failed to load data please rejoin."
            LogService:Info(
                "[PlayerService] Player '{player}' failed to load and was kicked.",
                {
                    player = player,
                }
            )
        end
        return false
    end

    _playersInSession[player] = true

    return true
end

const function endSessionForPlayer(player: Player)
    DataService.Unload(player)

    _playersInSession[player] = nil
end

const function onPlayerJoined(player: Player)
    if _playersInSession[player] then
        LogService:Info("[PlayerService] Player '{player} has been accounted for twice.'", { player = player.Name })
        return
    end

    const success = startSessionForPlayer(player)
    if not success then return end

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

    _playerRemoving:Fire(player)

    endSessionForPlayer(player)
end

-- PUBLIC MODULE
const PlayerService = {}

PlayerService.Dependencies = { "DataService" }

PlayerService.PlayerJoined = _playerJoined
PlayerService.PlayerRemoving = _playerRemoving

function PlayerService.GetPlayers(): ReadonlySet<Player> return table.clone(_playersInSession) end

function PlayerService.OnInit()
    Players.PlayerAdded:Connect(onPlayerJoined)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
end

function PlayerService.OnStart()
    for _, player in Players:GetPlayers() do
        -- i think its ok to spawn the task?
        task.spawn(onPlayerJoined, player)
    end
end

return PlayerService
