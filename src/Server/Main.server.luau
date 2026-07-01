-- SERVICES
const ServerScriptService = game:GetService "ServerScriptService"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Loader = require "@game/ReplicatedStorage/Utilities/Loader"

-- MAIN
Loader.Load(ServerScriptService):andThen(Loader.Start):catch(function(err)
	LogService:Warn("[Main] Loader failed: {error}", { error = tostring(err) })
end)
