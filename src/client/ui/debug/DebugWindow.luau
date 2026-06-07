--[=[
	DebugWindow.luau
	Main debug window
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const DebugStore = require(ReplicatedStorage.client.store.DebugStore)
const SaveStore = require(ReplicatedStorage.client.store.SaveStore)
const PerformanceTab = require(ReplicatedStorage.client.ui.debug.PerformanceTab)
const PlayerTab = require(ReplicatedStorage.client.ui.debug.PlayerTab)
const Iris = require(ReplicatedStorage.packages.Iris)

const function DebugWindow()
	const window = Iris.Window({ "Debug Menu" }, { isOpened = DebugStore.IsOpened, position = DebugStore.Position })

	if not window.state.isUncollapsed:get() then
		Iris.End()
		return
	end

	if not window.state.isOpened:get() then
		Iris.End()
		return
	end

	Iris.TabBar()

	const playerTab = Iris.Tab({ "Local Player State" })
	if playerTab.state.isOpened:get() then
		const playerData = SaveStore.GetSave()

		PlayerTab(playerData)
	end
	Iris.End()

	const performanceTab = Iris.Tab({ "Performance" })
	if performanceTab.state.isOpened:get() then
		PerformanceTab()
	end
	Iris.End()

	Iris.End()

	Iris.End()
end

return DebugWindow
