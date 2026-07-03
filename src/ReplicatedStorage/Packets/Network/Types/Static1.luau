local SoundService = game:GetService("SoundService")

local SFX = SoundService:WaitForChild("SFX")

local StaticTable = {
	
}

for _, Sound in SFX:GetChildren() do
	if Sound:IsA("SoundGroup") then
		for _, SoundReal in Sound:GetChildren() do
			table.insert(StaticTable, Sound.Name.."/"..SoundReal.Name)
		end
	else
		table.insert(StaticTable, Sound.Name)
	end
end

table.sort(StaticTable)

return StaticTable
