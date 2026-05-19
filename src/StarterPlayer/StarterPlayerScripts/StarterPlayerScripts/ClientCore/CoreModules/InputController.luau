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

local Whitelist = {
	MouseButton1 = true,
	MouseButton2 = true,
	Q = true,
	E = true,
	R = true,
	T = true,
	Y = true,
	U = true,
	I = true,
	O = true,
	F = true,
	G = true,
	H = true,
	J = true,
	K = true,
	L = true,
	Z = true,
	X = true,
	C = true,
	V = true,
	B = true,
	N = true,
}

function HandleInput(Input : InputObject, GameProcessed : boolean)
	if GameProcessed then
		return
	end
	
	if Humanoid.Health <= 0 then
		return
	end
	
	local UserInputState = Input.UserInputState
	if UserInputState.Value ~= 0 and UserInputState.Value ~= 2 then
		return
	end

	local InputEnum : Enum.UserInputType | Enum.KeyCode = Input.UserInputType
	if InputEnum == Enum.UserInputType.Keyboard then
		InputEnum = Input.KeyCode
	end

	local MoveName = InputEnum.Name
	
	if not Whitelist[MoveName] then
		return
	end
	
	Packets.MoveEvent:Fire(MoveName, Input.UserInputState == Enum.UserInputState.Begin)
end

local function CharacterAdded(Character : Model)
	Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
end

function InputController.init()
	UserInputService.InputBegan:Connect(HandleInput)
	UserInputService.InputEnded:Connect(HandleInput)
	
	if Player.Character then
		CharacterAdded(Player.Character)
	end
	
	Player.CharacterAdded:Connect(CharacterAdded)
end

return InputController