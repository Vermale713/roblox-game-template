-- IMPORTED MODULES
const Charm = require "@game/ReplicatedStorage/Packages/Charm"
const CharmSync = require "@game/ReplicatedStorage/Packages/CharmSync"
const Network = require "@game/ServerScriptService/Network/Server"
const PlayerDataStore = require "@game/ServerScriptService/Store/PlayerDataStore"
const PlayerService = require "@game/ServerScriptService/Shared/Services/PlayerService"

-- PRIVATE STATE
const _playerDataCleanups: { [Player]: () -> () } = {}

-- PRIVATE FUNCTIONS
const function subscribePlayer(player: Player)
	const record = PlayerService.Get(player)
	if not record then
		return
	end

	const computed = Charm.computed(function()
		return PlayerDataStore.Get(player.UserId)
	end)
	-- Have to type as any because ProfileStore types are wack
	const dataChanged = Charm.subscribe(computed, function(data: any)
		record.Profile.Data = data
	end)

	_playerDataCleanups[player] = dataChanged

	-- project only the public fields into the synced store; the profile's
	-- server-only Metadata must never cross to clients (the synced map broadcasts
	-- to every player). Extend this as public fields are added to PlayerData.
	PlayerDataStore.Load(player.UserId, record.Profile.Data)
	CharmSync.server.addSignalsToClient(player, { playerData = PlayerDataStore.Getter })
end

const function unsubscribePlayer(player: Player)
	const cleanup = _playerDataCleanups[player]
	if cleanup then
		cleanup()
	end
	CharmSync.server.removeClient(player)
	PlayerDataStore.Unload(player.UserId)
end

-- PUBLIC MODULE
const DataReplicationService = {}

DataReplicationService.Dependencies = { "PlayerService" }

function DataReplicationService.OnInit()
	-- the blink `Data.Sync` event carries one SyncPayload at a time, so fan the
	-- charm-sync batch out into individual fires (see src/Network.blink)
	CharmSync.server.connect(function(player, payloads)
		for _, payload in payloads do
			Network.Data.Sync.Fire(player, payload)
		end
	end)

	-- players whose data already loaded before this service initialised
	for _, record in PlayerService.GetAll() do
		subscribePlayer(record.Player)
	end

	PlayerService.PlayerAdded:Connect(subscribePlayer)
	PlayerService.PlayerRemoving:Connect(unsubscribePlayer)
end

return DataReplicationService
