--!strict
local Combat = {}

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules
local Animations = Shared.Animations

local Data = ReplicatedStorage.Shared.Data
local Modules = ServerStorage.Modules

-- // MODULES \\ --
local StandData = require(Data.StandData)
local Packets = require(ReplicatedStorage.Packets)
local Common = require(SharedModules.Common)
local CoreUtils = require(Modules.CoreUtils)

function Combat.Damage(Attacker : CoreUtils.HumanoidR15, Target : CoreUtils.HumanoidR15, Data : {
	MoveName : string,
	StandName : string,
	MoveInfo : {[any] : any}?,
})
	local MoveData = Data.MoveInfo or StandData[Data.StandName][Data.MoveName]

	local Humanoid = Target.Humanoid
	local Attributes = Target:GetAttributes()
	
	if not MoveData or not Humanoid or Humanoid.Health <= 0 or Attributes.Invincible then
		return
	end
	
	local StunTime = MoveData.StunTime
	local StunEnd = os.clock() + StunTime
	Target:SetAttribute("Stun", StunEnd)
	
	task.delay(StunTime, function()
		if Target:GetAttribute("Stun") == StunEnd then
			Target:SetAttribute("Stun", false)
		end
	end)
	
	local Damage = MoveData.Damage
	
	Humanoid.Health -= Damage
	
	Packets.VFXEvent:Fire("HitEffect", {
		Damage = Damage,
		Character = Target,
	})
	
	Common.PlayAnimation(
		Target.Humanoid:FindFirstChild("Animator") :: Animator,
		Animations,
		`Hit{math.random(1, 3)}`
	)
end

function Combat.IsStunned(Target : CoreUtils.HumanoidR15) : boolean
	return os.clock() < (Target:GetAttribute("Stun") or 0)
end

type MoveSettings = {
	IgnoreStun : boolean?,
	RequiresStand : boolean?,
}

function Combat.CanUseMove(Target : CoreUtils.HumanoidR15, Params : MoveSettings?) : (boolean, string?)
	local Attributes = Target:GetAttributes()
	local Settings = Params or {RequiresStand = true} :: MoveSettings
	
	local Humanoid = Target.Humanoid
	
	if Humanoid.Health <= 0 then
		return false, "Dead"
	end
	
	if Combat.IsStunned(Target) then
		if not Settings.IgnoreStun then
			return false, "Stunned"
		end
	end
	
	if Attributes.UsingMove then
		return false, "Using move"
	end
	
	if not Attributes.Summoned and Settings.RequiresStand then
		return false, "Not summoned"
	end
	
	return true
end

return Combat