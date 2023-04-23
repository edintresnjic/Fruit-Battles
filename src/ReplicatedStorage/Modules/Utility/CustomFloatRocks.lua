local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local RayCastParams = RaycastParams.new() do
	RayCastParams.FilterType = Enum.RaycastFilterType.Whitelist
	RayCastParams.FilterDescendantsInstances = {workspace} --{workspace.World.Map}
end

local FloatRocks = {}

function FloatRocks.Create(Params)
	local CenterCFrame = Params.CenterCFrame

	if not CenterCFrame then 
		return false 
	end

	setmetatable(Params, {
		__index = {
			InnerRadius = 10, 
			OuterRadius = 15,
			Lifetime = 7, 
			Amount = 12, 
			Size = 0.5, 
			GroundAllowance = -20,
			Velocity = {Min = 20, Max = 40}
		}
	})
	
	local RockArray = {}
	
	for i = 1, 360, 360/Params.Amount do
		local X = math.random(Params.InnerRadius, Params.OuterRadius) * math.cos(math.rad(i))
		local Z = math.random(Params.InnerRadius, Params.OuterRadius) * math.sin(math.rad(i))

		local RayCastResult = workspace:Raycast(
			(CenterCFrame * CFrame.new(X, 10, Z)).Position, 
			Vector3.new(0, Params.GroundAllowance, 0),	
			RayCastParams
		)
		
		if RayCastResult then	
			local ActualSize = (typeof(Params.Size) == "table" and math.random(Params.Size.Min * 10, Params.Size.Max * 10)/10 or Params.Size)

			local Rock = Instance.new("Part") do
				Rock.CFrame = CFrame.new(RayCastResult.Position) * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)))
				Rock.TopSurface = Enum.SurfaceType.Smooth
				Rock.BottomSurface = Enum.SurfaceType.Smooth
				Rock.Material = RayCastResult.Material
				Rock.Size = Vector3.new(0, 0, 0)
				Rock.Color = RayCastResult.Instance.Color
				Rock.CollisionGroup = "Visuals"
				Rock.CanQuery = false
				Rock.CanTouch = false
			end
			
			Rock.Parent = workspace --workspace.World.Visuals

			TweenService:Create(Rock, TweenInfo.new(0.25), {Size = Vector3.new(1, 1, 1) * ActualSize}):Play()

			RockArray[#RockArray + 1] = Rock
		end
	end
	
	local RockFunctionality = {
		["Rise"] = function(Information)
			for i,v in ipairs(RockArray) do
				if v:FindFirstChildOfClass("BodyVelocity") then
					v:FindFirstChildOfClass("BodyVelocity"):Destroy()
				end
				
				local BodyVelocity = Instance.new("BodyVelocity") do
					BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 4e4
					BodyVelocity.Velocity = Vector3.new(0, 1, 0) * math.random(Information.Velocity.Min, Information.Velocity.Max)
					BodyVelocity.Parent = v
					
					Debris:AddItem(BodyVelocity, Information.FloatTime or .25)
				end
			end
		end,
		
		["Repulse"] = function(Information)
			for i,v in ipairs(RockArray) do
				if v:FindFirstChildOfClass("BodyVelocity") then
					v:FindFirstChildOfClass("BodyVelocity"):Destroy()
				end
				
				v.CFrame = CFrame.lookAt(v.Position, CenterCFrame.Position)
				
				local BodyVelocity = Instance.new("BodyVelocity") do
					BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 4e4
					BodyVelocity.Velocity = (-v.CFrame.LookVector) * 75 --Vector3.new(0, 1, 0) * math.random(Information.Velocity.Min, Information.Velocity.Max)
					BodyVelocity.Parent = v
					
					Debris:AddItem(BodyVelocity, Information.VelocityLifetime or .25)
				end
			end
		end,
		
		["Cleanup"] = function()
			for i,v in ipairs(RockArray) do
				TweenService:Create(v, TweenInfo.new(0.5), {Size = Vector3.new(0, 0, 0)}):Play()

				Debris:AddItem(v, 0.5)

				task.wait(0.1)
			end
		end,
	}
	
	return RockFunctionality
end

return FloatRocks