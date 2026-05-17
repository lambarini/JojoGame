--!strict
local SoundController = {}

-- // SERVICES \\ --
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)
local SignalModule = require(ReplicatedStorage.Shared.Modules.Signal)

-- // FOLDERS \\ --
local SFX = SoundService.SFX

local function HandleSound(Sound : string)
	local Arg1, Arg2 = unpack(string.split(Sound, "/"))

	if Arg2 == nil then
		SFX[Arg1]:Play()
	else
		SFX[Arg1][Arg2]:Play()
	end
end

function SoundController.init(Signal : SignalModule.Signal<...any>)
	Packets.PlaySound.OnClientEvent:Connect(HandleSound)
	
	Signal:Connect(function(Component : string, ...)
		if Component == "SoundController" then
			HandleSound(...)
		end
	end)
end

return SoundController