--[=[
	DebugController.luau
	Handles the debug menu
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local DebugWindow = require(ReplicatedStorage.client.ui.debug.DebugWindow)
local Iris = require(ReplicatedStorage.packages.Iris)
local Loader = require(ReplicatedStorage.utilities.Loader)

local DebugController = {}
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
