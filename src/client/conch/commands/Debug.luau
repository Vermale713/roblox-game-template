-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const DebugStore = require(ReplicatedStorage.client.store.DebugStore)
const Conch = require(ReplicatedStorage.packages.Conch)
const Iris = require(ReplicatedStorage.packages.Iris)

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
