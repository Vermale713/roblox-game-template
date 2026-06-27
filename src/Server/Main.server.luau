-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const ServerScriptService = game:GetService "ServerScriptService"

-- IMPORTED MODULES
const Loader = require(ReplicatedStorage.Utilities.Loader)

-- MAIN
Loader.Load(ServerScriptService):andThen(Loader.Start):catch(function(err)
	warn("[Main] Loader failed:", err)
end)
