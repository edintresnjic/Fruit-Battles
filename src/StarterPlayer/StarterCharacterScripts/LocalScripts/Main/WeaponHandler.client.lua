--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

--|| Instances ||--
-- Folders
local Weapons = ReplicatedStorage:WaitForChild("Weapons")
local Events = ReplicatedStorage:WaitForChild("Events")
local RagdollModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("Ragdoll"))
local Animations = ReplicatedStorage:WaitForChild("Animations")
-- Players
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
local Animator: Animator = Humanoid:WaitForChild("Animator")
local Mouse: Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- Events
local WeaponInit = Events:WaitForChild("WeaponInit")
local WeaponActivation = Events:WaitForChild("WeaponActivation")
local KnockbackEvent = Events:WaitForChild("Knockback")
local RagdollEvent : RemoteFunction = Events:WaitForChild("RagdollCallback")
local UltimateEvent : RemoteEvent = Events:WaitForChild("Ultimate")

local GetNearestPlayer : RemoteFunction = Events:WaitForChild("GetNearestPlayer")
local CameraHandler : RemoteFunction = Events:WaitForChild("CameraHandler")
local CameraShaker = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Utility"):WaitForChild("CameraShaker"))
local CheckServerValue = Events:WaitForChild("CheckServerValue")
local Dashing = false

-- Weapon
repeat
	task.wait()
until Player:GetAttribute("DataLoaded") and Player:GetAttribute("DataLoaded") == true
local WeaponEquipped: Tool = WeaponInit:InvokeServer()

local Sound = WeaponEquipped:WaitForChild("Sound")

-- Variables
local JumpDebounce = false

-- Modules
local AnimationHandler = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("AnimationHandler"))
local WeaponsObj = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Main"):WaitForChild("Weapons"):WaitForChild("WeaponsObj"))

--|| Main Code ||--
------------------------------------------------------------------------------------
local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCFrame)
	Camera.CFrame = Camera.CFrame * ShakeCFrame
end)

CamShake:Start()

for _, AnimationType in pairs(Animations:GetChildren()) do
	AnimationHandler:InitAnimations(Character, AnimationType.Name)
end

local function IsGrounded(StartPos, Ignore)
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Blacklist
	RayParams.FilterDescendantsInstances = Ignore
	local RayResult = workspace:Raycast(StartPos.WorldPosition, Vector3.new(0, -10, 0), RayParams)
	if RayResult then
		if RayResult.Instance.Parent and RayResult.Instance.Parent.Name == "Island" then
			return true
		else
			return false
		end
	else
		return false
	end
end

WeaponEquipped.Activated:Connect(function() -- Perform action
	if not Character:GetAttribute("Cooldown") then
		if Character:GetAttribute("Ragdolled") then return end
		AnimationHandler:PlayAnimation(Character, "Apple", "Action")
		Sound:WaitForChild("Action"):Play()
		
		-- Main code
		local MousePosition = Mouse.Hit.Position

		WeaponActivation:FireServer("Normal", MousePosition, WeaponEquipped:WaitForChild("Handle"), WeaponEquipped:WaitForChild("Handle"))
		
		-- Reset animation
		task.delay(1, function()
			if WeaponEquipped.Equipped == true then
				AnimationHandler:StopAnimation(Character, "Apple", "Action")
				AnimationHandler:PlayAnimation(Character, "Apple", "Idle")
			end
		end)
	end
end)


local function Attack()
	if Character:GetAttribute("InUltimate") == true then
		if Character:GetAttribute("Ragdolled") == true then return end
		if Character:GetAttribute("UltimateAttackCooldown") == true then return end
		-- Attack()
		if Player.ValuesFolder.Weapons.Value == "Banana" then
			AnimationHandler:PlayAnimation(Character, "Banana", "ActionUlt")
			WeaponActivation:FireServer("CheckHitbox")
		elseif Player.ValuesFolder.Weapons.Value == "Grape" then
			if Humanoid.MoveDirection == Vector3.new(0, 0, 0) then
				for _, Animation in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
					Animation:Stop()
				end
				WeaponActivation:FireServer("CheckHitbox")
			end
		elseif Player.ValuesFolder.Weapons.Value == "Watermelon" then
			WeaponActivation:FireServer("CheckHitbox", Mouse.Hit.Position)
		elseif Player.ValuesFolder.Weapons.Value == "Rokakaka" then
			WeaponActivation:FireServer("CheckHitbox")
		elseif Player.ValuesFolder.Weapons.Value == "GomuGomuNoMi" then
			WeaponActivation:FireServer("CheckHitbox", Mouse.Hit.Position)
		end
	end
end

local function SecondAttack()
	if Character:GetAttribute("InUltimate") == true then
		if Character:GetAttribute("Ragdolled") == true then return end
		if Character:GetAttribute("UltimateAttackCooldown") == true then return end
		-- Attack()
		if Player.ValuesFolder.Weapons.Value == "GomuGomuNoMi" or Player.ValuesFolder.Weapons.Value == "Rokakaka" then
			WeaponActivation:FireServer("SecondAttackHitbox")
		end
	end
