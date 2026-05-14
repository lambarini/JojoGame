--!strict
--!optimize 2
-- // Copyright 2025 lambarini, All rights reserved. \\ --

-- // SERVICES \\ --
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local CoreModules = script.CoreModules

-- // MODULES \\ --
local Replica = require(ReplicatedStorage.ReplicaClient)

-- // VARUABLES \\ --
local Player = PlayersService.LocalPlayer

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
	
	local Core = require(Module) :: {init : () -> ()}
	task.spawn(Core.init)
end

Replica.RequestData()