-- SERVICES
const ServerScriptService = game:GetService "ServerScriptService"

-- IMPORTED MODULES
const Loader = require "@lib/Loader"

-- MAIN
Loader.Start {
    Root = ServerScriptService,
    SingletonMatcher = { "Service" },
    Lifecycles = {
        { Method = "OnInit" },
        { Method = "OnStart", Async = true },
    },
}
