-- PUBLIC MODULE
-- server-only account metadata persisted with the profile (see PlayerProfile);
-- it is never replicated to clients. Timestamps are unix seconds (os.time) and
-- Playtime is the total seconds played across every session.
const PlayerMetadata = {
	JoinedAt = 0, -- first ever join; set once and never overwritten
	LastOnlineAt = 0, -- last time seen online; set on join, updated at session end
	Playtime = 0, -- total seconds played across all sessions
	SessionCount = 0, -- number of sessions started
	RobuxSpent = 0, -- total Robux spent in the game
}

export type PlayerMetadata = typeof(PlayerMetadata)

return PlayerMetadata
