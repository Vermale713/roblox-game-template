--[=[
	DataMigrationUtil.luau
	Handles data migration in the event that data deletion/reconciling does not work
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local PlayerData = require(ReplicatedStorage.data.templates.PlayerData)

-- PRIVATE STATE
local _migrations: { (data: PlayerData.PlayerData) -> () } = {
	-- Example Migration
	-- [1] = function(data)
	-- modify some data
	-- data.Metadata.Version += 1
	-- end,
}

local DataMigrationUtil = {}

function DataMigrationUtil.migrate(data: PlayerData.PlayerData)
	local version = data.Metadata.Version
	local migration = _migrations[version]
	if migration then
		migration(data)
	end
end

return DataMigrationUtil
