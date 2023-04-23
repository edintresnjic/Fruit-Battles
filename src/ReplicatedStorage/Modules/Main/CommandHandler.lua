local Command = {}

function Command:SpawnDummy(Player)
	local Character = Player.Character
	local Dummy = game:GetService("ServerStorage"):WaitForChild("Dummy"):Clone()
	Dummy.Parent = workspace
	Dummy:PivotTo(Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -7))
	game:GetService("Debris"):AddItem(Dummy, 60)
end

return Command
