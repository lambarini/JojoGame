--!strict
--!optimize 2
-- // Copyright 2026 lambarini, All rights reserved. \\ --

local GUI = {}

function GUI.init()
	-- Init all GUI components
	for _, Singleton in script:GetChildren() do
		if not Singleton:IsA("ModuleScript") then
			continue
		end

		task.spawn(require, Singleton)
	end
end

return GUI