-- Ragdoll Module
-- Made by Dev1n @ADRENALXNE

local PS = game:GetService('Players')
local RPS = game:GetService('ReplicatedStorage')

local stateType = Enum.HumanoidStateType

local RAGDOLL_NAME = 'RagdollConstraint'
local NOCOLLIDE_NAME = 'RagdollNoCollide'

local noCollisionMap = {
	R15 = {
		Head = {'LeftUpperArm', 'LeftUpperLeg', 'LowerTorso', 'RightUpperArm', 'RightUpperLeg'},
		LeftFoot = {'LowerTorso', 'UpperTorso'},
		LeftHand = {'LowerTorso', 'UpperTorso'},
		RightFoot = {'LowerTorso', 'UpperTorso'},
		RightHand = {'LowerTorso', 'UpperTorso'},
		LeftLowerArm = {'LowerTorso', 'UpperTorso'},
		LeftLowerLeg = {'LowerTorso', 'UpperTorso'},
		LeftUpperArm = {'LeftUpperLeg', 'LowerTorso', 'UpperTorso', 'RightUpperArm', 'RightUpperLeg'},
		LeftUpperLeg = {'LowerTorso', 'UpperTorso', 'RightUpperLeg'},
		RightLowerArm = {'LowerTorso', 'UpperTorso'},
		RightLowerLeg = {'LowerTorso', 'UpperTorso'},
		RightUpperArm = {'RightUpperLeg', 'LowerTorso', 'UpperTorso', 'LeftUpperLeg'},
		RightUpperLeg = {'LowerTorso', 'UpperTorso'},
	},
	
	R6 = {
		Head = {'Left Arm', 'Left Leg', 'Torso', 'Right Arm', 'Right Leg'},
	}
}

local function getMotors(character : Model) : {Motor6D}
	local t : {Motor6D} = {}
	local humanoid : Humanoid = character.Humanoid
	
	for _,part in character:GetChildren() do
		for _, descendant in part:GetChildren() do
			if descendant:IsA('Motor6D') then
				t[#t + 1] = descendant
			end
		end
	end
	
	return t
end

-- create NoCollisionConstraints so the character doesn't fling
local function createNoCollisionConstraints(character, rigTypeName)
	for i,subMap in noCollisionMap[rigTypeName] do
		for _,x in subMap do
			local noCollision = Instance.new('NoCollisionConstraint')
			noCollision.Name = NOCOLLIDE_NAME
			noCollision.Part0 = character[i]
			noCollision.Part1 = character[x]
			noCollision.Parent = character
			
		end
	end
end

-- Ragdoll Module
local Ragdoll = {}

-- Create joints for ragdoll
function Ragdoll.CreateJoints(character : Model) : {Motor6D}
	if not character:IsA('Model') or not character:FindFirstChildOfClass('Humanoid') then
		return
	end
	
	local rigType = character.Humanoid.RigType
	local motors = getMotors(character)
	
	createNoCollisionConstraints(character, rigType.Name)
	
	for _, motor in motors do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = RAGDOLL_NAME, RAGDOLL_NAME
		a0.CFrame = motor.C0
		a1.CFrame = motor.C1
		a0.Parent = motor.Part0
		a1.Parent = motor.Part1

		local name = motor.Name:gsub('Right', '')
		name = name:gsub('Left', '')
		name = name:gsub('Joint', '')
		name = name:gsub(' ', '')
		
		local b = (script[rigType.Name]:FindFirstChild(name) or script[rigType.Name].Default):Clone()
		b.Name = RAGDOLL_NAME

		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Parent = motor.Part1
	end
	
	return motors
end

-- Remove joints for ragdoll
function Ragdoll.DestroyJoints(character : Model)
	for _, descendant : Instance in character:GetDescendants() do
		-- Remove BallSockets and NoCollides, leave the additional Attachments
		if (descendant:IsA('Constraint') or descendant:IsA('WeldConstraint') or descendant:IsA('Attachment')) and descendant.Name == RAGDOLL_NAME
			or descendant:IsA("NoCollisionConstraint") and descendant.Name == NOCOLLIDE_NAME
		then
			descendant:Destroy()
		end
	end
end

-- Setup properties for Ragdoll
function Ragdoll.Ragdoll(character : Model)
	
	local rootPart : BasePart? = character.PrimaryPart
	local humanoid : Humanoid = character.Humanoid
	
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	rootPart.CanCollide = false
	character.Head.CanCollide = true
	
	
	if not character.PrimaryPart:GetNetworkOwner() then
		if humanoid.Health > 0 and humanoid:GetState() ~= stateType.Physics then
			humanoid:ChangeState(stateType.Physics)
		end
	end
end

-- Reset properties for ragdoll
function Ragdoll.UnRagdoll(character : Model)
	local humanoid : Humanoid = character.Humanoid
	
	if humanoid.Health > 0 then
		humanoid.WalkSpeed = 16
		humanoid.AutoRotate = true
		character.PrimaryPart.CanCollide = true
		character.Head.CanCollide = false
		
		if not character.PrimaryPart:GetNetworkOwner() then
			if humanoid:GetState() ~= stateType.GettingUp then
				humanoid:ChangeState(stateType.GettingUp)
			end
		end
	end
end

-- Set motor-set enabled
function Ragdoll.SetMotorsEnabled(motors : {Motor6D}, enabled : boolean)
	for _, motor in motors do
		motor.Enabled = enabled
	end
end

-- Check whether a humanoid is ragdolled or not
function Ragdoll.IsRagdolled(humanoid : Humanoid) : boolean
	if not humanoid then return end
	local success, result = pcall(function()
		return humanoid:GetState() == stateType.Physics
	end)
	
	if not success then
		print("Player died, couldn't check if player is ragdolled for that.")
	end
end

return Ragdoll
