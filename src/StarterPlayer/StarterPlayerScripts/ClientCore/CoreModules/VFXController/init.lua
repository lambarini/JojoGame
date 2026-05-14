--!strict
-- // SERVICES \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)

local EffectModules : {[string] : (...any) -> ()} = {}

Packets.VFXEvent.OnClientEvent:Connect(function(EffectName : string, Data)
	pcall(EffectModules[EffectName], Data)
end)

return {
	init = function()
		for _, Singleton in script:GetChildren() do
			if not Singleton:IsA("ModuleScript") then
				continue
			end

			EffectModules[Singleton.Name] = require(Singleton) :: any
		end
	end,
}