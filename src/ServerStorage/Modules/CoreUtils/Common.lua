--!strict
local Common = {}

function Common:SetAttributes(Instance : Instance, Attributes : {[string] : any})
	for Name, Value in Attributes do
		Instance:SetAttribute(Name, Value)
	end
end

return Common