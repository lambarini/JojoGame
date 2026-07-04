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
	Center = Vector3.zero,
}

type StandPose = "Attacking" | "StandOut" | "Hidden" | "Center" | "Idle"

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
		Beatdown = self:Beatdown(),
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

			self.AbilityManager.PlayerObject.MousePos = Info.MousePos
			self.AbilityManager.PlayerObject:SetAimTracking(true)
			
			Common.PlayAnimation(
				self.Stand.AnimationController.Animator, 
				Animations,
				"NailShot",
				nil,
				Enum.AnimationPriority.Action
			)
			
			self:SetStandPosition("Attacking")
			
			task.delay(36 / 60, function()
				self.AbilityManager.PlayerObject:SetAimTracking(false)

				local Origin = self.Stand.RightHand.Position
				local Direction = self.AbilityManager.PlayerObject.MousePos - Origin

				if Direction.Magnitude == 0 then
					Direction = self.AbilityManager.Character.HumanoidRootPart.CFrame.LookVector
				end

				Packets.VFXEvent:Fire("NailShotEffect", {self.AbilityManager.Character})

				ProjectileModule.new({
					Origin = Origin,
					Direction = Direction.Unit,
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
			
			Packets.PlaySound:Fire("Swing", self.AbilityManager.Character.HumanoidRootPart)

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
	
	self.AbilityManager.Character.AttributeChanged:Connect(function()
		if not Combat.CanUseMove(self.AbilityManager.Character, {
			IgnoreStun = true,
			RequiresStand = true,
			IgnoreAttacking = true,
			}) then
			self.BarrageCancelEvent:Fire()
		end
	end)

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
			
			local BarrageAnim = Common.PlayAnimation(
				self.Stand.AnimationController.Animator,
				Animations.Barrage,
				"Barrage",
				nil,
				Enum.AnimationPriority.Action
			)

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

					if BarrageAnim then
						BarrageAnim:Stop()
					end
					
					return
				end
			end

			self.BarrageCancelEvent:Once(Cancel)
			BarrageTrove:Connect(self.AbilityManager.Character:GetAttributeChangedSignal("Ragdolled"), function()
				if BarrageActive then
					self.BarrageCancelEvent:Fire()
				end
			end)

			task.delay(7, function()
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

function Ability:Beatdown()
	return {
		[true] = function()
			local Character = self.AbilityManager.Character

			if not Combat.CanUseMove(Character, {
				RequiresStand = true
				}) then
				return
			end

			local Data = StandData.Tusk.Beatdown

			Common:SetAttributes(Character, {
				UsingMove = true,
			})

			self:SetStandPosition("Attacking")

			local Grabbed = false
			local Hitbox = HitboxModule.new({
				Size = Data.HitboxSize,
				Offset = Data.HitboxOffset,
				TargetPart = Character.HumanoidRootPart,
				Lingering = true,
				HitOnce = true,
				Character = Character,
				Callback = function(Enemy : CoreUtils.HumanoidR15)
					if Grabbed then
						return
					end

					if Enemy:GetAttribute("InBeatdown") or Enemy:GetAttribute("Invincible") then
						return
					end

					local EnemyHumanoid = Enemy:FindFirstChildOfClass("Humanoid")

					if not EnemyHumanoid or EnemyHumanoid.Health <= 0 then
						return
					end

					Grabbed = true

					task.spawn(function()
						self:RunBeatdown(Enemy, Data)
					end)
				end,
			})

			self.AbilityManager._trove:Add(Hitbox :: any)

			task.delay(Data.HitboxDuration, function()
				Hitbox:Destroy()
				
				if Grabbed then
					return
				end

				self.AbilityManager.PlayerObject:SetCooldown("Beatdown", Data.WhiffCooldown)

				Common:SetAttributes(Character, {
					UsingMove = false,
				})

				self:SetStandPosition("Idle", 0.15)
			end)
		end,
		[false] = function()

		end,
	}
end

function Ability:RunBeatdown(Enemy : CoreUtils.HumanoidR15, Data : typeof(StandData.Tusk.Beatdown))
	local Character = self.AbilityManager.Character
	local HumanoidRootPart = Character.HumanoidRootPart
	local Humanoid = Character.Humanoid
	local EnemyRootPart = Enemy.HumanoidRootPart
	local EnemyHumanoid = Enemy.Humanoid
	
	EnemyHumanoid.AutoRotate = false
	Humanoid.AutoRotate = false

	self.AbilityManager.PlayerObject:SetCooldown("Beatdown", Data.Cooldown)

	local Trove = self.AbilityManager._trove:Add(TroveModule.new())
	local Active = true
	local StunEnd = os.clock() + Data.Duration + 0.5

	Common:SetAttributes(Character, {
		InBeatdown = true,
	})

	Common:SetAttributes(Enemy, {
		InBeatdown = true,
		Stun = StunEnd,
	})

	self:SetStandPosition("Center")
	
	local StartCFrame = HumanoidRootPart.CFrame
	EnemyRootPart.CFrame = HumanoidRootPart.CFrame

	local UserTrack = Common.PlayAnimation(
		Humanoid:FindFirstChildOfClass("Animator"),
		Animations,
		"BeatdownPlayer",
		nil,
		Enum.AnimationPriority.Action4
	)

	local StandTrack = Common.PlayAnimation(
		self.Stand.AnimationController.Animator,
		Animations,
		"BeatdownStand",
		nil,
		Enum.AnimationPriority.Action4
	)

	local VictimTrack = Common.PlayAnimation(
		EnemyHumanoid:FindFirstChildOfClass("Animator"),
		Animations,
		"BeatdownVictim",
		nil,
		Enum.AnimationPriority.Action4
	)

	local EnemyPlayer = PlayersService:GetPlayerFromCharacter(Enemy)

	if EnemyPlayer then
		Packets.VFXEvent:FireClient(EnemyPlayer, "BeatdownCutscene", {Character, "TuskBeatdown", true, StartCFrame})
	end

	Packets.VFXEvent:FireClient(self.AbilityManager.Player, "BeatdownCutscene", {Character, "TuskBeatdown", true, StartCFrame})

	Trove:Add(task.spawn(function()
		while task.wait() do
			EnemyRootPart.CFrame = StartCFrame
			HumanoidRootPart.CFrame = StartCFrame
		end
	end))

	Trove:Add(function()
		Active = false

		Character:SetAttribute("InBeatdown", false)
		Enemy:SetAttribute("InBeatdown", false)

		if Enemy:GetAttribute("Stun") == StunEnd then
			Enemy:SetAttribute("Stun", false)
		end

		if UserTrack then
			UserTrack:Stop()
		end

		if StandTrack then
			StandTrack:Stop()
		end

		if VictimTrack then
			VictimTrack:Stop()
		end

		Common:SetAttributes(Character, {
			UsingMove = false,
		})

		if EnemyPlayer then
			Packets.VFXEvent:FireClient(EnemyPlayer, "BeatdownCutscene", {Character, "TuskBeatdown", false})
		end
		
		if self.AbilityManager.Player then
			Packets.VFXEvent:FireClient(self.AbilityManager.Player, "BeatdownCutscene", {Character, "TuskBeatdown", false})
		end

		self:SetStandPosition("Idle", 0.15)
		
		Humanoid.AutoRotate = true
		EnemyHumanoid.AutoRotate = true
	end)

	Trove:Connect(EnemyHumanoid.Died, function()
		Trove:Destroy()
	end)

	Trove:Connect(Enemy.AncestryChanged, function()
		if not Enemy.Parent then
			Trove:Destroy()
		end
	end)

	task.delay(Data.Duration, function()
		if not Active then
			return
		end

		Combat.Damage(Character, Enemy, {
			MoveName = "Beatdown",
			StandName = StandName,
			MoveInfo = Data,
		})

		Trove:Destroy()
		Enemy:PivotTo(HumanoidRootPart.CFrame * CFrame.new(Data.KnockbackOffset))
	end)
end

return Ability