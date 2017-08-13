local rnd = math.random
local wildlifeConfig = {

-- The number of trees that are spawned in a radius is set to 9 by default. (adjustable in gadged)
-- The radius on prey determine there foraging distance to available food. (same for pred-> prey dist.)
-- Set units at start on different places on the map which get respawn after possible extinction
-- For full settings see gadged
-- TODO maybe add number of trees spawned in radius as parameters here later


	["LakeDay_v1"] = {
		[1] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=750, z=750, r=500} }, 		-- radius units get spawn
				unitNames = {["tree"] = 2},										-- unit name
				radius = 100,													-- radius trees expand
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "circle", dim = {x=750, z=750, r=500} },
				unitNames = {["critter_duck"] = 1},
				radius = 200,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "circle", dim = {x=750, z=750, r=500} },
				unitNames = {["critter_gull"] = 1},
				radius = 200,
				name = "critter_gull"
			},
		},
		[2] = {
			["food"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["tree"] = 20},
				radius = 100,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["critter_goldfish"] = 5},
				radius = 500,
				name = "critter_goldfish"
			},
			["pred"] = { 
				spawn= {shape = "box", dim = {x1=1150, z1=1500, x2=3550, z2=2700} },
				unitNames = {["critter_goldfish_big"] = 1},
				radius = 500,
				name = "critter_goldfish_big"
			},
		},
		[3] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=3238, z=746, r=500} },
				unitNames = {["tree"] = 2},
				radius = 200,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "circle", dim = {x=3238, z=746, r=500} },
				unitNames = {["critter_duck"] = 1},
				radius = 300,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "circle", dim = {x=3238, z=746, r=500} },
				unitNames = {["critter_gull"] = 1},
				radius = 300,
				name = "critter_gull"
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


	["Trefoil_v2"] = {
		[1] = {
			["food"] = { 
				spawn= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames = {["tree"] = 30},
				radius = 100,
				name = "tree"
			},
			["prey"] = { 
				spawn= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames = {["critter_duck"] = 10},
				radius = 750,
				name = "critter_duck"
			},
			["pred"] = { 
				spawn= {shape = "circle", dim = {x=4000, z=4000, r=3000} },
				unitNames = {["critter_gull"] = 1},
				radius = 1000,
				name = "critter_gull"
			},
		},
	},	

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


}

return wildlifeConfig