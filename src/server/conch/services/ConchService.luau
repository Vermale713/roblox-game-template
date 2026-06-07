--[=[
	ConchService.luau
	Handles the debug menu
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
const UserService = require(ServerScriptService.services.UserService)
const Conch = require(ReplicatedStorage.packages.Conch)
const Loader = require(ReplicatedStorage.utilities.Loader)

-- TYPES
type Command = {
	registerCommand: () -> (),
	registerPermission: () -> (),
}

const ConchService = {}
Loader.register("ConchService", {
	Module = ConchService,
	Dependencies = { "UserService" },
})

function ConchService.onInit()
	Conch.initiate_default_lifecycle()
	UserService.UserAdded:Connect(function(user)
		const player = user.Player
		const conchUser = Conch.get_user(player)
		Conch.give_roles(conchUser, user.Permissions)
	end)
end

function ConchService.onStart()
	const commands: { [string]: Command } = {}

	-- Register commands
	for _, commandModule in ServerScriptService.conch.commands:GetChildren() do
		if not commandModule:IsA("ModuleScript") then
			continue
		end

		commands[commandModule.Name] = (require)(commandModule)
	end

	-- Register command and the permission
	for _, command in commands do
		command.registerCommand()
		command.registerPermission()
	end
end

return ConchService
