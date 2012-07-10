return {
	XTA = {
		WeaponLightDefs = {
			-- Core Pillager 
			["core_artillery"] = {
				projectileLightDef = {
					diffuseColor    = {4.9, 4.9, 0.2},
					specularColor   = {0.9, 0.9, 0.1},
					radius          = 250.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {4.0, 2.0, 0.2},
					specularColor     = {4.0, 2.0, 0.2},
					radius            = 350.0,
					ttl               = 75,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 50.0,
				},
			},

			-- Arm/Core Commander
			-- NOTE:
			--   no explosion light defs, because a dgun
			--   projectile triggers a new explosion for
			--   every frame it is alive (which consumes
			--   too many light slots)
			--
			--   ttl values are arbitrarily large to make
			--   the lights survive until projectiles die
			["arm_disintegrator"] = {
				projectileLightDef = {
					diffuseColor      = {3.0, 2.0, 0.1},
					specularColor     = {3.0, 2.0, 0.1},
					radius            = 175.0,
					ttl               = 100000,
				},
			},
			["core_disintegrator"] = {
				projectileLightDef = {
					diffuseColor      = {3.0, 2.0, 0.1},
					specularColor     = {3.0, 2.0, 0.1},
					radius            = 175.0,
					ttl               = 100000,
				},
			},

			-- Arm Retaliator/Core Silencer
			-- NOTE:
			--   uses a vertical offset to simulate an
			--   airburst, since the actual projectile
			--   detonates on ground impact
			--   ttl value roughly matches CEG duration
			["nuclear_missile"] = {
				projectileLightDef = {
					diffuseColor    = {5.0, 5.0, 0.0},
					specularColor   = {2.0, 2.0, 0.0},
					intensityWeight = {10.0, 10.0, 10.0},
					radius          = 900.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {45.0, 45.0, 30.0},
					specularColor     = {10.0, 10.0, 10.0},
					intensityWeight   = {10.0, 10.0, 10.0},
					radius            = 2000.0,
					ttl               = 9 * 30,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 250.0,
				},
			},
			["crblmssl"] = {
				projectileLightDef = {
					diffuseColor    = {5.0, 5.0, 0.0},
					specularColor   = {2.0, 2.0, 0.0},
					intensityWeight = {10.0, 10.0, 10.0},
					radius          = 900.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {45.0, 45.0, 30.0},
					specularColor     = {10.0, 10.0, 10.0},
					intensityWeight   = {10.0, 10.0, 10.0},
					radius            = 2000.0,
					ttl               = 9 * 30,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 250.0,
				},
			},

			-- Arm Bertha / Core Intimidator
			-- NOTE:
			--   basically the same as core_artillery
			--   since these share their CEG, but has
			--   higher priority
			["arm_berthacannon"] = {
				projectileLightDef = {
					diffuseColor    = {3.9, 3.9, 0.2},
					specularColor   = {0.9, 0.9, 0.1},
					intensityWeight = {2.0, 2.0, 2.0},
					radius          = 450.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {4.0, 3.0, 1.2},
					specularColor     = {4.0, 3.0, 1.2},
					intensityWeight   = {2.0, 2.0, 2.0},
					radius            = 500.0,
					ttl               = 60,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 50.0,
				},
			},
			["core_intimidator"] = {
				projectileLightDef = {
					diffuseColor    = {3.9, 3.9, 0.2},
					specularColor   = {0.9, 0.9, 0.1},
					intensityWeight = {2.0, 2.0, 2.0},
					radius          = 450.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {4.0, 3.0, 1.2},
					specularColor     = {4.0, 3.0, 1.2},
					intensityWeight   = {2.0, 2.0, 2.0},
					radius            = 500.0,
					ttl               = 60,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 50.0,
				},
			},
		},
	},
}

