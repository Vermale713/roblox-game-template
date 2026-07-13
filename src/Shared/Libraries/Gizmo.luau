-- SERVICES
const RunService = game:GetService "RunService"

-- TYPES
export type Render = {
	Render: (self: Render, wireframe: WireframeHandleAdornment) -> (),
}

export type RenderSatisfier = (self: Render, wireframe: WireframeHandleAdornment) -> ()

export type Config = {
	Color: Color3?,
	Thickness: number?,
	Transparency: number?,
	AlwaysOnTop: boolean?,
	ZIndex: number?,
}

export type BoxRender = Render & {
	CFrame: CFrame,
	Size: Vector3,
}

export type LineRender = Render & {
	From: Vector3,
	To: Vector3,
}

export type SphereRender = Render & {
	CFrame: CFrame,
	Radius: number,
}

export type ArrowRender = Render & {
	CFrame: CFrame,
	Length: number,
}

export type CylinderRender = Render & {
	CFrame: CFrame,
	Radius: number,
	Height: number,
}

export type ConeRender = Render & {
	CFrame: CFrame,
	Radius: number,
	Height: number,
}

-- CONSTANTS
const CURVE_SEGMENTS = 16
const ARROW_HEAD_LENGTH_SCALE = 0.25
const ARROW_HEAD_RADIUS_SCALE = 0.5

-- PRIVATE STATE
const _wireframe = Instance.new "WireframeHandleAdornment"
const _renders: { Render } = {}
local _config: Config = {
	Color = Color3.new(0, 1, 1),

	Thickness = 0.05,
	Transparency = 0,
	AlwaysOnTop = true,
	ZIndex = 0,
}
local _connection: RBXScriptConnection? = nil

-- PRIVATE FUNCTIONS
const function applyConfig(config: Config)
	_config.Color = config.Color or _wireframe.Color3
	_config.Thickness = config.Thickness or _wireframe.Thickness
	_config.Transparency = config.Transparency or _wireframe.Transparency
	_config.AlwaysOnTop = config.AlwaysOnTop or _wireframe.AlwaysOnTop
	_config.ZIndex = config.ZIndex or _wireframe.ZIndex

	_wireframe.Color3 = _config.Color or Color3.new(1, 1, 1)
	_wireframe.Thickness = _config.Thickness or 1
	_wireframe.Transparency = _config.Transparency or 0
	_wireframe.AlwaysOnTop = _config.AlwaysOnTop or false
	_wireframe.ZIndex = _config.ZIndex or -1
end

const function render()
	_wireframe:Clear()

	for _, gizmoRender in _renders do
		gizmoRender.Render(gizmoRender, _wireframe)
	end
end

const function renderBox(self: BoxRender, wireframe: WireframeHandleAdornment)
	const halfSize = self.Size / 2
	const cframe = self.CFrame
	const backBottomLeft = cframe * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z)
	const backBottomRight = cframe * Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z)
	const backTopRight = cframe * Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z)
	const backTopLeft = cframe * Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z)
	const frontBottomLeft = cframe * Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z)
	const frontBottomRight = cframe * Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z)
	const frontTopRight = cframe * Vector3.new(halfSize.X, halfSize.Y, halfSize.Z)
	const frontTopLeft = cframe * Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z)

	wireframe:AddPath({
		backBottomLeft,
		backBottomRight,
		backTopRight,
		backTopLeft,
		backBottomLeft,
		frontBottomLeft,
		frontBottomRight,
		frontTopRight,
		frontTopLeft,
		frontBottomLeft,
		backBottomLeft,
		backBottomRight,
		frontBottomRight,
		frontTopRight,
		backTopRight,
		backTopLeft,
		frontTopLeft,
	}, false)
end

const function renderLine(self: LineRender, wireframe: WireframeHandleAdornment)
	wireframe:AddPath({ self.From, self.To }, false)
end

const function renderSphere(self: SphereRender, wireframe: WireframeHandleAdornment)
	const points = {}

	for segment = 0, CURVE_SEGMENTS do
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		table.insert(points, self.CFrame * Vector3.new(math.cos(angle) * self.Radius, math.sin(angle) * self.Radius, 0))
	end

	for segment = 1, CURVE_SEGMENTS do
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		table.insert(points, self.CFrame * Vector3.new(math.cos(angle) * self.Radius, 0, math.sin(angle) * self.Radius))
	end

	for segment = 1, CURVE_SEGMENTS / 4 do
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		table.insert(points, self.CFrame * Vector3.new(math.cos(angle) * self.Radius, math.sin(angle) * self.Radius, 0))
	end

	for segment = 1, CURVE_SEGMENTS do
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		table.insert(points, self.CFrame * Vector3.new(0, math.cos(angle) * self.Radius, math.sin(angle) * self.Radius))
	end

	for segment = (CURVE_SEGMENTS / 4) - 1, 0, -1 do
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		table.insert(points, self.CFrame * Vector3.new(math.cos(angle) * self.Radius, math.sin(angle) * self.Radius, 0))
	end

	wireframe:AddPath(points, false)
end

