--[=[
	UserController.luau
	Handles creating the user and related data
]=]

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local Client = require(ReplicatedStorage.client.network.Client)
local CharmSync = require(ReplicatedStorage.packages.CharmSync)
local SaveStore = require(ReplicatedStorage.client.store.SaveStore)
local Loader = require(ReplicatedStorage.utilities.Loader)

-- CONSTANTS

-- TYPES
type SyncPayload = CharmSync.SyncPayload

-- PRIVATE STATE

-- PRIVATE FUNCTIONS
local function onSync(patches: { SyncPayload })
	print("patching client")
	CharmSync.client.patch(patches)
end

-- PUBLIC MODULE
local UserController = {}
Loader.register("UserController", {
	Module = UserController,
	Dependencies = {},
})

function UserController.onInit()
	CharmSync.client.addSignals({
		[`User-{Players.LocalPlayer.Name}`] = SaveStore.SetSave,
	})
	Client.User.Sync.on(onSync)
end

return UserController
