-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Loader = require(ReplicatedStorage.Utilities.Loader)

-- MAIN
Loader.Load(ReplicatedStorage.Client):andThen(Loader.Start):catch(function(err)
	warn("[Main] Loader failed:", err)
end)
