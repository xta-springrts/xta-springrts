function gadget:GetInfo()
	return {
		name    = "game_zombiemode",
		desc    = "handles the 'zombies' modoption",
		author  = "",
		date    = "Okt, 2013",
		license = "Public domain",
		layer   = 0,
		enabled = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

local FIRESTATE_FATW 		   = 2
local MOVESTATE_ROAM 		   = 2
local MOVESTATE_HP 		   	   = 0
local FIRESTATE_HF			   = 0
local CMD_AREA_GUARD 		   = 14001
local spGetUnitNeutral         = Spring.GetUnitNeutral
local spSetUnitNeutral         = Spring.SetUnitNeutral
local spGetGameFrame           = Spring.GetGameFrame
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitDirection       = Spring.GetUnitDirection
local spGetUnitBuildFacing     = Spring.GetUnitBuildFacing
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spGetFeatureDefID        = Spring.GetFeatureDefID
local spGetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local spCreateUnit             = Spring.CreateUnit
local spDestroyFeature         = Spring.DestroyFeature
local spTestMoveOrder          = Spring.TestMoveOrder
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local GetUnitDefID			   = Spring.GetUnitDefID
local Echo					   = Spring.Echo
local random 				   = math.random
local mapX, mapZ
local FACTORYCHECKFRAMES	   = 1420 -- ~47 s
local UNITCHECKFRAMES		   = 1820 -- ~1 min
local ARMYMAKEFRAMES		   = 6100 -- ~3.4 mins
local COMMANDERCHECKFRAMES 	   = 100  -- 3 secs

local modOptions    		   = Spring.GetModOptions()
local modOptionDefs 		   = VFS.Include("modoptions.lua")
local modRules      		   = VFS.Include("gamedata/modrules.lua")

local losToElmos = 1.0
local gaiaTeamID = Spring.GetGaiaTeamID()

-- "modOptions" is a <string, string> map (values are not numbers!)
local haveZombies = (((modOptions["zombies"] or "0") + 0) ~= 0)
local isKOTH	= (tonumber(Spring.GetModOptions().koth) or 0) == 1
local zombieConf  = "LuaRules/Configs/game_zombiemode_defs.lua"
local zombieDefs  = (VFS.FileExists(zombieConf) and include(zombieConf)) or {}
local zombieQueue = {}
local zombieTable = {}
local zombieCount = 0
local zombieCommanders = {}
local kothBoxes = {}

-- Get from common defs config

local CommanderDefs,dgunTable = include("LuaRules/Configs/xta_common_defs.lua")
local _,CaptureDefs,NapDefs = include(zombieConf)

local function sortByDist(v1,v2) -- increasing
	return v1[2] < v2[2]
end

local function sortByHP(v1,v2) -- increasing
	return v1[2] < v2[2]
end

local function sortByRange(v1,v2) -- increasing
	return v1[3] < v2[3]
end
	
local function ZombieGuard(unitID,x,y,z,radius)
		
	local targetArray 	= Spring.GetUnitsInSphere(x,y,z,radius,gaiaTeamID)
	local targetTable 	= {} -- list of units that should be guarded
	
	for _, zID in pairs (targetArray) do
		local tUD = UnitDefs[GetUnitDefID(zID)]
		local dist = Spring.GetUnitSeparation(unitID, zID)
		local isMovingUnit = tUD.canMove and (not tUD.isBuilding)
		
		if isMovingUnit and dist > 0 then 
			targetTable[#targetTable+1] = {zID,dist}
		end
		
		table.sort(targetTable, sortByDist)
	end
	
	if targetTable and #targetTable > 0 then
		for i=1,math.min(3,#targetTable) do
			local zID = targetTable[i][1]
			spGiveOrderToUnit(unitID, CMD.INSERT,{-1,CMD.GUARD,CMD.OPT_SHIFT,zID},{"alt"})
		end
	end
end

local function zombieRemoveGuard(unitID)
	for _,uID in pairs (Spring.GetTeamUnits(gaiaTeamID) ) do
		for _, cmd in pairs (Spring.GetUnitCommands (uID,6)) do
			if cmd.id == CMD.GUARD then
				local tID = cmd.params[1]
				local tag = cmd.tag
				if tID and tID == unitID then
					spGiveOrderToUnit(uID, CMD.REMOVE,{tag},{""})
				end
			end
		end
	end
end

local function ZombiePatrol(unitID, unitDefID, x,y,z, radius)
	local p0 = {x + random(-radius,radius), y, z + random(-radius,radius)}
	local p1 = {x + random(-radius,radius), y, z + random(-radius,radius)}
	
	local b0 = spTestMoveOrder(unitDefID,  p0[1], p0[2], p0[3], 0.0, 0.0, 0.0,  true, true, true)
	local b1 = spTestMoveOrder(unitDefID,  p1[1], p1[2], p1[3], 0.0, 0.0, 0.0,  true, true, true)
	
	if (b0) then spGiveOrderToUnit(unitID, CMD.PATROL, p0, {"shift"}) end
	if (b1) then spGiveOrderToUnit(unitID, CMD.PATROL, p1, {"shift"}) end
end

local function MakeZombieArmy(zombieArray,x0,z0,x1,z1)
	local front = {}
	local ranged = {}
	local misc = {}
	
	local array = {}
	local count = #zombieArray
	local testUdefID
	
	for _, zID in pairs(zombieArray) do
		local udefID = GetUnitDefID(zID)
		local uD =  UnitDefs[udefID]
		testUdefID = testUdefID or ((not uD.canFly) and udefID)
		
		local hp = uD.health
		local speed = uD.speed
		local wID = uD.weapons[1].weaponDef
		local range = wID and WeaponDefs[wID].range or 0
		local dmg = wID and WeaponDefs[wID].damages.default or 0
		local rTime = wID and WeaponDefs[wID].reloadTime or 1000
		local dps = dmg/rTime
		local dhp = hp+20*dps
		array[#array+1] = {zID,dhp,range}
	end
	testUdefID = testUdefID or GetUnitDefID(array[1][1])
	
	table.sort(array,sortByHP)
	
	local rest = count%3
	
	for i=#array,#array-(math.floor(count/3)+rest),-1 do
		front[#front+1] = array[i][1]
		array[#array] = nil
	end
	
	table.sort(array,sortByRange)
	
	for i=#array,#array-(math.floor(count/3)),-1 do
		ranged[#ranged+1] = array[i][1]
		array[#array] = nil
	end
	
	for i=1,#array do
		misc[#misc+1] = array[i][1]
	end

	-- pick target for army
	local tx,ty,tz, b0
	local loops = 0
	local sbox = #kothBoxes > 0 and random(#kothBoxes)
	
	local xmin = isKOTH and #kothBoxes > 0 and (kothBoxes[sbox]["xmin"]) or 0
	local zmin = isKOTH and #kothBoxes > 0 and (kothBoxes[sbox]["zmin"]) or 0
	local xmax = isKOTH and #kothBoxes > 0 and (kothBoxes[sbox]["xmax"]) or mapX
	local zmax = isKOTH and #kothBoxes > 0 and (kothBoxes[sbox]["zmax"]) or mapZ
	
	repeat
		tx = random(xmin,xmax)
		tz = random(zmin,zmax)
		ty = Spring.GetGroundHeight(tx,tz)
		b0 = spTestMoveOrder(testUdefID,  tz, ty, tz, 0.0, 0.0, 0.0,  true, true, true)
		loops = loops + 1
	until (((tx < x0 or tx > x1) or (tz < z0 or tz > z1)) and b0) or loops > 50 -- send army to another quadrant and make sure it can move there
	
	if not tx and ty and tz then return end
	
	Spring.GiveOrderToUnitArray(front,CMD.STOP, {},{})
	Spring.GiveOrderToUnitArray(ranged,CMD.STOP, {},{})
	Spring.GiveOrderToUnitArray(misc,CMD.STOP, {},{})
	
	--front
	Spring.GiveOrderToUnitArray(front,CMD.FIGHT, {tx,ty,tz}, {})
	--ranged
	for i, zID in pairs(ranged) do
		for j = i,i+2 do
			if j > #front then j = j - #front end
			spGiveOrderToUnit(zID,CMD.GUARD, {front[j]},{"shift"})
		end
	end
	-- misc
	Spring.GiveOrderToUnitArray(misc,CMD.FIGHT, {tx+random(-100,100),ty,tz+random(-100,100)}, {})
	
end

local function GiveFactoryOrders(unitID,unitDefID)
	local buildopts = UnitDefs[unitDefID].buildOptions
	local orders = {}
			
	for i=1,random(10,30) do
		orders[#orders+1] = { -buildopts[random(1,#buildopts)], {}, {} }
	end
	if (#orders > 0) then
		if (Spring.GetUnitIsDead(unitID) == false) then
			Spring.GiveOrderArrayToUnitArray({unitID},orders)
		end
	end
end

local function GiveUnitOrders(unitID,unitDefID,isBuilder)
	local x,y,z = Spring.GetUnitPosition(unitID)
	
	if isBuilder then
		ZombieGuard(unitID,x,y,z,500)
	else
		ZombiePatrol(unitID, unitDefID, x,y,z, 1000)
	end
end

local function CheckFactories()
	for _, zID in pairs (Spring.GetTeamUnits(gaiaTeamID)) do
		local unitDefID = Spring.GetUnitDefID(zID)
		if UnitDefs[unitDefID].isFactory then
			local orders = Spring.GetFactoryCommands(zID, 1)
			if not orders or #orders == 0 then
				GiveFactoryOrders(zID,unitDefID)
			end
		end
	end
end

local function CheckUnits()
	for _, zID in pairs (Spring.GetTeamUnits(gaiaTeamID)) do
		local unitDefID = Spring.GetUnitDefID(zID)
		local uD = UnitDefs[unitDefID]
		if uD and uD.canGuard and not uD.isFactory and (not uD.isImmobile) then
			local orders = Spring.GetUnitCommands(zID, 1)
			if not orders or #orders == 0 then
				GiveUnitOrders(zID,unitDefID,uD.isBuilder)
			end
		end
	end
end

local function zombieReclaim(unitID,x,y,z,radius)
	for _, fID in pairs (Spring.GetFeaturesInSphere(x,y,z,radius)) do
		local isBlocking = Spring.GetFeatureBlocking(fID)
		local name = FeatureDefs[Spring.GetFeatureDefID(fID)].name
		if isBlocking then
			spGiveOrderToUnit(unitID, CMD.INSERT,{-1,CMD.RECLAIM,CMD.OPT_SHIFT,Game.maxUnits+fID},{"alt"})	
		end
	end
end

local function CheckZombieCount()
	
	local count = Spring.GetTeamUnitCount(gaiaTeamID)
	if count < 50 then return end
	
	for i=1,2 do
		for j = 1,2 do
			
			local x = mapX/2 * (i-1)
			local z = mapZ/2 * (j-1)
			
			local zombieArray = Spring.GetUnitsInRectangle(x,z,x+mapX/2,z+mapZ/2,gaiaTeamID)
			local armyArray = {}
			local zombieForce = 0
			for _, zID in pairs(zombieArray) do
				local uD =  UnitDefs[GetUnitDefID(zID)]
				if (not uD.isFactory) and uD.canAttack and (not uD.isImmobile) and uD.weapons and (#uD.weapons > 0) then
					zombieForce = zombieForce + 1
					armyArray[#armyArray+1] = zID
				end
			end
			
			if zombieForce > 20 then
				MakeZombieArmy(armyArray,x,z,x+mapX/2,z+mapZ/2)
				return
			end
		end
	end
end

local function CheckCommander(unitID)
	local health,_,hitpoints,captureProgress = Spring.GetUnitHealth(unitID)
	local x,y,z = spGetUnitPosition(unitID)
	if not (x and y and z and health and health > 0) then return end
	
	local eLevel,_,ePull,eInc = Spring.GetTeamResources(gaiaTeamID,"energy")
	if eLevel < 1000 then
		Spring.GiveOrderToUnit(unitID,CMD.CLOAK, {0},{})
	elseif eLevel > 2000 and eInc-ePull > 400 then
		Spring.GiveOrderToUnit(unitID,CMD.CLOAK, {1},{})
	end
		
	if captureProgress and captureProgress > 0.50 then
		for _, eID in pairs (Spring.GetUnitsInSphere(x,y,z,400)) do
			local udid = Spring.GetUnitDefID(eID)
			local teamID = Spring.GetUnitTeam(eID)
			if teamID ~= gaiaTeamID then
				if CaptureDefs[udid] then
					if not CommanderDefs[udid] then
						zombieReclaim(unitID,x,y,z,250)
					end
					
					local dist = Spring.GetUnitSeparation(eID,unitID)
					if dist < 240 then
						Spring.GiveOrderToUnit(unitID,CMD.DGUN, {eID},{})
					else
						Spring.GiveOrderToUnit(unitID,CMD.GUARD, {eID},{})
						Spring.GiveOrderToUnit(unitID,CMD.SELFD, {},{})
					end	
				end
			end
		end
	else
		zombieReclaim(unitID,x,y,z,250)
		
		for _, eID in pairs (Spring.GetUnitsInSphere(x,y,z,300)) do
			local teamID = Spring.GetUnitTeam(eID)
			if teamID ~= gaiaTeamID then
				local udid = Spring.GetUnitDefID(eID)
				
				if NapDefs[udid] then
					local dist = Spring.GetUnitSeparation(eID,unitID)
					if dist < 220 then
						local x1,y1,z1 = spGetUnitPosition(eID)
						local mx = x-5*(x1-x) + math.random(-200,200)
						local mz = z-5*(z1-z) + math.random(-200,200)
						local my = Spring.GetGroundHeight(mx,mz)
						local unitDefID = Spring.GetUnitDefID(unitID)
						local b0 = spTestMoveOrder(unitDefID,  mx, my, mz, 0.0, 0.0, 0.0,  true, true, true)
						if b0 then
							Spring.GiveOrderToUnit(unitID,CMD.MOVE, {mx,my,mz},{})
						else
							Spring.GiveOrderToUnit(unitID,CMD.MOVE, {x+math.random(-200,200),y,z+math.random(-200,200)},{})
						end
					end
				end
			end
		end
	end
	
end

function gadget:Initialize()
	assert(modOptionDefs ~= nil)

	if (modOptions == nil) then
		Spring.Echo("[game_zombiemode] no mod-options")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (gaiaTeamID == 0) then
		Spring.Echo("[game_zombiemode] no Gaia-team")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (not haveZombies) then
		for idx, tbl in ipairs(modOptionDefs) do
			if (tbl.key == "zombies") then
				haveZombies = haveZombies or tbl.def
				break
			end
		end
	end

	if (not haveZombies) then
		--Spring.Log("",LOG.INFO,"[game_zombiemode] no zombies no fun")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (modRules ~= nil and modRules["sensors"] ~= nil and modRules["sensors"]["los"] ~= nil) then
		local losResMult  = modRules["sensors"]["los"]["losMul"     ]
		local losMipLevel = modRules["sensors"]["los"]["losMipLevel"]

		-- losRadius = sightDist * losResMult / (SQUARE_SIZE * (1 << losMipLevel))
		-- sightDist = losRadius * SQUARE_SIZE * (1 << losMipLevel) / losResMult
		losToElmos = 8 * math.pow(2, losMipLevel) / losResMult
	end
	mapX = Game.mapSizeX
	mapZ = Game.mapSizeZ
	
	if isKOTH then
		for _, allyTeamID in ipairs(Spring.GetAllyTeamList()) do 
			local teams = Spring.GetTeamList(allyTeamID)
			if  (teams == nil or #teams == 0) then
				local xmin,zmin, xmax,zmax = Spring.GetAllyTeamStartBox(allyTeamID)
				
				if (xmin ~= nil) then
					xmin = math.floor(xmin)
					zmin = math.floor(zmin)
					xmax = math.floor(xmax)
					zmax = math.floor(zmax)
					
					table.insert(kothBoxes, {["xmin"] = xmin, ["zmin"] = zmin, ["xmax"] = xmax, ["zmax"] = zmax})
					
				end 
			end 
		end
	end
end 

-- NOTE:
--   dgun should not trigger respawn (config) *FIXED*
--   reclaiming should NOT EVER trigger respawn (ok, does not trigger UnitDamaged)
--   nanoframe decay should NOT EVER trigger respawn *FIXED*
--	 morphing should not trigger respawn *FIXED*
--   Moved to UnitPreDamaged to allow zombies that die to not leave wrecks, although I later removed that option
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local health, _,_,_, buildProgress = Spring.GetUnitHealth(unitID)
	local killed = (health - damage) <= 0.0 	-- in predamaged damage is not applied, but in unitdamaged it already is
	local dgunned = dgunTable[weaponDefID]

	if (dgunned) then
		return
	end
	if (not killed) then
		return
	end
	if (zombieTable[unitID]) then
		return
	end

	if (buildProgress >= 1.0) then
		local isZombie = (unitTeam == gaiaTeamID)
		local zombieDef = zombieDefs[unitDefID] or {}
		
		if ((isZombie and (not zombieDef.allowRepeatSpawn)) or (not zombieDef.allowZombieSpawn)) then 
			return 
		end

		if ((attackerID == nil or attackerTeam == nil) and (not zombieDef.allowDebrisSpawn)) then
			return
		end

		local teamKill, allowTeamKill = (attackerTeam == unitTeam), zombieDef.allowTeamKillSpawn
		local selfKill, allowSelfKill = (attackerID == unitID), zombieDef.allowSelfKillSpawn

		-- self-kills are also team-kills, check those separately
		if ((teamKill and (not selfKill)) and (not allowTeamKill)) then
			return
		end
		if (selfKill and (not allowSelfKill)) then
			return
		end

		zombieCount = zombieCount + 1
		zombieQueue[zombieCount] = {
			id     = unitID,
			defID  = unitDefID,
			pos    = {spGetUnitPosition(unitID)},
			dir    = {spGetUnitDirection(unitID)},
			facing = spGetUnitBuildFacing(unitID),
			frame  = spGetGameFrame() + zombieDef.respawnTime
		}

		-- prevent double spawns
		zombieTable[unitID] = true
	end
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	if zombieCommanders[unitID] then
		local eID = Spring.GetUnitNearestEnemy(unitID,240)
		if eID then
			Spring.GiveOrderToUnit(unitID,CMD.DGUN, {eID},{})
		elseif attackerID then
			local ex,ey,ez =  Spring.GetUnitPosition(attackerID)
			
			--test validity
			local b0 = spTestMoveOrder(unitDefID,  ez, ey, ez, 0.0, 0.0, 0.0,  true, true, true)
			if bo then
				Spring.GiveOrderToUnit(unitID,CMD.ATTACK, {attackerID},{})
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)

	
	if CommanderDefs[unitDefID] and unitTeam == gaiaTeamID then
		zombieCommanders[unitID] = nil
	end
end

function gadget:FeatureDestroyed(featureID, allyTeamID)
	local unitName  = Spring.GetFeatureResurrect(featureID)
	--Echo("FR:",unitName)
	if unitName then
		local unitDefID = (UnitDefNames[unitName] or {}).id
		local fx,_,fz = Spring.GetFeaturePosition(featureID)
		
		if unitDefID and fx and fz then
			
			for index, spawn in pairs(zombieQueue) do
				if spawn.defID == unitDefID then
					local spawnPos = spawn.pos
					local x = spawnPos[1]
					local z = spawnPos[3]
					-- remove zombie from queue if wreck was reclaimed
					if (x - fx < 10 and x - fx > -10) and (z - fz < 10 and z - fz > -10) then
						zombieQueue[index] = nil
						zombieTable[spawn.id] = nil
					end
				end
			end
			
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if CommanderDefs[unitDefID] and unitTeam == gaiaTeamID then
		zombieCommanders[unitID] = unitID
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	if oldTeam == gaiaTeamID then
		zombieRemoveGuard(unitID)
	end
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if unitTeam ~= gaiaTeamID or (cmdID ~= CMD.RECLAIM and cmdID ~= CMD.PATROL) then
		return true
	else
		--Echo("AC:",CMD[cmdID])
		-- TODO: fix to prevent zombies from reclaiming, but reclaim from patrol command is not seen as a reclaim command.
		return true
	end
end

function gadget:GameOver()
	gadgetHandler:RemoveGadget()
end

--[[
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)
	if (unitTeam ~= gaiaTeamID) then
		return true
	end

	if (cmdID ~= CMD_RECLAIM) then
		return true
	end

	return true
end
--]]

function gadget:GameFrame(n)
	for index, spawn in pairs(zombieQueue) do
		if (spawn.frame == n) then
			SpawnZombie(index, spawn)
		end
	end
	
	-- check that factories are doing something
	if n%FACTORYCHECKFRAMES == 0 then
		CheckFactories()
	end
	-- Check units
	if n%UNITCHECKFRAMES == 0 then
		CheckUnits()
	end
	
	-- check for army
	if n%ARMYMAKEFRAMES == 0 then
		CheckZombieCount()
	end
	
	-- check commander
	if n%COMMANDERCHECKFRAMES == 0 then
		for zID,_ in pairs(zombieCommanders) do
			CheckCommander(zID)
		end
	end
	
	-- set storages for zombies
	if (n==1) then
		Spring.SetTeamResource(gaiaTeamID, "ms", 500)
		Spring.SetTeamResource(gaiaTeamID, "es", 10500)
	end
end

function gadget:UnitFromFactory (unitID, unitDefID, unitTeam, factID,factDefID,_)
	if unitTeam == gaiaTeamID then
		local uD = UnitDefs[unitDefID]
		if uD and uD.canGuard and not uD.isFactory and uD.isBuilder and uD.canAssist then
			local x,y,z = Spring.GetUnitPosition(unitID)
			local rnd = random()
			if rnd < 0.33 then
				ZombieGuard(unitID,x,y,z,500)
			elseif rnd < 0.66 then
				spGiveOrderToUnit(unitID, CMD.INSERT,{-1,CMD.GUARD,CMD.OPT_SHIFT,factID},{"alt"})
			else
				ZombiePatrol(unitID, unitDefID, x,y,z, 500)
			end
		end
	end
end

function DestroyWreck(unitDef, spawnPos)
	local featureIDs = spGetFeaturesInRectangle(spawnPos[1] - 64.0, spawnPos[3] - 64.0,  spawnPos[1] + 64.0, spawnPos[3] + 64.0)

	if (featureIDs == nil) then
		return false
	end

	-- try to make sure zombies are not stuck in their own corpses
	-- player can still suck the wrecks if he acts quickly enough
	--
	-- (could be an option to prevent spawns *if* the player manages
	-- to reclaim >= 75% of a corpse in time, but would have to make
	-- an exception for units that don't leave wrecks and for zombie
	-- builders which might reclaim corpses before they could spawn:
	-- zombies should never hurt the chances of their own "team", so
	-- with such an option feature-reclaim orders should be blocked
	-- from all patrolling zombie builders)
	
	-- Note: patrolling zombies don't trigger the reclaim command when reclaiming.J
	--
	-- note: a corpse might have kept sliding along the ground after
	-- dying so this loop won't always find a match, but there is no
	-- general way to link a corpse back to the unit which created it
	
	-- Another option would be to move the whole code to featurecreated 
	-- callin instead, and just spawn zombies from wrecks. But I recall I
	-- exploded that method and it had some issue (that I can no longer
	-- remember), and it's also nice to get zombie aircraft, crawling bombs
	-- and mines. /J
	local minFeatureID = -1
	local minFeatureDist = math.huge

	for _, featureID in ipairs(featureIDs) do
		local featureDefID = spGetFeatureDefID(featureID)
		local featureName = FeatureDefs[featureDefID].name
		local featurePos = {spGetFeaturePosition(featureID)}
		local featureDist = (featurePos[1] - spawnPos[1])^2 + (featurePos[3] - spawnPos[3])^2

		if (featureDist < minFeatureDist and featureName == unitDef.wreckName) then
			minFeatureDist = featureDist
			minFeatureID = featureID
		end
	end

	if (minFeatureID ~= -1) then
		spDestroyFeature(minFeatureID)
		return true
	end

	return false
end

function SpawnZombie(index, spawn)
	local spawnPos = spawn.pos
	local spawnDir = spawn.dir

	local unitDefID = spawn.defID
	local unitDef = UnitDefs[unitDefID]

	local unitID = spCreateUnit(unitDefID, spawnPos[1], spawnPos[2], spawnPos[3], spawn.facing, gaiaTeamID)

	DestroyWreck(unitDef, spawnPos)

	if (unitID ~= nil) then
		if not CommanderDefs[unitDefID] then
			spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = FIRESTATE_FATW}, {})
			spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = MOVESTATE_ROAM}, {})
		else
			spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = FIRESTATE_FATW}, {})
			spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = MOVESTATE_HP}, {})
		end
		local losRadius = unitDef.losRadius
		local sightDist = losRadius * losToElmos
		local patrolVec = {spawnDir[1] * sightDist * 0.666, 0.0, spawnDir[3] * sightDist * 0.666}
		local hasWeapons = unitDef.weapons and (#unitDef.weapons > 0)
				
		if not hasWeapons and not unitDef.canAttack then
			Spring.SetUnitNeutral(unitID,true)
		end
		if (not unitDef.isImmobile) then
			
			-- 50 % chance of guarding
			if random() < 0.5 then
				local x,y,z = spawnPos[1],spawnPos[2],spawnPos[3]
				ZombieGuard(unitID,x,y,z,500)
			else
				local p0 = {spawnPos[1] + patrolVec[1], spawnPos[2], spawnPos[3] + patrolVec[3]}
				local p1 = {spawnPos[1] - patrolVec[1], spawnPos[2], spawnPos[3] - patrolVec[3]}

				-- test validity of orders
				local b0 = spTestMoveOrder(unitDefID,  p0[1], p0[2], p0[3], 0.0, 0.0, 0.0,  true, true, true)
				local b1 = spTestMoveOrder(unitDefID,  p1[1], p1[2], p1[3], 0.0, 0.0, 0.0,  true, true, true)

				if (b0) then spGiveOrderToUnit(unitID, CMD.PATROL, p0, {"shift"}) end
				if (b1) then spGiveOrderToUnit(unitID, CMD.PATROL, p1, {"shift"}) end
			end
		elseif unitDef.isFactory then
			GiveFactoryOrders(unitID,unitDefID)
		end
	end
	-- won't this break index of table? Or maybe that does not matter. Otherwise table.remove would be better.
	zombieQueue[index] = nil
	zombieTable[spawn.id] = nil
end

