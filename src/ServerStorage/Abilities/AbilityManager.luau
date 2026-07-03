--!strict
local AbilityManager = {}
AbilityManager.__index = AbilityManager

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules
local SharedData = Shared.Data
local Animations = script.Animations

-- // MODULES \\ --
local TroveModule = require(SharedModules.Trove)
local SignalModule = require(SharedModules.Signal)
local CoreUtils = require(Modules.CoreUtils)
local DataHandler = require(Modules.DataHandler)
local HitboxModule = require(Modules.Hitbox)
local Combat = require(Modules.Combat)
local Common = require(SharedModules.Common)
local StandData = require(SharedData.StandData)

export type InputInfo = {
	MousePos : Vector3,
}

export type Dispatch = {[boolean] : (InputInfo) -> ()}

export type AbilityManager = typeof(setmetatable({} :: {
	Player : Player,
	PlayerObject : DataHandler.PlayerObject,
	Character : CoreUtils.HumanoidR15,
	_trove : TroveModule.Trove,
	BaseMoves : {[string] : Dispatch},
	Moves : {[string] : Dispatch},
	Destroying : SignalModule.Signal<>,
	Summoned : boolean,
}, AbilityManager))

export type AbilityClass = {
	new: (Player: Player) -> AbilityInstance,
}

export type AbilityInstance = {
	AbilityManager: AbilityManager,
	Moves: {[string]: Dispatch},
}

-- // FUNCTIONS \\ --

local function PlayAnimation(Animator : Animator?, Folder : Instance?, Index : number, Cache : {[number] : AnimationTrack}) : AnimationTrack?
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

function AbilityManager.new(Player : Player) : AbilityManager
	local self = setmetatable({}, AbilityManager) :: AbilityManager

	self.Player = Player
	self.PlayerObject = DataHandler:GetPlayerObject(Player)
	self.Character = Player.Character or Player.CharacterAdded:Wait() :: any
	self._trove = TroveModule.new()
	self.Destroying = self._trove:Add(SignalModule.new())
	self.BaseMoves = {
		M1 = self:BaseM1(),
	}

	local Humanoid = self.Character:WaitForChild("Humanoid") :: Humanoid

	Humanoid.Died:Once(function()
		self:Destroy()
	end)

	return self
end

function AbilityManager.BaseM1(self : AbilityManager) : Dispatch
	local Character = self.Character
	local Last = os.clock()
	local Sequence = 0
	local Tracks : {[number] : AnimationTrack} = {}
	local CurrentTrack : AnimationTrack? = nil

	return {
		[true] = function()
			if not Combat.CanUseMove(Character, {
					RequiresStand = false,
				}) then
				return
			end

			if os.clock() - Last >= 0.9 then
				Sequence = 1
			else
				Sequence += 1

				if Sequence > #StandData.Standless.M1 then
					Sequence = 1
				end
			end

			Last = os.clock()

			local MoveData = StandData.Standless.M1[Sequence]

			if MoveData.Cooldown then
				self.PlayerObject:SetCooldown("M1", MoveData.Cooldown)
			end

			local Trove = self._trove:Add(TroveModule.new())
			local Cancelled = false

			Trove:Add(function()
				Cancelled = true

				Common:SetAttributes(Character, {
					UsingMove = false,
					Endlag = true,
				})

				local CurrentSequence = Sequence

				task.delay(MoveData.Endlag, function()
					if CurrentSequence == Sequence then
						Character:SetAttribute("Endlag", false)
					end
				end)
			end)

			Common:SetAttributes(Character, {
				UsingMove = true,
			})

			if CurrentTrack then
				CurrentTrack:Stop(0.1)
			end

			CurrentTrack = PlayAnimation(Character.Humanoid:FindFirstChildOfClass("Animator"), Animations.M1, Sequence, Tracks)

			task.delay(MoveData.StartUp, function()
				if Cancelled then
					return
				end

				local Hitbox = HitboxModule.new({
					Size = MoveData.HitboxSize,
					Offset = MoveData.HitboxOffset,
					TargetPart = Character.HumanoidRootPart,
					Lingering = true,
					HitOnce = true,
					Character = Character,
					Callback = function(Enemy : CoreUtils.HumanoidR15)
						Combat.Damage(Character, Enemy, {
							MoveName = "M1",
							StandName = "Standless",
							MoveInfo = MoveData,
						})
					end,
				})

				Trove:Add(Hitbox :: any)

				task.delay(MoveData.HitboxDuration, function()
					if Cancelled then
						return
					end

					Trove:Destroy()
				end)
			end)
		end,
		[false] = function()

		end,
	}
end

function AbilityManager.Destroy(self : AbilityManager)
	self.Destroying:Fire()
	self._trove:Destroy()
end

return AbilityManager
