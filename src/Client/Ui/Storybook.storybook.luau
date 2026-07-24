-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const UiLabs = require "@game/ReplicatedStorage/Packages/UiLabs"

-- PUBLIC MODULE
return {
	name = "Game Ui",
	storyRoots = { ReplicatedStorage },
} :: UiLabs.Storybook
