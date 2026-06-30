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

local function HandleSound(Sound : string, Target : BasePart?)
	local Arg1, Arg2 = unpack(string.split(Sound, "/"))
	
	local Sound : Sound

	if Arg2 == nil then
		Sound = SFX[Arg1]
	else
		Sound = SFX[Arg1][Arg2]
	end
	
	if not Target then
		Sound:Play()
	else
		local Clone = Sound:Clone()
		Clone.Parent = Target
		
		Clone:Play()
		
		Clone.Ended:Connect(function()
			Clone:Destroy()
		end)
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