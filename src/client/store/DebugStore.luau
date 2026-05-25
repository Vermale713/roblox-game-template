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
local _screenSize = workspace.CurrentCamera.ViewportSize
local _isOpened = Iris.State(false)
local _position = Iris.State(_screenSize / 2)
local _frameTimes = Iris.State({})
local _pings = Iris.State({})

-- PRIVATE FUNCTIONS

-- MODULES
local DebugStore = {}

DebugStore.IsOpened = _isOpened
DebugStore.Position = _position
DebugStore.FrameTimes = _frameTimes
DebugStore.Pings = _pings

return DebugStore
