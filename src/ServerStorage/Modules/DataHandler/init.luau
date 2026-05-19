--!strict
local DataHandler = {}

-- // SERVICES \\ --
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Data = Shared.Data

-- // MODULES \\ --
local Settings = require(script.Settings)
local ProfileStore = require(script.ProfileStore)
local DataTemplate = require(Data.DataTemplate)
local PlayerObject = require(script.PlayerObject)

-- // VARIABLES \\ --
local DataStoreName = "PlayerDataDev2"

local PlayerStore = nil
local Profiles : {[Player] : PlayerObject.PlayerObject} = {}

if RunService:IsStudio() and Settings.DevelopmentBranch then
	PlayerStore = ProfileStore.New(DataStoreName, DataTemplate).Mock
else
	PlayerStore = ProfileStore.New(DataStoreName, DataTemplate)
end

export type PlayerObject = PlayerObject.PlayerObject

-- // MAIN \\ --

function DataHandler:Load(Player : Player) : (PlayerObject.PlayerObject?)
	if not PlayerStore then
		return nil
	end
	
	local Profile = PlayerStore:StartSessionAsync(`Player_{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= PlayersService
		end,
	})

	if Profile == nil then
		Player:Kick("Profile load fail - Please rejoin")
		return nil
	end

	Profile:AddUserId(Player.UserId)
	Profile:Reconcile()
	Profile.OnSessionEnd:Connect(function()
		Profiles[Player]:Destroy()
		Profiles[Player] = nil

		Player:Kick("Profile session end - Please rejoin")
	end)

	if Player.Parent ~= PlayersService then
		Profile:EndSession()
		
		return nil
	end
	
	local playerObject = PlayerObject.new(Player, Profile)
	Profiles[Player] = playerObject
	
	Player:SetAttribute("Loaded", true)
	
	return playerObject
end

function DataHandler:SavePlayerData(Player : Player)
	local Profile = Profiles[Player]

	if not Profile then
		return
	end

	Profile:Destroy()
	Profiles[Player] = nil
end

function DataHandler:GetPlayerObject(Player : Player) : PlayerObject.PlayerObject
	return Profiles[Player]
end

return DataHandler