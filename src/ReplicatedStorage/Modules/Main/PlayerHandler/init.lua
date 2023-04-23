local PlayerHandler = {}

local Data = require(script:WaitForChild("PlayerData"))

local PlayerDict = {}

function PlayerHandler:Init(Character)
	for Key, Value in pairs(Data) do
		Character:SetAttribute(Key, Value.Value)
	end
	warn("[SERVER]: Initialized player data for ".."["..Character.Name.."]")
end

return PlayerHandler
