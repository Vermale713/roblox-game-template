-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const DebugStore = require(ReplicatedStorage.client.store.DebugStore)
const DebugWindow = require(ReplicatedStorage.client.ui.debug.DebugWindow)
const Iris = require(ReplicatedStorage.packages.Iris)
const UiLabs = require(ReplicatedStorage.packages.UiLabs)

local story = UiLabs.CreateIrisStory({
	iris = Iris,
}, function()
	local conn = Iris:Connect(function()
		DebugWindow()
	end)

	DebugStore.IsOpened:set(true)

	return function()
		conn()
	end
end)

return story
