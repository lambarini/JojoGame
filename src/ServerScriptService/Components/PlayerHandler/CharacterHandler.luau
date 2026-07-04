--!strict
--!optimize 2
-- // Copyright 2026 lambarini, All rights reserved. \\ --

local CharacterHandler = {}

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")

-- // FOLDERS \\ --
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules

-- // MODULES \\ --
local CoreUtils = require(Modules.CoreUtils)
local Ragdoll = require(SharedModules.Ragdoll)
local Packets = require(ReplicatedStorage.Packets)

function CharacterHandler.CharacterAdded(Character : CoreUtils.HumanoidR15)
	local Player = PlayersService:GetPlayerFromCharacter(Character)
	
	if Player then
		if not Player:HasAppearanceLoaded() then
			Player.CharacterAppearanceLoaded:Wait()
		end
	end
	
	for _, Part in Character:GetChildren() do
		if not Part:IsA("BasePart") then
			continue
		end

		Part.CollisionGroup = "Players"
		
		if not Player then
			Part:SetNetworkOwner(nil)
		end
	end
	
	Character:GetAttributeChangedSignal("Ragdoll"):Connect(function()
		local Ragdolled = Character:GetAttribute("Ragdoll") == true
		Ragdoll:ragdoll(Ragdolled, Character)
		
		if not Player then
			Character.Humanoid:ChangeState(Enum.HumanoidStateType[Ragdolled and "Physics" or "GettingUp"])
		end
	end)
	
	Character.Humanoid.Died:Connect(function()
		Ragdoll:ragdoll(true, Character)
	end)
	
	Ragdoll:rig(Character)
	
	Character.Parent = workspace.Living
end

return CharacterHandler