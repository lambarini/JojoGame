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
	
	if Attributes.Running then
		WalkSpeed = 23
	end
	
	return WalkSpeed
end

function CharacterHandler.init()
	Character.AttributeChanged:Connect(function()
		Humanoid.WalkSpeed = GetCharacterSpeed()
	end)
end

return CharacterHandler