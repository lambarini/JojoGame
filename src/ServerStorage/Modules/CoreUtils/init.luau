export type HumanoidR15 = Model & {
	HumanoidRootPart : BasePart & {
		RootAttachment : Attachment,
	},
	Humanoid : Humanoid,
}

return {
	Rules = require(script.Rules),
	Crypto = require(script.Crypto),
	Common = require(script.Common),
}