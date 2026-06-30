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
local SharedData = Shared.Data
local Modules = ServerStorage.Modules
local StandsFolder = ReplicatedStorage.Stands
local Animations = script.Animations

-- // MODULES \\ --
local HitboxModule = require(Modules.Hitbox)
local TroveModule = require(SharedModules.Trove)
local CoreUtils = require(Modules.CoreUtils)
local Combat = require(Modules.Combat)
local SignalModule = require(SharedModules.Signal)
local Packets = require(ReplicatedStorage.Packets)
local DataHandler = require(Modules.DataHandler)
local StandData = require(SharedData.StandData)
local AbilityManager = require(ServerStorage.Abilities.AbilityManager)

-- // VARIABLES \\ --

local StandName = script.Name
local StandOutPos = Vector3.new(-3.5, 1.5, 1.5)

type Ability = typeof(setmetatable({} :: {
	AbilityManager : AbilityManager.AbilityManager,
	Moves : {[string] : {[boolean] : () -> ()}},
	StandAttach : Attachment,
	Stand : typeof(StandsFolder.Tusk),
	Summoned : boolean,
	BarrageCancelEvent : SignalModule.Signal<>,
	CanSummon : boolean,
}, Ability))

-- // FUNCTIONS \\ --

local function PlayM1Animation(Animator : Animator?, Folder : Instance?, Index : number, Cache : {[number] : AnimationTrack}) : AnimationTrack?
	if not Animator or not Folder then
		return nil
	end

	local Track = Cache[Index]

	if not Track then
		local Animation = Folder:FindFirstChild(tostring(Index)) or Folder:FindFirstChildWhichIsA("Animation")

		if not Animation or not Animation:IsA("Animation") then
			return nil
		end
		
		Cache[Index] = Animator:LoadAnimation(Animation)
		Cache[Index].Priority = Enum.AnimationPriority.Action
		
		Track = Cache[Index]
	end

	Track:Play(0.1)

	return Track
end

function Ability.new(Player : Player) : Ability
	local self = setmetatable({}, table.clone(Ability)) :: Ability
	
	self.AbilityManager = AbilityManager.new(Player)
	
	self.Moves = {
		Summon = self:Summon(),
		Barrage = self:Barrage(),
		M1 = self:M1(),
	}
	
	self.CanSummon = true
	self.Summoned = false

	self.AbilityManager.Character:SetAttribute("Summoned", false)
	self.AbilityManager.Character.Parent = workspace.Living
	
	return self
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
				
				self.BarrageCancelEvent:Fire()

				--plrInfo.UserIdle:Stop(.5)
			else
				if not Combat.CanUseMove(self.AbilityManager.Character, {
					RequiresStand = false
					}) then
					return
				end
				
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

function Ability:M1()
	local Last = os.clock()
	local Sequence = 0

	local M1Animations = Animations.M1
	local StandTracks : {[number] : AnimationTrack} = {}
	local CharacterTracks : {[number] : AnimationTrack} = {}
	local CurrentTrack : AnimationTrack? = nil

	return {
		[true] = function()
			if not Combat.CanUseMove(self.AbilityManager.Character, {
					RequiresStand = false,
				}) then
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

			CoreUtils.Common:SetAttributes(self.AbilityManager.Character, {
				UsingMove = true,
			})

			local Summoned = self.Summoned

			if Summoned then
				self.StandAttach.Position = Vector3.new(0, 0, -2)
			end

			if CurrentTrack then
				CurrentTrack:Stop(0.1)
			end

			local Animator = if Summoned
				then self.Stand.AnimationController.Animator
				else self.AbilityManager.Character.Humanoid:FindFirstChildOfClass("Animator")

			local Folder = if Summoned then M1Animations.Stand else M1Animations.Character
			local Cache = if Summoned then StandTracks else CharacterTracks

			CurrentTrack = PlayM1Animation(Animator, Folder, Sequence, Cache)

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
				CoreUtils.Common:SetAttributes(self.AbilityManager.Character, {
					UsingMove = false,
					Endlag = true,
				})
				
				Hitbox:Destroy()
				
				local CurrentSequence = Sequence
				
				task.delay(StandData.Tusk.M1[Sequence].Endlag, function()
					if CurrentSequence == Sequence then
						self.AbilityManager.Character:SetAttribute("Endlag", false)
					end
					
					if not self.AbilityManager.Character:GetAttribute("UsingMove") then
						self.StandAttach.Position = if self.Summoned then StandOutPos else Vector3.zero
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
					IgnoreStun = true
				}) then
				return
			end

			local BarrageActive = true
			local BarrageTrove = self.AbilityManager._trove:Add(TroveModule.new())

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

					self.StandAttach.Position = StandOutPos

					CoreUtils.Common:SetAttributes(self.AbilityManager.Character, {
						Barraging = false,
						UsingMove = false,
					})
					
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