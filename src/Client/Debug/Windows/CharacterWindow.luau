-- SERVICES
const Players = game:GetService "Players"
const Workspace = game:GetService "Workspace"

-- IMPORTED MODULES
const Iris = require "@game/ReplicatedStorage/Packages/Iris"

-- PUBLIC MODULE
-- An Iris draw callback: live humanoid and movement state for the local character.
const function CharacterWindow()
	Iris.Window { "Character" }

	const character = Players.LocalPlayer.Character
	if not character then
		Iris.Text { "No character." }
		Iris.End()
		return
	end

	const humanoid = character:FindFirstChildOfClass "Humanoid" :: Humanoid?
	const rootPart = character:FindFirstChild "HumanoidRootPart" :: BasePart?
	if not (humanoid and rootPart) then
		Iris.Text { "Character loading…" }
		Iris.End()
		return
	end

	Iris.SeparatorText { "Humanoid" }
	Iris.Text { `Health: {string.format("%.0f / %.0f", humanoid.Health, humanoid.MaxHealth)}` }
	Iris.Text { `WalkSpeed: {humanoid.WalkSpeed}` }
	Iris.Text { `JumpPower: {humanoid.JumpPower}` }
	Iris.Text { `State: {humanoid:GetState().Name}` }

	Iris.SeparatorText { "Movement" }
	const position = rootPart.Position
	Iris.Text { `Position: {string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z)}` }
	Iris.Text { `Speed: {string.format("%.1f", rootPart.AssemblyLinearVelocity.Magnitude)}` }

	const camera = Workspace.CurrentCamera
	if camera then
		Iris.Text { `Camera: {camera.CameraType.Name}` }
	end

	Iris.End()
end

return CharacterWindow
