--!strict
-- SERVICES
const AssetService = game:GetService "AssetService"
const LogService = game:GetService "LogService"
const MaterialService = game:GetService "MaterialService"

-- TYPES
type Wave = {
    Length: number,
    DirX: number,
    DirZ: number,
    K: number,
    Omega: number,
    Amplitude: number,
    Offset: number,
}

type Config = {
    WaveHeight: number,
    CellSize: number,
    LodDistance: number,
    TextureScale: number,
    MaterialTile: number,
    FlowX: number,
    FlowZ: number,
    Variation: number,
    VariationScale: number,
    -- Sorted longest first.
    Waves: { Wave },
}

-- A region of the part's single mesh with its own level of detail. When the level changes its triangles are
-- swapped in place inside the shared EditableMesh.
type Patch = {
    GridX: number,
    GridZ: number,
    CenterX: number,
    CenterZ: number,
    SizeX: number,
    SizeZ: number,
    Distance: number,
    Want: number,
    -- -1 until the patch has geometry.
    Level: number,
    CellsX: number,
    CellsZ: number,
    FaceIds: { number },
    VertexIds: { number },
    NormalIds: { number },
    UvIds: { number },
    -- Surface space, relative to the part centre.
    LocalX: { number },
    LocalZ: { number },
    WorldX: { number },
    WorldZ: { number },
    Heights: { number },
    NormalX: { number },
    NormalY: { number },
    NormalZ: { number },
    -- TextureScale the UVs were last written with; they are rewritten when it changes or the texture flows.
    UvScale: number,
}

type State = {
    Part: MeshPart,
    Config: Config,
    -- Identifies the part across streaming, where it comes back as a new instance.
    Key: string,
    -- When the state was last released into the cache, so an old expiry timer can tell it is stale.
    ReleasedAt: number,
    -- Bumped on every rebuild and on Destroy so a build that yielded can tell it is stale.
    Token: number,
    Building: boolean,
    RetryAt: number,
    -- The part's CFrame when it was added. The part itself is slid around to flow materials, so this is the
    -- reference for everything else.
    Origin: CFrame,
    -- Last camera position; drives LOD and how much small-wave detail is drawn.
    Focus: Vector3,
    Mesh: EditableMesh?,
    -- The MeshPart built from Mesh, kept so a part that streams back in can have it applied without rebuilding.
    Source: MeshPart?,
    Patches: { Patch },
    ByDistance: { Patch },
    PatchesX: number,
    PatchesZ: number,
    BaseCellsX: number,
    BaseCellsZ: number,
    MaxLevel: number,
    Triangles: number,
    -- How far the part currently sits from Origin (surface space) to slide part-mapped materials.
    ShiftX: number,
    ShiftZ: number,
    Connection: RBXScriptConnection?,
}

-- ALIASES

-- CONSTANTS
-- Required attributes; the part fails to load without them.
const CELL_SIZE_ATTRIBUTE = "CellSize"
const WAVE_HEIGHT_ATTRIBUTE = "WaveHeight"
const WAVE_LENGTH_ATTRIBUTE = "WaveLength"
const WAVE_SPEED_ATTRIBUTE = "WaveSpeed"
const WAVE_DIRECTION_ATTRIBUTE = "WaveDirection"

-- Optional attributes.
const FLOW_SPEED_ATTRIBUTE = "FlowSpeed"
const FLOW_DIRECTION_ATTRIBUTE = "FlowDirection"
const TEXTURE_SCALE_ATTRIBUTE = "TextureScale"
const WAVE_SEED_ATTRIBUTE = "WaveSeed"
const WAVE_VARIATION_ATTRIBUTE = "WaveVariation"
const LOD_DISTANCE_ATTRIBUTE = "LodDistance"

-- Optional appearance attributes; any that aren't set leave the part's own property as authored.
const WATER_COLOR_ATTRIBUTE = "WaterColor"
const WATER_TRANSPARENCY_ATTRIBUTE = "WaterTransparency"
const WATER_REFLECTANCE_ATTRIBUTE = "WaterReflectance"
const WATER_MATERIAL_ATTRIBUTE = "WaterMaterial"
const WATER_MATERIAL_VARIANT_ATTRIBUTE = "WaterMaterialVariant"
const WATER_TEXTURE_ATTRIBUTE = "WaterTexture"

