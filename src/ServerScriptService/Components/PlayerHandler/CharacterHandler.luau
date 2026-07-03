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

-- // MODULES \\ --
local CoreUtils = require(Modules.CoreUtils)
local Packets = require(ReplicatedStorage.Packets)

function CharacterHandler.CharacterAdded(Character : CoreUtils.HumanoidR15)
	local Player = PlayersService:GetPlayerFromCharacter(Character)
	
	if not Player then
		return
	end
	
	if not Player:HasAppearanceLoaded() then
		Player.CharacterAppearanceLoaded:Wait()
	end
	
	for _, Part in Character:GetChildren() do
		if not Part:IsA("BasePart") then
			continue
		end

		Part.CollisionGroup = "Players"
	end
	
	Character.Parent = workspace.Living
end

return CharacterHandler