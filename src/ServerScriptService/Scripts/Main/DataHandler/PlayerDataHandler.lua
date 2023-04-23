local PlayerDataHandler = {}

local DataTemplate = {
	Inventory = {
		"Apple"
	},
	EquippedWeapon = "Apple",
	Settings = {
		["CustomSFX"] = ""
	}
}
local ProfileService = require(script.Parent.ProfileService)
local Players = game:GetService("Players")

local ProfileStore = ProfileService.GetProfileStore(
	"InventoryProfile",
	DataTemplate
)

local Profiles = {}

local function PlayerAdded(Player)
	local Profile = ProfileStore:LoadProfileAsync("Player_".. Player.UserId)
	
	if Profile then
		Profile:AddUserId(Player.UserId)
		Profile:Reconcile()
		
		Profile:ListenToRelease(function()
			Profiles[Player] = nil
			task.wait(180)
			if Player:IsDescendantOf(Players) then
				Player:Kick("There was an error with loading your data! Rejoin and it should fix 😀")
			end
		end)
		
		if not Player:IsDescendantOf(Players) then
			Profile:Release()
		else
			local timesincestart = os.clock()
			repeat
				Profiles[Player] = Profile
			until Profiles[Player] or (os.clock() - timesincestart > 5) or not Player:IsDescendantOf(game.Players)
			if not Player:IsDescendantOf(game.Players) then return end
			if not Profiles[Player] then Player:Kick("Trouble with loading data, please rejoin. If it still doesn't work, simply DM me on discord: edin#5868") end
			Player:SetAttribute("DataLoaded", true)
		end
	else
		Player:Kick("There was an error with loading your data! Rejoin and it should fix 😀")
	end
end

function PlayerDataHandler:Init()
	for _, Player in game.Players:GetPlayers() do
		task.spawn(PlayerAdded, Player)
	end
		
	game.Players.PlayerAdded:Connect(PlayerAdded)
		
	game.Players.PlayerRemoving:Connect(function(Player)
		if Profiles[Player] then
			Profiles[Player]:Release()
		end
	end)
end

local function GetProfile(Player)
	assert(Profiles[Player], string.format("Profile does not exist for %s", Player.UserId))
	
	return Profiles[Player]
end

function PlayerDataHandler:Get(Player, Key)
	local Profile = GetProfile(Player)
	assert(Profile.Data[Key], string.format("Data does not exist for key: %s", Key))
	
	return Profile.Data[Key]
end

function PlayerDataHandler:Set(Player, Key, Value)
	local Profile = GetProfile(Player)
	assert(Profile.Data[Key], string.format("Data does not exist for key: %s", Key))
	
	assert(type(Profile.Data[Key]) == type(Value))
	
	Profile.Data[Key] = Value
end

function PlayerDataHandler:Update(Player, Key, Callback)
	local Profile = GetProfile(Player)
	
	local OldData = self:Get(Player, Key)
	local NewData = Callback(OldData)
	
	self:Set(Player, Key, NewData)
end

return PlayerDataHandler
