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

local ConchService = {}
Loader.register("ConchService", {
	Module = ConchService,
	Dependencies = { "UserService" },
})

function ConchService.onInit()
	Conch.initiate_default_lifecycle()
	UserService.UserAdded:Connect(function(user)
		local player = user.Player
		local conchUser = Conch.get_user(player)
		Conch.give_roles(conchUser, user.Permissions)
	end)
end

function ConchService.onStart()
	local commands: { [string]: Command } = {}

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
