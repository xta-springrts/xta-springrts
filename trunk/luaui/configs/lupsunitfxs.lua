-- note that the order of the MergeTable args matters for nested tables (such as colormaps)!

local presets = {
	commandAuraRed = {
		{class='StaticParticles', options=commandCoronaRed},
		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},
	},
	commandAuraOrange = {
	    {class='StaticParticles', options=commandCoronaOrange},
		{class='GroundFlash', options=MergeTable(groundFlashOrange, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.8, 0, 0.2, 1},{0.8, 0, 0.2, 0.85},{0.8, 0, 0.2, 1} }})},
	},
	commandAuraGreen = {
		{class='StaticParticles', options=commandCoronaGreen},
		{class='GroundFlash', options=MergeTable(groundFlashGreen, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.2, 1, 0.2, 1},{0.2, 1, 0.2, 0.85},{0.2, 1, 0.2, 1} }})},
	},
	commandAuraBlue = {
		{class='StaticParticles', options=commandCoronaBlue},
		{class='GroundFlash', options=MergeTable(groundFlashBlue, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.2, 0.2, 1, 1},{0.2, 0.2, 1, 0.85},{0.2, 0.2, 1, 1} }})},
	},	
	commandAuraViolet = {
		{class='StaticParticles', options=commandCoronaViolet},
		{class='GroundFlash', options=MergeTable(groundFlashViolet, {radiusFactor=3.5,mobile=true,life=math.huge,
			colormap={ {0.8, 0, 0.8, 1},{0.8, 0, 0.8, 0.85},{0.8, 0, 0.8, 1} }})},
	},	
	
	commAreaShield = {
		{class='ShieldJitter', options={delay=0, life=math.huge, heightFactor = 0.75, size=350, strength = .001, precision=50, repeatEffect=true, quality=4}},
	},
	
	commandShieldRed = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{1, 0.1, 0.1, 0.6}}, colormap2 = {{1, 0.1, 0.1, 0.15}}}, commandShieldSphere)},
--		{class='StaticParticles', options=commandCoronaRed},
--		{class='GroundFlash', options=MergeTable(groundFlashRed, {radiusFactor=3.5,mobile=true,life=60,
--			colormap={ {1, 0.2, 0.2, 1},{1, 0.2, 0.2, 0.85},{1, 0.2, 0.2, 1} }})},	
	},
	commandShieldOrange = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.8, 0.3, 0.1, 0.6}}, colormap2 = {{0.8, 0.3, 0.1, 0.15}}}, commandShieldSphere)},
	},	
	commandShieldGreen = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 1, 0.1, 0.6}}, colormap2 = {{0.1, 1, 0.1, 0.15}}}, commandShieldSphere)},
	},
	commandShieldBlue= {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.1, 0.1, 0.8, 0.6}}, colormap2 = {{0.1, 0.1, 1, 0.15}}}, commandShieldSphere)},
	},	
	commandShieldViolet = {
		{class='ShieldSphere', options=MergeTable({colormap1 = {{0.6, 0.1, 0.75, 0.6}}, colormap2 = {{0.6, 0.1, 0.75, 0.15}}}, commandShieldSphere)},
	},	
}