end


local function Detonate()
	if Character:GetAttribute("InUltimate") == true then
		if Player.ValuesFolder.Weapons.Value == "Grape" then
			WeaponActivation:FireServer("Detonate")
		end
	end
end

local function MakeButton(Action)
	-- Making buttons pretty
	if not UIS.TouchEnabled and UIS.KeyboardEnabled and UIS.MouseEnabled then return end
	local Button: TextButton = ContextActionService:GetButton(Action)
	Button.Size = UDim2.new(0.4, 0, 0.4, 0)
	
	if Action == "Ultimate" then
		Button.Position = UDim2.new(0.6, 0, 0, 0)
	elseif Action == "Attack" then
		Button.Position = UDim2.new(0.2, 0, 0, 0)
	elseif Action == "Detonate" or Action == "SecondAttack" then
		Button.Position = UDim2.new(-0.2, 0, 0, 0)
	elseif Action == "Slide" then
		Button.Position = UDim2.new(0.2, 0, -0.5, 0)
	end
	
	ContextActionService:SetTitle(Action, Action)
end

Character:GetAttributeChangedSignal("InUltimate"):Connect(function()
	if Character:GetAttribute("InUltimate") == false then
		ContextActionService:UnbindAction("Attack")
		ContextActionService:UnbindAction("Detonate")
		ContextActionService:UnbindAction("SecondAttack")
	end
end)

local function StartUltimate()
	if not Character:GetAttribute("UltimateCooldown") then
		WeaponActivation:FireServer("UltimateBegin")
		if Player.ValuesFolder.Weapons.Value == "Banana" then
			local AttackBTN = ContextActionService:BindAction("Attack", Attack, true, Enum.UserInputType.MouseButton1)
			-- Making buttons pretty
			MakeButton("Attack")
			
		elseif Player.ValuesFolder.Weapons.Value == "Grape" then
			local AttackBTN = ContextActionService:BindAction("Attack", Attack, true, Enum.UserInputType.MouseButton1)
			local DetonateBTN = ContextActionService:BindAction("Detonate", Detonate, true, Enum.UserInputType.MouseButton2)
			-- Making buttons pretty
			MakeButton("Attack")
			MakeButton("Detonate")
		elseif Player.ValuesFolder.Weapons.Value == "Watermelon" then
			local AttackBTN = ContextActionService:BindAction("Attack", Attack, true, Enum.UserInputType.MouseButton1)
			MakeButton("Attack")
		elseif Player.ValuesFolder.Weapons.Value == "Rokakaka" then
			local AttackBTN = ContextActionService:BindAction("Attack", Attack, true, Enum.UserInputType.MouseButton1)
			MakeButton("Attack")
			local AttackBTN = ContextActionService:BindAction("SecondAttack", SecondAttack, true, Enum.KeyCode.R)
			MakeButton("SecondAttack")
		elseif Player.ValuesFolder.Weapons.Value == "GomuGomuNoMi" then
			local AttackBTN = ContextActionService:BindAction("Attack", Attack, true, Enum.UserInputType.MouseButton1)
			MakeButton("Attack")
			local AttackBTN = ContextActionService:BindAction("SecondAttack", SecondAttack, true, Enum.KeyCode.R)
			MakeButton("SecondAttack")
		end
	end
end

local function Slide()
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Blacklist
	Params.FilterDescendantsInstances = {Character}
	local HinderDetection = workspace:Raycast(Character.HumanoidRootPart.Position, (Character.HumanoidRootPart.CFrame.LookVector).Unit * 10, Params)
	if HinderDetection and HinderDetection.Instance.CanCollide == true then return end
	CheckServerValue:FireServer()
end

CheckServerValue.OnClientEvent:Connect(function()
	Dashing = true
	local SlideAnim: AnimationTrack = Character.Humanoid.Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Slide"):WaitForChild("Animation"))
	SlideAnim:Play()
	SlideAnim:GetMarkerReachedSignal("Pause"):Connect(function()
		SlideAnim:AdjustSpeed(0)
	end)
	
	local SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Slide"):WaitForChild("Swoosh"):Clone()
	SFX.Parent = Character
	SFX:Play()
	task.delay(1, function()
		SFX:Destroy()
	end)
	
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Blacklist
	Params.FilterDescendantsInstances = {Character}

	if workspace:GetAttribute("Event") == "Tiny Royale" then
		if IsGrounded(Character.HumanoidRootPart.RootAttachment, {Character}) then
			Character.HumanoidRootPart:ApplyImpulse((Character.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 7.5)
		else
			Character.HumanoidRootPart:ApplyImpulse((Character.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 4)
		end
	else
		if IsGrounded(Character.HumanoidRootPart.RootAttachment, {Character}) then
			Character.HumanoidRootPart:ApplyImpulse((Character.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 3500)
		else
			Character.HumanoidRootPart:ApplyImpulse((Character.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit * 1500)
		end
	end
	-- Camera
	local DefaultFOV = 70

	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FieldOfView = DefaultFOV + 30}):Play()
	CamShake:Shake(CameraShaker.Presets.RoughDriving)
	task.delay(0.2, function()
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FieldOfView = DefaultFOV}):Play()
	end)
	-- Reset
	task.delay(0.6, function()
		SlideAnim:Stop()
		Dashing = false
	end)
end)

