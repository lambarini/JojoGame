--!strict
local AbilityManager = {}
AbilityManager.__index = AbilityManager

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules

-- // MODULES \\ --
local TroveModule = require(SharedModules.Trove)
local SignalModule = require(SharedModules.Signal)
local CoreUtils = require(Modules.CoreUtils)

export type AbilityManager = typeof(setmetatable({} :: {
	Player : Player,
	Character : CoreUtils.HumanoidR15,
	CharacterAdded : SignalModule.Signal<CoreUtils.HumanoidR15>,
	_trove : TroveModule.Trove,
	Moves : {[string] : {
		[boolean] : () -> (),
	}},
	Summoned : boolean,
}, AbilityManager))

function AbilityManager.new(Player : Player) : AbilityManager
	local self = setmetatable({}, AbilityManager) :: AbilityManager
	
	self.Player = Player
	self.Character = Player.Character or Player.CharacterAdded:Wait() :: any
	self._trove = TroveModule.new()
	self.CharacterAdded = self._trove:Add(SignalModule.new())
	
	self._trove:Connect(Player.CharacterAdded, function(Character)
		self.CharacterAdded:Fire(Character :: CoreUtils.HumanoidR15)
	end)
	
	return self
end

return AbilityManager