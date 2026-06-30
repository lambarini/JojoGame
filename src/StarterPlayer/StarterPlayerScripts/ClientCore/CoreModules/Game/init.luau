--!strict

local Game = {}

function Game.init()
	for _, Singleton in script:GetChildren() do
		if not Singleton:IsA("ModuleScript") then
			continue
		end

		task.spawn(require, Singleton)
	end
end

return Game