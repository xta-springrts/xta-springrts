function gadget:GetInfo()
	return {
		name      	= "radiation",
		desc      	= "Radiation damage",
		author    	= "res",
		date      	= "8-10-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= 1,
		enabled   	= true,
	}
end


	--[[

		Specifies some units do damage to other units (radiation)

		-parameters options:
			- 

		# TODO
		1. Add map damage area fx
		2. Add list with damage areas (without units)

	--]]	


-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --

local radiationWeapons, radiationUnits	= include("LuaRules/Configs/radiation_config.lua")
local sqrt								= math.sqrt
local max								= math.max
local min								= math.min
local abs								= math.abs

local modOptions 						= Spring.GetModOptions()
local SetFeatureHealth					= Spring.SetFeatureHealth
local GetFeatureHealth					= Spring.GetFeatureHealth
local GetFeaturePosition				= Spring.GetFeaturePosition
local AddUnitDamage 					= Spring.AddUnitDamage
local GetFeaturesInSphere				= Spring.GetFeaturesInSphere
local GetUnitsInSphere					= Spring.GetUnitsInSphere
local GetUnitPosition					= Spring.GetUnitPosition
local GetFeatureDefID					= Spring.GetFeatureDefID
local GetUnitDefID						= Spring.GetUnitDefID
local Echo					      		= Spring.Echo
local ValidUnitID 						= Spring.ValidUnitID
local ValidFeatureID 					= Spring.ValidFeatureID
local SetGameRulesParam 				= Spring.SetGameRulesParam
local GetGameRulesParam					= Spring.GetGameRulesParam

local damageToUnits 					= {}
local damageToFeatures 					= {}
local unitsDoDamage						= {}
local timeDelayDamage					= 13 -- 1/4 second every second (either update or do damage)
local MAXDAMAGERADIUS					= 1000
local damageValues 						= {}


-- GLOBALS --


if not GG.radiation then
	GG['radiation'] = {}
end
SetGameRulesParam('radiation_update_number', 0)


-- INITIALISE --


