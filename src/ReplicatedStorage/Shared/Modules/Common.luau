--!strict
local Common = {}

export type HumanoidR15 = Model & {
	HumanoidRootPart : BasePart & {
		RootAttachment : Attachment,
	},
	Humanoid : Humanoid,
}

export type ParticleFolder = Folder & {
	Aura : Folder & {[string] : Folder},
	Summon : Attachment,
}

function Common.ToMMSS(Duration : number) : string
	Duration = math.abs(Duration)

	local Minutes = math.floor(Duration / 60)
	local Seconds = math.floor(Duration % 60)

	local String = `{Minutes == 0 and "0" or Minutes}m {Seconds}s`
	return String
end

function Common.AddThousandsSeparator(Value : number) : string
	return (((tostring(Value):reverse()):gsub("%d%d%d", "%1,")):reverse()):gsub("^,", "")
end

function Common.IsItem(Instance : Instance) : boolean
	if (Instance:IsA("Tool") or Instance:IsA("Model")) and Instance.Parent == workspace.Items then
		return true
	end
	
	return false
end

function Common.PlaySoundAt(Instance : Instance, Sound : Sound)
	local Clone = Sound:Clone()
	Clone.Parent = Instance
	
	if not Clone.IsLoaded then
		Clone.Loaded:Wait()
	end
	
	Clone:Play()
	
	Clone.Ended:Once(function()
		Clone:Destroy()
	end)
end

function Common.getNextIntervalTime(now: number, interval: number) : number
	return (now + (interval - (now % interval)))
end

function Common.EmitVFX(VFX : BasePart | Attachment)
	for _, Particle in VFX:GetDescendants() do
		if not Particle:IsA("ParticleEmitter") then
			continue
		end
		
		Particle:Emit(Particle:GetAttribute("EmitCount"))
	end
end

function Common.Weld(Target : BasePart, Anchor : BasePart)
	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Part0 = Anchor
	WeldConstraint.Part1 = Target
	WeldConstraint.Parent = Anchor
end

local AnimationCache = {}

function Common.PlayAnimation(
	Animator: Animator?,
	AnimationInstance: Instance?,
	Identifier: any,
	FadeTime: number?,
	Priority: Enum.AnimationPriority?
): AnimationTrack?
	if not Animator or not AnimationInstance then
		return nil
	end

	if not AnimationCache[Animator] then
		AnimationCache[Animator] = {}

		Animator.Destroying:Connect(function()
			AnimationCache[Animator] = nil
		end)
	end

	local LocalCache = AnimationCache[Animator]
	local Track = LocalCache[Identifier]

	if not Track then
		local TargetAnimation: Animation? = nil

		if AnimationInstance:IsA("Animation") then
			TargetAnimation = AnimationInstance
		else
			local Found = AnimationInstance:FindFirstChild(tostring(Identifier)) 
				or AnimationInstance:FindFirstChildWhichIsA("Animation")

			if Found and Found:IsA("Animation") then
				TargetAnimation = Found
			end
		end

		if not TargetAnimation then
			return nil
		end

		Track = Animator:LoadAnimation(TargetAnimation)
		if Track then
			Track.Priority = Priority or Enum.AnimationPriority.Action
			LocalCache[Identifier] = Track
		end
	end

	if Track then
		Track:Play(FadeTime or 0.1)
	end

	return Track
end

function Common:SetAttributes(Instance : Instance, Attributes : {[string] : any})
	for Name, Value in Attributes do
		Instance:SetAttribute(Name, Value)
	end
end

return Common