local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RepData = ReplicatedStorage.Database
local ErrorCodeData = require(RepData:WaitForChild("ErrorCodeData"))

local ErrorCodeHelper = {}

function ErrorCodeHelper.FormatCode(id, extra)
	return "Code: "..id.."\n"..ErrorCodeData[id].."\n"..(extra or "")
end
return ErrorCodeHelper