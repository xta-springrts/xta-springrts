local Sections = {
	{
		label		= "Graphics",
		name 		= "graphics"
	},
	
	{
		label		= "Sounds",
		name 		= "sound"
	},
	
	{
		label		= "Interface",
		name 		= "interface"
	},
	
	{
		label		= "Reports",
		name 		= "reports",
	},
	
	{
		label		= "Widgets",
		name 		= "widgets",
	},

	{
		label		= "Presets",
		name 		= "presets",
	},
	
}

local Presets = {
	{
			label = "Minimal",
			desc  = "Best for smooth operation",
			desc2 = "Disables heavy stuff",
			
			widgets = {
				"Widget Selector",
				"Defense Range",
				"MexUpg Helper",
				"HealthBars",
				"Ally Resource Bars - XTA",
				"BuildETA - XTA",
				"Changelog Info",
				"Cloak Fire State",
				"Commands info",
				"Don't Shoot",
				"Keybind/Mouse Info",
				"Mousecursors - XTA",
				"Autoquit",
				"Customkeys",
				"DGun Stall Assist",
				"DontMove - XTA",
				"Easy Facing",
				"Energy Conversion Info",
				"Energy overview",
				"FactoryGuard - XTA",
				"Fix drawmode-stuck",
				"Force cloak",
				"Highlight Geos",
				"Holdfire Fix",
				"ImmobileBuilder",
				"Nuke Button",
				"Pause Screen - XTA",
				"Point Tracker",
				"ReclaimInfo - XTA",
				"RelativeMinimap",
				"Simple menu",
				"SmartAreaReclaim",
				"Specific Unit Reclaimer",
				"State Reverse Toggle",
				"Volume OSD",
				"Z Selector",
				"Hide commands",
				"Stockpiler (dynamic) - XTA",
				"Attack AoE",
				"Commander visual warning",
				"Findunit",
				"Start Point Remover - XTA",
				"Prospector - XTA",
				"XTA Unit sounds",
				"Commander Name Tags",
				"AllyCursors",
				"Anti Ranges",
				"Area guard XTA",
				"Unit Count Indicator",
				"Select n Center! - XTA",
				"CustomFormations2",
				"Commander Change",
				"Fleas GUI",
				"Initial Queue - XTA",
				"Metalspot Finder",
				"Mission UI",
				"No Water Shadows",
				"replay buttons",
			},
		
			settings = {
				{Spring.SendCommands,"hardwarecursor 0"},
				{Spring.SendCommands,"info 1"},
				{Spring.SendCommands,"Shadows 0"},
				{Spring.SendCommands,"AdvMapShading 0"},
				{Spring.SendCommands,"AdvModelShading 0"},
				{Spring.SendCommands,"aoe-ballistic 0"},
				{Spring.SendCommands,"water 0"},
				{Spring.SetConfigInt,"XTA_MenuIconsX",3},
				{Spring.SetConfigInt,"XTA_MenuIconsY",8},
			},
			
			image = "luaui/images/options/minimal.png",
	},
	
	{
			label = "Default",
			desc  = "XTA layout",
			desc2  = "Uses default widgets",
			
			widgets = {
				"Widget Selector",
				"Deferred rendering",
				"Defense Range",
				"Red_UI_Framework",
				"MexUpg Helper",
				"Red Tooltip",
				"HealthBars",
				"XTA Layout",
				"Red Minimap",
				"Ally Resource Bars - XTA",
				"AdvPlayersList - XTA",
				"BuildETA - XTA",
				"Changelog Info",
				"Cloak Fire State",
				"Commands info",
				"Don't Shoot",
				"Keybind/Mouse Info",
				"Mousecursors - XTA",
				"Autoquit",
				"BuildBar - XTA",
				"CameraShake",
				"Customkeys",
				"DGun Stall Assist",
				"DontMove - XTA",
				"Easy Facing",
				"Energy Conversion Info",
				"Energy overview",
				"FactoryGuard - XTA",
				"Fix drawmode-stuck",
				"Ghost Radar",
				"Force cloak",
				"Ghost Site",
				"Highlight Geos",
				"Holdfire Fix",
				"ImmobileBuilder",
				"Mex Snap",
				"Nuke Button",
				"Pause Screen - XTA",
				"Point Tracker",
				"ReclaimInfo - XTA",
				"Red Console",
				"Red_Drawing",
				"Red Resource Bars",
				"SelectionButtons",
				"Simple menu",
				"SmartAreaReclaim",
				"Specific Unit Reclaimer",
				"State Reverse Toggle",
				"UnitGroups v5.1 - XTA",
				"Volume OSD",
				"Stockpiler (dynamic) - XTA",
				"Z Selector",
				"RelativeMinimap",
				"Start Point Remover - XTA",
				"Attack AoE",
				"Commander visual warning",
				"Desync warning",
				"Findunit",
				"Prospector - XTA",
				"XTA Unit sounds",
				"Commander Name Tags",
				"AllyCursors",
				"Anti Ranges",
				"BA Waypoint Dragger",
				"Area guard XTA",
				"LupsManager",
				"Smoke Signal",
				"Unit Count Indicator",
				"Units on Fire",
				"Lups",
				"CustomFormations2",
				"Select n Center! - XTA",
				"Commander Change",
				"Fleas GUI",
				"Initial Queue - XTA",
				"Metalspot Finder",
				"Mission UI",
				"No Water Shadows",
				"replay buttons",
			},
		
			settings = {
				{Spring.SendCommands,"hardwarecursor 1"},
				{Spring.SendCommands,"info 0"},
				{Spring.SendCommands,"Shadows 1"},
				{Spring.SendCommands,"AdvMapShading 1"},
				{Spring.SendCommands,"AdvModelShading 1"},
				{Spring.SendCommands,"aoe-ballistic 0"},
				{Spring.SendCommands,"water 0"},
				{Spring.SetConfigInt,"XTA_MenuIconsX",4},
				{Spring.SetConfigInt,"XTA_MenuIconsY",8},
			},
			
			image = "luaui/images/options/default.png",
			
	},
	
	{
			label = "Badger settings",
			desc  = "Modern, uses more GPU",
			desc2  = "Employs Red TM stuff",
			
			widgets = {
				"Widget Selector",
				"Deferred rendering",
				"Defense Range",
				"Red_UI_Framework",
				"MexUpg Helper",
				"Red Tooltip",
				"HealthBars",
				"Ally Resource Bars - XTA",
				"AdvPlayersList - XTA",
				"BuildETA - XTA",
				"Changelog Info",
				"Cloak Fire State",
				"Commands info",
				"Don't Shoot",
				"Keybind/Mouse Info",
				"Mousecursors - XTA",
				"Autoquit",
				"CameraShake",
				"Customkeys",
				"DGun Stall Assist",
				"DontMove - XTA",
				"Easy Facing",
				"Ecostats",
				"Energy Conversion Info",
				"Energy overview",
				"FactoryGuard - XTA",
				"Fix drawmode-stuck",
				"Ghost Radar",
				"Force cloak",
				"Ghost Site",
				"Highlight Geos",
				"Holdfire Fix",
				"ImmobileBuilder",
				"Nuke Button",
				"Pause Screen - XTA",
				"Point Tracker",
				"ReclaimInfo - XTA",
				"RelativeMinimap",
				"Simple menu",
				"SmartAreaReclaim",
				"Specific Unit Reclaimer",
				"State Reverse Toggle",
				"Volume OSD",
				"Z Selector",
				"Hide commands",
				"Stockpiler (dynamic) - XTA",
				"Red_Drawing",
				"Red Build/Order Menu",
				"Red Console",
				"Red Resource Bars",
				"Red Minimap",
				"Attack AoE",
				"Commander visual warning",
				"Desync warning",
				"Findunit",
				"Start Point Remover - XTA",
				"Prospector - XTA",
				"XTA Unit sounds",
				"Commander Name Tags",
				"AllyCursors",
				"Anti Ranges",
				"Area guard XTA",
				"LupsManager",
				"Smoke Signal",
				"Unit Count Indicator",
				"Select n Center! - XTA",
				"Units on Fire",
				"Lups",
				"CustomFormations2",
				"Commander Change",
				"Fleas GUI",
				"Initial Queue - XTA",
				"Metalspot Finder",
				"Mission UI",
				"No Water Shadows",
				"replay buttons",
			},
		
			settings = {
			{Spring.SendCommands,"hardwarecursor 0"},
				{Spring.SendCommands,"info 0"},
				{Spring.SendCommands,"Shadows 1"},
				{Spring.SendCommands,"AdvMapShading 1"},
				{Spring.SendCommands,"AdvModelShading 1"},
				{Spring.SendCommands,"aoe-ballistic 1"},
				{Spring.SendCommands,"water 3"},
				{Spring.SetConfigInt,"XTA_MenuIconsX",4},
				{Spring.SetConfigInt,"XTA_MenuIconsY",8},
			},
			
			image = "luaui/images/options/badger.png",
			
	},
	
	{
			label = "Hawk settings",
			desc  = "Elegant, medium GPU cost",
			desc2  = "Uses Ctrlpanel improved",
			
			widgets = {
			"Widget Selector",
				"Deferred rendering",
				"Defense Range",
				"Red_UI_Framework",
				"MexUpg Helper",
				"Red Tooltip",
				"HealthBars",
				"Ally Resource Bars - XTA",
				"AdvPlayersList - XTA",
				"BuildETA - XTA",
				"Changelog Info",
				"Cloak Fire State",
				"CtrlPanel Improved",
				"Red Minimap",
				"Commands info",
				"Don't Shoot",
				"Ecostats",
				"Keybind/Mouse Info",
				"Mousecursors - XTA",
				"Autoquit",
				"Customkeys",
				"DGun Stall Assist",
				"DontMove - XTA",
				"Easy Facing",
				"Energy Conversion Info",
				"Energy overview",
				"FactoryGuard - XTA",
				"Fix drawmode-stuck",
				"Ghost Radar",
				"Force cloak",
				"Ghost Site",
				"Highlight Geos",
				"Holdfire Fix",
				"ImmobileBuilder",
				"Nuke Button",
				"Pause Screen - XTA",
				"Point Tracker",
				"ReclaimInfo - XTA",
				"RelativeMinimap",
				"Simple menu",
				"SmartAreaReclaim",
				"Specific Unit Reclaimer",
				"State Reverse Toggle",
				"Volume OSD",
				"Z Selector",
				"Hide commands",
				"Stockpiler (dynamic) - XTA",
				"Red_Drawing",
				"Red Console",
				"Red Resource Bars",
				"Attack AoE",
				"Commander visual warning",
				"Findunit",
				"Start Point Remover - XTA",
				"Prospector - XTA",
				"XTA Unit sounds",
				"Commander Name Tags",
				"AllyCursors",
				"Anti Ranges",
				"Area guard XTA",
				"LupsManager",
				"Smoke Signal",
				"Unit Count Indicator",
				"Select n Center! - XTA",
				"Units on Fire",
				"Lups",
				"CustomFormations2",
				"Commander Change",
				"Fleas GUI",
				"Initial Queue - XTA",
				"Metalspot Finder",
				"Mission UI",
				"No Water Shadows",
				"replay buttons",
			},
		
			settings = {
				{Spring.SendCommands,"hardwarecursor 1"},
				{Spring.SendCommands,"info 0"},
				{Spring.SendCommands,"Shadows 1"},
				{Spring.SendCommands,"AdvMapShading 1"},
				{Spring.SendCommands,"AdvModelShading 1"},
				{Spring.SendCommands,"aoe-ballistic 0"},
				{Spring.SetConfigInt,"XTA_MenuIconsX",3},
				{Spring.SetConfigInt,"XTA_MenuIconsY",10},
			},
			
			image = "luaui/images/options/hawk.png",
			
	},

}	
-- 		Legend:
--		This table works quite like modoptions table, but with some modifications.
--		"key" value is not really used yet, but it's included in case a specific entry needs to be isolated
--		"label" is what shows up in the menu in the settings widget
--		"value" is the default value to display when menu is opened. In case of checkbox it's true or false, in
--				case of a scale option it's numerical
--		"section" is under which tab the option is displayed. Sections are defined on top of this file
--		"action" is the commands to run when the option button is clicked. 
--		"deaction" is a silly word but is the commands to be run when the options button is clicked and the value becomes false
--				(only used for checkboxes)
--				Special format of the "action" field:
--				First field should be a function
--				Second field can be a name, or a name with a value. If there are only two fields, the second field is
--				supplied as an argument to the first. So it can toggle a function or send a value.
--				Third field is needed if the function in first field takes two arguments, like eg
--					Spring.SetConfigInt("GrassDetail",0)
--					The special value -1 can be used to supply the value of the option together with the name in field 2,
--					like eg "Spring.SendCommands,"comnametagsize",-1" sends the command 
--						Spring.SendCommands("comnametagsize" .. " " .. <value>) 
--					that is, one argument as a string
--				Another special thing to know is that supplying only 2 fields, if a value is needed, it is automatically 
--				supplied from the option value. The special value -2 can also be used for this.


