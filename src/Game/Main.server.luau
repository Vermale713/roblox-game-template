--!strict
-- SERVICES
const ServerScriptService = game:GetService "ServerScriptService"

-- IMPORTED MODULES
const Loader = require "@platform/Loader"

-- MAIN
Loader.Start {
    Root = ServerScriptService.Server,
    SingletonMatcher = { "Service$" },
    Lifecycles = {
        { Method = "OnInit" },
        { Method = "OnStart", Async = true },
    },
}
