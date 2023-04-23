--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| Instances ||--
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utility = Modules:WaitForChild("Utility")
local Events = ReplicatedStorage:WaitForChild("Events")
local Camera = workspace.CurrentCamera

--|| Modules ||--
local CameraShaker = require(Utility:WaitForChild("CameraShaker"))

--|| Events ||--
local CameraHandlerEvent = Events:WaitForChild("CameraHandler")

--|| Main Code ||--
---------------------------------------------------------------------------

local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCFrame)
	Camera.CFrame = Camera.CFrame * ShakeCFrame
end)

CamShake:Start()

CameraHandlerEvent.OnClientEvent:Connect(function()
	CamShake:Shake(CameraShaker.Presets.Explosion)
end)