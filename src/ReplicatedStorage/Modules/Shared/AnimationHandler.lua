local AnimationHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Animations = ReplicatedStorage:WaitForChild("Animations")


local AnimationTracks = {}

function AnimationHandler:InitAnimations(Character, AnimationType)
	
	if not Animations:FindFirstChild(AnimationType) then return end
	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:FindFirstChild("Animator") or Instance.new("Animator", Humanoid)
	
	local AnimationsTypeFolder = Animations[AnimationType]
	
	if not AnimationTracks[Character] then
		AnimationTracks[Character] = {}
	end
	
	if not AnimationTracks[Character][AnimationType] then
		AnimationTracks[Character][AnimationType] = {}
	end
	
	for i, v in pairs(AnimationsTypeFolder:GetChildren()) do
		pcall(function()
			AnimationTracks[Character][AnimationType][v.Name] = Animator:LoadAnimation(v)
			
		end)
		
	end
	
	if RunService:IsClient() then
		warn("[CLIENT]: "..AnimationType.." were successfully loaded".." - "..Character.Name)
	end
end

function AnimationHandler:PlayAnimation(Character, AnimationType, AnimationName)
	
	if not AnimationTracks[Character] then return end 
	if not AnimationTracks[Character][AnimationType] then return end 
	if not AnimationTracks[Character][AnimationType][AnimationName] then return end 

	AnimationTracks[Character][AnimationType][AnimationName]:Play()
	
end


function AnimationHandler:StopAnimation(Character, AnimationType, AnimationName)

	if not AnimationTracks[Character] then return end 
	if not AnimationTracks[Character][AnimationType] then return end 
	if not AnimationTracks[Character][AnimationType][AnimationName] then return end 

	AnimationTracks[Character][AnimationType][AnimationName]:Stop()

end

return AnimationHandler
