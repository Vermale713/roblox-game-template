-- IMPORTED MODULES
const Vide = require "@game/ReplicatedStorage/Packages/Vide"

-- ALIASES
const create = Vide.create
const source = Vide.source
const cleanup = Vide.cleanup

-- CONSTANTS
const BASE_RESOLUTION = Vector2.new(1920, 1080)
const MIN_SCALE = 0.5
const MAX_SCALE = 1.5

-- PRIVATE FUNCTIONS
-- the scale to apply at the current viewport, as the ratio of the viewport's diagonal
-- to the design resolution's diagonal. Diagonal scaling blends both axes, so it holds
-- up across phones, tablets, and ultrawide rather than over-shrinking on one axis.
const function getUiScale(): number
	const camera = workspace.CurrentCamera
	if not camera then
		return 1
	end

	const ratio = camera.ViewportSize.Magnitude / BASE_RESOLUTION.Magnitude
	return math.clamp(ratio, MIN_SCALE, MAX_SCALE)
end

-- PUBLIC MODULE
-- a UIScale that keeps UI proportional to the design resolution across screen sizes;
-- parent it under a layer's root so everything beneath inherits the scale
const function Scaler()
	const scale = source(getUiScale())

	-- track the active camera's viewport; rebind if the camera itself is swapped so
	-- the scale never goes stale, disconnecting the previous listener each time
	local viewportConnection: RBXScriptConnection? = nil
	const function bindCamera(camera: Camera)
		if viewportConnection then
			viewportConnection:Disconnect()
		end
		scale(getUiScale())
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			scale(getUiScale())
		end)
	end

	if workspace.CurrentCamera then
		bindCamera(workspace.CurrentCamera)
	end

	const cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			bindCamera(workspace.CurrentCamera)
		end
	end)

	cleanup(function()
		if viewportConnection then
			viewportConnection:Disconnect()
		end
		cameraConnection:Disconnect()
	end)

	return create "UIScale" {
		Scale = scale,
	}
end

return Scaler
