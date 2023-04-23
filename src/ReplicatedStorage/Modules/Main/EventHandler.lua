local Events = {
	Events = {
		"Zero Gravity",
		"One Shot",
		"Double Money",
		"Knockback Mayhem",
		"All Shotgun",
		-- "Tiny Royale",
	}
}

local EventLength = 75
local EventOnGoing = false
--|| Instances
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventsFolder = ReplicatedStorage:WaitForChild("Events")
local EventHandlerEvent : RemoteEvent = EventsFolder:WaitForChild("EventHandler")
local UpdateEventGui : RemoteEvent = EventsFolder:WaitForChild("UpdateEventText")

local function HandleClock()
	workspace:FindFirstChild("Clock").Value = EventLength
	for i = EventLength, 0, -1 do
		workspace:FindFirstChild("Clock").Value = i
		task.wait(1)
	end
end

local function HandleGui(ChosenEvent, Status, JoinedPlr)
	if Status == "Begin" then
		UpdateEventGui:FireAllClients("AN EVENT HAS STARTED! THE EVENT IS: ".. string.upper(ChosenEvent).. "!")
	elseif Status == "End" then
		UpdateEventGui:FireAllClients("EVENT IS OVER! A NEW EVENT STARTS IN 60 SECONDS")
	elseif Status == "Join" then
		UpdateEventGui:FireClient(JoinedPlr, "AN EVENT IS ONGOING! THE EVENT IS: ".. string.upper(ChosenEvent).. "!")
	end
end

local function SetAttribute(Event)
	-- Gravity event
	if Event == "Zero Gravity" then
		workspace.Gravity = 10
	end
	-- Setting callback check
	workspace:SetAttribute("Event", Event)
	
	-- Resetting
	task.delay(EventLength, function()
		workspace:SetAttribute("Event", "")
		workspace.Gravity = 196.2
	end)
end

function Events:Init()
	-- Getting chosen event
	EventOnGoing = true
	local ChosenEventIndex = math.random(1, #Events.Events)
	local ChosenEvent = Events.Events[ChosenEventIndex]
	if game:GetService("RunService"):IsStudio() then
		ChosenEvent = ""
	end
	-- Setting Event
	SetAttribute(ChosenEvent)
	HandleGui(ChosenEvent, "Begin")
	-- Checking if someone joins
	game.Players.PlayerAdded:Connect(function(Player)
		HandleGui(ChosenEvent, "Join", Player)
	end)
	-- Starting neccessary functions
	local Co = coroutine.create(HandleClock)
	coroutine.resume(Co)
	-- Resetting
	task.delay(EventLength, function()
		HandleGui(UpdateEventGui, "End")
		EventOnGoing = false
	end)
end

return Events
