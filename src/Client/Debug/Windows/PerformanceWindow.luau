-- SERVICES
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const Stats = game:GetService "Stats"

-- IMPORTED MODULES
const Iris = require(ReplicatedStorage.Packages.Iris)

-- CONSTANTS
-- samples retained in the FPS graph (~1.5s at 60fps)
const HISTORY_LENGTH = 90
-- weight for the exponential moving average of the FPS readout
const SMOOTHING = 0.1

-- PRIVATE STATE
-- frame timing is sampled between Iris cycles (Iris runs one cycle per Heartbeat)
local _lastClock = os.clock()
local _smoothedFps = 60

-- PUBLIC MODULE
-- An Iris draw callback: live FPS (with graph), frame time, memory and ping.
const function PerformanceWindow()
	const now = os.clock()
	const delta = now - _lastClock
	_lastClock = now
	const fps = if delta > 0 then 1 / delta else 0
	-- smooth the readout so it stays legible; the graph keeps the raw samples
	_smoothedFps += (fps - _smoothedFps) * SMOOTHING

	Iris.Window { "Performance" }

	Iris.Text { `FPS: {math.floor(_smoothedFps + 0.5)}` }
	Iris.Text { `Frame: {string.format("%.2f ms", delta * 1000)}` }

	-- Iris.State returns the same object every cycle (keyed by call position), so
	-- the history table persists across frames
	const history = Iris.State({} :: { number })
	const values = history.value
	table.insert(values, fps)
	if #values > HISTORY_LENGTH then
		table.remove(values, 1)
	end
	-- force=true: we mutated `values` in place, so the reference is unchanged and
	-- State:set would otherwise no-op and never refresh the connected plot
	history:set(values, true)

	-- Iris's PlotLines autoscale is dead code (it coalesces Min/Max to ±math.huge
	-- before a nil-check that can never pass), so we must pass an explicit Max or the
	-- range is -inf and every line renders to garbage. Derive it from the samples,
	-- rounded up to a 30fps step so the axis stays stable instead of jittering.
	local peak = 0
	for _, value in values do
		peak = math.max(peak, value)
	end
	const graphMax = math.max(30, math.ceil(peak / 30) * 30)

	-- positional args: Text, Height, Min, Max (bars rise from BaseLine, default 0)
	Iris.PlotHistogram({ "FPS", 80, 0, graphMax }, { values = history })

	Iris.SeparatorText { "Resources" }
	Iris.Text { `Memory: {string.format("%.0f MB", Stats:GetTotalMemoryUsageMb())}` }
	Iris.Text { `Ping: {string.format("%.0f ms", Players.LocalPlayer:GetNetworkPing() * 1000)}` }

	Iris.End()
end

return PerformanceWindow
