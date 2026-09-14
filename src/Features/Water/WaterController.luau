--!strict
-- SERVICES
const CollectionService = game:GetService "CollectionService"
const RunService = game:GetService "RunService"

-- IMPORTED MODULES
const TableTypes = require "@base/TableTypes"
const Water = require "@platform/Water"

-- TYPES
type Dictionary<T, K> = TableTypes.Dictionary<T, K>
type Water = Water.Water

-- CONSTANTS
const WATER_QUERY = "MeshPart.Water"
const UPDATE_DISTANCE = 300

-- PRIVATE STATE
const _waterCollection = CollectionService:CreateCollection(WATER_QUERY, workspace)
const _activeRender = {}
const _inactiveRender: Dictionary<BasePart, Water> = {}
const _waters: Dictionary<BasePart, Water> = {}

-- PRIVATE FUNCTIONS
const function getFocus(fallback: BasePart): Vector3
    const camera = workspace.CurrentCamera
    return if camera then camera.CFrame.Position else fallback.Position
end

-- PRIVATE MODULE
function _waterCollection.OnAdded(mesh: MeshPart)
    local water = _waters[mesh]
    if not water then
        water = Water.new(mesh)
        _waters[mesh] = water
    end

    water:StreamIn(getFocus(mesh))
end

function _waterCollection.OnRemoved(mesh: MeshPart)
    const water = _waters[mesh]
    if not water then return end

    -- A part that streams back in is usually a new instance, so don't keep the old object around.
    water:Destroy()
    _waters[mesh] = nil
end

-- PUBLIC MODULE
const WaterController = {}

function WaterController.OnStart()
    RunService.Heartbeat:Connect(function()
        const camera = workspace.CurrentCamera
        if not camera then return end

        const now = workspace:GetServerTimeNow()
        const focus = camera.CFrame.Position

        for part, water in _waters do
            if not water:IsRendered() then continue end
            if (part.Position - focus).Magnitude > UPDATE_DISTANCE + part.Size.Magnitude / 2 then continue end

            water:Update(now, focus)
        end
    end)
end

return WaterController
