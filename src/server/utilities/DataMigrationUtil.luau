--[=[
	DataMigrationUtil.luau
	Handles data migration in the event that data deletion/reconciling does not work
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const PlayerData = require(ReplicatedStorage.data.templates.PlayerData)

-- CONSTANTS
const LATEST_VERSION = PlayerData.Metadata.Version

-- PRIVATE STATE
const _migrations: { (data: PlayerData.PlayerData) -> () } = {}

-- PUBLIC MODULE
const DataMigrationUtil = {}

function DataMigrationUtil.migrate(data: PlayerData.PlayerData)
	const version = data.Metadata.Version
	while version < LATEST_VERSION do
		const migration = _migrations[version]
		if migration then
			migration(data)
		end
		data.Metadata.Version += 1
	end
end

return DataMigrationUtil
