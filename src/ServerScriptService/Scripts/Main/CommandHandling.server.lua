local CommandHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Main"):WaitForChild("CommandHandler"))

game.Players.PlayerAdded:Connect(function(Player)
	Player.Chatted:Connect(function(Chat)
		if Player.Name == "EdinHFK12" then
			if Chat == "?spawn regular_dummy" then
				CommandHandler:SpawnDummy(Player)
			end
		end
	end)
end)