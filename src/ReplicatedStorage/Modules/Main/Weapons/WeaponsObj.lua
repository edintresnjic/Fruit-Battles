--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")

--|| Instances ||--
-- OOP
Weapons = {}
Weapons.__index = Weapons

-- Folders
local WeaponsFolder = ReplicatedStorage:WaitForChild("Weapons")
local UltimatesFolder = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("Ultimates")
local Events = ReplicatedStorage:WaitForChild("Events")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utility = Modules:WaitForChild("Utility")
local AttackInstances = workspace:WaitForChild("AttackInstances")
local bulletsFolder = workspace:FindFirstChild("BulletsFolder") or Instance.new("Folder", workspace)
bulletsFolder.Name = "BulletsFolder"

-- Events
local KnockBackEvent = Events:WaitForChild("Knockback")
local UltimateEvent = Events:WaitForChild("Ultimate")
local SpawnVFXEvent = Events:WaitForChild("SpawnVFX")
local GetNearestPlayer: RemoteFunction = Events:WaitForChild("GetNearestPlayer")
local CameraHandler : RemoteEvent = Events:WaitForChild("CameraHandler")
local UpdateStandPos = Events:WaitForChild("UpdateStandPos")

--| Modules
local GuiHandler = require(script.Parent.Parent.GUIHandler)
local CameraShaker = require(script.Parent.Parent.Parent.Utility.CameraShaker)
local AnimationHandler = require(script.Parent.Parent.Parent.Shared.AnimationHandler)
local CustomFloatRocks = require(script.Parent.Parent.Parent.Utility.CustomFloatRocks)
local RaycastHitbox = require(script.Parent.Parent.Parent.Utility.RaycastHitboxV4)
-- Fastcast
local FastCastRedux = require(Utility:WaitForChild("FastCastRedux"))
FastCastRedux.VisualizeCasts = false

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Blacklist

local CastBehavior = FastCastRedux.newBehavior()
CastBehavior.Acceleration = Vector3.new(0, -100, 0)
CastBehavior.AutoIgnoreContainer = false
CastBehavior.CosmeticBulletContainer = bulletsFolder

--|| Main Code ||--
------------------------------------------------------------------------------------
function Weapons.new(Name, Cost, Damage, Type, Speed, CooldownTime, Level)
	-- Creating a weapon using OOP
	local Weapon = {}
	setmetatable(Weapon, Weapons)
	
	Weapon.Name = Name
	Weapon.Cost = Cost
	Weapon.Damage = Damage
	Weapon.Type = Type
	Weapon.Speed = Speed
	Weapon.CooldownTime = CooldownTime
	Weapon.Level = Level
	Weapon.Caster = FastCastRedux.new()
	
	return Weapon
end

function Weapons:GetModel()
	-- Instances
	for _, Weapon in pairs(WeaponsFolder[self.Type]:GetDescendants()) do
		if Weapon.Name == self.Name then
			return Weapon
		end
	end
end

local function KnockBack(HitPlayer, Direction)
	-- Knockback & Ragdoll on Client
	HitPlayer.PrimaryPart:SetNetworkOwner(nil)
	task.delay(2.5, function()
		HitPlayer.PrimaryPart:SetNetworkOwner(game.Players:GetPlayerFromCharacter(HitPlayer))
	end)
	local Player = game:GetService("Players"):GetPlayerFromCharacter(HitPlayer)
	KnockBackEvent:FireClient(Player, Direction)
end

