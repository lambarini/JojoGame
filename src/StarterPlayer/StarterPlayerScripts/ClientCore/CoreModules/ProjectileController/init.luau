--!strict
-- // Copyright 2026 lambarini, All rights reserved. \\ --

-- // SERVICES \\ --
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local FXFolder = Shared.FX

-- // MODULES \\ --
local Packets = require(ReplicatedStorage.Packets)
local ProjectileObject = require(script.Projectile)

-- // VARIABLES \\ --
local ActiveProjectiles : {[number] : ProjectileObject.Projectile} = {}

-- // FUNCTIONS \\ --

local function Destroy(Id : number)
	local Projectile = ActiveProjectiles[Id]

	if not Projectile then
		return
	end

	Projectile:Stop()
end

local function SpawnProjectile(Id : number, Origin : Vector3, Direction : Vector3, Speed : number, Range : number, Visual : string)
	local Projectile = ProjectileObject.new({
		Direction = Direction,
		Id = Id,
		Origin = Origin,
		Speed = Speed,
		Range = Range,
		Name = Visual,
	})
	
	Projectile:Start()
	
	ActiveProjectiles[Id] = Projectile
	
	Projectile._destroyed:Connect(function()
		ActiveProjectiles[Id] = nil
	end)
end

return {
	init = function()
		Packets.SpawnProjectile.OnClientEvent:Connect(SpawnProjectile)
		Packets.DestroyProjectile.OnClientEvent:Connect(Destroy)
	end,
}
