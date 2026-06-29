-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Conch = require(ReplicatedStorage.Packages.Conch)
const ConchUi = require(ReplicatedStorage.Packages.ConchUi)
const ConchRegistrar = require(ReplicatedStorage.Utilities.ConchRegistrar)

-- CONSTANTS
const TOGGLE_KEY = Enum.KeyCode.F4

-- PUBLIC MODULE
const ConchController = {}

function ConchController:OnInit()
	Conch.initiate_default_lifecycle()
	Conch.register_default_commands()
	ConchRegistrar.RegisterFolder(ReplicatedStorage.Client.Conch.Commands)
end

function ConchController:OnStart()
	ConchUi.mount()
	ConchUi.bind_to(TOGGLE_KEY)
end

return ConchController
