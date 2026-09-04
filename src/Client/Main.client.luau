-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const Loader = require "@lib/Loader"

-- MAIN
Loader.Start {
    Root = ReplicatedStorage.Client,
    SingletonMatcher = { "Controller" },
    Lifecycles = {
        { Method = "OnInit" },
        { Method = "OnStart", Async = true },
    },
}
