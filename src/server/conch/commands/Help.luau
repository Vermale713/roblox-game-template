-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Conch = require(ReplicatedStorage.packages.Conch)

-- PRIVATE FUNCTIONS
const function getLongest(key: "name" | "description", commands: any): number
	local longest = 0
	for _, command in commands do
		if #command[key] > longest then
			longest = #command[key]
		end
	end
	return longest
end

const function appendSpaces(text: string, lineWidth: number): string
	return `{text}{string.rep(" ", lineWidth - #text)}`
end

-- PUBLIC MODULE
const Command = {}

function Command.registerCommand()
	Conch.register("help", {
		description = "Displays commands that the executor has access to",
		permissions = { "help" },
		arguments = function() end,
		callback = function(...)
			-- Have to cast as because conch types are not correct
			const context = Conch.get_command_context() :: any
			const console = Conch.console :: any

			if not context then
				return
			end

			const commands: { { name: string, description: string, permissions: string } } = {}

			for _, command in console.commands do
				if not Conch.has_permissions(context.executor, table.unpack(command.permissions)) then
					continue
				end

				const args: { string } = {}

				for _, arg in command.type.arguments do
					const prefix = if arg.kind == "varargs" then "..." else ""
					const suffix = if arg.optional then "?" else ""

					table.insert(args, `{prefix}{arg.type.type}{suffix}`)
				end

				const permissions = table.concat(command.permissions, ", ")
				const name = if #args > 0 then `{command.name}: -{table.concat(args, " -")}` else command.name

				table.insert(commands, {
					name = name :: string,
					description = command.description :: string,
					permissions = permissions :: string,
				})
			end

			const lineNameWidth = getLongest("name", commands)
			const lineDescriptionWidth = getLongest("description", commands)

			table.sort(commands, function(a, b)
				return (a.name :: string) < (b.name :: string)
			end)

			const headerName = appendSpaces("Name", lineNameWidth)
			const headerDescription = appendSpaces("Description", lineDescriptionWidth)
			const headerPermissions = "Permissions"

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
