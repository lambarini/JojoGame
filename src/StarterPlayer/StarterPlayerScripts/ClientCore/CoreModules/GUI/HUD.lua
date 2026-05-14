--!strict

-- // SERVICES \\ --
local TweenService = game:GetService("TweenService")
local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Data = Shared.Data
local Modules = Shared.Modules

-- // MODULES \\ --
local TroveModule = require(Modules.Trove)
local Common = require(Modules.Common)
local DataTemplate = require(Data.DataTemplate)
local ReplicaClient = require(ReplicatedStorage.ReplicaClient)

-- // VARIABLES \\ --
local Trove = TroveModule.new()

local States = script.Parent.Parent.Parent.States
local GuiName = script.Name

local Player = PlayersService.LocalPlayer
local PlayerGui = Player.PlayerGui
local MainGui = PlayerGui:WaitForChild("HUD")

local HotColor = Color3.fromRGB(255, 43, 0)
local NeutralColor = Color3.fromRGB(158, 158, 158)
local ColdColor = Color3.fromRGB(0, 200, 255)

local PlayerReplica : ReplicaClient.Replica<typeof(DataTemplate)> = nil
local StatsReplica : ReplicaClient.Replica<{Stats : {[string] : {Min : number, Max : number}}, Values : {[string] : number}}> = nil

-- // FUNCTIONS \\ --

function UnRender()
	Trove:Destroy()
	
	MainGui.Enabled = false
end

function Render()
	MainGui.Enabled = true
end

function UpdateUI()
	local ActiveComponent = States:GetAttribute("ActiveComponent")
	
	if ActiveComponent == GuiName then
		Render()
	else
		UnRender()
	end
end

function UpdateTemperature()
	local Color : Color3 = nil
	local Temperature = StatsReplica.Data.Values.Temperature
	
	if not Temperature then
		return
	end
	
	if Temperature <= 50 then
		Color = ColdColor:Lerp(NeutralColor, Temperature / 50)
	else
		Color = NeutralColor:Lerp(HotColor, (Temperature - 50) / 50)
	end
	
	MainGui.Temperature.BackgroundColor3 = Color
end

function UpdateStats()
	UpdateTemperature()
	
	for Stat, Value in StatsReplica.Data.Values do
		if not StatsReplica.Data.Stats[Stat] then
			continue
		end
		
		local StatFrame = MainGui.Stats:FindFirstChild(Stat)
		
		if not StatFrame then
			continue
		end
		
		local Progress = Value / StatsReplica.Data.Stats[Stat].Max
		StatFrame.UIGradient.Offset = Vector2.new(Progress - 0.5, 0)
	end
end

function Init()
	task.spawn(UpdateUI)
	States:GetAttributeChangedSignal("ActiveComponent"):Connect(UpdateUI)
	
	UpdateStats()
	StatsReplica:OnChange(UpdateStats)
end

-- // MAIN \\ --
ReplicaClient.OnNew("PlayerData", function(PlayerData)
	PlayerReplica = PlayerData
	
	if PlayerReplica and StatsReplica then
		Init()
	end
end)

ReplicaClient.OnNew("StatsToken", function(PlayerStats)
	StatsReplica = PlayerStats

	if PlayerReplica and StatsReplica then
		Init()
	end
end)

return nil