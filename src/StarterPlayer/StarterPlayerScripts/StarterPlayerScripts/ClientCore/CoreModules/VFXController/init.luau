--!strict
-- // SERVICES \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)

local EffectModules : {[string] : {init : (any) -> (), run : (...any) -> ()}} = {}

Packets.VFXEvent.OnClientEvent:Connect(function(EffectName : string, Data)
	xpcall(EffectModules[EffectName].run, function(Error) 
		warn(`[VFXController]:[{EffectName}], {Error}`)
	end, Data)
end)

return {
	init = function(Signal)
		for _, Singleton in script:GetChildren() do
			if not Singleton:IsA("ModuleScript") then
				continue
			end

			EffectModules[Singleton.Name] = require(Singleton) :: any
			EffectModules[Singleton.Name].init(Signal)
		end
	end,
}