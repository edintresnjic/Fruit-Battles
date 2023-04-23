--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| Instances ||--
local Events = ReplicatedStorage:WaitForChild("Events")

--|| Events ||--
local SpawnAura = Events:WaitForChild("SpawnVFX")

--|| Main Code ||--
--------------------------------------------------------------
task.spawn(function()
	while task.wait(0.1) do
		local Data = {
			["HighestStreak"] = 0,
			["HighestStreakPlr"] = ""
		}
		for _, Player in ipairs(game.Players:GetPlayers()) do
			if not Player.Character then continue end
			local Character = Player.Character
			if Character:GetAttribute("Streak") == nil then continue end
			if Character:GetAttribute("Streak") > Data["HighestStreak"] then
				Data["HighestStreak"] = Character:GetAttribute("Streak")
				Data["HighestStreakPlr"] = Player.Name
			end
		end
		workspace:SetAttribute("HighestStreak", Data["HighestStreakPlr"])

		if workspace:GetAttribute("PreviousHighestStreak") ~= "" then
			if game.Players:FindFirstChild(workspace:GetAttribute("PreviousHighestStreak")) then
				local Player = game.Players:FindFirstChild(workspace:GetAttribute("PreviousHighestStreak"))
				if not Player.Character then return end

				Player.Character.Humanoid.JumpHeight = 7.2
				Player.Character.Humanoid.WalkSpeed = 16

				if Player.Character:FindFirstChildOfClass("Highlight") then
					local Outline: Highlight = Player.Character:FindFirstChildOfClass("Highlight")
					Outline.OutlineColor = Color3.fromRGB(255, 255, 255)
				end
			end
		end

		if game.Players:FindFirstChild(Data["HighestStreakPlr"]) then
			local Player = game.Players:FindFirstChild(Data["HighestStreakPlr"])
			local Character: Model = Player.Character
			if Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
				workspace:SetAttribute("PreviousHighestStreak", Player.Name)
				task.delay(0.3, function()
					workspace:SetAttribute("HighestStreak", "")
				end)
			else
				if Character:FindFirstChildOfClass("Highlight") then
					local Outline: Highlight = Character:FindFirstChildOfClass("Highlight")
					Outline.OutlineColor = Color3.fromRGB(255, 0, 4)
				end
				
				local UltimateStreak
				if not Character.Head:FindFirstChild("HighestStreakGUI") then
					UltimateStreak = ReplicatedStorage:WaitForChild("GUI"):WaitForChild("HighestStreakGUI"):Clone()
					if Character.Head then
						UltimateStreak.Parent = Character.Head
					end
				end
				task.spawn(function()
					repeat
						Character.Humanoid.JumpHeight = 15
						Character.Humanoid.WalkSpeed = 25
						task.wait()
					until Player.Name ~= workspace:GetAttribute("HighestStreak") or Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead
					workspace:SetAttribute("PreviousHighestStreak", Player.Name)
					if Character.Head:FindFirstChild("HighestStreakGUI") then
						Character.Head:FindFirstChild("HighestStreakGUI"):Destroy()
					end
				end)
			end
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(Player)
	if Player.Name == workspace:GetAttribute("HighestStreak") then
		workspace:SetAttribute("HighestStreak", "")
	elseif Player.name == workspace:GetAttribute("PreviousHighestStreak") then
		workspace:SetAttribute("PreviousHighestStreak", "")
	end
end)