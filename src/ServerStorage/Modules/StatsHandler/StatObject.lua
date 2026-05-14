--!strict
local StatObject = {}
StatObject.__index = StatObject

export type StatObject = typeof(setmetatable({} :: {
	Name : string,
	Value : number,
	MaxValue : number,
	MinValue : number,
	ChangeRate : number,
	ChangeSpeed : number,
	LastUpdate : number,
	_boosts : {thread},
}, StatObject))

function StatObject.new(Name : string, Value : number, MaxValue : number, MinValue : number, ChangeRate : number, ChangeSpeed : number) : StatObject
	local self = setmetatable({}, StatObject) :: StatObject
	
	self.Name = Name
	self.Value = Value
	self.MaxValue = MaxValue
	self.MinValue = MinValue
	self.ChangeRate = ChangeRate
	self.ChangeSpeed = ChangeSpeed
	self.LastUpdate = 0
	self._boosts = {}
	
	return self
end

function StatObject.Update(self : StatObject) : ()
	if os.clock() - self.LastUpdate < self.ChangeSpeed then
		return
	end
	
	self.LastUpdate = os.clock()
	self.Value = math.clamp(self.Value + self.ChangeRate, self.MinValue, self.MaxValue)
end

function StatObject.Add(self : StatObject, Value : number) : ()
	self.Value += Value
end

function StatObject.Set(self : StatObject, Value : number) : ()
	self.Value = Value
end

function StatObject.SetChangeRate(self : StatObject, ChangeRate : number) : ()
	print(ChangeRate)
	self.ChangeRate = ChangeRate
	
	for _, Thread in self._boosts do
		task.cancel(Thread)
	end
end

function StatObject.BoostChangeRate(self : StatObject, Boost : number, Duration : number?) : ()
	self.ChangeRate *= Boost
	
	if Duration then
		table.insert(self._boosts, task.delay(Duration, function()
			self.ChangeRate /= Boost
		end))
	end
end

return StatObject