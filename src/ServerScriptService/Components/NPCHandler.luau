--!strict
local NPCHandler = {}

-- // SERVICES \\ --
local PlayersService = game:GetService("Players")

-- // MODULES \\ --
local CharacterHandler = require(script.Parent.PlayerHandler.CharacterHandler)

local function CharacterAdded(Character : Model)
	if not PlayersService:GetPlayerFromCharacter(Character) then
		CharacterHandler.CharacterAdded(Character :: any)
	end
end

function NPCHandler.init()
	for _, Mob in workspace.Living:GetChildren() do
		CharacterAdded(Mob)
	end
	
	workspace.Living.ChildAdded:Connect(CharacterAdded)
end

return NPCHandler