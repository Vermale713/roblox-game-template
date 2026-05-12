--!nonstrict
-- we have to make this nonstrict otherwise
-- ConchUi provides a type error
--[=[
	ConchController.luau
	Handles the debug menu
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Conch = require(ReplicatedStorage.packages.Conch)
local ConchUi = require(ReplicatedStorage.packages.ConchUi)
local Loader = require(ReplicatedStorage.utilities.Loader)

-- TYPES
type Command = {
	registerCommand: () -> (),
	registerPermission: () -> (),
}

local ConchController = {}
Loader.register("ConchController", {
	Module = ConchController,
	Dependencies = {},
})

function ConchController.onInit()
	Conch.initiate_default_lifecycle()
	ConchUi.bind_to(Enum.KeyCode.F4)
end

function ConchController.onStart()
	local commands: { [string]: Command } = {}

	-- Register commands
	for _, commandModule in ReplicatedStorage.client.conch.commands:GetChildren() do
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

return ConchController
