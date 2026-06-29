-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Conch = require(ReplicatedStorage.Packages.Conch)

-- CONSTANTS
-- Conch's built-in role that bypasses every permission check
const SUPER_USER_ROLE = "super-user"

-- PUBLIC MODULE
-- registers `permissions`; reports the local player's permission level — their
-- roles and how many commands those roles let them run
return function()
	Conch.register("permissions", {
		permissions = {},
		description = "Shows your permission level: your roles and what you can run.",
		arguments = function() end,
		callback = function()
			const context = Conch.get_command_context()
			if not context then
				Conch.log("error", "Could not determine who is running this command.")
				return
			end

			const roles = context.executor.roles
			if #roles == 0 then
				Conch.log("info", "You have no roles.")
			else
				Conch.log("info", `Your roles: {table.concat(roles, ", ")}`)
			end

			local available = 0
			for _ in Conch.console.commands do
				available += 1
			end

			if table.find(roles, SUPER_USER_ROLE) then
				Conch.log("normal", "You are a super-user — you can run every command.")
			end
			Conch.log("normal", `You can run {available} command(s); type 'help' to list them.`)
		end,
	})
end
