-- IMPORTED MODULES
const Vide = require "@game/ReplicatedStorage/Packages/Vide"
const UiLabs = require "@game/ReplicatedStorage/Packages/UiLabs"
const Theme = require "@game/ReplicatedStorage/Client/Ui/Theme"
const Scaler = require "@game/ReplicatedStorage/Client/Ui/Components/Primitives/Scaler"

-- ALIASES
const create = Vide.create

-- PUBLIC MODULE
-- Scaler is a UIScale, so it has nothing to show on its own. Parent it under a demo
-- panel and resize the viewport (drag the UiLabs preview, or test on a phone) to see
-- the panel scale with the screen.
return UiLabs.CreateVideStory({
	vide = Vide,
}, function()
	return create "Frame" {
		Size = UDim2.fromOffset(320, 160),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Colors.Surface,

		Scaler(),

		create "UICorner" { CornerRadius = Theme.CornerRadius },

		create "TextLabel" {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "Scaled by Scaler",
			TextColor3 = Theme.Colors.Text,
			FontFace = Theme.Font,
			TextSize = 24,
		},
	}
end)
