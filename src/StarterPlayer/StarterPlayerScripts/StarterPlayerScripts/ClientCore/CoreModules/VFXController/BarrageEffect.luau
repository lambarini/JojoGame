--!native
--!strict

-- // SERVICES \\ --
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Modules = Shared.Modules
local FXFolder = Shared.FX
local BarrageArms = FXFolder.BarrageArms

-- // MODULES \\ --
local TroveModule = require(Modules.Trove)
local Common = require(Modules.Common)

local function Bezier(P0 : Vector3, P1 : Vector3, P2 : Vector3, T : number) : Vector3
	return (1 - T) * (P0 * (1 - T) + 2 * P1 * T) + P2 * T ^ 2
end

local Barrages : {[any] : boolean} = {}

return {
	init = function()
		
	end,
	
	run = function(Data : {})
		local Character : Common.HumanoidR15, Active : boolean = table.unpack(Data)
		Barrages[Character] = Active

		if not Active then
			return
		end

		local Trove = TroveModule.new()
		local Rand = Random.new()

		local HumanoidRootPart = Character.HumanoidRootPart
		local BarrageEffect = FXFolder.BarrageEffect:Clone()
		BarrageEffect.Parent = workspace.Debris

		local function SpawnArm()
			local Duration = Rand:NextNumber(0.3, 0.5)
			local Start = os.clock()

			local Arm = Trove:Clone(BarrageArms.Tusk)
			Arm.Parent = workspace.Debris

			local P0 : CFrame, P1 : CFrame, P2 : CFrame

			if Rand:NextInteger(1, 2) == 1 then
				local F1 = Rand:NextInteger(1, 2) == 1

				P0 = CFrame.new(-1.5 + Rand:NextNumber(-1, 1), F1 and -0.5 or 0.5, 0)
				P1 = CFrame.new(-2.5 + Rand:NextNumber(-1, 1), F1 and -1.5 or 1.5, -3)
				P2 = CFrame.new(-1.5 + Rand:NextNumber(-1, 1), 0, -6 + Rand:NextNumber(-1, 1))
			else
				local F1 = Rand:NextInteger(1, 2) == 1

				P0 = CFrame.new(1.5 + Rand:NextNumber(-1, 1), F1 and -0.5 or 0.5, 0)
				P1 = CFrame.new(2.5 + Rand:NextNumber(-1, 1), F1 and -1.5 or 1.5, -3)
				P2 = CFrame.new(1.5 + Rand:NextNumber(-1, 1), 0, -6 + Rand:NextNumber(-1, 1))
			end

			local Parts = Arm:GetChildren() :: {BasePart}

			RunService:BindToRenderStep("UpdateArm"..Start, Enum.RenderPriority.Camera.Value, function()
				if os.clock() - Start >= Duration  then
					RunService:UnbindFromRenderStep("UpdateArm"..Start)
					Arm:Destroy()
					return	
				end

				local T = (os.clock() - Start) / Duration

				local Position = HumanoidRootPart.CFrame
				local C1 = Bezier((Position * P0).Position, (Position * P1).Position, (Position * P2).Position, T)
				local C2 = Bezier((Position * P0).Position, (Position * P1).Position, (Position * P2).Position, T + 0.05)

				for _, Part in Parts do
					Part.Transparency = math.sqrt(math.cos(math.pi * T * 2))
				end

				Arm.PrimaryPart.CFrame = CFrame.lookAt(C1, C2) * CFrame.Angles(math.rad(-90), 0, 0)
			end)
		end

		while task.wait(1 / 60) and Barrages[Character] do
			BarrageEffect.PrimaryPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(90), 0)
			SpawnArm()
		end

		BarrageEffect:Destroy()
	end
}