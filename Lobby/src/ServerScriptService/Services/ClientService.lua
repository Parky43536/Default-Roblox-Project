local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RepServices = ReplicatedStorage.Services
local PlayerValues = require(RepServices.PlayerValues)

local ClientService = {}

function ClientService.InitializeClient(player, profile)
    PlayerValues:SetValue(player, "Gold", profile.Data.Gold, "playerOnly")
end

return ClientService