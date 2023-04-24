local function UpdateBasedOnEvent(Player)
	-- Update
	local Character: Model = Player.Character
	if not Character then return end
	if workspace:GetAttribute("Event") == "Zero Gravity" then
		task.spawn(function()
			while workspace:GetAttribute("Event") == "Zero Gravity" do
				if Character:FindFirstChild("Ultimate") then
					Character:FindFirstChild("Ultimate"):Destroy()
				end
				Character:SetAttribute("UltimateCooldown", true)
				Character.Humanoid.UseJumpPower = true
				Character.Humanoid.JumpPower = 30
				task.wait()
			end
		end)

	elseif workspace:GetAttribute("Event") == "One Shot" then
		task.spawn(function()
			while workspace:GetAttribute("Event") == "One Shot" do
				Character.Humanoid.Health = 1
				task.wait()
			end
		end)
	--[[
	elseif workspace:GetAttribute("Event") == "Tiny Royale" then
		if Character:FindFirstChild("Ultimate") then
			Character:FindFirstChild("Ultimate"):Destroy()
		end
		Character:SetAttribute("UltimateCooldown", true)

		print("Applying scale on: ".. Character.Name)
		local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")
		Humanoid:WaitForChild("BodyDepthScale").Value = 0.23
		Humanoid:WaitForChild("BodyWidthScale").Value = 0.23
		Humanoid:WaitForChild("BodyHeightScale").Value = 0.23
		Humanoid:WaitForChild("HeadScale").Value = 0.23
		
		-- Humanoid.HipHeight = 0.37 ]]--
	elseif workspace:GetAttribute("Event") == "" then
		Character.Humanoid.UseJumpPower = false

		Character.Humanoid.JumpHeight = 7.2
		Character.Humanoid.Health = 100
		Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")
		Humanoid:WaitForChild("BodyDepthScale").Value = 1
		Humanoid:WaitForChild("BodyWidthScale").Value = 1
		Humanoid:WaitForChild("BodyHeightScale").Value = 1
		Humanoid:WaitForChild("HeadScale").Value = 1
		-- Cooldown
		local CooldownText = Player:WaitForChild("PlayerGui"):WaitForChild("Cooldown"):WaitForChild("Attacks"):WaitForChild("Ultimate")
		local Cooldown = string.match(CooldownText.Text, "%(.*%)")

		if not Cooldown then 
			Character:SetAttribute("UltimateCooldown", false)
			return 
		end

		Cooldown = string.split(Cooldown, "(")
		Cooldown[2] = string.split(Cooldown[2], ")")
		Cooldown = Cooldown[2][1]
		task.delay(tonumber(Cooldown), function()
			Character:SetAttribute("UltimateCooldown", false)
		end)
	end
end

-- Updating when character gets loaded in to the game
game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		Character:GetAttributeChangedSignal("Loading"):Connect(function()
			if Character:GetAttribute("Loading") == false then
				print("Player has loaded in")
				UpdateBasedOnEvent(Player)
			end
		end)
	end)
end)

workspace:GetAttributeChangedSignal("Event"):Connect(function()
	for _, Player in ipairs(game.Players:GetPlayers()) do
		-- Update
		UpdateBasedOnEvent(Player)
	end
end)