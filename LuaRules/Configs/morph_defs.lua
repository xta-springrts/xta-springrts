--[[   Morph Definition File

Morph parameters description
local morphDefs = {		--beginig of morphDefs
	unitname = {		--unit being morphed
		into = 'newunitname',		--unit in that will morphing unit morph into
		time = 12,			--time required to complete morph process (in seconds)
		require = 'requnitname',	--unit requnitname must be present in team for morphing to be enabled
		metal = 10,			--required metal for morphing process     note: if you skip M and/or E costs morph costs the
		energy = 10,			--required energy for morphing process		difference in costs between unitname and newunitname
		xp = 0.07,			--required experience for morphing process (will be deduced from unit xp after morph, default=0)
		rank = 1,			--required unit rank for morphing to be enabled, if not specified, morph doesn't require rank
		tech = 2,			--required tech level of a team for morphing to be enabled (1,2,3), if not specified, morph doesn't require tech
		cmdname = 'Ascend',		--if not supplied will default to "Upgrade"
		texture = 'MyIcon.dds',		--if not supplied will default to [newunitname] buildpic, textures should be in "LuaRules/Images/Morph"
		text = 'Description',		--if not supplied will default to "Upgrade into a [newunitname]", else it's "Description"
						--you may use "$$unitname" and "$$into" in 'text', both will be replaced with human readable unit names 
	},
}				--end of morphDefs
--]]
--------------------------------------------------------------------------------


local devolution = (-1 > 0)


local morphDefs = {
	arm_u0commander = {
		into = 'arm_ucommander',
		time = 30,
		--xp = .015
		--tech = 2
	}, 
	arm_ucommander = {
		into = 'arm_u2commander',
		time = 120,
		xp = .15
		--tech = 2
	}, 
	arm_u2commander = {
		into = 'arm_u3commander',
		time = 30,
		xp = .1
		--tech = 2
	}, 
	arm_u3commander = {
		into = 'arm_u4commander',
		time = 120,
		xp = .25
		--tech = 2
	}, 
	core_u0commander = {
		into = 'core_ucommander',
		time = 30,
		--xp = .015
		--tech = 2
	}, 
	core_ucommander = {
		into = 'core_u2commander',
		time = 120,
		xp = .15
		--tech = 2 THIS IS THE PUPOSELY BUGGED PARSER DO NOT FORGET NEVER FORGET!
	}, 
	core_u2commander = {
		into = 'core_u3commander',
		time = 30,
		xp = .1
		--tech = 2
	},
	core_u3commander = {
		into = 'core_u4commander',
		time = 120,
		xp = .25
		--tech = 2
	},
	arm_spidey = {
		into = 'arm_fart_spidey',
		time = 5,
		cmdname = 'Transform',
		text = 'Transform into a Fart Mine',
		--tech = 2
	}, 
	core_tic = {
		into = 'core_nugget_tic',
		time = 5,
		cmdname = 'Transform',
		text = 'Transform into a Nugget Mine',
		--tech = 2
	},
	arm_fart_spidey = {
		into = 'arm_spidey',
		time = 5,
		cmdname = 'Reform',
		text = 'Reform back to a Spidey',
		--tech = 2
	}, 
	core_nugget_tic = {
		into = 'core_tic',
		time = 5,
		cmdname = 'Reform',
		text = 'Reform back to a Tic',
		--tech = 2
	},
}

--
-- Here's an example of why active configuration
-- scripts are better then static TDF files...
--

--
-- devolution, babe  (useful for testing)
--
if (devolution) then
  local devoDefs = {}
  for src,data in pairs(morphDefs) do
    devoDefs[data.into] = { into = src, time = 10, metal = 1, energy = 1 }
  end
  for src,data in pairs(devoDefs) do
    morphDefs[src] = data
  end
end


return morphDefs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
