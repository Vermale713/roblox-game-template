--!strict
--[[
    The engine's Character Controller Library, normally reached as
    require("@rbx/AvatarAbilities").

    Roblox resolves "@rbx/..." itself and the library is loaded from a content
    URI at runtime, so the alias exists in neither .luaurc nor larvae.toml:
    larvae stops on the unknown alias, and luau-lsp has no definitions for the
    module. Binding the path to a name keeps the require dynamic, which larvae
    leaves untouched, and the types below stand in for the ones the library
    exports.

    Require this module instead of "@rbx/AvatarAbilities" anywhere in the
    project. The types are hand-written from
    https://create.roblox.com/docs/characters/character-controller-library
    and cover the documented surface only; extend them as the docs grow.
]]

-- TYPES
-- A condition built by Rule.All/Any/Not, or taken from Identifiers.Sensor.
-- The library's own representation is undocumented, so it stays opaque.
export type ConditionExpr = { __condition: never }
export type Condition = string | ConditionExpr

export type Rule = {
    All: (...Condition) -> ConditionExpr,
    Any: (...Condition) -> ConditionExpr,
    Not: (Condition) -> ConditionExpr,
    -- A value, not a function: the ability's generated input sensor.
    Input: ConditionExpr,
}

export type SensorIdentifiers = {
    Ground: ConditionExpr,
    IsMoving: ConditionExpr,
    MoveInput: ConditionExpr,
    Ceiling: ConditionExpr,
    Climb: ConditionExpr,
    Water: ConditionExpr,
    WaterSurface: ConditionExpr,
    Sit: ConditionExpr,
    Tipped: ConditionExpr,
    Tool: ConditionExpr,
    LookDirectionInput: ConditionExpr,
    RotateToLookDirectionInput: ConditionExpr,
    [string]: ConditionExpr,
}

export type AbilityIdentifiers = {
    Running: string,
    FallingDown: string,
    Jumping: string,
    Sprinting: string,
    Crouching: string,
    [string]: string,
}

export type Identifiers = { Ability: AbilityIdentifiers, Sensor: SensorIdentifiers }

export type InputMode = "Press" | "Hold" | "Toggle" | "Repeat"

export type AbilityInput = {
    InputName: string,
    Mode: InputMode?,
    ActionSlot: number?,
    CustomIcon: string?,
    CustomIconActive: string?,
    CustomIconInvalid: string?,
}

export type TimedLabels = {
    OnStart: { [string]: number }?,
    OnStop: { [string]: number }?,
    Consumes: { string }?,
}

export type ExclusiveGroup = { Name: string, Priority: number }

export type ManagerContext = {
    AbilityOwner: Model,
    -- Cut-down view of the manager; its shape is undocumented.
    AbilityManager: any,
    -- Body parts with per-limb collision helpers; shape is undocumented.
    BodyParts: any,
    -- nil when no registered ability needs physics.
    ControllerManager: ControllerManager?,
    RootCFrame: CFrame,
    RootLookVector: Vector3,
    RootUpVectorY: number,
    TaskSynchronize: () -> (),
}

export type AbilityContext = {
    Config: { [string]: any },
    -- Replicates and takes part in server-authority rollback.
    State: { [string]: any },
    -- Scratch state: neither replicated nor rolled back.
    Local: { [string]: any },
}

-- Was the label present when activation began, before conflict resolution?
export type HadLabel = (label: string) -> boolean

export type AbilityDefinition = {
    Name: string,
    Labels: { string }?,
    TimedLabels: TimedLabels?,
    StartsWhen: Condition?,
    RunsWhile: Condition?,
    Blocks: { string }?,
    Stops: { string }?,
    Suspends: { string }?,
    ExclusiveGroup: ExclusiveGroup?,
    Input: AbilityInput?,
    OnSetup: ((managerCtx: ManagerContext, abilityCtx: AbilityContext) -> ())?,
    OnStart: ((managerCtx: ManagerContext, abilityCtx: AbilityContext, hadLabel: HadLabel) -> ())?,
    OnUpdate: ((managerCtx: ManagerContext, abilityCtx: AbilityContext) -> ())?,
    OnStop: ((managerCtx: ManagerContext, abilityCtx: AbilityContext) -> ())?,
    OnTeardown: ((managerCtx: ManagerContext, abilityCtx: AbilityContext) -> ())?,
}

export type AvatarAbilities = {
    Identifiers: Identifiers,
    Rule: Rule,
    getAbilityConfigurationForCharacter: (character: Model, abilityName: string) -> Configuration?,
    addAbilityForCharacter: (character: Model, abilityModule: ModuleScript) -> (),
}

-- CONSTANTS
const LIBRARY_PATH = "@rbx/AvatarAbilities"

return (require(LIBRARY_PATH) :: any) :: AvatarAbilities
