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
local AbilityClasses : {[string] : AbilityManager.AbilityManager} = {}
local PlayerAbilities : {[Player] : AbilityManager.AbilityManager} = {}

-- // FUNCTIONS \\ --

for _, Ability in ServerStorage.Abilities:GetChildren() do
	if not Ability:IsA("ModuleScript") or Ability.Name == "AbilityManager" then
		continue
	end
	
	AbilityClasses[Ability.Name] = require(Ability) :: AbilityManager.AbilityManager
end

local function HandleMoveEvent(Player : Player, Keybind : string, State : boolean)
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
	
	MoveFunction[State]()
end

Packets.MoveEvent.OnServerEvent:Connect(HandleMoveEvent)

function StandHandler.Setup(Player : Player)
	local PlayerObject = DataHandler:GetPlayerObject(Player)
	
	if not PlayerObject then
		return
	end
	
	local StandName : string = PlayerObject:Get({"Stand"})
	local Ability = AbilityClasses[StandName].new(Player)
	
	PlayerAbilities[Player] = Ability
end

return StandHandler