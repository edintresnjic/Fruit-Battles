game:GetService("TweenService"):Create(script.Parent, TweenInfo.new(0.15), {Size = Vector3.new(42.483, 4.361, 43.681)}):Play()

task.wait(3)
game:GetService("TweenService"):Create(script.Parent, TweenInfo.new(0.1), {Size = Vector3.new(0, 0, 0)}):Play()
task.wait(0.1)
script.Parent:Destroy()