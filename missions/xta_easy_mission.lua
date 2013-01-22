gameData = {
	map = "Red Comet",
	game = "XTA",
	minVersion = "9 SVN",
	nextMission = "XTA_long_sea_mission",
}

spawnData = {
	teams = {
		[0] = {
			{"arm_metal_extractor", 904, 3448, 0},
			{"arm_light_laser_tower", 688, 2576, 0},
			{"arm_metal_storage", 144, 3176, 0},
			{"arm_light_laser_tower", 1328, 4000, 0},
			{"arm_metal_extractor", 616, 3256, 0},
			{"arm_solar_collector", 296, 3256, 0},
			{"arm_energy_storage", 144, 3248, 0},
			{"arm_light_laser_tower", 1328, 3232, 0},
			{"arm_metal_extractor", 296, 2952, 0},
			{"arm_vehicle_plant", 496, 2992, 1},
			{"arm_light_laser_tower", 240, 2544, 0},
			{"arm_light_laser_tower", 1328, 3632, 0},
			{"arm_commander", 752, 3312, 0},
			{"arm_solar_collector", 296, 3176, 0},
			{"arm_light_laser_tower", 1168, 2784, 0},
		},
		[1] = {
			{"core_light_laser_tower", 5088, 1280, 3},
			{"core_light_laser_tower", 5888, 1616, 3},
			{"core_light_laser_tower", 4816, 528, 3},
			{"core_light_laser_tower", 4816, 896, 3},
			{"core_light_laser_tower", 5488, 1536, 3},
			{"core_vehicle_plant", 5648, 1040, 3},
			{"core_metal_storage", 5920, 616, 1},
			{"core_metal_extractor", 5224, 664, 1},
			{"core_light_laser_tower", 4816, 160, 3},
			{"core_energy_storage", 5920, 688, 1},
			{"core_metal_extractor", 5496, 872, 1},
			{"core_solar_collector", 5928, 856, 1},
			{"core_solar_collector", 5848, 856, 1},
			{"core_commander", 5296, 928, 1},
			{"core_metal_extractor", 5848, 1144, 1},
		},
	},
	features = {
	}
}

missionTriggers = {
	[0] = {
		{
			conditions = {
				"Death 1 arm_commander",
			},
			actions = {
				"Defeat",
			},
			once = true,
		},
		{
			conditions = {
				"Kill 1 core_commander",
			},
			actions = {
				"Bonus arm_commander 0",
				"Victory",
			},
			once = true,
		},
	}
}

locations = {
}

briefing = {
	"$cFirst engagement",
	"",
	"",
	"Commander, congratulations on your promotion. This will be your first assignment and your final exam.",
	"",
	"Your mission is to clear all CORE forces from this sector. CORE has a small base in northeast which shouldn't",
	"pose a serious challenge. Intel says enemy commander is a n00b straight from the academy. Don't fail us or",
	"you're demoted to infantry.",
	"",
	"$rARM Central Command",
}

return gameData, spawnData, missionTriggers, locations, briefing