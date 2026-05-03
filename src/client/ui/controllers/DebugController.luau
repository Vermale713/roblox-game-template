--[=[
	DebugController.luau
	Handles the debug menu
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Iris = require(ReplicatedStorage.packages.Iris)

local DebugController = {}

function DebugController.onInit()
	Iris.Init(nil, nil, false)
end

function DebugController.onStart()
	-- Iris:Connect()
end

return DebugController
