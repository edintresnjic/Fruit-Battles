--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGUI = game:GetService("StarterGui")
local MessagingService = game:GetService("MessagingService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local MarketPlaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local DataStoreSerivce = game:GetService("DataStoreService")
--|| Instances ||--
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Main = Modules:WaitForChild("Main")
local Events = ReplicatedStorage:WaitForChild("Events")
local StreakGUI = ReplicatedStorage:WaitForChild("GUI"):WaitForChild("StreakGUI")
local Objects = ServerStorage:WaitForChild("Objects")

--|| Modules ||--
local Weapons = require(Main:WaitForChild("Weapons"))
local GuiHandler = require(Main:WaitForChild("GUIHandler"))
local PlayerHandler = require(Main:WaitForChild("PlayerHandler"))
local DataStore2 = require(script.Parent:WaitForChild("DataHandler"):WaitForChild("DataStore2"))
local RagdollModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("Ragdoll"))
local EventHandler = require(Main:WaitForChild("EventHandler"))
local PlayerDataHandler = require(script.Parent.DataHandler.PlayerDataHandler)

-- Initialize PlayerDataHandler
PlayerDataHandler:Init()

--|| Events ||--
local WeaponInit = Events:WaitForChild("WeaponInit")
local WeaponActivation = Events:WaitForChild("WeaponActivation")
local KillEvent: RemoteEvent = Events:WaitForChild("KilledEvent")
local RagdollEvent : RemoteFunction = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RagdollCallback")
local DataEvent : RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DataEvent")
local StartQueue: RemoteEvent = Events:WaitForChild("StartQueue")
local Shop = Events:WaitForChild("Shop")
local UpdateLoadingState = Events:WaitForChild("UpdateLoadingState")
local EventOnGoing: boolean = false
local SetSoundID = Events:WaitForChild("SetSoundID")
local SpawnVFX = Events:WaitForChild("SpawnVFX")
local CameraHandler = Events:WaitForChild("CameraHandler")
local CheckServerValue = Events:WaitForChild("CheckServerValue")

--|| Instances ||--
local TournamentPlace = workspace:WaitForChild("Map"):WaitForChild("Leaderboard")
local TournamentMoney = TournamentPlace:WaitForChild("Leaderboard Money")
local TournamentKills = TournamentPlace:WaitForChild("Leaderboard Kills")

local MoneyTournamentGui = TournamentMoney:WaitForChild("Main"):WaitForChild("SurfaceGui"):WaitForChild("ScrollingFrame")
local KillTournamentGui = TournamentKills:WaitForChild("Main"):WaitForChild("SurfaceGui"):WaitForChild("ScrollingFrame")

-- Leaderboard Money
local LeaderboardStore = DataStoreSerivce:GetOrderedDataStore("LeaderboardStore")
local Pages = LeaderboardStore:GetSortedAsync(false, 100)

local Data = Pages:GetCurrentPage()
for i, v in pairs(Data) do
	local MainFrame = script:WaitForChild("Frame"):Clone()
	
	local PlayerText = MainFrame:WaitForChild("Player")
	PlayerText.Text = v.key
	
	local MoneyText = MainFrame:WaitForChild("Value")
	MoneyText.Text = "$".. v.value
	
	local RankText = MainFrame:WaitForChild("Rank")
	RankText.Text = "#".. i
	
	MainFrame.Parent = MoneyTournamentGui
end

-- Leaderboard Kills
local KillsLeaderboardStore = DataStoreSerivce:GetOrderedDataStore("KillsLeaderboardStore")
local Pages = KillsLeaderboardStore:GetSortedAsync(false, 100)

local Data = Pages:GetCurrentPage()
for i, v in pairs(Data) do
	local MainFrame = script:WaitForChild("Frame"):Clone()

	local PlayerText = MainFrame:WaitForChild("Player")
	PlayerText.Text = v.key

	local KillText = MainFrame:WaitForChild("Value")
	KillText.Text = v.value

	local RankText = MainFrame:WaitForChild("Rank")
	RankText.Text = "#".. i

	MainFrame.Parent = KillTournamentGui
end

-- Variables
local KillTexts = {
	"You ded.",
	"hax?",
	"good gaem.",
	":(",
	"are you serious right neow?",
	"thats tuff",
	"next time g",
	"😥😥😥😥",
	"wow..",
	"🤷‍"
}
local QueueingPlayers = {
	[1] = {}
}

