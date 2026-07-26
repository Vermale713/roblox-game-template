-- SERVICES
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"

-- IMPORTED MODULES
const Iris = require "@game/ReplicatedStorage/Packages/Iris"
const CharacterWindow = require "@game/ReplicatedStorage/Client/Debug/Windows/CharacterWindow"
const ServicesWindow = require "@game/ReplicatedStorage/Client/Debug/Windows/ServicesWindow"
const AdminUserIds = require "@game/ReplicatedStorage/Data/Admins/AdminUserIds"
const Gizmo = require "@game/ReplicatedStorage/Libraries/Gizmo"
const Input = require "@game/ReplicatedStorage/Libraries/Input"

-- ALIASES
-- Id namespaces the window's widgets via Iris.PushId. Iris derives widget IDs from
-- call-stack line numbers only (not script identity), and every window is invoked
-- from the same loop line below, so without a per-window id two widgets sharing a
-- line number across modules would collide onto the same instance.
type DebugWindow = { Id: string, Draw: () -> () }

-- CONSTANTS
const WINDOWS: { DebugWindow } = {
	{ Id = "Character", Draw = CharacterWindow },
	{ Id = "Services", Draw = ServicesWindow },
}

-- PRIVATE STATE
local _input: Input.Input
local _isShown = false

-- PRIVATE FUNCTIONS
const function isDebugAllowed(): boolean
	return RunService:IsStudio() or AdminUserIds.IsAdmin(Players.LocalPlayer.UserId)
end

-- PUBLIC MODULE
const DebugController = {}

function DebugController.OnInit()
	Gizmo.Init()
	_input = Input.new "Debug"
	_input
		:SetPriority(10)
		:SetEnabled(true)
		:SetSink(true)
		:Action("Toggle")
		:OnPressed(function()
			_isShown = not _isShown
		end)
		:Bind(Enum.KeyCode.F3)
end

function DebugController.OnStart()
	-- gate before Init so the per-frame render loop never starts for normal players
	if not isDebugAllowed() then
		return
	end

	-- Iris.Init yields on PlayerGui, so it lives here (OnStart) rather than OnInit
	Iris.Init(nil, nil, false)
	Iris:Connect(function()
		if not _isShown then
			return
		end
		for _, window in WINDOWS do
			-- namespace each window's widget IDs so equal line numbers across
			-- modules don't collide (see DebugWindow above)
			Iris.PushId(window.Id)
			window.Draw()
			Iris.PopId()
		end
	end)
end

return DebugController
