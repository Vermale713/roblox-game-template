-- SERVICES

-- IMPORTED MODULES

-- TYPES

-- ALIASES

-- CONSTANTS

-- PRIVATE STATE

-- PRIVATE FUNCTIONS

-- PRIVATE MODULE

-- PUBLIC MODULE
const Example = {}

Example.Data = {
	Id = "Example",
	OverrideRule = "Ignore",
	ApplyType = "ClearOnDeath",
	Duration = 10,
}

function Example.ModifyDamage(amount: number)
	return amount * 2
end

function Example.ModifyHeal(amount: number)
	return amount * 2
end

return Example
