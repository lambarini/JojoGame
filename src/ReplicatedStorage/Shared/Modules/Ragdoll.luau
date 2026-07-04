local runService = game:GetService("RunService")

export type ConstraintsInfo = {
	[string]: {
		[string]: boolean | string | number
	}
}

local function createRootWeld(instance: Model): WeldConstraint?
	if not instance then
		return
	end

	local humanoidRootPart = instance:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
		return
	end

	local torso = instance:FindFirstChild("UpperTorso") or instance:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return
	end

	local rootWeld = humanoidRootPart:FindFirstChild("RootWeld")
	if rootWeld and rootWeld:IsA("WeldConstraint") then
		return rootWeld
	else
		if rootWeld then
			rootWeld:Destroy()
		end

		rootWeld = Instance.new("WeldConstraint")
		rootWeld.Name = "RootWeld"

		rootWeld.Part0 = humanoidRootPart
		rootWeld.Part1 = torso

		rootWeld.Enabled = false
		rootWeld.Parent = humanoidRootPart

		return rootWeld
	end
end

local Ragdoll = {}
Ragdoll.__index = Ragdoll

function Ragdoll:initTimeStamps()
	_G.ragdollTimeStamps = (type(_G.ragdollTimeStamps) == "table" and _G.ragdollTimeStamps) or {}

	if not _G.ragdollTimeStampsHandler or typeof(_G.ragdollTimeStampsHandler) ~= "RBXScriptConnection" then
		_G.ragdollTimeStampsHandler = runService.Heartbeat:Connect(function()
			for instance, timeStampInfo in _G.ragdollTimeStamps do
				if typeof(timeStampInfo) ~= "table" or #timeStampInfo ~= 2 or not instance:IsA("Model") then
					if instance:IsA("Model") and instance:GetAttribute("Ragdolled") then
						instance:SetAttribute("Ragdolled", false)
					end

					continue
				end

				local _elapsedTime = (DateTime.now().UnixTimestampMillis - timeStampInfo[1]) / 1000
				if _elapsedTime >= timeStampInfo[2] and instance:GetAttribute("Ragdolled") then
					instance:SetAttribute("Ragdolled", false)
				end
			end
		end)
	end
end

