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

local Sounds  = {
	SoundItems  = {
		IncomingChat  = {
			file  = "sounds/beep4.wav",
			in3d  = "false",
		},
		MultiSelect  = {
			file  = "sounds/button9.wav",
			in3d  = "false",
		},
		MapPoint  = {
			file  = "sounds/beep6.wav",
			rolloff  = 0,
			dopplerscale  = 0,       
		},
		FailedCommand  = {
			file  = "sounds/cantdo4.wav",       
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

local explosionsList  = {
		'amphok1.wav',
		'amphsel1.wav' ,
		'amphstp1.wav',
		'anni.wav',
		'annigun1.wav',
		'armcom1.wav',
		'armcomgun.wav',
		'armcomhit.wav',
		'armsml2.wav',
		'armsml3.wav',
		'armsml4.wav',
		'bluemis.wav',
		'bluemishit.wav',
		'bombdropxx.wav',
		'bombrel.wav',
		'burn02.wav',
		'burn03.wav',
		'canlite2.wav',
		'canlite3.wav',
		'cannhvy1.wav',
		'cannhvy2.wav',
		'cannhvy3.wav',
		'cannhvy5.wav',
		'cannon1.wav',
		'cannon2.wav',
		'cannon3.wav',
		'coastalarty.wav',
		'comfire1.wav',
		'comfire2.wav',
		'corcomgun.wav',
		'depth3.wav',
		'disigun1.wav',
		'exmine1.wav',
		'exmine2.wav',
		'exmine3.wav',
		'exmine4.wav',
		'explode.wav',
		'explode2.wav',
		'flamhvy1.wav',
		'gunhuge.wav',
		'impact.wav',
		'ionbeam.wav',
		'largegun.wav',
		'laser.wav',
		'lasfirerb.wav',
		'lashit.wav',
		'lashit2.wav',
		'lasrfast.wav',
		'lasrfir1.wav',
		'lasrfir3.wav',
		'lasrhit1.wav',
		'lasrhit2.wav',
		'lasrhvy3.wav',
		'lasrlit1.wav',
		'lasrlit3.wav',
		'lasrlong.wav',
		'lasrmas2.wav',
		'lghthvy1.wav',
		'mavgun1.wav',
		'mavgun2.wav',
		'orcant.wav',
		'orcfire.wav',
		'orcua.wav',
		'order_firedeath.wav',
		'phaser.wav',
		'phofir00.wav',
		'ravenhvyrock.txt',
		'ravenhvyrock.wav',
		'rhinofire.wav',
		'rhinohit.wav',
		'rockethit.wav',
		'rockhit.wav',
		'rockhvy1.wav',
		'rockhvy2.wav',
		'rocklit1.wav',
		'rocklit3.wav',
		'sizzle.wav',
		'splshbig.wav',
		'splslrg.wav',
		'splsmed.wav',
		'splssml.old',
		'splssml.wav',
		'tigerrailgun1.wav',
		'tigerrailgun2.wav',
		'tllelechit.wav',
		'torpadv2.wav',
		'torpedo1.wav',
		'torpedo2.wav',
		'wasp1.wav',
		'wasp2.wav',
		'xplodep1.wav',
		'xplodep2.wav',
		'xplodep3.wav',
		'xplolrg1.wav',
		'xplolrg2.wav',
		'xplolrg3.wav',
		'xplolrg4.wav',
		'xplomas2.wav',
		'xplomed1.wav',
		'xplomed2.wav',
		'xplomed3.wav',
		'xplomed4.wav',
		'xplonuk1.wav',
		'xplonuk3.wav',
		'xplonuk4.wav',
		'xplosml1.wav',
		'xplosml2.wav',
		'xplosml3.wav',
		'xplosml4.wav',
		'xplosml6.wav',
		'xtanewnuke.wav'
		}

local guiList = {
		'beep1.wav',
		'beep4.wav',
		'beep6.wav',
		'bell.ogg',
		'button11.wav',
		'button9.wav',
		'cancel2.wav',
		'ding.wav',
		'honk.wav',
		'sing.wav',
		'sneer_mono.ogg',
		'ticktock.wav',
		'victory2.wav',
		'warning1.wav',
		'warning2.wav'
		}
		
local explosionSounds = {}
local guiSounds = {}

for i,snd in pairs(guiList) do
	guiSounds[snd] = true
end

for i,snd in pairs(explosionsList) do
	explosionSounds[snd] = true
end	
		
local files  = VFS.DirList("sounds/")
local t  = Sounds.SoundItems
for i =1,#files do
	local fileName  = files[i]
	local startChar,endChar = string.find(fileName,"sounds/")
	local shortName = string.sub(fileName, endChar+1)
	--Echo("Filename:", fileName, shortName)
	
	if guiSounds[shortName] then
		Echo("GUI sound:",shortName)
		t[fileName]  = {
		file      = fileName;
		pitchmod  = 0.0;
		gainmod   = 0;
		gain  = 1;
		maxconcurrent  = 32;
		rolloff  = 0;
		priority  = -1;
		in3d = 0;
		}
	elseif explosionSounds[shortName] then
		if shortname == 'xplomas2.wav' then --DGUN sound
			t[fileName]  = {
			file      = fileName;
			gainmod   = 0.2;
			gain  = 1;
			rolloff  = 0.4;
			maxconcurrent  = 1;
			pitchmod  = 0.05;
			maxdist  = 5000;
			priority  = -2;
			}
		else
		Echo("Explosion sound:",shortName)
		t[fileName]  = {
		file      = fileName;
		pitchmod  = 0.1;
		gainmod   = 0.2;
		gain  = 1;
		maxconcurrent  = 16;
		rolloff  = 0.4;
		}
		end
	else
		-- unitreply sounds
		Echo("Unitreply sound (assumed):",shortName)
		t[fileName]  = {
		file      = fileName;
		pitchmod  = 0.0;
		gainmod   = 0.0;
		gain  = 1;
		maxconcurrent  = 16;
		rolloff  = 0.4;
		priority  = -3;
		}
	end
end


--Echo("Sound files:")
--Echo("-------------")
local t  = Sounds.SoundItems
for i,v in pairs (t) do
	for u,x in pairs(v) do
		Echo("Index:", i, "Item:",u,x)
	end
end

return Sounds
