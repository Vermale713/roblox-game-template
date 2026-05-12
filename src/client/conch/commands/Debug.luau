-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local DebugStore = require(ReplicatedStorage.client.store.DebugStore)
local Conch = require(ReplicatedStorage.packages.Conch)
local Iris = require(ReplicatedStorage.packages.Iris)

local Command = {}

function Command.registerCommand()
	Conch.register("debug", {
		description = "Enable the debug menu",
		permissions = { "use-debug" },
		arguments = function()
			return
		end,
		callback = function()
			Iris.Disabled = false
			DebugStore.IsOpened:set(true)
		end,
	})
end

function Command.registerPermission()
	Conch.set_role_permissions("guest", "use-debug")
end

return Command
