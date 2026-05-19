--[=[
	Character.luau
	Handles the character as a class
]=]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- IMPORTED MODULES
local GlobalTypes = require(ReplicatedStorage.types.GlobalTypes)

--TYPES
type CharacterImpl = {
	__index: CharacterImpl,
	new: (rig: GlobalTypes.R15Character) -> Character,
	isAlive: (self: Character) -> boolean,
	heal: (self: Character, amount: number) -> (),
	takeDamage: (self: Character, amount: number) -> (),
	getHealth: (self: Character) -> number,
	getMaxHealth: (self: Character) -> number,
}

type CharacterProto = {
	Model: GlobalTypes.R15Character,
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
	StatusEffects: {},
}

export type Character = setmetatable<CharacterProto, CharacterImpl>

local Character = {} :: CharacterImpl
Character.__index = Character

function Character.new(rig: GlobalTypes.R15Character): Character
	return setmetatable({
		Model = rig,
		Humanoid = rig.Humanoid :: Humanoid,
		HumanoidRootPart = rig.HumanoidRootPart :: BasePart,
		StatusEffects = {},
	}, Character)
end

function Character.isAlive(self: Character): boolean
	local health = self.Humanoid.Health

	return health > 0
end

function Character.heal(self: Character, amount: number): ()
	if amount <= 0 or not math.isfinite(amount) then
		return
	end

	self.Humanoid.Health += amount
end

function Character.takeDamage(self: Character, amount: number): ()
	if amount <= 0 or not math.isfinite(amount) then
		return
	end

	self.Humanoid:TakeDamage(amount)
end

function Character.getHealth(self: Character)
	return self.Humanoid.Health
end

function Character.getMaxHealth(self: Character)
	return self.Humanoid.MaxHealth
end

return Character
