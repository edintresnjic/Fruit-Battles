--[[

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
-- GUI
local MainFrame = script.Parent:WaitForChild("MainFrame")
local Gui = MainFrame.Parent.Parent
local Buttons = MainFrame:WaitForChild("Buttons")
local Popups = MainFrame:WaitForChild("Popups")
local ShopPopup = Popups:WaitForChild("Shop")
local GamePasses = MainFrame:WaitForChild("GamePassFrame"):WaitForChild("Gamepasses"):GetChildren()
local SettingsFrame = MainFrame:WaitForChild("Popups"):WaitForChild("Settings")
-- Instances
local Camera = workspace.CurrentCamera
local CameraPos = workspace:WaitForChild("CameraStartPosition")

-- Camera
Camera.CameraType = Enum.CameraType.Scriptable
Camera.CameraSubject = CameraPos
Camera.CFrame = CameraPos.CFrame * CFrame.new(0, 3, 0)

--|| Variables ||--
local Connection: RBXScriptConnection
UpdateLoadingState:FireServer("Add")

local GamePassIDs = {
	["2X Money"] = 164543945,
	["Custom Kill Sound"] = 164544847
}

local Settings = {
	["Lobby Music"] = true
}

--|| Main Code ||--
------------------------------------------------------------
local Char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")

MainFrame:WaitForChild("Title"):WaitForChild("Level"):WaitForChild("Level").Text = "LEVEL: ".. game.Players.LocalPlayer:WaitForChild("ValuesFolder"):WaitForChild("Level").Value
MainFrame:WaitForChild("Title"):WaitForChild("Level"):WaitForChild("XP").Text = game.Players.LocalPlayer:WaitForChild("ValuesFolder"):WaitForChild("XP").Value.. "/".. (math.pow(game.Players.LocalPlayer:WaitForChild("ValuesFolder"):WaitForChild("Level").Value, 3) * 10).. " XP"

TweenService:Create(game:WaitForChild("Lighting"):FindFirstChild("Blur"), TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Size = 13}):Play()
TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, 0.18, 0)}):Play()
TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.7, 0)}):Play()
TweenService:Create(MainFrame.GamePassFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0, 0, 0.42, 0)}):Play()
TweenService:Create(MainFrame.SoloMode, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.15, 0, 0.07, 0)}):Play()
if Settings["Lobby Music"] == true then
	script:WaitForChild("Lobby"):Play()
	script:WaitForChild("Lobby").Looped = true
end

Humanoid.WalkSpeed = 0
Humanoid.JumpHeight = 0

local function PlaySound()
	local Sound = script:WaitForChild("GUISound")
	Sound:Play()
end

for _, Frame: Frame in ipairs(Buttons:GetChildren()) do
	Frame.MouseEnter:Connect(function()
		TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0.74, 0, 0.24, 0)}):Play()
		PlaySound()
	end)
	
	Frame:FindFirstChildOfClass("TextButton").MouseButton1Click:Connect(function()
		if Frame.Name == "Play" then
			-- Click sfx
			PlaySound()
			-- Main Gui Tween
			TweenService:Create(game:WaitForChild("Lighting"):FindFirstChild("Blur"), TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Size = 0}):Play()
			TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, -0.3, 0)}):Play()
			TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
			TweenService:Create(MainFrame.GamePassFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(-1, 0, 0.42, 0)}):Play()
			TweenService:Create(MainFrame.SoloMode, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.15, 0, -0.5, 0)}):Play()
			-- Camera
			local CameraTween: Tween = TweenService:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {CFrame = Camera.CFrame * CFrame.new(0, 0, -15)}):Play()
			task.wait(0.5)
			-- Disabling attribute & spawning
			UpdateLoadingState:FireServer("Cancel")

			Camera.CameraType = Enum.CameraType.Custom
			-- game.Players.LocalPlayer:LoadCharacter()
			Camera.CameraSubject = game.Players.LocalPlayer.Character
			-- Sound
			script:WaitForChild("Lobby").Looped = false
			TweenService:Create(script:WaitForChild("Lobby"), TweenInfo.new(0.6, Enum.EasingStyle.Linear), {Volume = 0}):Play()
			task.wait(0.6)
			Humanoid.WalkSpeed = 16
			Humanoid.JumpHeight = 7.2
			script:WaitForChild("Lobby"):Stop()
			
		elseif Frame.Name == "1V1Queue" then
			TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
			StartQueue:FireServer()
			Gui.Main["1v1"].OneOnOneFrame.No.MouseButton1Click:Connect(function()
				TweenService:Create(Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.7, 0)}):Play()
				PlaySound()
			end)
			PlaySound()
		elseif Frame.Name == "Shop" then
			TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, -0.3, 0)}):Play()
			TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
			TweenService:Create(Popups.Shop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.35, 0, 0.5, 0)}):Play()
			
			Popups.Shop.BTN.TextLabel.MouseButton1Click:Connect(function()
				TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, 0.18, 0)}):Play()
				TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.7, 0)}):Play()
				TweenService:Create(Popups.Shop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(-1.5, 0, 0.5, 0)}):Play()
				PlaySound()
			end)
			PlaySound()
		elseif Frame.Name == "Settings" then
			TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, -0.3, 0)}):Play()
			TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
			TweenService:Create(Popups.Settings, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
			
			Popups.Settings.BTN.TextLabel.MouseButton1Click:Connect(function()
				TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, 0.18, 0)}):Play()
				TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.7, 0)}):Play()
				TweenService:Create(Popups.Settings, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(-1.5, 0, 0.5, 0)}):Play()
				PlaySound()
			end)
			PlaySound()
		end
	end)
	
	Frame.MouseLeave:Connect(function()
		TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0.69, 0, 0.194, 0)}):Play()
	end)
