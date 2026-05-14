--!strict

local InputController = {}

-- // SERVICES \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)

-- // VARIABLES \\ --
local Player = PlayersService.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

local Whitelist = "QWERTYUIOPASDFGHJKLZXCVBNM"

function HandleInput(Input : InputObject, GameProcessed : boolean)
	if GameProcessed then
		return
	end
	
	if Humanoid.Health <= 0 then
		return
	end
	
	if not string.find(Whitelist, Input.KeyCode.Name) then
		return
	end
	
	Packets.MoveEvent:Fire(Input.KeyCode.Name, Input.UserInputState == Enum.UserInputState.Begin)
end

function InputController.init()
	UserInputService.InputBegan:Connect(HandleInput)
	UserInputService.InputEnded:Connect(HandleInput)
end

return InputController