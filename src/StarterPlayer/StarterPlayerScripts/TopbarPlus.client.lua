local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Icon = require(ReplicatedStorage.Modules.Utility.Icon)
local IconController = require(ReplicatedStorage.Modules.Utility.Icon.IconController)
IconController.voiceChatEnabled = true

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainFrame = PlayerGui:WaitForChild("Menu"):WaitForChild("MainFrame")
local Gui = MainFrame.Parent.Parent
local ShopPopup = PlayerGui:WaitForChild("Menu"):WaitForChild("MainFrame"):WaitForChild("Popups"):WaitForChild("Shop")
local SettingsPopup = PlayerGui:WaitForChild("Menu"):WaitForChild("MainFrame"):WaitForChild("Popups"):WaitForChild("Settings")
local Gamepasses = ShopPopup:WaitForChild("GamePassFrame"):WaitForChild("Gamepasses"):GetChildren()

--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

--|| Instances ||--
-- Folders
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Main = Modules:WaitForChild("Main")
local Events = ReplicatedStorage:WaitForChild("Events")
-- Modules
local GUIHandler = require(Main:WaitForChild("GUIHandler"))
-- Events
local StartQueue = Events:WaitForChild("StartQueue")
local ShopEvent = Events:WaitForChild("Shop")
local UpdateLoadingState = Events:WaitForChild("UpdateLoadingState")
local SetSound = Events:WaitForChild("SetSoundID")

--|| Variables ||--
local Connection: RBXScriptConnection
UpdateLoadingState:FireServer("Add")

local GamePassIDs = {
	["2X Money"] = 164543945,
	["Custom Kill Sound"] = 164544847,
	["2X XP"] = 167970838
}

local Settings = {
	["Lobby Music"] = true
}


local function PlaySound()
	local Sound = script:WaitForChild("GUISound")
	Sound:Play()
end

local ShopIcon = Icon.new()
	:setLabel("Shop")
	:setImage("rbxassetid://13214107399")
	:bindEvent("selected", function()
		TweenService:Create(ShopPopup, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.4, 0, 0.5, 0)}):Play()
		for _, Item: ImageButton in ipairs(ShopPopup:WaitForChild("Items"):GetChildren()) do
			Item.MouseButton1Click:Connect(function()
				PlaySound()
				local ShopInfo = ShopPopup:WaitForChild("Info")
				ShopInfo:WaitForChild("Image"):WaitForChild("ImageLabel").Image = Item.ImageLabel.Image
				ShopInfo:WaitForChild("ProductName").Text = Item.Name
				ShopInfo:WaitForChild("ProductInfo"):WaitForChild("DMGINFO").Text = "DAMAGE: ".. tostring(Item:GetAttribute("DMG"))
				ShopInfo:WaitForChild("ProductInfo"):WaitForChild("TYPEINFO").Text = "TYPE: ".. Item:GetAttribute("Type")
				ShopInfo:WaitForChild("ProductInfo"):WaitForChild("ULT INFO").Text = "ULTIMATE: ".. Item:GetAttribute("Ultimate")
				ShopInfo:WaitForChild("ProductInfo"):WaitForChild("LVLINFO").Text = "LEVEL REQUIRED: ".. Item:GetAttribute("Level")
				-- Check if player has weapon
				-- If not, change info btn and make it so they can buy it

				-- Check weapon status
				local Status = ShopEvent:InvokeServer("Check", ShopPopup.Info.ProductName.Text)
				if Status == "Equip" then
					ShopPopup.Info.BTN.TextLabel.Text = "EQUIP"
				elseif Status == "Equipped" then
					ShopPopup.Info.BTN.TextLabel.Text = "EQUIPPED"
				elseif Status == "Purchase" then
					ShopPopup.Info.BTN.TextLabel.Text = "PURCHASE - ".. ShopPopup.Items:FindFirstChild(ShopPopup.Info.ProductName.Text):GetAttribute("Cost")
				end
			end)
		end
		-- Equip Shop click
		ShopPopup:WaitForChild("Info"):WaitForChild("BTN"):WaitForChild("TextLabel").MouseButton1Click:Connect(function()
			PlaySound()
			if string.lower(ShopPopup:WaitForChild("Info"):WaitForChild("BTN"):WaitForChild("TextLabel").Text) == "equip" then
				-- Equipping
				ShopEvent:InvokeServer("Equip", ShopPopup.Info.ProductName.Text)
			elseif ShopPopup:WaitForChild("Info"):WaitForChild("BTN"):WaitForChild("TextLabel").Text:match("PURCHASE") then
				local Status = ShopEvent:InvokeServer("Purchase", ShopPopup.Info.ProductName.Text)
				if Status == "Bought" then
					script.PurchaseSFX:Play()
					ShopPopup:WaitForChild("Info"):WaitForChild("BTN"):WaitForChild("TextLabel").Text = "EQUIP"
				end
			end
		end)
		
		for _, GamepassFrame: TextButton in pairs(Gamepasses) do
			GamepassFrame.MouseEnter:Connect(function()
				TweenService:Create(GamepassFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0.82, 0, 0.367, 0)}):Play()
				PlaySound()
			end)

			GamepassFrame.MouseButton1Click:Connect(function()
				if GamepassFrame.Name == "Gamepass Kill"  then
					MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["Custom Kill Sound"])
				elseif GamepassFrame.Name == "Gamepass Money" then
					MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["2X Money"])
				elseif GamepassFrame.Name == "Gamepass XP" then
					MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["2X XP"])
				end
			end)

			GamepassFrame.MouseLeave:Connect(function()
				TweenService:Create(GamepassFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0.809, 0, 0.347, 0)}):Play()
				PlaySound()
			end)
		end
		
	end)
	:bindEvent("deselected", function()
		TweenService:Create(ShopPopup, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(-1.5, 0, 0.5, 0)}):Play()
	end)
	:bindToggleKey(Enum.KeyCode.B)
	

