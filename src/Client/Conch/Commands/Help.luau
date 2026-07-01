-- IMPORTED MODULES
const Conch = require "@game/ReplicatedStorage/Packages/Conch"

-- TYPES
-- minimal view of the internal language type carried on each command; only the
-- fields needed to render a usage string are described here
type CommandArgument = {
	name: string,
	varargs: boolean?,
}
type CommandType = {
	kind: string,
	name: string?,
	arguments: { CommandArgument }?,
	fields: { CommandType }?,
}

-- PRIVATE FUNCTIONS
-- renders `name <arg> <...rest>` for a single (non-overloaded) command type
const function usageForType(name: string, commandType: CommandType): string
	const parts = { name }
	for _, argument in commandType.arguments or {} do
		const token = if argument.varargs then `...{argument.name}` else argument.name
		table.insert(parts, `<{token}>`)
	end
	return table.concat(parts, " ")
end

-- one usage line per command; an overloaded command yields a line per overload
const function usagesForCommand(name: string, commandType: CommandType): { string }
	if commandType.kind == "intersection" and commandType.fields then
		const usages = {}
		for _, overload in commandType.fields do
			table.insert(usages, usageForType(name, overload))
		end
		return usages
	end
	return { usageForType(name, commandType) }
end

-- PUBLIC MODULE
-- registers `help`; lists every command the local player is allowed to run with
-- its usage. The client command registry is already filtered to the user's
-- permission level, so iterating it needs no extra permission check.
return function()
	Conch.register("help", {
		permissions = {},
		description = "Lists the commands you can run and how to use them.",
		arguments = function() end,
		callback = function()
			const commands = Conch.console.commands

			const names = {}
			for name in commands do
				table.insert(names, name)
			end
			table.sort(names)

			Conch.log("info", `Available commands ({#names}):`)
			for _, name in names do
				const representation = commands[name]
				const commandType = representation.type :: any
				const description = representation.description or "No description."
				for _, usage in usagesForCommand(name, commandType) do
					Conch.log("normal", `  {usage}  -  {description}`)
				end
			end
		end,
	})
end
