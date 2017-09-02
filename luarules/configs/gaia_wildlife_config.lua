local rnd	= math.random
local floor = math.floor
--[[

FOR NOW ALL ROLES NEED TO BE DEVINED FOR EVERY AREA (HOPE FIX FAST :S)
See for more information the gadget

--------------------------------------- READ FIRST -----------------------------------

The units used need to have:
maxWaterDepth tag in unitdef
minWaterDepth tag in Unitdef
If used for food1 a non-mobile behavior (like trees because they will grow)

While all species (food1 till pred2) need to be specified, not all need to be present, meaning:
you can have just food1, prey1 and pred1 numbers with species2 all zeros for instance.
having only predators will result in extinction fast resulting in spamming ocassionally new units.
For now predators will eat both prey sources as will do prey with food sources. (maybe optionalized in future) 

--------------------------------------- INSTRUCTIONS (EASY) -----------------------------------
AGAIN all roles: food1, food2, prey1, ... should be specified to work (thats why i made some default settings):
notice that the model names for instance default tree for food1 need to be changed if preferable.

-- TREES ONLY
	*	A setting that will do with non reclaimable trees that will not overcrouwd small maps (free adjustable ofcourse)
		map is devided in four sectors which be respammed after extinction behavior per sector.
		USE: ["LakeDay_v1"] = "easyTreeSmallMap"
	*	A setting which allow some tree reclaiming withour overgrouding too much (again free adjustable ofcourse like all)
		four sectors with growing (reclaimable trees) forrest of trees grows a bit faster than non reclaiming setup.
		USE: ["LakeDay_v1"] = "easyTreeSmallMapReclaim"
	*	A setting for a food source that lifes in water as food1(growing) (can be changed to food2) used model is reclaimable.
		minWaterDepth and maxWaterDepth are set to allow only spawming trees is shallow water (adjust for all water etc..)
		USE: ["LakeDay_v1"] = "easyTreeSmallMapWater" 
	*	A setting for larger maps that spawns trees more close to each other
		The trees will die and reappear without overcrouwding the map (ofcourse changing maxWildlife wil give other behavior)
		Use ["Tropical"] = "easyTreeLargerMapGroupings"

-- TREE AND PREY
	*	spams trees and tree eating preys (CAN BE CPU EXPENSIVE) 
		Does a periodic oscilator behavior of number of trees and preys.
		USE: ["LakeDay_v1"] = "easyTreePrey" 

-- SPECIES1 (FOOD1, PREY1, PRED1)
	*	spams species1 (CAN BE CPU EXPENSIVE)
		USE: 
	
-- SPECIES2 (FOOD2, PREY2, PRED2)
	*	REMARK: FOOD2 IS ONLYTESTED IMMOBILE AND I THINKIT WORKS FOR NOW ONLY IMMOBILE          (TODO FIX)

-- WATER 
	*	A seeting for water maps (fish eat water trees and gull and big fish eat little fish)
		Non reclaimeble trees used in this setup
		USE: ["Ring Atoll Remake"] = "waterMap" (in this case the middle will have water energy trees but they can not be eaten by fish which dont like shallow waters)
-- ALL 
	*	Only setup for map trefoil HARDCODED map coordinates (notice that preditors can predate in other areas)
		Spawns 4 circles (3 on islands and 1 in middle little islands) all species are used
		USE: ["Trefoil_v2"] = "allTrefoil"

TODO
-- WATER
-- ISLANDS
-- MOUNTAINS
-- WATER/GROUND	
-- WATER
-- 3 species 1 area
-- 6 species 1 area
-- 3 species 4 area
-- 6 species 4 area
--etc	

--------------------------------------- INSTRUCTIONS (HARD) -----------------------------------

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
...
*
*	Contact me for some more nice rules to consider for doing a proper setup for this gadget to add here!!!

PARAMETERS THAT CAN BE USED FOR MANUALLY SET WILDLIFE BEHAVIORS
*	FOR ALL ROLES NECESSARY
	- spawn						shape and dim for spawming
	- unitNames					unitName and spawmned number
	- area						if more than 1 keep counting
	- name						unitName
	- role						food1, food2, prey1, prey2, pred1 or pred2 (food1 is for trees that grow (immobile))
*	OPTIONAL FOR ALL ROLES (default settings can be found in gadget)
	- radius					radius of procreation (food), foraging (prey) and predation (pred)
	- MaxInRadius				Determince the distance of offspring from parents, and limit food1 to procreate.
	- maxLifespan
	- procreateLifespan
	- procreatSucces
	- (TODO) 
	-

*	OPTIONAL FOR ROLE SPECIFIC (default settings can be found in gadget)
	- predationSucces
	- (TODO) 
	-
--]]


