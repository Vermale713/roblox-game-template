-- IMPORTED MODULES
const ProfileStore = require "@spkg/ProfileStore"
const DataTypes = require "@types/DataTypes"

-- TYPES
type DataProviderInterface<T> = DataTypes.DataProviderInterface<T>
type Store<T> = ProfileStore.ProfileStore<T>
type Profile<T> = ProfileStore.Profile<T>

-- PRIVATE FUNCTIONS
const function loadProfile<T>(store: Store<T>, key: string, userId: number): (boolean, Profile<T> | string)
    const profile = store:StartSessionAsync(key, {})

    if profile == nil then return false, "Profile returned nil for player" end

    profile:AddUserId(userId)
    profile:Reconcile()

    return true, profile
end

const function unloadProfile<T>(store: Store<T>, profile: Profile<T>)
    profile:EndSession()
    return true, ""
end

-- PUBLIC MODULE
const ProfileStoreProvider = {}

function ProfileStoreProvider.CreateStore<T>(name: string, data: T): DataProviderInterface<T>
    -- have to cast
    -- because ProfileStore has terrible types
    const store = ProfileStore.New(name, data) :: Store<T> -- will not get gc'd

    return {
        Load = function(key: string, userId: number): (boolean, Profile<T> | string)
            const success, res = loadProfile(store, key, userId)

            return success, res :: Profile<T> | string
        end,
        Unload = function(profile: Profile<T>) return unloadProfile(store, profile) end,
    }
end

return ProfileStoreProvider
