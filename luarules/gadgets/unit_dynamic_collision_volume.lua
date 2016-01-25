function gadget:GetInfo()
  return {
    name      = "Dynamic collision volume & Hitsphere Scaledown",
    desc      = "Adjusts collision volume for pop-up style units & Reduces the diameter of default sphere collision volume for 3DO models",
    author    = "Deadnight Warrior",
    date      = "Nov 26, 2011",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-- Pop-up style unit and per piece collision volume definitions
local popupUnits = {}		--list of pop-up style units
local unitCollisionVolume, pieceCollisionVolume, dynamicPieceCollisionVolume = include("LuaRules/Configs/CollisionVolumes.lua")
local mapFeatures = {}

-- Localization and speedups
local spGetPieceCollisionData = Spring.GetUnitPieceCollisionVolumeData
local spSetPieceCollisionData = Spring.SetUnitPieceCollisionVolumeData
local spGetPieceList = Spring.GetUnitPieceList
local spGetUnitCollisionData = Spring.GetUnitCollisionVolumeData
local spSetUnitCollisionData = Spring.SetUnitCollisionVolumeData
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight
local spGetUnitRadius = Spring.GetUnitRadius
local spGetUnitHeight = Spring.GetUnitHeight
local spSetUnitMidAndAimPos = Spring.SetUnitMidAndAimPos
local spGetFeatureCollisionData = Spring.GetFeatureCollisionVolumeData
local spSetFeatureCollisionData = Spring.SetFeatureCollisionVolumeData
local spSetFeatureRadiusAndHeight = Spring.SetFeatureRadiusAndHeight
local spGetFeatureRadius = Spring.GetFeatureRadius
local spGetFeatureHeight = Spring.GetFeatureHeight
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitDefID = Spring.GetUnitDefID
local spValidUnitID = Spring.ValidUnitID
local spGetGameFrame = Spring.GetGameFrame

local spArmor = Spring.GetUnitArmored
local spActive = Spring.GetUnitIsActive
local pairs = pairs	
local min = math.min
local Echo = Spring.Echo
local startIndex

if (gadgetHandler:IsSyncedCode()) then

	--Process all initial map features
	function gadget:Initialize()
		local mapConfig = "LuaRules/Configs/DynCVmapCFG/" .. Game.mapName .. ".lua"
		if VFS.FileExists(mapConfig) then
			mapFeatures = VFS.Include(mapConfig)
			for _, featID in pairs(Spring.GetAllFeatures()) do
				local featureModel = FeatureDefs[Spring.GetFeatureDefID(featID)].modelname:lower()
				if featureModel:len() > 4 then
					local featureModelTrim
					
					featureModelTrim = featureModel:match("/.*%."):sub(2,-2)
					
					if mapFeatures[featureModelTrim] then
						local p = mapFeatures[featureModelTrim]
						spSetFeatureCollisionData(featID, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
						spSetFeatureRadiusAndHeight(featID, min(p[1], p[3])*0.5, p[2])
					elseif featureModel:find(".s3o") then
						local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetFeatureCollisionData(featID)
						if (vtype>=3 and xs==ys and ys==zs) then
							spSetFeatureCollisionData(featID, xs, ys*0.75, zs,  xo, yo-ys*0.09, zo,  1, htype, 1)
						end
					end
				end
			end			
		else
			for _, featID in pairs(Spring.GetAllFeatures()) do
				local featureModel = FeatureDefs[Spring.GetFeatureDefID(featID)].modelname:lower()
				if featureModel:find(".3do") then
					local rs, hs
					if (spGetFeatureRadius(featID)>47) then
						rs, hs = 0.68, 0.60
					else
						rs, hs = 0.75, 0.67  
					end
					local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetFeatureCollisionData(featID)
					if (vtype>=3 and xs==ys and ys==zs) then
						spSetFeatureCollisionData(featID, xs*rs, ys*hs, zs*rs,  xo, yo-ys*0.1323529*rs, zo,  vtype, htype, axis)
					end
					spSetFeatureRadiusAndHeight(featID, spGetFeatureRadius(featID)*rs, spGetFeatureHeight(featID)*hs)			
				elseif featureModel:find(".s3o") then
					local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetFeatureCollisionData(featID)
					if (vtype>=3 and xs==ys and ys==zs) then
						spSetFeatureCollisionData(featID, xs, ys*0.75, zs,  xo, yo-ys*0.09, zo,  vtype, htype, axis)
					end
				end
			end
		end
		local version = Game.version
		startIndex = version > "100" and version:sub(1,1) == "1" and 1 or 0
	end

	
	--Reduces the diameter of default (unspecified) collision volume for 3DO models,
	--for S3O models it's not needed and will in fact result in wrong collision volume
	--also handles per piece collision volume definitions
	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
		if (pieceCollisionVolume[UnitDefs[unitDefID].name]) then
			local t = pieceCollisionVolume[UnitDefs[unitDefID].name]
			--for pieceIndex, pieceName in pairs (spGetPieceList(unitID)) do
			-- it has to be done this way to access piece 0, uncomment when backwards compatibility is not needed
			for pieceIndex=startIndex, #spGetPieceList(unitID)-1+startIndex do
				-- hacky because GetPieceList always returns 1-based piecelist
				local pieceName = spGetPieceList(unitID)[pieceIndex+1-startIndex]
				p = t[pieceName]
				if p then
					spSetPieceCollisionData(unitID, pieceIndex, true, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
				else
					spSetPieceCollisionData(unitID, pieceIndex, false, 1, 1, 1, 0, 0, 0, 1, 1)
				end
			end
		elseif dynamicPieceCollisionVolume[UnitDefs[unitDefID].name] then
			local t = dynamicPieceCollisionVolume[UnitDefs[unitDefID].name].on
			--for pieceIndex, pieceName in pairs (spGetPieceList(unitID)) do
			-- same here
			for pieceIndex=startIndex, #spGetPieceList(unitID)-1+startIndex do
				local pieceName = spGetPieceList(unitID)[pieceIndex+1-startIndex]
				p = t[pieceName]
				if p then
					spSetPieceCollisionData(unitID, pieceIndex, true, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
				else
					
					spSetPieceCollisionData(unitID, pieceIndex, false, 1, 1, 1, 0, 0, 0, 1, 1)
				end
			end
		elseif UnitDefs[unitDefID].model.type=="3do" then
			local rs, hs, ws
			if (spGetUnitRadius(unitID)>47 and not UnitDefs[unitDefID].canFly) then
				rs, hs, ws = 0.68, 0.68, 0.68
			elseif (not UnitDefs[unitDefID].canFly) then
				rs, hs, ws = 0.75, 0.75, 0.75
			else
				rs, hs, ws = 0.52, 0.24, 0.38
			end
			local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetUnitCollisionData(unitID)
			if (vtype>=3 and xs==ys and ys==zs) then
				spSetUnitCollisionData(unitID, xs*ws, ys*hs, zs*rs,  xo, yo, zo,  vtype, htype, axis)
				spSetUnitRadiusAndHeight(unitID, spGetUnitRadius(unitID)*rs, spGetUnitHeight(unitID)*hs)
				return
			end
		end
		if UnitDefs[unitDefID].model.type=="3do" then	-- a 3DO unit that has dynamic or per-piece CV still needs a radius and height adjustment
			local rs, hs
			if (spGetUnitRadius(unitID)>47 and not UnitDefs[unitDefID].canFly) then
				rs, hs = 0.68, 0.68
			elseif (not UnitDefs[unitDefID].canFly) then
				rs, hs = 0.75, 0.75
			else
				rs, hs = 0.52, 0.24
			end
			spSetUnitRadiusAndHeight(unitID, spGetUnitRadius(unitID)*rs, spGetUnitHeight(unitID)*hs)
		end
		-- the following lines are commented because they're not needed in XTA, but that might change
		--if UnitDefs[unitDefID].canFly and UnitDefs[unitDefID].transportCapacity>0 then
		--	spSetUnitRadiusAndHeight(unitID, 16, 16)
		--end
		
		-- adjust commander's radiuses to match their visible height
		local ud = UnitDefs[unitDefID]
		
		if ud.customParams and ud.customParams.iscommander then
			local radius = spGetUnitRadius(unitID)
			local height = spGetUnitHeight(unitID)
			
			if ud.customParams.side == "arm" then			
				spSetUnitRadiusAndHeight(unitID, radius-5, height)
			else
				spSetUnitRadiusAndHeight(unitID, radius-1, height)
			end
		end
		
		-- adjust units that are floating below water to have smaller radius (applies mostly to submarines but also to subpen e.g.)
		local ud = UnitDefs[unitDefID]
		if ud.waterline > 15 and ud.moveDef then
			local radius = spGetUnitRadius(unitID)
			local height = spGetUnitHeight(unitID)
			spSetUnitRadiusAndHeight(unitID, min(radius,height*1.5), height)
		end
		
		-- adjust arm adv.torpedo launcher some extra
		if ud.name == "arm_advanced_torpedo_launcher" then
			local radius = spGetUnitRadius(unitID)
			local height = spGetUnitHeight(unitID)
			spSetUnitRadiusAndHeight(unitID, radius*0.5, height)
		end
	end


	-- Same as for 3DO units, but for features
	function gadget:FeatureCreated(featureID, allyTeam)
		local featureModel = FeatureDefs[Spring.GetFeatureDefID(featureID)].modelname:lower()
		if featureModel == "" then return end	--geovents or engine trees have no models		
		local featureModelTrim
		
		featureModelTrim = featureModel:match("/.*%."):sub(2,-2)
		
		if mapFeatures[featureModelTrim] then	-- it just might happen that some map features can have corpses
			local p = mapFeatures[featureModelTrim]
			spSetFeatureCollisionData(featureID, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
			spSetFeatureRadiusAndHeight(featureID, min(p[1], p[3])*0.5, p[2])		
		elseif featureModelTrim:find(".3do",-1) then
			local rs, hs
			if (spGetFeatureRadius(featureID)>47) then
				rs, hs = 0.68, 0.60
			else
				rs, hs = 0.75, 0.67
			end
			local xs, ys, zs, xo, yo, zo, vtype, htype, axis, _ = spGetFeatureCollisionData(featureID)
			if (vtype>=3 and xs==ys and ys==zs) then
				spSetFeatureCollisionData(featureID, xs*rs, ys*hs, zs*rs,  xo, yo-ys*0.09, zo,  vtype, htype, axis)
			end
			spSetFeatureRadiusAndHeight(featureID, spGetFeatureRadius(featureID)*rs, spGetFeatureHeight(featureID)*hs)
		end
	end


	-- Check if a unit is pop-up type (the list must be entered manually)
	function gadget:UnitFinished(unitID, unitDefID, unitTeam)
		local un = UnitDefs[unitDefID].name
		if unitCollisionVolume[un] then
			popupUnits[unitID]={name=un, state=-1, perPiece=false}
		elseif dynamicPieceCollisionVolume[un] then
			popupUnits[unitID]={name=un, state=-1, perPiece=true, numPieces = #spGetPieceList(unitID)-1}
		end
	end


	--check if a pop-up type unit was destroyed
	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, _, _, _, preEvent)
		if (preEvent) then return end
		
		if popupUnits[unitID] then
			popupUnits[unitID] = nil
		end
	end

	
	--Dynamic adjustment of pop-up style of units' collision volumes based on unit's ARMORED status, runs twice per second
	function gadget:GameFrame(n)
		if (n%15 ~= 0) then
			return
		end
		local p, t
		for unitID,defs in pairs(popupUnits) do
			if spArmor(unitID) then
				if (defs.state ~= 0) then
					if defs.perPiece then
						t = dynamicPieceCollisionVolume[defs.name].off
						--for pieceIndex, pieceName in pairs (spGetPieceList(unitID)) do
						-- same here
						for pieceIndex=startIndex, defs.numPieces-1+startIndex do
							local pieceName = spGetPieceList(unitID)[pieceIndex+1-startIndex]
							p = t[pieceName]
							if p then
								spSetPieceCollisionData(unitID, pieceIndex, true, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
							else
								spSetPieceCollisionData(unitID, pieceIndex, false, 1, 1, 1, 0, 0, 0, 1, 1)
							end
						end
						if t.offsets then
							p = t.offsets
							spSetUnitMidAndAimPos(unitID, p[1], p[2], p[3], p[4], p[5], p[6],true)
						end
					else
						p = unitCollisionVolume[defs.name].off
						spSetUnitCollisionData(unitID, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
						if p[10] then
							spSetUnitMidAndAimPos(unitID, p[10], p[11], p[12], p[13], p[14], p[15],true)
						end
					end
					popupUnits[unitID].state = 0
				end
			else
				if (defs.state ~= 1) then
					if defs.perPiece then
						t = dynamicPieceCollisionVolume[defs.name].on
						--for pieceIndex, pieceName in pairs (spGetPieceList(unitID)) do
						-- same here
						for pieceIndex=startIndex, defs.numPieces-1+startIndex do
							local pieceName = spGetPieceList(unitID)[pieceIndex+1-startIndex]
							p = t[pieceName]
							if p then
								spSetPieceCollisionData(unitID, pieceIndex, true, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
							else
								spSetPieceCollisionData(unitID, pieceIndex, false, 1, 1, 1, 0, 0, 0, 1, 1)
							end
						end
						if t.offsets then
							p = t.offsets
							spSetUnitMidAndAimPos(unitID, p[1], p[2], p[3], p[4], p[5], p[6],true)
						end
					else
						p = unitCollisionVolume[defs.name].on
						spSetUnitCollisionData(unitID, p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
						if p[10] then
							spSetUnitMidAndAimPos(unitID, p[10], p[11], p[12], p[13], p[14], p[15],true)
						end
					end
					popupUnits[unitID].state = 1
				end
			end			
		end
	end
	
end
