--!strict
-- // SERVICES \\ --
local TweenService = game:GetService("TweenService")
local PlayersService = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local SFX = SoundService.SFX

local Shared = ReplicatedStorage.Shared
local Modules = Shared.Modules

-- // MODULES \\ --
local Common = require(Modules.Common)

-- // VARIABLES \\ --
local STTweenInfo = TweenInfo.new(.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

-- // FUNCTIONS \\ --

local function SetupStand(Stand : Common.HumanoidR15)
	local Character = Stand.Parent :: Common.HumanoidR15
	
	if not Character then
		return
	end
	
	local StandName = Stand:GetAttribute("Stand")
	local ParticleFolder = Shared.Particles:FindFirstChild(StandName) :: Common.ParticleFolder
	local AuraFolder = ParticleFolder.Aura:Clone()
	local AuraParticles : {ParticleEmitter} = {}
	
	task.spawn(function()
		for _, Limb in AuraFolder:GetChildren() do
			task.spawn(function()
				local Part = Character:WaitForChild(Limb.Name, 10)

				if not Part then
					return
				end

				for _, Particle in Limb:GetChildren() do
					Particle.Parent = Part
					table.insert(AuraParticles, Particle :: ParticleEmitter)
				end
			end)
		end
	end)
	
	AuraFolder:Destroy()
	
	local function UpdateStandTransparency()
		local Summoned = Character:GetAttribute("Summoned") :: boolean
		
		if Summoned == nil then
			return
		end
		
		for _, Part in Stand:GetDescendants() do
			if not Part:IsA("BasePart") and not Part:IsA("Decal") then
				continue
			end

			if Part.Name == "HumanoidRootPart" then
				continue
			end
			
			if not Summoned then
				TweenService:Create(Part, STTweenInfo, {
					Transparency = 1
				}):Play()
			else
				TweenService:Create(Part, STTweenInfo, {
					Transparency = 0
				}):Play()
			end
		end
	end

	local function PlaySummonSound()
		if Character:GetAttribute("Summoned") then
			Common.PlaySoundAt(Stand.HumanoidRootPart, SFX.StandSummon)
			
			local StandSound = SFX:FindFirstChild(StandName):FindFirstChild("Summon")
			
			if StandSound then
				Common.PlaySoundAt(Stand.HumanoidRootPart, StandSound)
			end
		else
			Common.PlaySoundAt(Stand.HumanoidRootPart, SFX.StandUnsummon)
			
			local StandSound = SFX:FindFirstChild(StandName):FindFirstChild("UnSummon")

			if StandSound then
				Common.PlaySoundAt(Stand.HumanoidRootPart, StandSound)
			end
		end
		
	end

	local function UpdateAura()
		local Summoned = Character:GetAttribute("Summoned") :: boolean
		
		if Summoned == nil then
			Summoned = false
		end
		
		if Character:GetAttribute("LastSummoned") ~= true and Summoned == true then
			local SummonVFX = ParticleFolder.Summon:Clone()
			SummonVFX.Parent = Stand:WaitForChild("HumanoidRootPart")
			
			Common.EmitVFX(SummonVFX)
		end
		
		for _, Particle in AuraParticles do
			Particle.Enabled = Summoned
		end
		
		Character:SetAttribute("LastSummon", Summoned)
	end

	local function OnStandSummon()
		UpdateStandTransparency()
		PlaySummonSound()
		UpdateAura()
	end

	task.spawn(UpdateAura)
	task.spawn(UpdateStandTransparency)
	Character:GetAttributeChangedSignal("Summoned"):Connect(OnStandSummon)
end

local function CharacterAdded(Character : Common.HumanoidR15)
	
end

local function PlayerAdded(Player : Player)
	Player.CharacterAdded:Connect(CharacterAdded :: any)
	
	if Player.Character then
		task.spawn(CharacterAdded, Player.Character :: any)
	end
end

for _, Player in PlayersService:GetPlayers() do
	task.spawn(PlayerAdded, Player)
end

PlayersService.PlayerAdded:Connect(PlayerAdded)

for _, Stand in CollectionService:GetTagged("STAND_TAG") do
	task.spawn(SetupStand, Stand)
end

CollectionService:GetInstanceAddedSignal("STAND_TAG"):Connect(SetupStand)

return nil