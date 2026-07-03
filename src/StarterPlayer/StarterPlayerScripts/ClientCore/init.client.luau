--!strict
--!optimize 2
-- // Copyright 2026 lambarini, All rights reserved. \\ --

-- // SERVICES \\ --
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local CoreModules = script.CoreModules

-- // MODULES \\ --
local SignalModule = require(ReplicatedStorage.Shared.Modules.Signal)
local Replica = require(ReplicatedStorage.ReplicaClient)

-- // VARUABLES \\ --
local Player = PlayersService.LocalPlayer
local Signal = SignalModule.new()

-- // MAIN \\ --

if not Player:GetAttribute("Loaded") then
	repeat
		Player:GetAttributeChangedSignal("Loaded"):Wait()
	until Player:GetAttribute("Loaded")
end

for _, Module in CoreModules:GetChildren() do
	if not Module:IsA("ModuleScript") then
		continue
	end
	
	local Core = require(Module) :: {init : (Signal : SignalModule.Signal<...any>) -> ()}
	task.spawn(Core.init, Signal)
end

Replica.RequestData()