-- SERVICES
const LogService = game:GetService "LogService"
const MarketplaceService = game:GetService "MarketplaceService"
const Players = game:GetService "Players"

-- IMPORTED MODULES
const TableUtil = require "@game/ReplicatedStorage/Utilities/TableUtil"
const PlayerDataStore = require "@game/ServerScriptService/Shared/Stores/PlayerDataStore"

-- TYPES
type ReceiptInfo = {
	PlayerId: number,
	CurrencySpent: number,
	PurchaseId: string,
	ProductId: number,
	ProductPurchaseChannel: Enum.ProductPurchaseChannel,
	PlaceIdWherePurchased: number,
	CurrencyType: Enum.CurrencyType,
	ReceiptType: Enum.CurrencyType,
}
type ReceiptHandlers = { [number]: Handler }

export type Handler = (ReceiptInfo) -> ()

-- PRIVATE STATE
const _handlers: ReceiptHandlers = {}

-- PRIVATE FUNCTIONS
const function processReceipt(info: ReceiptInfo): Enum.ProductPurchaseDecision
	const userId = info.PlayerId
	const productId = info.ProductId
	const transactionId = info.PurchaseId
	const robuxSpent = info.CurrencySpent

	const player = Players:GetPlayerByUserId(userId)
	if not player then
		LogService:Warn("[ProductService] Player is no longer in the server", { id = userId })
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	const handler = _handlers[productId]
	if not handler then
		LogService:Warn("[ProductService] No product handler associated with {ProductId}", info :: { [string]: any })
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	const success, result = pcall(function()
		handler(info)
	end)

	if not success then
		LogService:Warn("[ProductService] Failed to grant rewards: {err}", { err = result })
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PlayerDataStore.Update(userId, function(data)
		if (data.Transactions :: { [string]: boolean })[transactionId] then
			return data
		end

		return TableUtil.Merge(data, {
			RobuxSpent = data.RobuxSpent + robuxSpent,
			Transactions = TableUtil.Set(data.Transactions, transactionId, true),
		})
	end)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- PUBLIC MODULE
const ProductService = {}

function ProductService.OnInit()
	LogService:Info "[ProductService] TODO"
	MarketplaceService.ProcessReceipt = processReceipt
end

function ProductService.AddHandlerToProduct(productId: number, handler: Handler)
	if _handlers[productId] then
		LogService:Error("[ProductService] ProductId already has a handler attached: {productId}", {
			productId = productId,
		})
		return
	end

	_handlers[productId] = handler
end

return ProductService
