--|| Services & Storages ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Data = TeleportService:GetLocalPlayerTeleportData()
local RunService = game:GetService("RunService")
--|| Instances ||--
local Events = ReplicatedStorage:WaitForChild("Events")

--|| Events ||--
local DataEvent : RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("DataEvent")
----------------------------------------------------------------------
if not RunService:IsStudio() then
	if Data ~= nil then
		DataEvent:FireServer(Data.Winner)
	else
		print("No Data")
	end
end