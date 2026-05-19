--!native
--!strict

-- // SERVICES \\ --
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Modules = Shared.Modules
local FXFolder = Shared.FX

-- // MODULES \\ --
local SignalModule = require(Modules.Signal)
local TroveModule = require(Modules.Trove)
local Common = require(Modules.Common)

local Signal : SignalModule.Signal<...any> = nil

return {
	init = function(Event : SignalModule.Signal<>)
		Signal = Event
	end,
	
	run = function(Data : {Character : Common.HumanoidR15, Damage : number})
		Signal:Fire("SoundController", "Hit", Data.Character.HumanoidRootPart)
	end
}