function gadget:Initialize()
	local mo = modOptions
	if mo and tonumber(mo.radiation)== 0 then
		Echo("radiation.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	else
		Echo("radiation.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
		Echo("Warning some units deal damage because of radiation!")
		for w,_ in pairs(radiationWeapons) do
			Script.SetWatchWeapon(w, true)
		end
	end
end


-- HELP FUNCTION --


function update_damage()

	-- updating units causing damage
	for k,v in pairs(unitsDoDamage) do
		-- WANDGLOW, PORTALGLOW
		if ValidUnitID(k) == true then
			unitsDoDamage[k].damage = min(v.damage + damageValues[k].dDamage,1)
			unitsDoDamage[k].radius = min(v.radius +  damageValues[k].dRadius,MAXDAMAGERADIUS)
			SetGameRulesParam('radiation_radius' .. k, unitsDoDamage[k].radius)
			SetGameRulesParam('radiation_damage' .. k, unitsDoDamage[k].damage)
			if (unitsDoDamage[k].damage <= 0 or unitsDoDamage[k].radius <= 0) then
				unitsDoDamage[k] = nil
				SetGameRulesParam('radiation_radius' .. k, 0)
				SetGameRulesParam('radiation_damage' .. k, 0)
				if GG.radiation[k] then
					GG.radiation[k] = nil
				end
				local update_number = GetGameRulesParam('radiation_update_number')
				SetGameRulesParam('radiation_update_number', update_number + 1)
			end
		elseif v.duration > 0 then
			unitsDoDamage[k].damage = max(v.damage - abs(damageValues[k].dDamage),0)
			unitsDoDamage[k].radius = max(v.radius - abs(damageValues[k].dRadius),0)
			unitsDoDamage[k].duration = v.duration - timeDelayDamage*2
			SetGameRulesParam('radiation_radius' .. k, unitsDoDamage[k].radius)
			SetGameRulesParam('radiation_damage' .. k, unitsDoDamage[k].damage)
			if (unitsDoDamage[k].damage <= 0 or unitsDoDamage[k].radius <= 0) then
				unitsDoDamage[k] = nil
				SetGameRulesParam('radiation_radius' .. k, 0)
				SetGameRulesParam('radiation_damage' .. k, 0)
				if GG.radiation[k] then
					GG.radiation[k] = nil
				end
				local update_number = GetGameRulesParam('radiation_update_number')
				SetGameRulesParam('radiation_update_number', update_number + 1)
			end
		else
			unitsDoDamage[k] = nil
			if GG.radiation[k] then
				GG.radiation[k] = nil
			end
			SetGameRulesParam('radiation_radius' .. k, 0)
			SetGameRulesParam('radiation_damage' .. k, 0)
			local update_number = GetGameRulesParam('radiation_update_number')
			SetGameRulesParam('radiation_update_number', update_number + 1)
		end
	end

	-- update damaged to units/features
	for k,v in pairs(unitsDoDamage) do
		local near_units = GetUnitsInSphere(v.x,v.y,v.z, v.radius)
		local near_features = GetFeaturesInSphere(v.x,v.y,v.z, v.radius)

		if not (near_units == nil) then
			for i in pairs(near_units) do
				local unitID = near_units[i]
				local xu,yu,zu = GetUnitPosition(unitID)
				local multiplier = 1-sqrt( (v.x-xu)*(v.x-xu) + (v.y-yu)*(v.y-yu) + (v.z-zu)*(v.z-zu) )/v.radius
				local damage = damageToUnits[unitID] or 0
				damageToUnits[unitID] = max(v.damage *multiplier*1000,damage)
			end
		end
		if not (near_features == nil) then
			for i in pairs(near_features) do
				if not FeatureDefs[GetFeatureDefID(near_features[i])].geoThermal then
					local featureID = near_features[i]
					local xf,yf,zf = GetFeaturePosition(featureID)
					local multiplier = 1-sqrt( (v.x-xf)*(v.x-xf) + (v.y-yf)*(v.y-yf) + (v.z-zf)*(v.z-zf) )/v.radius
					local damage = damageToFeatures[featureID] or 0
					damageToFeatures[featureID] = max(v.damage*multiplier*1000,damage)
				end
			end
		end

	end
end


local function update_radiation_unit()
	if GG.radiation then
		for unitID,v in pairs(GG.radiation) do
			if ValidUnitID(unitID) then
				if damageValues[unitID] == nil then
					damageValues[unitID] = {
						['radius'] = GG.radiation[unitID].radius,
						['damage'] = GG.radiation[unitID].damage,
						['dRadius'] = GG.radiation[unitID].dRadius,
						['dDamage'] = GG.radiation[unitID].dDamage,
						['duration'] = GG.radiation[unitID].duration,
						['protection'] = GG.radiation[unitID].protection
					}
					local x, y, z = GetUnitPosition(unitID)
					unitsDoDamage[unitID] = {
						["damage"] = GG.radiation[unitID].damage,
						["radius"] = GG.radiation[unitID].radius,
						["x"] = x,
						["y"] = y,
						["z"] = z,
						["duration"] = GG.radiation[unitID].duration,
					}
					SetGameRulesParam('radiation_radius' .. unitID, GG.radiation[unitID].radius)
					SetGameRulesParam('radiation_damage' .. unitID, GG.radiation[unitID].damage)
					local update_number = GetGameRulesParam('radiation_update_number')
					SetGameRulesParam('radiation_update_number', update_number + 1)
				end
			end
		end
	end
end


function apply_damage()
	for k,v in pairs(damageToUnits) do
		if ValidUnitID(k) == true then
			AddUnitDamage(k, v)
			damageToUnits[k] = 0

		else
			damageToUnits[k] = nil
		end
	end
	for k,v in pairs(damageToFeatures) do
		if ValidFeatureID(k) then
			local feature_health = GetFeatureHealth(k)
			SetFeatureHealth(k,feature_health-v)
			damageToFeatures[k] = 0
		else
			damageToFeatures[k] = nil
		end
	end
end


-- CALL-INS


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	local UDID = GetUnitDefID(unitID)
	if radiationUnits[UnitDefs[UDID].name] then
		damageValues[unitID] = radiationUnits[UnitDefs[UDID].name]
		GG.radiation[unitID] = damageValues[unitID]
		SetGameRulesParam('radiation_radius' .. unitID, GG.radiation[unitID].radius)
		SetGameRulesParam('radiation_damage' .. unitID, GG.radiation[unitID].damage)
		local update_number = GetGameRulesParam('radiation_update_number')
		SetGameRulesParam('radiation_update_number', update_number + 1)
	end
end


function gadget:Explosion(weaponID, px, py, pz, ownerID)
	if (radiationWeapons[weaponID]) then
		if damageValues[ownerID] == nil then
			damageValues[ownerID] = {
				['radius'] = radiationWeapons[weaponID].radius,
				['damage'] = radiationWeapons[weaponID].damage,
				['dRadius'] = radiationWeapons[weaponID].dRadius,
				['dDamage'] = radiationWeapons[weaponID].dDamage,
				['duration'] = radiationWeapons[weaponID].duration,
				['protection'] = radiationWeapons[weaponID].protection
			}
			GG.radiation[ownerID] = damageValues[ownerID]
			SetGameRulesParam('radiation_radius' .. ownerID, GG.radiation[ownerID].radius)
			SetGameRulesParam('radiation_damage' .. ownerID, GG.radiation[ownerID].damage)
			local update_number = GetGameRulesParam('radiation_update_number')
			SetGameRulesParam('radiation_update_number', update_number + 1)
		end
	end
	return false
end


-- LOOP --


function gadget:GameFrame(f)

	if (f%timeDelayDamage == 0) then

		if (f%2 ==0) then

			update_damage()

			update_radiation_unit()

		else

			apply_damage()

		end
	end

end
