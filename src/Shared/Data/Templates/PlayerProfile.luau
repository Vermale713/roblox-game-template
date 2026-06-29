-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"

-- IMPORTED MODULES
const PlayerData = require(ReplicatedStorage.Data.Templates.PlayerData)
const PlayerMetadata = require(ReplicatedStorage.Data.Templates.PlayerMetadata)

-- TYPES
-- the full persisted profile: every public (replicated) field plus a server-only
-- Metadata table
export type PlayerProfile = PlayerData.PlayerData & {
	Metadata: PlayerMetadata.PlayerMetadata,
}

-- PUBLIC MODULE
-- the shape ProfileStore persists. Public fields are kept at the top level (cloned
-- from PlayerData) so DataReplicationService can project them into the replicated
-- PlayerDataStore, while Metadata stays server-side. Add public fields to
-- PlayerData and server-only fields to PlayerMetadata.
const PlayerProfile = (table.clone(PlayerData) :: any) :: PlayerProfile
PlayerProfile.Metadata = table.clone(PlayerMetadata)

return PlayerProfile
