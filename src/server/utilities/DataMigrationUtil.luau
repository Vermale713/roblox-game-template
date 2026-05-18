--[=[
	DataMigrationUtil.luau
	Handles data migration in the event that data deletion/reconciling does not work
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local PlayerData = require(ReplicatedStorage.data.templates.PlayerData)

-- CONSTANTS
local LATEST_VERSION = PlayerData.Metadata.Version

-- PRIVATE STATE
local _migrations: { (data: PlayerData.PlayerData) -> () } = {}

local DataMigrationUtil = {}

function DataMigrationUtil.migrate(data: PlayerData.PlayerData)
	local version = data.Metadata.Version
	while version < LATEST_VERSION do
		local migration = _migrations[version]
		if migration then
			migration(data)
		end
		data.Metadata.Version += 1
	end
end

return DataMigrationUtil
