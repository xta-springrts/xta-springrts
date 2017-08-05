local rnd = math.random
local critterConfig = {


["Tropical"] = {
[1] = {
		["prey"] = { spawnCircle = {x=4600, z=5200, r=3500}, unitNames = {["critter_duck"]=20} },
		["pred"] = { spawnCircle = {x=4600, z=5200, r=3500}, unitNames = {["critter_gull"]=10} },
	},

[2] = {
		["prey"] = { spawnCircle = {x=4600, z=5200, r=500}, unitNames = {["critter_duck"]=5} },
		["pred"] = { spawnCircle = {x=4600, z=5200, r=500}, unitNames = {["critter_gull"]=5} },
	},
},

["trefoil"] = {
[1] = {
		["prey"] = { spawnBox = {x1=5666, z1=4888, x2=8000, z2=6400}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=5666, z1=4888, x2=8000, z2=6400}, unitNames = {["critter_goldfish_big"]=10} },
	},
[2] = {
		["prey"] = { spawnBox = {x1=3400, z1=300, x2=5000, z2=1500}, unitNames = {["critter_goldfish"]=10} },
		["pred"] = { spawnBox = {x1=3400, z1=300, x2=5000, z2=1500}, unitNames = {["critter_goldfish_big"]=10} },
	},
},

}

return critterConfig