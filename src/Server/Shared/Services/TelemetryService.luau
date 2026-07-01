-- SERVICES
const RunService = game:GetService "RunService"
const AnalyticsService = game:GetService "AnalyticsService"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const PlayerService = require "@game/ServerScriptService/Shared/Services/PlayerService"

-- TYPES
-- optional custom dimensions accepted by every AnalyticsService event
type Fields = { [string]: string }?

-- CONSTANTS
-- AnalyticsService silently drops events in Studio, so we log them there instead
const IS_STUDIO = RunService:IsStudio()

-- PRIVATE FUNCTIONS
-- forwards an AnalyticsService call, swallowing its errors (it throws when the
-- API is disabled) and short-circuiting in Studio where events are dropped anyway
const function track(method: string, player: Player, ...: any)
	if IS_STUDIO then
		LogService:Info("[Telemetry] {method} skipped in Studio", { method = method, player = player.Name })
		return
	end

	const args = table.pack(...)
	const ok, err = pcall(function()
		(AnalyticsService :: any)[method](AnalyticsService, player, table.unpack(args, 1, args.n))
	end)
	if not ok then
		LogService:Warn("[Telemetry] {method} failed", { method = method, player = player.Name, error = tostring(err) })
	end
end

-- PUBLIC MODULE
const TelemetryService = {}

TelemetryService.Dependencies = { "PlayerService" }

function TelemetryService:OnInit()
	-- reference example: log a server-authoritative onboarding step on join. Copy
	-- this pattern for future events — always called from trusted server logic. Step
	-- 1 ("joined the game") is universal; add later, game-specific steps (tutorial,
	-- first match, ...) as those flows are built.
	PlayerService.PlayerAdded:Connect(function(player: Player)
		TelemetryService.LogOnboardingFunnelStepEvent(player, 1, "Joined the game")
	end)
end

-- thin, Studio-safe pass-throughs over AnalyticsService. Arguments match the
-- engine API exactly; see the AnalyticsService documentation.
function TelemetryService.LogCustomEvent(player: Player, eventName: string, value: number?, fields: Fields)
	track("LogCustomEvent", player, eventName, value, fields)
end

function TelemetryService.LogEconomyEvent(
	player: Player,
	flowType: Enum.AnalyticsEconomyFlowType,
	currencyType: string,
	amount: number,
	endingBalance: number,
	transactionType: string,
	itemSku: string?,
	fields: Fields
)
	track("LogEconomyEvent", player, flowType, currencyType, amount, endingBalance, transactionType, itemSku, fields)
end

function TelemetryService.LogProgressionEvent(
	player: Player,
	progressionPathName: string,
	status: Enum.AnalyticsProgressionType,
	level: number?,
	levelName: string?,
	fields: Fields
)
	track("LogProgressionEvent", player, progressionPathName, status, level, levelName, fields)
end

-- the experience-wide onboarding funnel (Analytics -> Funnels). `step` is the
-- 1-based position in the funnel (1-100); call with increasing steps as the
-- player advances first-time setup (e.g. 1 "JoinedGame", 2 "FinishedTutorial").
function TelemetryService.LogOnboardingFunnelStepEvent(player: Player, step: number, stepName: string, fields: Fields)
	track("LogOnboardingFunnelStepEvent", player, step, stepName, fields)
end

return TelemetryService