const WAVE_COUNT = 8
-- The shortest wave, as a fraction of WaveLength.
const WAVE_SHORTEST = 0.15
-- Degrees the shortest waves may stray from WaveDirection; longer waves stray less.
const WAVE_SPREAD = 55
-- Amplitude grows with length to this power; below 1 keeps the short waves visible.
const WAVE_AMPLITUDE_EXPONENT = 0.8
-- Calm/rough regions are this many WaveLengths across, and drift at this many noise units per second.
const VARIATION_SCALE = 4
const VARIATION_SPEED = 0.03
-- math.noise is periodic over 256 units, so time can be wrapped to this without a jump.
const NOISE_PERIOD = 256
-- Waves need this many mesh cells per wavelength to show; they fade in between MIN and FULL.
const FADE_MIN_SAMPLES = 2.5
const FADE_FULL_SAMPLES = 5

const DEFAULT_LOD_DISTANCE = 100
const DEFAULT_TEXTURE_SCALE = 16
const DEFAULT_FLOW_SPEED = 0
const DEFAULT_WAVE_SEED = 0
const DEFAULT_WAVE_VARIATION = 0.5

const MIN_CELL_SIZE = 0.5
const MIN_TEXTURE_SCALE = 0.1
-- Cells per patch side at full detail; each LOD level halves it. Must be a power of two.
const PATCH_CELLS = 32
-- A patch only drops/raises a level once the distance is this far past the threshold, so it doesn't flicker.
const LOD_HYSTERESIS = 1.15
-- Kept under the per-EditableMesh triangle cap; far patches are coarsened first to fit.
const MAX_TRIANGLES = 20000
-- Patch rebuilds are synchronous, so spread them over frames.
const MAX_REBUILDS_PER_FRAME = 2
const BUILD_RETRY_DELAY = 5
-- Seconds a released part's mesh is kept for the part to stream back in before it's freed.
const CACHE_LIFETIME = 30

-- PRIVATE STATE
const _states: { [MeshPart]: State } = {}
-- Released states by Key, waiting for their part to stream back in.
const _cache: { [string]: State } = {}

-- PRIVATE FUNCTIONS
const function numberAttribute(instance: Instance, name: string, default: number): number
    const value = instance:GetAttribute(name)
    return if typeof(value) == "number" then value else default
end

const function requiredNumberAttribute(part: MeshPart, name: string): number
    const value = part:GetAttribute(name)
    if typeof(value) ~= "number" then
        LogService:Error(
            "[Water] Required number attribute '{attribute}' is missing from '{part}'.",
            { attribute = name, part = part:GetFullName() }
        )
    end
    return value :: number
end

const function findMaterialVariant(name: string): MaterialVariant?
    if name == "" then return nil end

    const variant = MaterialService:FindFirstChild(name, true)
    return if variant and variant:IsA "MaterialVariant" then variant else nil
end

-- Water appearance attributes override the part's own properties; any that aren't set leave the part as authored.
const function applyAppearance(part: MeshPart)
    const color = part:GetAttribute(WATER_COLOR_ATTRIBUTE)
    if typeof(color) == "Color3" then part.Color = color end

    const transparency = part:GetAttribute(WATER_TRANSPARENCY_ATTRIBUTE)
    if typeof(transparency) == "number" then part.Transparency = transparency end

    const reflectance = part:GetAttribute(WATER_REFLECTANCE_ATTRIBUTE)
    if typeof(reflectance) == "number" then part.Reflectance = reflectance end

    const material = part:GetAttribute(WATER_MATERIAL_ATTRIBUTE)
    if typeof(material) == "string" then
        const ok, item = pcall(function() return (Enum.Material :: any)[material] end)
        if ok and typeof(item) == "EnumItem" then part.Material = item :: any end
    end

    -- A variant only shows when the part's Material matches its BaseMaterial, so that is taken from the variant.
    const variantName = part:GetAttribute(WATER_MATERIAL_VARIANT_ATTRIBUTE)
    if typeof(variantName) == "string" then
        const variant = findMaterialVariant(variantName)
        if variant then
            part.Material = variant.BaseMaterial
            part.MaterialVariant = variant.Name
        elseif variantName ~= "" then
            warn(`[Water] MaterialVariant '{variantName}' for {part:GetFullName()} was not found under MaterialService`)
        end
    end

    -- Accepts a bare asset id (number or digits) or a full content URI.
    const texture = part:GetAttribute(WATER_TEXTURE_ATTRIBUTE)
    if typeof(texture) == "number" then
        part.TextureContent = Content.fromUri(`rbxassetid://{texture}`)
    elseif typeof(texture) == "string" and texture ~= "" then
        part.TextureContent = Content.fromUri(if texture:match "^%d+$" then `rbxassetid://{texture}` else texture)
    end
end

