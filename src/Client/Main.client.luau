-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Loader = require(ReplicatedStorage.Utilities.Loader)

-- MAIN
Loader.Load(ReplicatedStorage.Client):andThen(Loader.Start):catch(function(err)
	LogService:Warn("[Main] Loader failed: {error}", { error = tostring(err) })
end)
