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

}

return critterConfig