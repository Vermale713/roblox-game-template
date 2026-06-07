--[=[
	DebugStore.luau
	This is where the data will live all reads are from
	to user data will be from here
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Iris = require(ReplicatedStorage.packages.Iris)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE
const _screenSize = workspace.CurrentCamera.ViewportSize
const _isOpened = Iris.State(false)
const _position = Iris.State(_screenSize / 2)
const _frameTimes = Iris.State({})
const _pings = Iris.State({})

-- PRIVATE FUNCTIONS

-- PUBLIC MODULES
const DebugStore = {}

DebugStore.IsOpened = _isOpened
DebugStore.Position = _position
DebugStore.FrameTimes = _frameTimes
DebugStore.Pings = _pings

return DebugStore
