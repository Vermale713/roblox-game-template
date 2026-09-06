export type DataProviderInterface<T> = {
    Load: (string, number) -> (boolean, T),
    Unload: (T) -> (boolean, string),
}

export type DataProviderModuleInterface<T> = { CreateStore: (string) -> DataProviderInterface<T> }

return nil
