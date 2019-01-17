function gadget:GetInfo()
	return {
		name      	= "tornedo",
		desc      	= "tornedo are spawned",
		author    	= "res",
		date      	= "24-11-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= -99,
		enabled   	= true,
	}
end




--[[

	Does:
		1. spawns tornado's that picks up units and buildings
		2. lift them up and trow them away after some time

	TODO:
		1. moving tornado's
		2. appearing and disappearing tornado's
		3. wobbling tornado's (not straight angle)
		4. different sizes of tornado's (this should be calculated: angle,speed,updatetime)
		5. add feature support (flying features?)
		6. fix projectile properties (speed, model randomness)
		7. make projectiles, fying units and tornado's classes?

		for instance

		unitFlying[unitID].move(dx,dy.dz)
		unitFlying[unitID].explode
		unitFlying[unitID].isValid
		unitFlying[unitID].rotate


]]--



-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --


local floor 				= math.floor
local random				= math.random
local sqrt					= math.sqrt
local max					= math.max

local gmatch				= string.gmatch
local remove				= table.remove

local modOptions 			= Spring.GetModOptions()
local SetFeatureHealth		= Spring.SetFeatureHealth
local DestroyFeature		= Spring.DestroyFeature
local GetFeatureHealth		= Spring.GetFeatureHealth
local GetFeaturePosition	= Spring.GetFeaturePosition
local AddUnitDamage 		= Spring.AddUnitDamage
local GetFeaturesInSphere	= Spring.GetFeaturesInSphere
local GetUnitsInSphere		= Spring.GetUnitsInSphere
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitDefID			= Spring.GetUnitDefID
local GetFeatureDefID		= Spring.GetFeatureDefID
local Echo					= Spring.Echo
local GetUnitsInCylinder	= Spring.GetUnitsInCylinder
local GetGroundHeight		= Spring.GetGroundHeight
local GetGroundOrigHeight	= Spring.GetGroundOrigHeight
local SetHeightMapFunc		= Spring.SetHeightMapFunc
local PlaySoundFile			= Spring.PlaySoundFile
local SetHeightMap 			= Spring.SetHeightMap
local SpawnCEG				= Spring.SpawnCEG
local GaiaTeamID  			= Spring.GetGaiaTeamID()
local SetUnitNeutral		= Spring.SetUnitNeutral
local SetUnitNoSelect		= Spring.SetUnitNoSelect
local CreateUnit			= Spring.CreateUnit
local DestroyUnit			= Spring.DestroyUnit
local SetUnitAlwaysVisible	= Spring.SetUnitAlwaysVisible
local SetUnitPosition 		= Spring.SetUnitPosition
local SetUnitStealth		= Spring.SetUnitStealth
local TransferUnit			= Spring.TransferUnit
local GetTeamList 			= Spring.GetTeamList()
local GetAllUnits 			= Spring.GetAllUnits
local ValidFeatureID 		= Spring.ValidFeatureID
local ValidUnitID 			= Spring.ValidUnitID

local GetUnitsInCylinder 	= Spring.GetUnitsInCylinder

local crushsnd				= "sounds/battle/crush3.wav"

local mapX 					= Game.mapX
local mapZ 					= Game.mapY


local projectiles 			= {}
local flyingUnits 			= {}
local SpawnProjectile 		= Spring.SpawnProjectile
local projectilesFlying		= 0
local tornados				= {}
local tornadoData			= {}  	-- data of all alive tornado's
local tornadoNumber			= 0		-- index for tornado list
local tornadoNumberUnit		= {}	-- stored which unit belong to which tornado
local tornadoNumberProj		= {}	-- stored which projectile belong to which tornado

-- SETTINGS --

local moving = {
	["kbotsf2"] 	= true, 
	["kbotsf3"] 	= true,					
	["kbotss2"] 	= true,						
	["kbotuw3"] 	= true,	-- gimp, spiders, moved land pelican to this
	--["kbotds2"] 	= true,	 		-- commanders
	["tankbh3"] 	= true,	 					
	["tankdh3"] 	= true,	-- beaver, crab, triton, crock, garpike, muskrat, zulu
	["tanksh2"] 	= true,	 					
	["tanksh2"] 	= true,	 					
	["tanksh4"] 	= true,	 					
	["tankdtcrush"] = true,	-- Bulldog/Reaper/Goliath can crush DT's
	["spid3"] 		= true,
	["krogoth"] 	= true,						
	["crawlbomb"] 	= true,	-- crawling bombs
	["tankdh4"] 	= true,	-- beaver, crab, triton, crock, garpike, muskrat, zulu -- land
	["hover1"] 		= true,
	["hover2"]		= true,
	["hover3"]		= true,
	["hover4"]		= true,
	["hover9"]		= true,
	["hover10"]		= true,
}



