local rnd	= math.random
local floor = math.floor
--[[
--------------------------------------- INSTRUCTIONS (EASY) -----------------------------------
	Choose a proper setup that might allready be defined or use one the the functions to make a default setup
	REMARKS (when setting your own default setup)
	*	all roles need to be defined
	*	maxWaterDepth tag in unitdef should be defined
	*	minWaterDepth tag in Unitdef should be defined
	* 	use for food1 a immobile behavior (like trees because they will grow)
	*	for now also food2 should be used as immobile unit (will change later)
--]]

local lib =  include("luarules/configs/gaia_wildlife_config_lib.lua") 								-- functions used for setups
local wildlifeConfig = {
	
	-- maps uses default
	["Cow"]									= "treeSmallMapGroupingsMetal10",						-- see for a discription below
	["TheColdPlace"] 						= "treeMediumMapGroupingsMetal10",			
	["The Cold Place Remake V3c"] 			= "treeMediumMapGroupingsMetal10",			
	["The Cold Place Remake"] 				= "treeMediumMapGroupingsMetal10",			
	["Tropical"]							= "treeLargeMapGroupingsMetal1",
	["Geyser_Plains_TNM04-V3"]				= "treeSmallMapGroupingsMetal5",
	["WidePass Fineto"]						= "treeLargeMapGroupingsMetal10",
	
	-- directly map setups
	["Sierra-v2"]							= lib.twoTreeGroupings("tree_sierra_map_1_metal", 20, 500, 50,
																	"tree_sierra_map_10_metal", 20, 500, 50),
	--["MoonQ10x"]							= lib.twoMobileFoodGroupings("critter_ant", 2, 500, 50,						-- used with mobile units
	--																"critter_duck", 2, 500, 50),																
	["LakeDay_v1"]							= lib.twoTreeGroupingPrey("palmetto_10_metal", 5, 50, 5,
																	"palmetto_20_metal", 5, 50, 5,
																	"critter_duck", 2, 400, 50),
	["Lowland_Crossing_TNM01-V4"]			= lib.twoTreeGroupingPreyPred("palmetto_10_metal", 5, 50, 5,
																		"palmetto_20_metal", 5, 50, 5,
																		"critter_duck", 2, 400, 50,
																		"critter_gull", 1, 500, 50),
	--["Trefoil_v2"] 						= "allTrefoil",												-- manually set
	["Trefoil_v2"]							= lib.twoTreeGroupingPreyPred("tree_sierra_map_1_metal", 5, 50, 5,
																		"tree_sierra_map_10_metal", 5, 50, 5,
																		"critter_duck", 2, 400, 50,
																		"critter_gull", 1, 500, 50),
	["LakeDay_v1"]							= lib.twoTreeGroupingTwoPreyTwoPred("tree_10_metal", 5, 50, 5,
																				"critter_duck", 2, 400, 50,
																				"critter_gull", 1, 500, 50,
																				"tree_5_metal", 5, 50, 5,
																				"critter_goldfish", 2, 300, 50,
																				"critter_goldfish_big", 1, 300, 50),					
	["Ring Atoll Remake"]					= lib.twoTreeGroupingTwoPreyTwoPred("tree_water_10_metal", 20, 100, 10,				-- setting some to zero
																				"critter_duck", 0, 400, 50,
																				"critter_gull", 1, 500, 50,
																				"tree_water_10_metal", 20, 100, 10,
																				"critter_goldfish", 2, 300, 50,
																				"critter_goldfish_big", 1, 300, 50),
	-- default map setups
	["treeSmallMapGroupingsMetal10"]  		= lib.treeGroupings("tree_10_metal", 5, 50, 5),				-- tree groupings (10 metal)(4x5 units(sectors x number)
	["treeSmallMapGroupingsMetal5"]  		= lib.treeGroupings("tree_5_metal", 5, 50, 5),				-- tree groupings (5 metal)
	["treeSmallMapGroupingsMetal1"]  		= lib.treeGroupings("tree_1_metal", 5, 50, 5),				-- tree groupings (5 metal)
	["treeSmallMapGroupingsMetal10Water"]  	= lib.treeGroupings("tree_water_10_metal", 5, 50, 5),		-- tree groupings in shallow water (10 metal)
	["treeMediumMapGroupingsMetal10"]  		= lib.treeGroupings("tree_10_metal", 10, 100, 10),			-- same medium map
	["treeMediumMapGroupingsMetal5"]  		= lib.treeGroupings("tree_5_metal", 10, 100, 10),			-- same medium map
	["treeMediumMapGroupingsMetal1"]  		= lib.treeGroupings("tree_1_metal", 10, 100, 10),			-- same medium map
	["treeMediummapGroupingsMetal10Water"]  = lib.treeGroupings("tree_water_10_metal", 10, 100, 10),	-- same medium map
	["treeLargeMapGroupingsMetal10"]  		= lib.treeGroupings("tree_10_metal", 20, 300, 10),			-- same large
	["treeLargeMapGroupingsMetal5"]  		= lib.treeGroupings("tree_5_metal", 20, 300, 10),			-- 
	["treeLargeMapGroupingsMetal1"]  		= lib.treeGroupings("tree_1_metal", 20, 300, 10),			-- 
	["treeLargemapGroupingsMetal10Water"] 	= lib.treeGroupings("tree_water_10_metal", 20, 300, 10),	-- 
	
	--[[
	--------------------------------------- INSTRUCTIONS (HARD) -----------------------------------

	While all species (food1 till pred2) need to be specified, not all need to be present, meaning:
	you can have just food1, prey1 and pred1 numbers with species2 all zeros for instance.
	having only predators will result in extinction fast resulting in spamming ocassionally new units.
	For now predators will eat both prey sources as will do prey with food sources. (maybe optionalized in future) 
	
	TODO: add some maps with HARD settings (like changing procreationSucces.., ..., different areas with different behaviors)

	Many setups are possible with many different area on one map with alot of species for each specified. Also the unit
	properties makes up extra parameters to set, think about unit speed etc... Then with all this tweaking possible it 
	is also possible to change the evolveTime or values derived fromthis set value. Only very motivated peaple should
	try to make sence of these values since likely without any luck and time one will end up in fail and more fail. 

	THERE ARE SOME KNOWN BEHAVIORS THAT MIGHT HELP:
	*	radius (high) and MaxInRadius (low) parameters for trees can restrict trees becomming overpopulating 
	*	You dont want overpopulation so maybe change max wildlife setting in gadged if necessary
	*	Another solution is to make prey more effective by increasing there radius (radius of forraging)
	*	This option comes with the risk of prey overpopulation (temporarly untill food is no more) 
	*	Possibly this can be solved to make radius predators larger with the risk that they eat all prey fast.
	*
	
	NoSelectable = true
	noGrowing = false
	mobile????
	TODO 
	]]--
		
	
	-- manual map setups
 
	["treeWaterMetal10"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 500,
				name = "tree_water_10_metal",
				area = 1,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 1,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_goldfish_big"] = 5},
				radius = 500,
				name = "critter_goldfish_big",
				area = 1,
				role = "pred1"
			},
			["food2"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 100,
				name = "tree_water_10_metal",
				area = 1,
				role = "food2",
				maxInRadius = 9
			},
			["prey2"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 1,
				role = "prey2"
			},
			["pred2"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_gull"] = 5},
				radius = 500,
				name = "critter_gull",
				area = 1,
				role = "pred2"
			},
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 500,
				name = "tree_water_10_metal",
				area = 2,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 2,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_goldfish_big"] = 5},
				radius = 500,
				name = "critter_goldfish_big",
				area = 2,
				role = "pred1"
			},
			["food2"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 100,
				name = "tree_water_10_metal",
				area = 2,
				role = "food2",
				maxInRadius = 9
			},
			["prey2"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 2,
				role = "prey2"
			},
			["pred2"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_gull"] = 5},
				radius = 500,
				name = "critter_gull",
				area = 2,
				role = "pred2"
			},
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 500,
				name = "tree_water_10_metal",
				area = 3,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 3,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_goldfish_big"] = 5},
				radius = 500,
				name = "critter_goldfish_big",
				area = 3,
				role = "pred1"
			},
			["food2"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 100,
				name = "tree_water_10_metal",
				area = 3,
				role = "food2",
				maxInRadius = 9
			},
			["prey2"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 3,
				role = "prey2"
			},
			["pred2"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_gull"] = 5},
				radius = 500,
				name = "critter_gull",
				area = 3,
				role = "pred2"
			},
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 500,
				name = "tree_water_10_metal",
				area = 4,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 4,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_goldfish_big"] = 5},
				radius = 500,
				name = "critter_goldfish_big",
				area = 4,
				role = "pred1"
			},
			["food2"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree_water_10_metal"] = 10},
				radius = 100,
				name = "tree_water_10_metal",
				area = 4,
				role = "food2",
				maxInRadius = 9
			},
			["prey2"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 500,
				name = "critter_goldfish",
				area = 4,
				role = "prey2"
			},
			["pred2"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_gull"] = 5},
				radius = 500,
				name = "critter_gull",
				area = 4,
				role = "pred2"
			},
		},
	},
	
	["allTrefoil"] = {
		[1] = {
			["food1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=4000} },
				unitNames 			= {["tree_5_metal"] = 50},
				radius 				= 100,
				area 				= 1,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_5_metal"
			},
			["prey1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=4000} },
				unitNames 			= {["critter_duck"] = 10},
				radius 				= 500,
				name 				= "critter_duck",
				role 				= "prey1",
				area				= 1
			},
			["pred1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=4000} },
				unitNames			= {["critter_gull"] = 2},
				radius 				= 500,
				name 				= "critter_gull",
				role 				= "pred1",
				area				= 1
			},
			["food2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=4000} },
				unitNames 			= {["tree_5_metal"] = 50},
				radius 				= 100,
				name 				= "tree_5_metal",												
				role 				= "food2",																		
				maxInRadius 		= 10,
				area				= 1
			},
			["prey2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=4000} },
				unitNames 			= {["critter_pinguin"] = 10},
				radius 				= 500,
				name 				= "critter_pinguin",
				role 				= "prey2",
				area				= 1
			},
			["pred2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=4000} },
				unitNames			= {["critter_ant"] = 2},
				radius 				= 5000,
				name 				= "critter_ant",
				role 				= "pred2",
				area				= 1
			},
		},
		[2] = {
			["food1"] = { 
				spawn				= {shape = "circle", dim = {x=2000, z=2600, r=1500} },
				unitNames 			= {["tree_5_metal"] = 10},
				radius 				= 100,
				area 				= 2,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_5_metal"
			},
			["prey1"] = { 
				spawn				= {shape = "circle", dim = {x=2000, z=2600, r=1500} },
				unitNames 			= {["critter_duck"] = 10},
				radius 				= 500,
				name 				= "critter_duck",
				role 				= "prey1",
				area				= 2
			},
			["pred1"] = { 
				spawn				= {shape = "circle", dim = {x=2000, z=2600, r=1500} },
				unitNames			= {["critter_gull"] = 2},
				radius 				= 500,
				name 				= "critter_gull",
				role 				= "pred1",
				area				= 2
			},
			["food2"] = { 
				spawn				= {shape = "circle", dim = {x=2000, z=2600, r=1500} },
				unitNames 			= {["tree_water_10_metal"] = 50},
				radius 				= 100,
				name 				= "tree_5_metal",												
				role 				= "food2",																		
				maxInRadius 		= 10,
				area				= 2
			},
			["prey2"] = { 
				spawn				= {shape = "circle", dim = {x=2000, z=2600, r=1500} },
				unitNames 			= {["critter_goldfish"] = 10},
				radius 				= 500,
				name 				= "critter_goldfish",
				role 				= "prey2",
				area				= 2
			},
			["pred2"] = { 
				spawn				= {shape = "circle", dim = {x=2000, z=2600, r=1500} },
				unitNames			= {["critter_goldfish_big"] = 2},
				radius 				= 500,
				name 				= "critter_goldfish_big",
				role 				= "pred2",
				area				= 2
			},
		},
		[3] = {
			["food1"] = { 
				spawn				= {shape = "circle", dim = {x=6000, z=2600, r=1500} },
				unitNames 			= {["tree_5_metal"] = 10},
				radius 				= 100,
				area 				= 3,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_5_metal"
			},
			["prey1"] = { 
				spawn				= {shape = "circle", dim = {x=6000, z=2600, r=1500} },
				unitNames 			= {["critter_duck"] = 10},
				radius 				= 500,
				name 				= "critter_duck",
				role 				= "prey1",
				area				= 3
			},
			["pred1"] = { 
				spawn				= {shape = "circle", dim = {x=6000, z=2600, r=1500} },
				unitNames			= {["critter_gull"] = 2},
				radius 				= 500,
				name 				= "critter_gull",
				role 				= "pred1",
				area				= 3
			},
			["food2"] = { 
				spawn				= {shape = "circle", dim = {x=6000, z=2600, r=1500} },
				unitNames 			= {["tree_water_10_metal"] = 50},
				radius 				= 100,
				name 				= "tree_5_metal",												
				role 				= "food2",																		
				maxInRadius 		= 10,
				area				= 3
			},
			["prey2"] = { 
				spawn				= {shape = "circle", dim = {x=6000, z=2600, r=1500} },
				unitNames 			= {["critter_goldfish"] = 10},
				radius 				= 500,
				name 				= "critter_goldfish",
				role 				= "prey2",
				area				= 3
			},
			["pred2"] = { 
				spawn				= {shape = "circle", dim = {x=6000, z=2600, r=1500} },
				unitNames			= {["critter_goldfish_big"] = 2},
				radius 				= 500,
				name 				= "critter_goldfish_big",
				role 				= "pred2",
				area				= 3
			},
		},
		[4] = {
			["food1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=6600, r=1500} },
				unitNames 			= {["tree_5_metal"] = 10},
				radius 				= 100,
				area 				= 4,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_5_metal"
			},
			["prey1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=6600, r=1500} },
				unitNames 			= {["critter_duck"] = 10},
				radius 				= 500,
				name 				= "critter_duck",
				role 				= "prey1",
				area				= 4
			},
			["pred1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=6600, r=1500} },
				unitNames			= {["critter_gull"] = 2},
				radius 				= 500,
				name 				= "critter_gull",
				role 				= "pred1",
				area				= 4
			},
			["food2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=6600, r=1500} },
				unitNames 			= {["tree_water_10_metal"] = 50},
				radius 				= 100,
				name 				= "tree_5_metal",												
				role 				= "food2",																		
				maxInRadius 		= 10,
				area				= 4
			},
			["prey2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=6600, r=1500} },
				unitNames 			= {["critter_goldfish"] = 10},
				radius 				= 500,
				name 				= "critter_goldfish",
				role 				= "prey2",
				area				= 4
			},
			["pred2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=6600, r=1500} },
				unitNames			= {["critter_goldfish_big"] = 2},
				radius 				= 500,
				name 				= "critter_goldfish_big",
				role 				= "pred2",
				area				= 4
			},
		},
	},

}

return wildlifeConfig