--[=[
	DebugController.luau
	Handles the debug menu
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const DebugWindow = require(ReplicatedStorage.client.ui.debug.DebugWindow)
const Iris = require(ReplicatedStorage.packages.Iris)
const Loader = require(ReplicatedStorage.utilities.Loader)

const DebugController = {}
Loader.register("DebugController", {
	Module = DebugController,
	Dependencies = {},
})

function DebugController.onInit()
	Iris.Init(nil, nil, false)
end

function DebugController.onStart()
	Iris:Connect(DebugWindow)
end

return DebugController