local Friends = {
	"Drilon2007",
	"KaWaSaK1io",
	"Endryeos",
	"Joseffd",
	"Josefsd"
}

local WasUlted = {}
-- Datastore2
DataStore2.Combine("DATA", "Money", "Kills", "Weapons")

StartQueue.OnServerEvent:Connect(function(Player)
	GuiHandler:OneVOne(Player)
end)

local GamePassIDs = {
	["2X Money"] = 164543945,
	["Custom Kill Sound"] = 164544847
}
-- MessagingService
if not RunService:IsStudio() then
	MessagingService:SubscribeAsync("QueueAdd", function(Data)
		for Index, Table in pairs(QueueingPlayers) do
			if table.find(Table, Data.Data) then return end
		end

		local FoundPair = false
		for Queue, Pair in pairs(QueueingPlayers) do
			if #Pair <= 1 then
				table.insert(Pair, Data.Data)
				FoundPair = true
			end
		end

		if not FoundPair then
			QueueingPlayers[#QueueingPlayers + 1] = {Data.Data}
		end
		
		local Player = game.Players:FindFirstChild(Data.Data)
		local Character = Player.Character
		workspace:SetAttribute("PlayersInQueue", workspace:GetAttribute("PlayersInQueue") + 1)
		Character:SetAttribute("InQueue", true)

		for Queue, Pair in pairs(QueueingPlayers) do
			if #Pair >= 2 then
				local Player1 = Pair[1]
				local Player2 = Pair[2]

				-- Changing GUI & Disabling cancel buttons
				Players:FindFirstChild(Player1).PlayerGui.Main["1v1"].OneOnOneFrame.TextLabel.Text = "We found a match! Teleporting in progress..."
				workspace:FindFirstChild(Player1):SetAttribute("FoundGame", true)
				Players:FindFirstChild(Player2).PlayerGui.Main["1v1"].OneOnOneFrame.TextLabel.Text = "We found a match! Teleporting in progress..."
				workspace:FindFirstChild(Player2):SetAttribute("FoundGame", true)


				-- Teleporting
				local success, response 
				while not success do
					success, response = pcall(function()
						TeleportService:TeleportAsync(13048383578, {Players:FindFirstChild(Player1), Players:FindFirstChild(Player2)})
					end)
					task.wait(2)
				end
			end
		end
	end)

	MessagingService:SubscribeAsync("QueueRemove", function(Data)
		local IndexToDelete
		local PlayersInQueue = 0
		for Index, Pair in ipairs(QueueingPlayers) do
			if table.find(Pair, Data.Data) then
				table.remove(Pair, table.find(Pair, Data.Data))
			end
			PlayersInQueue += #Pair
		end
		workspace:SetAttribute("PlayersInQueue", PlayersInQueue)
		local Player = game.Players:FindFirstChild(Data.Data)
		local Character = Player.Character
		Character:SetAttribute("InQueue", true)
	end)
end

--|| Main Code ||--
------------------------------------------------------------------------------------
-- Ragdoll func
function RagdollOnDeath(player : Player)
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then
		return false
	end

	local CanRagdoll = not RagdollModule.IsRagdolled(player.Character.Humanoid)

	if CanRagdoll then
		local Motors = RagdollModule.CreateJoints(player.Character)
		RagdollModule.Ragdoll(player.Character)
		RagdollModule.SetMotorsEnabled(Motors, false)
	end

	return CanRagdoll
end


local function RetrieveWeapon(Player)
	local EquippedWeapon = PlayerDataHandler:Get(Player, "EquippedWeapon")
	for Key, Val in pairs(Weapons) do
		if Key == EquippedWeapon then
			return Val, Key
		end
	end
end

local function GetWeapon(Player)
	-- Reset weapons
	for Index, Tool in pairs(Player:WaitForChild("Backpack"):GetChildren()) do
		if Tool:IsA("Tool") then
			Tool:Destroy()
		end
	end
	local EquippedWeapon = PlayerDataHandler:Get(Player, "EquippedWeapon")

	local StarterWeapon
	-- = Weapons.Throwables.Apple:GetModel():Clone()
	for Key, Val in pairs(Weapons) do
		if Key == EquippedWeapon then
			StarterWeapon = Val:GetModel():Clone()
		end
	end
	local BackPack = Player:WaitForChild("Backpack")

	StarterWeapon.Parent = BackPack

	return StarterWeapon
end

SetSoundID.OnServerEvent:Connect(function(Player, SoundID)
	local HasPass
	local success, message = pcall(function()
		HasPass = MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, GamePassIDs["Custom Kill Sound"])
	end)

	if not success then
		warn("Error while checking if player has pass:", message)
		return
	end
	
	if not HasPass then return end
	
	if HasPass then
		local Success, Response = pcall(MarketPlaceService.GetProductInfo, MarketPlaceService, SoundID)
		
		if success then
			if Response.AssetTypeId == Enum.AssetType.Audio.Value then
				Player:SetAttribute("CustomSFX", "rbxassetid://".. SoundID)
				SetSoundID:FireClient(Player, "Success")
			else
				SetSoundID:FireClient(Player, "Error")
			end
		end
	end
end)

