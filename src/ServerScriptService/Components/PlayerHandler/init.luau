--!strict
--!optimize 2
-- // Copyright 2025 lambarini, All rights reserved. \\ --

local PlayerHandler = {}

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")

-- // FOLDERS \\ --
local Commands = TextChatService.Commands
local Modules = ServerStorage.Modules

-- // MODULES \\ --
local Packets = ReplicatedStorage.Packets
local DataHandler = require(Modules.DataHandler)
local StatsHandler = require(Modules.StatsHandler)
local StandHandler = require(Modules.StandHandler)
local CharacterHandler = require(script.CharacterHandler)

-- // FUNCTIONS \\ --

local function PlayerAdded(Player : Player) : ()
	local PlayerObject = DataHandler:Load(Player)
	
	if not PlayerObject then
		return
	end
	
	Player.CharacterAdded:Connect(CharacterHandler.CharacterAdded :: any)
	task.spawn(StandHandler.Setup, Player)
	
	local PlayerStats = StatsHandler.new(Player)
end

local function PlayerRemoving(Player : Player) : ()
	DataHandler:SavePlayerData(Player)
	
	local StatObject = StatsHandler.GetPlayerObject(Player)
	
	if StatObject then
		StatObject:Destroy()
	end
end

function PlayerHandler.init()
	for _, Player in PlayersService:GetPlayers() do
		task.spawn(PlayerAdded, Player)
	end
	
	PlayersService.PlayerAdded:Connect(PlayerAdded)
	PlayersService.PlayerRemoving:Connect(PlayerRemoving)
	
	Commands.SetGlobal.Triggered:Connect(function(TextSource, Text)
		local Player = PlayersService:GetPlayerByUserId(TextSource.UserId)
		
		if not Player then
			return
		end
	
		local StatName : string, Value : string = select(2, table.unpack(string.split(Text, " ")))
		
		StatsHandler.SetStatValue(Player, StatName, tonumber(Value) :: number)
	end)
end

return PlayerHandler