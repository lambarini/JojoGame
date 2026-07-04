--!strict
local PlayerObject = {}
PlayerObject.__index = PlayerObject

-- // SERVICES \\ --
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // FOLDERS \\ --
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules
local Data = Shared.Data

local Modules = ServerStorage.Modules

-- // MODULES \\ --
local TroveModule = require(SharedModules.Trove)
local CoreUtils = require(Modules.CoreUtils)
local DataTemplate = require(Data.DataTemplate)
local ReplicaServer = require(Modules.ReplicaServer)
local ProfileStore = require(script.Parent.ProfileStore)

-- // VARIABLES \\ --
local DataToken = ReplicaServer.Token("PlayerData")

export type Profile = typeof(ProfileStore.New("PlayerStore", DataTemplate):StartSessionAsync("1", {}))

export type SessionData = {
	Cooldowns : {[string] : number},
}

export type PlayerObject = typeof(setmetatable({} :: {
	Player : Player,
	Profile : Profile,
	Replica : ReplicaServer.Replica<typeof(DataTemplate)>,
	SessionData : SessionData,
	MousePos : Vector3,
	_trove : TroveModule.Trove
}, PlayerObject))

function PlayerObject.new(Player : Player, Profile : Profile) : PlayerObject
	local self = setmetatable({}, PlayerObject) :: PlayerObject

	self.Player = Player
	self.Profile = Profile
	self.SessionData = {
		Cooldowns = {},
	}
	self.MousePos = Vector3.zero
	self._trove = TroveModule.new()
	self.Replica = self._trove:Add(ReplicaServer.New({
		Token = DataToken,
		Data = Profile.Data
	}))
	
	self._trove:Add(function()
		self.Profile:EndSession()
	end)
	
	if ReplicaServer.ReadyPlayers[Player] then
		self.Replica:Subscribe(Player)
	else
		local Connection : RBXScriptConnection = nil
		
		Connection = ReplicaServer.NewReadyPlayer:Connect(function()
			if ReplicaServer.ReadyPlayers[Player] then
				self.Replica:Subscribe(Player)
				
				Connection:Disconnect()
			end
		end)
	end

	return self
end

function PlayerObject.Destroy(self : PlayerObject) : ()
	self._trove:Destroy()
end

function PlayerObject.Set(self : PlayerObject, Key : {string}, Value : any) : (boolean?)
	local Status, Message = CoreUtils.Rules.IsValueSaveable(Value)
	
	if not Status then
		if Message then
			warn(`[PlayerObject/Set] Value is not supported, User id : {self.Player.UserId}. Error : {Message}`)
		end
		
		return false
	end
	
	self.Replica:Set(Key, Value)
	
	return nil
end

function PlayerObject.Get(self : PlayerObject, Key : {string}) : (any)
	local Value = self.Replica.Data
	
	for _, Index in Key do
		Value = Value[Index]
	end
	
	return Value
end

function PlayerObject.Update(self : PlayerObject, Key : {string}, TransformFunction : (any) -> (any)) : ()
	local Success, Value = pcall(TransformFunction, self:Get(Key))
	
	if not Success then
		return warn(`[PlayerObject/Update] Update failed, Error : {Value} User Id : {self.Player.UserId}`)
	end
	
	self:Set(Key, Value)
end

function PlayerObject.TableInsert(self : PlayerObject, Key : {string}, Value : any, Index : number?) : ()
	local Status, Message = CoreUtils.Rules.IsValueSaveable(Value)

	if not Status then
		if Message then
			warn(`[PlayerObject/TableInsert] Value is not supported, User id : {self.Player.UserId}. Error : {Message}`)
		end

		return false
	end
	
	if Index and typeof(Index) ~= "number" then
		warn(`[PlayerObject/TableInsert] Index is not a number, User id : {self.Player.UserId}`)
		return false
	end
	
	self.Replica:TableInsert(Key, Index)
end

function PlayerObject.TableRemove(self : PlayerObject, Key : {string}, Index : number) : ()
	if not Index or typeof(Index) ~= "number" then
		warn(`[PlayerObject/TableRemove] Index is not a number or nil, User id : {self.Player.UserId}`)
		return false
	end

	self.Replica:TableRemove(Key, Index)
end

-- // SESSION DATA \\ --

function PlayerObject.SetCooldown(self : PlayerObject, Name : string, Duration : number) : ()
	self.SessionData.Cooldowns[Name] = os.clock() + Duration
end

function PlayerObject.IsOnCooldown(self : PlayerObject, Name : string) : boolean
	local Expiry = self.SessionData.Cooldowns[Name]

	if not Expiry then
		return false
	end

	return os.clock() < Expiry
end

function PlayerObject.SetAimTracking(self : PlayerObject, Enabled : boolean) : ()
	self.Player:SetAttribute("AimTracking", Enabled)
end

function PlayerObject.GetCooldown(self : PlayerObject, Name : string) : number
	local Expiry = self.SessionData.Cooldowns[Name]

	if not Expiry then
		return 0
	end

	return math.max(Expiry - os.clock(), 0)
end

-- TODO: Implement PlayerObject:SetValues() based on replica SetValues (still dont understand how it works)

return PlayerObject