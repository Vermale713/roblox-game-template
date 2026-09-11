--!strict
-- IMPORTED MODULES
const AvatarAbilities = require "@lib/AvatarAbilities"

-- TYPES
type AbilityDefinition = AvatarAbilities.AbilityDefinition
type ManagerContext = AvatarAbilities.ManagerContext
type AbilityContext = AvatarAbilities.AbilityContext

-- ALIASES
const Identifiers = AvatarAbilities.Identifiers
const Rule = AvatarAbilities.Rule
const Sensor = Identifiers.Sensor
const All, Not = Rule.All, Rule.Not

-- PUBLIC MODULE
const Example: AbilityDefinition = {
    Name = "Example",
    Labels = { "Exampleing" },
    StartsWhen = All(Sensor.Ground, Not "ExampleCooldown"),
    RunsWhile = "ExampleWindow",
    Input = {
        InputName = "Example",
        Mode = "Press",
        ActionSlot = 5,
    },
    TimedLabels = {
        OnStart = { ExampleWindow = 0.2 },
        OnStop = { ExampleCooldown = 1 },
    },
}

function Example.OnStart(manager: ManagerContext, ability: AbilityContext)
    const rootPart = manager.AbilityOwner.PrimaryPart
    if rootPart then rootPart:ApplyImpulse(manager.RootLookVector * 80 * rootPart.AssemblyMass) end
end

return Example
