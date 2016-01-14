local Sections = {
	{
		label		= "Graphics",
		name 		= "graphics"
	},
	
	{
		label		= "Sound",
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
	

local Buttons = {
	
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
	key				= "sndbattle",				
	label			= "Battle volume:",
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
	key				= "sndunitreply",				
	label			= "Unit reply volume:",
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
	key				= "sndgeneral",				
	label			= "General volume:",
	value			= tonumber(Spring.GetConfigInt("snd_general",50)),
	section			= "sound",
	type 			= "scale",
	min				= 0,
	max				= 100,
	step			= 1,
	items			= {	
						[0] ="Muted",
						[100] = "Ear breaking",
					  },
	action			= {Spring.SetConfigInt,"snd_general"},
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
	
	{
	key				= "showFPS", 
	value			= tonumber(Spring.GetConfigInt("ShowFPS",1) or 1) == 1,
	label			= "Show fps indicator:",
	section			= "interface",
	action			= {Spring.SendCommands,"fps 0"},
	deaction		= {Spring.SendCommands,"fps 1"}, 
	},
	
	{
	key 			= "showTime",
	value			= tonumber(Spring.GetConfigInt("ShowClock",1) or 1) == 1,
	label			= "Show game time:",
	section			= "interface",
	action			= {Spring.SendCommands,"clock 0"},
	deaction		= {Spring.SendCommands,"clock 1"}, 
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
	value			= tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1,
	key 			= "fullscreen",
	label			= "Full screen:",
	section			= "graphics",
	action			= {Spring.SendCommands,"fullscreen 1"},
	deaction		= {Spring.SendCommands,"fullscreen 0"}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("TeamHighlight",1) or 1) == 1,
	key 			= "blinking",
	label			= "Blinking units:",
	section			= "reports",
	action			= {Spring.SendCommands,"teamhighlight 1"},
	deaction		= {Spring.SendCommands,"teamhighlight 0"}, 
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
	value			= tonumber(Spring.GetConfigInt("XTA_CommandHelpText",1) or 1) == 1,
	key 			= "help",
	label			= "Show interface help text:",
	section			= "interface",
	action			= {Spring.SetConfigInt,"XTA_CommandHelpText",1},
	deaction		= {Spring.SetConfigInt,"XTA_CommandHelpText",0}, 
	},
	
	{
	value			= tonumber(Spring.GetConfigInt("XTA_ShowNoobButtons",1) or 1) == 1,
	key 			= "noob-buttons",
	label			= "Show noob-buttons in order menu:",
	section			= "interface",
	action			= {Spring.SetConfigInt,"XTA_ShowNoobButtons",1},
	deaction		= {Spring.SetConfigInt,"XTA_ShowNoobButtons",0}, 
	},
	
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
	value			= not (WG.fontShadow or false),
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
	
	
	
}

return Buttons, Sections