local p
for name,data in pairs(WeaponDefNames) do
	local weaponDefID = WeaponDefNames[name].id
	local cp = WeaponDefs[weaponDefID].customParams
	if cp ~= nil and name == 'kbot_rocket' then
		p = weaponDefID
	end
end


-- INITIALISE --


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.tornedo)== 0 then
		Echo("tornedo.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	Echo("tornedo.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
end


local function projectileParams(px, py, pz, ex, ey, ez, sx,sy, sz)
	local ttl = random(2000,5000)
	return {
		['pos'] = {px, py, pz},
   		['end'] = {ex, ey, ez},
   		['speed'] = {sx, sy, sz},
   		['ttl'] = ttl,
   		['maxRange'] = 5000, --number,
	}
end


local function unitParams(unitID, x,y,z)
	local vy = 0.1 + 2*random()
	return {
		['radius'] = 500,
		['duration'] = 1000,
		['x'] = x,
		['y'] = y,
		['z'] = z,
		['unitID'] = unitID,
		['vy'] = vy
	}
end


local function addProjectile(number)

	local pos = tornadoData[number].pos
	local x, y, z = pos.x, pos.y, pos.z
	local radius = tornadoData[number].radius

	local xx = random(x-radius, x+radius)
	local zz = random(z-radius, z+radius)

	local d = sqrt( (x-xx)*(x-xx)+(z-zz)*(z-zz))/radius
	local velo = 2 + 1*(d) -- distance from center

	local a_x = xx-x
	local a_z = zz-z

	local norm = sqrt(a_x * a_x + a_z * a_z)
	a_x = a_x/norm
	a_z = a_z/norm
	local angle = 90
	local vx = a_x * math.cos(math.pi*angle/180) + a_z * math.sin(math.pi*angle/180)
	local vz = -a_x * math.sin(math.pi*angle/180) + a_z * math.cos(math.pi*angle/180)

	local height = random(y+10, y + 200)
	local params = projectileParams(xx,y+height,zz,xx+10,y+height,zz+10,vx,0.1,vz)
	local projID = SpawnProjectile(p, params)

	params["projID"] = projID
	params["velo"] = velo
	tornadoNumberProj[projID] = number
	tornadoData[number].projectiles[#tornadoData[number].projectiles+1] = params
end


local function addUnit(unitID,ux , uy, uz, number)
	if ValidUnitID(unitID)  and uy < tornadoData[number].height then

		local pos = tornadoData[number].pos
		local x, y, z = pos.x, pos.y, pos.z

		local a_x = ux-x
		local a_z = uz-z
		local norm = sqrt(a_x * a_x + a_z * a_z)

		a_x = a_x/norm
		a_z = a_z/norm

		local angle = 90
		local vx = a_x * math.cos(math.pi*angle/180) + a_z * math.sin(math.pi*angle/180)
		local vz = -a_x * math.sin(math.pi*angle/180) + a_z * math.cos(math.pi*angle/180)
		local params = unitParams(unitID, x,y,z)
		local rotx = 0
		local roty = 0
		local rotz = 0
		local dragx = 0
		local dragy = 0
		local dragz = 0
		Spring.MoveCtrl.Enable(unitID)
		Spring.MoveCtrl.SetGravity(unitID, 0)
		--Spring.SetUnitPhysics(unitID, x, y+100, z, 2, 0, 2, rotx, roty , rotz,  dragx, dragy, dragz)
		Spring.MoveCtrl.SetVelocity(unitID, vx, params.vy, vz)
		return params
	else
		return nil
	end
end


local function scanTorpedoArea(number)
	local tornado = tornadoData[number]
	local units = GetUnitsInCylinder(tornado.pos.x, tornado.pos.z, tornado.radius)
	for index, unitID in pairs(units) do
		if tornado.units[unitID] == nil and tornadoNumberUnit[unitID] == nil then
			local x,y,z = GetUnitPosition(unitID)
			if y < tornado.height then
				tornadoNumberUnit[unitID] = number
				tornadoData[number].units[unitID] = addUnit(unitID, x, y, z, number)
			end
		end
	end
end


local function spinProjectiles(number)
	for index, v in pairs(tornadoData[number].projectiles) do

		local projID = v.projID
		local velo = v.velo
		local x, y, z = Spring.GetProjectilePosition(projID)

		-- still exists
		if x ~= nil then

			local vx, vy, vz = Spring.GetProjectileVelocity(projID)
			local norm = math.sqrt(vx*vx+vy*vy+vz*vz)

			local angle = 40
			local xx = vx * math.cos(math.pi*angle/180) + vz * math.sin(math.pi*angle/180)
			local zz = -vx * math.sin(math.pi*angle/180) + vz * math.cos(math.pi*angle/180)

			local norm = math.sqrt(xx*xx + zz*zz)
			xx = xx/norm*velo
			zz = zz/norm*velo
			Spring.SetProjectileVelocity(projID,xx, vy, zz)
		end
	end
end


local function spinUnits(number)

	for unitID, v in pairs(tornadoData[number].units) do


		if ValidUnitID(unitID) then

			local vx, vy, vz, velLen =  Spring.GetUnitVelocity(unitID)
			local x,y,z = GetUnitPosition(unitID)

			-- spinning
			if y < Spring.GetGroundOrigHeight(x,z) + 400 then

				local angle = 35
				local xx = vx * math.cos(math.pi*angle/180) + vz * math.sin(math.pi*angle/180)
				local zz = -vx * math.sin(math.pi*angle/180) + vz * math.cos(math.pi*angle/180)

				local norm = math.sqrt(xx*xx + zz*zz)
				xx = xx/norm*3
				zz = zz/norm*3
				Spring.MoveCtrl.SetVelocity(unitID, xx, v.vy, zz)


			elseif y < Spring.GetGroundOrigHeight(x,z) + 500 then

				local angle = 35
				local xx = vx * math.cos(math.pi*angle/180) + vz * math.sin(math.pi*angle/180)
				local zz = -vx * math.sin(math.pi*angle/180) + vz * math.cos(math.pi*angle/180)
				Spring.MoveCtrl.SetVelocity(unitID, 1.1*xx, 1, 1.1*zz)

			else

				Spring.MoveCtrl.Disable(unitID)
				Spring.SetUnitCrashing(unitID, true)
				tornadoNumberUnit[unitID] = nil
				tornadoData[number].units[unitID] = nil
			end
		end

	end

end


local function removeTornado(number)

	-- makeall units fall
	for unitID, v in pairs(tornadoData[number].units) do
		Spring.MoveCtrl.Disable(unitID)
		Spring.SetUnitCrashing(unitID, true)
		tornadoNumberUnit[unitID] = nil
		tornadoData[number].units[unitID] = nil
	end

	for index, v in pairs(tornadoData[number].projectiles) do
		Spring.DeleteProjectile(v.projID)

	end

end


local function addTornado()


	local x = floor(random(0,  mapX*512))
	local z = floor(random(0,  mapZ*512))

	local randx = random(-300,300)
	local randz = random(-300,300)
	local randx2 = random(x+randx-300,x+randx+300)
	local randz2 = random(z+randz-300,z+randz+300)

	local y = Spring.GetGroundOrigHeight(x,z)
	local test_radius = 100
	tornadoNumber = tornadoNumber + 1
	tornadoData[tornadoNumber] = {
		['pos'] = {
			['x'] = x,
			['y'] = y,
			['z'] = z
		},
		['heading']	= {
			[1] = {['x'] = x,
				   ['y'] = y,
				   ['z'] = z},
			[2] = {['x'] = x + randx,
				   ['y'] = GetGroundOrigHeight(x + randx, randz),
				   ['z'] = z + randz},
			[3] = {['x'] = x + randx2,
				   ['y'] = GetGroundOrigHeight(randx2, randz2),
				   ['z'] = z + randz2},
		},
		['radius'] 		= 100,
		['duration'] 	= 4000,
		['width'] 		= 100,	-- not used yet
		['height'] 		= 1000, --not used yet
		['n_proj'] 		= 0, --number of projectiles in tornedo
		['projectiles'] = {}, --projectiles
		['units'] 		= {} --units in tornado
	}
	return tornadoNumber
end



local function tornadoFX(number)
	local pos = tornadoData[number].pos
	local x, y, z = pos.x, pos.y, pos.z
	local metalcloud2 = "smokeshell_medium"
	local height = random(y,700)
	SpawnCEG(metalcloud2,x, height, z)
end


local function updateTornados()

	-- check if there are enough tornado's (if not make a new one)
	if #tornados < 5 then
		tornados[#tornados+1] = addTornado()
	end

	--add projectiles
	for i=#tornados,1,-1 do

		if tornadoData[tornados[i]].duration < 0 then

			removeTornado(tornados[i])
			remove(tornados, i)
		else

			tornadoData[tornados[i]].duration = tornadoData[tornados[i]].duration - 22

		end

		-- add posibly more projectiles
		if tornadoData[tornados[i]].n_proj < 100 then

			addProjectile(tornados[i])
			tornadoData[tornados[i]].n_proj = tornadoData[tornados[i]].n_proj + 1

		end

		-- scan area to lift more units if necessary
		scanTorpedoArea(tornados[i])

		-- add some fx
		tornadoFX(tornados[i])

	end

end


local function updateHeading(number)
	local heading = tornadoData[number].heading[1]
	local x,y,z = heading.x,heading.y,heading.z
	local randx = random(-300,300)
	local randz = random(-300,300)
	local randx2 = random(x+randx-300,x+randx+300)
	local randz2 = random(z+randz-300,z+randz+300)
	-- this should account for map coordinates
	tornadoData[number].heading = {
		[1] = {['x'] = x,
			   ['y'] = y,
			   ['z'] = z},
		[2] = {['x'] = x + randx,
			   ['y'] = GetGroundOrigHeight(x + randx, randz),
			   ['z'] = z + randz},
		[3] = {['x'] = x + randx2,
			   ['y'] = GetGroundOrigHeight(randx2, randz2),
			   ['z'] = z + randz2},
	}
end



local function moveUnits(number, dx, dy, dz)

	for unitID, v in pairs(tornadoData[number].units) do
		if ValidUnitID(unitID) then

			local x,y,z = GetUnitPosition(unitID)
			if y < Spring.GetGroundOrigHeight(x,z) + 500 then
				local vx,vy,vz = Spring.GetUnitVelocity(unitID)
				local rx,ry,rz = Spring.GetUnitRotation(unitID)
				Spring.MoveCtrl.SetPhysics(unitID, x+dx,y+dy,z+dz, vx,vy,vz, rx,ry,rz)
			end
		end
	end
end


local function moveProjectiles(number, dx, dy, dz)

	for index, v in pairs(tornadoData[number].projectiles) do

		local projID = v.projID
		local velo = v.velo
		local x, y, z = Spring.GetProjectilePosition(projID)

		-- still exists
		if x ~= nil then

			Spring.SetProjectilePosition(projID, x+dx,y+dy,z+dz)

		end

	end

end


local function updateLocation(number)

	-- make new heading
	local heading =  tornadoData[number].heading
	if #heading == 1 then
		updateHeading(number)
	end
	local heading =  tornadoData[number].heading

	-- change position
	local pos = tornadoData[number].pos
	local x, y, z = pos.x, pos.y, pos.z
	local heading = tornadoData[number].heading
	local hx, hy, hz = heading[1].x, heading[1].y, heading[1].z
	if sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z)) < 20 then
		hx, hy, hz = heading[2].x, heading[2].y, heading[2].z
		remove(heading, 1)
		tornadoData[number].heading = heading
	end
	local dx = hx-x
	local dy = hy-y
	local dz = hz-z
	dx = dx/sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z))*10
	dy = dy/sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z))*10
	dz = dz/sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z))*10
	tornadoData[number].pos = {
		['x'] = x + dx,
		['y'] = y + dy,
		['z'] = z + dz
	}

	-- change unit/projectile
	moveUnits(number, dx, dy, dz)
	moveProjectiles(number, dx, dy, dz)

end



local function spinTornados()

	for i=#tornados,1,-1 do

		-- do the spinning & moving?
		local number = tornados[i]		-- number that links to the tornado data
		spinProjectiles(number)
		spinUnits(number)

		-- do moving
		if random() <0.5 then
			updateLocation(number)
		end
	end
end


function gadget:GameFrame(f)

	if (f%11 == 0) then

		if (f%2==0) then

			updateTornados()

		else

			spinTornados()

		end

	end

end


function gadget:ProjectileDestroyed(projID)
	if tornadoNumberProj[projID] ~= nil then
		tornadoData[tornadoNumberProj[projID]].n_proj = max(0, tornadoData[tornadoNumberProj[projID]].n_proj - 1)
	end
end


-- HELP FUNCTIONS


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if tornadoNumberUnit[unitID] ~= nil then
		tornadoData[tornadoNumberUnit[unitID]].units[unitID] = nil
		tornadoNumberUnit[unitID] = nil
	end
end
