-- Cleaned up by Jools, 2015/2

function gadget:GetInfo()
  return {
    name      = "Chicken Spawner",
    desc      = "Spawns burrows and chickens",
    author    = "quantum",
    date      = "April 29, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 20,
    enabled   = true --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then
	-- BEGIN SYNCED
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Speed-ups and upvalues
	--

	local Spring              	= Spring
	local math                	= math
	local Game                	= Game
	local table               	= table
	local ipairs              	= ipairs
	local pairs               	= pairs
	local Echo 					= Spring.Echo
	local GetGroundHeight 		= Spring.GetGroundHeight
	local queenID
	local targetCache     
	local luaAI  
	local chickenTeamID
	local burrows             	= {}
	local burrowBirths	  		= {}
	local burrowLevel		  	= {}
	local burrowSpawnProgress 	= 0
	local commanders          	= {}
	local maxTries            	= 100
	local computerTeams       	= {}
	local humanTeams          	= {}
	local lagging             	= false
	local gameOver            	= false
	local cpuUsages           	= {}
	local chickenBirths       	= {}
	local totalKills          	= 0
	local idleQueue           	= {}
	local turrets             	= {}
	local timeOfLastSpawn     	= 0
	local specialBugCount     	= 0
	local hiveposx		  		= 0
	local hiveposz            	= 0   
	local checkDisabled	  		= 0
	local armflea		  		= 0
	gameMode                 	= 'normal' --Spring.GetModOption("gamemode")
	local gaiaTeamID          	= Spring.GetGaiaTeamID()
	local malus
	
	local Counter				= {
			['waves']			= 0,
			['burrowspawns']	= 0,
			['totalkills']		= 0,
			['burrowkills']		= 0,
			['queens']			= 0,
			['fleas']			= 0,
	}

	local mexes = {
		"arm_metal_extractor", 
		"core_metal_extractor",
		"lost_metal_extractor",
		"guardian_metal_extractor",
	}

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Teams
	--


	local modes = {
		[0] = 0,
		[1] = 'FLEAS: Easy',
		[2] = 'FLEAS: Normal',
		[3] = 'FLEAS: Hard',
		[4] = 'FLEAS: Cruel',
		[5] = 'Fleas: Impossible Cream',
		[6] = 'Fire Spirits Edition',
	}


	for i, v in ipairs(modes) do -- make it bi-directional
	  modes[v] = i
	end


	local function CompareDifficulty(...)
	  level = 1
	  for _, difficulty in ipairs{...} do
		if (modes[difficulty] > level) then
		  level = modes[difficulty]
		end
	  end
	  return modes[level]
	end


	if (not gameMode) then -- set human and computer teams
	  humanTeams[0]    = true
	  computerTeams[1] = true
	  chickenTeamID    = 1
	  luaAI            = defaultDifficulty
	else
	  local teams = Spring.GetTeamList()
	  local highestLevel = 0
	  for _, teamID in ipairs(teams) do
		local teamLuaAI = Spring.GetTeamLuaAI(teamID)
		if (teamLuaAI and teamLuaAI ~= "") then
		  luaAI = teamLuaAI
		  highestLevel = CompareDifficulty(teamLuaAI, highestLevel)
		  chickenTeamID = teamID
		  computerTeams[teamID] = true
		else
		  humanTeams[teamID]    = true
		end
	  end
	  luaAI = highestLevel
	end


	local gaiaTeamID          = Spring.GetGaiaTeamID()
	computerTeams[gaiaTeamID] = nil
	humanTeams[gaiaTeamID]    = nil


	if (gameMode and luaAI == 0) then
	  return false
	else
			Spring.SetGameRulesParam('Fleabowl',1)
	end


	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Utility
	--

	local function SetToList(set)
	  local list = {}
	  for k in pairs(set) do
		table.insert(list, k)
	  end
	  return list
	end


	local function SetCount(set)
	  local count = 0
	  for k in pairs(set) do
		count = count + 1
	  end
	  return count
	end


	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Difficulty
	--

	do -- load config file
	  local CONFIG_FILE = "LuaRules/Configs/spawn_defs.lua"
	  local VFSMODE = VFS.RAW_FIRST
	  local s = assert(VFS.LoadFile(CONFIG_FILE, VFSMODE))
	  local chunk = assert(loadstring(s, file))
	  setfenv(chunk, gadget)
	  chunk()
	end

	local function SetGlobals(difficulty)
	  for key, value in pairs(gadget.difficulties[difficulty]) do
		gadget[key] = value
	  end
	  gadget.difficulties = nil
	end

	SetGlobals(luaAI or defaultDifficulty) -- set difficulty

	-- adjust for player and chicken bot count
	local malus     = SetCount(humanTeams)^playerMalus
	burrowSpawnRate = burrowSpawnRate/malus/SetCount(computerTeams)

	local function DisableBuildButtons(unitID, ...)
	  for _, unitName in ipairs({...}) do
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, -UnitDefNames[unitName].id)
		if (cmdDescID) then
		  local cmdArray = {disabled = true, tooltip = tooltipMessage}
		  Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
		end
	  end
	end

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Game Rules
	--


	local function SetupUnit(unitName)
	  Spring.SetGameRulesParam(unitName.."Count", 0)
	  Spring.SetGameRulesParam(unitName.."Kills", 0)
	end

	Spring.SetGameRulesParam("lagging",           0)
	Spring.SetGameRulesParam("queenTime",        queenTime)

	for unitName in pairs(chickenTypes) do
	  SetupUnit(unitName)
	end

	for unitName in pairs(defenders) do
	  SetupUnit(unitName)
	end

	SetupUnit(burrowName)
	SetupUnit(queenName)

	local difficulty = modes[luaAI or defaultDifficulty]
	Spring.SetGameRulesParam("difficulty", difficulty)
	
	local function UpdateUnitCount()
	  local teamUnitCounts = Spring.GetTeamUnitsCounts(chickenTeamID)
	  for unitDefID, count in pairs(teamUnitCounts) do
		if (unitDefID ~= "n") then
		  Spring.SetGameRulesParam(UnitDefs[unitDefID].name.."Count", count)
		end
	  end
	end

	local function KillOldChicken()
	  for unitID, birthDate in pairs(chickenBirths) do
		local age = Spring.GetGameSeconds() - birthDate
		if (age > maxAge + math.random(10)) then
		  Spring.DestroyUnit(unitID)
		end
	  end
	end

	local function UpgradeBurrows()
	  for unitID, birthDate in pairs(burrowBirths) do
		local age = Spring.GetGameSeconds() - birthDate
		if (age > upgradeTime) then
		  burrowLevel[unitID]= burrowLevel[unitID] + 1
		end
	  end
	end

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Game End Stuff
	--

	local function KillAllChicken()
	  local chickenUnits = Spring.GetTeamUnits(chickenTeamID)
	  for _, unitID in ipairs(chickenUnits) do
		Spring.DestroyUnit(unitID)
	  end
	end

	local function KillAllComputerUnits()
	  for teamID in pairs(computerTeams) do
		local teamUnits = Spring.GetTeamUnits(teamID)
		for _, unitID in ipairs(teamUnits) do
		  Spring.DestroyUnit(unitID)
		end
	  end
	end

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Spawn Dynamics
	--

	local function IsPlayerUnitNear(x, z, r)
	  for teamID in pairs(humanTeams) do   
		if (#Spring.GetUnitsInCylinder(x, z, r, teamID) > 0) then
		  return true
		end
	  end
	end

	local function AttackNearestEnemy(unitID)
	  local targetID = Spring.GetUnitNearestEnemy(unitID)
	  if (targetID) then
		local tx, ty, tz  = Spring.GetUnitPosition(targetID)
		Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {tx, ty, tz}, {})
	  end
	end

	local function ChooseTarget()
	  local humanTeamList = SetToList(humanTeams)
	  if (#humanTeamList == 0) or gameOver then
		return
	  end
	  local teamID = humanTeamList[math.random(#humanTeamList)]
	  local units  = Spring.GetTeamUnits(teamID)
	  local unitID = #units > 0 and units[math.random(#units)]
	  
		if unitID then
			return {Spring.GetUnitPosition(unitID)}
		else
			return false
		end
	end

	local function ChooseChicken(units)
	  local s = Spring.GetGameSeconds()
	  units = units or chickenTypes
	  choices = {}
	  for chickenName, c in pairs(units) do
		if (c.time <= s and (c.obsolete or math.huge) > s) then   
		  local chance = math.floor((c.initialChance or 1) + 
									(s-c.time) * (c.chanceIncrease or 0))
		  for i=1, chance do
			table.insert(choices, chickenName)
		  end
		end
	  end
	  if (#choices < 1) then
		return
	  else
		return choices[math.random(#choices)], choices[math.random(#choices)]
	  end
	end

	local function SpawnChicken(burrowID, spawnNumber, chickenName)
		local x, y, z
		local bx, by, bz    = Spring.GetUnitPosition(burrowID)
		if (not bx or not by or not bz) then return end
		
		local tries         = 0
		local s             = spawnSquare
	  
		for i=1, spawnNumber do

			repeat
				x = math.random(bx - s, bx + s)
				z = math.random(bz - s, bz + s)
				s = s + spawnSquareIncrement
				tries = tries + 1
			until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)
			
			y = GetGroundHeight(x,z)
			local unitID = Spring.CreateUnit(chickenName, x, y, z, "n", chickenTeamID)
			Counter['fleas'] = Counter['fleas'] + 1
			Spring.SetGameRulesParam('fleas',Counter['fleas'])
			
			if (targetCache) then
				Spring.GiveOrderToUnit(unitID, CMD.FIGHT, targetCache, {})
			end
			
			chickenBirths[unitID] = Spring.GetGameSeconds() 
		end

		local sec = Spring.GetGameSeconds()

		if (sec >= 480) then
			for i=1, 2 do

				repeat
					x = math.random(bx - s, bx + s)
					z = math.random(bz - s, bz + s)
					s = s + spawnSquareIncrement
					tries = tries + 1
				until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)
				
				y = GetGroundHeight(x,z)
				local unitID = Spring.CreateUnit("armflea", x, y, z, "n", chickenTeamID)
				Counter['fleas'] = Counter['fleas'] + 1
				Spring.SetGameRulesParam('fleas',Counter['fleas'])
				
				if (targetCache) then
					Spring.GiveOrderToUnit(unitID, CMD.FIGHT, targetCache, {})
				end
				
				chickenBirths[unitID] = Spring.GetGameSeconds() 
			end
		end
	  
		if (queenID) then return end

		if (specialBugCount == 8 or specialBugCount == 29) then

			if (burrowLevel[burrowID] >= 120) then

				for i=1, burrowLevel[burrowID]/120 do

					repeat
						x = math.random(bx - s, bx + s)
						z = math.random(bz - s, bz + s)
						s = s + spawnSquareIncrement
						tries = tries + 1
					until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)

					y = GetGroundHeight(x,z)
					local unitID = Spring.CreateUnit("mflea", x, y, z, "n", chickenTeamID)
					Counter['fleas'] = Counter['fleas'] + 1
					Spring.SetGameRulesParam('fleas',Counter['fleas'])
					
					if (targetCache) then
						Spring.GiveOrderToUnit(unitID, CMD.FIGHT, targetCache, {})
					end
					
					chickenBirths[unitID] = Spring.GetGameSeconds() 
				end
			end
		end

		if (specialBugCount == 22) then

			if (burrowLevel[burrowID] >= 300) then

				for i=1, 1 do		
					repeat
						x = math.random(bx - s, bx + s)
						z = math.random(bz - s, bz + s)
						s = s + spawnSquareIncrement
						tries = tries + 1
					until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)
					
					y = GetGroundHeight(x,z)
					local unitID = Spring.CreateUnit("mflea", x, y, z, "n", chickenTeamID)
					Counter['fleas'] = Counter['fleas'] + 1
					Spring.SetGameRulesParam('fleas',Counter['fleas'])
					
					armflea = unitID
					if (targetCache) then
						Spring.GiveOrderToUnit(unitID, CMD.FIGHT, targetCache, {})
					end
					
					chickenBirths[unitID] = Spring.GetGameSeconds() 
				end
			
				for i=1, 3 do
					repeat
						x = math.random(bx - s, bx + s)
						z = math.random(bz - s, bz + s)
						s = s + spawnSquareIncrement
						tries = tries + 1
					until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)
					
					y = GetGroundHeight(x,z)
					local unitID = Spring.CreateUnit("mflea", x, y, z, "n", chickenTeamID)
					Counter['fleas'] = Counter['fleas'] + 1
					Spring.SetGameRulesParam('fleas',Counter['fleas'])
					
					if (targetCache) then
						Spring.GiveOrderToUnit(unitID, CMD.GUARD, {armflea}, {})
					end
				
					chickenBirths[unitID] = Spring.GetGameSeconds() 
				end
			end
		end


		if (sec >= 600 and specialBugCount >= 35) then

			for i=1, 1 do

				repeat
					x = math.random(bx - s, bx + s)
					z = math.random(bz - s, bz + s)
					s = s + spawnSquareIncrement
					tries = tries + 1
				until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)
				y = GetGroundHeight(x,z)
				
				local unitID = Spring.CreateUnit("mflea", x, y, z, "n", chickenTeamID)
				Counter['fleas'] = Counter['fleas'] + 1
				Spring.SetGameRulesParam('fleas',Counter['fleas'])
				
				if (targetCache) then
					Spring.GiveOrderToUnit(unitID, CMD.PATROL, {hiveposx, 0, hiveposz}, {})
				end
				chickenBirths[unitID] = Spring.GetGameSeconds() 
			end
		end


		specialBugCount = specialBugCount + 1

		if (specialBugCount >= 40) then
			specialBugCount = 0
		end
	end

	local function SpawnTurret(burrowID, turret)
	  
	  if (math.random() > defenderChance and defenderChance < 1 or not turret) then
		return
	  end
	  
	  local x, y, z
	  local bx, by, bz    = Spring.GetUnitPosition(burrowID)
	  local tries         = 0
	  local s             = spawnSquare
	  local spawnNumber   = math.max(math.floor(defenderChance), 1)
	  
	  for i=1, spawnNumber do
		
		repeat
		  x = math.random(bx - s, bx + s)
		  z = math.random(bz - s, bz + s)
		  s = s + spawnSquareIncrement
		  tries = tries + 1
		until (not Spring.GetGroundBlocked(x, z) or tries > spawnNumber + maxTries)
		
		y = GetGroundHeight(x,z)
		local unitID = Spring.CreateUnit(turret, x, y, z, "n", chickenTeamID) -- FIXME
		Spring.SetUnitBlocking(unitID, false)
		turrets[unitID] = Spring.GetGameSeconds()
		
	  end
	  
	end

	local function SpawnBurrow()
	  
	  if (queenID) then
		return
	  end
		
	  local t     = Spring.GetGameSeconds()
	  local unitDefID = UnitDefNames[burrowName].id
		
	  for i=1, 1 do
		local x, y, z
		local tries = 0

	  repeat
		x = math.random(spawnSquare, Game.mapSizeX - spawnSquare)
		z = math.random(spawnSquare, Game.mapSizeZ - spawnSquare)
		y = Spring.GetGroundHeight(x, z)
		tries = tries + 1
		local blocking = Spring.TestBuildOrder(UnitDefNames["arm_metal_maker"].id, x, y, z, 1)
		if (blocking == 2) then
		  local proximity = Spring.GetUnitsInCylinder(x, z, minBaseDistance)
		  local vicinity = Spring.GetUnitsInCylinder(x, z, maxBaseDistance)
		  local humanUnitsInVicinity = false
		  local humanUnitsInProximity = false
		  for i=1,#vicinity,1 do
			if (Spring.GetUnitTeam(vicinity[i]) ~= chickenTeamID) then
			  humanUnitsInVicinity = true
			  break
			end
		  end

		  for i=1,#proximity,1 do
			if (Spring.GetUnitTeam(proximity[i]) ~= chickenTeamID) then
			  humanUnitsInProximity = true
			  break
			end
		  end

		  if (humanUnitsInProximity or not humanUnitsInVicinity) then
			blocking = 1
		  end
		end
	  until (blocking == 2 or tries > maxTries)

		local unitID = Spring.CreateUnit(burrowName, x, y, z, "n", chickenTeamID)
		hiveposx = x
		hiveposz = z
		burrows[unitID] = true
		Spring.SetUnitBlocking(unitID, false)
		burrowBirths[unitID] = Spring.GetGameSeconds() 
		burrowLevel[unitID] = 0
		Counter['burrowspawns'] = Counter['burrowspawns'] + 1
		Spring.SetGameRulesParam('burrowspawns',Counter['burrowspawns'])
	  end
	  
	end

	local function SpawnQueen()
	  
	  local x, y, z
	  local tries = 0
	 
	 repeat
		x = math.random(spawnSquare, Game.mapSizeX - spawnSquare)
		z = math.random(spawnSquare, Game.mapSizeZ - spawnSquare)
		y = Spring.GetGroundHeight(x, z)
		tries = tries + 1
		local blocking = Spring.TestBuildOrder(UnitDefNames["arm_peewee"].id, x, y, z, 1)
		if (blocking == 2 and tries < maxTries - 10) then
		  local proximity = Spring.GetUnitsInCylinder(x, z, minBaseDistance)
		  local vicinity = Spring.GetUnitsInCylinder(x, z, maxBaseDistance)
		  local humanUnitsInVicinity = false
		  local humanUnitsInProximity = false
		  for i=1,#vicinity,1 do
			if (Spring.GetUnitTeam(vicinity[i]) ~= chickenTeamID) then
			  humanUnitsInVicinity = true
			  break
			end
		  end

		  for i=1,#proximity,1 do
			if (Spring.GetUnitTeam(proximity[i]) ~= chickenTeamID) then
			  humanUnitsInProximity = true
			  break
			end
		  end

		  if (humanUnitsInProximity or not humanUnitsInVicinity) then
			blocking = 1
		  end
		end
	  until (blocking == 2 or tries > maxTries)
	 

	  Counter['queens'] = Counter['queens'] + 1
	  Spring.SetGameRulesParam('queens',Counter['queens'])
	  
	  return Spring.CreateUnit(queenName, x, y, z, "n", chickenTeamID)
	 
	end

	local function Wave()
	  
	  if gameOver then return end
	  local t = Spring.GetGameSeconds()
	  
	  if (Spring.GetTeamUnitCount(chickenTeamID) > maxChicken or lagging or t < gracePeriod) then
		return
	  end
	  

	  local chicken1Name, chicken2Name = ChooseChicken(chickenTypes)
	  local turret = ChooseChicken(defenders)
	  local squadNumber = t*timeSpawnBonus+firstSpawnSize
	  local chicken1Number = math.ceil(waveRatio * squadNumber * chickenTypes[chicken1Name].squadSize)
	  local chicken2Number = math.floor((1-waveRatio) * squadNumber * chickenTypes[chicken2Name].squadSize)
	  
	  if (queenID) then
		SpawnChicken(queenID, chicken1Number*queenSpawnMult*malus, chicken1Name)
		SpawnChicken(queenID, chicken2Number*queenSpawnMult*malus, chicken2Name)
	  else
		for burrowID in pairs(burrows) do
		  SpawnChicken(burrowID, chicken1Number, chicken1Name)
		  SpawnChicken(burrowID, chicken2Number, chicken2Name)
		  SpawnTurret(burrowID, turret)
		end
		
		Counter['waves'] = Counter['waves'] + 1
		Spring.SetGameRulesParam('waves',Counter['waves'])
		
		return chicken1Name, chicken2Name, chicken1Number, chicken2Number -- not used anymore
	  end
	  
	end

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Get rid of the AI
	--

	local function DisableUnit(unitID)
	  Spring.MoveCtrl.Enable(unitID)
	  Spring.MoveCtrl.SetNoBlocking(unitID, true)
	  Spring.MoveCtrl.SetPosition(unitID, Game.mapSizeX+4000, 0, Game.mapSizeZ+4000)
	  Spring.SetUnitHealth(unitID, {paralyze=99999999})
	  Spring.SetUnitNoDraw(unitID, true)
	  Spring.SetUnitStealth(unitID, true)
	  Spring.SetUnitNoSelect(unitID, true)
	  commanders[unitID] = nil
	end

	local function DisableComputerUnits()
	  for teamID in pairs(computerTeams) do
		local teamUnits = Spring.GetTeamUnits(teamID)
		for _, unitID in ipairs(teamUnits) do
		  DisableUnit(unitID)
		end
	  end
	end

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	--
	-- Call-ins
	--

	function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	  local name = UnitDefs[unitDefID].name
	  if (name == "arm_commander" or
		  name == "core_commander") then
		commanders[unitID] = true
	  end
	--  if (chickenTeamID == unitTeam and name ~= "arm_commander" and name ~= "core_commander" ) then
	--    local n = Spring.GetGameRulesParam(name.."Count")
	--    Spring.SetGameRulesParam(name.."Count", n+1)
	--  end
	  if (alwaysVisible and unitTeam == chickenTeamID) then
		Spring.SetUnitAlwaysVisible(unitID, true)
	  end
	--  if (eggs) then
	--    DisableBuildButtons(unitID, unpack(mexes))
	--  end
	end

	function gadget:GameFrame(n)
	  if gameOver then return end
	  local t = Spring.GetGameSeconds()

	  if (n == 1) then
		DisableComputerUnits()
		checkDisabled = checkDisabled + 1
	  end

	  if (math.fmod(n,33) == 0) then

		UpgradeBurrows()

	  end

	  if (checkDisabled == 0) then

		DisableComputerUnits()
		checkDisabled = checkDisabled + 1

	  end
	  
	  if ((n+19) % (30 * chickenSpawnRate) < 0.1) then
		Wave()
	  end
	  
	  if ((n+21) % 30 < 0.1) then

		KillOldChicken()
		UpdateUnitCount()
		targetCache = ChooseTarget()
	  
		for _, unitID in ipairs(Spring.GetTeamUnits(chickenTeamID)) do
		  if (targetCache and 
			  (not Spring.GetUnitCommands(unitID,1)
			  or #Spring.GetUnitCommands(unitID,1) < 1)) then
			Spring.GiveOrderToUnit(unitID, CMD.FIGHT, targetCache, {})
		  end
		end  


		if (t >= queenTime) then
		  if (not queenID) then
			queenID = SpawnQueen()
			local xp = (malus^2 or 1) - 1
			Spring.SetUnitExperience(queenID, xp)
		  --local _, maxhp = Spring.GetUnitHealth(queenID)
		  --Spring.SetUnitMaxHealth(queenID, maxhp*malus^2)
		  --Spring.SetUnitHealth(queenID, maxhp*malus^2)
		  end
		end
		
		local burrowCount = SetCount(burrows)
		local timeSinceLastSpawn = t - timeOfLastSpawn
		local burrowSpawnTime = burrowSpawnRate*0.25*(burrowCount+1)

		local malus     = SetCount(humanTeams)^playerMalus
	   
		if (burrowCount/(malus^0.8) <= 6 and t > 300) then

		burrowSpawnTime = burrowSpawnTime * burrowCount/(burrowCount + 2*malus)

		end    

		if (burrowSpawnTime < timeSinceLastSpawn and 
			not lagging and burrowCount < maxBurrows) then
		  SpawnBurrow()
		  timeOfLastSpawn = t
		end
		
	  end
	  
	end

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, _, _, _)
	  
	  if gameOver then return end
	  chickenBirths[unitID] = nil
	  burrowBirths[unitID] = nil
	  commanders[unitID] = nil
	  turrets[unitID] = nil
	  local name = UnitDefs[unitDefID].name
	  if (unitTeam == chickenTeamID) then
		if (chickenTypes[name] or defenders[name]) then
			if (chickenTypes[name]) then -- exclude turrets
				Counter['fleas'] = Counter['fleas'] - 1
				totalKills = totalKills + 1
				Spring.SetGameRulesParam('fleas',Counter['fleas'])
				Spring.SetGameRulesParam("killedFleas", totalKills)
			end
			
			local kills = Spring.GetGameRulesParam(name.."Kills")
			Spring.SetGameRulesParam(name.."Kills", kills + 1)
		end
		if (name == queenName) then
		  KillAllComputerUnits()
		  KillAllChicken()
		end
	  end
	  if (name == burrowName) then
		burrows[unitID] = nil

		local burrowCount = SetCount(burrows)
		if (burrowCount - malus <= 3) then
			SpawnBurrow()
		end
	  end
	end

	function gadget:TeamDied(teamID)
	  humanTeams[teamID] = nil
	  computerTeams[teamID] = nil
	end

	function gadget:AllowCommand(unitID, unitDefID, teamID,
								 cmdID, cmdParams, cmdOptions)
	--  if (eggs) then
	--    for _, mexName in ipairs(mexes) do
	--      if (UnitDefNames[mexName].id == -cmdID) then
	--        return false -- command was used
	--      end
	--    end
	--  end
	  return true  -- command was not used
	end

	function gadget:GameOver()
	  gameOver=true
	end

end

--------------------------------------------------------------------------------