function Ragdoll:rig(instance: Model, constraintsInfo: ConstraintsInfo?): RBXScriptConnection?
	if instance:FindFirstChild("RagdollConstraints") then
		return
	end

	local rootWeld = createRootWeld(instance)
	if rootWeld then
		rootWeld.Enabled = false
	end

	local constraintsFolder = Instance.new("Folder")
	constraintsFolder.Name = "RagdollConstraints"
	constraintsFolder.Parent = instance

	local humanoid = instance:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.BreakJointsOnDeath = false
	end

	for _, joint in (instance:GetDescendants()) do
		if not joint:IsA("Motor6D") or joint.Name == "RootJoint" or joint.Name == "Root" then continue end

		local part0, part1 = joint.Part0, joint.Part1
		if not part0 or not part1 then continue end

		local attachment0: Attachment = part0:FindFirstChild(`{joint.Name}RigAttachment`)
		local attachment1: Attachment = part1:FindFirstChild(`{joint.Name}RigAttachment`)

		if not attachment0 or not attachment1 then
			if attachment0 then
				attachment0:Destroy()
			end

			if attachment1 then
				attachment1:Destroy()
			end

			attachment0 = Instance.new("Attachment")
			attachment1 = Instance.new("Attachment")

			attachment0.Name = `{joint.Name}RigAttachment`
			attachment1.Name = `{joint.Name}RigAttachment`

			attachment0.Parent = part0
			attachment1.Parent = part1

			attachment1.Position = joint.C1.Position
			attachment0.WorldPosition = attachment1.WorldPosition
		end

		if not attachment0 or not attachment1 then
			continue
		end

		local jointName = joint.Name:match("[A-Z]?%l*$")

		if jointName and constraintsInfo and constraintsInfo[jointName] then
			for constraintName, properties in constraintsInfo[jointName] do
				local success: boolean, constraint: Constraint | NoCollisionConstraint = pcall(function()
					return Instance.new(constraintName)
				end)

				if not success or not constraint then
					if typeof(constraint) == "Instance" and not (constraint:IsA("Constraint") or constraint:IsA("NoCollisionConstraint") or constraint:IsA("WeldConstraint")) then
						constraint:Destroy()
					end

					continue
				end

				if constraint:IsA("NoCollisionConstraint") or constraint:IsA("WeldConstraint") then
					constraint.Part0 = part0
					constraint.Part1 = part1
				else
					constraint.Attachment0 = attachment0
					constraint.Attachment1 = attachment1
				end
				constraint.Name = part1.Name .. constraintName

				for index, value in (properties) do
					if not properties or typeof(constraint[index]) == "Instance" then
						continue
					end

					constraint[index] = value
				end

				local folder: Folder = constraintsFolder:FindFirstChild(jointName)
				if not folder then
					if not jointName then
						folder = constraintsFolder
					else
						folder = Instance.new("Folder")
						folder.Name = jointName
						folder.Parent = constraintsFolder
					end
				end

				constraint.Enabled = false
				constraint.Parent = folder
			end
		elseif not constraintsInfo then
			local constraint = Instance.new("BallSocketConstraint")

			constraint.Name = part1.Name .. constraint.Name

			constraint.LimitsEnabled = true
			constraint.TwistLimitsEnabled = true
			constraint.Attachment0 = attachment0
			constraint.Attachment1 = attachment1

			local folder: Folder = constraintsFolder:FindFirstChild(jointName)
			if not folder then
				if not jointName then
					folder = constraintsFolder
				else
					folder = Instance.new("Folder")
					folder.Name = jointName
					folder.Parent = constraintsFolder
				end
			end

			constraint.Enabled = false
			constraint.Parent = folder
		end
	end

	instance:SetAttribute("Ragdolled", false)

	local connection = instance:GetAttributeChangedSignal("Ragdolled"):Connect(function()
		local attribute = instance:GetAttribute("Ragdolled")
		if type(attribute) ~= "boolean" then return end

		Ragdoll:ragdoll(attribute, instance)
	end)

	return connection
end

function Ragdoll:ragdoll(ragdoll: boolean, instance: Model, duration: number?)
	if not instance:FindFirstChild("RagdollConstraints") then
		Ragdoll:rig(instance)
	end

	if ragdoll and duration and _G.ragdollTimeStamps then
		if _G.ragdollTimeStamps[instance] and type(_G.ragdollTimeStamps[instance]) == "table" and #_G.ragdollTimeStamps[instance] == 2 then
			local _elapsedTime = (DateTime.now().UnixTimestampMillis - _G.ragdollTimeStamps[instance][1]) / 1000
			local timeStampInfo = _G.ragdollTimeStamps[instance]

			_G.ragdollTimeStamps[instance] = {
				timeStampInfo[1],
				(duration - (timeStampInfo[2] - _elapsedTime) < 0 and timeStampInfo[2]) or duration + _elapsedTime
			}
		else
			_G.ragdollTimeStamps[instance] = {DateTime.now().UnixTimestampMillis, duration}
		end
	elseif not ragdoll and _G.ragdollTimeStamps then
		if _G.ragdollTimeStamps[instance] then
			_G.ragdollTimeStamps[instance] = nil
		end
	end

	local head = instance:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		head.CanCollide = ragdoll
	end

	local humanoid = instance:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.AutoRotate = not ragdoll
	end

	local humanoidRootPart = instance:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		--humanoidRootPart.CanCollide = not ragdoll

		local rootWeld = humanoidRootPart:FindFirstChild("RootWeld")
		if rootWeld then
			rootWeld.Enabled = ragdoll
		end
	end

	for _, joint in (instance:GetDescendants()) do
		if not joint:IsA("Motor6D") then
			if joint.Parent.Parent and joint.Parent.Parent.Name == "RagdollConstraints" and joint:IsA("Constraint") or joint:IsA("NoCollisionConstraint") or joint:IsA("WeldConstraint") then
				joint.Enabled = ragdoll
			end
			continue
		end

		joint.Enabled = not ragdoll
	end

	instance:SetAttribute("Ragdolled", ragdoll)
end

return Ragdoll