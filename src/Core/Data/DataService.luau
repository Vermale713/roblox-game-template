--!strict
-- SERVICES
const Players = game:GetService "Players"

-- IMPORTED MODULES
const TableTypes = require "@base/TableTypes"
const DataTemplate = require "@game/ReplicatedStorage/Shared/Core/Data/DataTemplate".Server

-- TYPES
type Set<T> = TableTypes.Set<T>
type Dictionary<T, K> = TableTypes.Dictionary<T, K>

-- PRIVATE STATE
const _playerState: Set<Player> = {}
const _activeSessions: Dictionary<Player, any> = {} -- TODO: add session type

-- PRIVATE FUNCTIONS
const function onPlayerJoined(player: Player)
    if _playerState[player] then return end
    _playerState[player] = true

    local data, reason = DataTemplate.WaitForData(player)
    if not data and reason == "still-loading" then data = DataTemplate.WaitForData(player, 60) end
end

const function onPlayerRemoving(player: Player)
    _playerState[player] = nil
    _activeSessions[player] = nil
end

-- PUBLIC MODULE
const DataService = {}

function DataService.OnInit()
    Players.PlayerAdded:Connect(onPlayerJoined)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
end

function DataService.OnStart()
    for _, player in Players:GetPlayers() do
        task.spawn(onPlayerJoined, player)
    end
end

return DataService
