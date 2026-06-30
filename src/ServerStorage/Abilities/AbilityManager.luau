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
local DataHandler = require(Modules.DataHandler)

export type AbilityManager = typeof(setmetatable({} :: {
	Player : Player,
	PlayerObject : DataHandler.PlayerObject,
	Character : CoreUtils.HumanoidR15,
	_trove : TroveModule.Trove,
	Moves : {[string] : {
		[boolean] : () -> (),
	}},
	Destroying : SignalModule.Signal<>,
	Summoned : boolean,
}, AbilityManager))

export type AbilityClass = {
	new: (Player: Player) -> AbilityInstance,
}

export type AbilityInstance = {
	AbilityManager: AbilityManager,
	Moves: {[string]: {[boolean]: () -> ()}},
}

function AbilityManager.new(Player : Player) : AbilityManager
	local self = setmetatable({}, AbilityManager) :: AbilityManager
	
	self.Player = Player
	self.PlayerObject = DataHandler:GetPlayerObject(Player)
	self.Character = Player.Character or Player.CharacterAdded:Wait() :: any
	self._trove = TroveModule.new()
	self.Destroying = self._trove:Add(SignalModule.new())
	
	local Humanoid = self.Character:WaitForChild("Humanoid") :: Humanoid
	
	Humanoid.Died:Once(function()
		self:Destroy()
	end)
	
	return self
end

function AbilityManager.Destroy(self : AbilityManager)
	self.Destroying:Fire()
	self._trove:Destroy()
end

return AbilityManager