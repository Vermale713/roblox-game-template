-- SERVICES
const LogService = game:GetService "LogService"

-- TYPES
type Lifecycle = { Method: string, Async: boolean? }
type Matchers = { string }
type SingletonModules = { [string]: ModuleScript }
type Singletons = {
    [string]: { Dependencies: { string }?, [string]: () -> ()? },
}
type SortedSingletons = { string }
type StartOpts = {
    Root: Instance,
    SingletonMatcher: Matchers,
    Lifecycles: { Lifecycle },
}

-- PRIVATE STATE
const _singletons: Singletons = {}
const _singletonModules: SingletonModules = {}
local _sortedSingletons: SortedSingletons = {}

-- PRIVATE FUNCTIONS
const function matchesAny(name: string, matchers: Matchers): boolean
    for _, matcher in matchers do
        if name:match(matcher) then return true end
    end

    return false
end

const function topologicalSort(unsorted: any): SortedSingletons
    local sizeOfUnsorted = 0

    const inDegree: { [string]: number } = {}
    const dependents: { [string]: { string } } = {}

    -- set all values to 0
    for name in unsorted do
        sizeOfUnsorted += 1

        inDegree[name] = 0
        dependents[name] = {}
    end

    for name, singleton in unsorted do
        for _, dependency in singleton.Dependencies or {} do
            if not unsorted[dependency] then
                LogService:Error(
                    "[Loader] Unknown dependency '{dependency}' required by '{name}'.",
                    {
                        dependency = dependency,
                        name = name,
                    }
                )
            end

            inDegree[name] += 1
            table.insert(dependents[dependency], name)
        end
    end

    const ready: { string } = {}

    for name, degree in inDegree do
        if degree == 0 then table.insert(ready, name) end
    end

    const sorted: { string } = {}

    while #ready > 0 do
        const name = table.remove(ready) :: string

        table.insert(sorted, name)

        for _, dependent in dependents[name] do
            inDegree[dependent] -= 1
            if inDegree[dependent] == 0 then table.insert(ready, dependent) end
        end
    end

    if #sorted ~= sizeOfUnsorted then LogService:Error "[Loader] Circular dependency detected." end

    return sorted
end

-- PUBLIC MODULE
const Loader = {}

function Loader.Start(opts: StartOpts)
    const root = opts.Root
    const matchers = opts.SingletonMatcher
    const lifecycles = opts.Lifecycles

    const descendants = root:GetDescendants()

    -- find and load/register all singleton modules
    for _, descendant in descendants do
        -- check for module script and if parented to nil
        -- for type refining
        if not descendant:IsA "ModuleScript" then continue end

        -- check if its a singleton by checking name for matchers
        if not matchesAny(descendant.Name, matchers) then continue end

        -- check if its already registered
        if _singletons[descendant.Name] then
            const duplicate = _singletonModules[descendant.Name]

            LogService:Warn(
                "[Loader] Singleton '{name}' is already registered at '{originalPath}'. Skipping duplicate at '{duplicatePath}'.",
                {
                    name = descendant.Name,
                    originalPath = duplicate:GetFullName(),
                    duplicatePath = descendant:GetFullName(),
                }
            )
            continue
        end

        -- wrap in parentheses to remove type error
        -- regarding unsupported path
        const requiredModule = (require)(descendant)

        _singletons[descendant.Name] = requiredModule
        _singletonModules[descendant.Name] = descendant
    end

    -- sort the singletons
    _sortedSingletons = topologicalSort(_singletons)

    -- start the lifecycles
    for _, lifecycle in lifecycles do
        const method = lifecycle.Method

        for _, name in _sortedSingletons do
            const singleton = _singletons[name]
            const callback = singleton[method]

            if not callback then continue end

            if lifecycle.Async then
                task.spawn(callback)
            else
                callback()
            end
        end
    end
end

return Loader
