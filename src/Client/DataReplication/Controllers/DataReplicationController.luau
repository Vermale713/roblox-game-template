-- IMPORTED MODULES
const CharmSync = require "@game/ReplicatedStorage/Packages/CharmSync"
const Network = require "@game/ReplicatedStorage/Client/Network/Client"
const PlayerDataStore = require "@game/ReplicatedStorage/Client/Store/PlayerData"

-- PUBLIC MODULE
const DataReplicationController = {}

function DataReplicationController.OnInit()
	-- register the replica atom before any payload can arrive
	CharmSync.client.addSignals { playerData = PlayerDataStore.Setter }
end

function DataReplicationController.OnStart()
	-- blink buffers incoming events until a listener attaches, so payloads sent
	-- before this point are not lost; patch expects a list, so wrap the single
	-- payload this event delivers
	Network.Data.Sync.On(function(payload)
		CharmSync.client.patch { payload }
	end)
end

return DataReplicationController
