--!strict
local Projectile = {}
Projectile.__index = Projectile

-- // SERVICES \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Modules = Shared.Modules
local FXFolder = Shared.FX

-- // MODULES \\ --
local SignalModule = require(Modules.Signal)
local TroveModule = require(Modules.Trove)

export type ProjectileProps = {
	Origin : Vector3,
	Direction : Vector3,
	Speed : number,
	Range : number,
	Id : number,
	Name : string,
	
	Projectile : BasePart,
	StartTime : number,
	
	_trove : TroveModule.Trove,
	_destroyed : SignalModule.Signal<>,
}

export type Projectile = typeof(setmetatable({} :: ProjectileProps, Projectile))

function Projectile.new(Info : {Name : string, Origin : Vector3, Direction : Vector3, Speed : number, Range : number, Id : number}) : Projectile
	local self = setmetatable({} :: ProjectileProps, Projectile) :: Projectile
	
	self._trove = TroveModule.new()
	self._destroyed = self._trove:Add(SignalModule.new())
	
	self.Origin = Info.Origin
	self.Direction = Info.Direction
	self.Speed = Info.Speed
	self.Range = Info.Range
	self.Id = Info.Id
	self.Name = Info.Name
	
	self.StartTime = os.clock()
	
	return self
end

function Projectile.CreateProjectile(self : Projectile)
	if self.Name == "TuskNail" then
		self.Projectile = self._trove:Clone(FXFolder.Projectiles.Nail)
	else
		self.Projectile = self._trove:Add(Instance.new("Part"))
		self.Projectile.Size = Vector3.new(0.3, 0.3, 1.6)
	end
	
	self.Projectile.Material = Enum.Material.Neon
	self.Projectile.Color = Color3.fromRGB(225, 225, 225)
	self.Projectile.Anchored = true
	self.Projectile.CanCollide = false
	self.Projectile.CanQuery = false
	self.Projectile.CanTouch = false
	self.Projectile.CFrame = CFrame.lookAt(self.Origin, self.Origin + self.Direction)
	self.Projectile.Parent = workspace.Projectiles
end

function Projectile.Start(self : Projectile)
	self:CreateProjectile()
	
	RunService:BindToRenderStep(`UpdateProjectile`..self.Id, Enum.RenderPriority.Camera.Value, function()
		local Distance = (os.clock() - self.StartTime) * self.Speed
		
		if Distance >= self.Range then
			self:Stop()
			return
		end
	
		self.Projectile.Position = self.Origin + Distance * self.Direction
	end)
end

function Projectile.Stop(self : Projectile)
	for _, Particle in self.Projectile:GetDescendants() do
		if Particle:IsA("ParticleEmitter") then
			Particle.Enabled = false
		end
	end
	
	RunService:UnbindFromRenderStep(`UpdateProjectile`..self.Id)
	
	task.delay(1, function()
		self:Cleanup()
	end)
end

function Projectile.Cleanup(self : Projectile)
	self._destroyed:Fire()
	
	self._trove:Destroy()
end

return Projectile