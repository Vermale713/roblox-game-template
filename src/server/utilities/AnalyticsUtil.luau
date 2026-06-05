--[=[
	AnalyticsUtil.luau
	A module that handles analytics
]=]

-- SERVICES
const AnalyticsService = game:GetService("AnalyticsService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

-- IMPORTED MODULES
const OnboardingData = require(ServerStorage.data.analytics.OnboardingData)
const Promise = require(ReplicatedStorage.packages.Promise)

-- PUBLIC MODULE
local AnalyticsUtil = {}

function AnalyticsUtil.LogOnboardingStep(player: Player, step: keyof<typeof(OnboardingData)>)
	Promise.new(function(resolve, reject)
		-- have to typecast cause type solver sucks
		if not (OnboardingData :: { [string]: number })[step] then
			reject("Step does not exist in OnboardingData")
		end
		AnalyticsService:LogOnboardingFunnelStepEvent(player, (OnboardingData :: { [string]: number })[step], step)
		resolve()
	end):catch(function(err)
		warn(`[AnalyticsUtil] encountered an error: {err}\n{debug.traceback()}`)
	end)
end

return AnalyticsUtil
