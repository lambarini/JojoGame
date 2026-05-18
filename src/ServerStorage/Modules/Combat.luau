--!strict
local Combat = {}

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Data = ReplicatedStorage.Shared.Data
local Modules = ServerStorage.Modules

-- // MODULES \\ --
local StandData = require(Data.StandData)
local Packets = require(ReplicatedStorage.Packets)
local CoreUtils = require(Modules.CoreUtils)

function Combat.Damage(Attacker : CoreUtils.HumanoidR15, Target : CoreUtils.HumanoidR15, Data : {
	MoveName : string,
	StandName : string,
})
	local MoveData = StandData[Data.StandName][Data.MoveName]
	
	if not MoveData then
		return
	end
	
	local Humanoid = Target.Humanoid
	
	if not Humanoid or Humanoid.Health <= 0 then
		return
	end
	
	local Attributes = Target:GetAttributes()
	if Attributes.Invincible then
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
		Damage = Damage
	})
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