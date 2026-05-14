--!strict
-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- // FOLDERS \\ --
local ServerModules = ServerStorage.Modules

-- // VARIABLES \\ --

-- // MAIN \\ --
require(ReplicatedStorage.Packets)
require(ServerScriptService.Components.PlayerHandler).init()
print("hi")

for _, Module in ServerScriptService.Components:GetChildren() do
	if not Module:IsA("ModuleScript") then
		continue
	end

	if Module.Name == "PlayerHandler" then
		continue
	end

	local Component = require(Module) :: {init : () -> ()}
	task.spawn(Component.init)
end