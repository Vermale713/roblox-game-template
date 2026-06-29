-- SERVICES
const Players = game:GetService "Players"
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"
const UserInputService = game:GetService "UserInputService"

-- IMPORTED MODULES
const Iris = require(ReplicatedStorage.Packages.Iris)
const PlayerDataWindow = require(ReplicatedStorage.Client.Debug.Windows.PlayerDataWindow)
const PerformanceWindow = require(ReplicatedStorage.Client.Debug.Windows.PerformanceWindow)
const CharacterWindow = require(ReplicatedStorage.Client.Debug.Windows.CharacterWindow)
const ServicesWindow = require(ReplicatedStorage.Client.Debug.Windows.ServicesWindow)

-- ALIASES
-- Id namespaces the window's widgets via Iris.PushId. Iris derives widget IDs from
-- call-stack line numbers only (not script identity), and every window is invoked
-- from the same loop line below, so without a per-window id two widgets sharing a
-- line number across modules would collide onto the same instance.
type DebugWindow = { Id: string, Draw: () -> () }

-- CONSTANTS
-- Conch owns F4, so the debug overlay toggles on F3.
const TOGGLE_KEY = Enum.KeyCode.F3
-- UserIds that get the Iris overlay in live games; everyone in Studio gets it for
-- easy testing. Mirrors ConchService's admin gating so the overlay (which draws
-- every frame) never ships to ordinary players' clients.
const ADMIN_USER_IDS: { number } = {}
-- every window drawn while the overlay is shown; add new ones here
const WINDOWS: { DebugWindow } = {
	{ Id = "PlayerData", Draw = PlayerDataWindow },
	{ Id = "Performance", Draw = PerformanceWindow },
	{ Id = "Character", Draw = CharacterWindow },
	{ Id = "Services", Draw = ServicesWindow },
}

-- PRIVATE STATE
-- reassigned by the toggle key; the draw callback early-returns while hidden
local _isShown = true

-- PRIVATE FUNCTIONS
const function isDebugAllowed(): boolean
	return RunService:IsStudio() or table.find(ADMIN_USER_IDS, Players.LocalPlayer.UserId) ~= nil
end

-- PUBLIC MODULE
const DebugController = {}

function DebugController:OnStart()
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

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.KeyCode == TOGGLE_KEY then
			_isShown = not _isShown
		end
	end)
end

return DebugController
