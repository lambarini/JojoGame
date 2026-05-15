--!strict
-- // SERVICES \\ --
local TextChatService = game:GetService("TextChatService")

-- // FOLDERS \\ --
local Commands = TextChatService.Commands

return function()
	Commands.SetGlobal.Triggered:Connect(function(Source, Text)
		local _, Global, Value = unpack(string.split(Text, " "))
		
		_G[Global] = Value == "true"
	end)
end