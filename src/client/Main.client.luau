-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE
local _startTime = os.clock()

-- PRIVATE FUNCTIONS

-- SCRIPT
Loader.loadDirectory(ReplicatedStorage.client, true)
	:andThen(Loader.start)
	:andThen(function()
		print(`[Main] Client has successfully started in: {os.clock() - _startTime}`)
	end)
	:catch(function()
		error("[Main] Client has failed to start")
	end)
