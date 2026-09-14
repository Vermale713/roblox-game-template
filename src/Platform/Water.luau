--!strict
-- SERVICES
const AssetService = game:GetService "AssetService"
const MaterialService = game:GetService "MaterialService"

-- TYPES
export type Water = {
    Part: BasePart,
    StreamIn: (self: Water, focus: Vector3) -> (),
    StreamOut: (self: Water) -> (),
    Update: (self: Water, now: number, focus: Vector3) -> (),
    GetHeightAt: (self: Water, position: Vector3, now: number) -> number,
    IsRendered: (self: Water) -> boolean,
    Destroy: (self: Water) -> (),
}

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
    Color: Color3,
    Transparency: number,
    Reflectance: number,
    Material: Enum.Material,
    MaterialVariant: string,
    Texture: string,
    TextureScale: number,
    MaterialTile: number,
    FlowX: number,
    FlowZ: number,
    Variation: number,
    VariationScale: number,
    -- Sorted longest first.
    Waves: { Wave },
}

-- A region of the area's single mesh with its own level of detail. When the level changes its triangles are
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
    -- Surface space, relative to the area centre.
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

type WaterInternal = {
    Part: BasePart,
    _config: Config,
    _state: "Out" | "In",
    -- Bumped on every StreamIn/StreamOut so a build that yielded can tell it is stale.
    _token: number,
    _building: boolean,
    _retryAt: number,
    _origin: CFrame,
    -- Last camera position given to StreamIn/Update; drives LOD and how much small-wave detail is drawn.
    _focus: Vector3,
    _mesh: EditableMesh?,
    _surface: MeshPart?,
    _patches: { Patch },
    _byDistance: { Patch },
    _patchesX: number,
    _patchesZ: number,
    _baseCellsX: number,
    _baseCellsZ: number,
    _maxLevel: number,
    _triangles: number,
    -- How far the MeshPart currently sits from the area centre (surface space) to slide part-mapped materials.
    _shiftX: number,
    _shiftZ: number,
    _attributeConnection: RBXScriptConnection?,
    _destroyed: boolean,
}

-- ALIASES

-- CONSTANTS
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

const DEFAULT_WAVE_HEIGHT = 0.6
const DEFAULT_WAVE_LENGTH = 40
const DEFAULT_WAVE_SPEED = 6
const DEFAULT_WAVE_DIRECTION = 0
const DEFAULT_CELL_SIZE = 4
const DEFAULT_LOD_DISTANCE = 100
const DEFAULT_COLOR = Color3.fromRGB(40, 110, 150)
const DEFAULT_TRANSPARENCY = 0.35
const DEFAULT_REFLECTANCE = 0.15
const DEFAULT_MATERIAL = Enum.Material.Glass
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
-- A perfectly flat mesh has a zero-height bounding box, so the initial geometry is pinned to at least this.
const MIN_BOUNDS_HEIGHT = 0.05

-- PRIVATE STATE

-- PRIVATE FUNCTIONS
const function numberAttribute(instance: Instance, name: string, default: number): number
    const value = instance:GetAttribute(name)
    return if typeof(value) == "number" then value else default
end

const function colorAttribute(instance: Instance, name: string, default: Color3): Color3
    const value = instance:GetAttribute(name)
    return if typeof(value) == "Color3" then value else default
end

const function materialAttribute(instance: Instance, name: string, default: Enum.Material): Enum.Material
    const value = instance:GetAttribute(name)
    if typeof(value) ~= "string" then return default end

    const ok, material = pcall(function() return (Enum.Material :: any)[value] end)
    return if ok and typeof(material) == "EnumItem" then material :: any else default
end

-- Accepts a bare asset id (number or digits) or a full content URI.
const function textureAttribute(instance: Instance, name: string): string
    const value = instance:GetAttribute(name)
    if typeof(value) == "number" then return `rbxassetid://{value}` end
    if typeof(value) ~= "string" then return "" end
    return if value:match "^%d+$" then `rbxassetid://{value}` else value
end

