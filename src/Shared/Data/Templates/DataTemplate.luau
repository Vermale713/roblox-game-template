-- PUBLIC MODULE
const PlayerData = {
	Coins = 0,

	-- Combat
	StatusEffects = {}, -- Persistent status effects

	-- Metadata
	JoinedAt = 0,
	LastOnlineAt = 0,
	Playtime = 0,
	RobuxSpent = 0,
}

export type PlayerData = typeof(PlayerData)

return PlayerData
