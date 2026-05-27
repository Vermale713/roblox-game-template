local PlayerData = {
	-- Monetization
	RobuxSpent = 0,

	-- Metadata
	Metadata = {
		JoinDate = 0,
		LastSeen = 0,
		TotalPlaytime = 0,
		Version = 1, -- For migration purposes in the event that data can not be deleted, increment this if there is breaking changes to data
	},
}

export type PlayerData = typeof(PlayerData)

return PlayerData
