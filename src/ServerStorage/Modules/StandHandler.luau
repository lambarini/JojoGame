--!strict
--!optimize 2
-- // Copyright 2025 lambarini, All rights reserved. \\ --

local StandHandler = {}

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")

-- // FOLDERS \\ --
local Modules = ServerStorage.Modules

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)
local DataHandler = require(Modules.DataHandler)
local AbilityManager = require(ServerStorage.Abilities.AbilityManager)

-- // VARIABLES \\ --
local AbilityClasses: {[string]: AbilityManager.AbilityClass} = {}
local PlayerAbilities: {[Player]: AbilityManager.AbilityInstance} = {}

-- // FUNCTIONS \\ --

for _, Ability in ServerStorage.Abilities:GetChildren() do
	if not Ability:IsA("ModuleScript") or Ability.Name == "AbilityManager" then
		continue
	end
	
	AbilityClasses[Ability.Name] = require(Ability) :: AbilityManager.AbilityClass
end

local function HandleMoveEvent(Player : Player, Keybind : string, State : boolean, Hit : Vector3)
	local PlayerObject = DataHandler:GetPlayerObject(Player)

	if not PlayerObject then
		return
	end

	local Keybinds = PlayerObject:Get({"Keybinds"})
	local MoveName = Keybinds[Keybind]
	local PlayerAbility = PlayerAbilities[Player].Moves

	local MoveFunction = PlayerAbility[MoveName]
	
	if not MoveFunction then
		return
	end
	
	if PlayerObject:IsOnCooldown(MoveName) then
		return
	end
	
	MoveFunction[State]({
		MousePos = Hit
	})
end

Packets.MoveEvent.OnServerEvent:Connect(HandleMoveEvent)

local function CharacterAdded(PlayerObject : DataHandler.PlayerObject, Character : Model)
	local StandName : string = PlayerObject:Get({"Stand"})
	local Ability = AbilityClasses[StandName].new(PlayerObject.Player)

	PlayerAbilities[PlayerObject.Player] = Ability
	
	Ability.AbilityManager.Destroying:Once(function()
		PlayerAbilities[PlayerObject.Player] = nil
	end)
end

function StandHandler.Setup(Player : Player)
	local PlayerObject = DataHandler:GetPlayerObject(Player)
	
	if not PlayerObject then
		return
	end
	
	if Player.Character then
		CharacterAdded(PlayerObject, Player.Character)
	end
	
	Player.CharacterAdded:Connect(function(Character)
		if not Player:HasAppearanceLoaded() then
			Player.CharacterAppearanceLoaded:Wait()
		end
		
		task.wait()
		
		CharacterAdded(PlayerObject, Character)
	end)
end

return StandHandler