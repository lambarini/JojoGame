--!strict

-- // SERVICES \\ --
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Modules = Shared.Modules
local Cutscenes = Shared.Animations.Cutscenes

-- // MODULES \\ --
local TroveModule = require(Modules.Trove)
local Common = require(Modules.Common)

-- // VARIABLES \\ --
local Camera = workspace.CurrentCamera
local ActiveTrove : TroveModule.Trove? = nil

return {
	init = function()

	end,

	run = function(Data : {})
		local Attacker : Common.HumanoidR15, CutsceneName : string, Active : boolean = table.unpack(Data)

		if ActiveTrove then
			ActiveTrove:Destroy()
			ActiveTrove = nil
		end

		if not Active then
			return
		end

		local Cutscene = Cutscenes:FindFirstChild(CutsceneName) :: any

		if not Cutscene then
			return
		end

		local AttackerHumanoid = Attacker:FindFirstChildOfClass("Humanoid")

		if not AttackerHumanoid then
			return
		end

		local Trove = TroveModule.new()
		ActiveTrove = Trove

		local Rig = Trove:Clone(Cutscene.CameraRig)
		Rig.Parent = workspace.Debris

		local Track : AnimationTrack = Rig.Humanoid.Animator:LoadAnimation(Cutscene.Animation)

		local HumanoidRootPart = Attacker.HumanoidRootPart
		local Offset = CFrame.new(Vector3.new(0, -Attacker.Humanoid.HipHeight, 0))

		Rig.RootPart.Anchored = true
		Rig.RootPart.CFrame = HumanoidRootPart.CFrame * Offset

		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.FieldOfView = 25

		RunService:BindToRenderStep("BeatdownCutscene", Enum.RenderPriority.Camera.Value, function()
			Rig.RootPart.CFrame = HumanoidRootPart.CFrame * Offset 
			Camera.CFrame = Rig.Torso.CFrame
		end)

		Trove:Add(function()
			RunService:UnbindFromRenderStep("BeatdownCutscene")
			Camera.CameraType = Enum.CameraType.Custom
			Camera.FieldOfView = 70
			HumanoidRootPart.Anchored = false
		end)

		Track:Play(0)

		Track.Stopped:Once(function()
			if ActiveTrove ~= Trove then
				return
			end

			ActiveTrove = nil
			Trove:Destroy()
		end)
	end
}