const function renderArrow(self: ArrowRender, wireframe: WireframeHandleAdornment)
	const headLength = self.Length * ARROW_HEAD_LENGTH_SCALE
	const headRadius = headLength * ARROW_HEAD_RADIUS_SCALE
	const tip = self.CFrame * Vector3.new(0, self.Length, 0)
	const headBaseHeight = self.Length - headLength
	const right = self.CFrame * Vector3.new(headRadius, headBaseHeight, 0)
	const forward = self.CFrame * Vector3.new(0, headBaseHeight, headRadius)
	const left = self.CFrame * Vector3.new(-headRadius, headBaseHeight, 0)
	const back = self.CFrame * Vector3.new(0, headBaseHeight, -headRadius)

	wireframe:AddPath({
		self.CFrame.Position,
		tip,
		right,
		tip,
		forward,
		tip,
		left,
		tip,
		back,
		tip,
		right,
		forward,
		left,
		back,
		right,
	}, false)
end

const function renderCylinder(self: CylinderRender, wireframe: WireframeHandleAdornment)
	const points = {}
	const halfHeight = self.Height / 2

	const function getPoint(height: number, segment: number)
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		return self.CFrame * Vector3.new(math.cos(angle) * self.Radius, height, math.sin(angle) * self.Radius)
	end

	table.insert(points, getPoint(-halfHeight, 0))
	table.insert(points, getPoint(halfHeight, 0))

	for segment = 1, CURVE_SEGMENTS do
		table.insert(points, getPoint(halfHeight, segment))
	end

	table.insert(points, getPoint(-halfHeight, 0))

	for segment = 1, CURVE_SEGMENTS do
		table.insert(points, getPoint(-halfHeight, segment))
		table.insert(points, getPoint(halfHeight, segment))
		table.insert(points, getPoint(-halfHeight, segment))
	end

	wireframe:AddPath(points, false)
end

const function renderCone(self: ConeRender, wireframe: WireframeHandleAdornment)
	const points = {}
	const baseHeight = -self.Height / 2
	const tip = self.CFrame * Vector3.new(0, self.Height / 2, 0)

	const function getBasePoint(segment: number)
		const angle = (segment / CURVE_SEGMENTS) * math.pi * 2
		return self.CFrame * Vector3.new(math.cos(angle) * self.Radius, baseHeight, math.sin(angle) * self.Radius)
	end

	table.insert(points, getBasePoint(0))
	for segment = 1, CURVE_SEGMENTS do
		table.insert(points, getBasePoint(segment))
	end

	for segment = 0, CURVE_SEGMENTS do
		table.insert(points, tip)
		table.insert(points, getBasePoint(segment))
	end

	wireframe:AddPath(points, false)
end

-- PUBLIC MODULE
const Gizmo = {}

-- Pass settings here, or use Configure to update an already-initialised gizmo.
function Gizmo.Init(config: Config?)
	if _connection then
		_connection:Disconnect()
	end

	_wireframe.Name = "Gizmo"
	_wireframe.Adornee = workspace.Terrain
	_wireframe.Parent = workspace.Terrain

	applyConfig(config or _config)

	_connection = RunService.Heartbeat:Connect(render)
end

function Gizmo.Configure(config: Config)
	applyConfig(config)
end

function Gizmo.Clear()
	table.clear(_renders)
	_wireframe:Clear()
end

function Gizmo.Box(cframe: CFrame, size: Vector3): BoxRender
	const boxRender: BoxRender = {
		CFrame = cframe,
		Size = size,
		Render = renderBox :: RenderSatisfier,
	}

	table.insert(_renders, boxRender)

	return boxRender
end

function Gizmo.Line(from: Vector3, to: Vector3): LineRender
	const lineRender: LineRender = {
		From = from,
		To = to,
		Render = renderLine :: RenderSatisfier,
	}

	table.insert(_renders, lineRender)

	return lineRender
end

function Gizmo.Sphere(cframe: CFrame, radius: number): SphereRender
	const sphereRender: SphereRender = {
		CFrame = cframe,
		Radius = radius,
		Render = renderSphere :: RenderSatisfier,
	}

	table.insert(_renders, sphereRender)

	return sphereRender
end

function Gizmo.Arrow(cframe: CFrame, length: number): ArrowRender
	const arrowRender: ArrowRender = {
		CFrame = cframe,
		Length = length,
		Render = renderArrow :: RenderSatisfier,
	}

	table.insert(_renders, arrowRender)

	return arrowRender
end

function Gizmo.Cylinder(cframe: CFrame, radius: number, height: number): CylinderRender
	const cylinderRender: CylinderRender = {
		CFrame = cframe,
		Radius = radius,
		Height = height,
		Render = renderCylinder :: RenderSatisfier,
	}

	table.insert(_renders, cylinderRender)

	return cylinderRender
end

function Gizmo.Cone(cframe: CFrame, radius: number, height: number): ConeRender
	const coneRender: ConeRender = {
		CFrame = cframe,
		Radius = radius,
		Height = height,
		Render = renderCone :: RenderSatisfier,
	}

	table.insert(_renders, coneRender)

	return coneRender
end

return Gizmo
