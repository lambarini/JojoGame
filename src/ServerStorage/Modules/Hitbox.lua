--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules
local Modules = ServerStorage.Modules

local CoreUtils = require(Modules.CoreUtils)
local Trove = require(SharedModules.Trove)

local Hitbox = {}
Hitbox.__index = Hitbox

local Params1 = OverlapParams.new()
Params1.FilterType = Enum.RaycastFilterType.Include
Params1.FilterDescendantsInstances = {workspace.Living}

local Cnew = CFrame.new
local InstanceNew = Instance.new

local ForceField = Enum.Material.ForceField

export type self = {
	Enabled : boolean,
	Size : Vector3,
	Offset : Vector3,
	Part : Part,
	Character : Model,
	OverlapParams : OverlapParams,
	Hitbox : Part,
	HitboxCheck : RBXScriptConnection,
	Lingering : boolean,
}

local Alive = workspace.Living
local Debris = workspace.Debris

function Hitbox.new(Parameters : {
	Size : Vector3, 
	Offset : Vector3, 
	TargetPart : BasePart, 
	Character : Model,
	OverlapParams : OverlapParams?,
	HitOnce : boolean?,
	Callback : (Enemy : CoreUtils.HumanoidR15) -> nil,
	Lingering : boolean?,
})
	local self = setmetatable({}, Hitbox)

	self.Enabled = true
	self.Size = Parameters.Size
	self.Offset = Parameters.Offset
	self.Part = Parameters.TargetPart
	self.Callback = Parameters.Callback
	self.Character = Parameters.Character
	self.HitOnce = Parameters.HitOnce
	self.Lingering = Parameters.Lingering or false
	self.OverlapParams = Parameters.OverlapParams or Params1
	self.Debug = _G.DEBUG_MODE

	local Hitbox : Part
	if self.Debug then
		self.Hitbox = Instance.new("Part")
		Hitbox = self.Hitbox
		Hitbox.Anchored = true
		Hitbox.CanCollide = false
		Hitbox.EnableFluidForces = false
		Hitbox.CastShadow = false
		Hitbox.CanTouch = false
		Hitbox.CanQuery = false
		Hitbox.Massless = true
		Hitbox.Color = Color3.new(1, 0, 0)
		Hitbox.Material = ForceField
		Hitbox.Transparency = 0.5
		Hitbox.Name = "Hitbox"

		if typeof(self.Size) == "Vector3" then
			Hitbox.Size = self.Size
		end

		Hitbox.Parent = Debris
	end

	local Size : Vector3 = self.Size
	local Offset : CFrame = CFrame.new(self.Offset)
	local Part : BasePart = self.Part
	local Debug : boolean = self.Debug
	local Character : Model = self.Character
	local Callback = self.Callback
	local Parameters = self.OverlapParams

	local Blacklist : {[Model] : boolean} = {}

	local Position = Part.CFrame * Offset
	
	if Debug then
		Hitbox.CFrame = Position
	end
	
	local function Check()
		if self.Lingering then
			Position = Part.CFrame * Offset

			if Debug then
				Hitbox.CFrame = Position
			end
		end

		for _, v in workspace:GetPartBoundsInBox(Position, Size, Parameters) do
			local Enemy : Model = v:FindFirstAncestorWhichIsA("Model")

			if Blacklist[Enemy] or Enemy == Character then continue end

			if self.HitOnce then
				Blacklist[Enemy] = true
			end

			Callback(Enemy :: CoreUtils.HumanoidR15)
		end
	end

	Check()

	self.HitboxCheck = RunService.Heartbeat:Connect(Check)

	return self
end

function Hitbox:Destroy()
	if self.Debug then
		self.Hitbox:Destroy()
	end

	if self.HitboxCheck then
		self.HitboxCheck:Disconnect()
	end
end

return Hitbox