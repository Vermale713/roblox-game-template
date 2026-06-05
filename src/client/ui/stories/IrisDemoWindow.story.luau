-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Iris = require(ReplicatedStorage.packages.Iris)
const UiLabs = require(ReplicatedStorage.packages.UiLabs)

local story = UiLabs.CreateIrisStory({
	iris = Iris,
}, function()
	local conn = Iris:Connect(function()
		Iris.ShowDemoWindow()
	end)

	return function()
		conn()
	end
end)

return story
