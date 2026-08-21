-- SERVICES
const ServerScriptService = game:GetService "ServerScriptService"
const LogService = game:GetService "LogService"

-- IMPORTED MODULES
const Loader = require "@game/ReplicatedStorage/Utilities/Loader"
const Vow = require "@game/ReplicatedStorage/Packages/Vow"

-- MAIN
const loadVow = Loader.Load(ServerScriptService)
const loaded, result = Vow.await(loadVow)
Vow.destroy(loadVow)

if loaded then
	const startVow = Loader.Start(result :: Loader.Services)
	Vow.await(startVow)
	Vow.destroy(startVow)
else
	LogService:Warn("[Main] Loader failed: {error}", { error = tostring(result) })
end
