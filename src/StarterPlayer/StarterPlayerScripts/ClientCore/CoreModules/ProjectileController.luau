--!strict
-- // Copyright 2025 lambarini, All rights reserved. \\ --

-- // SERVICES \\ --
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local FXFolder = Shared.FX

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)

-- // VARIABLES \\ --
local ActiveProjectiles : {[number] : () -> ()} = {}

-- // FUNCTIONS \\ --

local function Destroy(Id : number)
	local Cleanup = ActiveProjectiles[Id]

	if not Cleanup then
		return
	end

	ActiveProjectiles[Id] = nil
	Cleanup()
end

local function SpawnProjectile(Id : number, Origin : Vector3, Direction : Vector3, Speed : number, Range : number, Visual : string)
	local Part
	
	if Visual == "TuskNail" then
		Part = FXFolder.Projectiles.Nail:Clone()
		Part.CFrame = CFrame.lookAt(Origin, Origin + Direction)
		Part.Parent = workspace.Projectiles
	else
		Part = Instance.new("Part")
		Part.Size = Vector3.new(0.3, 0.3, 1.6)
		Part.Material = Enum.Material.Neon
		Part.Color = Color3.fromRGB(225, 225, 225)
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.CFrame = CFrame.lookAt(Origin, Origin + Direction)
		Part.Parent = workspace.Projectiles
	end

	local Traveled = 0
	RunService:BindToRenderStep("UpdateProjectile_"..Id, Enum.RenderPriority.Camera.Value, function(DeltaTime)
		local Step = Speed * DeltaTime
		Traveled += Step

		if Traveled >= Range then
			Destroy(Id)
			return
		end

		Part.Position += Direction * Step
	end)

	ActiveProjectiles[Id] = function()
		Part:Destroy()
	end
end

return {
	init = function()
		Packets.SpawnProjectile.OnClientEvent:Connect(SpawnProjectile)
		Packets.DestroyProjectile.OnClientEvent:Connect(Destroy)
	end,
}
