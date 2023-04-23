local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Settings = UserSettings()
local GameSettings = Settings.GameSettings
local ShiftLockController = {}
while not Players.LocalPlayer do
	wait()
end
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui, ShiftLockIcon, InputCn
local IsShiftLockMode = true
local IsShiftLocked = true
local IsActionBound = false
local IsInFirstPerson = false
ShiftLockController.OnShiftLockToggled = Instance.new("BindableEvent")
local function isShiftLockMode()
	return LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove and GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove and LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable
end
if not UserInputService.TouchEnabled then
	IsShiftLockMode = isShiftLockMode()
end
local function onShiftLockToggled()
	IsShiftLocked = not IsShiftLocked
	ShiftLockController.OnShiftLockToggled:Fire()
end

function ShiftLockController:IsShiftLocked()
	return IsShiftLockMode and IsShiftLocked
end
function ShiftLockController:SetIsInFirstPerson(isInFirstPerson)
	IsInFirstPerson = isInFirstPerson
end
local function mouseLockSwitchFunc(actionName, inputState, inputObject)
	if IsShiftLockMode then
		onShiftLockToggled()
	end
end
local function disableShiftLock()
	if ScreenGui then
		ScreenGui.Parent = nil
	end
	IsShiftLockMode = false
	Mouse.Icon = ""
	if InputCn then
		InputCn:disconnect()
		InputCn = nil
	end
	IsActionBound = false
	ShiftLockController.OnShiftLockToggled:Fire()
end
local onShiftInputBegan = function(inputObject, isProcessed)
	if isProcessed then
		return
	end
	if inputObject.UserInputType ~= Enum.UserInputType.Keyboard or inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift then
	end
end
local function enableShiftLock()
	IsShiftLockMode = isShiftLockMode()
	if IsShiftLockMode then
		if ScreenGui then
			ScreenGui.Parent = PlayerGui
		end
		if IsShiftLocked then
			ShiftLockController.OnShiftLockToggled:Fire()
		end
		if not IsActionBound then
			InputCn = UserInputService.InputBegan:connect(onShiftInputBegan)
			IsActionBound = true
		end
	end
end
GameSettings.Changed:connect(function(property)
	if property == "ControlMode" then
		if GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
			enableShiftLock()
		else
			disableShiftLock()
		end
	elseif property == "ComputerMovementMode" then
		if GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove then
			disableShiftLock()
		else
			enableShiftLock()
		end
	end
end)
LocalPlayer.Changed:connect(function(property)
	if property == "DevEnableMouseLock" then
		if LocalPlayer.DevEnableMouseLock then
			enableShiftLock()
		else
			disableShiftLock()
		end
	elseif property == "DevComputerMovementMode" then
		if LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.ClickToMove or LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable then
			disableShiftLock()
		else
			enableShiftLock()
		end
	end
end)
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
	if isShiftLockMode() then
		InputCn = UserInputService.InputBegan:connect(onShiftInputBegan)
		IsActionBound = true
	end
end
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
	enableShiftLock()
end

return ShiftLockController
