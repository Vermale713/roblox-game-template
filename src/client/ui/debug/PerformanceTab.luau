--[=[
	PerformanceTab.luau
	Local player performance statistics
]=]

-- SERVICES
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Stats = game:GetService("Stats")

-- IMPORTED MODULES
const DebugStore = require(ReplicatedStorage.client.store.DebugStore)
const Iris = require(ReplicatedStorage.packages.Iris)
const NumberUtil = require(ReplicatedStorage.utilities.NumberUtil)

-- CONSTANTS
const SAMPLE_COUNT = 60

-- PRIVATE STATE
local _frameTimes = {}
local _pings = {}

const function PerformanceTab()
	Iris.SeparatorText({ "Basic Performance Data" })
	local fps = 1 / Stats.FrameTime
	local ping = Players.LocalPlayer:GetNetworkPing() * 1000

	Iris.Text({ `FPS: {NumberUtil.truncate(fps)}` })
	Iris.Text({ `Ping: {NumberUtil.truncate(ping)}` })

	table.insert(_frameTimes, fps)
	if #_frameTimes > SAMPLE_COUNT then
		table.remove(_frameTimes, 1)
	end

	table.insert(_pings, ping)
	if #_pings > SAMPLE_COUNT then
		table.remove(_pings, 1)
	end

	DebugStore.FrameTimes:set(_frameTimes, true)
	DebugStore.Pings:set(_pings, true)

	Iris.SeparatorText({ "Frame Time" })
	Iris.PlotHistogram({ "Frame Per Second", 100, 0, 300, "", 0 }, { values = DebugStore.FrameTimes })

	Iris.SeparatorText({ "Ping" })
	Iris.PlotHistogram({ "Ping (ms)", 100, 0, 300, "", 0 }, { values = DebugStore.Pings })
end

return PerformanceTab
