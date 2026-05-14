--!strict
local StatsHandler = {}
StatsHandler.__index = StatsHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Shared
local SharedModules = Shared.Modules

local ReplicaServer = require(Modules.ReplicaServer)
local TroveModule = require(SharedModules.Trove)
local StatObject = require(script.StatObject)

export type StatsHandler = typeof(setmetatable({} :: {
	Stats : {[string] : StatObject.StatObject},
	_player : Player,
	_trove : TroveModule.Trove,
	_replica : ReplicaServer.Replica<{[string] : number}>
}, StatsHandler))

local Token = ReplicaServer.Token("StatsToken")

local PlayerStatsObjects : {[Player] : StatsHandler}  = {}

function StatsHandler.new(Player : Player) : StatsHandler
	local self = setmetatable({}, StatsHandler) :: StatsHandler
	
	self.Stats = {}
	self._player = Player
	self._trove = TroveModule.new()
	self._replica = ReplicaServer.New({
		Data = {} :: {[string] : number},
		Token = Token,
	})
	
	self._replica:Set({"Stats"}, {})
	self._replica:Set({"Values"}, {})
	
	if ReplicaServer.ReadyPlayers[Player] then
		self._replica:Subscribe(Player)
	else
		local Connection
		Connection = ReplicaServer.NewReadyPlayer:Connect(function()
			if ReplicaServer.ReadyPlayers[Player] then
				self._replica:Subscribe(Player)

				Connection:Disconnect()
			end
		end)
	end
	
	self._trove:Add(task.spawn(function()
		while task.wait(.1) do
			local Values = {}
			local NotEmpty = false
			
			for Name, Stat in self.Stats do
				local OldValue = Stat.Value
				
				Stat:Update()
				
				if OldValue == Stat.Value then
					continue
				end
				
				NotEmpty = true
				Values[Name] = Stat.Value
			end
			
			if not NotEmpty then
				continue
			end
			
			self._replica:SetValues({"Values"}, Values)
		end
	end))
	
	PlayerStatsObjects[Player] = self
	
	self._trove:Add(function()
		PlayerStatsObjects[Player] = nil
	end)
	
	return self
end

function StatsHandler.AddStatValue(Player : Player, Name : string, Value : number) : ()
	local StatsObject = PlayerStatsObjects[Player]
	
	if not StatsObject then
		return
	end
	
	local StatObject = StatsObject.Stats[Name]
	
	if not StatObject then
		return
	end
	
	StatObject:Add(Value)
	StatsObject._replica:Set({"Values", Name}, StatObject.Value)
end

function StatsHandler.SetStatValue(Player : Player, Name : string, Value : number) : ()
	local StatsObject = PlayerStatsObjects[Player]

	if not StatsObject then
		return
	end

	local StatObject = StatsObject.Stats[Name]

	if not StatObject then
		return
	end

	StatObject:Set(Value)
	StatsObject._replica:Set({"Values", Name}, Value)
end

function StatsHandler.SetChangeRate(Player : Player, Name : string, ChangeRate : number) : ()
	local StatsObject = PlayerStatsObjects[Player]

	if not StatsObject then
		return
	end

	local StatObject = StatsObject.Stats[Name]

	if not StatObject then
		return
	end

	StatObject:SetChangeRate(ChangeRate)
end

function StatsHandler.AddStat(self : StatsHandler, Name : string, Value : number, MaxValue : number, MinValue : number, ChangeRate : number, ChangeSpeed : number) : StatObject.StatObject
	local Stat = StatObject.new(Name, Value, MaxValue, MinValue, ChangeRate, ChangeSpeed)
	
	self.Stats[Name] = Stat
	self._replica:Set({"Stats", Name}, {Max = MaxValue, Min = MinValue})
	
	return Stat
end

function StatsHandler.GetStatObject(self : StatsHandler, Name : string) : StatObject.StatObject
	return self.Stats[Name]
end

function StatsHandler.GetPlayerObject(Player : Player) : StatsHandler
	return PlayerStatsObjects[Player]
end

function StatsHandler.Destroy(self : StatsHandler)
	self._trove:Destroy()
	
	table.clear(self.Stats)
end

return StatsHandler