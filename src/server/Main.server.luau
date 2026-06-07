-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTED MODULES
const Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE
const _startTime = os.clock()

-- PRIVATE FUNCTIONS

-- SCRIPT
Loader.loadDirectory(ServerScriptService, true)
	:andThen(Loader.start)
	:andThen(function()
		print(`[Main] Server has successfully started in: {os.clock() - _startTime}`)
	end)
	:catch(function(err)
		error(`[Main] Server has failed to start\n{err}`)
	end)
