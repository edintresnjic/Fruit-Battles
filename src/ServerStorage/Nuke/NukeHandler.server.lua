local TweenService = game:GetService("TweenService")
local RepStorage = game:GetService("ReplicatedStorage")
local Events = RepStorage:WaitForChild("Events")
local CameraHandler = Events:WaitForChild("CameraHandler")

local Tween = TweenService:Create(script.Parent.PrimaryPart, TweenInfo.new(10, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = Vector3.new(-235.207, 42.553, -76.251)})
Tween:Play()
Tween.Completed:Connect(function()
	script.Parent:Destroy()
	-- Shockwave
end)