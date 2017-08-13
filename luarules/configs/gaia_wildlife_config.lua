local rnd = math.random
local wildlifeConfig = {
["LakeDay_v1"] = {

[1] = {
		["food"] = { 
			spawn= {shape = "circle", dim = {x=750, z=750, r=500} },
			unitNames = {["tree"] = 2},
			radius = 100,
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


}

return wildlifeConfig