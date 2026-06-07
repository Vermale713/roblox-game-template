--[=[
	PlayerTab.luau
	Local player state debug tab
]=]

-- SERVICES
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
const PlayerData = require(ReplicatedStorage.data.templates.PlayerData)
const Iris = require(ReplicatedStorage.packages.Iris)

-- PRIVATE FUNCTIONS
const function traversePlayerData(data: { [string]: any })
	for key, value in data do
		if typeof(value) == "table" then
			const isUncollapsed = Iris.State(true)

			Iris.Tree({ key }, { isUncollapsed = isUncollapsed })

			traversePlayerData(value)

			Iris.End()
		else
			Iris.Text({ `{key} = {value}` })
		end
	end
end

const function PlayerTab(data: PlayerData.PlayerData)
	Iris.SeparatorText({ "Player Data" })
	traversePlayerData(data :: { [string]: any })
end

return PlayerTab
