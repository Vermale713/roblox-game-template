--!strict
-- IMPORTED MODULES
const Sync = require "@lib/Sync"
const Client = require "@network/Client"
const DataTemplate = require "@templates/DataTemplate"

-- TYPES
type PlayerData = DataTemplate.PlayerData

-- PRIVATE STATE
const _channel: Sync.Sync<PlayerData> = Sync.new(DataTemplate.PlayerData)

-- PRIVATE FUNCTIONS
const function onDataReplicated(buf: buffer)
    _channel:Apply(buf)
    print(_channel:Get())
end

-- PUBLIC MODULE
const DataReplicationController = {}

function DataReplicationController.OnInit() Client.Replication.SyncData.On(onDataReplicated) end

return DataReplicationController
