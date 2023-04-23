local Items = {}
local Frames = {}
local Images = {
	["Apple"] = "rbxassetid://13033399561",
	["Banana"] = "rbxassetid://13033441530",
	["Grape"] = "rbxassetid://13123476884",
	["Watermelon"] = "rbxassetid://13125373387",
	["Lemon"] = "rbxassetid://13142915466",
	["Pumpkin"] = "rbxassetid://13150530724",
	["Rokakaka"] = "rbxassetid://13213813637",
	["GomuGomuNoMi"] = "rbxassetid://13212558790"
}
local Click = 1
local UIS = game:GetService("UserInputService")
local Equipped = nil
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Debounce = false
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Player = game.Players.LocalPlayer
local Char: Model = Player.Character or Player.CharacterAdded:Wait()

local function Scan(location)
	for i, v in pairs(location:GetChildren()) do
		if v:IsA("Tool") then
			table.insert(Items, v)
		end
	end
end

local function Update()
	if Char:GetAttribute("Loading") == true then return end
	for i, v in pairs(Frames) do
		v:Destroy()
	end
	for i, v in pairs(Items) do
		local Sam = script.Sample:Clone()
		Sam.Name = v.Name
		Sam.ImageLabel.Image = Images[Sam.Name]
		Sam.Parent = script.Parent
		table.insert(Frames, Sam)
		Sam.MouseButton1Click:Connect(function()
			if Character:GetAttribute("CanShoot") == true and not Debounce then
				Debounce = true
				if Equipped ~= v then
					Character.Humanoid:UnequipTools(v)
					wait()
					Character.Humanoid:EquipTool(v)
					Equipped = v
				else
					Character.Humanoid:UnequipTools(v)
					Equipped = nil
				end
				task.wait(0.5)
				Debounce = false
			end
		end)
	end
end


local function BackPackChanged()
	Items = {}
	Scan(Character)
	Scan(Player:WaitForChild("Backpack"))
	Update()
end

UIS.InputBegan:Connect(function(Input, GameProcessedEvent)
	if GameProcessedEvent then return end

	if Input.KeyCode == Enum.KeyCode.One then
		if not Debounce and Character:GetAttribute("CanShoot") == true then
			Debounce = true

			if Click % 2 == 0 then
				Character.Humanoid:UnequipTools()
				Equipped = nil
				Click += 1
			else
				local Tool = Player.Backpack:FindFirstChildOfClass("Tool")
				Character.Humanoid:EquipTool(Tool)
				Equipped = Tool
				Click += 1
			end
			task.wait(0.5)
			Debounce = false
		end
	end
end)

Player.Backpack.ChildAdded:Connect(BackPackChanged)
Player.Backpack.ChildRemoved:Connect(BackPackChanged)

Character.ChildAdded:Connect(BackPackChanged)
Character.ChildRemoved:Connect(BackPackChanged)

Character:GetAttributeChangedSignal("Loading"):Connect(BackPackChanged)