const function readConfig(part: MeshPart): Config
    const waveHeight = math.max(requiredNumberAttribute(part, WAVE_HEIGHT_ATTRIBUTE), 0)
    const waveLength = math.max(requiredNumberAttribute(part, WAVE_LENGTH_ATTRIBUTE), 1)
    const waveSpeed = requiredNumberAttribute(part, WAVE_SPEED_ATTRIBUTE)
    const waveDegrees = requiredNumberAttribute(part, WAVE_DIRECTION_ATTRIBUTE)
    const waveDirection = math.rad(waveDegrees)
    const flowSpeed = numberAttribute(part, FLOW_SPEED_ATTRIBUTE, DEFAULT_FLOW_SPEED)
    -- Flows with the waves unless told otherwise.
    const flowDirection = math.rad(numberAttribute(part, FLOW_DIRECTION_ATTRIBUTE, waveDegrees))
    const textureScale = math.max(numberAttribute(part, TEXTURE_SCALE_ATTRIBUTE, DEFAULT_TEXTURE_SCALE), MIN_TEXTURE_SCALE)

    -- Seeded so every client (and every part sharing a seed) generates the same waves.
    const random = Random.new(numberAttribute(part, WAVE_SEED_ATTRIBUTE, DEFAULT_WAVE_SEED))
    const waves: { Wave } = {}
    local amplitudeTotal = 0

    for index = 1, WAVE_COUNT do
        const t = (index - 1) / (WAVE_COUNT - 1)
        -- Lengths fall off geometrically and are jittered so no two waves share a simple ratio, which is what makes
        -- a sum of waves look tiled.
        const length = waveLength * WAVE_SHORTEST ^ t * random:NextNumber(0.85, 1.15)
        const angle = waveDirection + math.rad(random:NextNumber(-WAVE_SPREAD, WAVE_SPREAD) * (0.3 + 0.7 * t))
        const k = (2 * math.pi) / length
        const amplitude = length ^ WAVE_AMPLITUDE_EXPONENT
        amplitudeTotal += amplitude

        table.insert(
            waves,
            {
                Length = length,
                DirX = math.cos(angle),
                DirZ = math.sin(angle),
                K = k,
                -- Real deep-water waves travel at a speed proportional to the square root of their length.
                Omega = k * waveSpeed * math.sqrt(length / waveLength),
                Amplitude = amplitude,
                Offset = random:NextNumber(0, 2 * math.pi),
            }
        )
    end

    -- Amplitudes sum to WaveHeight so it stays the highest possible peak.
    for _, wave in waves do
        wave.Amplitude = waveHeight * wave.Amplitude / amplitudeTotal
    end
    table.sort(waves, function(a: Wave, b: Wave) return a.Length > b.Length end)

    const variant = findMaterialVariant(part.MaterialVariant)

    return {
        WaveHeight = waveHeight,
        CellSize = math.max(requiredNumberAttribute(part, CELL_SIZE_ATTRIBUTE), MIN_CELL_SIZE),
        LodDistance = math.max(numberAttribute(part, LOD_DISTANCE_ATTRIBUTE, DEFAULT_LOD_DISTANCE), 1),
        TextureScale = textureScale,
        -- Built-in materials don't expose their tile size, so TextureScale stands in for it.
        MaterialTile = if variant then math.max(variant.StudsPerTile, MIN_TEXTURE_SCALE) else textureScale,
        FlowX = math.cos(flowDirection) * flowSpeed,
        FlowZ = math.sin(flowDirection) * flowSpeed,
        Variation = math.clamp(numberAttribute(part, WAVE_VARIATION_ATTRIBUTE, DEFAULT_WAVE_VARIATION), 0, 1),
        VariationScale = waveLength * VARIATION_SCALE,
        Waves = waves,
    }
end

-- Height and its world-space slope (dh/dx, dh/dz) at a point. Everything depends only on world XZ, time and
-- `cellSize`, so a vertex shared by two patches gets the same result from both. `cellSize` is the mesh spacing
-- around the point, used to drop waves too short to draw; pass 0 for the full surface.
const function sampleSurface(config: Config, x: number, z: number, now: number, cellSize: number): (number, number, number)
    -- Slow noise makes some regions calmer than others so the pattern doesn't read as uniform.
    local modulation = 1
    const variation = config.Variation
    if variation > 0 then
        const scale = config.VariationScale
        const noise = math.noise(x / scale, z / scale, (now * VARIATION_SPEED) % NOISE_PERIOD)
        modulation = 1 - variation * math.clamp(0.5 - noise, 0, 1)
    end

    local height, slopeX, slopeZ = 0, 0, 0
    for _, wave in config.Waves do
        local amplitude = wave.Amplitude * modulation

        if cellSize > 0 then
            const samples = wave.Length / cellSize
            -- Sorted longest first, so every remaining wave is too short as well.
            if samples <= FADE_MIN_SAMPLES then break end
            if samples < FADE_FULL_SAMPLES then
                amplitude *= (samples - FADE_MIN_SAMPLES) / (FADE_FULL_SAMPLES - FADE_MIN_SAMPLES)
            end
        end

        const phase = (wave.DirX * x + wave.DirZ * z) * wave.K - wave.Omega * now + wave.Offset
        const slope = amplitude * wave.K * math.cos(phase)

        height += amplitude * math.sin(phase)
        slopeX += slope * wave.DirX
        slopeZ += slope * wave.DirZ
    end
    return height, slopeX, slopeZ
