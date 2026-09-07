export type Session<T> = { Get: () -> T, Update: ((T) -> T) -> (), Unload: () -> () }

export type DataProviderInterface<T> = { Load: (string, number) -> (Session<T>?, string?) }

export type DataProviderModuleInterface = { CreateStore: <T>(string, T) -> DataProviderInterface<T> }

return nil
