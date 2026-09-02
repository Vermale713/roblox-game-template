-- SERVICES
const ReplicatedStorage = game:GetService "ReplicatedStorage"
const RunService = game:GetService "RunService"
const ServerStorage = game:GetService "ServerStorage"

-- IMPORTED MODULES
const Vow = require "@pkg/Vow"

-- TYPES
type Path = string
type ResolvedPath = { string }

-- PRIVATE FUNCTIONS
const function fetchAssetFromDirectory(directory: Folder, path: ResolvedPath): Instance?
	local asset = directory

	-- walk the directory
	for _, nextPath in path do
		asset = asset:FindFirstChild(nextPath)
		if asset == nil then
			break
		end
	end

	return asset
end

-- PUBLIC MODULE
const Asset = {}

--[=[
    Requests an asset
    @yields
    @param path string -- path to asset separated by "/" (eg. "Buildings/Home1")
    @return asset Instance -- the asset at the specified path
]=]
function Asset.Request(path: Path): Instance?
	local searchFolder: Folder
	const resolvedPath = path:split "/" :: ResolvedPath

	if RunService:IsServer() then
		searchFolder = ServerStorage:FindFirstChild "Assets" :: Folder
		const Server = require "@network/Server"

		Server.Asset.RequestAsset.On(function()
			local replicatedAssetFolder = ReplicatedStorage:FindFirstChild "Assets" :: Folder?
			if not replicatedAssetFolder then
				replicatedAssetFolder = Instance.new "Folder"
				replicatedAssetFolder.Name = "Assets"
				replicatedAssetFolder.Parent = ReplicatedStorage
			end

			const asset = fetchAssetFromDirectory(searchFolder, resolvedPath)

			if not asset then
				return nil
			end

			const clone = asset:Clone()
			clone.Parent = replicatedAssetFolder

			return clone
		end)
	else
		const replicatedAssetFolder = ReplicatedStorage:FindFirstChild "Assets" :: Folder?
		if not replicatedAssetFolder then
			-- send request to server
			const id = Vow.new(function(id)
				const Client = require "@network/Client"

				const asset = Client.Asset.RequestAsset.Invoke(resolvedPath)

				Vow.resolve(id, asset)
			end)

			const ok, value = Vow.await(id)

			Vow.destroy(id)

			return if ok then value else nil
		else
			searchFolder = ReplicatedStorage:FindFirstChild "Assets" :: Folder
		end
	end

	-- search for asset
	return fetchAssetFromDirectory(searchFolder, resolvedPath)
end

return Asset
