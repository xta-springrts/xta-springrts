--[[  Help on Sounds.lua syntax from springcontent template
	ExampleSound  = {
		--- some things you can do with this file

		--- can be either ogg or wav
		file  = "somedir/subdir/soundfile.ogg",

		--- loudness, > 1 is louder, < 1  is more quiet, you will most likely not set it to 0
		gain  = 1,

		--- > 1 -> high pitched, < 1 lowered
		pitch  = 1,

		--- If > 0.0 then this adds a random amount to gain each time the sound is played.
		--- Clamped between 0.0 and 1.0. The result is in the range [(gain * (1 + gainMod)), (gain * (1 - gainMod))].
		gainmod  = 0.0,

		--- If > 0.0 then this adds a random amount to pitch each time the sound is played.
		--- Clamped between 0.0 and 1.0. The result is in the range [(pitch * (1 + pitchMod)), (pitch * (1 - pitchMod))].
		pitchmod  = 0.0,

		--- how unit / camera speed affects the sound, to exagerate it, use values > 1
		--- dopplerscale  = 0 completely disables the effect
		dopplerscale  = 1,

		--- when lots of sounds are played, sounds with lower priority are more likely to get cut off
		--- priority > 0 will never be cut of (priorities can be negative)
		priority  = 0,

		--- this sound will not be played more than 16 times at a time
		maxconcurrent  = 16,

		--- cutoff distance
		maxdist  = 20000,

		--- how fast it becomes more quiet in the distance (0 means aleays the same loudness regardless of dist)
		rolloff  = 1,

		--- non-3d sounds do always came out of the front-speakers (or the center one)
		--- 3d sounds are, well, in 3d
		in3d  = true,

		--- you can loop it for X miliseconds
		looptime  = 0,
	}
--]]

local Exceptions = {
		["fleabossattack.wav"] 	= true,
		["count1.wav"]			= true,
		["count2.wav"]			= true,
		["count3.wav"]			= true,
		["count4.wav"]			= true,
		["count5.wav"]			= true,
		["count6.wav"]			= true,
		["tllcount.wav"]		= true,
		["cancel1.wav"]			= true,
		["cancel2.wav"]			= true,
	}
	

local Sounds  = {
	SoundItems  = {
		IncomingChat  = {
			file  = "sounds/gui/beep4.wav",
			in3d  = "false",
		},
		MultiSelect  = {
			file  = "sounds/gui/button9.wav",
			in3d  = "false",
		},
		MapPoint  = {
			file  = "sounds/gui/beep6.wav",
			rolloff  = 0,
			dopplerscale  = 0,       
		},
		FailedCommand  = {
			file  = "sounds/unit/cantdo4.wav",       
		},
		
		-- default  = { -- has undesired effects
		-- new since 89.0
		-- you can overwrite the fallback profile here (used when no corresponding SoundItem is defined for a sound)
		-- gainmod  = 0.2,
		-- pitchmod  = 0.3,
		-- in3d  = true,
		-- maxconcurrent  = 16,
		-- rolloff  = 0.4,
		-- },
	
		--[[ Has undesired effects
		default  = {
			--- new since 89.0
			--- you can overwrite the fallback profile here (used when no corresponding SoundItem is defined for a sound)
			gainmod  = 0.15,
			pitchmod  = 0.1,
		},
		--]]
		silence  = {
			file  = "sounds/silence.wav",
			maxconcurrent  = 1,
			dopplerscale  = 0,
			priority  = -1,
		},
		-- dgun explosion sound, normally plays every frame
		-- because dgun projectiles are ground-hugging and
		-- collide with it for each frame of their lifetime
		--  = => limit concurrency to prevent resonance
   },
}

local Echo  = Spring.Echo
local files, t		

files  = VFS.DirList("sounds/gui")
t  = Sounds.SoundItems
for i =1,#files do
	local fileName  = files[i]
	local _,endchar = fileName:find("gui/")
	local shortName = fileName:sub(endchar+1)	
	--Echo("GUI sound:", fileName, shortName)
	
	if fileName:find('victory1') then --victory sound
		t[fileName]  	= {
		file     	 	= fileName;
		pitchmod  		= 0.0;
		gainmod  		= 0;
		gain  			= 5;
		maxconcurrent  	= 1;
		rolloff  		= 0;
		priority 		= 10;
		in3d 			= 0;
		}
	elseif fileName:find('button10.wav') then --build queue sound
		--Echo("Button 10 found",fileName, shortName)
		
		t[fileName] = {
		file      		= fileName;
		pitchmod  		= 0.0;
		gainmod   		= 0;
		gain  			= 0.5;
		maxconcurrent  	= 1;
		rolloff  		= 0;
		priority  		= -1;
		in3d 			= 0;
		}
	else
	t[fileName] = {
		file      		= fileName;
		pitchmod  		= 0.0;
		gainmod   		= 0;
		gain  			= 1;
		maxconcurrent  	= 4;
		rolloff  		= 0;
		priority  		= 1;
		in3d 			= 0;
		}	
	end
end
	
	
files  = VFS.DirList("sounds/battle")
t  = Sounds.SoundItems

