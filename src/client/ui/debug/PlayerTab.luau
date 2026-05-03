--[=[
	PlayerTab.luau
	Local player state debug tab
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
local Iris = require(ReplicatedStorage.packages.Iris)

-- PRIVATE FUNCTIONS
local function traversePlayerData(data: { [string]: any })
	for key, value in data do
		if typeof(value) == "table" then
			Iris.Tree({ key })

			traversePlayerData(value)

			Iris.End()
		else
			Iris.Text({ `{key} = {value}` })
		end
	end
end

local function PlayerTab(data: PlayerData.PlayerData)
	Iris.SeparatorText({ "Player Data" })
	traversePlayerData(data :: { [string]: any })
end

return PlayerTab
