--!strict
--!optimize 2
-- // Copyright 2026 lambarini, All rights reserved. \\ --

local CommandsHandler = {}

function CommandsHandler.init()
	for _, Command in script:GetChildren() do
		(require(Command) :: any)()
	end
end

return CommandsHandler