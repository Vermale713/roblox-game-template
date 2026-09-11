--!strict
export type LoadStatus = "Ok" | "Already-Loaded" | "Pending" | "Left" | "Failed"

export type Session<T> = {
    Get: () -> T,
    Update: ((T) -> ()) -> (),
    IsActive: () -> boolean,
    OnEnd: (() -> ()) -> (),
    Save: () -> (),
    Unload: () -> (),
}

export type DataProviderInterface<T> = { Load: (string, number) -> (Session<T>?, string?) }

export type DataProviderModuleInterface = { CreateStore: <T>(string, T) -> DataProviderInterface<T> }

return nil
