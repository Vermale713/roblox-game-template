-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Conch = require(ReplicatedStorage.packages.Conch)

-- PUBLIC MODULE
const Command = {}

function Command.registerCommand()
	Conch.register("permission", {
		description = "Check a player's permission level",
		permissions = { "permission-check" },
		arguments = function()
			return Conch.args.player("Player", "The player to check args for")
		end,
		callback = function(player: Player)
			const user = Conch.get_user(player)
			Conch.log("info", user.roles[1])
		end,
	})
end

function Command.registerPermission()
	Conch.set_role_permissions("guest", "permission-check")
end

return Command
