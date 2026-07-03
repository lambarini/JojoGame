--!strict

-- // SERVICES \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local Modules = Shared.Modules
local FXFolder = Shared.FX

-- // MODULES \\ --
local Common = require(Modules.Common)

return {
	init = function()

	end,

	run = function(Data : {})
		local Character : Common.HumanoidR15 = table.unpack(Data)

		local Stand = Character:FindFirstChild("Stand")

		if not Stand then
			return
		end

		local RightArm = Stand:FindFirstChild("RightHand")

		if not RightArm then
			return
		end

		local ShootVFX = FXFolder.Tusk.NailShot:Clone()
		ShootVFX.Parent = RightArm

		Common.EmitVFX(ShootVFX)

		task.delay(2, function()
			if ShootVFX.Parent then
				ShootVFX:Destroy()
			end
		end)
	end
}
