-- NOTE: when starting Spring standalone, modoption-table is empty
local modOptions = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")

local enableSlopeMods = modOptions.enableSlopeMods
local enableDepthMods = modOptions.enableDepthMods

assert(modOptionDefs ~= nil)

for idx, tbl in ipairs(modOptionDefs) do
	if (tbl.key == "enableSlopeMods") then
		enableSlopeMods = enableSlopeMods or tbl.def
	end
	if (tbl.key == "enableDepthMods") then
		enableDepthMods = enableDepthMods or tbl.def
	end
end



local function EngineInternalMaxSlope(maxSlope)
	return (1.0 - math.cos((maxSlope * 1.5) * (math.pi / 180.0)))
end
local function EngineDefaultSlopeMod(maxSlope)
	return (4.0 / EngineInternalMaxSlope(maxSlope))
end



local moveDefs = {
	-- NOTE: engine starts counting MoveDefs at 1, not 0
	-- SHIPS
	[1] = {
		name = "SMALLBOAT",
		footprintX = 2,
		footprintZ = 3,
		minWaterDepth = 5.0,
		crushStrength = 50.0,
	},
	[2] = {
		name = "MEDIUMBOAT",
		footprintX = 3,
		footprintZ = 4,
		minWaterDepth = 25.0,
		crushStrength = 200.0,
	},
	[3] = {
		name = "LARGEBOAT",
		footprintX = 4,
		footprintZ = 6,
		minWaterDepth = 50.0,
		crushStrength = 1600.0,
	},
	[4] = {
		name = "BOATSUB",
		footprintX = 3,
		footprintZ = 3,
		minWaterDepth = 36.0,
		crushStrength = 100.0,
		submarine = true,
	},

	-- BOTS
	[5] = {
		name = "KBOTSF2",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 25.0,
		maxSlope = 36.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(36.0)) or 0.0,
		crushStrength = 30.0,
	},
	[6] = {
		name = "KBOTSf3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 25.0,
		maxSlope = 24.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(24.0)) or 0.0,
		crushStrength = 100.0,
	},
	[7] = {
		name = "KBOTSS2",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 25.0,
		maxSlope = 36.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(36.0)) or 0.0,
		crushStrength = 10.0,
	},
	[8] = {
		name = "KBOTUW3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 36.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(36.0)) or 0.0,
		crushStrength = 30.0,

		depthModParams = {
			linearCoeff = (enableDepthMods and 0.003) or 0.0,
		}
	},
	[9] = {
		name = "KBOTDS2",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 32.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(32.0)) or 0.0,
		crushStrength = 150.0,

		depthModParams = {
			linearCoeff = (enableDepthMods and 0.002) or 0.0,
		}
	},

	-- TANKS
	[10] = {
		name = "TANKBH3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 300.0,
	},
	[11] = {
		name = "TANKDH3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 31.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(31.0)) or 0.0,
		crushStrength = 30.0,

		depthModParams = {
			linearCoeff = (enableDepthMods and 0.003) or 0.0,
		}
	},
	[12] = {
		name = "TANKSH2",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 10.0,
	},
	[13] = {
		name = "TANKSH3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 15.0,
	},
	[14] = {
		name = "TANKSH4",
		footprintX = 4,
		footprintZ = 4,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 100.0,
	},
	[15] = {
		-- Bulldog/Reaper/Goliath can crush DT's
		name = "TANKDTCRUSH",
		footprintX = 4,
		footprintZ = 4,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 400.0,
	},

	-- HOVERS
	[16] = {
		name = "HOVER2",
		footprintX = 2,
		footprintZ = 2,
		maxSlope = 21.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(21.0)) or 0.0,
		crushStrength = 10.0,
	},
	[17] = {
		name = "HOVER3",
		footprintX = 3,
		footprintZ = 3,
		maxSlope = 21.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(21.0)) or 0.0,
		crushStrength = 30.0,
	},
	[18] = {
		name = "HOVER4",
		footprintX = 4,
		footprintZ = 4,
		maxSlope = 21.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(21.0)) or 0.0,
		crushStrength = 50.0,
	},
	[19] = {
		name = "HOVER9",
		footprintX = 1,
		footprintZ = 1,
		maxWaterDepth = 255.0,
		maxSlope = 60.0, -- ??
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(60.0)) or 0.0,
		crushStrength = 30.0,
	},
	[20] = {
		name = "HOVER10",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		maxSlope = 35.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(35.0)) or 0.0,
		crushStrength = 3000.0, -- ??
	},

	-- MISC
	[21] = {
		name = "SPID3",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 16.0,
		crushStrength = 30.0,
	},
	[22] = {
		name = "Krogoth",
		footprintX = 5,
		footprintZ = 5,
		maxWaterDepth = 90.0,
		maxSlope = 25.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(25.0)) or 0.0,
		crushStrength = 500.0,
	},
	[23] = {
		name = "CRAWLBOMB",
		footprintX = 1,
		footprintZ = 1,
		maxWaterDepth = 255.0,
		maxSlope = 48.0,
		crushStrength = 1.0,

		depthModParams = {
			linearCoeff = (enableDepthMods and 0.002) or 0.0,
		}
	},
}

return moveDefs