local Buttons = {
	
	-- ORDERED BY SECTION
	-- graphics
	
	{
	key				= "MapShading",				
	label			= "Advanced map shading:",
	value			= tonumber(Spring.GetConfigInt("AdvMapShading",1) or 1) == 1,
	section			= "graphics",
	action			= {Spring.SendCommands,"AdvMapShading 1"},
	deaction		= {Spring.SendCommands,"AdvMapShading 0"},
	
	},
		
	{
	key				= "UnitShading",				
	label			= "Advanced unit shading:",
	value			= tonumber(Spring.GetConfigInt("AdvModelShading",1) or 1) == 1,
	section			= "graphics",
	action			= {Spring.SendCommands,"AdvModelShading 1"},
	deaction		= {Spring.SendCommands,"AdvModelShading 0"}, 
	},
	
	{
	key				= "Shadows", 
	value			= tonumber(Spring.GetConfigInt("Shadows",1) or 1) == 1,
	label			= "Shadows:",
	section			= "graphics",
	action			= {Spring.SendCommands,"Shadows 1"},
	deaction		= {Spring.SendCommands,"Shadows 0"},
	},
	
	{
	key				= "hardwareCursor", 
	value			= tonumber(Spring.GetConfigInt("hardwareCursor",1) or 1) == 1,
	label			= "Hardware-cursor:",
	section			= "graphics",
	action			= {Spring.SendCommands,"hardwarecursor 1"},
	deaction		= {Spring.SendCommands,"hardwarecursor 0"}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1,
	key 			= "fullscreen",
	label			= "Full screen:",
	section			= "graphics",
	action			= {Spring.SendCommands,"fullscreen 1"},
	deaction		= {Spring.SendCommands,"fullscreen 0"}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("GrassDetail",1) or 1) == 1,
	key 			= "grass",
	label			= "Show grass on maps:",
	section			= "graphics",
	action			= {Spring.SetConfigInt,"GrassDetail",1},
	deaction		= {Spring.SetConfigInt,"GrassDetail",0}, 
	},
	
	{
	key				= "water",				
	label			= "Water type:",
	value			= tonumber(Spring.GetConfigInt("ReflectiveWater",1)) or 0,
	section			= "graphics",
	type 			= "scale",
	min				= 0,
	max				= 4,
	step			= 1,
	items			= {	
						[0] ="Basic",
						[1]="Reflective",
						[2]="Dynamic",
						[3]="Reflective & refractive",
						[4]="Bumpmapped",
					  },
	action			= {Spring.SendCommands,"water",-1},
	},
	
	-- sound
	
	{
	key				= "sndmaster",				
	label			= "Master volume:",
	value			= tonumber(Spring.GetConfigInt("snd_volmaster",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_volmaster"},
	},
	
	{
	key				= "sndgeneral",				
	label			= "General type sounds:",
	value			= tonumber(Spring.GetConfigInt("snd_volgeneral",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_volgeneral"},
	},
	
	{
	key				= "sndbattle",				
	label			= "Battle sounds:",
	value			= tonumber(Spring.GetConfigInt("snd_volbattle",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_volbattle"},
	},
	
	{
	key				= "sndunitreply",				
	label			= "Unit reply sounds:",
	value			= tonumber(Spring.GetConfigInt("snd_volunitreply",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_volunitreply"},
	},
	
	{
	key				= "sndui",				
	label			= "User interface sounds:",
	value			= tonumber(Spring.GetConfigInt("snd_volui",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_volui"},
	},
	
	{
	key				= "sndmusic",				
	label			= "Music volume:",
	value			= tonumber(Spring.GetConfigInt("snd_volmusic",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_volmusic"},
	},
	
	{
	key				= "PauseMusic", 
	value			= (not WG.disablePauseMusic) or false,
	label			= "Pause music:",
	section			= "sound",
	action			= {Spring.SendCommands,"pausemusic"},
	deaction		= {Spring.SendCommands,"pausemusic"},
	},
	
	{
	key				= "introMusic", 
	value			= tonumber(Spring.GetConfigInt('snd_intromusic',0) or 0) == 1,
	label			= "Intro music:",
	section			= "sound",
	action			= {Spring.SetConfigInt, 'snd_intromusic', 1},
	deaction		= {Spring.SetConfigInt, 'snd_intromusic', 0}, 
	},
	
	{
	key				= "endMusic", 
	value			= tonumber(Spring.GetConfigInt('snd_endmusic',0) or 0) == 1,
	label			= "End music:",
	section			= "sound",
	action			= {Spring.SetConfigInt,'snd_endmusic', 1},
	deaction		= {Spring.SetConfigInt,'snd_endmusic', 0}, 
	},
	
	-- interface
			
	{
	key				= "menuiconsx",				
	label			= "Build menu - number of columns:",
	value			= tonumber(Spring.GetConfigInt("XTA_MenuIconsX")) or 4,
	section			= "interface",
	type 			= "scale",
	min				= 2,
	max				= 8,
	step			= 1,
	items			= {	
						[4] ="Default",
						[8]="Max",
					  },
	action			= {Spring.SetConfigInt,"XTA_MenuIconsX"},
	reloadwidgets	= {"Red Build/Order Menu","CtrlPanel Improved","XTA Layout","Red Minimap"},
	},
	
	{
	key				= "menuiconsy",				
	label			= "Build menu - number of rows:",
	value			= tonumber(Spring.GetConfigInt("XTA_MenuIconsY")) or 8,
	section			= "interface",
	type 			= "scale",
	min				= 3,
	max				= 16,
	step			= 1,
	items			= {	
						[8] ="Default",
						[16]="Max",
					  },
	action			= {Spring.SetConfigInt,"XTA_MenuIconsY"},
	reloadwidgets	= {"Red Build/Order Menu","CtrlPanel Improved","XTA Layout"},
	},
	
	{
	key				= "ordermenuiconsy",				
	label			= "Order menu - number of rows:",
	value			= tonumber(Spring.GetConfigInt("XTA_OrderMenuIconsY")) or 4,
	section			= "interface",
	type 			= "scale",
	min				= 2,
	max				= 6,
	step			= 1,
	items			= {	
						[4] ="Default",
						[6]="Max",
					  },
	action			= {Spring.SetConfigInt,"XTA_OrderMenuIconsY"},
	reloadwidgets	= {"Red Build/Order Menu","CtrlPanel Improved","XTA Layout"},
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("XTA_ShowNoobButtons",1) or 1) == 1,
	key 			= "noob-buttons",
	label			= "Build menu - show newbie buttons:",
	section			= "interface",
	action			= {Spring.SetConfigInt,"XTA_ShowNoobButtons",1},
	deaction		= {Spring.SetConfigInt,"XTA_ShowNoobButtons",0}, 
	reloadwidgets	= {"Red Build/Order Menu","CtrlPanel Improved","XTA Layout"},
	},
	
	{
	key				= "showFPS", 
	value			= tonumber(Spring.GetConfigInt("ShowFPS",1) or 1) == 1,
	label			= "Show fps indicator:",
	section			= "interface",
	action			= {Spring.SendCommands,"fps 1"},
	deaction		= {Spring.SendCommands,"fps 0"}, 
	},
	
	{
	key 			= "showTime",
	value			= tonumber(Spring.GetConfigInt("ShowClock",1) or 1) == 1,
	label			= "Show game time:",
	section			= "interface",
	action			= {Spring.SendCommands,"clock 1"},
	deaction		= {Spring.SendCommands,"clock 0"}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("ShowSpeed",0) or 0) == 1,
	key 			= "showSpeed",
	label			= "Show game speed:",
	section			= "interface",
	action			= {Spring.SendCommands,"speed 1"},
	deaction		= {Spring.SendCommands,"speed 0"}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("ShowPlayerInfo",0) or 0) == 1,
	key 			= "showInfo",
	label			= "Show simple player infotable:",
	section			= "interface",
	action			= {Spring.SendCommands,"info 1"},
	deaction		= {Spring.SendCommands,"info 0"}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("XTA_EngineGraphFirst") or 0) == 1,
	key 			= "XTA_EngineGraphFirst",
	label			= "Show engine graph first:",
	section			= "interface",
	action			= {Spring.SetConfigInt,"XTA_EngineGraphFirst",1},
	deaction		= {Spring.SetConfigInt,"XTA_EngineGraphFirst",0}, 
	},
		
	{
	value			= tonumber(Spring.GetConfigInt("XTA_CommandHelpText",1) or 1) == 1,
	key 			= "help",
	label			= "Show interface help text:",
	section			= "interface",
	action			= {Spring.SetConfigInt,"XTA_CommandHelpText",1},
	deaction		= {Spring.SetConfigInt,"XTA_CommandHelpText",0}, 
	},
		
	{
	key				= "opacity",				
	label			= "GUI opacity:",
	value			= tonumber(Spring.GetConfigString("GuiOpacity","0.7")) or 0.2,
	section			= "interface",
	type 			= "scale",
	min				= 0,
	max				= 1,
	step			= 0.1,
	items			= {	
						[0.0] ="Transparent",
						[0.2]="XTA default",
						[0.5]="Medium",
						[0.7]="Spring default",
						[1.0]="Opaque",
					  },
	action			= {Spring.SendCommands,"SetGuiOpacity",-1},
	},
	
	-- reports
	
	{
	value			= tonumber(Spring.GetConfigInt("XTA_DisableMoveFailedSound",0) or 0) == 1,
	key				= "disableMoveFailed",
	label			= "Disable move-failed unit reply sound:",
	section			= "reports",
	action			= {Spring.SetConfigInt,"XTA_DisableMoveFailedSound",1},
	deaction		= {Spring.SetConfigInt,"XTA_DisableMoveFailedSound",0}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("XTA_DisableMoveFailedText",0) or 0) == 1,
	key 			= "disableMoveFailedText",
	label			= "Disable move-failed unit reply text:",
	section			= "reports",
	action			= {Spring.SetConfigInt,"XTA_DisableMoveFailedText",1},
	deaction		= {Spring.SetConfigInt,"XTA_DisableMoveFailedText",0}, 
	},
	
	
	
	{
	value			= tonumber(Spring.GetConfigInt("TeamHighlight",1) or 1) == 1,
	key 			= "blinking",
	label			= "Blinking units:",
	section			= "reports",
	action			= {Spring.SendCommands,"teamhighlight 1"},
	deaction		= {Spring.SendCommands,"teamhighlight 0"}, 
	},
	
	-- widgets
		
	{
	value			= tonumber(Spring.GetConfigInt("XTA_ShowBallisticTraces") or 0) == 1,
	key 			= "ballistic",
	label			= "Attack-AoE: show ballistic traces (can be expensive)",
	section			= "widgets",
	action			= {Spring.SendCommands,"aoe-ballistic"},
	deaction		= {Spring.SendCommands,"aoe-ballistic"},
	},
	
	{
	value			= WG.nameScaling or false,
	key 			= "scale-names",
	label			= "Commander nametags: scale names to zoom-level:",
	section			= "widgets",
	action			= {Spring.SendCommands,"comnamescale"},
	deaction		= {Spring.SendCommands,"comnamescale"}, 
	},
	
	{
	value			= WG.fontShadow or false,
	key 			= "nameshadow",
	label			= "Commander nametags: draw shadow around commander names:",
	section			= "widgets",
	action			= {Spring.SendCommands,"comnameshadow"},
	deaction		= {Spring.SendCommands,"comnameshadow"}, 
	},
	
	{
	value			= WG.cpuText or false,
	key 			= "cputext",
	label			= "Adv. playerslist: show CPU-usage as text",
	section			= "widgets",
	action			= {Spring.SendCommands,"cputext"},
	deaction		= {Spring.SendCommands,"cputext"}, 
	},
	
	{
	key				= "comnametagsize",				
	label			= "Commander nametags: font size",
	value			= WG.commNameTagFontSize or 12,
	section			= "widgets",
	type 			= "scale",
	min				= 4,
	max				= 20,
	step			= 1,
	items			= {	
						[4] ="Minimal",
						[6]="Small",
						[10]="Normal",
						[12]="Big",
						[14]="Large",
						[16]="Larger",
						[20]="Huge",
					  },
	action			= {Spring.SendCommands,"comnametagsize",-1},
	},
}

return Buttons, Sections, Presets