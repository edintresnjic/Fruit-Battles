game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
	script.Parent.Orientation += Vector3.new(0,3,0)
	task.delay(3, function()
		game:GetService("TweenService"):Create(script.Parent, TweenInfo.new(0.1), {Transparency = 1}):Play()
		task.wait(0.1)
		script.Parent:Destroy()
	end)
end)