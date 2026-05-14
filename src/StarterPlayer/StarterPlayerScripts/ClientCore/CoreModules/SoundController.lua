--!strict
local SoundController = {}

-- // SERVICES \\ --
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)

-- // FOLDERS \\ --
local SFX = SoundService.SFX

function SoundController.init()
	Packets.PlaySound.OnClientEvent:Connect(function(Sound : string)
		local Arg1, Arg2 = unpack(string.split(Sound, "/"))
		
		if Arg2 == nil then
			SFX[Arg1]:Play()
		else
			SFX[Arg1][Arg2]:Play()
		end
	end)
end

return SoundController