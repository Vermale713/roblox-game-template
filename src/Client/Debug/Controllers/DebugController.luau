-- SERVICES
const Players = game:GetService "Players"
const RunService = game:GetService "RunService"

-- IMPORTED MODULES
const Iris = require "@game/ReplicatedStorage/Packages/Iris"
const PlayerDataWindow = require "@game/ReplicatedStorage/Client/Debug/Windows/PlayerDataWindow"
const PerformanceWindow = require "@game/ReplicatedStorage/Client/Debug/Windows/PerformanceWindow"
const CharacterWindow = require "@game/ReplicatedStorage/Client/Debug/Windows/CharacterWindow"
const ServicesWindow = require "@game/ReplicatedStorage/Client/Debug/Windows/ServicesWindow"
const Input = require "@game/ReplicatedStorage/Libraries/Input"

-- ALIASES
-- Id namespaces the window's widgets via Iris.PushId. Iris derives widget IDs from
-- call-stack line numbers only (not script identity), and every window is invoked
-- from the same loop line below, so without a per-window id two widgets sharing a
-- line number across modules would collide onto the same instance.
type DebugWindow = { Id: string, Draw: () -> () }

-- CONSTANTS
-- UserIds that get the Iris overlay in live games; everyone in Studio gets it for
-- easy testing. Mirrors ConchService's admin gating so the overlay (which draws
-- every frame) never ships to ordinary players' clients.
const ADMIN_USER_IDS: { number } = {
	2600715546,
}
-- every window drawn while the overlay is shown; add new ones here
const WINDOWS: { DebugWindow } = {
	{ Id = "PlayerData", Draw = PlayerDataWindow },
	{ Id = "Performance", Draw = PerformanceWindow },
	{ Id = "Character", Draw = CharacterWindow },
	{ Id = "Services", Draw = ServicesWindow },
}

-- PRIVATE STATE
local _input: Input.Input
local _isShown = false

-- PRIVATE FUNCTIONS
const function isDebugAllowed(): boolean
	return RunService:IsStudio() or table.find(ADMIN_USER_IDS, Players.LocalPlayer.UserId) ~= nil
end

-- PUBLIC MODULE
const DebugController = {}

function DebugController.OnInit()
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
