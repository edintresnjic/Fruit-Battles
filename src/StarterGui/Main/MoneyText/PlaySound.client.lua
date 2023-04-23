local SoundService = game:GetService("SoundService")

script.Parent:GetPropertyChangedSignal("Text"):Connect(function()
	SoundService:PlayLocalSound(script.Parent:WaitForChild("PurchaseSFX"))
end)