ContextActionService:BindAction("Ultimate", StartUltimate, true, Enum.KeyCode.Q)
-- Making buttons pretty
MakeButton("Ultimate")
ContextActionService:BindAction("Slide", Slide, true, Enum.KeyCode.C or Enum.KeyCode.LeftShift)
-- Making buttons pretty
MakeButton("Slide")

UIS.InputEnded:Connect(function(Input, GameProcessedEvent)
	if GameProcessedEvent then return end
	
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		if Player.ValuesFolder.Weapons.Value == "Watermelon" then
			local MousePosition = Player:GetMouse().Hit.Position
			WeaponActivation:FireServer("Detonate", MousePosition)
		end
	end
end)

WeaponEquipped.Equipped:Connect(function() -- Equip weapon, play anim
	SoundService:PlayLocalSound(ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Equip"))
	AnimationHandler:PlayAnimation(Character, "Apple", "Idle")
end)

WeaponEquipped.Unequipped:Connect(function() -- Cancel scope, Unequip Weapon, stop anims
	-- CancelScope()
	SoundService:PlayLocalSound(ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Equip"))
	local PlayingAnimations = Animator:GetPlayingAnimationTracks()
	
	for _, Anims in pairs(PlayingAnimations) do
		if Anims.Name == "Idle" or Anims.Name == "Action" then
			AnimationHandler:StopAnimation(Character, "Apple", "Idle")
			AnimationHandler:StopAnimation(Character, "Apple", "Action")
		end
	end
end)

KnockbackEvent.OnClientEvent:Connect(function(Direction) -- Ragdoll & Knockback
	local CanRagdoll, Duration = RagdollEvent:InvokeServer()
	if workspace:GetAttribute("Event") == "Knockback Mayhem" then
		Character.HumanoidRootPart:ApplyImpulse(Direction * 4)
	else
		Character.HumanoidRootPart:ApplyImpulse(Direction * 1.5)
	end

	if CanRagdoll then
		-- GUI HANDLING
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		Humanoid:UnequipTools()
			
		task.delay(Duration, function()
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end)

local function AddJumpForce()
	if Character:FindFirstChild("Ultimate") then
		if Character:FindFirstChild("Ultimate"):GetAttribute("Ultimate") ~= "Apple" then return end
		local Ult = Character:FindFirstChild("Ultimate")
		if Ult:FindFirstChild("JumpForce") then return end
		if not IsGrounded(Ult:FindFirstChild("ForceAttach"), {Ult}) then return end
		
		if JumpDebounce then return end
		JumpDebounce = true
		local JumpForce: LinearVelocity = Instance.new("LinearVelocity")
		local MoveForce: LinearVelocity = Ult:FindFirstChild("LinearVelocity")
		
		JumpForce.Name = "JumpForce"
		JumpForce.Attachment0 = Ult:WaitForChild("ForceAttach")
		JumpForce.MaxForce = math.huge
		JumpForce.VectorVelocity = MoveForce.VectorVelocity + Vector3.new(0, 40, 0)
		JumpForce.Parent = Ult
		
		local SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Apple"):WaitForChild("Jump"):Clone()
		SFX.Parent = Character
		SFX:Play()
		CamShake:Shake(CameraShaker.Presets.Explosion)
		task.delay(0.5, function()
			SFX:Destroy()
		end)
		local DefaultFOV = 70
		
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FieldOfView = DefaultFOV + 20}):Play()
		
		game:GetService("Debris"):AddItem(JumpForce, .3)
		task.delay(0.6, function()
			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {FieldOfView = DefaultFOV}):Play()
		end)
		task.delay(4, function()
			JumpDebounce = false
		end)
	end
end

UltimateEvent.OnClientEvent:Connect(function(Type, PlayerCharacter, Ultimate, MovementForce)
	if Type == "Movement" then
		repeat
			-- Update Movement
			MovementForce.VectorVelocity = PlayerCharacter.Humanoid.MoveDirection * 100
			RunService.Heartbeat:Wait()
			
			UIS.JumpRequest:Connect(function()
				AddJumpForce()
			end)
		until Ultimate == nil
	elseif Type == "UpdateCamera" then
		Camera.CameraSubject = Ultimate
	end
end)

GetNearestPlayer.OnClientInvoke = function(Pumpkin, maxDistance)
	local nearestPlayer
	local nearestDistance
	for _, player in pairs(game.Players:GetPlayers()) do
		if player == Player then continue end
		local character = player.Character
		local distance = player:DistanceFromCharacter(Pumpkin.Position)
		if not character or 
			distance > maxDistance or
			(nearestDistance and distance >= nearestDistance)
		then
			continue
		else
			nearestDistance = distance
			nearestPlayer = player
		end
		return nearestPlayer
	end
end