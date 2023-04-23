local Right = script.Parent:WaitForChild("Status"):WaitForChild("TextLabel")
local Status = script.Parent:WaitForChild("Status")
local UpdateEventText = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("UpdateEventText")
local TweenService = game:GetService("TweenService")

UpdateEventText.OnClientEvent:Connect(function(Text)
	Right.Text = Text
	TweenService:Create(Status, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.new(0.8, 0, 0.698, 0)}):Play()
	TweenService:Create(script.Parent["Event Status"], TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.new(0.128, 0, 0.98, 0)}):Play()
	
	task.delay(2, function()
		TweenService:Create(Status, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.new(1.2, 0, 0.698, 0)}):Play()
	end)
	
	workspace:FindFirstChild("Clock"):GetPropertyChangedSignal("Value"):Connect(function()
		if workspace:FindFirstChild("Clock").Value == 0 then
			TweenService:Create(script.Parent["Event Status"], TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.new(0.8, 0, 1.1, 0)}):Play()
		else
			script.Parent["Event Status"].Text = string.format("EVENT [%s] ENDS IN: ".. tostring(workspace:FindFirstChild("Clock").Value).. "S..", workspace:GetAttribute("Event"))
		end
	end)
end)