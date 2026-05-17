--!strict
local Rules = {}

local ValueRules : {[string] : (Value : any) -> (boolean, string?)} = {}

ValueRules.string = function(Value : string) : (boolean, string?)
	if utf8.len(Value) == nil then
		return false, "Invalid UTF-8 exploit" -- Safeguard against exploits like "\128"
	end

	if #Value > 8192 then
		return false, "String over 8KB" -- Return false if string is over 8 kilobytes.
	end

	return true, nil
end

ValueRules.number = function(Value : number)
	if Value ~= Value then
		return false, "Number is NaN" -- Returns false if Value is 0/0 (nan)
	end

	if math.abs(Value) == math.huge then
		return false, "Number is inf" -- Returns false for infinite values.
	end

	return true, nil
end

ValueRules.boolean = function(Value : boolean)
	return true
end

ValueRules.table = function(Table : {[any] : any})
	for Index, Value in Table do
		if not ValueRules[typeof(Index)](Index) or not ValueRules[typeof(Value)](Value) then
			return false
		end
	end

	return true
end

function Rules.IsValueSaveable(Value : any) : (boolean, string?)
	local RuleFunction = ValueRules[typeof(Value)]
	
	-- Return false is the value type is not supported.
	if not RuleFunction then
		return false
	end
	
	local Success, Status, Message = pcall(RuleFunction, Value)
	
	-- Return false if the rule function throws an error.
	if not Success then
		return false, Message
	end
	
	return Status, Message
end

return Rules