function Weapons:Ultimate(Player, Status, MousePosition, Type)
	if Status == "Begin" then
		-- Instances
		local PlayerCharacter = workspace:FindFirstChild(Player.Name)
		if PlayerCharacter:GetAttribute("UltimateCooldown") then return end
		if PlayerCharacter:GetAttribute("Ragdolled") then return end
		if PlayerCharacter:GetAttribute("Loading") == true then return end
		if PlayerCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
		if PlayerCharacter:GetAttribute("SlideDebounce", true) then return end
		PlayerCharacter:SetAttribute("InUltimate", true)
		PlayerCharacter:SetAttribute("UltimateCooldown", true)
		GuiHandler:UltimateCooldown(Player)
		-- Setting
		PlayerCharacter.Humanoid.JumpHeight = 0
		-- Get Ultimate
		if self.Name == "Apple" then
			-- Setting
			PlayerCharacter:SetAttribute("SlideDebounce", true)
			PlayerCharacter.Humanoid.JumpHeight = 0
			-- Instances
			local Ultimate = UltimatesFolder:FindFirstChild("Apple"):Clone()
			local Seat = Ultimate:WaitForChild("VehicleSeat")
			
			-- Delays
			task.delay(30, function()
				Ultimate:Destroy()
				PlayerCharacter.Humanoid.JumpHeight = 7.2
				PlayerCharacter:SetAttribute("InUltimate", false)
				PlayerCharacter:SetAttribute("SlideDebounce", false)

				-- Reset
				task.delay(90, function()
					PlayerCharacter:SetAttribute("UltimateCooldown", false)
				end)
			end)
			
			-- Main
			Ultimate.CFrame = PlayerCharacter.HumanoidRootPart.CFrame
			Ultimate.Name = "Ultimate"
			Ultimate.Parent = PlayerCharacter
			Ultimate:SetAttribute("Ultimate", "Apple")
			Seat:Sit(PlayerCharacter.Humanoid)
			local MovementForce: LinearVelocity = Instance.new("LinearVelocity")
			MovementForce.Attachment0 = Ultimate.ForceAttach
			MovementForce.MaxForce = 60000
			MovementForce.Parent = Ultimate
			UltimateEvent:FireClient(Player, "UpdateCamera", nil, Ultimate)
			UltimateEvent:FireAllClients("Movement", PlayerCharacter, Ultimate, MovementForce)
			
			-- CheckHit
			local CharactersOnDebounce = {}
			Ultimate.Touched:Connect(function(PartHit)
				local PartHitParent = PartHit.Parent
				if PartHitParent:GetAttribute("Loading") == true then return end
				if PartHitParent and PartHitParent:FindFirstChild("Humanoid") then
					if PartHitParent:FindFirstChild("Ultimate") then
						if PartHitParent:FindFirstChild("Ultimate"):GetAttribute("Ultimate") ~= "Apple" then
							if table.find(CharactersOnDebounce, PartHitParent.Name) then return end -- Checking debounce
							-- Damage & Knockback & Ragdoll
							PartHitParent:FindFirstChild("Humanoid"):TakeDamage(20)
							KnockBack(PartHitParent, PlayerCharacter.Humanoid.MoveDirection * 750)

							-- Setting Attributes for KillFeed & Resetting afte a while
							local Distance = (PlayerCharacter.HumanoidRootPart.Position - PartHitParent.HumanoidRootPart.Position).Magnitude

							PartHitParent:SetAttribute("Distance", Distance)
							PartHitParent:SetAttribute("Killer", Player.Name)

							-- Resetting killfeed
							task.delay(10, function() -- Reset
								PartHitParent:SetAttribute("Distance", "")
								PartHitParent:SetAttribute("Killer", "")
							end)
							-- Resseting debounce
							table.insert(CharactersOnDebounce, PartHitParent.Name)
							task.delay(0.5, function()
								local Index = table.find(CharactersOnDebounce, PartHitParent.Name)
								table.remove(CharactersOnDebounce, Index)
							end)	
						end
					else
						if table.find(CharactersOnDebounce, PartHitParent.Name) then return end -- Checking debounce
						-- Damage & Knockback & Ragdoll
						PartHitParent:FindFirstChild("Humanoid"):TakeDamage(20)
						KnockBack(PartHitParent, PlayerCharacter.Humanoid.MoveDirection * 750)

						-- Setting Attributes for KillFeed & Resetting afte a while
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - PartHitParent.HumanoidRootPart.Position).Magnitude

						PartHitParent:SetAttribute("Distance", Distance)
						PartHitParent:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							PartHitParent:SetAttribute("Distance", "")
							PartHitParent:SetAttribute("Killer", "")
						end)
						-- Resseting debounce
						table.insert(CharactersOnDebounce, PartHitParent.Name)
						task.delay(0.5, function()
							local Index = table.find(CharactersOnDebounce, PartHitParent.Name)
							table.remove(CharactersOnDebounce, Index)
						end)
					end
				end
			end)
		elseif self.Name == "Banana" then
			-- Setting
			PlayerCharacter.Humanoid.JumpHeight = 7.2
			-- Instances
			local Banana = UltimatesFolder:FindFirstChild("Banana"):Clone()
			Banana.Name = "Ultimate"
			Banana:SetAttribute("Ultimate", "Banana")
			local AnimateScript = PlayerCharacter:WaitForChild("Animate")
			local PreviousIdle1 = AnimateScript.idle.Animation1.AnimationId
			local PreviousIdle2 = AnimateScript.idle.Animation2.AnimationId
			local PreviousRun = AnimateScript.run.RunAnim.AnimationId
			PlayerCharacter.Humanoid.WalkSpeed = 35
			
			PlayerCharacter:SetAttribute("CanShoot", false)
			
			task.spawn(function()
				repeat
					PlayerCharacter.Humanoid.WalkSpeed = 35
					task.wait()
				until PlayerCharacter:GetAttribute("InUltimate") == false or PlayerCharacter:FindFirstChild("Ultimate") == nil
				
				PlayerCharacter:SetAttribute("InUltimate", false)
				AnimateScript.idle.Animation1.AnimationId = PreviousIdle1
				AnimateScript.idle.Animation2.AnimationId = PreviousIdle2
				AnimateScript.run.RunAnim.AnimationId = PreviousRun
				PlayerCharacter:SetAttribute("CanShoot", true)

				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end
				
				PlayerCharacter.Humanoid.WalkSpeed = 16
				coroutine.yield()
			end)
			-- Delays
			task.delay(30, function()
				Banana:Destroy()
				PlayerCharacter:SetAttribute("InUltimate", false)
				AnimateScript.idle.Animation1.AnimationId = PreviousIdle1
				AnimateScript.idle.Animation2.AnimationId = PreviousIdle2
				AnimateScript.run.RunAnim.AnimationId = PreviousRun
				PlayerCharacter:SetAttribute("CanShoot", true)
				
				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end
				-- Reset
				task.delay(60, function()
					PlayerCharacter:SetAttribute("UltimateCooldown", false)
				end)
			end)
			
			-- Main Code
			local Animations = Banana:WaitForChild("Animations"):GetChildren()
			local IdleAnimation = Animations[1]
			local ActionAnimation = Animations[2]
			local RunAnimation = Animations[3]
			
			local IdleAnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(IdleAnimation)
			local RunAnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(RunAnimation)
			
			if PlayerCharacter.Humanoid.MoveDirection == Vector3.new(0, 0, 0) then
				RunAnimationTrack:Stop()
				IdleAnimationTrack:Play()
			else
				IdleAnimationTrack:Stop()
				RunAnimationTrack:Play()
			end
			
			local IdleAnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(IdleAnimation)
			local ActionAnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(ActionAnimation)
			
			PlayerCharacter.Humanoid:UnequipTools()
			
			local RightHand = PlayerCharacter.RightHand
			local Motor6D = RightHand:FindFirstChild("Banana6D") or Instance.new("Motor6D", RightHand)
			Banana.Parent = PlayerCharacter
			Motor6D.Part0 = RightHand
			Motor6D.Name = "Banana6D"
			Motor6D.Part1 = Banana
			
			AnimateScript.idle.Animation1.AnimationId = IdleAnimation.AnimationId
			AnimateScript.idle.Animation2.AnimationId = IdleAnimation.AnimationId
			AnimateScript.run.RunAnim.AnimationId = RunAnimation.AnimationId
			
			task.spawn(function()
				repeat
					task.wait()
				until PlayerCharacter.Humanoid.MoveDirection ~= Vector3.new(0, 0, 0)
				IdleAnimationTrack:Stop()
				RunAnimationTrack:Stop()
				coroutine.yield()
			end)
		elseif self.Name == "Watermelon" then
			-- Main
			PlayerCharacter:SetAttribute("InUltimate", true)
			PlayerCharacter:SetAttribute("CanShoot", false)
			PlayerCharacter.Humanoid:UnequipTools()
			local Comet = UltimatesFolder:WaitForChild("Watermelon"):Clone()
			
			-- Reset
			task.delay(90, function()
				PlayerCharacter:SetAttribute("UltimateCooldown", false)
			end)
			
			local Anim = PlayerCharacter.Humanoid.Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Watermelon"):WaitForChild("Action"))
			Anim:Play()
			UltimatesFolder:WaitForChild("Watermelon"):WaitForChild("SFX"):WaitForChild("Angry"):Play()
			-- Rocks
			local RockCache = CustomFloatRocks.Create({
				CenterCFrame = CFrame.new(PlayerCharacter.HumanoidRootPart.Position),
				InnerRadius = 20,
				OuterRadius = 40,
				Size = {Min = 2, Max = 3}
			})
			
			RockCache.Rise({
				Velocity = {Min = 3, Max = 5},
				FloatTime = 8
			})
			
			-- Spawn Comet
			local GoalDestination = PlayerCharacter.HumanoidRootPart.Position
			local SpawnPosition = PlayerCharacter.HumanoidRootPart.Position + Vector3.new(0, 300, 0)

			Comet.Position = SpawnPosition
			Comet.Parent = workspace
			Comet.Anchored = true
			game:GetService("TweenService"):Create(Comet, TweenInfo.new(1), {Transparency = 0}):Play()
			
			task.wait(0.125)

			RockCache.Rise({
				Velocity = {Min = 3, Max = 5},
				FloatTime = 8
			})
			
			task.wait(0.125)
			RockCache.Rise({
				Velocity = {Min = 3, Max = 5},
				FloatTime = 8
			})
			
			task.wait(0.125)
			RockCache.Rise({
				Velocity = {Min = 3, Max = 5},
				FloatTime = 8
			})
			
			task.wait(0.70)
			RockCache.Repulse({
				VelocityLifetime = .3
			})
			
			-- Main
			PlayerCharacter:SetAttribute("InUltimate", false)
			PlayerCharacter:SetAttribute("CanShoot", true)
			
			task.delay(2, function()
				RockCache.Cleanup()
			end)
			
			-- Moving comet to position
			local Tween: Tween = game:GetService("TweenService"):Create(Comet, TweenInfo.new(0.5), {Position = GoalDestination})
			Tween:Play()
			CameraHandler:FireAllClients()
			
			task.wait(0.3)
			
			-- Check if comet reached position
			Comet:Destroy()
			-- Play SFX & VFX
			-- SpawnVFXEvent:FireAllClients(ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("Watermelon"):WaitForChild("VFX"), GoalDestination, false)
			local SFX = UltimatesFolder:WaitForChild("Watermelon"):WaitForChild("SFX"):WaitForChild("Broken Ground"):Play()
			CameraHandler:FireAllClients()
			local VFX: Model = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("Watermelon"):WaitForChild("VFX"):Clone()
			VFX:ScaleTo(0.1)
			VFX.Parent = workspace
			VFX:PivotTo(CFrame.new(GoalDestination) * CFrame.new(0, 3, 0))
			SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Lemon"):WaitForChild("Spin"):Clone()
			SFX.Parent = VFX
			SFX.Looped = true
			SFX:Play()
			game:GetService("TweenService"):Create(VFX, TweenInfo.new(1), {Size = VFX:ScaleTo(1)}):Play()
			task.delay(1.5, function()
				VFX:Destroy()
			end)
			-- Hitbox
			local Hitbox = workspace:GetPartBoundsInRadius(Comet.Position, 40)
			local CharactersOnDebounce = {}
			
			if Hitbox then
				for _, Hit in pairs(Hitbox) do
					if Hit.Parent and Hit.Parent:FindFirstChild("Humanoid") then
						-- Setting Attributes for KillFeed & Resetting afte a while
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Hit.Parent.HumanoidRootPart.Position).Magnitude
						
						if Hit.Parent ~= PlayerCharacter then
							Hit.Parent:SetAttribute("Distance", Distance)
							Hit.Parent:SetAttribute("Killer", Player.Name)

							-- Resetting killfeed
							task.delay(10, function() -- Reset
								Hit.Parent:SetAttribute("Distance", "")
								Hit.Parent:SetAttribute("Killer", "")
							end)
						end
						
						-- Killing
						Hit.Parent.Humanoid.Health = 0
					end
				end
			end
		elseif self.Name == "Lemon" then
			-- Setting
			PlayerCharacter.Humanoid.JumpHeight = 15
			-- Instances
			local Decoy = Instance.new("BoolValue")
			Decoy.Name = "Ultimate"
			Decoy:SetAttribute("Ultimate", "Lemon")
			Decoy.Parent = PlayerCharacter
			
			PlayerCharacter.Humanoid:UnequipTools()
			
			task.spawn(function()
				repeat
					PlayerCharacter.Humanoid.WalkSpeed = 25
					PlayerCharacter.Humanoid.JumpHeight = 15
					task.wait()
				until PlayerCharacter:GetAttribute("InUltimate") == false or PlayerCharacter:FindFirstChild("Ultimate") == nil

				PlayerCharacter:SetAttribute("InUltimate", false)
				PlayerCharacter:SetAttribute("CanShoot", true)

				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end

				PlayerCharacter.Humanoid.WalkSpeed = 16
				PlayerCharacter.Humanoid.JumpHeight = 7.2
				Decoy:Destroy()
				coroutine.yield()
			end)

			-- Delays
			task.delay(30, function()
				Decoy:Destroy()
				PlayerCharacter:SetAttribute("InUltimate", false)
				PlayerCharacter:SetAttribute("CanShoot", true)
				-- Setting
				PlayerCharacter.Humanoid.JumpHeight = 7.2

				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end
				-- Reset
				task.delay(60, function()
					PlayerCharacter:SetAttribute("UltimateCooldown", false)
				end)
			end)
			
			local ActionAnimation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Lemon"):WaitForChild("Action")
			local Lemon = UltimatesFolder:WaitForChild("Lemon"):WaitForChild("Lemon"):Clone()
			Lemon.Parent = PlayerCharacter
			local ActionAnimationTrack: AnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(ActionAnimation)

			PlayerCharacter.Humanoid:UnequipTools()
			local RightHand = PlayerCharacter.RightHand

			local Motor6D = RightHand:FindFirstChild("Lemon6D") or Instance.new("Motor6D", RightHand)
			Motor6D.Name = "Lemon6DR"
			Motor6D.Part0 = RightHand
			Motor6D.Part1 = Lemon
			ActionAnimationTrack:Play()
			
			local EatSFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Lemon"):WaitForChild("Eat"):Clone()
			ActionAnimationTrack:GetMarkerReachedSignal("Eat"):Connect(function()
				EatSFX.Parent = PlayerCharacter
				EatSFX:Play()
			end)
			
			ActionAnimationTrack:GetMarkerReachedSignal("Action"):Connect(function()
				local CharactersOnDebounce = {}
				local ActionSFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Lemon"):WaitForChild("Action"):Clone()
				EatSFX:Destroy()
				ActionSFX.Parent = PlayerCharacter
				ActionSFX.Looped = true
				ActionSFX:Play()
				
				ActionAnimationTrack:AdjustSpeed(0)
				local VFX = PlayerCharacter.Head:FindFirstChild("VFX") or ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("Lemon"):WaitForChild("VFX"):WaitForChild("Attachment"):Clone()
				VFX.Parent = PlayerCharacter.Head
				VFX.Name = "VFX"
				task.spawn(function()
					repeat
						-- Play VFX
						-- Hitbox
						local Params = OverlapParams.new()
						Params.FilterType = Enum.RaycastFilterType.Blacklist
						Params.FilterDescendantsInstances = {PlayerCharacter}
						-- Visualizing hitbox
						--[[
						local HitboxPart = Instance.new("Part")
						HitboxPart.Anchored = true
						HitboxPart.CanCollide = false
						HitboxPart.Transparency = 0.5
						HitboxPart.CFrame = PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -6)
						HitboxPart.Size = Vector3.new(10, 6, 12)
						HitboxPart.Parent = workspace
						Debris:AddItem(HitboxPart, 2) ]]--

						local Hitbox = workspace:GetPartBoundsInBox(PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8), Vector3.new(13, 6, 21), Params)
						for Index, Hit in pairs(Hitbox) do
							local HitParent = Hit.Parent
							if HitParent:GetAttribute("Loading") == true then return end
							if HitParent and HitParent:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, HitParent.Name) and not HitParent:FindFirstChild("Ultimate") then
								-- Main
								local HitAnim: AnimationTrack = HitParent:FindFirstChild("Humanoid").Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Lemon"):WaitForChild("Hit"))
								HitAnim:Play()
								local Sound: Sound = HitParent:FindFirstChild("HitSound") or ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Lemon"):WaitForChild("Hit"):Clone()
								Sound.Parent = HitParent
								Sound.Name = "HitSound"
								Sound:Play()
								
								HitParent:FindFirstChild("Humanoid").Health -= 2
								HitParent.Humanoid.WalkSpeed = 8
								task.delay(1, function()
									HitParent.Humanoid.WalkSpeed = 16
								end)

								-- Setting atributes
								local Distance = (PlayerCharacter.HumanoidRootPart.Position - HitParent.HumanoidRootPart.Position).Magnitude
								HitParent:SetAttribute("Distance", Distance)
								HitParent:SetAttribute("Killer", Player.Name)

								-- Resetting killfeed
								task.delay(10, function() -- Reset
									HitParent:SetAttribute("Distance", "")
									HitParent:SetAttribute("Killer", "")
								end)

								table.insert(CharactersOnDebounce, HitParent.Name)
								task.delay(0.2, function()
									table.remove(CharactersOnDebounce, table.find(CharactersOnDebounce, HitParent.Name))
								end)
							else
								if HitParent:FindFirstChild("Ultimate") then	
									if HitParent:FindFirstChild("Ultimate"):GetAttribute("Ultimate") == "Apple" then
										if HitParent:GetAttribute("UltimateHealth") > 0 then
											HitParent:SetAttribute("UltimateHealth", HitParent:GetAttribute("UltimateHealth") - self.Damage)
											-- Update ULT Health
											game:GetService("TweenService"):Create(HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(HitParent:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
											HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = HitParent:GetAttribute("UltimateHealth").. "HP"	
										end
										table.insert(CharactersOnDebounce, HitParent.Name)
										coroutine.wrap(function()
											if HitParent:GetAttribute("UltimateHealth") <= 0 then
												-- Delays
												HitParent:WaitForChild("Ultimate"):Destroy()

												-- Reset
												local Player = game:GetService("Players"):GetPlayerFromCharacter(HitParent)
												local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
												local Cooldown = string.match(CooldownText.Text, "%(.*%)")
												Cooldown = string.split(Cooldown, "(")
												Cooldown[2] = string.split(Cooldown[2], ")")
												Cooldown = Cooldown[2][1]
												task.delay(Cooldown, function()
													PlayerCharacter:SetAttribute("UltimateCooldown", false)
													HitParent:SetAttribute("UltimateHealth", 250)
												end)
											end
										end)()
									end
								end
							end
						end
						task.wait()
					until PlayerCharacter:GetAttribute("InUltimate") == false or PlayerCharacter.Humanoid:GetState() == Enum.HumanoidStateType.Dead
					ActionSFX:Destroy()
					Lemon:Destroy()
					VFX:Destroy()
				end)
			end)
			
		elseif self.Name == "Pumpkin" then
			local Pumpkin = UltimatesFolder:WaitForChild("Pumpkin"):Clone()
			Pumpkin:SetAttribute("Ultimate", "Apple")
			PlayerCharacter:SetAttribute("InUltimate", true)
			PlayerCharacter:SetAttribute("CanShoot", true)
			local Destination = PlayerCharacter.HumanoidRootPart.Position + Vector3.new(0, 150, 0)
			PlayerCharacter.Humanoid.JumpHeight = 7.2
			
			-- game.Lighting.TimeOfDay = "00:00:00"
			
			-- Delays
			task.delay(30, function()
				Pumpkin:Destroy()
				PlayerCharacter:SetAttribute("InUltimate", false)
				-- Reset
				task.delay(60, function()
					PlayerCharacter:SetAttribute("UltimateCooldown", false)
				end)
			end)
			
			Pumpkin.Position = Destination
			Pumpkin.Name = "Ultimate"
			Pumpkin.Parent = PlayerCharacter
			PlayerCharacter:SetAttribute("UltimateHealth", 250)
			local maxDistance = 185
			
			task.spawn(function()
				while PlayerCharacter:GetAttribute("InUltimate") ~= false or Pumpkin ~= nil do
					task.wait()

					local nearestPlayer = GetNearestPlayer:InvokeClient(Player, Pumpkin, maxDistance)
					print(nearestPlayer)
					if not nearestPlayer then continue end
					nearestPlayer.Character.Humanoid:TakeDamage(0.4)
					Pumpkin.CFrame = CFrame.new(Pumpkin.Position, nearestPlayer.Character.Head.Position)
					Pumpkin:FindFirstChild("EndL").WorldPosition = nearestPlayer.Character.Head.Position
					Pumpkin:FindFirstChild("EndR").WorldPosition = nearestPlayer.Character.Head.Position
					-- Setting Attributes for KillFeed & Resetting afte a while
					local Hit = nearestPlayer.Character
					local Distance = (PlayerCharacter.HumanoidRootPart.Position - Hit.HumanoidRootPart.Position).Magnitude

					Hit:SetAttribute("Distance", Distance)
					Hit:SetAttribute("Killer", Player.Name)

					-- Resetting killfeed
					task.delay(10, function() -- Reset
						Hit:SetAttribute("Distance", "")
						Hit:SetAttribute("Killer", "")
					end)
				end
			end)
		elseif self.Name == "Rokakaka" then
			-- Main
			PlayerCharacter:SetAttribute("InUltimate", true)
			PlayerCharacter:SetAttribute("CanShoot", false)
			PlayerCharacter.Humanoid:UnequipTools()
			-- Setting
			PlayerCharacter.Humanoid.JumpHeight = 7.2
			-- Instances
			local Stand = UltimatesFolder:FindFirstChild("Rokakaka"):Clone()
			Stand.Name = "Ultimate"
			Stand:SetAttribute("Ultimate", "Rokakaka")
			local AnimateScript = PlayerCharacter:WaitForChild("Animate")
			local PreviousIdle1 = AnimateScript.idle.Animation1.AnimationId
			local PreviousIdle2 = AnimateScript.idle.Animation2.AnimationId

			local SummonSFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Rokakaka"):WaitForChild("Summon"):Clone()
			SummonSFX.Parent = PlayerCharacter
			SummonSFX:Play()
			Debris:AddItem(SummonSFX, 3)

			PlayerCharacter:SetAttribute("CanShoot", false)
			Stand.HumanoidRootPart.CFrame = PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 3.5, 3)
			Stand.Parent = PlayerCharacter
			UpdateStandPos:FireAllClients(Stand, PlayerCharacter)
			-- Delays
			task.delay(30, function()
				Stand:Destroy()
				PlayerCharacter:SetAttribute("InUltimate", false)
				AnimateScript.idle.Animation1.AnimationId = PreviousIdle1
				AnimateScript.idle.Animation2.AnimationId = PreviousIdle2
				PlayerCharacter:SetAttribute("CanShoot", true)

				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end
				-- Reset
				task.delay(60, function()
					PlayerCharacter:SetAttribute("UltimateCooldown", false)
				end)
			end)

			-- Main Code
			local IdleAnimation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Rokakaka"):WaitForChild("Idle")
			local StandIdle = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Rokakaka"):WaitForChild("Stand Idle")

			PlayerCharacter.Humanoid:UnequipTools()

			AnimateScript.idle.Animation1.AnimationId = IdleAnimation.AnimationId
			AnimateScript.idle.Animation2.AnimationId = IdleAnimation.AnimationId
			
			Stand.Humanoid.Animator:LoadAnimation(StandIdle):Play()
		elseif self.Name == "GomuGomuNoMi" then
			-- Main
			PlayerCharacter:SetAttribute("InUltimate", true)
			PlayerCharacter:SetAttribute("CanShoot", false)
			PlayerCharacter.Humanoid:UnequipTools()

			local SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("GomuGomuNoMi"):WaitForChild("SecondGear"):Clone()
			SFX.Parent = PlayerCharacter
			SFX:Play()
			
			local AnimateScript = PlayerCharacter:WaitForChild("Animate")
			local PreviousIdle1 = AnimateScript.idle.Animation1.AnimationId
			local PreviousIdle2 = AnimateScript.idle.Animation2.AnimationId
			
			-- Setting
			PlayerCharacter.Humanoid.JumpHeight = 0
			PlayerCharacter.Humanoid.WalkSpeed = 0
			local AnimationTrack: AnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("GomuGomuNoMi"):WaitForChild("Intro"))
			AnimationTrack:Play()
			task.wait(0.4)
			AnimationTrack:AdjustSpeed(0)
			task.wait(0.5)
			AnimationTrack:AdjustSpeed(1)

			task.wait(AnimationTrack.Length)
			PlayerCharacter.Humanoid.JumpHeight = 16
			PlayerCharacter.Humanoid.WalkSpeed = 7.2
			

			-- Main Code
			PlayerCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
			local IdleAnimation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("GomuGomuNoMi"):WaitForChild("Idle")
			AnimateScript.idle.Animation1.AnimationId = IdleAnimation.AnimationId
			AnimateScript.idle.Animation2.AnimationId = IdleAnimation.AnimationId
			
		elseif self.Name == "Grape" then
			-- Setting
			PlayerCharacter.Humanoid.JumpHeight = 7.2
			PlayerCharacter:SetAttribute("InUltimate", true)
			PlayerCharacter:SetAttribute("CanShoot", false)
			PlayerCharacter.Humanoid.WalkSpeed = 27
			-- Instances
			local GrapeUltimate = UltimatesFolder:WaitForChild("Grape"):Clone()
			GrapeUltimate.Name = "Ultimate"
			GrapeUltimate:SetAttribute("Ultimate", "Grape")
			GrapeUltimate.Parent = PlayerCharacter
			
			local GrapeL = GrapeUltimate:FindFirstChild("GrapeL")
			local GrapeR = GrapeUltimate:FindFirstChild("GrapeR")
			
			local AnimateScript = PlayerCharacter:WaitForChild("Animate")
			local PreviousRun = AnimateScript.run.RunAnim.AnimationId
			
			task.spawn(function()
				repeat
					PlayerCharacter.Humanoid.WalkSpeed = 27
					task.wait()
				until PlayerCharacter:GetAttribute("InUltimate") == false or PlayerCharacter:FindFirstChild("Ultimate") == nil
				

				PlayerCharacter:SetAttribute("InUltimate", false)
				AnimateScript.run.RunAnim.AnimationId = PreviousRun
				PlayerCharacter:SetAttribute("CanShoot", true)

				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end

				PlayerCharacter.Humanoid.WalkSpeed = 16
				coroutine.yield()
			end)
			
			task.delay(30, function()
				GrapeUltimate:Destroy()
				PlayerCharacter:FindFirstChild("GrapeL"):Destroy()
				PlayerCharacter:FindFirstChild("GrapeR"):Destroy()
				PlayerCharacter:SetAttribute("InUltimate", false)
				AnimateScript.run.RunAnim.AnimationId = PreviousRun
				PlayerCharacter:SetAttribute("CanShoot", true)

				for _, Track in pairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					Track:Stop()
				end
				-- Reset
				task.delay(60, function()
					PlayerCharacter:SetAttribute("UltimateCooldown", false)
				end)
			end)
			
			-- Main Code
			local Animations = GrapeUltimate:WaitForChild("Animations"):GetChildren()
			local ActionAnimation = Animations[3]
			local RunAnimation = Animations[2]

			local RunAnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(RunAnimation)
			

			PlayerCharacter.Humanoid:UnequipTools()

			if PlayerCharacter.Humanoid.MoveDirection ~= Vector3.new(0, 0, 0) then
				RunAnimationTrack:Play()
			end
			
			local LeftHand = PlayerCharacter.LeftHand
			local RightHand = PlayerCharacter.RightHand
			
			local Motor6DL = RightHand:FindFirstChild("Grape6DL") or Instance.new("Motor6D", RightHand)
			GrapeL.Parent = PlayerCharacter
			Motor6DL.Part0 = LeftHand
			Motor6DL.Name = "Grape6DL"
			Motor6DL.Part1 = GrapeL
			
			local Motor6DR = RightHand:FindFirstChild("Grape6DR") or Instance.new("Motor6D", RightHand)
			GrapeR.Parent = PlayerCharacter
			Motor6DR.Part0 = RightHand
			Motor6DR.Name = "Grape6DR"
			Motor6DR.Part1 = GrapeR
			
			AnimateScript.run.RunAnim.AnimationId = RunAnimation.AnimationId
			task.spawn(function()
				repeat
					task.wait()
				until PlayerCharacter.Humanoid.MoveDirection == Vector3.new(0, 0, 0)
				RunAnimationTrack:Stop()
			end)
		end
	elseif Status == "Detonate" then
		if self.Name == "Grape" then
			local PlayerCharacter = workspace:FindFirstChild(Player.Name)
			if bulletsFolder:FindFirstChild("GrapeR_".. PlayerCharacter.Name) then
				if bulletsFolder:FindFirstChild("GrapeL_".. PlayerCharacter.Name) then
					local GrapeLClone = bulletsFolder:FindFirstChild("GrapeL_".. PlayerCharacter.Name)
					local GrapeRClone = bulletsFolder:FindFirstChild("GrapeR_".. PlayerCharacter.Name)
					if GrapeLClone:FindFirstChildOfClass("Explosion") or GrapeRClone:FindFirstChildOfClass("Explosion") then return end
					local ExplosionL = Instance.new("Explosion", GrapeLClone)
					local ExplosionR = Instance.new("Explosion", GrapeLClone)

					ExplosionL.BlastRadius = 30
					ExplosionR.BlastRadius = 30

					ExplosionL.ExplosionType = Enum.ExplosionType.Craters
					ExplosionR.ExplosionType = Enum.ExplosionType.Craters

					ExplosionL.Position = GrapeLClone.Position
					ExplosionR.Position = GrapeRClone.Position

					ExplosionL.Parent = GrapeLClone
					ExplosionR.Parent = GrapeRClone
					
					-- Checking people who will die most likely
					local MaxDist = 10
					for _, plr in pairs(game.Players:GetPlayers()) do
						if Player == plr then continue end
						local Root = plr.Character:WaitForChild("HumanoidRootPart")
						if (Root.Position - PlayerCharacter.HumanoidRootPart.Position).Magnitude <= MaxDist then
							Root.Parent:SetAttribute("Killer", plr.Name)
							Root.Parent:SetAttribute("Distance", (Root.Position - PlayerCharacter.HumanoidRootPart.Position).Magnitude)
							task.delay(10, function()
								Root.Parent:SetAttribute("Killer", "")
								Root.Parent:SetAttribute("Distance", "")
							end)
						end
					end

					PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("SFX"):WaitForChild("Explosion"):Play()

					local VFX1 = PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("VFX"):Clone()
					VFX1.Position = GrapeLClone.Position
					local VFX2 = PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("VFX"):Clone()
					VFX2.Position = GrapeRClone.Position

					VFX1.Parent = GrapeLClone
					VFX2.Parent = GrapeRClone

					for _, Particle in ipairs(VFX1.Attachment:GetDescendants()) do
						Particle:Emit(Particle:GetAttribute("EmitCount"))
					end
					for _, Particle in ipairs(VFX2.Attachment:GetDescendants()) do
						Particle:Emit(Particle:GetAttribute("EmitCount"))
					end

					GrapeLClone.Transparency = 1
					GrapeRClone.Transparency = 1
					task.wait(0.6)
					GrapeRClone:Destroy()
					GrapeLClone:Destroy()
				end
			end
		end
	
	elseif Status == "CheckHitbox" then	
		if self.Name == "Grape" then
			local PlayerCharacter = workspace:FindFirstChild(Player.Name)
			if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
			if PlayerCharacter:GetAttribute("UltimateAttackCooldown") == true then return end
			PlayerCharacter:SetAttribute("UltimateAttackCooldown", true)
			task.delay(2, function()
				PlayerCharacter:SetAttribute("UltimateAttackCooldown", false)
			end)
			
			local GrapeL = PlayerCharacter:FindFirstChild("GrapeL")
			local GrapeR = PlayerCharacter:FindFirstChild("GrapeR")
			
			
			local ActionAnim: AnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Grape"):WaitForChild("Action"))
			ActionAnim:Play()
			ActionAnim:GetMarkerReachedSignal("Action"):Connect(function()
				GrapeL.Transparency = 1
				GrapeR.Transparency = 1
				
				task.delay(0.3, function()
					GrapeL.Transparency = 0
					GrapeR.Transparency = 0
				end)
				
				local GrapeLClone = GrapeL:Clone()
				local GrapeRClone = GrapeR:Clone()
				GrapeLClone.Name = "GrapeL_".. PlayerCharacter.Name
				GrapeRClone.Name = "GrapeR_".. PlayerCharacter.Name
				-- Destroy descendants
				for _, Descendant in pairs(GrapeLClone:GetDescendants()) do
					Descendant:Destroy()
				end
				for _, Descendant in pairs(GrapeRClone:GetDescendants()) do
					Descendant:Destroy()
				end
				
				-- Setting values
				GrapeLClone.CanCollide = true
				GrapeRClone.CanCollide = true
				GrapeLClone.Transparency = 0
				GrapeRClone.Transparency = 0
				
				GrapeLClone.CFrame = PlayerCharacter.LeftHand.CFrame
				GrapeRClone.CFrame =  PlayerCharacter.RightHand.CFrame
				
				
				game:GetService("TweenService"):Create(GrapeLClone, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, false, 0.5), {Size = Vector3.new(10, 10, 10)}):Play()
				game:GetService("TweenService"):Create(GrapeRClone, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, false, 0.5), {Size = Vector3.new(10, 10, 10)}):Play()
				
				GrapeLClone.Parent = bulletsFolder
				GrapeRClone.Parent = bulletsFolder
				Debris:AddItem(GrapeLClone, 4)
				Debris:AddItem(GrapeRClone, 4)
				
				task.wait(0.5)
				PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("SFX"):WaitForChild("Balloon Inflating"):Play()
				
				-- Exploding
				task.delay(3, function()
					if GrapeLClone and GrapeRClone then
						if 
							GrapeLClone:FindFirstChildOfClass("Explosion")
							or GrapeRClone:FindFirstChildOfClass("Explosion")
							or bulletsFolder:FindFirstChild(GrapeLClone.Name) == nil
							or bulletsFolder:FindFirstChild(GrapeRClone.Name) == nil
						then return end
						
						local ExplosionL = Instance.new("Explosion", GrapeLClone)
						local ExplosionR = Instance.new("Explosion", GrapeLClone)

						ExplosionL.BlastRadius = 30
						ExplosionR.BlastRadius = 30

						ExplosionL.ExplosionType = Enum.ExplosionType.Craters
						ExplosionR.ExplosionType = Enum.ExplosionType.Craters

						ExplosionL.Position = GrapeLClone.Position
						ExplosionR.Position = GrapeRClone.Position

						ExplosionL.Parent = GrapeLClone
						ExplosionR.Parent = GrapeRClone

						PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("SFX"):WaitForChild("Explosion"):Play()

						local VFX1 = PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("VFX"):Clone()
						VFX1.Position = GrapeLClone.Position
						local VFX2 = PlayerCharacter:FindFirstChild("Ultimate"):FindFirstChild("VFX"):Clone()
						VFX2.Position = GrapeRClone.Position

						VFX1.Parent = GrapeLClone
						VFX2.Parent = GrapeRClone

						for _, Particle in ipairs(VFX1.Attachment:GetDescendants()) do
							Particle:Emit(Particle:GetAttribute("EmitCount"))
						end
						for _, Particle in ipairs(VFX2.Attachment:GetDescendants()) do
							Particle:Emit(Particle:GetAttribute("EmitCount"))
						end

						GrapeLClone.Transparency = 1
						GrapeRClone.Transparency = 1
						task.wait(0.6)
						GrapeRClone:Destroy()
						GrapeLClone:Destroy()
					end
				end)
			end)	
		elseif self.Name == "Rokakaka" then
			local PlayerCharacter = workspace:FindFirstChild(Player.Name)
			if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
			if PlayerCharacter:GetAttribute("UltimateAttackCooldown") == true then return end
			PlayerCharacter:SetAttribute("UltimateAttackCooldown", true)
			task.delay(5, function()
				PlayerCharacter:SetAttribute("UltimateAttackCooldown", false)
			end)
			if Type == 2 then
				local Stand = PlayerCharacter:FindFirstChild("Ultimate")
				local Animator: Animator = Stand.Humanoid.Animator
				local ActionAnim = Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Rokakaka"):WaitForChild("Action"))
				
				for _, PlayingAnims in ipairs(Animator:GetPlayingAnimationTracks()) do
					PlayingAnims:Stop()
				end
				
				ActionAnim:Play()			
				task.delay(2.5, function()
					for _, PlayingAnims in ipairs(Animator:GetPlayingAnimationTracks()) do
						PlayingAnims:Stop()
					end
	
					local IdleAnimation = Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Rokakaka"):WaitForChild("Stand Idle"))
					IdleAnimation:Play()
				end)
	
				-- Hitbox
				local Params = OverlapParams.new()
				Params.FilterType = Enum.RaycastFilterType.Blacklist
				Params.FilterDescendantsInstances = {PlayerCharacter}
				local VFXDebounce = false
				local ActionSFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Rokakaka"):WaitForChild("MudaMudaMuda"):Clone()
				ActionSFX.Parent = PlayerCharacter
				ActionSFX:Play()
				task.delay(2.4, function()
					ActionSFX:Destroy()
				end)
				for i = 1, 145, 1 do
					task.wait()
					--[[
					local HitboxPart = Instance.new("Part")
					HitboxPart.Anchored = true
					HitboxPart.CanCollide = false
					HitboxPart.Transparency = 0.5
					HitboxPart.CFrame = PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
					HitboxPart.Size = Vector3.new(7, 10, 7)
					HitboxPart.Parent = workspace 
					Debris:AddItem(HitboxPart, 2) ]]--
					
					local Hitbox = workspace:GetPartBoundsInBox(PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8), Vector3.new(7, 10, 7), Params)
					
					for _, HitParts in Hitbox do
						local HitParent = HitParts.Parent
						if HitParent:GetAttribute("Loading") == true then return end
						if HitParent and HitParent:FindFirstChild("Humanoid") and not HitParent:FindFirstChild("Ultimate") then
							-- Spawn VFX
							if not VFXDebounce then
								VFXDebounce = true
								SpawnVFXEvent:FireAllClients(WeaponsFolder:WaitForChild("Throwable"):WaitForChild("Banana"):WaitForChild("Handle"), HitParent.HumanoidRootPart.Position, Player)
								task.delay(0.1, function()
									VFXDebounce = false
								end)
							end
							-- Main
							HitParent:FindFirstChild("Humanoid").Health -= 0.02
							HitParent.Humanoid.WalkSpeed = 6
							HitParent:SetAttribute("SlideDebounce", true)
							task.delay(1, function()
								HitParent.Humanoid.WalkSpeed = 16
								task.delay(0.5, function()
									HitParent:SetAttribute("SlideDebounce", false)
								end)
								
							end)
	
							-- Setting atributes
							local Distance = (PlayerCharacter.HumanoidRootPart.Position - HitParent.HumanoidRootPart.Position).Magnitude
							HitParent:SetAttribute("Distance", Distance)
							HitParent:SetAttribute("Killer", Player.Name)
	
							-- Resetting killfeed
							task.delay(10, function() -- Reset
								HitParent:SetAttribute("Distance", "")
								HitParent:SetAttribute("Killer", "")
							end)
						else
							if HitParent:FindFirstChild("Ultimate") then	
								if HitParent:FindFirstChild("Ultimate"):GetAttribute("Ultimate") == "Apple" then
									if HitParent:GetAttribute("UltimateHealth") > 0 then
										HitParent:SetAttribute("UltimateHealth", HitParent:GetAttribute("UltimateHealth") - 2)
										-- Update ULT Health
										game:GetService("TweenService"):Create(HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(HitParent:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
										HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = HitParent:GetAttribute("UltimateHealth").. "HP"	
									end
									coroutine.wrap(function()
										if HitParent:GetAttribute("UltimateHealth") <= 0 then
											-- Delays
											HitParent:WaitForChild("Ultimate"):Destroy()
	
											-- Reset
											local Player = game:GetService("Players"):GetPlayerFromCharacter(HitParent)
											local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
											local Cooldown = string.match(CooldownText.Text, "%(.*%)")
											Cooldown = string.split(Cooldown, "(")
											Cooldown[2] = string.split(Cooldown[2], ")")
											Cooldown = Cooldown[2][1]
											task.delay(Cooldown, function()
												PlayerCharacter:SetAttribute("UltimateCooldown", false)
												HitParent:SetAttribute("UltimateHealth", 250)
											end)
										end
									end)()
								end
							end
						end
					end
				end
			else
				local Stand = PlayerCharacter:FindFirstChild("Ultimate")
				local Animator: Animator = Stand.Humanoid.Animator
				local ActionAnim = Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Rokakaka"):WaitForChild("Regular Punch"))

				for _, PlayingAnims in ipairs(Animator:GetPlayingAnimationTracks()) do
					PlayingAnims:Stop()
				end

				ActionAnim:Play()		
				-- Punch SFX
				local PunchSFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Rokakaka"):WaitForChild("Punch"):Clone()
				PunchSFX.Parent = PlayerCharacter
				PunchSFX:Play()
				Debris:AddItem(PunchSFX, 3)
				task.delay(0.53, function()
					for _, PlayingAnims in ipairs(Animator:GetPlayingAnimationTracks()) do
						PlayingAnims:Stop()
					end

					local IdleAnimation = Animator:LoadAnimation(ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Rokakaka"):WaitForChild("Stand Idle"))
					IdleAnimation:Play()
				end)

				-- Hitbox
				local Params = OverlapParams.new()
				Params.FilterType = Enum.RaycastFilterType.Blacklist
				Params.FilterDescendantsInstances = {PlayerCharacter}

				local CharactersOnDebounce = {}

				local Hitbox = workspace:GetPartBoundsInBox(PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8), Vector3.new(7, 10, 7), Params)
				for _, Hit in ipairs(Hitbox) do
					local HitParent = Hit.Parent
					if HitParent:GetAttribute("Loading") == true then return end
					if HitParent and HitParent:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, HitParent.Name) and not HitParent:FindFirstChild("Ultimate") then
						-- Spawn VFX
						SpawnVFXEvent:FireAllClients(WeaponsFolder:WaitForChild("Throwable"):WaitForChild("Banana"):WaitForChild("Handle"), HitParent.HumanoidRootPart.Position, Player)
						-- Main
						HitParent:FindFirstChild("Humanoid").Health -= 20
						KnockBack(HitParent, HitParent.HumanoidRootPart.CFrame.LookVector * -650)
						HitParent.Humanoid.WalkSpeed = 6
						HitParent:SetAttribute("SlideDebounce", true)
						task.delay(1, function()
							HitParent.Humanoid.WalkSpeed = 16
							task.delay(0.6, function()
								HitParent:SetAttribute("SlideDebounce", false)
							end)
						end)
						
						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - HitParent.HumanoidRootPart.Position).Magnitude
						HitParent:SetAttribute("Distance", Distance)
						HitParent:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							HitParent:SetAttribute("Distance", "")
							HitParent:SetAttribute("Killer", "")
						end)
						
						table.insert(CharactersOnDebounce, HitParent.Name)
					else
						if HitParent:FindFirstChild("Ultimate") then	
							if HitParent:FindFirstChild("Ultimate"):GetAttribute("Ultimate") == "Apple" then
								if HitParent:GetAttribute("UltimateHealth") > 0 then
									HitParent:SetAttribute("UltimateHealth", HitParent:GetAttribute("UltimateHealth") - 25)
									-- Update ULT Health
									game:GetService("TweenService"):Create(HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(HitParent:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
									HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = HitParent:GetAttribute("UltimateHealth").. "HP"	
								end
								table.insert(CharactersOnDebounce, HitParent.Name)
								coroutine.wrap(function()
									if HitParent:GetAttribute("UltimateHealth") <= 0 then
										-- Delays
										HitParent:WaitForChild("Ultimate"):Destroy()

										-- Reset
										local Player = game:GetService("Players"):GetPlayerFromCharacter(HitParent)
										local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
										local Cooldown = string.match(CooldownText.Text, "%(.*%)")
										Cooldown = string.split(Cooldown, "(")
										Cooldown[2] = string.split(Cooldown[2], ")")
										Cooldown = Cooldown[2][1]
										task.delay(Cooldown, function()
											PlayerCharacter:SetAttribute("UltimateCooldown", false)
											HitParent:SetAttribute("UltimateHealth", 250)
										end)
									end
								end)()
							end
						end
					end
				end
			end
		elseif self.Name == "GomuGomuNoMi" then
			local PlayerCharacter = workspace:FindFirstChild(Player.Name)
			if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
			if PlayerCharacter:GetAttribute("UltimateAttackCooldown") == true then return end
			if PlayerCharacter:GetAttribute("SlideDebounce") == true then return end
			PlayerCharacter:SetAttribute("UltimateAttackCooldown", true)
			task.delay(3.5, function()
				PlayerCharacter:SetAttribute("UltimateAttackCooldown", false)
			end)
			
			if Type == 1 then
				local ActionAnimation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("GomuGomuNoMi"):WaitForChild("Action")
				local ActionAnim: AnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(ActionAnimation)
				PlayerCharacter.Humanoid.WalkSpeed = 0
				PlayerCharacter.Humanoid.JumpHeight = 0

				local hrp = PlayerCharacter:WaitForChild("HumanoidRootPart")
				local rightUpperArm = PlayerCharacter:WaitForChild("RightUpperArm")
				local rightHand = PlayerCharacter:WaitForChild("RightHand")

				local partStretch = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("Ultimates"):WaitForChild("GomuGomuNoMi"):Clone()
				partStretch.Material = Enum.Material.SmoothPlastic
				partStretch.Massless = true
				partStretch.CFrame = rightHand.CFrame
				-- partStretch.Size = rightHand.Size
				partStretch.CanCollide = false
				partStretch.Anchored = false
				partStretch.Orientation = rightHand.Orientation
				partStretch.Color = rightHand.Color
				partStretch.Parent = bulletsFolder

				local weld = Instance.new("ManualWeld")
				weld.Part0 = partStretch
				weld.Part1 = rightHand
				weld.C0 = weld.Part0.CFrame:ToObjectSpace(weld.Part1.CFrame)
				weld.Parent = weld.Part0

				for _, PlayingAnims in ipairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					PlayingAnims:Stop()
				end

				ActionAnim:Play()			
				ActionAnim:GetMarkerReachedSignal("Hold"):Connect(function()
					ActionAnim:AdjustSpeed(0)
				end)

				task.wait(0.5)
				ActionAnim:AdjustSpeed(1)

				ActionAnim:GetMarkerReachedSignal("Release"):Connect(function()
					if ActionAnim.Speed ~= 0 then
						repeat
							task.wait()
							ActionAnim:AdjustSpeed(0)
						until   ActionAnim.Speed == 0
					end

					local PistolInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true, 0)
					local ArmSpeed = Vector3.new(0,0,10)
					local SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("GomuGomuNoMi"):WaitForChild("Stretch"):Clone()
					SFX.Parent = PlayerCharacter
					SFX:Play()
					CameraHandler:FireClient(Player)
					local PistolTweenSize = game:GetService("TweenService"):Create(partStretch, PistolInfo, {Size = partStretch.Size + Vector3.new(0,46,0)})
					PistolTweenSize:Play()
					local TweenPos = game:GetService("TweenService"):Create(weld, PistolInfo, {C0 = CFrame.new(0, 23, 0)}):Play()
					-- SPAWNING SHOCKWAVE CIRCLS
					task.spawn(function()
						for i = 6, 18, 6 do
							local Circle = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("GumoGumoNoMi"):WaitForChild("Circle"):Clone()
							Circle.CFrame = rightHand.CFrame * CFrame.new(0, -i, 0)
							Circle.Parent = workspace
							Debris:AddItem(Circle, 3.5)
						end
					end)
					
					task.wait(1.5)
					SFX:Destroy()
					ActionAnim:Stop()

					local SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("GomuGomuNoMi"):WaitForChild("Retract"):Clone()
					SFX.Parent = PlayerCharacter
					SFX:Play()
					task.wait(0.6)
					SFX:Destroy()
					PlayerCharacter.Humanoid.WalkSpeed = 16
					PlayerCharacter.Humanoid.JumpHeight = 7.2
					partStretch:Destroy()
				end)
				-- Hitbox
				local Overlap_Params = OverlapParams.new()
				Overlap_Params.FilterType = Enum.RaycastFilterType.Blacklist
				Overlap_Params.FilterDescendantsInstances = {PlayerCharacter, partStretch}

				local charactersOnDebounce = {}
				coroutine.wrap(function()
					for i = 0, 46 do
						task.wait()
						local spawnPos = hrp.CFrame * CFrame.new(0, 1, -i)
						local hitParts = workspace:GetPartBoundsInBox(spawnPos, Vector3.new(6, 7, 7), Overlap_Params)

						for index, hitPartsVal in pairs(hitParts) do
							local hitPartsParent = hitPartsVal.Parent

							if hitPartsParent and hitPartsParent:FindFirstChild("Humanoid") and not table.find(charactersOnDebounce, hitPartsParent.Name) then
								hitPartsParent:FindFirstChild("Humanoid"):TakeDamage(20)
								KnockBack(hitPartsParent, ((PlayerCharacter.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 3, 1)).Unit * 700))
								table.insert(charactersOnDebounce, hitPartsParent.Name)
							end
						end
					end
				end)()		
			else
				local ActionAnimation = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("GomuGomuNoMi"):WaitForChild("GomuGomuNoOno")
				local ActionAnim: AnimationTrack = PlayerCharacter.Humanoid.Animator:LoadAnimation(ActionAnimation)
				PlayerCharacter.Humanoid.WalkSpeed = 0
				PlayerCharacter.Humanoid.JumpHeight = 0

				local hrp = PlayerCharacter:WaitForChild("HumanoidRootPart")
				local rightHand = PlayerCharacter:WaitForChild("LeftFoot")

				local partStretch = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild("Ultimates"):WaitForChild("GomuGomuNoMi"):Clone()
				partStretch.Material = Enum.Material.SmoothPlastic
				partStretch.Massless = true
				partStretch.CFrame = rightHand.CFrame
				partStretch.Size = rightHand.Size
				partStretch.CanCollide = false
				partStretch.Anchored = false
				partStretch.Orientation = rightHand.Orientation
				partStretch.Color = rightHand.Color
				partStretch.Parent = bulletsFolder

				local weld = Instance.new("ManualWeld")
				weld.Part0 = partStretch
				weld.Part1 = rightHand
				weld.C0 = weld.Part0.CFrame:ToObjectSpace(weld.Part1.CFrame)
				weld.Parent = weld.Part0

				for _, PlayingAnims in ipairs(PlayerCharacter.Humanoid.Animator:GetPlayingAnimationTracks()) do
					PlayingAnims:Stop()
				end

				ActionAnim:Play()			

				ActionAnim:GetMarkerReachedSignal("Hold"):Connect(function()
					local PistolInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local ArmSpeed = Vector3.new(0,10,0)
					
					local SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("GomuGomuNoMi"):WaitForChild("Stretch"):Clone()
					SFX.Parent = PlayerCharacter
					SFX:Play()
					CameraHandler:FireClient(Player)
					task.spawn(function()
						for i = 3, 12, 3 do
							local Circle = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("GumoGumoNoMi"):WaitForChild("Circle"):Clone()
							Circle.CFrame = rightHand.CFrame * CFrame.new(0, -i, 0)
						end
					end)
					
					local PistolTweenSize = game:GetService("TweenService"):Create(partStretch, PistolInfo, {Size = partStretch.Size + Vector3.new(0,50,0)})
					PistolTweenSize:Play()
					local TweenPos = game:GetService("TweenService"):Create(weld, PistolInfo, {C0 = CFrame.new(0, 25, 0)}):Play()
					
					-- SPAWNING SHOCKWAVE CIRCLS
					task.spawn(function()
						for i = 6, 48, 6 do
							local Circle = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("GumoGumoNoMi"):WaitForChild("Circle"):Clone()
							Circle.CFrame = PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, i, 0)
							Circle.Parent = workspace
							Debris:AddItem(Circle, 3.5)
						end
					end)

					task.wait(1.5)
					SFX:Destroy()
					local PistolInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local PistolTweenSize = game:GetService("TweenService"):Create(partStretch, PistolInfo, {Size = partStretch.Size + Vector3.new(0,-50,0)})
					PistolTweenSize:Play()
					local TweenPos = game:GetService("TweenService"):Create(weld, PistolInfo, {C0 = CFrame.new(0, 0, 0)}):Play()
					task.wait(0.1)
					ActionAnim:AdjustSpeed(1)
					-- Camera shake
					task.spawn(function()
						for i = 1, 4, 1 do
							CameraHandler:FireClient(Player)
						end
					end)
					-- Spawning VFX
					local VFX = ReplicatedStorage:WaitForChild("VFX"):WaitForChild("Ultimates"):WaitForChild("GumoGumoNoMi"):WaitForChild("Hit"):Clone()
					VFX:PivotTo(PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 26.5, 0))
					VFX.Parent = workspace
					Debris:AddItem(VFX, 6)
					-- SFX
					SFX = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("GomuGomuNoMi"):WaitForChild("Broken Ground"):Clone()
					SFX.Parent = PlayerCharacter
					SFX:Play()

					local SFX2 = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("GomuGomuNoMi"):WaitForChild("Retract"):Clone()
					SFX2.Parent = PlayerCharacter
					SFX2:Play()

					-- Hitbox
					local Params = OverlapParams.new()
					Params.FilterType = Enum.RaycastFilterType.Blacklist
					Params.FilterDescendantsInstances = {PlayerCharacter}
					local Hitbox = workspace:GetPartBoundsInRadius(rightHand.Position, 30, Params)
					local CharactersOnDebounce = {}
					for _, Hit in ipairs(Hitbox) do
						local HitParent = Hit.Parent
						if HitParent:GetAttribute("Loading") == true then return end
						if HitParent and HitParent:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, HitParent.Name) and not HitParent:FindFirstChild("Ultimate") then
							-- Spawn VFX
							SpawnVFXEvent:FireAllClients(WeaponsFolder:WaitForChild("Throwable"):WaitForChild("GomuGomuNoMi"):WaitForChild("Handle"), HitParent.HumanoidRootPart.Position, Player)
							-- Main
							HitParent:FindFirstChild("Humanoid").Health -= 40
							KnockBack(HitParent, HitParent.HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 3, 1) * -750)
							HitParent.Humanoid.WalkSpeed = 6
							HitParent:SetAttribute("SlideDebounce", true)
							task.delay(1, function()
								HitParent.Humanoid.WalkSpeed = 16
								task.delay(0.5, function()
									HitParent:SetAttribute("SlideDebounce", false)
								end)
								
							end)
							
							-- Setting atributes
							local Distance = (PlayerCharacter.HumanoidRootPart.Position - HitParent.HumanoidRootPart.Position).Magnitude
							HitParent:SetAttribute("Distance", Distance)
							HitParent:SetAttribute("Killer", Player.Name)

							-- Resetting killfeed
							task.delay(10, function() -- Reset
								HitParent:SetAttribute("Distance", "")
								HitParent:SetAttribute("Killer", "")
							end)
							
							table.insert(CharactersOnDebounce, HitParent.Name)
						else
							if HitParent:FindFirstChild("Ultimate") then	
								if HitParent:FindFirstChild("Ultimate"):GetAttribute("Ultimate") == "Apple" then
									if HitParent:GetAttribute("UltimateHealth") > 0 then
										HitParent:SetAttribute("UltimateHealth", HitParent:GetAttribute("UltimateHealth") - 75)
										-- Update ULT Health
										game:GetService("TweenService"):Create(HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(HitParent:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
										HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = HitParent:GetAttribute("UltimateHealth").. "HP"	
									end
									table.insert(CharactersOnDebounce, HitParent.Name)
									coroutine.wrap(function()
										if HitParent:GetAttribute("UltimateHealth") <= 0 then
											-- Delays
											HitParent:WaitForChild("Ultimate"):Destroy()

											-- Reset
											local Player = game:GetService("Players"):GetPlayerFromCharacter(HitParent)
											local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
											local Cooldown = string.match(CooldownText.Text, "%(.*%)")
											Cooldown = string.split(Cooldown, "(")
											Cooldown[2] = string.split(Cooldown[2], ")")
											Cooldown = Cooldown[2][1]
											task.delay(Cooldown, function()
												PlayerCharacter:SetAttribute("UltimateCooldown", false)
												HitParent:SetAttribute("UltimateHealth", 250)
											end)
										end
									end)()
								end
							end
						end
					end

					-- RESET
					task.delay(0.6, function()
						PlayerCharacter.Humanoid.WalkSpeed = 16
						PlayerCharacter.Humanoid.JumpHeight = 7.2
						partStretch:Destroy()
						task.delay(1.2, function()
							SFX:Destroy()
							SFX2:Destroy()
						end)
					end)
				end)
				-- Hitbox
				local Overlap_Params = OverlapParams.new()
				Overlap_Params.FilterType = Enum.RaycastFilterType.Blacklist
				Overlap_Params.FilterDescendantsInstances = {PlayerCharacter, partStretch}

			end	
			
		elseif self.Name == "Banana" then
			local PlayerCharacter = workspace:FindFirstChild(Player.Name)
			if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
			if PlayerCharacter:GetAttribute("UltimateAttackCooldown") == true then return end
			PlayerCharacter:SetAttribute("UltimateAttackCooldown", true)
			task.delay(0.10, function()
				PlayerCharacter:SetAttribute("UltimateAttackCooldown", false)
			end)
			-- Instances
			UltimatesFolder:FindFirstChild("Banana"):FindFirstChild("SFX"):FindFirstChild("Action"):Play()
			local HitboxParams = OverlapParams.new()
			HitboxParams.FilterType = Enum.RaycastFilterType.Exclude
			HitboxParams.FilterDescendantsInstances = {PlayerCharacter}
			local Hitbox = workspace:GetPartBoundsInBox(PlayerCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5), Vector3.new(9, 9, 6.5), HitboxParams)
			
			local CharactersOnDebounce = {}
			for Index, Hit in pairs(Hitbox) do
				local HitParent = Hit.Parent
				if HitParent:GetAttribute("Loading") == true then return end
				if HitParent and HitParent:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, HitParent.Name) and not HitParent:FindFirstChild("Ultimate") then
					-- Spawn VFX
					SpawnVFXEvent:FireAllClients(WeaponsFolder:WaitForChild("Throwable"):WaitForChild("Banana"):WaitForChild("Handle"), HitParent.HumanoidRootPart.Position, Player)
					-- Main
					HitParent:FindFirstChild("Humanoid").Health -= 3
					HitParent.Humanoid.WalkSpeed = 6
					HitParent:SetAttribute("SlideDebounce", true)
					task.delay(1, function()
						HitParent.Humanoid.WalkSpeed = 16
						task.delay(0.5, function()
							HitParent:SetAttribute("SlideDebounce", false)
						end)
						
					end)
					
					-- Setting atributes
					local Distance = (PlayerCharacter.HumanoidRootPart.Position - HitParent.HumanoidRootPart.Position).Magnitude
					HitParent:SetAttribute("Distance", Distance)
					HitParent:SetAttribute("Killer", Player.Name)

					-- Resetting killfeed
					task.delay(10, function() -- Reset
						HitParent:SetAttribute("Distance", "")
						HitParent:SetAttribute("Killer", "")
					end)
					
					table.insert(CharactersOnDebounce, HitParent.Name)
				else
					if HitParent:FindFirstChild("Ultimate") then	
						if HitParent:FindFirstChild("Ultimate"):GetAttribute("Ultimate") == "Apple" then
							if HitParent:GetAttribute("UltimateHealth") > 0 then
								HitParent:SetAttribute("UltimateHealth", HitParent:GetAttribute("UltimateHealth") - 25)
								-- Update ULT Health
								game:GetService("TweenService"):Create(HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(HitParent:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
								HitParent:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = HitParent:GetAttribute("UltimateHealth").. "HP"	
							end
							table.insert(CharactersOnDebounce, HitParent.Name)
							coroutine.wrap(function()
								if HitParent:GetAttribute("UltimateHealth") <= 0 then
									-- Delays
									HitParent:WaitForChild("Ultimate"):Destroy()

									-- Reset
									local Player = game:GetService("Players"):GetPlayerFromCharacter(HitParent)
									local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
									local Cooldown = string.match(CooldownText.Text, "%(.*%)")
									Cooldown = string.split(Cooldown, "(")
									Cooldown[2] = string.split(Cooldown[2], ")")
									Cooldown = Cooldown[2][1]
									task.delay(Cooldown, function()
										PlayerCharacter:SetAttribute("UltimateCooldown", false)
										HitParent:SetAttribute("UltimateHealth", 250)
									end)
								end
							end)()
						end
					end
				end
			end
		end
	end
end

function Weapons:Activated(Player, MousePosition, FirePoint, Weapon) -- Attack
	if self.Name == "Grape" then
		-- Instances
		local PlayerCharacter = workspace:FindFirstChild(Player.Name)
		if PlayerCharacter:GetAttribute("Cooldown") == true then return end
		if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
		if PlayerCharacter:GetAttribute("Loading") == true then return end
		PlayerCharacter:SetAttribute("CooldownTime", self.CooldownTime)
		PlayerCharacter:SetAttribute("Cooldown", true)
		PlayerCharacter:FindFirstChild(self.Name).Handle.Transparency = 1

		-- Removing cooldown
		task.delay(PlayerCharacter:GetAttribute("CooldownTime"), function()
			PlayerCharacter:SetAttribute("Cooldown", false)
		end)
		-- Gui
		task.spawn(function()
			GuiHandler:Cooldown(Player)
		end)
		local Pellet = game:GetService("ServerStorage"):WaitForChild("Grape Pellet")
		-- Casting
		-- local Direction = (MousePosition - PlayerCharacter.RightHand.Position).Unit -- Gets the vector between firepoint & mousepos and normalizes it
		castParams.FilterDescendantsInstances = {Pellet, bulletsFolder, Weapon:FindFirstChild("VFX"), Player.Character, workspace:WaitForChild("Map"):FindFirstChild("DeadZone"), workspace:WaitForChild("Map"):WaitForChild("SpawnPoints")}
		-- Bullet temp
		local CosmeticWeapon = Pellet:Clone()
		CosmeticWeapon.Name = Player.Name
		CastBehavior.CosmeticBulletTemplate = CosmeticWeapon
		CastBehavior.RaycastParams = castParams

		task.delay(0.3, function()
			if PlayerCharacter:FindFirstChild(self.Name) then
				PlayerCharacter:FindFirstChild(self.Name).Handle.Transparency = 0
			else
				Player.Backpack:FindFirstChild(self.Name).Handle.Transparency = 0
			end
		end)


		local CharactersOnDebounce = {}
		local ShotgunCast = FastCastRedux.new()
		local function onLengthChanged(Cast, LastPoint, Direction, Length, Velocity, Bullet)
			if Bullet then
				local BulletLength = Bullet.Size.Z/2
				local Offset = CFrame.new(0, 0, -(Length - BulletLength))
				Bullet.CFrame = CFrame.lookAt(LastPoint, LastPoint + Direction):ToWorldSpace(Offset)
			else
				Cast:Terminate()
			end
		end
		
		local function Fire(direction)
			local directionCF = CFrame.new(Vector3.new(), direction)
			local spreadDirection = CFrame.fromOrientation(0, 0, math.random(0, math.pi * 2))
			local spreadAngle = CFrame.fromOrientation(math.rad(math.random(1, 4)), 0, 0)
			local Direction = (directionCF * spreadDirection * spreadAngle).LookVector
			ShotgunCast:Fire(PlayerCharacter.RightHand.Position, Direction, self.Speed, CastBehavior)
		end
		local direction = (MousePosition - PlayerCharacter.RightHand.Position).Unit
		
		for i = 1, 6 do
			Fire(direction)
		end
		-- local ActiveCast = self.Caster:Fire(PlayerCharacter.RightHand.Position, (MousePosition - PlayerCharacter.RightHand.Position).Unit, self.Speed, CastBehavior)
		ShotgunCast.LengthChanged:Connect(onLengthChanged)
		local Connection: RBXScriptConnection
		ShotgunCast.RayHit:Connect(function(Cast, Result, Velocity, Bullet)
			Cast:Pause()
			Bullet:Destroy()

			local Hit = Result.Instance

			local Character = Hit:FindFirstAncestorWhichIsA("Model")
			if Character:GetAttribute("Loading") == true then return end
			if Character and Character:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, Character.Name) then
				-- Add & Reset debounce
				table.insert(CharactersOnDebounce, Character.Name)
				if Character:FindFirstChild("Ultimate") then
					if Character:FindFirstChild("Ultimate"):GetAttribute("Ultimate") ~= "Apple" then
						Character.Humanoid:TakeDamage(self.Damage)
						KnockBack(Character, Velocity)
						Character:SetAttribute("Ragdolled", true)
						task.delay(2.5, function()
							Character:SetAttribute("Ragdolled", false)
						end)

						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						Character:SetAttribute("Distance", Distance)
						Character:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							Character:SetAttribute("Distance", "")
							Character:SetAttribute("Killer", "")
						end)

					else
						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						Character:SetAttribute("Distance", Distance)
						Character:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							Character:SetAttribute("Distance", "")
							Character:SetAttribute("Killer", "")
						end)

						-- Dealing DMG
						if Character:GetAttribute("UltimateHealth") > 0 then
							Character:SetAttribute("UltimateHealth", Character:GetAttribute("UltimateHealth") - self.Damage)
							-- Update ULT Health
							game:GetService("TweenService"):Create(Character:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(Character:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
							Character:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = Character:GetAttribute("UltimateHealth").. "HP"	
						end

						coroutine.wrap(function()
							if Character:GetAttribute("UltimateHealth") <= 0 then
								-- Delays
								local Destination = Character:WaitForChild("Ultimate").CFrame
								Character:WaitForChild("Ultimate"):Destroy()
								Character.Humanoid.JumpHeight = 7.2

								local Explosion = Instance.new("Explosion", Character)

								Explosion.BlastRadius = 30
								Explosion.ExplosionType = Enum.ExplosionType.Craters
								Explosion.Position = Destination
								Explosion.Parent = Character

								-- Reset
								local Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
								local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
								local Cooldown = string.match(CooldownText.Text, "%(.*%)")
								Cooldown = string.split(Cooldown, "(")
								Cooldown[2] = string.split(Cooldown[2], ")")
								Cooldown = Cooldown[2][1]
								task.delay(Cooldown, function()
									PlayerCharacter:SetAttribute("UltimateCooldown", false)
									Character:SetAttribute("UltimateHealth", 250)
								end)
							end
						end)()
					end
				else
					Character.Humanoid:TakeDamage(self.Damage)
					KnockBack(Character, Velocity)
					Character:SetAttribute("Ragdolled", true)
					task.delay(2.5, function()
						Character:SetAttribute("Ragdolled", false)
					end)

					-- Setting atributes
					local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
					Character:SetAttribute("Distance", Distance)
					Character:SetAttribute("Killer", Player.Name)

					-- Resetting killfeed
					task.delay(10, function() -- Reset
						Character:SetAttribute("Distance", "")
						Character:SetAttribute("Killer", "")
					end)
				end
			end
			SpawnVFXEvent:FireAllClients(Weapon, Result.Position, Player)
		end)

	elseif workspace:GetAttribute("Event") == "All Shotgun" then
		-- Instances
		local PlayerCharacter = workspace:FindFirstChild(Player.Name)
		if PlayerCharacter:GetAttribute("Cooldown") == true then return end
		if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
		if PlayerCharacter:GetAttribute("Loading") == true then return end
		PlayerCharacter:SetAttribute("CooldownTime", self.CooldownTime)
		PlayerCharacter:SetAttribute("Cooldown", true)
		PlayerCharacter:FindFirstChild(self.Name).Handle.Transparency = 1

		-- Removing cooldown
		task.delay(PlayerCharacter:GetAttribute("CooldownTime"), function()
			PlayerCharacter:SetAttribute("Cooldown", false)
		end)
		-- Gui
		task.spawn(function()
			GuiHandler:Cooldown(Player)
		end)
		-- Casting
		-- local Direction = (MousePosition - PlayerCharacter.RightHand.Position).Unit -- Gets the vector between firepoint & mousepos and normalizes it
		castParams.FilterDescendantsInstances = {Weapon, Player.Character, workspace:WaitForChild("Map"):FindFirstChild("DeadZone"), workspace:WaitForChild("Map"):WaitForChild("SpawnPoints"), bulletsFolder}
		-- Bullet temp
		local CosmeticWeapon = Weapon:Clone()
		CosmeticWeapon.Name = Player.Name
		CastBehavior.CosmeticBulletTemplate = CosmeticWeapon
		CastBehavior.RaycastParams = castParams

		task.delay(0.3, function()
			if PlayerCharacter:FindFirstChild(self.Name) then
				PlayerCharacter:FindFirstChild(self.Name).Handle.Transparency = 0
			else
				Player.Backpack:FindFirstChild(self.Name).Handle.Transparency = 0
			end
		end)


		local CharactersOnDebounce = {}
		local ShotgunCast = FastCastRedux.new()
		local function onLengthChanged(Cast, LastPoint, Direction, Length, Velocity, Bullet)
			if Bullet then
				local BulletLength = Bullet.Size.Z/2
				local Offset = CFrame.new(0, 0, -(Length - BulletLength))
				Bullet.CFrame = CFrame.lookAt(LastPoint, LastPoint + Direction):ToWorldSpace(Offset)
			else
				Cast:Terminate()
			end
		end

		local function Fire(direction)
			local directionCF = CFrame.new(Vector3.new(), direction)
			local spreadDirection = CFrame.fromOrientation(0, 0, math.random(0, math.pi * 2))
			local spreadAngle = CFrame.fromOrientation(math.rad(math.random(1, 4)), 0, 0)
			local Direction = (directionCF * spreadDirection * spreadAngle).LookVector
			ShotgunCast:Fire(PlayerCharacter.RightHand.Position, Direction, self.Speed, CastBehavior)
		end
		local direction = (MousePosition - PlayerCharacter.RightHand.Position).Unit

		for i = 1, 6 do
			Fire(direction)
		end
		-- local ActiveCast = self.Caster:Fire(PlayerCharacter.RightHand.Position, (MousePosition - PlayerCharacter.RightHand.Position).Unit, self.Speed, CastBehavior)
		ShotgunCast.LengthChanged:Connect(onLengthChanged)
		local Connection: RBXScriptConnection
		ShotgunCast.RayHit:Connect(function(Cast, Result, Velocity, Bullet)
			Bullet:Destroy()
			local Hit = Result.Instance

			local Character = Hit:FindFirstAncestorWhichIsA("Model")
			if Character:GetAttribute("Loading") == true then return end
			if Character and Character:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, Character.Name) then
				-- Add & Reset debounce
				table.insert(CharactersOnDebounce, Character.Name)
				if Character:FindFirstChild("Ultimate") then
					if Character:FindFirstChild("Ultimate"):GetAttribute("Ultimate") ~= "Apple" then
						Character.Humanoid:TakeDamage(self.Damage)
						KnockBack(Character, Velocity)
						Character:SetAttribute("Ragdolled", true)
						task.delay(2.5, function()
							Character:SetAttribute("Ragdolled", false)
						end)

						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						Character:SetAttribute("Distance", Distance)
						Character:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							Character:SetAttribute("Distance", "")
							Character:SetAttribute("Killer", "")
						end)

					else
						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						Character:SetAttribute("Distance", Distance)
						Character:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							Character:SetAttribute("Distance", "")
							Character:SetAttribute("Killer", "")
						end)

						-- Dealing DMG
						if Character:GetAttribute("UltimateHealth") > 0 then
							Character:SetAttribute("UltimateHealth", Character:GetAttribute("UltimateHealth") - self.Damage)
							-- Update ULT Health
							game:GetService("TweenService"):Create(Character:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(Character:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
							Character:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = Character:GetAttribute("UltimateHealth").. "HP"	
						end

						coroutine.wrap(function()
							if Character:GetAttribute("UltimateHealth") <= 0 then
								-- Delays
								local Destination = Character:WaitForChild("Ultimate").CFrame
								Character:WaitForChild("Ultimate"):Destroy()
								Character.Humanoid.JumpHeight = 7.2

								local Explosion = Instance.new("Explosion", Character)

								Explosion.BlastRadius = 30
								Explosion.ExplosionType = Enum.ExplosionType.Craters
								Explosion.Position = Destination
								Explosion.Parent = Character


								-- Reset
								local Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
								local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
								local Cooldown = string.match(CooldownText.Text, "%(.*%)")
								Cooldown = string.split(Cooldown, "(")
								Cooldown[2] = string.split(Cooldown[2], ")")
								Cooldown = Cooldown[2][1]
								task.delay(Cooldown, function()
									PlayerCharacter:SetAttribute("UltimateCooldown", false)
									Character:SetAttribute("UltimateHealth", 250)
								end)
							end
						end)()
					end
				else
					Character.Humanoid:TakeDamage(self.Damage)
					KnockBack(Character, Velocity)
					Character:SetAttribute("Ragdolled", true)
					task.delay(2.5, function()
						Character:SetAttribute("Ragdolled", false)
					end)

					-- Setting atributes
					local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
					Character:SetAttribute("Distance", Distance)
					Character:SetAttribute("Killer", Player.Name)

					-- Resetting killfeed
					task.delay(10, function() -- Reset
						Character:SetAttribute("Distance", "")
						Character:SetAttribute("Killer", "")
					end)
				end
			end
			SpawnVFXEvent:FireAllClients(Weapon, Result.Position, Player)
		end)
		-- Instances
	else
		local PlayerCharacter = workspace:FindFirstChild(Player.Name)
		if PlayerCharacter:GetAttribute("Cooldown") == true then return end
		if PlayerCharacter:GetAttribute("Ragdolled") == true then return end
		if PlayerCharacter:GetAttribute("Loading") == true then return end
		PlayerCharacter:SetAttribute("CooldownTime", self.CooldownTime)
		PlayerCharacter:SetAttribute("Cooldown", true)
		PlayerCharacter:FindFirstChild(self.Name).Handle.Transparency = 1

		-- Removing cooldown
		task.delay(PlayerCharacter:GetAttribute("CooldownTime"), function()
			PlayerCharacter:SetAttribute("Cooldown", false)
		end)
		-- Gui
		task.spawn(function()
			GuiHandler:Cooldown(Player)
		end)

		-- Casting
		-- local Direction = (MousePosition - PlayerCharacter.RightHand.Position).Unit -- Gets the vector between firepoint & mousepos and normalizes it
		castParams.FilterDescendantsInstances = {Weapon, Weapon:FindFirstChild("VFX"), Player.Character, workspace:WaitForChild("Map"):FindFirstChild("DeadZone"), workspace:WaitForChild("Map"):WaitForChild("SpawnPoints")}
		-- Bullet temp
		local CosmeticWeapon = Weapon:Clone()
		CosmeticWeapon.Name = Player.Name
		CastBehavior.CosmeticBulletTemplate = CosmeticWeapon
		CastBehavior.RaycastParams = castParams

		task.delay(0.3, function()
			if PlayerCharacter:FindFirstChild(self.Name) then
				PlayerCharacter:FindFirstChild(self.Name).Handle.Transparency = 0
			else
				Player.Backpack:FindFirstChild(self.Name).Handle.Transparency = 0
			end
		end)


		local CharactersOnDebounce = {}

		local function onLengthChanged(Cast, LastPoint, Direction, Length, Velocity, Bullet)
			if Bullet then
				local BulletLength = Bullet.Size.Z/2
				local Offset = CFrame.new(0, 0, -(Length - BulletLength))
				Bullet.CFrame = CFrame.lookAt(LastPoint, LastPoint + Direction):ToWorldSpace(Offset)
			else
				Cast:Terminate()
			end
		end

		local ActiveCast = self.Caster:Fire(PlayerCharacter.RightHand.Position, (MousePosition - PlayerCharacter.RightHand.Position).Unit, self.Speed, CastBehavior)
		self.Caster.LengthChanged:Connect(onLengthChanged)

		local Connection: RBXScriptConnection
		Connection = self.Caster.RayHit:Connect(function(Cast, Result, Velocity, Bullet)
			Connection:Disconnect()
			Cast:Pause()
			Bullet:Destroy()
			-- Spawn VFX
			local Hit = Result.Instance

			local Character = Hit:FindFirstAncestorWhichIsA("Model")
			if Character:GetAttribute("Loading") == true then return end
			if Character and Character:FindFirstChild("Humanoid") and not table.find(CharactersOnDebounce, Character.Name) then
				-- Add & Reset debounce
				table.insert(CharactersOnDebounce, Character.Name)
				if Character:FindFirstChild("Ultimate") then
					if Character:FindFirstChild("Ultimate"):GetAttribute("Ultimate") ~= "Apple" then
						Character.Humanoid:TakeDamage(self.Damage)
						KnockBack(Character, Velocity)
						Character:SetAttribute("Ragdolled", true)
						task.delay(2.5, function()
							Character:SetAttribute("Ragdolled", false)
						end)

						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						Character:SetAttribute("Distance", Distance)
						Character:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							Character:SetAttribute("Distance", "")
							Character:SetAttribute("Killer", "")
						end)

					else
						-- Setting atributes
						local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
						Character:SetAttribute("Distance", Distance)
						Character:SetAttribute("Killer", Player.Name)

						-- Resetting killfeed
						task.delay(10, function() -- Reset
							Character:SetAttribute("Distance", "")
							Character:SetAttribute("Killer", "")
						end)

						-- Dealing DMG
						if Character:GetAttribute("UltimateHealth") > 0 then
							Character:SetAttribute("UltimateHealth", Character:GetAttribute("UltimateHealth") - 25)
							-- Update ULT Health
							game:GetService("TweenService"):Create(Character:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthInner, TweenInfo.new(0.25), {Size = UDim2.new(Character:GetAttribute("UltimateHealth")/250, 0, 1, 0)}):Play()
							Character:FindFirstChild("Ultimate").ForceAttach.BillboardGui.HealthBackground.HealthStatus.Text = Character:GetAttribute("UltimateHealth").. "HP"	
						end

						coroutine.wrap(function()
							if Character:GetAttribute("UltimateHealth") <= 0 then
								-- Delays
								local Destination = Character:WaitForChild("Ultimate").Position
								Character:WaitForChild("Ultimate"):Destroy()
								Character.Humanoid.JumpHeight = 7.2

								local Explosion = Instance.new("Explosion", Character)

								Explosion.BlastRadius = 10
								Explosion.ExplosionType = Enum.ExplosionType.Craters
								Explosion.Position = Destination
								Explosion.Parent = Character

								-- Reset
								local Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
								local CooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
								local Cooldown = string.match(CooldownText.Text, "%(.*%)")
								Cooldown = string.split(Cooldown, "(")
								Cooldown[2] = string.split(Cooldown[2], ")")
								Cooldown = Cooldown[2][1]
								task.delay(Cooldown, function()
									PlayerCharacter:SetAttribute("UltimateCooldown", false)
									Character:SetAttribute("UltimateHealth", 250)
								end)
							end
						end)()
					end
				else
					Character.Humanoid:TakeDamage(self.Damage)
					KnockBack(Character, Velocity)
					Character:SetAttribute("Ragdolled", true)
					task.delay(2.5, function()
						Character:SetAttribute("Ragdolled", false)
					end)

					-- Setting atributes
					local Distance = (PlayerCharacter.HumanoidRootPart.Position - Character.HumanoidRootPart.Position).Magnitude
					Character:SetAttribute("Distance", Distance)
					Character:SetAttribute("Killer", Player.Name)

					-- Resetting killfeed
					task.delay(10, function() -- Reset
						Character:SetAttribute("Distance", "")
						Character:SetAttribute("Killer", "")
					end)
				end
			end
			SpawnVFXEvent:FireAllClients(Weapon, Result.Position, Player)
			-- Connection:Disconnect()
		end)
		task.delay(0.5, function()
			if bulletsFolder:FindFirstChild(Player.Name) then
				bulletsFolder:FindFirstChild(Player.Name):Destroy()
			end
		end)
	end
end

return Weapons