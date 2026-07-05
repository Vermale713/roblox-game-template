-- IMPORTED MODULES
const Iris = require "@game/ReplicatedStorage/Packages/Iris"
const PlayerDataStore = require "@game/ReplicatedStorage/Client/Store/PlayerDataStore"

-- PUBLIC MODULE
-- An Iris draw callback: connected once and re-run every cycle by Iris. Watches
-- the local player's replicated PlayerData live. Cast to a generic map so new
-- template fields show up automatically without editing this window.
const function PlayerDataWindow()
	Iris.Window { "Player Data" }

	const data = PlayerDataStore.GetLocal() :: { [string]: unknown }?
	if data then
		for key, value in data do
			Iris.Text { `{key}: {tostring(value)}` }
		end
	else
		Iris.Text { "Waiting for replication…" }
	end

	Iris.End()
end

return PlayerDataWindow
