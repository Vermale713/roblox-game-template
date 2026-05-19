local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiLabs = require(ReplicatedStorage.packages.UiLabs)

local storybook: UiLabs.Storybook = {
	name = "Stories",
	storyRoots = { ReplicatedStorage.client.ui.stories },
}

return storybook
