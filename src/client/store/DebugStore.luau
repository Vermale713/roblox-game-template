--[=[
	DebugStore.luau
	This is where the data will live all reads are from
	to user data will be from here
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Iris = require(ReplicatedStorage.packages.Iris)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE
local screenSize = workspace.CurrentCamera.ViewportSize
local isOpened = Iris.State(false)
local position = Iris.State(screenSize / 2)

-- PRIVATE FUNCTIONS

-- MODULES
local DebugStore = {}

DebugStore.IsOpened = isOpened
DebugStore.Position = position

return DebugStore