effectUnitDefs = {

	--// ENERGY STORAGE //--------------------
  core_energy_storage = {
    {class='GroundFlash',options=groundFlashCorestor},
  },
  lost_energy_storage = {
    {class='GroundFlash',options=groundFlashCorestor},
  },
  arm_energy_storage = {
    {class='GroundFlash',options=groundFlashArmestor},
  },

  --// PLANES still need to do work here //----------------------------
  arm_freedom_fighter = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="rearthrust", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="rearthrust2", onActive=true}},
  },
  arm_tornado = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="thrust", onActive=true}},
  },
  arm_albatross = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=45, piece="thrust", onActive=true}},
  },
  arm_hawk = {
    {class='AirJet',options={color={0.3,0.1,0}, width=6, length=75, piece="rearthrust", onActive=true}},
  },
  core_fink = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3, length=35, piece="thrustb", onActive=true}},
  },
  core_titan = {
    {class='AirJet',options={color={0.3,0.1,0}, width=5, length=65, piece="thrustb", onActive=true}},
  },
  arm_lancet = {
   {class='AirJet',options={color={0.3,0.1,0}, width=5, length=65, piece="thrust", onActive=true}},
  },
  core_avenger = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
  },
  core_typhoon = {
    {class='AirJet',options={color={0.3,0.1,0}, width=1.1, length=31, piece="thrustl1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=1.8, length=47, piece="thrustl2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=1.8, length=47, piece="thrustl3", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=1.1, length=31, piece="thrustr1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=1.8, length=47, piece="thrustr2", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=1.8, length=47, piece="thrustr3", onActive=true}},
  },
  core_shadow = {
    {class='AirJet',options={color={0.6,0.1,0}, width=3.5, length=52, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.6,0.1,0}, width=3.5, length=52, piece="thrust2", onActive=true}},
  },
  arm_thunder = {
    {class='ThundAirJet',options={color={0.3,0.1,0}, width=2.9, length=52, piece="thrust1", onActive=true}},
    {class='ThundAirJet',options={color={0.3,0.1,0}, width=2.9, length=52, piece="thrust2", onActive=true}},
    {class='ThundAirJet',options={color={0.3,0.1,0}, width=2.9, length=52, piece="thrust3", onActive=true}},
    {class='ThundAirJet',options={color={0.3,0.1,0}, width=2.9, length=52, piece="thrust4", onActive=true}},
  },
  core_hurricane = {
    {class='AirJet',options={color={0.9,0.3,0}, width=10, length=80, piece="thrust", onActive=true}},
  },
  arm_phoenix = {
    {class='AirJet',options={color={0.3,0.1,0}, width=8, length=75, piece="thrust", onActive=true}},
  },
  core_vamp = {
    {class='AirJet',options={color={0.6,0.1,0}, width=3.5, length=65, piece="thrustb", onActive=true}},
  },
  core_vulture = {
    {class='AirJet',options={color={0.8,0.2,0}, width=4, length=50, piece="thrust", onActive=true}},
  },
  core_hunter = {
    {class='AirJet',options={color={0.8,0.2,0}, width=4, length=50, piece="thrust", onActive=true}},
  },
  arm_eagle = {
    {class='AirJet',options={color={0.3,0.1,0}, width=3.5, length=50, piece="thrust", onActive=true}},
  },
  arm_seahawk = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4, length=50, piece="thrust", onActive=true}},
  },
  core_silhouette = {
    {class='AirJet',options={color={0.4,0.1,0}, width=1.8, length=52, piece="thrust1a", onActive=true}},
    {class='AirJet',options={color={0.4,0.1,0}, width=1.8, length=52, piece="thrust1b", onActive=true}},
    {class='AirJet',options={color={0.6,0.1,0}, width=3.7, length=76, piece="thrust2", onActive=true}},
  },
  arm_harpoon = {
    {class='AirJet',options={color={0.3,0.1,0}, width=4.5, length=70, piece="thrust", onActive=true}},
  },
  lost_falcon = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
  },
  lost_condor = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
  },
  lost_ghost = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust3", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust4", onActive=true}},
  },
  lost_osprey = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust3", onActive=true}},
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust4", onActive=true}},
  },
  lost_probe = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust", onActive=true}},
  },
  lost_pterodactyl = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
  },
  lost_sparrow = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust", onActive=true}},
  },
  lost_swallow = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
  },
  lost_trawler = {
    {class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust1", onActive=true}},
	{class='AirJet',options={color={0.3,0.1,0}, width=2.4, length=42, piece="thrust2", onActive=true}},
  },

  --// OTHER
  roost = {
		{class='SimpleParticles', options=roostDirt},
		{class='SimpleParticles', options=MergeTable({delay=60},roostDirt)},
		{class='SimpleParticles', options=MergeTable({delay=120},roostDirt)},
  },
   
}
 
effectUnitDefsXmas = {

  arm_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_scommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u0commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_ucommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u2commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u3commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_u4commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  arm_decoy_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,3.8,0.7}, emitVector={0.3,0.7,0.3}, width=3.4, height=9, ballSize=1.3, piecenum=8, piece="head"}},
  },
  core_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_scommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u0commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_ucommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u2commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u3commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_u4commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  core_decoy_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,5.2,2.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=16, piece="head"}},
  },
  -- lost commanders
  lost_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u0commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_ucommander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u2commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u3commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_u4commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
  lost_decoy_commander = {
    {class='SantaHat',options={color={1,0.1,0,1}, pos={0,9.2,3.1}, emitVector={0.3,0.7,0.3}, width=3.4, height=8, ballSize=1.1, piecenum=18, piece="head"}},
  },
}

effectUnitDefsStPatrick = {}
 
for i,f in pairs(effectUnitDefsXmas) do
	
	if f and (f[1]) and (f[1].options) and (f[1].options.color) then
		f[1].options.color = {0.1,0.7,0,1}
		effectUnitDefsStPatrick[i] = f
	end
end
 
 
local levelScale = {
    1,
    1.1,
    1.2,
    1.25,
    1.3,
}

-- load presets from unitdefs
for i=1,#UnitDefs do
	local unitDef = UnitDefs[i]
	
	if unitDef.customParams and unitDef.customParams.commtype then
		local s = levelScale[tonumber(unitDef.customParams.level) or 1]
		if unitDef.customParams.commtype == "1" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0.7,0,1}, pos={0,4*s,0.35*s}, emitVector={0.3,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "2" then
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0,6*s,2*s}, emitVector={0.4,1,0.2}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "3" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0.7,0,1}, pos={1.5*s,4*s,0.5*s}, emitVector={0.7,1.6,0.2}, width=2.2*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "4" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={pos={0,3.8*s,0.35*s}, emitVector={0,1,0}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="head"}},
			}
		elseif unitDef.customParams.commtype == "5" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,0.1}, width=2.7*s, height=6*s, ballSize=0.7*s, piece="hat"}},
			}	    
		elseif unitDef.customParams.commtype == "6" then 
			effectUnitDefsXmas[unitDef.name] = {
				{class='SantaHat', options={color={0,0,0.7,1}, pos={0,0,0}, emitVector={0,1,-0.1}, width=4.05*s, height=9*s, ballSize=1.05*s, piece="hat"}},
			}	    
		end
	end
	if unitDef.customParams then
		local fxTableStr = unitDef.customParams.lups_unit_fxs
		if fxTableStr then
			local fxTableFunc = loadstring("return "..fxTableStr)
			local fxTable = fxTableFunc()
			effectUnitDefs[unitDef.name] = effectUnitDefs[unitDef.name] or {}
			for i=1,#fxTable do	-- for each item in preset table
				local toAdd = presets[fxTable[i]]
				for i=1,#toAdd do
					table.insert(effectUnitDefs[unitDef.name],toAdd[i])	-- append to unit's lupsFX table
				end
			end
		end
	end
end
