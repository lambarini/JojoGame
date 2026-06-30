--!strict
local Network = require(script.Network)

return {
	RunEvent = Network("RunEvent", Network.Boolean8),
	DragEvent = Network("Drag", Network.Instance),
	UseItemEvent = Network("UseItemEvent", Network.Instance),
	PlaySound = Network("PlaySound", Network.Static1),
	MoveEvent = Network("MoveEvent", Network.Characters, Network.Boolean8, Network.Vector3F32),
	VFXEvent = Network("VFXEvent", Network.String, Network.Any :: {any}),
	SpawnProjectile = Network("SpawnProjectile", Network.NumberU16, Network.Vector3F32, Network.Vector3F32, Network.NumberF32, Network.NumberF32, Network.String),
	DestroyProjectile = Network("DestroyProjectile", Network.NumberU16)
}