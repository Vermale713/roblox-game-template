-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const DebugStore = require(ReplicatedStorage.client.store.DebugStore)
const DebugWindow = require(ReplicatedStorage.client.ui.debug.DebugWindow)
const Iris = require(ReplicatedStorage.packages.Iris)
const UiLabs = require(ReplicatedStorage.packages.UiLabs)

const story = UiLabs.CreateIrisStory({
	iris = Iris,
}, function()
	const conn = Iris:Connect(function()
		DebugWindow()
	end)

	DebugStore.IsOpened:set(true)

	return function()
		conn()
	end
end)

return story
