local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RagdollModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("Ragdoll"))
local RagdollEvent : RemoteFunction = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RagdollCallback")

local RagdollDuration : number = 2.5

function RagdollEvent.OnServerInvoke(player : Player)
	if not player.Character or not player.Character:FindFirstChild("Humanoid") then
		return false
	end
	
	local CanRagdoll = not RagdollModule.IsRagdolled(player.Character.Humanoid)
	
	if CanRagdoll then
		local Motors = RagdollModule.CreateJoints(player.Character)
		RagdollModule.Ragdoll(player.Character)
		RagdollModule.SetMotorsEnabled(Motors, false)
		
		task.delay(RagdollDuration, function()
			RagdollModule.DestroyJoints(player.Character)
			RagdollModule.SetMotorsEnabled(Motors, true)
			RagdollModule.UnRagdoll(player.Character)
		end)
	end
	
	return CanRagdoll, CanRagdoll and RagdollDuration
end

Players.PlayerAdded:Connect(function(player : Player)
	player.CharacterAdded:Connect(function(character : Model)
		local humanoid : Humanoid = character:WaitForChild("Humanoid")
		humanoid.RequiresNeck = false
		humanoid.BreakJointsOnDeath = false
		
		humanoid.Died:Once(function()
			if not RagdollModule.IsRagdolled(character) then
				local Motors = RagdollModule.CreateJoints(player.Character)
				RagdollModule.Ragdoll(player.Character)
				RagdollModule.SetMotorsEnabled(Motors, false)
			end
		end)
	end)
end)