local function CopyTable(srcTbl, dstTbl)
	assert(dstTbl ~= nil)

	for key, val in pairs(srcTbl) do
		assert(type(key) ~= type({}))

		if (type(val) == type({})) then
			dstTbl[key] = {}

			srcSubTbl = val
			dstSubTbl = dstTbl[key]

			CopyTable(srcSubTbl, dstSubTbl)
		else
			dstTbl[key] = val
		end
	end
end


local rgbSpecMults = {0.25, 0.25, 0.25} -- specular RGB scales
local copyLightDefs = {
	["XTA"] = {
		["cor_gol"             ] = "core_artillery",
		["corplas_weapon"      ] = "core_artillery",
		["commander_self_d"    ] = "commander_blast",
		["arm_udisintegrator"  ] = "arm_disintegrator",
		["csarm_disintegrator" ] = "arm_disintegrator",
		["core_disintegrator"  ] = "arm_disintegrator",
		["core_udisintegrator" ] = "arm_disintegrator",
		["cscore_disintegrator"] = "arm_disintegrator",
		["core_intimidator"    ] = "arm_berthacannon",
		["cor_bats"            ] = "arm_bats",
		["armmine5"            ] = "crawl_blast",
		["atomic_blastpen"     ] = "atomic_blast",
		["crblmssl"            ] = "nuclear_missile",
		["cortron_weapon"      ] = "armemp_weapon",
	},
}
local dynLightDefs = {
	["XTA"] = {
		weaponLightDefs = {
			-- Core Pillager / Goliath / Immolator (main barrel) projectiles
			["core_artillery"] = {
				projectileLightDef = {
					diffuseColor    = {4.9,                   4.5,                   0.2                  },
					specularColor   = {4.9 * rgbSpecMults[1], 4.5 * rgbSpecMults[2], 0.2 * rgbSpecMults[3]},
					radius          = 275.0,
					priority        = 3 * 10,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {4.0,                   2.5,                   0.2                  },
					specularColor     = {4.0 * rgbSpecMults[1], 2.5 * rgbSpecMults[2], 0.2 * rgbSpecMults[3]},
					radius            = 350.0,
					priority          = 3 * 10 + 1,
					ttl               = 2.5 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 50.0,
				},
			},


			-- Arm & Core Commander (dgun) projectiles
			-- NOTE:
			--   no explosion light defs, because a dgun
			--   projectile triggers a new explosion for
			--   every frame it is alive (which consumes
			--   too many light slots)
			["arm_disintegrator"] = {
				projectileLightDef = {
					diffuseColor      = {3.0,                   2.0,                   0.1                  },
					specularColor     = {3.0 * rgbSpecMults[1], 2.0 * rgbSpecMults[2], 0.1 * rgbSpecMults[3]},
					radius            = 200.0,
					priority          = 2 * 10,
					ttl               = 100000,
				},
			},


			-- explodeas/selfdestructas lights for various large units
			["commander_blast"] = {
				explosionLightDef = {
					diffuseColor      = { 9.0,                    8.0,                    3.5                  },
					specularColor     = { 9.0 * rgbSpecMults[1],  8.0 * rgbSpecMults[2],  3.5 * rgbSpecMults[3]},
					priority          = 15 * 10,
					radius            = 1050.0,
					ttl               = 3 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 65.0,
				},
			},
			["giant_blast"] = {
				explosionLightDef = {
					diffuseColor      = { 7.0,                    6.0,                    3.5                  },
					specularColor     = { 7.0 * rgbSpecMults[1],  6.0 * rgbSpecMults[2],  3.5 * rgbSpecMults[3]},
					priority          = 14 * 10,
					radius            = 775.0,
					ttl               = 2.5 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 55.0,
				},
			},

			["crawl_blast"] = {
				explosionLightDef = {
					diffuseColor      = { 6.5,                    5.5,                    3.25                  },
					specularColor     = { 6.5 * rgbSpecMults[1],  5.5 * rgbSpecMults[2],  3.25 * rgbSpecMults[3]},
					priority          = 13 * 10,
					radius            = 725.0,
					ttl               = 2.5 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 45.0,
				},
			},
			["crawl_blastsml"] = {
				explosionLightDef = {
					diffuseColor      = { 5.5,                    4.5,                    2.25                  },
					specularColor     = { 5.5 * rgbSpecMults[1],  4.5 * rgbSpecMults[2],  2.25 * rgbSpecMults[3]},
					priority          = 12 * 10,
					radius            = 675.0,
					ttl               = 2.5 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 35.0,
				},
			},

			["atomic_blast"] = {
				explosionLightDef = {
					diffuseColor      = { 6.0,                    5.0,                    4.5                  },
					specularColor     = { 6.0 * rgbSpecMults[1],  5.0 * rgbSpecMults[2],  4.5 * rgbSpecMults[3]},
					priority          = 13 * 10,
					radius            = 575.0,
					ttl               = 2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 25.0,
				},
			},
			["atomic_blastsml"] = {
				explosionLightDef = {
					diffuseColor      = { 5.0,                    4.0,                    3.5                  },
					specularColor     = { 5.0 * rgbSpecMults[1],  4.0 * rgbSpecMults[2],  3.5 * rgbSpecMults[3]},
					priority          = 12 * 10,
					radius            = 525.0,
					ttl               = 2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 25.0,
				},
			},


			-- Arm Retaliator / Core Silencer (large nuke) projectiles
			-- NOTE:
			--   uses a vertical offset to simulate an
			--   airburst, since the actual projectile
			--   detonates on ground impact
			--   ttl value roughly matches CEG duration
			["nuclear_missile"] = {
				projectileLightDef = {
					diffuseColor    = {5.0,                   5.0,                   0.0                  },
					specularColor   = {5.0 * rgbSpecMults[1], 5.0 * rgbSpecMults[2], 0.0 * rgbSpecMults[3]},
					priority        = 20 * 10,
					radius          = 1000.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {45.0,                   45.0,                   30.0                  },
					specularColor     = {45.0 * rgbSpecMults[1], 45.0 * rgbSpecMults[2], 30.0 * rgbSpecMults[3]},
					priority          = 20 * 10 + 1,
					radius            = 2500.0,
					ttl               = 8.5 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 250.0,
				},
			},

			-- Arm Stunner / Core Neutron (small nuke) projectiles
			["armemp_weapon"] = {
				projectileLightDef = {
					diffuseColor    = {3.0,                   3.0,                   0.0                  },
					specularColor   = {3.0 * rgbSpecMults[1], 3.0 * rgbSpecMults[2], 0.0 * rgbSpecMults[3]},
					priority        = 8 * 10,
					radius          = 400.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {12.0,                   12.0,                   8.0                  },
					specularColor     = {12.0 * rgbSpecMults[1], 12.0 * rgbSpecMults[2], 8.0 * rgbSpecMults[3]},
					priority          = 8 * 10 + 1,
					radius            = 575.0,
					ttl               = 2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 125.0,
				},
			},


			-- Arm Bertha / Core Intimidator (main barrel) projectiles
			-- NOTE:
			--   basically the same as core_artillery
			--   since these share their CEG, but has
			--   higher priority
			["arm_berthacannon"] = {
				projectileLightDef = {
					diffuseColor    = {3.9,                   3.9,                   0.2                  },
					specularColor   = {3.9 * rgbSpecMults[1], 3.9 * rgbSpecMults[2], 0.2 * rgbSpecMults[3]},
					priority        = 5 * 10,
					radius          = 475.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {4.0,                   3.0,                   1.2                  },
					specularColor     = {4.0 * rgbSpecMults[1], 3.0 * rgbSpecMults[2], 1.2 * rgbSpecMults[3]},
					priority          = 5 * 10 + 1,
					radius            = 500.0,
					ttl               = 2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 50.0,
				},
			},

			-- Arm Millennium / Core Warlord (Bertha) projectiles
			["arm_bats"] = {
				projectileLightDef = {
					diffuseColor    = {3.9,                   3.9,                   0.2                  },
					specularColor   = {3.9 * rgbSpecMults[1], 3.9 * rgbSpecMults[2], 0.2 * rgbSpecMults[3]},
					priority        = 5 * 10,
					radius          = 475.0,
					ttl             = 100000,
				},
				explosionLightDef = {
					diffuseColor      = {4.0,                   3.0,                   1.2                  },
					specularColor     = {4.0 * rgbSpecMults[1], 3.0 * rgbSpecMults[2], 1.2 * rgbSpecMults[3]},
					priority          = 5 * 10 + 1,
					radius            = 500.0,
					ttl               = 2 * Game.gameSpeed,
					decayFunctionType = {0.0, 0.0, 0.0},
					altitudeOffset    = 50.0,
				},
			},
		},
	},
}

local modLightDefs = dynLightDefs[Game.modShortName]
local modCopyDefs = copyLightDefs[Game.modShortName]

-- insert copy-definitions for each light that has one
if (modLightDefs ~= nil and modCopyDefs ~= nil) then
	for dstWeaponDef, srcWeaponDef in pairs(modCopyDefs) do
		modLightDefs.weaponLightDefs[dstWeaponDef] = {}

		srcLightDefTbl = modLightDefs.weaponLightDefs[srcWeaponDef]
		dstLightDefTbl = modLightDefs.weaponLightDefs[dstWeaponDef]

		CopyTable(srcLightDefTbl, dstLightDefTbl)
	end
end

return dynLightDefs

