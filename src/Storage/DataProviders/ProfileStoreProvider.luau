--!strict
-- IMPORTED MODULES
const ProfileStore = require "@spkg/ProfileStore"
const DataTypes = require "@types/DataTypes"

-- TYPES
type DataProviderInterface<T> = DataTypes.DataProviderInterface<T>
type Session<T> = DataTypes.Session<T>
type Store<T> = ProfileStore.ProfileStore<T>
type Profile<T> = ProfileStore.Profile<T>

-- PRIVATE FUNCTIONS
const function loadProfile<T>(store: Store<T>, key: string, userId: number): (Profile<T>?, string?)
    const profile = store:StartSessionAsync(key, {})

    if profile == nil then return nil, "Profile returned nil for player" end

    profile:AddUserId(userId)
    profile:Reconcile()

    return profile, nil
end

const function unloadProfile<T>(profile: Profile<T>) profile:EndSession() end

-- PUBLIC MODULE
const ProfileStoreProvider = {}

function ProfileStoreProvider.CreateStore<T>(name: string, data: T): DataProviderInterface<T>
    -- have to cast
    -- because ProfileStore has terrible types
    const store = ProfileStore.New(name, data) :: Store<T> -- will not get gc'd

    return {
        Load = function(key: string, userId: number): (Session<T>?, string?)
            const profile, err = loadProfile(store, key, userId)

            if not profile then
                return nil, err
            else
                return
                    {
                        Get = function() return profile.Data end,
                        Update = function(callback: (T) -> T) profile.Data = callback(profile.Data) end,
                        Unload = function() unloadProfile(profile :: Profile<T>) end,
                    },
                    nil
            end
        end,
    }
end

return ProfileStoreProvider
