-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Conch = require(ReplicatedStorage.packages.Conch)

-- PRIVATE FUNCTIONS
local function getLongest(key: "name" | "description", commands: any): number
	local longest = 0
	for _, command in commands do
		if #command[key] > longest then
			longest = #command[key]
		end
	end
	return longest
end

local function appendSpaces(text: string, lineWidth: number): string
	return `{text}{string.rep(" ", lineWidth - #text)}`
end

local Command = {}

function Command.registerCommand()
	Conch.register("help", {
		description = "Displays commands that the executor has access to",
		permissions = { "help" },
		arguments = function() end,
		callback = function(...)
			-- Have to cast as because conch types are not correct
			local context = Conch.get_command_context() :: any
			local console = Conch.console :: any

			if not context then
				return
			end

			local commands: { { name: string, description: string, permissions: string } } = {}

			for _, command in console.commands do
				if not Conch.has_permissions(context.executor, table.unpack(command.permissions)) then
					continue
				end

				local args: { string } = {}

				for _, arg in command.type.arguments do
					local prefix = if arg.kind == "varargs" then "..." else ""
					local suffix = if arg.optional then "?" else ""

					table.insert(args, `{prefix}{arg.type.type}{suffix}`)
				end

				local permissions = table.concat(command.permissions, ", ")
				local name = if #args > 0 then `{command.name}: -{table.concat(args, " -")}` else command.name

				table.insert(commands, {
					name = name :: string,
					description = command.description :: string,
					permissions = permissions :: string,
				})
			end

			local lineNameWidth = getLongest("name", commands)
			local lineDescriptionWidth = getLongest("description", commands)

			table.sort(commands, function(a, b)
				return (a.name :: string) < (b.name :: string)
			end)

			local headerName = appendSpaces("Name", lineNameWidth)
			local headerDescription = appendSpaces("Description", lineDescriptionWidth)
			local headerPermissions = "Permissions"

			Conch.log("info", `{headerName}   {headerDescription}   {headerPermissions}`)

			for _, command in commands do
				command.name = appendSpaces(command.name, lineNameWidth)
				command.description = appendSpaces(command.description, lineDescriptionWidth)

				Conch.log("normal", `{command.name} | {command.description} | {command.permissions}`)
			end

			table.clear(commands)
		end,
	})
end

function Command.registerPermission()
	Conch.set_role_permissions("guest", "help")
end

return Command
