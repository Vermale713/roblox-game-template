--!strict
-- SERVICES
const CollectionService = game:GetService "CollectionService"
const RunService = game:GetService "RunService"

-- IMPORTED MODULES
const TableTypes = require "@base/TableTypes"
const Water = require "@platform/Water"

-- TYPES
type Set<T> = TableTypes.Set<T>

-- CONSTANTS
const WATER_QUERY = "MeshPart.Water"
const UPDATE_DISTANCE = 300
-- Parts go inactive only this far past UPDATE_DISTANCE, so they don't flip back and forth at the edge.
const UPDATE_HYSTERESIS = 20
const RANGE_CHECK_INTERVAL = 0.5

-- PRIVATE STATE
const _waterCollection = CollectionService:CreateCollection(WATER_QUERY, workspace)
const _waters: Set<MeshPart> = {}
const _activeRender: Set<MeshPart> = {}
const _inactiveRender: Set<MeshPart> = {}
local _nextRangeCheck = 0

-- PRIVATE FUNCTIONS
-- Distance to the nearest point on the part rather than its centre, so a long river stays active while you're on it.
const function distanceToPart(part: MeshPart, focus: Vector3): number
    const localFocus = part.CFrame:PointToObjectSpace(focus)
    const half = part.Size / 2
    const nearest = Vector3.new(
        math.clamp(localFocus.X, -half.X, half.X),
        math.clamp(localFocus.Y, -half.Y, half.Y),
        math.clamp(localFocus.Z, -half.Z, half.Z)
    )
    return (localFocus - nearest).Magnitude
end

const function refreshRange(focus: Vector3)
    for mesh in _activeRender do
        if distanceToPart(mesh, focus) <= UPDATE_DISTANCE + UPDATE_HYSTERESIS then continue end
        _activeRender[mesh] = nil
        _inactiveRender[mesh] = true
    end

    for mesh in _inactiveRender do
        if distanceToPart(mesh, focus) > UPDATE_DISTANCE then continue end
        _inactiveRender[mesh] = nil
        _activeRender[mesh] = true
    end
end

-- PRIVATE MODULE
function _waterCollection.OnAdded(mesh: MeshPart)
    if _waters[mesh] then return end

    Water.new(mesh)
    _waters[mesh] = true

    -- Starts inactive; forcing a range check next frame activates it if it's close.
    _inactiveRender[mesh] = true
    _nextRangeCheck = 0
end

function _waterCollection.OnRemoved(mesh: MeshPart)
    if not _waters[mesh] then return end

    -- A part that streams back in is a new instance, so this one is forgotten. Water keeps its mesh for a while so
    -- the new instance can reuse it.
    Water.Release(mesh)
    _waters[mesh] = nil
    _activeRender[mesh] = nil
    _inactiveRender[mesh] = nil
end

-- PUBLIC MODULE
const WaterController = {}

function WaterController.OnStart()
    RunService.PreRender:Connect(function()
        const camera = workspace.CurrentCamera
        if not camera then return end

        const clock = os.clock()
        if clock >= _nextRangeCheck then
            _nextRangeCheck = clock + RANGE_CHECK_INTERVAL
            refreshRange(camera.CFrame.Position)
        end

        const sync = workspace:GetServerTimeNow()
        for mesh in _activeRender do
            Water.Update(mesh, sync)
        end
    end)
end

return WaterController
