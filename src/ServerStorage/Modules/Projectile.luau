--!strict
--!optimize 2
-- // Copyright 2025 lambarini, All rights reserved. \\ --

local Projectile = {}
Projectile.__index = Projectile

-- // SERVICES \\ --
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Living = workspace.Living
local Debris = workspace.Debris

-- // MODULES \\ --
local CoreUtils = require(script.Parent.CoreUtils)
local Packets = require(ReplicatedStorage.Packets)

-- // VARIABLES \\ --
local IdCounter = 0

-- // TYPES \\ --
type ProjectileProps = {
	Id : number,
	Destroyed : boolean,
	Direction : Vector3,
	Speed : number,
	Range : number,
	Character : Model,
	Pierce : boolean,
	Callback : (Enemy : CoreUtils.HumanoidR15, Position : Vector3) -> (),
	OnImpact : ((Position : Vector3) -> ())?,
	Position : Vector3,
	Traveled : number,
	RaycastParams : RaycastParams,
	Blacklist : {[Model] : boolean},
	Connection : RBXScriptConnection,
	DebugPart : BasePart?,
}

export type Projectile = typeof(setmetatable({} :: ProjectileProps, Projectile))

-- // FUNCTIONS \\ --

function Projectile.new(Parameters : {
	Origin : Vector3,
	Direction : Vector3,
	Speed : number,
	Range : number,
	Character : Model,
	Pierce : boolean?,
	Visual : string?,
	Callback : (Enemy : CoreUtils.HumanoidR15, Position : Vector3) -> (),
	OnImpact : ((Position : Vector3) -> ())?,
}) : Projectile
	local self = setmetatable({} :: ProjectileProps, Projectile)

	self.Id = IdCounter
	self.Destroyed = false
	IdCounter = (IdCounter + 1) % 65536

	self.Direction = Parameters.Direction.Unit
	self.Speed = Parameters.Speed
	self.Range = Parameters.Range
	self.Character = Parameters.Character
	self.Pierce = Parameters.Pierce or false
	self.Callback = Parameters.Callback
	self.OnImpact = Parameters.OnImpact
	self.Position = Parameters.Origin
	self.Traveled = 0
	self.Blacklist = {}

	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParameters.FilterDescendantsInstances = {self.Character, Debris}
	self.RaycastParams = RaycastParameters

	if _G.DEBUG_MODE then
		local Part = Instance.new("Part")
		Part.Shape = Enum.PartType.Ball
		Part.Size = Vector3.one * 0.5
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.Material = Enum.Material.Neon
		Part.Color = Color3.new(1, 1, 0)
		Part.Position = self.Position
		Part.Parent = Debris
		self.DebugPart = Part
	end

	Packets.SpawnProjectile:Fire(self.Id, Parameters.Origin, self.Direction, self.Speed, self.Range, Parameters.Visual or "Nail")

	self.Connection = RunService.Heartbeat:Connect(function(DeltaTime : number)
		self:Step(DeltaTime)
	end)

	return self
end

function Projectile.Step(self : Projectile, DeltaTime : number)
	local Distance = self.Speed * DeltaTime
	local Result = workspace:Raycast(self.Position, self.Direction * Distance, self.RaycastParams)

	self.Position += self.Direction * Distance
	self.Traveled += Distance

	if self.DebugPart then
		self.DebugPart.Position = self.Position
	end

	if Result then
		local Model = Result.Instance:FindFirstAncestorWhichIsA("Model")

		if Model and Model:IsDescendantOf(Living) then
			local Humanoid = Model:FindFirstChildOfClass("Humanoid")

			if Humanoid and Model ~= self.Character and not self.Blacklist[Model] then
				self.Blacklist[Model] = true
				self.Callback(Model :: CoreUtils.HumanoidR15, Result.Position)

				if not self.Pierce then
					return self:Destroy()
				end
			end
		else
			if self.OnImpact then
				self.OnImpact(Result.Position)
			end

			return self:Destroy()
		end
	end

	if self.Traveled >= self.Range then
		if self.OnImpact then
			self.OnImpact(self.Position)
		end

		self:Destroy()
	end
end

function Projectile.Destroy(self : Projectile)
	if self.Destroyed then
		return
	end

	self.Destroyed = true

	if self.Connection then
		self.Connection:Disconnect()
	end

	if self.DebugPart then
		self.DebugPart:Destroy()
	end

	Packets.DestroyProjectile:Fire(self.Id)
end

return Projectile
