--!strict
local CharacterHandler = {}

-- // SERVICES \\ --
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES \\ --
local Trove = require(ReplicatedStorage.Shared.Modules.Trove)

-- // VARIABLES \\ --
local Player = PlayersService.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
local CharacterTrove = Trove.new()

-- // FUNCTIONS \\ --
local function IsStunned() : boolean
	return os.clock() < (Character:GetAttribute("Stun") or 0)
end

local function IsRestricted() : boolean
	local Attributes = Character:GetAttributes()
	return Attributes.UsingMove == true or Attributes.Endlag == true or IsStunned()
end

local function UpdateMovement()
	local Restricted = IsRestricted()

	local WalkSpeed = if Restricted then 3 else 16
	local JumpPower = if Restricted then 0 else 50

	if Humanoid.WalkSpeed ~= WalkSpeed then
		Humanoid.WalkSpeed = WalkSpeed
	end

	if Humanoid.JumpPower ~= JumpPower then
		Humanoid.JumpPower = JumpPower
	end
end

local function CharacterAdded(Char : Model)
	CharacterTrove:Clean()

	Character = Char
	Humanoid = Char:WaitForChild("Humanoid") :: Humanoid

	CharacterTrove:Connect(RunService.Heartbeat, UpdateMovement)
end

function CharacterHandler.init()
	if Player.Character then
		CharacterAdded(Player.Character)
	end

	Player.CharacterAdded:Connect(CharacterAdded)
end

return CharacterHandler
