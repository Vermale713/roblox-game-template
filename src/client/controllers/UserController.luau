--[=[
	UserController.luau
	Handles creating the user and related data
]=]

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Client = require(ReplicatedStorage.Client.network.Client)
local PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
local Charm = require(ReplicatedStorage.packages.Charm)
local CharmSync = require(ReplicatedStorage.packages.CharmSync)
local SaveStore = require(ReplicatedStorage.Client.store.SaveStore)
local Signal = require(ReplicatedStorage.packages.Signal)
local Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES

-- PRIVATE STATE

-- PRIVATE FUNCTIONS
-- PUBLIC MODULE
local UserController = {}
Loader.register("UserController", {
	Module = UserController,
	Dependencies = {},
})

function UserController.onInit()
	CharmSync.client.addSignals({
		[`UserData-{Players.LocalPlayer.Name}`] = SaveStore.SetSave,
	})
	Client.User.sync.on(function(patches)
		CharmSync.client.patch(patches)
	end)
end

return UserController