-- a help function to fill empty slots(see below for setups)
local function emptySlot(areaNumber, unitRole)
	
	local empty = {
		["food1"] = { 
			spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
			unitNames = {["tree"] = 0},
			radius = 300,
			name = "tree",
			area = areaNumber,
			role = "food1",
			maxInRadius = 3
		},
		["prey1"] = { 
			spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
			unitNames = {["critter_goldfish"] = 0},
			radius = 500,
			name = "critter_goldfish",
			area = areaNumber,
			role = "prey1"
		},
		["pred1"] = { 
			spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
			unitNames = {["critter_goldfish_big"] = 0},
			radius = 500,
			name = "critter_goldfish_big",
			area = areaNumber,
			role = "pred1"
		},
		["food2"] = { 
			spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
			unitNames = {["tree_energy"] = 0},
			radius = 100,
			name = "tree_energy",
			area = areaNumber,
			role = "food2",
			maxInRadius = 9
		},
		["prey2"] = { 
			spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
			unitNames = {["critter_duck"] = 0},
			radius = 500,
			name = "critter_duck",
			area = areaNumber,
			role = "prey2"
		},
		["pred2"] = { 
			spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
			unitNames = {["critter_pinguin"] = 0},
			radius = 500,
			name = "critter_pinguin",
			area = areaNumber,
			role = "pred2"
		},
	}
	
	return empty[unitRole]
	
end 


