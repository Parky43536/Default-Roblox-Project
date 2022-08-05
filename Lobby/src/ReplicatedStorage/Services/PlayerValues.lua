local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerValuesConnection

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

if IsServer then
    PlayerValuesConnection = Instance.new("RemoteEvent")
    PlayerValuesConnection.Name = "PlayerValuesConnection"
    PlayerValuesConnection.Parent = Remotes
elseif IsClient then
    PlayerValuesConnection = Remotes:WaitForChild("PlayerValuesConnection")
end

local StoredValues = {}
local StoredCallbacks = {}

local function checkCallbacks(player, property, value)
	if StoredCallbacks[property] then
		for _,callbackObject in pairs(StoredCallbacks[property]) do
			task.spawn(callbackObject.callback, player, value)
		end
	end
end

local PlayerValues = {}

if IsClient then
	PlayerValuesConnection.OnClientEvent:Connect(function(player, property, value)
		if player then
			if not StoredValues[player] then
				StoredValues[player] = {}
			end
			
			StoredValues[player][property] = value
			checkCallbacks(player, property, value)
		else
			--assert(false, "No player supplied to PlayerValues ["..property.." = "..value.."]")
		end
	end)
end

function PlayerValues:SetValue(player, property, value, replicate)
	if not StoredValues[player] then
		StoredValues[player] = {}
	end
	
	StoredValues[player][property] = value
	checkCallbacks(player, property, value)
	
	if replicate and IsServer then
		if replicate == "playerOnly" then
			PlayerValuesConnection:FireClient(player, player, property, value)
		else
			PlayerValuesConnection:FireAllClients(player, property, value)
		end
	end
end

function PlayerValues:IncrementValue(player, property, value, replicate)
	if not StoredValues[player] then
		StoredValues[player] = {}
	end

	StoredValues[player][property] = (StoredValues[player][property] or 0) + value
	checkCallbacks(player, property, StoredValues[player][property])

	if replicate and IsServer then
		if replicate == "playerOnly" then
			PlayerValuesConnection:FireClient(player, player, property, StoredValues[player][property])
		else
			PlayerValuesConnection:FireAllClients(player, property, StoredValues[player][property])
		end
	end
end

function PlayerValues:GetValue(player, property)
	if not StoredValues[player] then
		StoredValues[player] = {}
	end
	
	return StoredValues[player][property]
end

-- ITS NOT a ., its a :, check that before you waste your time
function PlayerValues:SetCallback(property, callback, optionalId)
	if not StoredCallbacks[property] then
		StoredCallbacks[property] = {}
	end

	local callbackId = optionalId or HttpService:GenerateGUID(false)
	table.insert(StoredCallbacks[property], {
		callback = callback,
		id = callbackId
	})

	return callbackId
end

function PlayerValues:RemoveCallback(property, id)
	local removeIndex = nil

	if not StoredCallbacks[property] then return end

	for i,callbackObject in pairs(StoredCallbacks[property]) do
		if callbackObject.id == id then
			removeIndex = i
			break
		end
	end

	if removeIndex then
		table.remove(StoredCallbacks[property], removeIndex)
	end
end

function PlayerValues:GetCallback(property, id)
	if not StoredCallbacks[property] then return end
	
	for i,callbackObject in pairs(StoredCallbacks[property]) do
		if callbackObject.id == id then
			return callbackObject
		end
	end

	return false
end

-- Updates everyone in the table with the given property's current value
-- Used for when players join in late, so they don't have any data on their client
function PlayerValues:SyncProperty(syncPlayer, property)
	for player, values in pairs(StoredValues) do
		if player ~= syncPlayer then
			if values[property] then
				PlayerValuesConnection:FireClient(syncPlayer, player, property, values[property])
			end
		end
	end
end

return PlayerValues
