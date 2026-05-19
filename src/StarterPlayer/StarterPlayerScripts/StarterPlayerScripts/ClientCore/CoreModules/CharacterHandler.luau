--!strict
local CharacterHandler = {}

-- // SERVICES \\ --
local PlayersService = game:GetService("Players")

-- // VARIABLES \\ --
local Player = PlayersService.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

function GetCharacterSpeed() : number
	local WalkSpeed = 16
	local Attributes = Character:GetAttributes()
	
	if Attributes.UsingMove or Attributes.Stunned or Attributes.Endlag then
		WalkSpeed = 3
	end
	
	return WalkSpeed
end

local function GetJumpPower() : number
	local JumpPower = 50
	local Attributes = Character:GetAttributes()

	if Attributes.UsingMove then
		JumpPower = 0
	end
	
	if Attributes.Stunned then
		JumpPower = 0
	end
	
	if Attributes.Endlag then
		JumpPower = 0
	end

	return JumpPower
end

local function CharacterAdded(Char : Model)
	Character = Char
	Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	
	Character.AttributeChanged:Connect(function()
		Humanoid.WalkSpeed = GetCharacterSpeed()
		Humanoid.JumpPower = GetJumpPower()
	end)
end

function CharacterHandler.init()
	if Player.Character then
		CharacterAdded(Player.Character)
	end

	Player.CharacterAdded:Connect(CharacterAdded)
end

return CharacterHandler