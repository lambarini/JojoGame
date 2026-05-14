--!strict
local Network = require(script.Network)

return {
	RunEvent = Network("RunEvent", Network.Boolean8),
	DragEvent = Network("Drag", Network.Instance),
	UseItemEvent = Network("UseItemEvent", Network.Instance),
	PlaySound = Network("PlaySound", Network.Static1),
	MoveEvent = Network("MoveEvent", Network.Characters, Network.Boolean8),
	VFXEvent = Network("VFXEvent", Network.String, Network.Any :: {any})
}