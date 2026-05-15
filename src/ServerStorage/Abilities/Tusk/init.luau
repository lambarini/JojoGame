--!strict
--!optimize 2
-- // Copyright 2025 lambarini, All rights reserved. \\ --

local Ability = {}
Ability.__index = Ability

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules
local Modules = ServerStorage.Modules
local StandsFolder = ReplicatedStorage.Stands
local Animations = script.Animations

-- // MODULES \\ --
local HitboxModule = require(Modules.Hitbox)
local TroveModule = require(SharedModules.Trove)
local CoreUtils = require(Modules.CoreUtils)
local SignalModule = require(SharedModules.Signal)
local Packets = require(ReplicatedStorage.Packets)
local DataHandler = require(Modules.DataHandler)
local AbilityManager = require(ServerStorage.Abilities.AbilityManager)

-- // VARIABLES \\ --

local StandOutPos = Vector3.new(-3.5, 1.5, 1.5)

type Ability = typeof(setmetatable({} :: {
	AbilityManager : AbilityManager.AbilityManager,
	Moves : {[string] : {[boolean] : () -> ()}},
	StandAttach : Attachment,
	Stand : typeof(StandsFolder.Tusk),
	Summoned : boolean,
	CanSummon : boolean,
}, Ability))

function Ability.new(Player : Player) : Ability
	local self = setmetatable({}, table.clone(Ability)) :: Ability
	
	self.AbilityManager = AbilityManager.new(Player)
	
	self.Moves = {
		Summon = self:Summon(),
		Barrage = self:Barrage()
	}
	
	self.CanSummon = true
	self.Summoned = false

	self.AbilityManager.Character:SetAttribute("Summoned", false)
	
	return self
end

function Ability:Summon()
	local function SetupSummon()
		self.StandAttach = self.AbilityManager._trove:Add(Instance.new("Attachment"))
		self.StandAttach.Name = "StandAttach"
		self.StandAttach.Parent = self.AbilityManager.Character.HumanoidRootPart

		self.Stand = self.AbilityManager._trove:Clone(StandsFolder.Tusk)
		self.Stand.Name = "Stand"
		self.Stand.Parent = self.AbilityManager.Character

		self.Stand.AnimationController.Animator:LoadAnimation(Animations.StandIdle):Play()

		local AlignPosition = Instance.new("AlignPosition")
		AlignPosition.Attachment1 = self.StandAttach
		AlignPosition.Attachment0 = self.Stand.HumanoidRootPart.RootAttachment
		AlignPosition.MaxForce = math.huge
		AlignPosition.MaxVelocity = math.huge
		AlignPosition.MaxAxesForce = Vector3.one * math.huge
		AlignPosition.Responsiveness = 65
		AlignPosition.Parent = self.Stand.HumanoidRootPart

		local AlignOrientation = Instance.new("AlignOrientation")
		AlignOrientation.Attachment1 = self.StandAttach
		AlignOrientation.Attachment0 = self.Stand.HumanoidRootPart.RootAttachment
		AlignOrientation.MaxTorque = math.huge
		AlignOrientation.MaxAngularVelocity = math.huge
		AlignOrientation.Responsiveness = 65
		AlignOrientation.Parent = self.Stand.HumanoidRootPart

		for _, Part in self.Stand:GetChildren() do
			if not Part:IsA("BasePart") then
				continue
			end

			Part:SetNetworkOwner(self.AbilityManager.Player)
		end
	end
	
	if self.AbilityManager.Character then
		SetupSummon()
	end
	
	self.AbilityManager.CharacterAdded:Connect(SetupSummon)
	
	return {
		[true] = function()
			if not self.CanSummon then
				return
			end
			
			if self.Summoned then
				self.StandAttach.Position = Vector3.zero
				self.Summoned = false
				self.CanSummon = false
				
				self.AbilityManager.Character:SetAttribute("Summoned", false)

				task.delay(1.5, function()
					self.CanSummon = true
				end)

				--plrInfo.UserIdle:Stop(.5)
			else
				--if Attributes.Stunned then return false end
				
				self.StandAttach.Position = Vector3.new(-3.5, 1.5, 1.5)
				self.Summoned = true
				self.CanSummon = false
				
				self.AbilityManager.Character:SetAttribute("Summoned", true)
				
				task.delay(1.5, function()
					self.CanSummon = true
				end)

				--plrInfo.UserIdle:Play(.5)
			end 

		end,
		[false] = function()
			
		end,
	}
end

function Ability:Barrage()
	local BarrageCancelEvent = self.AbilityManager._trove:Add(SignalModule.new())

	return {
		[true] = function()
			local Humanoid = self.AbilityManager.Character.Humanoid
			local Attributes = self.AbilityManager.Character:GetAttributes()

			if Attributes.UsingMove
				or Attributes.Blocking
				or not Attributes.Summoned
				or Humanoid.Health <= 0 
				or Attributes.Ragdolled
				or Attributes.Barraging then return end

			local BarrageActive = true

			Humanoid.WalkSpeed = 3
			Humanoid.JumpPower = 0

			CoreUtils.Common:SetAttributes(self.AbilityManager.Character, {
				Barraging = true,
				UsingMove = true,
			})

			Packets.VFXEvent:Fire("BarrageEffect", {self.AbilityManager.Character, true})

			self.StandAttach.Position = Vector3.new(0, 0, -2)
			
			local blacklist = {}

			local Hitbox = HitboxModule.new({
				Size = Vector3.new(4, 4, 8),
				Offset = Vector3.new(0, 0, -4),
				TargetPart = self.AbilityManager.Character.HumanoidRootPart,
				Lingering = true,
				Character = self.AbilityManager.Character,
				Callback = function(Enemy : CoreUtils.HumanoidR15)
					if blacklist[Enemy] then return end

					blacklist[Enemy] = true

					task.delay(.15, function()
						blacklist[Enemy] = nil
					end)
					
					Enemy.Humanoid.Health -= 1.2
				end,
			})

			--local Sound = Util:PlaySound(HumanoidRootPart, Sounds.BarrageWoosh, false)
			--local BarrageAnim : AnimationTrack = plrInfo.StandAnimator:LoadAnimation(SAnims.Barrage)
			--BarrageAnim.Priority = Enum.AnimationPriority.Action
			--BarrageAnim:Play()

			local Connection, Task

			local function Cancel()
				if BarrageActive then
					BarrageActive = false
					--Bindables.AddCooldown:Fire(Player, "Barrage", 7)

					Hitbox:Destroy()

					self.StandAttach.Position = StandOutPos

					if Connection and Connection.Connected then
						Connection:Disconnect()
					end

					CoreUtils.Common:SetAttributes(self.AbilityManager.Character, {
						Barraging = false,
						UsingMove = false,
					})
					
					Humanoid.WalkSpeed = 16
					Humanoid.JumpPower = 50
					
					Packets.VFXEvent:Fire("BarrageEffect", {self.AbilityManager.Character, false})

					--Sound:Destroy()
					--BarrageAnim:Stop()
					return
				end
			end

			BarrageCancelEvent:Once(Cancel)
			Connection = self.AbilityManager.Character:GetAttributeChangedSignal("Ragdolled"):Once(function()
				if BarrageActive then
					BarrageCancelEvent:Fire()
				end
			end)

			task.delay(8, function()
				if BarrageActive then
					BarrageCancelEvent:Fire()
				end
			end)
			
			return
		end,
		[false] = function()
			local Attributes = self.AbilityManager.Character:GetAttributes()

			if Attributes.UsingMove and Attributes.Barraging then
				BarrageCancelEvent:Fire()
			end
		end,
	}
end

return Ability