local SettingsIcon = Icon.new()
:setLabel("Settings")
:setImage("rbxassetid://13214413516")
:bindEvent("selected", function()
	TweenService:Create(SettingsPopup, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
	SettingsPopup:WaitForChild("SoundID").Focused:Connect(function()
		local HasPass
		local success, message = pcall(function()
			HasPass = MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, GamePassIDs["Custom Kill Sound"])
		end)

		if not success then
			warn("Error while checking if player has pass:", message)
			return
		end

		if HasPass then
			SettingsPopup:WaitForChild("Apply").MouseButton1Click:Wait()
			-- local Sound = "rbxassetid://".. SettingsFrame:WaitForChild("SoundID").Text
			SetSound:FireServer(SettingsPopup:WaitForChild("SoundID").Text)		
		else
			MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["Custom Kill Sound"])
			SettingsPopup:WaitForChild("Apply").MouseButton1Click:Connect(function()
				MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["Custom Kill Sound"])
			end)
		end
	end)

	SetSound.OnClientEvent:Connect(function(Status)
		if Status == "Error" then
			local PreviousPlaceHolderText = "Apply"
			SettingsPopup:WaitForChild("Apply").Text = "Error! Try a different one."
			task.delay(1, function()
				SettingsPopup:WaitForChild("Apply").Text = PreviousPlaceHolderText
			end)
			SettingsPopup:WaitForChild("SoundID").Text = ""
		else		
			local PreviousPlaceHolderText = "Apply"
			SettingsPopup:WaitForChild("Apply").Text = "Success!"
			task.delay(1, function()
				SettingsPopup:WaitForChild("Apply").Text = PreviousPlaceHolderText
			end)

		end
	end)
end)
:bindEvent("deselected", function()
	TweenService:Create(SettingsPopup, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(-1.5, 0, 0.5, 0)}):Play()
end)
:bindToggleKey(Enum.KeyCode.P)

local QueueIcon = Icon.new()
:setLabel("1V1")
:bindEvent("selected", function()
	TweenService:Create(Gui.Main["1v1"].OneOnOneFrame, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0.55, 0)}):Play()
	Gui.Main["1v1"].OneOnOneFrame.No.MouseButton1Click:Connect(function()
		PlaySound()
		TweenService:Create(Gui.Main["1v1"].OneOnOneFrame, TweenInfo.new(0.5), {Position = UDim2.new(1.5, 0, 0.55, 0)}):Play()
	end)
	Gui.Main["1v1"].OneOnOneFrame.Yes.MouseButton1Click:Connect(function()
		PlaySound()
		StartQueue:FireServer()
	end)
	PlaySound()
end)
:bindEvent("deselected", function()
	TweenService:Create(Gui.Main["1v1"].OneOnOneFrame, TweenInfo.new(0.5), {Position = UDim2.new(1.5, 0, 0.55, 0)}):Play()
end)
:bindToggleKey(Enum.KeyCode.V)

local Invite = Icon.new()
:setLabel("Invite Friends")
:setImage("rbxassetid://13214908524")
:bindEvent("selected", function()
	local SocialService = game:GetService("SocialService")
	local CanInvite = SocialService:CanSendGameInviteAsync(Player)
	if CanInvite then
		SocialService:PromptGameInvite(Player)
	end
end)
:bindToggleKey(Enum.KeyCode.M)