-- A variant only shows when the part's Material matches its BaseMaterial, so that is taken from the variant.
const function findMaterialVariant(part: BasePart): MaterialVariant?
    const name = part:GetAttribute "WaterMaterialVariant"
    if typeof(name) ~= "string" or name == "" then return nil end

    const variant = MaterialService:FindFirstChild(name, true)
    if variant and variant:IsA "MaterialVariant" then return variant end

    warn(`[Water] MaterialVariant '{name}' for {part:GetFullName()} was not found under MaterialService`)
    return nil
end

const function readConfig(part: BasePart): Config
    const waveHeight = math.max(numberAttribute(part, "WaveHeight", DEFAULT_WAVE_HEIGHT), 0)
    const waveLength = math.max(numberAttribute(part, "WaveLength", DEFAULT_WAVE_LENGTH), 1)
    const waveSpeed = numberAttribute(part, "WaveSpeed", DEFAULT_WAVE_SPEED)
    const waveDegrees = numberAttribute(part, "WaveDirection", DEFAULT_WAVE_DIRECTION)
    const waveDirection = math.rad(waveDegrees)
    const flowSpeed = numberAttribute(part, "FlowSpeed", DEFAULT_FLOW_SPEED)
    -- Flows with the waves unless told otherwise.
    const flowDirection = math.rad(numberAttribute(part, "FlowDirection", waveDegrees))
    const textureScale = math.max(numberAttribute(part, "TextureScale", DEFAULT_TEXTURE_SCALE), MIN_TEXTURE_SCALE)

    -- Seeded so every client (and every area sharing a seed) generates the same waves.
    const random = Random.new(numberAttribute(part, "WaveSeed", DEFAULT_WAVE_SEED))
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

    const variant = findMaterialVariant(part)

    return {
        WaveHeight = waveHeight,
        CellSize = math.max(numberAttribute(part, "CellSize", DEFAULT_CELL_SIZE), MIN_CELL_SIZE),
        LodDistance = math.max(numberAttribute(part, "LodDistance", DEFAULT_LOD_DISTANCE), 1),
        Color = colorAttribute(part, "WaterColor", DEFAULT_COLOR),
        Transparency = numberAttribute(part, "WaterTransparency", DEFAULT_TRANSPARENCY),
        Reflectance = numberAttribute(part, "WaterReflectance", DEFAULT_REFLECTANCE),
        Material = if variant then variant.BaseMaterial else materialAttribute(part, "WaterMaterial", DEFAULT_MATERIAL),
        MaterialVariant = if variant then variant.Name else "",
        Texture = textureAttribute(part, "WaterTexture"),
        TextureScale = textureScale,
        -- Built-in materials don't expose their tile size, so TextureScale stands in for it.
        MaterialTile = if variant then math.max(variant.StudsPerTile, MIN_TEXTURE_SCALE) else textureScale,
        FlowX = math.cos(flowDirection) * flowSpeed,
        FlowZ = math.sin(flowDirection) * flowSpeed,
        Variation = math.clamp(numberAttribute(part, "WaveVariation", DEFAULT_WAVE_VARIATION), 0, 1),
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

const function surfaceCFrame(part: BasePart): CFrame return part.CFrame * CFrame.new(0, part.Size.Y / 2, 0) end

const function applyAppearance(surface: MeshPart, config: Config)
    surface.Color = config.Color
    surface.Transparency = config.Transparency
    surface.Reflectance = config.Reflectance
    surface.Material = config.Material
    surface.MaterialVariant = config.MaterialVariant
    surface.TextureContent = if config.Texture ~= "" then Content.fromUri(config.Texture) else Content.none
end

const function log2(value: number): number return math.floor(math.log(value, 2) + 0.5) end

const function cellsForLevel(baseCells: number, level: number): number return math.max(baseCells // 2 ^ level, 1) end

const function trianglesForLevel(self: WaterInternal, level: number): number
    return 2 * cellsForLevel(self._baseCellsX, level) * cellsForLevel(self._baseCellsZ, level)
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

const function neighborCells(self: WaterInternal, gridX: number, gridZ: number, alongX: boolean): number?
    if gridX < 0 or gridX >= self._patchesX or gridZ < 0 or gridZ >= self._patchesZ then return nil end

    const patch = self._patches[gridZ * self._patchesX + gridX + 1]
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
const function buildPatch(self: WaterInternal, mesh: EditableMesh, patch: Patch, level: number)
    for _, faceId in patch.FaceIds do
        mesh:RemoveFace(faceId)
    end
    self._triangles -= #patch.FaceIds
    clearPatch(patch)

    const cellsX = cellsForLevel(self._baseCellsX, level)
    const cellsZ = cellsForLevel(self._baseCellsZ, level)
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
            const world = self._origin:PointToWorldSpace(Vector3.new(localX, 0, localZ))

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
    self._triangles += #patch.FaceIds
end

const function refreshLevels(self: WaterInternal, focus: Vector3)
    self._focus = focus
    const localFocus = self._origin:PointToObjectSpace(focus)
    const lodDistance = self._config.LodDistance
    const maxLevel = self._maxLevel
    local triangles = 0

    for _, patch in self._patches do
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
        triangles += trianglesForLevel(self, want)
    end

    if triangles <= MAX_TRIANGLES then return end

    -- Over budget: coarsen one level at a time, farthest patches first, until it fits.
    const byDistance = self._byDistance
    table.sort(byDistance, function(a: Patch, b: Patch) return a.Distance > b.Distance end)

    local coarsened = true
    while triangles > MAX_TRIANGLES and coarsened do
        coarsened = false

        for _, patch in byDistance do
            if patch.Want >= maxLevel then continue end

            triangles += trianglesForLevel(self, patch.Want + 1) - trianglesForLevel(self, patch.Want)
            patch.Want += 1
            coarsened = true

            if triangles <= MAX_TRIANGLES then break end
        end
    end
end

const function rebuildPatches(self: WaterInternal, mesh: EditableMesh)
    local remaining = MAX_REBUILDS_PER_FRAME

    -- Coarsen first so the triangles they free are available to the refinements.
    for _, patch in self._patches do
        if remaining == 0 then break end
        if patch.Want <= patch.Level then continue end

        buildPatch(self, mesh, patch, patch.Want)
        remaining -= 1
    end

    while remaining > 0 do
        local nearest: Patch? = nil

        for _, patch in self._patches do
            if patch.Want >= patch.Level then continue end
            if nearest and patch.Distance >= nearest.Distance then continue end

            const cost = trianglesForLevel(self, patch.Want) - #patch.FaceIds
            if self._triangles + cost <= MAX_TRIANGLES then nearest = patch end
        end

        if not nearest then break end

        buildPatch(self, mesh, nearest, nearest.Want)
        remaining -= 1
    end

    if remaining < MAX_REBUILDS_PER_FRAME then mesh:RemoveUnused() end
end

const function pose(self: WaterInternal, mesh: EditableMesh, surface: MeshPart, now: number)
    const config = self._config

    -- Materials and MaterialVariants are mapped relative to the part and ignore UVs, so they flow by sliding the
    -- MeshPart and moving the vertices back by the same amount. Wrapped to one tile so it never drifts far.
    const tile = config.MaterialTile
    const flow = self._origin:VectorToObjectSpace(Vector3.new(config.FlowX, 0, config.FlowZ))
    const shiftX = (-flow.X * now) % tile
    const shiftZ = (-flow.Z * now) % tile

    if shiftX ~= self._shiftX or shiftZ ~= self._shiftZ then
        surface.CFrame = self._origin * CFrame.new(-shiftX, 0, -shiftZ)
        self._shiftX = shiftX
        self._shiftZ = shiftZ
    end

    -- UVs come from world XZ so textures line up across patches and areas. The flow offset is wrapped to one tile
    -- because server time is in the billions and would lose precision on the GPU.
    const scale = config.TextureScale
    const flowing = config.FlowX ~= 0 or config.FlowZ ~= 0
    const offsetU = (config.FlowX * now) % scale
    const offsetV = (config.FlowZ * now) % scale

    -- For rotating world-space normals into the mesh's space.
    const right = self._origin.XVector
    const up = self._origin.YVector
    const back = self._origin.ZVector

    -- A continuous stand-in for the mesh spacing at a distance (the finest spacing that LOD level could have), so
    -- small waves fade out smoothly with distance instead of changing abruptly at patch borders.
    const focus = self._focus
    const surfaceY = self._origin.Position.Y
    const baseCell = config.CellSize
    const inverseLodDistance = 1 / config.LodDistance

    for _, patch in self._patches do
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

        const leftCells = neighborCells(self, patch.GridX - 1, patch.GridZ, false)
        const rightCells = neighborCells(self, patch.GridX + 1, patch.GridZ, false)
        const bottomCells = neighborCells(self, patch.GridX, patch.GridZ - 1, true)
        const topCells = neighborCells(self, patch.GridX, patch.GridZ + 1, true)

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

-- Yields while the engine builds the MeshPart.
const function buildSurface(self: WaterInternal, token: number)
    const part = self.Part

    const createdOk, created = pcall(function() return AssetService:CreateEditableMesh {} end)
    if token ~= self._token then return end

    if not createdOk or not created then
        warn(`[Water] Could not create EditableMesh for {part:GetFullName()}: {created}`)
        self._building = false
        self._retryAt = os.clock() + BUILD_RETRY_DELAY
        return
    end
    const mesh = created :: EditableMesh

    for _, patch in self._patches do
        buildPatch(self, mesh, patch, patch.Want)
    end

    -- Symmetric bounds keep the mesh centred on the surface and give the MeshPart a 1:1 scale with room for waves.
    const bounds = math.max(self._config.WaveHeight, MIN_BOUNDS_HEIGHT)
    const first = self._patches[1]
    const last = self._patches[#self._patches]
    const lastIndex = #last.VertexIds
    mesh:SetPosition(first.VertexIds[1], Vector3.new(first.LocalX[1], bounds, first.LocalZ[1]))
    mesh:SetPosition(last.VertexIds[lastIndex], Vector3.new(last.LocalX[lastIndex], -bounds, last.LocalZ[lastIndex]))

    const builtOk, built = pcall(function()
        return AssetService:CreateMeshPartAsync(
            Content.fromObject(mesh),
            { CollisionFidelity = Enum.CollisionFidelity.Box } :: { [string]: any }
        )
    end)

    if token ~= self._token then
        -- StreamOut or Destroy ran while we were yielding.
        if builtOk and built then (built :: MeshPart):Destroy() end
        mesh:Destroy()
        return
    end

    self._building = false

    if not builtOk or not built then
        warn(`[Water] Could not build surface for {part:GetFullName()}: {built}`)
        mesh:Destroy()
        for _, patch in self._patches do
            clearPatch(patch)
        end
        self._triangles = 0
        self._retryAt = os.clock() + BUILD_RETRY_DELAY
        return
    end

    const surface = built :: MeshPart
    surface.Name = "WaterSurface"
    surface.Anchored = true
    surface.CanCollide = false
    surface.CanQuery = false
    surface.CanTouch = false
    surface.CastShadow = false
    applyAppearance(surface, self._config)

    -- SurfaceAppearance images can't be set from scripts, so one authored under the water part is cloned instead.
    const appearance = part:FindFirstChildOfClass "SurfaceAppearance"
    if appearance then appearance:Clone().Parent = surface end

    self._mesh = mesh
    self._surface = surface
    pose(self, mesh, surface, workspace:GetServerTimeNow())

    part.LocalTransparencyModifier = 1
    surface.Parent = part
end

const function startBuild(self: WaterInternal)
    self._building = true
    task.spawn(buildSurface, self, self._token)
end

-- PRIVATE MODULE
const Impl = {}
Impl.__index = Impl

-- Lays out the patches and starts building the mesh in the background; `focus` picks the starting detail.
function Impl.StreamIn(self: WaterInternal, focus: Vector3)
    if self._destroyed or self._state == "In" then return end

    self._state = "In"
    self._token += 1

    const part = self.Part
    const size = part.Size
    const cellSize = self._config.CellSize
    const patchSize = cellSize * PATCH_CELLS

    const patchesX = math.max(math.ceil(size.X / patchSize), 1)
    const patchesZ = math.max(math.ceil(size.Z / patchSize), 1)
    const sizeX = size.X / patchesX
    const sizeZ = size.Z / patchesZ

    -- Powers of two so a coarser patch's vertices are always a subset of a finer neighbour's along a shared edge.
    const baseCellsX = 2 ^ log2(math.clamp(sizeX / cellSize, 1, PATCH_CELLS))
    const baseCellsZ = 2 ^ log2(math.clamp(sizeZ / cellSize, 1, PATCH_CELLS))

    self._origin = surfaceCFrame(part)
    self._patchesX = patchesX
    self._patchesZ = patchesZ
    self._baseCellsX = baseCellsX
    self._baseCellsZ = baseCellsZ
    self._maxLevel = math.max(log2(baseCellsX), log2(baseCellsZ))
    self._triangles = 0
    self._shiftX = math.huge
    self._shiftZ = math.huge
    self._retryAt = 0

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

            table.insert(self._patches, patch)
            table.insert(self._byDistance, patch)
        end
    end

    refreshLevels(self, focus)
    startBuild(self)
end

function Impl.StreamOut(self: WaterInternal)
    if self._state == "Out" then return end

    self._token += 1
    self._state = "Out"
    self._building = false
    self.Part.LocalTransparencyModifier = 0

    const surface = self._surface
    const mesh = self._mesh
    self._surface = nil
    self._mesh = nil
    if surface then surface:Destroy() end
    if mesh then mesh:Destroy() end

    table.clear(self._patches)
    table.clear(self._byDistance)
    self._triangles = 0
end

-- `now` should be shared across clients (workspace:GetServerTimeNow()) so everyone sees the same waves.
-- `focus` is usually the camera position; it drives each patch's level of detail.
function Impl.Update(self: WaterInternal, now: number, focus: Vector3)
    if self._state ~= "In" then return end

    refreshLevels(self, focus)

    const mesh = self._mesh
    const surface = self._surface
    if not mesh or not surface then
        if not self._building and os.clock() >= self._retryAt then startBuild(self) end
        return
    end

    rebuildPatches(self, mesh)
    pose(self, mesh, surface, now)
end

-- World-space Y of the animated surface above `position`; works whether or not the area is rendered.
function Impl.GetHeightAt(self: WaterInternal, position: Vector3, now: number): number
    return surfaceCFrame(self.Part).Position.Y + (sampleSurface(self._config, position.X, position.Z, now, 0))
end

function Impl.IsRendered(self: WaterInternal): boolean return self._state == "In" end

function Impl.Destroy(self: WaterInternal)
    if self._destroyed then return end

    Impl.StreamOut(self)
    self._destroyed = true

    const connection = self._attributeConnection
    self._attributeConnection = nil
    if connection then connection:Disconnect() end
end

-- PUBLIC MODULE
const Water = {}

-- Cheap: reads config only. The mesh is built after StreamIn and freed on StreamOut.
function Water.new(part: BasePart): Water
    const self: WaterInternal = {
        Part = part,
        _config = readConfig(part),
        _state = "Out",
        _token = 0,
        _building = false,
        _retryAt = 0,
        _origin = surfaceCFrame(part),
        _focus = part.Position,
        _mesh = nil,
        _surface = nil,
        _patches = {},
        _byDistance = {},
        _patchesX = 0,
        _patchesZ = 0,
        _baseCellsX = 1,
        _baseCellsZ = 1,
        _maxLevel = 0,
        _triangles = 0,
        _shiftX = math.huge,
        _shiftZ = math.huge,
        _attributeConnection = nil,
        _destroyed = false,
    }

    -- Wave, flow, appearance and LodDistance changes apply live; CellSize changes apply on the next StreamIn.
    self._attributeConnection = part.AttributeChanged:Connect(function()
        self._config = readConfig(part)

        const surface = self._surface
        if surface then applyAppearance(surface, self._config) end
    end)

    return (setmetatable(self, Impl) :: any) :: Water
end

return Water