for i =1,#files do
	local fileName  = files[i]
	--Echo("Explosion sound:",fileName)
	
	if fileName:find('xplomas2dgun.wav') or fileName:find('lostdgunhit.wav') then --DGUN sound
		t[fileName]  = {
		file      = fileName;
		gainmod   = 0.1;
		gain  = 1;
		rolloff  = 0.4;
		maxconcurrent  = 1;
		pitchmod  = 0.05;
		maxdist  = 5000;
		priority  = 3;
		}
	elseif fileName:find('sizzle.wav') then --DGUN water sound
		t[fileName]  = {
		file      = fileName;
		gainmod   = 0.1;
		gain  = 1;
		rolloff  = 0.4;
		maxconcurrent  = 1;
		pitchmod  = 0.05;
		maxdist  = 5000;
		priority  = -1;
		}
	elseif fileName:find('disigun1.wav') then -- DGUN start sound
		t[fileName]  = {
		file      = fileName;
		gainmod   = 0.1;
		gain  = 1;
		rolloff  = 0.1;
		maxconcurrent  = 8;
		pitchmod  = 0.05;
		maxdist  = 10000;
		priority  = 10;
		}
	else	
		t[fileName]  = {
			file      		= fileName;
			pitchmod  		= 0.1;
			gainmod   		= 0.2;
			gain  			= 1;
			maxconcurrent  	= 16;
			rolloff  		= 0.4;
		}
	end
end

files  = VFS.DirList("sounds/unit")
t  = Sounds.SoundItems

for i =1,#files do
	local fileName  = files[i]
	--Echo("Unit sound:",fileName)	
	
	local startChar,endChar = fileName:find("unit/")
	local shortName = fileName:sub(endChar+1)
	
	if fileName:find('sing.wav') or fileName:find('sing2.wav') or fileName:find('honk.wav') or fileName:find('honk2.wav') then 	--sing/honk sounds
		t[fileName]  = {
		file      		= fileName;
		pitchmod 		= 0.1;
		gainmod			= 0.2;
		gain  			= 1;
		maxconcurrent  	= 8;
		rolloff  		= 0;
		priority  		= -1;
		in3d 			= 0;
		}
	else
		if not Exceptions[shortName] then
			t[fileName]  = {
			file      		= fileName;
			pitchmod  		= 0.3;
			gainmod   		= 0.2;
			gain  			= 1;
			maxconcurrent  	= 16;
			rolloff  		= 0.4;
			priority  		= -3;
			}
		else
			Echo("Exception:",shortName)
			t[fileName]  = {
			file      		= fileName;
			pitchmod  		= 0;
			gainmod   		= 0;
			gain  			= 1;
			maxconcurrent  	= 1;
			rolloff  		= 0;
			priority  		= 1;
			in3d 			= 0;
			}
		end
		
	end
end
--files  = VFS.DirList("sounds/music")
-- t  = Sounds.SoundItems

-- for i =1,#files do
	-- local fileName  = files[i]
	-- Echo("Music sound:",fileName)	
	
	-- t[fileName]  = {
		-- file      		= fileName;
		-- pitchmod  		= 0.0;
		-- gainmod   		= 0.0;
		-- gain  			= 1;
		-- maxconcurrent  	= 2;
		-- rolloff  		= 0;
		-- priority  		= 1;
	-- }
-- end





-- add sounds located in luaui too as gui sounds
local uiFiles  = VFS.DirList("luaui/sounds")
local t  = Sounds.SoundItems
for i =1,#uiFiles do
	local fileName  = uiFiles[i]
	local startChar,endChar = string.find(fileName,"luaui/sounds/")
	local shortName = string.sub(fileName, endChar+1)
	
	t[fileName]  = {
	file      = fileName;
	pitchmod  = 0.0;
	gainmod   = 0;
	gain  = 1;
	maxconcurrent  = 1;
	rolloff  = 0;
	priority  = -1;
	in3d = 0;
	}
end

-- add sounds located in /glhf too as gui sounds:
local uiFiles  = VFS.DirList("sounds/glhf")
local t  = Sounds.SoundItems
for i =1,#uiFiles do
	local fileName  = uiFiles[i]
	local startChar,endChar = string.find(fileName,"sounds/glhf")
	local shortName = string.sub(fileName, endChar+1)
	--Echo("Filename:", fileName, shortName)
	t[fileName]  = {
	file      = fileName;
	pitchmod  = 0.1;
	gainmod   = 0;
	gain  = 1;
	maxconcurrent  = 4;
	rolloff  = 0;
	priority  = -1;
	in3d = 0;
	}
end
	
-- add sounds located in /commander too as gui sounds:	
local uiFiles  = VFS.DirList("sounds/commander")
local t  = Sounds.SoundItems
for i =1,#uiFiles do
	local fileName  = uiFiles[i]
	local startChar,endChar = string.find(fileName,"sounds/commander")
	local shortName = string.sub(fileName, endChar+1)
	--Echo("Filename:", fileName, shortName)
	t[fileName]  = {
	file      = fileName;
	pitchmod  = 0.05;
	gainmod   = 0;
	gain  = 1;
	maxconcurrent  = 4;
	rolloff  = 0;
	priority  = -1;
	in3d = 0;
	}	
end



for j, t in pairs(Sounds) do
	for i,v in pairs (t) do
		--Echo("SoundItem:",i,v)
		for u,x in pairs(v) do
			--Echo("SoundItem:", i, "Item:",u,x)
		end
	end
end

return Sounds
