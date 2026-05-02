-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE
local startTime = os.clock()

-- PRIVATE FUNCTIONS

-- SCRIPT
Loader.loadDirectory(ReplicatedStorage.Client)
	:andThen(Loader.start)
	:andThen(function()
		print(`[Main] Server has successfully started in: {os.clock() - startTime}`)
	end)
	:catch(function()
		error("[Main] Server has failed to start")
	end)
