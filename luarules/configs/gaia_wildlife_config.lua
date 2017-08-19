local rnd = math.random

-- See for more information the gadged

-- INSTRUCTIONS --
-- EASY

-- All roles: food1, food2, prey1, ... should be specified to work (fix later)
-- To have an easy squer area copy the setup of Lowland_Crossing_TNM01-V4 and change numbers.
-- to have an easy circle area copy Trefoil_v2. (these setups only uses one area with 3 roles(6 max))
-- notice that these setups set food, prey2 and pred2 number to spawn to zero (leaving this out fails)

-- HARD
-- Many setups are possible with many different area on one map with alot of species.
-- To see the full options used see example.. (TODO)
-- 

-- WARNING
-- The hard part misses some optional settings which very hard to set manually 
-- Mainly because theymight break the gadged functioning 
-- 


-- ADVISE FOR USE
-- when radius (trees) is chosen large the amount of wildlife in restricted. (good for small maps)
-- As a side effect the likelihood that trees wander around the map is higher. (not packed together)
-- Radius incrementals for predators and preys make them much more effective
-- (TODO) finish this list

-- manual

-- FOR ALL ROLES NECESSARY
-- spawn					shape and dim for spawming
-- unitNames				unitName and spawmned number
-- area						if more than 1 keep counting
-- name						unitName
-- role						food1, food2, prey1, prey2, pred1 or pred2 (food1 is for trees that grow (steady))

-- OPTIONAL FOR ALL ROLES
-- (TODO) finish this

-- OPTIONAL FOR ROLE SPECIFIC
-- (TODO) finish this
--

