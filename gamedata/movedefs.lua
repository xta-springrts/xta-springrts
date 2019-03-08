-- NOTE: when starting Spring standalone, modoption-table is empty
local modOptions = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")

local enableSlopeMods = modOptions.enableSlopeMods

assert(modOptionDefs ~= nil)

for idx, tbl in ipairs(modOptionDefs) do
	if (tbl.key == "enableSlopeMods") then
		enableSlopeMods = enableSlopeMods or tbl.def
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
		speedModClass = 3, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[2] = {
		name = "MEDIUMBOAT",
		footprintX = 3,
		footprintZ = 4,
		minWaterDepth = 25.0,
		crushStrength = 200.0,
		speedModClass = 3, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[3] = {
		name = "LARGEBOAT",
		footprintX = 4,
		footprintZ = 6,
		minWaterDepth = 50.0,
		crushStrength = 1600.0,
		speedModClass = 3, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[4] = {
		name = "BOATSUB",
		footprintX = 3,
		footprintZ = 3,
		minWaterDepth = 36.0,
		crushStrength = 100.0,
		submarine = true,
		speedModClass = 3, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},

	-- BOTS
	[5] = {
		name = "KBOTSF2", -- fido, maverick, can
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 25.0,
		maxSlope = 36.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(36.0)) or 0.0,
		crushStrength = 30.0,
		depthModParams = 	{
							minHeight = 4,
							linearCoeff = 0.03,
							maxScale = 1.5,
							},
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[6] = {
		name = "KBOTSf3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 25.0,
		maxSlope = 24.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(24.0)) or 0.0,
		crushStrength = 100.0,
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[7] = {
		name = "KBOTSS2",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 25.0,
		maxSlope = 36.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(36.0)) or 0.0,
		crushStrength = 10.0,
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[8] = {
		name = "KBOTUW3", -- gimp, spiders, moved land pelican to this
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 36.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(36.0)) or 0.0,
		crushStrength = 30.0,

		depthModParams = 	{
							minHeight = 4,
							linearCoeff = 0.03,
							maxScale = 1.33,
							},
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[9] = {
		name = "KBOTDS2", -- commanders
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 32.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(32.0)) or 0.0,
		crushStrength = 150.0,

		depthModParams = 	{
							minHeight = 4,
							linearCoeff = 0.03,
							maxScale = 1.33,
							},
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
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
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[11] = {
		name = "TANKDH3", -- beaver, crab, triton, crock, garpike, muskrat, zulu
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 31.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(31.0)) or 0.0,
		crushStrength = 30.0,

		depthModParams = 	{
							minHeight = 4,
							linearCoeff = 0.03,
							maxScale = 2,
							},
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[12] = {
		name = "TANKSH2",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 10.0,
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[13] = {
		name = "TANKSH3",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 15.0,
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[14] = {
		name = "TANKSH4",
		footprintX = 4,
		footprintZ = 4,
		maxWaterDepth = 35.0,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 100.0,
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
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
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},

	-- HOVERS
	[16] = {
		name = "HOVER2",
		footprintX = 2,
		footprintZ = 2,
		maxSlope = 21.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(21.0)) or 0.0,
		crushStrength = 10.0,
		speedModClass = 2, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[17] = {
		name = "HOVER3",
		footprintX = 3,
		footprintZ = 3,
		maxSlope = 21.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(21.0)) or 0.0,
		crushStrength = 30.0,
		speedModClass = 2, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[18] = {
		name = "HOVER4",
		footprintX = 4,
		footprintZ = 4,
		maxSlope = 21.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(21.0)) or 0.0,
		crushStrength = 50.0,
		speedModClass = 2, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[19] = {
		name = "HOVER9",
		footprintX = 1,
		footprintZ = 1,
		maxWaterDepth = 255.0,
		maxSlope = 60.0, -- ??
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(60.0)) or 0.0,
		crushStrength = 30.0,
		speedModClass = 2, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[20] = {
		name = "HOVER10",
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		maxSlope = 35.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(35.0)) or 0.0,
		crushStrength = 3000.0, -- ??
		speedModClass = 2, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},

	-- MISC
	[21] = {
		name = "SPID3",
		footprintX = 2,
		footprintZ = 2,
		maxWaterDepth = 16.0,
		crushStrength = 30.0,
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[22] = {
		name = "Krogoth",
		footprintX = 5,
		footprintZ = 5,
		maxWaterDepth = 90.0,
		maxSlope = 25.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(25.0)) or 0.0,
		crushStrength = 500.0,
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
		
	},
	[23] = {
		name = "CRAWLBOMB", -- crawling bombs
		footprintX = 1,
		footprintZ = 1,
		maxWaterDepth = 255.0,
		maxSlope = 48.0,
		crushStrength = 1.0,
		depthModParams = 	{
							minHeight = 4,
							linearCoeff = 0.03,
							maxScale = 1.5,
							},
		speedModClass = 1, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
	[24] = {
		name = "TANKDH4", -- beaver, crab, triton, crock, garpike, muskrat, zulu -- land
		footprintX = 3,
		footprintZ = 3,
		maxWaterDepth = 255.0,
		submarine = true,
		maxSlope = 18.0,
		slopeMod = (enableSlopeMods and EngineDefaultSlopeMod(18.0)) or 0.0,
		crushStrength = 30.0,
		
		depthModParams = 	{
							minHeight = 8,
							linearCoeff = 0.03,
							maxScale = 2.0,
							},
							
		speedModClass = 0, -- 0 = tank, 1 = kbot, 2 = hover, 3 = ship 
	},
}

return moveDefs

