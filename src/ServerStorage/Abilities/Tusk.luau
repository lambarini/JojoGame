--!strict
--!optimize 2
-- // Copyright 2026 lambarini, All rights reserved. \\ --

local Ability = {}
Ability.__index = Ability

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules
local SharedData = Shared.Data
local Modules = ServerStorage.Modules
local StandsFolder = ReplicatedStorage.Stands
local Animations = script.Animations

-- // MODULES \\ --
local HitboxModule = require(Modules.Hitbox)
local ProjectileModule = require(Modules.Projectile)
local TroveModule = require(SharedModules.Trove)
local CoreUtils = require(Modules.CoreUtils)
local Combat = require(Modules.Combat)
local SignalModule = require(SharedModules.Signal)
local Packets = require(ReplicatedStorage.Packets)
local DataHandler = require(Modules.DataHandler)
local Common = require(SharedModules.Common)
local StandData = require(SharedData.StandData)
local AbilityManager = require(ServerStorage.Abilities.AbilityManager)

-- // VARIABLES \\ --

local StandName = script.Name
local StandPoses = {
	Attacking = Vector3.new(0, 0, -2),
	StandOut = Vector3.new(-3.5, 1.5, 1.5),
	Hidden = Vector3.zero,
}

type StandPose = "Attacking" | "StandOut" | "Hidden" | "Idle"

type Ability = typeof(setmetatable({} :: {
	AbilityManager : AbilityManager.AbilityManager,
	Moves : {[string] : AbilityManager.Dispatch},
	StandAttach : Attachment,
	Stand : typeof(StandsFolder.Tusk),
	Summoned : boolean,
	BarrageCancelEvent : SignalModule.Signal<>,
	CanSummon : boolean,
	_poseToken : number,

	StandIdle : AnimationTrack,
}, Ability))

-- // FUNCTIONS \\ --

function Ability.new(Player : Player) : Ability
	local self = setmetatable({}, table.clone(Ability)) :: Ability
	
	self.AbilityManager = AbilityManager.new(Player)

	self.CanSummon = true
	self.Summoned = false
	self._poseToken = 0

	self.Moves = {
		Summon = self:Summon(),
		Barrage = self:Barrage(),
		M1 = self:M1(),
		NailShot = self:NailShot(),
	}

	self:SetStandPosition("Idle")

	self.AbilityManager.Character:SetAttribute("Summoned", false)
	self.AbilityManager.Character.Parent = workspace.Living

	return self
end

function Ability:SetStandPosition(Pose : StandPose, Buffer : number?)
	self._poseToken += 1
	local Token = self._poseToken

	local function Apply()
		if not self.StandAttach.Parent then
			return
		end

		if Pose == "Idle" then
			self.StandAttach.Position = if self.Summoned then StandPoses.StandOut else StandPoses.Hidden
			return
		end

		self.StandAttach.Position = StandPoses[Pose]
	end

	if not Buffer then
		Apply()
		return
	end

	task.delay(Buffer, function()
		if Token ~= self._poseToken then
			return
		end

		if self.AbilityManager.Character:GetAttribute("UsingMove") then
			return
		end

		Apply()
	end)
end

function Ability:NailShot()
	return {
		[true] = function(Info : AbilityManager.InputInfo)
			if not Combat.CanUseMove(self.AbilityManager.Character, {
				RequiresStand = true
				}) then
				return
			end

			local Data = StandData.Tusk.NailShot
			
			Common:SetAttributes(self.AbilityManager.Character, {
				UsingMove = true,
			})
			self.AbilityManager.PlayerObject:SetCooldown("NailShot", Data.Cooldown)
			
			Common.PlayAnimation(
				self.Stand.AnimationController.Animator, 
				Animations,
				"NailShot",
				nil,
				Enum.AnimationPriority.Action
			)
			
			self:SetStandPosition("Attacking")
			
			task.delay(36 / 60, function()
				Packets.VFXEvent:Fire("NailShotEffect", {self.AbilityManager.Character})

				ProjectileModule.new({
					Origin = self.Stand.RightHand.Position,
					Direction = (Info.MousePos - self.Stand.RightHand.Position).Unit,
					Speed = Data.Speed,
					Range = Data.Range,
					Character = self.AbilityManager.Character,
					Pierce = Data.Pierce,
					Visual = "TuskNail",
					Callback = function(Enemy : CoreUtils.HumanoidR15)
						Combat.Damage(self.AbilityManager.Character, Enemy, {
							MoveName = "NailShot",
							StandName = StandName,
							MoveInfo = Data,
						})
					end,
				})
				
				task.wait(18 / 60)

				Common:SetAttributes(self.AbilityManager.Character, {
					UsingMove = false,
				})

				self:SetStandPosition("Idle", 0.15)
			end)
		end,
		[false] = function()

		end,
	}
end

