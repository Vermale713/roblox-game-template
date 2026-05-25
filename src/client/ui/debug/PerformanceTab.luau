--[=[
	PerformanceTab.luau
	Local player performance statistics
]=]

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

-- IMPORTED MODULES
local Iris = require(ReplicatedStorage.packages.Iris)
local NumberUtil = require(ReplicatedStorage.utilities.NumberUtil)

-- CONSTANTS
local SAMPLE_COUNT = 60

-- PRIVATE STATE
local _frameTimes = {}
local _pings = {}
local frameTimesState = Iris.State(frameTimes)
local pingsState = Iris.State(pings)

local function PerformanceTab()
	Iris.SeparatorText({ "Basic Performance Data" })
	local fps = 1 / Stats.FrameTime
	local ping = Players.LocalPlayer:GetNetworkPing() * 1000

	Iris.Text({ `FPS: {NumberUtil.truncate(fps)}` })
	Iris.Text({ `Ping: {NumberUtil.truncate(ping)}` })

	table.insert(frameTimes, fps)
	if #frameTimes > SAMPLE_COUNT then
		table.remove(frameTimes, 1)
	end

	table.insert(pings, ping)
	if #pings > SAMPLE_COUNT then
		table.remove(pings, 1)
	end

	frameTimesState:set(frameTimes, true)
	pingsState:set(pings, true)

	Iris.SeparatorText({ "Frame Time" })
	Iris.PlotHistogram({ "Frame Per Second", 100, 0, 300, "", 0 }, { values = frameTimesState })

	Iris.SeparatorText({ "Ping" })
	Iris.PlotHistogram({ "Ping (ms)", 100, 0, 300, "", 0 }, { values = pingsState })
end

return PerformanceTab
