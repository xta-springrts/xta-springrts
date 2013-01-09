--[[  Help on Sounds.lua syntax from springcontent template
	ExampleSound = {
		--- some things you can do with this file

		--- can be either ogg or wav
		file = "somedir/subdir/soundfile.ogg",

		--- loudness, > 1 is louder, < 1  is more quiet, you will most likely not set it to 0
		gain = 1,

		--- > 1 -> high pitched, < 1 lowered
		pitch = 1,

		--- If > 0.0 then this adds a random amount to gain each time the sound is played.
		--- Clamped between 0.0 and 1.0. The result is in the range [(gain * (1 + gainMod)), (gain * (1 - gainMod))].
		gainmod = 0.0,

		--- If > 0.0 then this adds a random amount to pitch each time the sound is played.
		--- Clamped between 0.0 and 1.0. The result is in the range [(pitch * (1 + pitchMod)), (pitch * (1 - pitchMod))].
		pitchmod = 0.0,

		--- how unit / camera speed affects the sound, to exagerate it, use values > 1
		--- dopplerscale = 0 completely disables the effect
		dopplerscale = 1,

		--- when lots of sounds are played, sounds with lower priority are more likely to get cut off
		--- priority > 0 will never be cut of (priorities can be negative)
		priority = 0,

		--- this sound will not be played more than 16 times at a time
		maxconcurrent = 16,

		--- cutoff distance
		maxdist = 20000,

		--- how fast it becomes more quiet in the distance (0 means aleays the same loudness regardless of dist)
		rolloff = 1,

		--- non-3d sounds do always came out of the front-speakers (or the center one)
		--- 3d sounds are, well, in 3d
		in3d = true,

		--- you can loop it for X miliseconds
		looptime = 0,
	}
--]]


local Sounds = {
	SoundItems = {
		IncomingChat = {
			file = "sounds/beep4.wav",
			in3d = "false",
		},
		MultiSelect = {
			file = "sounds/button9.wav",
			in3d = "false",
		},
		MapPoint = {
			file = "sounds/beep6.wav",
			rolloff = 0,
			dopplerscale = 0,       
		},
		FailedCommand = {
			file = "sounds/cantdo4.wav",       
		},

		--[[ Has undesired effects
		default = {
			--- new since 89.0
			--- you can overwrite the fallback profile here (used when no corresponding SoundItem is defined for a sound)
			gainmod = 0.15,
			pitchmod = 0.1,
		},
		--]]
		silence = {
			file = "sounds/silence.wav",
			maxconcurrent = 1,
			dopplerscale = 0,
			priority = -1,
		},
		-- dgun explosion sound, normally plays every frame
		-- because dgun projectiles are ground-hugging and
		-- collide with it for each frame of their lifetime
		-- ==> limit concurrency to prevent resonance
		xplomas2 = {
			file = "sounds/xplomas2.wav",
			maxconcurrent = 4,
			pitchmod = 0.05,
			maxdist = 2000,
		}
   },
}

return Sounds