function Ability:Summon()
	self.StandAttach = self.AbilityManager._trove:Add(Instance.new("Attachment"))
	self.StandAttach.Name = "StandAttach"
	self.StandAttach.Parent = self.AbilityManager.Character.HumanoidRootPart

	self.Stand = self.AbilityManager._trove:Clone(StandsFolder.Tusk)
	self.Stand.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	self.Stand.Name = "Stand"
	self.Stand:PivotTo(self.AbilityManager.Character:GetPivot())
	self.Stand.Parent = self.AbilityManager.Character

	self.StandIdle = self.Stand.AnimationController.Animator:LoadAnimation(Animations.StandIdle)
	self.StandIdle.Priority = Enum.AnimationPriority.Idle
	self.StandIdle:Play()
	
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
	
	return {
		[true] = function()
			if not self.CanSummon then
				return
			end
			
			if self.Summoned then
				self.Summoned = false
				self:SetStandPosition("Hidden")
				self.CanSummon = false
				
				self.AbilityManager.Character:SetAttribute("Summoned", false)

				task.delay(1.5, function()
					self.CanSummon = true
				end)
				
				self.BarrageCancelEvent:Fire()

				--plrInfo.UserIdle:Stop(.5)
			else
				if not Combat.CanUseMove(self.AbilityManager.Character, {
					RequiresStand = false
					}) then
					return
				end
				
				self.Summoned = true
				self:SetStandPosition("StandOut")
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

function Ability:M1()
	local Last = os.clock()
	local Sequence = 0

	local M1Animations = Animations.M1
	local CurrentTrack : AnimationTrack? = nil

	return {
		[true] = function(InputInfo)
			if not self.Summoned then
				self.AbilityManager.BaseMoves.M1[true](InputInfo)
				return
			end

			if not Combat.CanUseMove(self.AbilityManager.Character) then
				return
			end

			if os.clock() - Last >= 0.9 then
				Sequence = 1
			else
				Sequence += 1

				if Sequence > #StandData.Tusk.M1 then
					Sequence = 1
				end
			end

			if Sequence == #StandData.Tusk.M1 then
				self.AbilityManager.PlayerObject:SetCooldown("M1", 2)
			end

			Last = os.clock()

			local Trove = self.AbilityManager._trove:Add(TroveModule.new())

			Common:SetAttributes(self.AbilityManager.Character, {
				UsingMove = true,
			})

			self:SetStandPosition("Attacking")

			if CurrentTrack then
				CurrentTrack:Stop(0.1)
			end

			CurrentTrack = Common.PlayAnimation(
				self.Stand.AnimationController.Animator, 
				M1Animations.Stand, 
				Sequence
			)

			local Hitbox = HitboxModule.new({
				Size = Vector3.new(4, 4, 5),
				Offset = Vector3.new(0, 0, -2.5),
				TargetPart = self.AbilityManager.Character.HumanoidRootPart,
				Lingering = true,
				HitOnce = true,
				Character = self.AbilityManager.Character,
				Callback = function(Enemy : CoreUtils.HumanoidR15)
					Combat.Damage(self.AbilityManager.Character, Enemy, {
						MoveName = "M1",
						StandName = StandName,
						MoveInfo = StandData.Tusk.M1[Sequence]
					})
				end,
			})
			
			Trove:Add(Hitbox :: any)
			
			Trove:Add(function()
				Common:SetAttributes(self.AbilityManager.Character, {
					UsingMove = false,
					Endlag = true,
				})
				
				Hitbox:Destroy()
				
				local CurrentSequence = Sequence

				self:SetStandPosition("Idle", StandData.Tusk.M1[Sequence].Endlag)

				task.delay(StandData.Tusk.M1[Sequence].Endlag, function()
					if CurrentSequence == Sequence then
						self.AbilityManager.Character:SetAttribute("Endlag", false)
					end
				end)
			end)
			
			task.delay(.35, function()
				Trove:Destroy()
			end)
		end,
		[false] = function()
			
		end,
	}
end

function Ability:Barrage()
	self.BarrageCancelEvent = self.AbilityManager._trove:Add(SignalModule.new())

	return {
		[true] = function()
			local Humanoid = self.AbilityManager.Character.Humanoid
			local Attributes = self.AbilityManager.Character:GetAttributes()

			if not Combat.CanUseMove(self.AbilityManager.Character, {
					IgnoreStun = true,
					RequiresStand = true,
				}) then
				return
			end

			local BarrageActive = true
			local BarrageTrove = self.AbilityManager._trove:Add(TroveModule.new())

			Common:SetAttributes(self.AbilityManager.Character, {
				Barraging = true,
				UsingMove = true,
			})

			Packets.VFXEvent:Fire("BarrageEffect", {self.AbilityManager.Character, true})

			self:SetStandPosition("Attacking")

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

					task.delay(.1, function()
						blacklist[Enemy] = nil
					end)

					Combat.Damage(self.AbilityManager.Character, Enemy, {
						MoveName = "Barrage",
						StandName = StandName,
					})
				end,
			})

			--local Sound = Util:PlaySound(HumanoidRootPart, Sounds.BarrageWoosh, false)
			--local BarrageAnim : AnimationTrack = plrInfo.StandAnimator:LoadAnimation(SAnims.Barrage)
			--BarrageAnim.Priority = Enum.AnimationPriority.Action
			--BarrageAnim:Play()

			local function Cancel()
				BarrageTrove:Destroy()
				
				if BarrageActive then
					BarrageActive = false

					self.AbilityManager.PlayerObject:SetCooldown("Barrage", 7)

					Common:SetAttributes(self.AbilityManager.Character, {
						Barraging = false,
						UsingMove = false,
					})

					self:SetStandPosition("Idle", 0.15)
					
					Packets.VFXEvent:Fire("BarrageEffect", {self.AbilityManager.Character, false})

					--Sound:Destroy()
					--BarrageAnim:Stop()
					return
				end
			end

			self.BarrageCancelEvent:Once(Cancel)
			BarrageTrove:Connect(self.AbilityManager.Character:GetAttributeChangedSignal("Ragdolled"), function()
				if BarrageActive then
					self.BarrageCancelEvent:Fire()
				end
			end)

			task.delay(8, function()
				if BarrageActive then
					self.BarrageCancelEvent:Fire()
				end
			end)
			
			BarrageTrove:Add(function()
				Hitbox:Destroy()
				Cancel()
			end)
			
			return
		end,
		[false] = function()
			local Attributes = self.AbilityManager.Character:GetAttributes()

			if Attributes.UsingMove and Attributes.Barraging then
				self.BarrageCancelEvent:Fire()
			end
		end,
	}
end

return Ability