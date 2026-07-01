-- CONSTANTS
-- the single static design theme, direct-required by every component. There is no
-- runtime theme switching, so these are plain constants rather than reactive state.
const Theme = {
	Colors = {
		Background = Color3.fromRGB(20, 22, 28),
		Surface = Color3.fromRGB(32, 35, 44),
		Primary = Color3.fromRGB(88, 132, 255),
		Text = Color3.fromRGB(240, 242, 248),
		TextMuted = Color3.fromRGB(150, 156, 170),
	},

	Font = Font.fromEnum(Enum.Font.GothamMedium),

	-- spacing scale in pixels
	Spacing = {
		Small = 4,
		Medium = 8,
		Large = 16,
	},

	Resolution = Vector2.new(1920, 1080),

	CornerRadius = UDim.new(0, 8),

	-- ScreenGui DisplayOrder per layer, thousands apart so each layer owns a wide
	-- z-band and new layers can slot between (see Ui/App.luau)
	DisplayOrder = {
		Hud = 1000,
		Menu = 2000,
		Modal = 3000,
	},
}

return Theme
