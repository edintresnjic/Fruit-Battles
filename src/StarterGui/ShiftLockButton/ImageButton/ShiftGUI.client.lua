local MobileCameraFramework = {}
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local button = script.Parent

--Visiblity
uis = game:GetService("UserInputService")
ismobile = uis.TouchEnabled
button.Visible = ismobile

local states = {
	OFF = "rbxasset://textures/ui/mouseLock_off@2x.png",
	ON = "rbxasset://textures/ui/mouseLock_on@2x.png"
}
local MAX_LENGTH = 900000
local active = false
local ENABLED_OFFSET = CFrame.new(1.7, 0, 0)
local DISABLED_OFFSET = CFrame.new(-1.7, 0, 0)
local function UpdateImage(STATE)
	button.Image = states[STATE]
end
local function UpdateAutoRotate(BOOL)
	humanoid.AutoRotate = BOOL
end
local function GetUpdatedCameraCFrame(ROOT, CAMERA)
	return CFrame.new(root.Position, Vector3.new(CAMERA.CFrame.LookVector.X * MAX_LENGTH, root.Position.Y, CAMERA.CFrame.LookVector.Z * MAX_LENGTH))
end
local function EnableShiftlock()
	UpdateAutoRotate(false)
	UpdateImage("ON")
	root.CFrame = GetUpdatedCameraCFrame(root, camera)
	camera.CFrame = camera.CFrame * ENABLED_OFFSET
end
local function DisableShiftlock()
	UpdateAutoRotate(true)
	UpdateImage("OFF")
	camera.CFrame = camera.CFrame * DISABLED_OFFSET
	pcall(function()
		active:Disconnect()
		active = nil
	end)
end
UpdateImage("OFF")
active = false
function ShiftLock()
	if not active then
		active = runservice.RenderStepped:Connect(function()
			EnableShiftlock()
		end)
	else
		DisableShiftlock()
	end
end
local ShiftLockButton = CAS:BindAction("ShiftLOCK", ShiftLock, false, "On")
CAS:SetPosition("ShiftLOCK", UDim2.new(0.8, 0, 0.8, 0))
button.MouseButton1Click:Connect(function()
	if character:GetAttribute("Loading") == true then return end
	if not active then
		active = runservice.RenderStepped:Connect(function()
			EnableShiftlock()
		end)
	else
		DisableShiftlock()
	end
end)
return MobileCameraFramework