end

MainFrame:WaitForChild("SoloMode"):WaitForChild("TextLabel").MouseButton1Click:Connect(function()
	TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, -0.3, 0)}):Play()
	TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
	TweenService:Create(MainFrame.Status, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
end)

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
		-- Tweens
		TweenService:Create(script.Parent.Status, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		TweenService:Create(game:WaitForChild("Lighting"):FindFirstChild("Blur"), TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Size = 20}):Play()
		
		TweenService:Create(MainFrame.Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.282, 0, -0.3, 0)}):Play()
		TweenService:Create(MainFrame.Buttons, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		TweenService:Create(Popups.Shop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), {Position = UDim2.new(-1.5, 0, 0.5, 0)}):Play()
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

for _, GamepassFrame: TextButton in pairs(GamePasses) do
	GamepassFrame.MouseEnter:Connect(function()
		TweenService:Create(GamepassFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0.82, 0, 0.367, 0)}):Play()
		PlaySound()
	end)
	
	GamepassFrame.MouseButton1Click:Connect(function()
		if GamepassFrame.Name == "Gamepass Kill"  then
			MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["Custom Kill Sound"])
		elseif GamepassFrame.Name == "Gamepass Money" then
			MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["2X Money"])
		end
	end)
	
	GamepassFrame.MouseLeave:Connect(function()
		TweenService:Create(GamepassFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0.809, 0, 0.347, 0)}):Play()
		PlaySound()
	end)
end

SettingsFrame:WaitForChild("Disable Intro Music"):WaitForChild("Inner").MouseButton1Click:Connect(function()
	if Settings["Lobby Music"] == true then
		TweenService:Create(SettingsFrame:WaitForChild("Disable Intro Music"):WaitForChild("Inner"), TweenInfo.new(0.15), {Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 37, 41)}):Play()
		Settings["Lobby Music"] = false
		script:WaitForChild("Lobby"):Stop()
	else
		TweenService:Create(SettingsFrame:WaitForChild("Disable Intro Music"):WaitForChild("Inner"), TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(117, 255, 25)}):Play()
		Settings["Lobby Music"] = true
		script:WaitForChild("Lobby"):Play()
		script:WaitForChild("Lobby").Looped = true
	end
end)

SettingsFrame:WaitForChild("SoundID").Focused:Connect(function()
	local HasPass
	local success, message = pcall(function()
		HasPass = MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, GamePassIDs["Custom Kill Sound"])
	end)
	
	if not success then
		warn("Error while checking if player has pass:", message)
		return
	end
	
	if HasPass then
		SettingsFrame:WaitForChild("Apply").MouseButton1Click:Wait()
		-- local Sound = "rbxassetid://".. SettingsFrame:WaitForChild("SoundID").Text
		SetSound:FireServer(SettingsFrame:WaitForChild("SoundID").Text)		
	else
		MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["Custom Kill Sound"])
		SettingsFrame:WaitForChild("Apply").MouseButton1Click:Connect(function()
			MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, GamePassIDs["Custom Kill Sound"])
		end)
	end
end)

SetSound.OnClientEvent:Connect(function(Status)
	if Status == "Error" then
		local PreviousPlaceHolderText = "Apply"
		SettingsFrame:WaitForChild("Apply").Text = "Error! Try a different one."
		task.delay(1, function()
			SettingsFrame:WaitForChild("Apply").Text = PreviousPlaceHolderText
		end)
		SettingsFrame:WaitForChild("SoundID").Text = ""
	else		
		local PreviousPlaceHolderText = "Apply"
		SettingsFrame:WaitForChild("Apply").Text = "Success!"
		task.delay(1, function()
			SettingsFrame:WaitForChild("Apply").Text = PreviousPlaceHolderText
		end)
		
	end
end) ]]--