local wildlifeConfig = {

--[[


	["LakeDay_v1"] = {
		[1] = {
			["food1"] = { 
				spawn				= {shape = "circle", dim = {x=750, z=750, r=500} }, -- radius units get spawn 	(NECESSARY)
				unitNames 			= {["tree"] = 20},									-- unit name				(NECESSARY)
				name 				= "tree",											-- name 					(NECESSARY)
				area 				= 1,												-- area						(NECESSARY))
				role 				= "food1",											-- role						(NECESSARY)							
				--maxLifespan 		= 20 * evolveTimePace,								--(default) understand before changing 
				--procreateLifespan 	= 20 * evolveTimePace,								--(default) understand before changing 
				maxInRadius 		= 9,												--(default) 
				procreatSucces		= 0.7,												--(default)
				radius 				= 100												--(default)radius trees expand		
			},
			["prey1"] = { 
				spawn				= {shape = "circle", dim = {x=750, z=750, r=500} },
				unitNames 			= {["critter_duck"] = 10},
				name 				= "critter_duck",
				area 				= 1,
				role 				= "prey1",
				maxInRadius			= 30,												--(default)
				procreatSucces		= 0.4,												--(default)
				radius 				= 200												--(default)
			},
			["pred1"] 				= { 
				spawn				= {shape = "circle", dim = {x=750, z=750, r=500} },
				unitNames			= {["critter_gull"] = 10},
				name 				= "critter_gull",
				area 				= 1,
				role 				= "pred1",
				maxInRadius 		= 30,												--(default)
				procreatSucces		= 0.4,												--(default)
				predationSucces		= 0.7,												--(default)
				radius 				= 200												--(default)
			},
			["food2"] = { 
				spawn				= {shape = "circle", dim = {x=750, z=750, r=500} }, -- radius units get spawn 	(NECESSARY)
				unitNames 			= {["tree"] = 0},									-- unit name				(NECESSARY)
				name 				= "tree",											-- name 					(NECESSARY)
				area 				= 1,												-- area						(NECESSARY))
				role 				= "food2",											-- role						(NECESSARY)							
				--maxLifespan 		= 20 * evolveTimePace,								--(default) understand before changing 
				--procreateLifespan 	= 20 * evolveTimePace,								--(default) understand before changing 
				maxInRadius 		= 9,												--(default) 
				procreatSucces		= 0.7,												--(default)
				radius 				= 100												--(default)radius trees expand		
			},
			["prey2"] = { 
				spawn				= {shape = "circle", dim = {x=750, z=750, r=500} },
				unitNames 			= {["critter_duck"] = 0},
				name 				= "critter_duck",
				area 				= 1,
				role 				= "prey2",
				maxInRadius			= 30,												--(default)
				procreatSucces		= 0.4,												--(default)
				radius 				= 200												--(default)
			},
			["pred2"] 				= { 
				spawn				= {shape = "circle", dim = {x=750, z=750, r=500} },
				unitNames			= {["critter_gull"] = 0},
				name 				= "critter_gull",
				area 				= 1,
				role 				= "pred2",
				maxInRadius 		= 30,												--(default)
				procreatSucces		= 0.4,												--(default)
				predationSucces		= 0.7,												--(default)
				radius 				= 200												--(default)
			},
		},
		[2] = {
			["food1"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["tree"] = 30},
				radius = 100,
				name = "tree",
				area = 2,
				role = "food1",
				maxInRadius = 9
			},
			["prey1"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["critter_goldfish"] = 20},
				radius = 500,
				name = "critter_goldfish",
				area = 2,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["critter_goldfish_big"] = 10},
				radius = 500,
				name = "critter_goldfish_big",
				area = 2,
				role = "pred1"
			},
			["food2"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["tree"] = 30},
				radius = 100,
				name = "tree",
				area = 2,
				role = "food2",
				maxInRadius = 9
			},
			["prey2"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["critter_goldfish"] = 20},
				radius = 500,
				name = "critter_goldfish",
				area = 2,
				role = "prey2"
			},
			["pred2"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["critter_goldfish_big"] = 10},
				radius = 500,
				name = "critter_goldfish_big",
				area = 2,
				role = "pred2"
			},
		},
		]]--
		--[[
		[3] = {
			["food1"] = { 
				spawn= {shape = "circle", dim = {x=3238, z=746, r=500} },
				unitNames = {["tree"] = 5},
				radius = 300,
				name = "tree",
				area = 3,
				role = "food1",
				maxInRadius = 9
			},
			["prey1"] = { 
				spawn= {shape = "circle", dim = {x=3238, z=746, r=500} },
				unitNames = {["critter_duck"] = 2},
				radius = 300,
				name = "critter_duck",
				area = 3,
				role = "prey1"
			},
			["pred1"] = { 
				spawn= {shape = "circle", dim = {x=3238, z=746, r=500} },
				unitNames = {["critter_gull"] = 1},
				radius = 300,
				name = "critter_gull",
				area = 3,
				role = "pred1"
			},
		},
		[4] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=3222, z=3348, r=500} },
				unitNames = {["tree"] = 2},
				radius = 200,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "circle", dim = {x=3222, z=3348, r=500} },
				unitNames = {["critter_duck"] = 1},
				radius = 300,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "circle", dim = {x=3222, z=3348, r=500} },
				unitNames = {["critter_gull"] = 1},
				radius = 300,
				name = "critter_gull"
			},
		},
		[6] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=720, z=3477, r=500} },
				unitNames = {["tree"] = 2},
				radius = 200,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "circle", dim = {x=720, z=3477, r=500} },
				unitNames = {["critter_duck"] = 1},
				radius = 300,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "circle", dim = {x=720, z=3477, r=500} },
				unitNames = {["critter_gull"] = 1},
				radius = 300,
				name = "critter_gull"
			},
		},
		[7] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=2000, z=2000, r=2000} },
				unitNames = {["tree"] = 40},
				radius = 1000,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "circle", dim = {x=2000, z=2000, r=2000} },
				unitNames = {["critter_duck"] = 10},
				radius = 500,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "circle", dim = {x=2000, z=2000, r=2000} },
				unitNames = {["critter_gull"] = 2},
				radius = 500,
				name = "critter_gull"
			},
		},
	},
 ]]--
	["Lowland_Crossing_TNM01-V4"] = {
		[1] = {
			["food1"] = { 
				spawn				= {shape = "box", dim = {x1=500, z1=500, x2=2500, z2=3500} },
				unitNames 			= {["tree"] = 10},
				radius 				= 1000,
				area 				= 1,												
				role 				= "food1",																		
				maxInRadius 		= 9,
				name				= "tree"
			},
			["prey1"] = { 
				spawn				= {shape = "box", dim = {x1=500, z1=500, x2=2500, z2=3500} },
				unitNames 			= {["critter_duck"] = 5},
				radius 				= 600,
				name 				= "critter_duck",
				role 				= "prey1",
				area				= 1
			},
			["pred1"] = { 
				spawn				= {shape = "box", dim = {x1=500, z1=500, x2=2500, z2=3500} },
				unitNames			= {["critter_gull"] = 1},
				radius 				= 600,
				name 				= "critter_gull",
				role 				= "pred1",
				area				= 1
			},
			["food2"] = { 
				spawn				= {shape = "box", dim = {x1=500, z1=500, x2=2500, z2=3500} },
				unitNames 			= {["tree"] = 0},
				radius 				= 1000,
				name 				= "tree",												
				role 				= "food2",																		
				maxInRadius 		= 9,
				area				= 1
			},
			["prey2"] = { 
				spawn				= {shape = "box", dim = {x1=500, z1=500, x2=2500, z2=3500} },
				unitNames 			= {["critter_duck"] = 0},
				radius 				= 600,
				name 				= "critter_duck",
				role 				= "prey2",
				area				= 1
			},
			["pred2"] = { 
				spawn				= {shape = "box", dim = {x1=500, z1=500, x2=2500, z2=3500} },
				unitNames			= {["critter_gull"] = 0},
				radius 				= 600,
				name 				= "critter_gull",
				role 				= "pred2",
				area				= 1
			},
		},
	},
	

	["Trefoil_v2"] = {
		[1] = {
			["food1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames 			= {["tree"] = 30},
				radius 				= 200,
				area 				= 1,												
				role 				= "food1",																		
				maxInRadius 		= 3,
				name				= "tree"
			},
			["prey1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames 			= {["critter_duck"] = 10},
				radius 				= 1000,
				name 				= "critter_duck",
				role 				= "prey1",
				area				= 1
			},
			["pred1"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames			= {["critter_gull"] = 1},
				radius 				= 1000,
				name 				= "critter_gull",
				role 				= "pred1",
				area				= 1
			},
			["food2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames 			= {["tree"] = 0},
				radius 				= 100,
				name 				= "tree",												
				role 				= "food2",																		
				maxInRadius 		= 9,
				area				= 1
			},
			["prey2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames 			= {["critter_duck"] = 0},
				radius 				= 750,
				name 				= "critter_duck",
				role 				= "prey2",
				area				= 1
			},
			["pred2"] = { 
				spawn				= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames			= {["critter_gull"] = 0},
				radius 				= 1000,
				name 				= "critter_gull",
				role 				= "pred2",
				area				= 1
			},
		},
	},
	
		--[[

	["Tropical"] = {
		[1] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=800, z1=750, x2=8400, z2=9505} },
				unitNames = {["tree"] = 50},
				radius = 100,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "box", dim = {x1=800, z1=750, x2=8400, z2=9505} },
				unitNames = {["critter_duck"] = 20},
				radius = 1000,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "box", dim = {x1=800, z1=750, x2=8400, z2=9505} },
				unitNames = {["critter_gull"] = 5},
				radius = 2000,
				name = "critter_gull"
			},
		},
		[2] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2=9200, z2=750} },
				unitNames = {["tree"] = 10},
				radius = 100,
				name = "tree"
				},
			["prey"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2=9200, z2=750} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 750,
				name = "critter_goldfish"
				},
			["pred"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=0, x2=9200, z2=750} },
				unitNames = {["critter_goldfish_big"] = 2},
				radius = 750,
				name = "critter_goldfish_big"
			},
		},
		[3] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=9505, x2=9200, z2=10200} },
				unitNames = {["tree"] = 10},
				radius = 100,
				name = "tree"
				},
			["prey"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=9505, x2=9200, z2=10200} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 750,
				name = "critter_goldfish"
				},
			["pred"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=9505, x2=9200, z2=10200} },
				unitNames = {["critter_goldfish_big"] = 2},
				radius = 750,
				name = "critter_goldfish_big"
			},
		},
		[4] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=750, x2=800, z2=9505} },
				unitNames = {["tree"] = 10},
				radius = 100,
				name = "tree"
				},
			["prey"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=750, x2=800, z2=9505} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 750,
				name = "critter_goldfish"
				},
			["pred"] = { 
				spawn= {shape = "box", dim = {x1=0, z1=750, x2=800, z2=9505} },
				unitNames = {["critter_goldfish_big"] = 2},
				radius = 750,
				name = "critter_goldfish_big"
			},
		},
		[5] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=8400, z1=750, x2=9200, z2=9505} },
				unitNames = {["tree"] = 10},
				radius = 100,
				name = "tree"
				},
			["prey"] = { 
				spawn= {shape = "box", dim = {x1=8400, z1=750, x2=9200, z2=9505} },
				unitNames = {["critter_goldfish"] = 10},
				radius = 750,
				name = "critter_goldfish"
				},
			["pred"] = { 
				spawn= {shape = "box", dim = {x1=8400, z1=750, x2=9200, z2=9505} },
				unitNames = {["critter_goldfish_big"] = 2},
				radius = 750,
				name = "critter_goldfish_big"
			},
		},
	},
	
	["WidePass Fineto"] = {
		[1] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=1500, z=1500, r=1500} },
				unitNames = {["tree_energy"] = 50},
				radius = 300,
				name = "tree_energy"
			},
		},
		[2] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=1500, z=9000, r=1500} },
				unitNames = {["tree_energy"] = 50},
				radius = 300,
				name = "tree_energy"
			},
		},
		[3] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=4500, z=9000, r=1500} },
				unitNames = {["tree_energy"] = 50},
				radius = 300,
				name = "tree_energy"
			},
		},
		[4] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=4500, z=1500, r=1500} },
				unitNames = {["tree_energy"] = 50},
				radius = 300,
				name = "tree_energy"
			},
		},
		[5] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=2450, z1=2300, x2=3906, z2=7928} },
				unitNames = {["tree_energy"] = 50},
				radius = 300,
				name = "tree_energy"
			},
		},
	},
--]]

}

return wildlifeConfig