local function CharacterAdded(Character)
	local SpawnPoints = workspace:WaitForChild("Map"):WaitForChild("SpawnPoints"):GetChildren()

	local FoundSpot
	task.spawn(function()
		repeat
			task.wait()
			local SpawnPoint = SpawnPoints[math.random(1, #SpawnPoints)]
			print(SpawnPoint)
			print(SpawnPoint:GetAttribute("RecentSpawn"))
			if SpawnPoint:GetAttribute("RecentSpawn") == false then
				Character.HumanoidRootPart.CFrame = SpawnPoint.CFrame
				SpawnPoint:SetAttribute("RecentSpawn", true)
				FoundSpot = true
				task.delay(7, function()
					SpawnPoint:SetAttribute("RecentSpawn", false)
				end)
			end
		until FoundSpot == true
	end)

	local Player = Players:GetPlayerFromCharacter(Character)
	if Player:GetAttribute("HasDied") and Player:GetAttribute("HasDied") == true then
		Player:SetAttribute("HasDied", false)
	end
	local Has2XMoneyPass
	local success, response = pcall(function()
		Has2XMoneyPass = MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, GamePassIDs["2X Money"])
	end)
	
	if not success then
		warn("Something wrong with getting the gamepass:", response)
	end
	-- Instances
	local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")
	Character:SetAttribute("Weapon", Weapons.Value)
	-- Enables ragdoll
	Humanoid.BreakJointsOnDeath = false
	Humanoid.RequiresNeck = false
	-- Initialize Player
	PlayerHandler:Init(Character)

	-- Streak GUI
	local StreakGUI = StreakGUI:Clone()
	StreakGUI.Adornee = Character.Head
	StreakGUI.Parent = Character.Head
	Character:GetAttributeChangedSignal("Streak"):Connect(function()
		StreakGUI.Text.Text = "STREAK: ".. Character:GetAttribute("Streak")
	end)
	
	local MoneyStore = DataStore2("Money", Player)
	
	-- Add Highlight
	local HighLight: Highlight = Instance.new("Highlight")
	HighLight.FillTransparency = 1
	HighLight.Parent = Character
	
	if Player:FindFirstChild("IsUlted") then
		-- Main
		Character:SetAttribute("UltimateCooldown", true)
		-- Reset
		local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
		local Cooldown = string.match(CooldownText.Text, "%(.*%)")
		if not Cooldown then return end
		Cooldown = string.split(Cooldown, "(")
		Cooldown[2] = string.split(Cooldown[2], ")")
		Cooldown = Cooldown[2][1]
		task.delay(tonumber(Cooldown), function()
			Character:SetAttribute("UltimateCooldown", false)
		end)
	end
	-- Adding aura vfx
	Character:GetAttributeChangedSignal("UltimateCooldown"):Connect(function()
		if Character:GetAttribute("UltimateCooldown") == false then
			local UltimateAuraVFX = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimate Aura")
			for _, Emit in ipairs(UltimateAuraVFX:GetDescendants()) do
				if Emit:IsA("ParticleEmitter") then
					local Copy = Emit:Clone()
					Copy.Parent = Character:FindFirstChild(Emit.Parent.Name)
				end
			end
			

		else
			SpawnVFX:FireAllClients(nil, nil, false, "AuraRemove", Player)
			for _, Emitter in ipairs(Character:GetDescendants()) do
				if Emitter:IsA("ParticleEmitter") then
					Emitter:Destroy()
				end
			end
		end
	end)

	if Character:GetAttribute("UltimateCooldown") == false then
		local UltimateAuraVFX = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimate Aura")
		for _, Emit in ipairs(UltimateAuraVFX:GetDescendants()) do
			if Emit:IsA("ParticleEmitter") then
				local Copy = Emit:Clone()
				Copy.Parent = Character:FindFirstChild(Emit.Parent.Name)
			end
		end
	end

	-- Kill Feed
	Humanoid.Died:Connect(function()
		local Streak = Character:GetAttribute("Streak")
		-- Destroy ultimate
		if Character:FindFirstChild("Ultimate") then
			Character:FindFirstChild("Ultimate"):Destroy()
		end
		
		Player:SetAttribute("HasDied", true)
		task.delay(3, function()
			if Player:GetAttribute("HasDied") == true then
				Player:LoadCharacter()
			end
		end)
		
		Character:SetAttribute("InUltimate", false)
		Character:SetAttribute("CanShoot", true)
		
		Character:FindFirstChildOfClass("Highlight"):Destroy()

		-- Ragdoll
		local CanRagdoll = RagdollOnDeath(Player)

		if CanRagdoll then
			Humanoid:UnequipTools()
			StarterGUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end
		-- Decrease money & spawn money on his death. if touched, add money to the player
		local Killer = Character:GetAttribute("Killer")
		local Distance = Character:GetAttribute("Distance")

		if MoneyStore:Get(0) >= 10 then
			MoneyStore:Increment(-10)

			-- Spawning money
			local MoneyClone = Objects:WaitForChild("Money"):Clone()
			MoneyClone.CFrame = Character.HumanoidRootPart.CFrame
			MoneyClone.Parent = workspace
			game:GetService("Debris"):AddItem(MoneyClone, 10)

			MoneyClone.Touched:Connect(function(HitPart)
				local HitParent = HitPart.Parent
				if HitParent and HitParent:FindFirstChild("Humanoid") then
					local Hum: Humanoid = HitParent:FindFirstChild("Humanoid")
					if Hum:GetState() == Enum.HumanoidStateType.Dead then
						return
					end

					local Player = Players:GetPlayerFromCharacter(HitParent)
					local HasPass = MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, GamePassIDs["2X Money"])
					local MoneyStore = DataStore2("Money", Player)
					if workspace:GetAttribute("Event") == "Double Money" or HasPass then
						MoneyStore:Increment(20)
					else
						MoneyStore:Increment(10)
					end
					MoneyClone:Destroy()
				end
			end)
		end

		if Killer ~= "" and Killer ~= Player.Name then -- Kill Handler
			-- Streak
			local KillerCharacter = workspace:FindFirstChild(Killer)
			local KillerHumanoid = KillerCharacter:FindFirstChild("Humanoid")
			local KillerStreakGUI = KillerCharacter.Head:FindFirstChild("StreakGUI")
			-- Kill Text Popup
			local KillerPlayer = Players:GetPlayerFromCharacter(KillerCharacter)
			local KillerGUI = KillerPlayer:WaitForChild("PlayerGui"):WaitForChild("Kill")
			TweenService:Create(KillerGUI:WaitForChild("TextLabel"), TweenInfo.new(0.05, Enum.EasingStyle.Bounce), {Size = UDim2.new(0.163, 0, 0.027, 0)}):Play()
			task.delay(2, function()
				TweenService:Create(KillerGUI:WaitForChild("TextLabel"), TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			end)
			-- Update Money & Kills
			local MoneyStore = DataStore2("Money", KillerPlayer)
			local KillsStore = DataStore2("Kills", KillerPlayer)
			local XPStore = DataStore2("XP", KillerPlayer)
			-- Check if own pass
			local HasCustomSoundFXPass
			local TwoTimesMoney
			local TwoTimesXP
			
			local success, message = pcall(function()
				 HasCustomSoundFXPass = MarketPlaceService:UserOwnsGamePassAsync(KillerPlayer.UserId, GamePassIDs["Custom Kill Sound"])
				 TwoTimesMoney = MarketPlaceService:UserOwnsGamePassAsync(KillerPlayer.UserId, GamePassIDs["2X Money"])
				 TwoTimesXP = MarketPlaceService:UserOwnsGamePassAsync(KillerPlayer.UserId, GamePassIDs["2X XP"])
			end)
			
			if not success then
				warn(message)
			end
			
			if HasCustomSoundFXPass then
				if KillerPlayer:GetAttribute("CustomSFX") then
					local Sound = Instance.new("Sound")
					Sound.Parent = Player.Character.HumanoidRootPart
					Sound.SoundId = KillerPlayer:GetAttribute("CustomSFX")
					Sound.Volume = 5
					Sound:Play()
				else
					warn("Player owns custom sfx gamepass but has no attribute of it")
				end
			end
			
			if workspace:GetAttribute("Event") == "Double Money" or TwoTimesMoney then
				if TwoTimesXP then
					KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">(2*25)$ & </font><font color="#3480EB">+(2*5XP)</font> | Killed '.. Player.Name
					XPStore:Increment(10)
				else
					KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">(2*25)$ & </font><font color="#3480EB">+5XP</font> | Killed '.. Player.Name
					XPStore:Increment(5)
				end
				KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">(2*25)$ & </font><font color="#3480EB">+5XP</font> | Killed '.. Player.Name
				MoneyStore:Increment(50)
				XPStore:Increment(5)
				KillerCharacter:SetAttribute("Streak", KillerCharacter:GetAttribute("Streak") + 1)
			else
				if TwoTimesXP then
					KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">(2*25)$ & </font><font color="#3480EB">+(2*5XP)</font> | Killed '.. Player.Name
					XPStore:Increment(10)
				else
					KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">(2*25)$ & </font><font color="#3480EB">+5XP</font> | Killed '.. Player.Name
					XPStore:Increment(5)
				end
				KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">25$ & </font><font color="#3480EB">+5XP</font> | Killed '.. Player.Name
				MoneyStore:Increment(25)
				KillerCharacter:SetAttribute("Streak", KillerCharacter:GetAttribute("Streak") + 1)
			end
			KillsStore:Increment(1)
			-- Update killfeed
			KillEvent:FireAllClients(Player, Killer, Distance, "Killfeed")
		end

		-- Spawn GTA Theme Death
		local KilledPLRKillGUI = Player:WaitForChild("PlayerGui").KillGUI
		local DarkBackGround = KilledPLRKillGUI.DarkBackground
		local KillTextLabel = DarkBackGround.Main.KillText

		KillTextLabel.Text = KillTexts[math.random(1, #KillTexts)]

		TweenService:Create(DarkBackGround, TweenInfo.new(.4), {BackgroundTransparency = 0.3}):Play()
		TweenService:Create(DarkBackGround:WaitForChild("Main"), TweenInfo.new(.2), {Size = UDim2.new(1, 0, 0.3, 0)}):Play()
		DarkBackGround.Visible = true
		task.delay(3.5, function()
			TweenService:Create(DarkBackGround:WaitForChild("Main"), TweenInfo.new(.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
			TweenService:Create(DarkBackGround, TweenInfo.new(.4), {BackgroundTransparency = 0}):Play()
			DarkBackGround.Visible = false
		end)
		-- Adding ult cooldown if needed
		if Character:GetAttribute("UltimateCooldown") == true then
			local UltChecker = Player:FindFirstChild("IsUlted") or Instance.new("BoolValue")
			UltChecker.Name = "IsUlted"
			UltChecker.Value = true
			UltChecker.Parent = Player
			
			local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
			local Cooldown = string.match(CooldownText.Text, "%(.*%)")
			if not Cooldown then return end
			Cooldown = string.split(Cooldown, "(")
			Cooldown[2] = string.split(Cooldown[2], ")")
			Cooldown = Cooldown[2][1]
			task.delay(tonumber(Cooldown), function()
				UltChecker:Destroy()
				Character:SetAttribute("UltimateCooldown", false)
			end)
		end
	end)
end

Shop.OnServerInvoke = function(Player, Type, Weapon)
	if Type == "Purchase" then
		-- Checking if player owns weapon & returning if so
		local WeaponsPlayerHas = PlayerDataHandler:Get(Player, "Inventory")
		for Index, WeaponVal in pairs(WeaponsPlayerHas) do
			if Weapon == WeaponVal then return end
		end
		-- Purchasing if can
		local MoneyStore = DataStore2("Money", Player)
		local LevelStore = DataStore2("Level", Player)
		if MoneyStore:Get() >= Weapons[Weapon].Cost and LevelStore:Get() >= Weapons[Weapon].Level then
			MoneyStore:Increment(-(Weapons[Weapon].Cost))
			
			PlayerDataHandler:Update(Player, "Inventory", function(currentInventory)
				table.insert(currentInventory, Weapon)
				return currentInventory
			end)
			return "Bought"
		end
		
	elseif Type == "Equip" then
		-- Returning if player already has weapon equipped
		if Player.Character and Player.Character:GetAttribute("Killer") ~= "" then return end
		if Player.Character and Player.Character:GetAttribute("Ragolled") == true then return end
		if Player.Character and Player.Character:GetAttribute("InUltimate") == true then return end
		if Player.Character.Humanoid and Player.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
		if Player.ValuesFolder.Weapons.Value == Weapon then 
			return 
		end
		-- Checking if player has weapon
		local WeaponsPlayerHas = PlayerDataHandler:Get(Player, "Inventory")
		for Index, WeaponVal in pairs(WeaponsPlayerHas) do
			if table.find(WeaponsPlayerHas, WeaponVal) then
				-- Adding weapon
				local EquippedWeapon = PlayerDataHandler:Get(Player, "EquippedWeapon")
				PlayerDataHandler:Update(Player, "EquippedWeapon", function(currentWeaponEquipped)
					currentWeaponEquipped = Weapon
					Player:LoadCharacter()
					return currentWeaponEquipped
				end)

				Player.ValuesFolder.Weapons.Value = Weapon
				local Character = Player.Character or Player.CharacterAdded:Wait()
				Character:SetAttribute("Weapon", Weapon)
				GetWeapon(Player)
				local HasDied = Instance.new("BoolValue")
				HasDied.Name = "IsUlted"
				HasDied.Parent = Player

				local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
				local Cooldown = string.match(CooldownText.Text, "%(.*%)")
				if not Cooldown then return end
				Cooldown = string.split(Cooldown, "(")
				Cooldown[2] = string.split(Cooldown[2], ")")
				Cooldown = Cooldown[2][1]
				task.delay(tonumber(Cooldown), function()
					Character:SetAttribute("UltimateCooldown", false)
					HasDied:Destroy()
				end)

				Player:LoadCharacter()
				-- Returning
				return "Equip"
			end
		end
		
	elseif Type == "Check" then
		local WeaponsPlayerHave = PlayerDataHandler:Get(Player, "Inventory")
		local EquippedWeapon = PlayerDataHandler:Get(Player, "EquippedWeapon")
		-- Checking if player already has the weapon equipped
		if string.lower(EquippedWeapon) == string.lower(Weapon) then
			return "Equipped"
		end
		
		-- Check if player has weapon or not
		for Index, WeaponsInTable in pairs(WeaponsPlayerHave) do
			if string.lower(Weapon) == string.lower(WeaponsInTable) then
				return "Equip"
			end
		end
		return "Purchase"
	end
end

local function PlayLevelUpVFX(Player)
	task.spawn(function()
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local LevelUpPart = ServerStorage:WaitForChild("LevelUpPart")
		local VFX = LevelUpPart:WaitForChild("LevelUpVFX"):Clone()
		VFX.Parent = Character:FindFirstChild("HumanoidRootPart")
		task.delay(2, function()
			VFX:Destroy()
		end)
		
		CameraHandler:FireClient(Player)
		VFX:FindFirstChild("Level Up"):Play()
		
		TweenService:Create(Player.PlayerGui.Main.LevelText, TweenInfo.new(0.4), {Position = UDim2.new(0.5, 0, 0.09, 0)}):Play()
		task.delay(1.5, function()
			TweenService:Create(Player.PlayerGui.Main.LevelText, TweenInfo.new(0.4), {Position = UDim2.new(0.5, 0, -1, 0)}):Play()
		end)
		for _, Emitter in ipairs(VFX:GetDescendants()) do
			if Emitter:IsA("ParticleEmitter") then
				Emitter:Emit(Emitter:GetAttribute("EmitCount"))
			end
		end
		
		local KillerGUI = Player:WaitForChild("PlayerGui"):WaitForChild("Kill")
		TweenService:Create(KillerGUI:WaitForChild("TextLabel"), TweenInfo.new(0.05, Enum.EasingStyle.Bounce), {Size = UDim2.new(0.163, 0, 0.027, 0)}):Play()
		task.delay(2, function()
			TweenService:Create(KillerGUI:WaitForChild("TextLabel"), TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		end)
		
		local MoneyStore = DataStore2("Money", Player)
		MoneyStore:Increment(100)
		KillerGUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">100$</font> | Leveled up'
	end)
end

local function PlayerAdded(Player)
	--|| Datastore
	-- Money
	local MoneyStore = DataStore2("Money", Player)

	local leaderstats = Instance.new("Folder", Player)
	leaderstats.Name = "leaderstats"

	local valuesfldr = Instance.new("Folder", Player)
	valuesfldr.Name = "ValuesFolder"

	local Money = Instance.new("IntValue", leaderstats)
	Money.Name = "Money"

	local function UpdateMoney(UpdatedMoney)
		Money.Value = UpdatedMoney
		LeaderboardStore:SetAsync(Player.Name, Money.Value)
		GuiHandler:UpdateMoney(Player)
	end

	-- Kills
	local KillsStore = DataStore2("Kills", Player)

	local Kills = Instance.new("IntValue", leaderstats)
	Kills.Name = "Kills"

	local function UpdateKills(UpdatedKills)
		Kills.Value = UpdatedKills
		KillsLeaderboardStore:SetAsync(Player.Name, Kills.Value)
	end
	
	local WeaponsStore = DataStore2("Weapons", Player)

	local Weapons = Instance.new("StringValue", valuesfldr)
	Weapons.Name = "Weapons"
	
	-- Level
	local Level = Instance.new("IntValue", valuesfldr)
	Level.Name = "Level"
	local LevelStore = DataStore2("Level", Player)
	
	local function UpdateLevel(UpdatedLevel)
		Level.Value = UpdatedLevel
		local LevelText = Player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("LevelText")
		LevelText.Text = "LEVEL: ".. Level.Value
		LevelText.Visible = true
	end
	
	local XP = Instance.new("IntValue", valuesfldr)
	XP.Name = "XP"
	local XPStore = DataStore2("XP", Player)
	
	local function UpdateXP(UpdatedXP)
		XP.Value = UpdatedXP
		local Level = LevelStore:Get()
		
		if XP.Value >= (math.pow(Level, 3) * 10) then
			local XPLeft = XP.Value - (math.pow(Level, 3) * 10)
			XPStore:Set(XPLeft)
			LevelStore:Increment(1)
			MoneyStore:Increment(150)
			-- Text
			local GUI = Player:WaitForChild("PlayerGui"):WaitForChild("Kill")
			TweenService:Create(GUI:WaitForChild("TextLabel"), TweenInfo.new(0.05, Enum.EasingStyle.Bounce), {Size = UDim2.new(0.163, 0, 0.027, 0)}):Play()
			GUI:WaitForChild("TextLabel").Text = '<font color="#FCF003">+150$</font> | LEVELED UP'
			task.delay(2, function()
				TweenService:Create(GUI:WaitForChild("TextLabel"), TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			end)
			-- VFX
			PlayLevelUpVFX(Player)
		end
		local XPText = Player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("XPText")
		XPText.Text = XP.Value.. "/"..(math.pow(Level, 3) * 10).. " XP"
		XPText.Visible = true
	end
	
	if RunService:IsStudio() then
		for _, Player in ipairs(game.Players:GetPlayers()) do
			MoneyStore:Set(1000000000)
			LevelStore:Set(50)
		end
	end
	-- Events
	coroutine.wrap(function()
		while task.wait() do
			if not EventOnGoing then
				EventOnGoing = true
				EventHandler:Init()
				task.wait(135)
				EventOnGoing = false
			end
		end
	end)()
	
	-- Weapons
	local function UpdateWeapons(UpdatedWeapon)
		local EquippedWeapon = PlayerDataHandler:Get(Player, "EquippedWeapon")
		Weapons.Value = EquippedWeapon
		Player.Character:SetAttribute("Weapon", Weapons.Value)
	end
	
	CharacterAdded(Player.Character or Player.CharacterAppearanceLoaded:Wait())
	Player.CharacterAppearanceLoaded:Connect(CharacterAdded)

	-- Updating & standardizing the datastores
	UpdateMoney(MoneyStore:Get(0))
	MoneyStore:OnUpdate(UpdateMoney)

	UpdateKills(KillsStore:Get(0))
	KillsStore:OnUpdate(UpdateKills)

	UpdateWeapons(WeaponsStore:Get("Apple"))
	WeaponsStore:OnUpdate(UpdateWeapons)
	
	UpdateLevel(LevelStore:Get(0))
	LevelStore:OnUpdate(UpdateLevel)
	
	UpdateXP(XPStore:Get(0))
	XPStore:OnUpdate(UpdateXP)

	Money:GetPropertyChangedSignal("Value"):Connect(function()
		GuiHandler:UpdateMoney(Player)
	end)
end

DataEvent.OnServerEvent:Connect(function(Player, Winner)
	local MoneyStore = DataStore2("Money", game:GetService("Players"):FindFirstChild(Winner))
	MoneyStore:Increment(150)
	GuiHandler:Status(game:GetService("Players"):FindFirstChild(Winner), "1v1")
end)

WeaponActivation.OnServerEvent:Connect(function(Player, Type, MousePosition, FirePoint, Weapon, SFX)
	if Type == "Normal" then
		local Weapon, WeaponName = RetrieveWeapon(Player)
		local WeaponOBJ = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("Throwable"):FindFirstChild(WeaponName):WaitForChild("Handle")
		Weapon:Activated(Player, MousePosition, FirePoint, WeaponOBJ)
	elseif Type == "UltimateBegin" then
		local Weapon, WeaponName = RetrieveWeapon(Player)
		Weapon:Ultimate(Player, "Begin")
	elseif Type == "CheckHitbox" then
		local Weapon, WeaponName = RetrieveWeapon(Player)
		Weapon:Ultimate(Player, "CheckHitbox", MousePosition, 1)
	elseif Type == "SecondAttackHitbox" then
		local Weapon, WeaponName = RetrieveWeapon(Player)
		Weapon:Ultimate(Player, "CheckHitbox", nil, 2)
	elseif Type == "Detonate" then
		local Weapon, WeaponName = RetrieveWeapon(Player)
		Weapon:Ultimate(Player, "Detonate", MousePosition)
	end
end)

--[[
UpdateLoadingState.OnServerEvent:Connect(function(Player, Type)
	local Character = workspace:FindFirstChild(Player.Name)
	
	-- Spawning
	if Type == "Cancel" then
		if Player:GetAttribute("Loading") == false then return end
		local SpawnPoints = workspace:WaitForChild("Map"):WaitForChild("SpawnPoints"):GetChildren()
		
		local FoundSpot
		task.spawn(function()
			repeat
				task.wait()
				local SpawnPoint = SpawnPoints[math.random(1, #SpawnPoints)]
				print(SpawnPoint)
				print(SpawnPoint:GetAttribute("RecentSpawn"))
				if SpawnPoint:GetAttribute("RecentSpawn") == false then
					Character.HumanoidRootPart.CFrame = SpawnPoint.CFrame
					SpawnPoint:SetAttribute("RecentSpawn", true)
					FoundSpot = true
					task.delay(7, function()
						SpawnPoint:SetAttribute("RecentSpawn", false)
					end)
				end
			until FoundSpot == true
		end)
		-- Add Highlight
		local HighLight: Highlight = Instance.new("Highlight")
		HighLight.FillTransparency = 1
		HighLight.Parent = Character
		Character:SetAttribute("Loading", false)
	else
		Character:SetAttribute("Loading", true)
	end
end) ]]

WeaponInit.OnServerInvoke = function(Player) -- Makes it so you can access the weapon on client
	local EquippedWeapon = PlayerDataHandler:Get(Player, "EquippedWeapon")
	Player.Character:SetAttribute("Weapon", EquippedWeapon)

	local StarterWeapon
	-- = Weapons.Throwables.Apple:GetModel():Clone()
	for Key, Val in pairs(Weapons) do
		if Key == EquippedWeapon then
			StarterWeapon = Val:GetModel():Clone()
		end
	end
	local BackPack = Player:WaitForChild("Backpack")
	
	-- StarterWeapon.Name = Player.Name.. " ".. StarterWeapon.Name
	StarterWeapon.Parent = BackPack

	return StarterWeapon
end

for _, Obj in ipairs(workspace:WaitForChild("Map"):GetDescendants()) do
	if Obj.Name == "DeadZone" then
		Obj.Touched:Connect(function(Hit)
			local HitParent = Hit.Parent
			if HitParent and HitParent:FindFirstChild("Humanoid") then
				local Hum: Humanoid = HitParent:FindFirstChild("Humanoid")
				Hum.Health = 0
			end
		end)
	end
end

CheckServerValue.OnServerEvent:Connect(function(Player)
	local Character = Player.Character
	if Character:GetAttribute("SlideDebounce") == true then return end
	if Character:GetAttribute("Ragdolled") == true then return end
	if Character:GetAttribute("Loading") == true then return end
	
	Character:SetAttribute("SlideDebounce", true)
	task.delay(1.4, function()
		Character:SetAttribute("SlideDebounce", false)
	end)
	CheckServerValue:FireClient(Player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	coroutine.wrap(PlayerAdded)(player)
end

Players.PlayerAdded:Connect(PlayerAdded)