end

const function getFocus(part: MeshPart): Vector3
    const camera = workspace.CurrentCamera
    return if camera then camera.CFrame.Position else part.Position
end

const function log2(value: number): number return math.floor(math.log(value, 2) + 0.5) end

const function cellsForLevel(baseCells: number, level: number): number return math.max(baseCells // 2 ^ level, 1) end

const function trianglesForLevel(state: State, level: number): number
    return 2 * cellsForLevel(state.BaseCellsX, level) * cellsForLevel(state.BaseCellsZ, level)
end

-- Level 0 inside LodDistance, then one level coarser each time the distance doubles.
const function levelForDistance(distance: number, lodDistance: number, maxLevel: number): number
    if distance < lodDistance then return 0 end
    return math.min(math.floor(math.log(distance / lodDistance, 2)) + 1, maxLevel)
end

-- Distance from the focus to the nearest point on the patch, in surface space.
const function patchDistance(patch: Patch, localFocus: Vector3): number
    const dx = math.max(math.abs(localFocus.X - patch.CenterX) - patch.SizeX / 2, 0)
    const dz = math.max(math.abs(localFocus.Z - patch.CenterZ) - patch.SizeZ / 2, 0)
    const dy = localFocus.Y
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

const function neighborCells(state: State, gridX: number, gridZ: number, alongX: boolean): number?
    if gridX < 0 or gridX >= state.PatchesX or gridZ < 0 or gridZ >= state.PatchesZ then return nil end

    const patch = state.Patches[gridZ * state.PatchesX + gridX + 1]
    if patch.Level < 0 then return nil end

    return if alongX then patch.CellsX else patch.CellsZ
end

-- Where a coarser neighbour shares this edge, the in-between vertices it doesn't have are placed on the straight
-- line between the ones it does, so the two patches meet without a gap. Normals get the same treatment so the
-- shading matches what the coarse side interpolates along that edge.
const function stitchEdge(values: { number }, cells: number, otherCells: number?, start: number, stride: number)
    if not otherCells or otherCells >= cells then return end

    const ratio = cells // otherCells
    for step = 1, cells - 1 do
        const offset = step % ratio
        if offset == 0 then continue end

        const from = values[start + (step - offset) * stride]
        const to = values[start + (step - offset + ratio) * stride]
        values[start + step * stride] = from + (to - from) * (offset / ratio)
    end
end

const function stitchPatch(
    patch: Patch,
    values: { number },
    left: number?,
    right: number?,
    bottom: number?,
    top: number?
)
    const cellsX = patch.CellsX
    const cellsZ = patch.CellsZ
    const rowWidth = cellsX + 1

    stitchEdge(values, cellsZ, left, 1, rowWidth)
    stitchEdge(values, cellsZ, right, cellsX + 1, rowWidth)
    stitchEdge(values, cellsX, bottom, 1, 1)
    stitchEdge(values, cellsX, top, cellsZ * rowWidth + 1, 1)
end

const function clearPatch(patch: Patch)
    patch.Level = -1
    table.clear(patch.FaceIds)
    table.clear(patch.VertexIds)
    table.clear(patch.NormalIds)
    table.clear(patch.UvIds)
    table.clear(patch.LocalX)
    table.clear(patch.LocalZ)
    table.clear(patch.WorldX)
    table.clear(patch.WorldZ)
    table.clear(patch.Heights)
    table.clear(patch.NormalX)
    table.clear(patch.NormalY)
    table.clear(patch.NormalZ)
end

-- Replaces the patch's triangles in the mesh with a grid at `level`. Old vertices are left for RemoveUnused.
const function buildPatch(state: State, mesh: EditableMesh, patch: Patch, level: number)
    for _, faceId in patch.FaceIds do
        mesh:RemoveFace(faceId)
    end
    state.Triangles -= #patch.FaceIds
    clearPatch(patch)

    const cellsX = cellsForLevel(state.BaseCellsX, level)
    const cellsZ = cellsForLevel(state.BaseCellsZ, level)
    const stepX = patch.SizeX / cellsX
    const stepZ = patch.SizeZ / cellsZ
    const rowWidth = cellsX + 1

    const vertexIds = patch.VertexIds
    const normalIds = patch.NormalIds
    const uvIds = patch.UvIds

    for iz = 0, cellsZ do
        for ix = 0, cellsX do
            const localX = patch.CenterX - patch.SizeX / 2 + ix * stepX
            const localZ = patch.CenterZ - patch.SizeZ / 2 + iz * stepZ
            const world = state.Origin:PointToWorldSpace(Vector3.new(localX, 0, localZ))

            table.insert(vertexIds, mesh:AddVertex(Vector3.new(localX, 0, localZ)))
            -- Placeholders; the next pose writes the real normals and UVs.
            table.insert(normalIds, mesh:AddNormal(Vector3.yAxis))
            table.insert(uvIds, mesh:AddUV(Vector2.zero))
            table.insert(patch.LocalX, localX)
            table.insert(patch.LocalZ, localZ)
            table.insert(patch.WorldX, world.X)
            table.insert(patch.WorldZ, world.Z)
            table.insert(patch.Heights, 0)
            table.insert(patch.NormalX, 0)
            table.insert(patch.NormalY, 1)
            table.insert(patch.NormalZ, 0)
        end
    end

    for iz = 0, cellsZ - 1 do
        for ix = 0, cellsX - 1 do
            const a = iz * rowWidth + ix + 1
            const b = a + rowWidth
            const c = a + 1
            const d = b + 1

            -- Wound so both triangles face +Y.
            const first = mesh:AddTriangle(vertexIds[a], vertexIds[b], vertexIds[c])
            mesh:SetFaceNormals(first, { normalIds[a], normalIds[b], normalIds[c] })
            mesh:SetFaceUVs(first, { uvIds[a], uvIds[b], uvIds[c] })
            table.insert(patch.FaceIds, first)

            const second = mesh:AddTriangle(vertexIds[c], vertexIds[b], vertexIds[d])
            mesh:SetFaceNormals(second, { normalIds[c], normalIds[b], normalIds[d] })
            mesh:SetFaceUVs(second, { uvIds[c], uvIds[b], uvIds[d] })
            table.insert(patch.FaceIds, second)
        end
    end

    patch.Level = level
    patch.CellsX = cellsX
    patch.CellsZ = cellsZ
    patch.UvScale = 0
    state.Triangles += #patch.FaceIds
end

const function refreshLevels(state: State, focus: Vector3)
    state.Focus = focus
    const localFocus = state.Origin:PointToObjectSpace(focus)
    const lodDistance = state.Config.LodDistance
    const maxLevel = state.MaxLevel
    local triangles = 0

    for _, patch in state.Patches do
        const distance = patchDistance(patch, localFocus)
        local want = levelForDistance(distance, lodDistance, maxLevel)

        const current = patch.Level
        if current >= 0 and want ~= current then
            const padded = levelForDistance(
                if want > current then distance / LOD_HYSTERESIS else distance * LOD_HYSTERESIS,
                lodDistance,
                maxLevel
            )

            if (want > current and padded <= current) or (want < current and padded >= current) then want = current end
        end

        patch.Distance = distance
        patch.Want = want
        triangles += trianglesForLevel(state, want)
    end

    if triangles <= MAX_TRIANGLES then return end

    -- Over budget: coarsen one level at a time, farthest patches first, until it fits.
    const byDistance = state.ByDistance
    table.sort(byDistance, function(a: Patch, b: Patch) return a.Distance > b.Distance end)

    local coarsened = true
    while triangles > MAX_TRIANGLES and coarsened do
        coarsened = false

        for _, patch in byDistance do
            if patch.Want >= maxLevel then continue end

            triangles += trianglesForLevel(state, patch.Want + 1) - trianglesForLevel(state, patch.Want)
            patch.Want += 1
            coarsened = true

            if triangles <= MAX_TRIANGLES then break end
        end
    end
end

const function rebuildPatches(state: State, mesh: EditableMesh)
    local remaining = MAX_REBUILDS_PER_FRAME

    -- Coarsen first so the triangles they free are available to the refinements.
    for _, patch in state.Patches do
        if remaining == 0 then break end
        if patch.Want <= patch.Level then continue end

        buildPatch(state, mesh, patch, patch.Want)
        remaining -= 1
    end

    while remaining > 0 do
        local nearest: Patch? = nil

        for _, patch in state.Patches do
            if patch.Want >= patch.Level then continue end
            if nearest and patch.Distance >= nearest.Distance then continue end

            const cost = trianglesForLevel(state, patch.Want) - #patch.FaceIds
            if state.Triangles + cost <= MAX_TRIANGLES then nearest = patch end
        end

        if not nearest then break end

        buildPatch(state, mesh, nearest, nearest.Want)
        remaining -= 1
    end

    if remaining < MAX_REBUILDS_PER_FRAME then mesh:RemoveUnused() end
end

const function pose(state: State, mesh: EditableMesh, now: number)
    const config = state.Config
    const origin = state.Origin

    -- Materials and MaterialVariants are mapped relative to the part and ignore UVs, so they flow by sliding the
    -- part and moving the vertices back by the same amount. Wrapped to one tile so it never drifts far.
    const tile = config.MaterialTile
    const flow = origin:VectorToObjectSpace(Vector3.new(config.FlowX, 0, config.FlowZ))
    const shiftX = (-flow.X * now) % tile
    const shiftZ = (-flow.Z * now) % tile

    if shiftX ~= state.ShiftX or shiftZ ~= state.ShiftZ then
        state.Part.CFrame = origin * CFrame.new(-shiftX, 0, -shiftZ)
        state.ShiftX = shiftX
        state.ShiftZ = shiftZ
    end

    -- UVs come from world XZ so textures line up across patches and parts. The flow offset is wrapped to one tile
    -- because server time is in the billions and would lose precision on the GPU.
    const scale = config.TextureScale
    const flowing = config.FlowX ~= 0 or config.FlowZ ~= 0
    const offsetU = (config.FlowX * now) % scale
    const offsetV = (config.FlowZ * now) % scale

    -- For rotating world-space normals into the mesh's space.
    const right = origin.XVector
    const up = origin.YVector
    const back = origin.ZVector

    -- A continuous stand-in for the mesh spacing at a distance (the finest spacing that LOD level could have), so
    -- small waves fade out smoothly with distance instead of changing abruptly at patch borders.
    const focus = state.Focus
    const surfaceY = origin.Position.Y
    const baseCell = config.CellSize
    const inverseLodDistance = 1 / config.LodDistance

    for _, patch in state.Patches do
        if patch.Level < 0 then continue end

        const heights = patch.Heights
        const normalX = patch.NormalX
        const normalY = patch.NormalY
        const normalZ = patch.NormalZ
        const worldX = patch.WorldX
        const worldZ = patch.WorldZ

        -- Normals come from the wave slope rather than being averaged from triangles, so a vertex on a patch border
        -- gets the same normal on both sides.
        for index = 1, #heights do
            const x = worldX[index]
            const z = worldZ[index]
            const dx = x - focus.X
            const dy = surfaceY - focus.Y
            const dz = z - focus.Z
            const cellSize = baseCell * math.max(math.sqrt(dx * dx + dy * dy + dz * dz) * inverseLodDistance, 1)

            const height, slopeX, slopeZ = sampleSurface(config, x, z, now, cellSize)
            heights[index] = height

            const nx = right.Y - slopeX * right.X - slopeZ * right.Z
            const ny = up.Y - slopeX * up.X - slopeZ * up.Z
            const nz = back.Y - slopeX * back.X - slopeZ * back.Z
            const inverseLength = 1 / math.sqrt(nx * nx + ny * ny + nz * nz)
            normalX[index] = nx * inverseLength
            normalY[index] = ny * inverseLength
            normalZ[index] = nz * inverseLength
        end

        const leftCells = neighborCells(state, patch.GridX - 1, patch.GridZ, false)
        const rightCells = neighborCells(state, patch.GridX + 1, patch.GridZ, false)
        const bottomCells = neighborCells(state, patch.GridX, patch.GridZ - 1, true)
        const topCells = neighborCells(state, patch.GridX, patch.GridZ + 1, true)

        stitchPatch(patch, heights, leftCells, rightCells, bottomCells, topCells)
        stitchPatch(patch, normalX, leftCells, rightCells, bottomCells, topCells)
        stitchPatch(patch, normalY, leftCells, rightCells, bottomCells, topCells)
        stitchPatch(patch, normalZ, leftCells, rightCells, bottomCells, topCells)

        const localX = patch.LocalX
        const localZ = patch.LocalZ
        const normalIds = patch.NormalIds

        for index, vertexId in patch.VertexIds do
            mesh:SetPosition(vertexId, Vector3.new(localX[index] + shiftX, heights[index], localZ[index] + shiftZ))
            mesh:SetNormal(normalIds[index], Vector3.new(normalX[index], normalY[index], normalZ[index]))
        end

        if flowing or patch.UvScale ~= scale then
            for index, uvId in patch.UvIds do
                mesh:SetUV(uvId, Vector2.new((worldX[index] - offsetU) / scale, (worldZ[index] - offsetV) / scale))
            end
            patch.UvScale = scale
        end
    end
end

-- Water is static, so a part that streams back in has the same CFrame and Size as the instance it replaces.
const function cacheKey(part: MeshPart): string return `{part.CFrame}|{part.Size}` end

-- Overwrites the part's geometry with the source's. ApplyMesh also overwrites TextureContent with the source's empty
-- one, so it's put back afterwards.
const function applySource(part: MeshPart, source: MeshPart)
    const texture = part.TextureContent
    part:ApplyMesh(source)
    part.TextureContent = texture
    applyAppearance(part)
end

-- Yields while the engine builds the MeshPart, then overwrites the part's geometry with it.
const function buildSurface(state: State, token: number)
    const part = state.Part

    const createdOk, created = pcall(function() return AssetService:CreateEditableMesh {} end)
    if token ~= state.Token then return end

    if not createdOk or not created then
        warn(`[Water] Could not create EditableMesh for {part:GetFullName()}: {created}`)
        state.Building = false
        state.RetryAt = os.clock() + BUILD_RETRY_DELAY
        return
    end
    const mesh = created :: EditableMesh

    for _, patch in state.Patches do
        buildPatch(state, mesh, patch, patch.Want)
    end

    -- ApplyMesh stretches the mesh's bounds to the part's Size, so pinning two corners to the part's top and bottom
    -- keeps it at 1:1 scale. The first pose moves them back.
    const bounds = part.Size.Y / 2
    const first = state.Patches[1]
    const last = state.Patches[#state.Patches]
    const lastIndex = #last.VertexIds
    mesh:SetPosition(first.VertexIds[1], Vector3.new(first.LocalX[1], bounds, first.LocalZ[1]))
    mesh:SetPosition(last.VertexIds[lastIndex], Vector3.new(last.LocalX[lastIndex], -bounds, last.LocalZ[lastIndex]))

    const builtOk, built = pcall(function()
        return AssetService:CreateMeshPartAsync(
            Content.fromObject(mesh),
            { CollisionFidelity = Enum.CollisionFidelity.Box } :: { [string]: any }
        )
    end)

    if token ~= state.Token then
        -- A rebuild or Destroy ran while we were yielding.
        if builtOk and built then (built :: MeshPart):Destroy() end
        mesh:Destroy()
        return
    end

    state.Building = false

    if not builtOk or not built then
        warn(`[Water] Could not build surface for {part:GetFullName()}: {built}`)
        mesh:Destroy()
        for _, patch in state.Patches do
            clearPatch(patch)
        end
        state.Triangles = 0
        state.RetryAt = os.clock() + BUILD_RETRY_DELAY
        return
    end

    -- The EditableMesh must stay alive while applied.
    const source = built :: MeshPart
    applySource(part, source)

    state.Mesh = mesh
    state.Source = source
    pose(state, mesh, workspace:GetServerTimeNow())
end

const function startBuild(state: State)
    state.Building = true
    task.spawn(buildSurface, state, state.Token)
end

-- Lays out the patches; `focus` picks the starting detail.
const function layout(state: State, focus: Vector3)
    const size = state.Part.Size
    const cellSize = state.Config.CellSize
    const patchSize = cellSize * PATCH_CELLS

    const patchesX = math.max(math.ceil(size.X / patchSize), 1)
    const patchesZ = math.max(math.ceil(size.Z / patchSize), 1)
    const sizeX = size.X / patchesX
    const sizeZ = size.Z / patchesZ

    -- Powers of two so a coarser patch's vertices are always a subset of a finer neighbour's along a shared edge.
    const baseCellsX = 2 ^ log2(math.clamp(sizeX / cellSize, 1, PATCH_CELLS))
    const baseCellsZ = 2 ^ log2(math.clamp(sizeZ / cellSize, 1, PATCH_CELLS))

    state.PatchesX = patchesX
    state.PatchesZ = patchesZ
    state.BaseCellsX = baseCellsX
    state.BaseCellsZ = baseCellsZ
    state.MaxLevel = math.max(log2(baseCellsX), log2(baseCellsZ))
    state.Triangles = 0
    state.ShiftX = math.huge
    state.ShiftZ = math.huge
    state.RetryAt = 0

    for gridZ = 0, patchesZ - 1 do
        for gridX = 0, patchesX - 1 do
            const patch: Patch = {
                GridX = gridX,
                GridZ = gridZ,
                CenterX = -size.X / 2 + (gridX + 0.5) * sizeX,
                CenterZ = -size.Z / 2 + (gridZ + 0.5) * sizeZ,
                SizeX = sizeX,
                SizeZ = sizeZ,
                Distance = math.huge,
                Want = 0,
                Level = -1,
                CellsX = 0,
                CellsZ = 0,
                FaceIds = {},
                VertexIds = {},
                NormalIds = {},
                UvIds = {},
                LocalX = {},
                LocalZ = {},
                WorldX = {},
                WorldZ = {},
                Heights = {},
                NormalX = {},
                NormalY = {},
                NormalZ = {},
                UvScale = 0,
            }

            table.insert(state.Patches, patch)
            table.insert(state.ByDistance, patch)
        end
    end

    refreshLevels(state, focus)
end

-- Frees the mesh and patches; any build still yielding is discarded.
const function reset(state: State)
    state.Token += 1
    state.Building = false

    const mesh = state.Mesh
    state.Mesh = nil
    if mesh then mesh:Destroy() end

    const source = state.Source
    state.Source = nil
    if source then source:Destroy() end

    table.clear(state.Patches)
    table.clear(state.ByDistance)
    state.Triangles = 0
end

const function rebuild(state: State)
    reset(state)
    layout(state, getFocus(state.Part))
    startBuild(state)
end

-- Wave, flow, appearance and LodDistance changes apply live; CellSize changes rebuild the mesh.
const function connect(state: State)
    const part = state.Part
    state.Connection = part.AttributeChanged:Connect(function()
        applyAppearance(part)

        const cellSize = state.Config.CellSize
        state.Config = readConfig(part)
        if state.Config.CellSize ~= cellSize then rebuild(state) end
    end)
end

const function disconnect(state: State)
    const connection = state.Connection
    state.Connection = nil
    if connection then connection:Disconnect() end
end

-- Hands a cached state's mesh to the instance that replaced its part. Nothing is rebuilt.
const function adopt(state: State, part: MeshPart, config: Config)
    state.Part = part
    state.Config = config
    -- The new instance sits at Origin, so the next pose has to slide it again.
    state.ShiftX = math.huge
    state.ShiftZ = math.huge

    applySource(part, state.Source :: MeshPart)
end

-- PRIVATE MODULE

-- PUBLIC MODULE
const Water = {}

-- Builds the mesh in the background and overwrites the part's geometry with it once it's ready. A part streaming
-- back in within CACHE_LIFETIME of being released picks its old mesh back up instead.
function Water.new(part: MeshPart)
    if _states[part] then return end

    -- Before readConfig, which takes the flow tile size from the part's MaterialVariant.
    applyAppearance(part)
    const config = readConfig(part)
    const key = cacheKey(part)

    const cached = _cache[key]
    if cached then
        _cache[key] = nil

        if cached.Config.CellSize == config.CellSize then
            adopt(cached, part, config)
            _states[part] = cached
            connect(cached)
            return
        end

        reset(cached)
    end

    const state: State = {
        Part = part,
        Config = config,
        Key = key,
        ReleasedAt = 0,
        Token = 0,
        Building = false,
        RetryAt = 0,
        Origin = part.CFrame,
        Focus = part.Position,
        Mesh = nil,
        Source = nil,
        Patches = {},
        ByDistance = {},
        PatchesX = 0,
        PatchesZ = 0,
        BaseCellsX = 1,
        BaseCellsZ = 1,
        MaxLevel = 0,
        Triangles = 0,
        ShiftX = math.huge,
        ShiftZ = math.huge,
        Connection = nil,
    }
    _states[part] = state
    connect(state)

    layout(state, getFocus(part))
    startBuild(state)
end

-- `sync` should be shared across clients (workspace:GetServerTimeNow()) so everyone sees the same waves.
function Water.Update(part: MeshPart, sync: number)
    const state = _states[part]
    if not state then return end

    refreshLevels(state, getFocus(part))

    const mesh = state.Mesh
    if not mesh then
        if not state.Building and os.clock() >= state.RetryAt then startBuild(state) end
        return
    end

    rebuildPatches(state, mesh)
    pose(state, mesh, sync)
end

-- World-space Y of the animated surface above `position`, whether or not the part is being updated.
function Water.GetHeightAt(part: MeshPart, position: Vector3, sync: number): number?
    const state = _states[part]
    if not state then return nil end

    return state.Origin.Position.Y + (sampleSurface(state.Config, position.X, position.Z, sync, 0))
end

-- For a part leaving the client, e.g. streaming out. Its mesh is kept for CACHE_LIFETIME seconds in case the part
-- streams back in, then freed.
function Water.Release(part: MeshPart)
    const state = _states[part]
    if not state then return end

    _states[part] = nil
    disconnect(state)

    -- Still building (or failed), so there's nothing worth keeping.
    if not state.Mesh or not state.Source then
        reset(state)
        return
    end

    const key = state.Key
    const existing = _cache[key]
    if existing then reset(existing) end

    const releasedAt = os.clock()
    state.ReleasedAt = releasedAt
    _cache[key] = state

    task.delay(CACHE_LIFETIME, function()
        if _cache[key] ~= state or state.ReleasedAt ~= releasedAt then return end

        _cache[key] = nil
        reset(state)
    end)
end

-- Frees the part's mesh right away, without caching it.
function Water.Destroy(part: MeshPart)
    const state = _states[part]
    if not state then return end

    _states[part] = nil
    disconnect(state)
    reset(state)
end

return Water
