--[=[
	DebugWindow.luau
	Main debug window
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local DebugStore = require(ReplicatedStorage.client.store.DebugStore)
local SaveStore = require(ReplicatedStorage.client.store.SaveStore)
local PerformanceTab = require(ReplicatedStorage.client.ui.debug.PerformanceTab)
local PlayerTab = require(ReplicatedStorage.client.ui.debug.PlayerTab)
local Iris = require(ReplicatedStorage.packages.Iris)

local function DebugWindow()
	local window = Iris.Window({ "Debug Menu" }, { isOpened = DebugStore.IsOpened, position = DebugStore.Position })

	if not window.state.isUncollapsed:get() then
		Iris.End()
		return
	end

	if not window.state.isOpened:get() then
		Iris.End()
		return
	end

	Iris.TabBar()

	local playerTab = Iris.Tab({ "Local Player State" })
	if playerTab.state.isOpened:get() then
		local playerData = SaveStore.GetSave()

		PlayerTab(playerData)
	end
	Iris.End()

	local performanceTab = Iris.Tab({ "Performance" })
	if performanceTab.state.isOpened:get() then
		PerformanceTab()
	end
	Iris.End()

	Iris.End()

	Iris.End()
end

return DebugWindow
