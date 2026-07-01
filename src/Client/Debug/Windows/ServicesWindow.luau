-- IMPORTED MODULES
const Iris = require "@game/ReplicatedStorage/Packages/Iris"
const Loader = require "@game/ReplicatedStorage/Utilities/Loader"

-- PUBLIC MODULE
-- An Iris draw callback: every service/controller the Loader discovered, in
-- dependency order, with OnInit timing and current lifecycle phase.
const function ServicesWindow()
	Iris.Window { "Services" }

	const statuses = Loader.GetStatus()
	Iris.Text { `{#statuses} loaded` }
	Iris.Separator()

	-- Iris's Table widget renders its cells empty until a discard/recreate cycle
	-- (its source is marked "needs an overhaul"), so we use auto-sizing Text rows,
	-- which render correctly on the first frame
	for _, status in statuses do
		const init = if status.InitSeconds then string.format("%.2f ms", status.InitSeconds * 1000) else "—"
		Iris.Text { `{status.Phase}  ·  {status.Name}  ({init})` }
	end

	Iris.End()
end

return ServicesWindow
