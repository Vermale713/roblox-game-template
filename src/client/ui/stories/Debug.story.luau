-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local DebugStore = require(ReplicatedStorage.client.store.DebugStore)
local DebugWindow = require(ReplicatedStorage.client.ui.debug.DebugWindow)
local Iris = require(ReplicatedStorage.packages.Iris)
local UiLabs = require(ReplicatedStorage.packages.UiLabs)

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