-- Wildlife setups
local wildlifeConfig = {

	["Lowland_Crossing_TNM01-V4"] = "species1", 

	["LakeDay_v1"] = "easyTreePrey",
	
	["WidePass Fineto"] = "easyTreeSmallMapReclaim",
	
	["Tropical"] = "easyTreeSmallMapGroupings",
	
	["Trefoil_v2"] = "allTrefoil",
	
	["Ring Atoll Remake"] = "waterMap",
	
	----------------------------------------------- default setups of wildlife -------------------------------------
	
	["easyTreeSmallMapGroupings"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_energy"] = 20},
				radius = 100,
				name = "tree_energy",
				area = 1,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(1, "prey1"),
			["pred1"] = emptySlot(1, "pred1"),
			["food2"] = emptySlot(1, "food2"),
			["prey2"] = emptySlot(1, "prey2"),
			["pred2"] = emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree_energy"] = 20},
				radius = 100,
				name = "tree_energy",
				area = 2,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(2, "prey1"),
			["pred1"] = emptySlot(2, "pred1"),
			["food2"] = emptySlot(2, "food2"),
			["prey2"] = emptySlot(2, "prey2"),
			["pred2"] = emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_energy"] = 20},
				radius = 100,
				name = "tree_energy",
				area = 3,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(3, "prey1"),
			["pred1"] = emptySlot(3, "pred1"),
			["food2"] = emptySlot(3, "food2"),
			["prey2"] = emptySlot(3, "prey2"),
			["pred2"] = emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree_energy"] = 20},
				radius = 100,
				name = "tree_energy",
				area = 4,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(4, "prey1"),
			["pred1"] = emptySlot(4, "pred1"),
			["food2"] = emptySlot(4, "food2"),
			["prey2"] = emptySlot(4, "prey2"),
			["pred2"] = emptySlot(4, "pred2"),
		},
	},
	
	["easyTreeSmallMap"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree"] = 20},
				radius = 300,
				name = "tree",
				area = 1,
				role = "food1",
				maxInRadius = 3
			},
			["prey1"] = emptySlot(1, "prey1"),
			["pred1"] = emptySlot(1, "pred1"),
			["food2"] = emptySlot(1, "food2"),
			["prey2"] = emptySlot(1, "prey2"),
			["pred2"] = emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree"] = 20},
				radius = 300,
				name = "tree",
				area = 2,
				role = "food1",
				maxInRadius = 3
			},
			["prey1"] = emptySlot(2, "prey1"),
			["pred1"] = emptySlot(2, "pred1"),
			["food2"] = emptySlot(2, "food2"),
			["prey2"] = emptySlot(2, "prey2"),
			["pred2"] = emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree"] = 20},
				radius = 300,
				name = "tree",
				area = 3,
				role = "food1",
				maxInRadius = 3
			},
			["prey1"] = emptySlot(3, "prey1"),
			["pred1"] = emptySlot(3, "pred1"),
			["food2"] = emptySlot(3, "food2"),
			["prey2"] = emptySlot(3, "prey2"),
			["pred2"] = emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree"] = 20},
				radius = 300,
				name = "tree",
				area = 4,
				role = "food1",
				maxInRadius = 3
			},
			["prey1"] = emptySlot(4, "prey1"),
			["pred1"] = emptySlot(4, "pred1"),
			["food2"] = emptySlot(4, "food2"),
			["prey2"] = emptySlot(4, "prey2"),
			["pred2"] = emptySlot(4, "pred2"),
		},
	},
	
	["easyTreeSmallMapReclaim"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_energy"] = 20},
				radius = 400,
				name = "tree_energy",
				area = 1,
				role = "food1",
				maxInRadius = 10
			},
						["prey1"] = emptySlot(1, "prey1"),
			["pred1"] = emptySlot(1, "pred1"),
			["food2"] = emptySlot(1, "food2"),
			["prey2"] = emptySlot(1, "prey2"),
			["pred2"] = emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree_energy"] = 20},
				radius = 400,
				name = "tree_energy",
				area = 2,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(2, "prey1"),
			["pred1"] = emptySlot(2, "pred1"),
			["food2"] = emptySlot(2, "food2"),
			["prey2"] = emptySlot(2, "prey2"),
			["pred2"] = emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_energy"] = 20},
				radius = 400,
				name = "tree_energy",
				area = 3,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(3, "prey1"),
			["pred1"] = emptySlot(3, "pred1"),
			["food2"] = emptySlot(3, "food2"),
			["prey2"] = emptySlot(3, "prey2"),
			["pred2"] = emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree_energy"] = 20},
				radius = 400,
				name = "tree_energy",
				area = 4,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(4, "prey1"),
			["pred1"] = emptySlot(4, "pred1"),
			["food2"] = emptySlot(4, "food2"),
			["prey2"] = emptySlot(4, "prey2"),
			["pred2"] = emptySlot(4, "pred2"),
		},
	},
	
	["easyTreeSmallMapWater"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water"] = 20},
				radius = 500,
				name = "tree_water",
				area = 1,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(1, "prey1"),
			["pred1"] = emptySlot(1, "pred1"),
			["food2"] = emptySlot(1, "food2"),
			["prey2"] = emptySlot(1, "prey2"),
			["pred2"] = emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree_water"] = 20},
				radius = 500,
				name = "tree_water",
				area = 2,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(2, "prey1"),
			["pred1"] = emptySlot(2, "pred1"),
			["food2"] = emptySlot(2, "food2"),
			["prey2"] = emptySlot(2, "prey2"),
			["pred2"] = emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water"] = 20},
				radius = 500,
				name = "tree_water",
				area = 3,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(3, "prey1"),
			["pred1"] = emptySlot(3, "pred1"),
			["food2"] = emptySlot(3, "food2"),
			["prey2"] = emptySlot(3, "prey2"),
			["pred2"] = emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree_water"] = 20},
				radius = 500,
				name = "tree_water",
				area = 4,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = emptySlot(4, "prey1"),
			["pred1"] = emptySlot(4, "pred1"),
			["food2"] = emptySlot(4, "food2"),
			["prey2"] = emptySlot(4, "prey2"),
			["pred2"] = emptySlot(4, "pred2"),
		},
	},
	
	["easyTreePrey"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree"] = 20},
				radius = 500,
				name = "tree",
				area = 1,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_duck"] = 10},
				radius = 500,
				name = "critter_duck",
				area = 1,
				role = "prey1"
			},
			["pred1"] = emptySlot(1, "pred1"),
			["food2"] = emptySlot(1, "food2"),
			["prey2"] = emptySlot(1, "prey2"),
			["pred2"] = emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree"] = 20},
				radius = 500,
				name = "tree",
				area = 2,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_duck"] = 10},
				radius = 500,
				name = "critter_duck",
				area = 2,
				role = "prey1"
			},
			["pred1"] = emptySlot(2, "pred1"),
			["food2"] = emptySlot(2, "food2"),
			["prey2"] = emptySlot(2, "prey2"),
			["pred2"] = emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree"] = 20},
				radius = 500,
				name = "tree",
				area = 3,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_duck"] = 10},
				radius = 500,
				name = "critter_duck",
				area = 3,
				role = "prey1"
			},
			["pred1"] = emptySlot(3, "pred1"),
			["food2"] = emptySlot(3, "food2"),
			["prey2"] = emptySlot(3, "prey2"),
			["pred2"] = emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree"] = 20},
				radius = 500,
				name = "tree",
				area = 4,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_duck"] = 10},
				radius = 500,
				name = "critter_duck",
				area = 4,
				role = "prey1"
			},
			["pred1"] = emptySlot(4, "pred1"),
			["food2"] = emptySlot(4, "food2"),
			["prey2"] = emptySlot(4, "prey2"),
			["pred2"] = emptySlot(4, "pred2"),
		},
	},
	
	["species1"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree"] = 10},
				radius = 500,
				name = "tree",
				area = 1,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_duck"] = 5},
				radius = 500,
				name = "critter_duck",
				area = 1,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_gull"] = 2},
				radius = 500,
				name = "critter_gull",
				area = 1,
				role = "pred1"
			},
			["food2"] = emptySlot(1, "food2"),
			["prey2"] = emptySlot(1, "prey2"),
			["pred2"] = emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["tree"] = 10},
				radius = 500,
				name = "tree",
				area = 2,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_duck"] = 5},
				radius = 500,
				name = "critter_duck",
				area = 2,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} },
				unitNames = {["critter_gull"] = 2},
				radius = 500,
				name = "critter_gull",
				area = 2,
				role = "pred1"
			},
			["food2"] = emptySlot(2, "food2"),
			["prey2"] = emptySlot(2, "prey2"),
			["pred2"] = emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["tree"] = 10},
				radius = 500,
				name = "tree",
				area = 3,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_duck"] = 5},
				radius = 500,
				name = "critter_duck",
				area = 3,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} },
				unitNames = {["critter_gull"] = 2},
				radius = 500,
				name = "critter_gull",
				area = 3,
				role = "pred1"
			},
			["food2"] = emptySlot(3, "food2"),
			["prey2"] = emptySlot(3, "prey2"),
			["pred2"] = emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["tree"] = 10},
				radius = 500,
				name = "tree",
				area = 4,
				role = "food1",
				maxInRadius = 10
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_duck"] = 5},
				radius = 500,
				name = "critter_duck",
				area = 4,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} },
				unitNames = {["critter_gull"] = 2},
				radius = 500,
				name = "critter_gull",
				area = 4,
				role = "pred1"
			},
			["food2"] = emptySlot(4, "food2"),
			["prey2"] = emptySlot(4, "prey2"),
			["pred2"] = emptySlot(4, "pred2"),
		},
	},
	
	["waterMap"] = {
		[1] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
				unitNames = {["tree_water"] = 10},
				radius = 500,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 100,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 500,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 100,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 500,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 100,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 500,
				name = "tree_water",
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
				unitNames = {["tree_water"] = 10},
				radius = 100,
				name = "tree_water",
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
				unitNames 			= {["tree_energy"] = 50},
				radius 				= 100,
				area 				= 1,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_energy"
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
				unitNames 			= {["tree_energy"] = 50},
				radius 				= 100,
				name 				= "tree_energy",												
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
				unitNames 			= {["tree_energy"] = 10},
				radius 				= 100,
				area 				= 2,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_energy"
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
				unitNames 			= {["tree_water"] = 50},
				radius 				= 100,
				name 				= "tree_energy",												
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
				unitNames 			= {["tree_energy"] = 10},
				radius 				= 100,
				area 				= 3,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_energy"
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
				unitNames 			= {["tree_water"] = 50},
				radius 				= 100,
				name 				= "tree_energy",												
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
				unitNames 			= {["tree_energy"] = 10},
				radius 				= 100,
				area 				= 4,												
				role 				= "food1",																		
				maxInRadius 		= 10,
				name				= "tree_energy"
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
				unitNames 			= {["tree_water"] = 50},
				radius 				= 100,
				name 				= "tree_energy",												
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