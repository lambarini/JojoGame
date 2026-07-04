--!strict

-- // SERVICES \\ --
local TweenService = game:GetService("TweenService")
local PlayersService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Data = Shared.Data
local Modules = Shared.Modules

-- // MODULES \\ --
local TroveModule = require(Modules.Trove)
local Common = require(Modules.Common)
local DataTemplate = require(Data.DataTemplate)
local Packets = require(ReplicatedStorage.Packets)
local ReplicaClient = require(ReplicatedStorage.ReplicaClient)

-- // VARIABLES \\ --
local Trove = TroveModule.new()

local States = script.Parent.Parent.Parent.States
local GuiName = script.Name

local Player = PlayersService.LocalPlayer
local PlayerGui = Player.PlayerGui
local MainGui = PlayerGui:WaitForChild("HUD")
local MainFrame = MainGui.Main

local Mouse = Player:GetMouse()

local PlayerReplica : ReplicaClient.Replica<typeof(DataTemplate)> = nil

-- // FUNCTIONS \\ --

local function SetupButton(Button : GuiButton, Keycode : EnumItem)
	Button.TouchLongPress:Connect(function()
		Packets.MoveEvent:Fire(Keycode.Name, false, Mouse.Hit.Position)
	end)

	Button.TouchTap:Connect(function()
		Packets.MoveEvent:Fire(Keycode.Name, true, Mouse.Hit.Position)
	end)
end

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

function Init()
	task.spawn(UpdateUI)
	States:GetAttributeChangedSignal("ActiveComponent"):Connect(UpdateUI)
	
	MainFrame.Hotbar.Visible = UserInputService.TouchEnabled
	
	SetupButton(MainFrame.Hotbar.One, Enum.UserInputType.MouseButton1)
	SetupButton(MainFrame.Hotbar.Two, Enum.KeyCode.Q)
	SetupButton(MainFrame.Hotbar.Three, Enum.KeyCode.E)
end

-- // MAIN \\ --
ReplicaClient.OnNew("PlayerData", function(PlayerData)
	PlayerReplica = PlayerData
	
	if PlayerReplica then
		Init()
	end
end)

return nil