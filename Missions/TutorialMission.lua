spawnData = {
	map = "Altair_Crossing_v3",
	teams = {
		[0] = {
			arm_commander = {460,2000,1},
			arm_energy_storage = {420,1700,0},
			arm_metal_storage = {300,1700,0},
		},
		[1] = {
			core_commander = {3760,2018,3},
			core_energy_storage = {3820,2400,0}
		},
	}
}

missionTriggers = {
	[0] = {
		{
			conditions = {
				"Always",
			},
			actions = {
				"Echo First thing to do is to build 3 metal extractors on the nearby spots",
			},
			once = true,
		},
		{	
			conditions = {
				"Ctrl 3 arm_metal_extractor",
			},
			actions = {
				"Echo Good. Now you should build 2 solar collectors",
			},
			once = true,
		},
		{	
			conditions = {
				"Ctrl 3 arm_metal_extractor",
				"Ctrl 2 arm_solar_collector",
			},
			actions = {
				"Echo Good. Now build a Kbot lab",
			},
			once = true,
		},
		{	
			conditions = {
				"Ctrl 3 arm_metal_extractor",
				"Ctrl 2 arm_solar_collector",
				"Ctrl 1 arm_kbot_lab",
			},
			actions = {
				"Echo Good. Select your Kbot lab and queue 5 Peewees. Left click to queue by one, Shift+Click for queuing 5 at the time",
				"Echo Ctrl+Click for 20 and Shift+Ctrl+Click for 100 at the time. Right click for removing queued units",
			},
			once = true,
		},
		{	
			conditions = {
				"Ctrl 3 arm_metal_extractor",
				"Ctrl 2 arm_solar_collector",
				"Ctrl 1 arm_kbot_lab",
				"Ctrl 5 arm_peewee",
			},
			actions = {
				"Echo Great, now you have 5 basic attack units, go kick some robot arse, the enemy should be on the center right side of the map",
			},
			once = true,
		},
	},
}

locations = {
}

return spawnData, missionTriggers, locations