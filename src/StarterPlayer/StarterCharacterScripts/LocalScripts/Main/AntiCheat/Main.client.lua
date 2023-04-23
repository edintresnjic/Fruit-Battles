local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Hum: Humanoid = Character:FindFirstChild("Humanoid")

Hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	if Hum.WalkSpeed > 17 then
		
		Player:Kick("Hacking isnt fun 😡")
	end
end)

Hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
	if Hum.JumpHeight > 7.3 and workspace:GetAttribute("TournamentChoice") ~= "One Shot" then
		Player:Kick("Hacking isnt fun 😡")
	end
end)