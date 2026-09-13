--!strict
-- IMPORTED MODULES
const Sync = require "@lib/Sync"
const Server = require "@network/Server"
const Scythe = require "@pkg/Scythe"
const DataService = require "@server/Data/DataService"
const PlayerService = require "@server/Player/PlayerService"
const DataTemplate = require "@templates/DataTemplate"

-- TYPES
type ScytheScope = Scythe.Scope
type PlayerData = DataTemplate.PlayerData
type Channel<T> = Sync.Sync<T>

-- PRIVATE STATE
const _channels: { [Player]: Channel<PlayerData> } = {}
const _playerCleaners: { [Player]: ScytheScope } = {}

-- PRIVATE FUNCTIONS
const function setupReplication(player: Player)
    const session = DataService.GetSession(player)
    if not session then return end

    const data = session.Get()

    const channel = Sync.new(data)
    _channels[player] = channel

    const scope = Scythe.scope()
    _playerCleaners[player] = scope

    const snapshot = channel:Snapshot()
    if not snapshot then return end

    Server.Replication.SyncData.Fire(player, snapshot)
end

const function cleanupReplication(player: Player)
    const channel = _channels[player]
    if not channel then return end
    channel:Destroy()
    _channels[player] = nil

    const scope = _playerCleaners[player]
    if not scope then return end
    Scythe.destroy(scope)
end

-- PUBLIC MODULE
const DataReplicationService = {}

DataReplicationService.Dependencies = { "PlayerService", "DataService" }

function DataReplicationService.OnInit()
    DataService.DataChanged:Connect(function(player, newData)
        const channel = _channels[player]
        if not channel then return end

        const buf = channel:Push(newData)
        if not buf then return end

        Server.Replication.SyncData.Fire(player, buf)
    end)
    PlayerService.PlayerJoined:Connect(setupReplication)
    PlayerService.PlayerRemoving:Connect(cleanupReplication)
end

return DataReplicationService
