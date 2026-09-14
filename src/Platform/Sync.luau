--!strict
-- IMPORTED MODULES
const Pancakes = require "@pkg/Pancakes"
const Signal = require "@pkg/Signal"

-- TYPES
type Signal<T> = Signal.Signal<T>
type AnyTable = { [any]: any }

export type Sync<T> = {
    Changed: Signal<T>,
    Push: (self: Sync<T>, newData: T) -> buffer?,
    Snapshot: (self: Sync<T>) -> buffer?,
    Apply: (self: Sync<T>, buf: buffer) -> (),
    Get: (self: Sync<T>) -> T?,
    Destroy: (self: Sync<T>) -> (),
}

type SyncInternal<T> = {
    _snapshot: T,
    _frozen: T?,
    _destroyed: boolean,
    Changed: Signal<T>,
}

-- CONSTANTS
const NIL_SENTINEL = "__nil__"

-- PRIVATE FUNCTIONS
const function deepClone(source: AnyTable): AnyTable
    const result: AnyTable = {}

    for key, value in source do
        if typeof(value) == "table" then
            result[key] = deepClone(value)
        else
            result[key] = value
        end
    end

    return result
end

const function deepFreeze(source: AnyTable): AnyTable
    for _, value in source do
        if typeof(value) == "table" then deepFreeze(value) end
    end

    return table.freeze(source)
end

const function apply(target: AnyTable, patch: AnyTable)
    for key, value in patch do
        const existing = target[key]

        if value == NIL_SENTINEL then
            target[key] = nil
        elseif typeof(value) == "table" and typeof(existing) == "table" then
            apply(existing, value)
        else
            target[key] = value
        end
    end
end

const function diff(previous: AnyTable, current: AnyTable): AnyTable
    const diffed: AnyTable = {}

    for key, value in current do
        const old = previous[key]

        if typeof(value) == "table" and typeof(old) == "table" then
            const nested = diff(old, value)

            if next(nested) ~= nil then diffed[key] = nested end
        elseif old ~= value then
            diffed[key] = value
        end
    end

    for key in previous do
        if current[key] == nil then diffed[key] = NIL_SENTINEL end
    end

    return diffed
end

const function frozenView<T>(self: SyncInternal<T>): T
    local frozen = self._frozen

    if not frozen then
        frozen = deepFreeze(deepClone(self._snapshot :: any)) :: any
        self._frozen = frozen
    end

    return frozen :: T
end

-- PRIVATE MODULE
const Impl = {}
Impl.__index = Impl

function Impl.Push<T>(self: SyncInternal<T>, newData: T): buffer?
    if self._destroyed then return nil end

    const patch = diff(self._snapshot :: any, newData :: any)
    -- Clone so the snapshot cannot alias a table the caller keeps mutating.
    self._snapshot = deepClone(newData :: any) :: any
    self._frozen = nil

    return Pancakes.SerializeAuto(patch)
end

function Impl.Snapshot<T>(self: SyncInternal<T>): buffer?
    if self._destroyed then return nil end

    -- push but with currently saved snapshot
    return Pancakes.SerializeAuto(self._snapshot)
end

function Impl.Apply<T>(self: SyncInternal<T>, buf: buffer)
    if self._destroyed then return end

    const patch = Pancakes.DeserializeAuto(buf)

    -- apply buffer to snapshot
    apply(self._snapshot :: any, patch)
    self._frozen = nil

    self.Changed:Fire(frozenView(self))
end

function Impl.Get<T>(self: SyncInternal<T>): T?
    if self._destroyed then return nil end

    return frozenView(self)
end

function Impl.Destroy<T>(self: SyncInternal<T>)
    if self._destroyed then return end

    self._destroyed = true
    self._frozen = nil
    self.Changed:Destroy()
end

-- PUBLIC MODULE
const Sync = {}

function Sync.new<T>(initialData: T?): Sync<T>
    const changed: Signal<T> = Signal.new()

    const data: SyncInternal<T> = {
        _snapshot = (if initialData ~= nil then deepClone(initialData :: any) else {}) :: any,
        _frozen = nil,
        _destroyed = false,
        Changed = changed,
    }

    return (setmetatable(data, Impl) :: any) :: Sync<T>
end

return Sync
