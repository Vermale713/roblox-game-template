-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const UiLabs = require(ReplicatedStorage.packages.UiLabs)

const storybook: UiLabs.Storybook = {
	name = "Stories",
	storyRoots = { ReplicatedStorage.client.ui.stories },
}

return storybook
