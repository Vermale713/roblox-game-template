--!strict
-- IMPORTED MODULES
const DataTemplate = require "@game/ReplicatedStorage/Shared/Core/Data/DataTemplate".Client

-- PUBLIC MODULE
const DataController = {}

function DataController.OnStart() DataTemplate.WaitForData() end

return DataController
