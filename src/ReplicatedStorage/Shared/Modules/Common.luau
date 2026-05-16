--!strict
local Common = {}

export type HumanoidR15 = Model & {
	HumanoidRootPart : BasePart & {
		RootAttachment : Attachment,
	}
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

return Common