-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const Iris = require(ReplicatedStorage.packages.Iris)
const UiLabs = require(ReplicatedStorage.packages.UiLabs)

const story = UiLabs.CreateIrisStory({
	iris = Iris,
}, function()
	const conn = Iris:Connect(function()
		Iris.ShowDemoWindow()
	end)

	return function()
		conn()
	end
end)

return story
