local rnd = math.random
local critterConfig = {
--

["Tropical"] = {
[1] = {
		["prey"] = { spawnCircle = {x=4600, z=5200, r=3500}, unitNames = {["critter_duck"]=20}, predRadius = 900 },
		["pred"] = { spawnCircle = {x=4600, z=5200, r=3500}, unitNames = {["critter_gull"]=10} },
	},
[2] = {
		["prey"] = { spawnCircle = {x=4600, z=5200, r=500}, unitNames = {["critter_duck"]=5}, predRadius = 900 },
		["pred"] = { spawnCircle = {x=4600, z=5200, r=500}, unitNames = {["critter_gull"]=5} },
	},
},

["Trefoil_v2"] = {
[1] = {
		["prey"] = { spawnBox = {x1=0, z1=4200, x2=2000, z2=8000}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=0, z1=4200, x2=2000, z2=8000}, unitNames = {["critter_goldfish_big"]=10}, predRadius = 450  },
	},
[2] = {
		["prey"] = { spawnBox = {x1=7000, z1=0, x2=8000, z2=2000}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=7000, z1=0, x2=8000, z2=2000}, unitNames = {["critter_goldfish_big"]=10}, predRadius = 450  },
	},
[3] = {
		["prey"] = { spawnBox = {x1=6000, z1=4200, x2=8000, z2=8000}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=6000, z1=4200, x2=8000, z2=8000}, unitNames = {["critter_goldfish_big"]=10}, predRadius = 450  },
	},
[4] = {
		["prey"] = { spawnBox = {x1=0, z1=0, x2=1400, z2=1800}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=0, z1=0, x2=1400, z2=1800}, unitNames = {["critter_goldfish_big"]=10}, predRadius = 900  },
	},
[5] = {
		["prey"] = { spawnCircle = {x=4000, z=1000, r=900}, unitNames = {["critter_goldfish"]=5} },
		["pred"] = { spawnCircle = {x=4000, z=1000, r=900}, unitNames = {["critter_goldfish_big"]=5}, predRadius = 900 },
	},
[6] = {
		["prey"] = { spawnBox = {x1=2000, z1=7400, x2=6000, z2=8000}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=2000, z1=7400, x2=6000, z2=8000}, unitNames = {["critter_goldfish_big"]=10}, predRadius = 900  },
	},
[7] = {
		["prey"] = { spawnCircle = {x=4000, z=4000, r=1500}, unitNames = {["critter_duck"]=5} },
		["pred"] = { spawnCircle = {x=4000, z=4000, r=1500}, unitNames = {["critter_gull"]=5}, predRadius = 900  },
	},
},

}

return critterConfig