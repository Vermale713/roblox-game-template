-- PUBLIC MODULE
const NumberUtil = {}

function NumberUtil.TruncateToDecimalPlace(n: number, decimalPlace: number): number
	const multiplier = 10 ^ decimalPlace

	return math.floor(n * multiplier) / multiplier
end

return NumberUtil
