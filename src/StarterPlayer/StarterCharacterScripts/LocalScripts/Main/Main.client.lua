-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Instances
local Events = ReplicatedStorage:WaitForChild("Events")

-- Events
local SpawnVFX = Events:WaitForChild("SpawnVFX")
local UpdateStandPos = Events:WaitForChild("UpdateStandPos")

-- Variables
local Player = game.Players.LocalPlayer
local PlayerCharacter = Player.Character or Player.CharacterAdded:Wait()


-- Update Queue Text
workspace:GetAttributeChangedSignal("PlayersInQueue"):Connect(function()
	local TextStatus = Player.PlayerGui.Main["1v1"].OneOnOneFrame.TextLabel
	TextStatus.Text = "You are now on a queue for a 1v1. You will join shortly. Current people in queue: ".. tostring(workspace:GetAttribute("PlayersInQueue"))
end)

SpawnVFX.OnClientEvent:Connect(function(Object, Position, Playsound, Type, Player)
	print("Received")
	if Type ~= nil then
		if Type == "StreakAdd" then
			local Character = Player.Character or Player.CharacterAppearanceLoaded:Wait()
			local StreakVFX = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Streak")
			for _, Emit in ipairs(StreakVFX:GetDescendants()) do
				if Emit:IsA("ParticleEmitter") then
					local Copy = Emit:Clone()
					Copy.Parent = Character:FindFirstChild(Emit.Parent.Name)
				end
			end
			
		elseif Type == "StreakRemove" then
			local Character = Player.Character or Player.CharacterAppearanceLoaded:Wait()
			for _, Emitter in ipairs(Character:GetDescendants()) do
				if Emitter:IsA("ParticleEmitter") then
					Emitter:Destroy()
				end
			end
		end
	else
		local VFX = Object:FindFirstChild("VFX"):Clone()
		VFX.Position = Position
		VFX.Parent = workspace
		
		if Playsound then
			local ImpactSFX = Object.Parent:WaitForChild("Sound"):WaitForChild("Impact"):Clone()
			ImpactSFX.Parent = VFX
			ImpactSFX:Play()
		end

		for _, Effect in pairs(VFX:GetDescendants()) do
			if Effect:IsA("ParticleEmitter") then
				Effect:Emit(Effect:GetAttribute("EmitCount"))
			end
		end

		task.delay(1, function()
			VFX:Destroy()
		end)
	end
end)

PlayerCharacter:GetAttributeChangedSignal("UltimateCooldown"):Connect(function()
	local UltimateStatus = Player:WaitForChild("PlayerGui"):WaitForChild("Cooldown"):WaitForChild("Ultimate Status")
	local UltimateCooldownText = Player:WaitForChild("PlayerGui"):WaitForChild("Cooldown"):WaitForChild("Attacks"):WaitForChild("Ultimate")

	if PlayerCharacter:GetAttribute("UltimateCooldown") == false then
		UltimateStatus.Text = "⚠ ULTIMATE IS READY ⚠"
		TweenService:Create(UltimateStatus, TweenInfo.new(0.2), {Position = UDim2.new(0.251, 0, 0.016, 0)}):Play()
	else
		if PlayerCharacter:GetAttribute("InUltimate") == false then
			TweenService:Create(UltimateStatus, TweenInfo.new(0.2), {Position = UDim2.new(0.251, 0, 1.5, 0)}):Play()
		end
	end
end)

UpdateStandPos.OnClientEvent:Connect(function(Stand, PlayerCharacter)
	task.spawn(function()
		local Connection: RBXScriptConnection
		Connection = RunService.Stepped:Connect(function()
			if not Stand:FindFirstChild("HumanoidRootPart") then
				Connection:Disconnect()
			else
				game:GetService("TweenService"):Create(Stand.HumanoidRootPart, TweenInfo.new(0.15), {CFrame = PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 3.5, 3)}):Play()
			end
		end)
	end)
end)