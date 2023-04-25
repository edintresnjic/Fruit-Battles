local Gui = {}
local TweenService = game:GetService("TweenService")
local MessageService = game:GetService("MessagingService")
local SoundService = game:GetService("SoundService")

local function RoundNumber(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function Gui:Cooldown(Player: Player)
	local Character = Player.Character
	if Character:GetAttribute("Cooldown") == true then
		local Clock = Character:GetAttribute("CooldownTime")
		local TimeSinceStart = tick()
		local CooldownTimeText = Player.PlayerGui.Cooldown.CooldownTime
		CooldownTimeText.Text =  tostring(Clock).. "s"
		CooldownTimeText.Visible = true

		repeat
			Clock = RoundNumber(Clock - 0.1, 1)
			CooldownTimeText.Text =  tostring(Clock).. "s"
			task.wait(0.1)
		until tick() - TimeSinceStart >= Character:GetAttribute("CooldownTime") or Character:GetAttribute("Cooldown") == false

		CooldownTimeText.Visible = false
	else
		local CooldownTimeText = script.Parent:WaitForChild("CooldownTime")
		CooldownTimeText.Visible = false
	end
end


function Gui:UltimateCooldown(Player: Player)
	print("Called")
	local Character = Player.Character
	local UltimateStatus = Player.PlayerGui.Cooldown["Ultimate Status"]
	local UltimateCooldownText = Player.PlayerGui.Cooldown.Attacks.Ultimate
	
	coroutine.wrap(function()
		local TimeSinceStart = tick()
		local Clock = 30
		UltimateStatus.Text = "⚠ ULTIMATE ENDS IN 30 SECONDS ⚠"
		TweenService:Create(UltimateStatus, TweenInfo.new(0.2), {Position = UDim2.new(0.251, 0, 0.016, 0)}):Play()
		
		repeat
			UltimateStatus.Text = "⚠ ULTIMATE ENDS IN "..  Clock.. " SECONDS ⚠"
			Clock -= 1
			task.wait(1)
		until tick() - TimeSinceStart >= 30 or Character:FindFirstChild("Ultimate") == nil
		
		TweenService:Create(UltimateStatus, TweenInfo.new(0.2), {Position = UDim2.new(0.251, 0, -0.8, 0)}):Play()
	end)()
	
	coroutine.wrap(function()
		local Clock = 90
		local TimeSinceStart = tick()
		UltimateCooldownText.Text =  "Q - Ultimate (".. tostring(Clock).. ")"
		UltimateCooldownText.Visible = true

		repeat
			Clock -= 1
			UltimateCooldownText.Text =  "Q - Ultimate (".. tostring(Clock).. ")"
			task.wait(1)
		until tick() - TimeSinceStart >= 90

		UltimateCooldownText.Text = "Q - Ultimate"
	end)()
end

function Gui:UpdateMoney(Player: Player)
	local MoneyText = Player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("MoneyText")
	local MoneyValue = Player:WaitForChild("leaderstats"):WaitForChild("Money")
	MoneyText.Text = "$".. MoneyValue.Value
end

function Gui:OneVOne(Player: Player)
	local Character = workspace:FindFirstChild(Player.Name)
	
	if Character:GetAttribute("InTournament") == true then return end
	if Character:GetAttribute("FoundGame") == true then return end
	
	local Frames = Player.PlayerGui.Main["1v1"]:GetChildren()
	local MainFrame = Player.PlayerGui.Main["1v1"].OneOnOneFrame
	local OneOnOneFrameYesBTN = Player.PlayerGui.Main["1v1"].OneOnOneFrame.Yes
	local OneOnOneFrameNoBTN = Player.PlayerGui.Main["1v1"].OneOnOneFrame.No
	local TextStatus = Player.PlayerGui.Main["1v1"].OneOnOneFrame.TextLabel

	
	if MainFrame.Position ~= UDim2.new(0.5, 0, 0.5, 0) and not workspace:FindFirstChild(Player.Name):GetAttribute("FoundGame") then
		TweenService:Create(MainFrame, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0.55, 0)}):Play()
	else
		TweenService:Create(MainFrame, TweenInfo.new(0.5), {Position = UDim2.new(1.5, 0, 0.5, 0)}):Play()
	end
	
	OneOnOneFrameNoBTN.TextLabel.Text = "NO"
	OneOnOneFrameYesBTN.TextLabel.Text = "YES"
	
	-- Checking clicks
	OneOnOneFrameYesBTN.MouseButton1Click:Connect(function()
		if workspace:FindFirstChild(Player.Name):GetAttribute("FoundGame") == true then return end
		if Character:GetAttribute("FoundGame") == true then return end
		-- Normal
		TextStatus.Text = "You are now on a queue for a 1v1. You will join shortly. Current people in queue: ".. tostring(workspace:GetAttribute("PlayersInQueue"))
		-- Update checker
		workspace:GetAttributeChangedSignal("PlayersInQueue"):Connect(function()
			TextStatus.Text = "You are now on a queue for a 1v1. You will join shortly. Current people in queue: ".. tostring(workspace:GetAttribute("PlayersInQueue"))
		end)
		-- Start queing
		MessageService:PublishAsync("QueueAdd", Player.Name)
		OneOnOneFrameNoBTN.TextLabel.Text = "CANCEL"
		OneOnOneFrameYesBTN.TextLabel.Text = "QUEUEING.."
	end)
	
	OneOnOneFrameNoBTN.MouseButton1Click:Connect(function()
		if workspace:FindFirstChild(Player.Name):GetAttribute("FoundGame") == true then return end
		if Character:GetAttribute("FoundGame") == true then return end
		-- Sending info
		MessageService:PublishAsync("QueueRemove", Player.Name)
		-- Resetting texts
		TextStatus.Text = "WOULD YOU LIKE TO QUEUE FOR A 1V1?"
		OneOnOneFrameNoBTN.TextLabel.Text = "NO"
		OneOnOneFrameYesBTN.TextLabel.Text = "YES"
		
		-- Making visible
		TweenService:Create(MainFrame, TweenInfo.new(0.5), {Position = UDim2.new(1.5, 0, 0.5, 0)}):Play()
	end)
end

function Gui:Status(Player: Player, Status: string)
	if Status == "1v1" then
		Player.CharacterAppearanceLoaded:Wait()
		task.wait(1)
		print("Won 1v1, applying text gui show")
		local StatusText = Player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("StatusText")
		StatusText.Text = "Your balance increased by 150$ for winning your recent 1V1 👏"
		local StatusTween = TweenService:Create(StatusText, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.new(0.308, 0, 0.061, 0)}):Play()
		task.wait(4)
		local StatusTween = TweenService:Create(StatusText, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {Position = UDim2.new(0.308, 0, -0.2, 0)}):Play()
	end
end

function Gui:Shop(Player: Player)
	local ShopFrames = Player.PlayerGui.Main.Shop:GetChildren()
	for _, Frame in pairs(ShopFrames) do
		if Frame:IsA("Frame") then
			Frame.Visible = not Frame.Visible
		end
	end
	print("Everything visisble")
end

return Gui
