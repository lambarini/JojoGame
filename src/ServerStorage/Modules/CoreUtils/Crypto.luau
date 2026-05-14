local Crypto = {}

function Crypto.HashVSH(String : string) : number
	local hash = 2166136261

	for i = 1, #String do
		local c = String:sub(i, i)
		local byte = string.byte(c)
		hash = bit32.bxor(hash, byte)
		hash = (hash * 16777619) % 2 ^ 32
	end

	return hash
end

return Crypto