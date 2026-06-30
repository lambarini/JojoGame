--!strict
return {
	Tusk = {
		Barrage = {
			Damage = 1.2,
			Duration = 5,
			StunTime = 0.3,
		},
		M1 = {
			[1] = {
				Damage = 5,
				StunTime = 0.8,
				Endlag = 0.15,
			},
			[2] = {
				Damage = 5,
				StunTime = 0.8,
				Endlag = 0.15,
			},
			[3] = {
				Damage = 5,
				StunTime = 0.8,
				Endlag = 0.15,
			},
			[4] = {
				Damage = 5,
				StunTime = 0.8,
				Endlag = 0.15,
			},
			[5] = {
				Damage = 5,
				StunTime = 0.8,
				Endlag = 0.15,
			},
		}
	},
	Standless = {
		M1 = {
			[1] = {
				StartUp = 0.22,
				HitboxDuration = 0.2,
				Endlag = .15,
				Damage = 5,
				StunTime = 0.4,
				HitboxSize = Vector3.one * 5,
				HitboxOffset = Vector3.new(0, 0, -3),
				KnockbackDuration = 0.1,
				KnockbackForce = 10,
			},
			[2] = {
				StartUp = 0.23,
				HitboxDuration = 0.2,
				Endlag = .15,
				Damage = 5,
				StunTime = 0.4,
				HitboxSize = Vector3.one * 5,
				HitboxOffset = Vector3.new(0, 0, -3),
				KnockbackDuration = 0.1,
				KnockbackForce = 10,
			},
			[3] = {
				StartUp = 0.2,
				HitboxDuration = 0.15,
				Endlag = .15,
				Damage = 5,
				StunTime = 0.4,
				HitboxSize = Vector3.one * 5,
				HitboxOffset = Vector3.new(0, 0, -3),
				KnockbackDuration = 0.1,
				KnockbackForce = 10,
			},
			[4] = {
				StartUp = 0.2,
				HitboxDuration = 0.2,
				Endlag = .15,
				Damage = 5,
				StunTime = 0.4,
				HitboxSize = Vector3.one * 5,
				HitboxOffset = Vector3.new(0, 0, -3),
				KnockbackDuration = 0.1,
				KnockbackForce = 10,
			},
			[5] = {
				StartUp = 0.22,
				HitboxDuration = 0.2,
				Endlag = 0.2,
				Damage = 10,
				StunTime = 0.4,
				HitboxSize = Vector3.one * 5,
				HitboxOffset = Vector3.new(0, 0, -3),
				KnockbackDuration = 0.1,
				KnockbackForce = 10,
				Ragdoll = 2,
				Cooldown = 2,
			},
		},
	},
}