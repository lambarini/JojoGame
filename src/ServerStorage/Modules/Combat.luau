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
	
	if not Humanoid then
		return
	end
	
	Humanoid.Health -= MoveData.Damage
end

return Combat