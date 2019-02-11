function gadget:GetInfo()
	return {
		name      	= "tornado",
		desc      	= "tornado are spawned",
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
		3. tornado's move around the map (appear and disappear)
		4. units outside the map get destroyed (buildings)

	TODO:

		4. different sizes of tornado's (this should be calculated: angle,speed,updatetime)
		5. add feature support (flying features?)
		6. fix projectile properties (speed, model randomness)
		7. sounds/units/windgen2.wav

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
local cos					= math.cos
local sin					= math.sin
local pi 					= math.pi
local gmatch				= string.gmatch
local remove				= table.remove
local pairs					= pairs
local abs					= math.abs

local modOptions 			= Spring.GetModOptions()
local maxTornados          	= tonumber(modOptions.max_tornados) or 10
local number_of_tornados 	= random(0, maxTornados)

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
local MoveCtrlEnable		= Spring.MoveCtrl.Enable
local MoveCtrlSetGravity 	= Spring.MoveCtrl.SetGravity
local MoveCtrlSetVelocity 	= Spring.MoveCtrl.SetVelocity
local MoveCtrlSetPhysics	= Spring.MoveCtrl.SetPhysics
local MoveCtrlDisable 		= Spring.MoveCtrl.Disable
local DeleteProjectile		= Spring.DeleteProjectile
local GetProjectilePosition = Spring.GetProjectilePosition
local GetProjectileVelocity = Spring.GetProjectileVelocity
local SpawnProjectile 		= Spring.SpawnProjectile
local SetProjectileVelocity = Spring.SetProjectileVelocity
local GetUnitVelocity		= Spring.GetUnitVelocity
local GetGroundOrigHeight 	= Spring.GetGroundOrigHeight
local GetUnitRotation		= Spring.GetUnitRotation
local SetUnitCrashing		= Spring.SetUnitCrashing
local SetProjectilePosition = Spring.SetProjectilePosition
local mapX 					= Game.mapX
local mapZ 					= Game.mapY
local projectiles 			= {}
local flyingUnits 			= {}
local projectilesFlying		= 0
local tornados				= {}
local tornadoData			= {}  	-- data of all alive tornado's
local tornadoNumber			= 0		-- index for tornado list
local tornadoNumberUnit		= {}	-- stored which unit belong to which tornado
local tornadoNumberProj		= {}	-- stored which projectile belong to which tornado
local buildings				= {}
local eceg 						= "gplasmaballbloom"
local metalcloud3				= "smokeshell_medium_tornado" -- nice raining efx
local metalcloud2				= "smokeshell_medium"
local p
for name,data in pairs(WeaponDefNames) do
	local weaponDefID = WeaponDefNames[name].id
	local cp = WeaponDefs[weaponDefID].customParams
	if cp ~= nil and name == 'kbot_rocket_tornado' then
		p = weaponDefID
	end
end

local random_map				= {}
local evenx 					= mapX%2==0 and 2 or 1 -- only make 1024x1024 sectors if possible
local evenz 					= mapZ%2==0 and 2 or 1
for i=0,mapX*512, evenx*512 do
	for j=0,mapZ*512, evenz*512 do
		random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
	end
end
for i=0,mapX*512, evenx*512 do
	for j=0,mapZ*512, evenz*512 do
		random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
	end
end
local nheatmap = #random_map
local counter = 0

local function remake_heatmap()
	local temp = {}
	for i=0,mapX*512, evenx*512 do
		for j=0,mapZ*512, evenz*512 do
			random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
		end
	end
	for i=0,mapX*512, evenx*512 do
		for j=0,mapZ*512, evenz*512 do
			random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
		end
	end
	random_map = temp
	Echo("updatemap")
end


local function random_coordinate()

	counter = counter == 0 and nheatmap or counter -1
	return random_map[counter][1], random_map[counter][2]

end






function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.tornado)== 0 then
		Echo("tornado.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	Echo("tornado.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	DisableMapDamage=0
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
	local vx = a_x * cos(pi*angle/180) + a_z * sin(pi*angle/180)
	local vz = -a_x * sin(pi*angle/180) + a_z * cos(pi*angle/180)
	local height = random(y+10, y + 400)
	local params = projectileParams(xx,y+height,zz,xx+10,0,zz+10,vx,0,vz)
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
		local vx = a_x * cos(pi*angle/180) + a_z * sin(pi*angle/180)
		local vz = -a_x * sin(pi*angle/180) + a_z * cos(pi*angle/180)
		local params = unitParams(unitID, x,y,z)

		MoveCtrlEnable(unitID)
		MoveCtrlSetGravity(unitID, 0)
		MoveCtrlSetVelocity(unitID, vx, params.vy, vz)
		return params
	else
		return nil
	end
end


local function scanTornadoArea(number)
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
		local x, y, z = GetProjectilePosition(projID)

		if x ~= nil then
			local vx, vy, vz = GetProjectileVelocity(projID)
			local norm = sqrt(vx*vx+vy*vy+vz*vz)
			local angle = 40
			local xx = vx * cos(pi*angle/180) + vz * sin(pi*angle/180)
			local zz = -vx * sin(pi*angle/180) + vz * cos(pi*angle/180)
			local norm = sqrt(xx*xx + zz*zz)
			xx = xx/norm*velo
			zz = zz/norm*velo
			SetProjectileVelocity(projID,xx, 0, zz)
		end
	end
end


local function spinUnits(number)

	for unitID, v in pairs(tornadoData[number].units) do


		if ValidUnitID(unitID) then

			local vx, vy, vz, velLen =  GetUnitVelocity(unitID)
			local x,y,z = GetUnitPosition(unitID)

			if y < GetGroundOrigHeight(x,z) + 400 then

				local angle = 35
				local xx = vx * cos(pi*angle/180) + vz * sin(pi*angle/180)
				local zz = -vx * sin(pi*angle/180) + vz * cos(pi*angle/180)
				local norm = sqrt(xx*xx + zz*zz)
				xx = xx/norm*3
				zz = zz/norm*3

				local rx,ry,rz = GetUnitRotation(unitID)
				if random() < 0.2 then
					rx = rx + random()*0.2
					ry = ry + random()*0.2
					rz = rz + random()*0.2
				end
				MoveCtrlSetPhysics(v.unitID, x, y, z, xx, v.vy, zz, rx, ry , rz,  0, 0, 0)

			elseif y < GetGroundOrigHeight(x,z) + 500 then

				local angle = 35
				local xx = vx * cos(pi*angle/180) + vz * sin(pi*angle/180)
				local zz = -vx * sin(pi*angle/180) + vz * cos(pi*angle/180)
				MoveCtrlSetVelocity(unitID, 1.1*xx, 1, 1.1*zz)

			else

				MoveCtrlSetGravity(unitID, 1)
				SetUnitCrashing(unitID, true)
				local UDID = GetUnitDefID(unitID)
				if UnitDefs[UDID].isBuilding then
					buildings[unitID] = 300 -- remove after 300 seconds from list
				else
					MoveCtrlDisable(unitID)
				end
				tornadoNumberUnit[unitID] = nil
				tornadoData[number].units[unitID] = nil

			end
		end

	end

end


local function removeTornado(number)
	for unitID, v in pairs(tornadoData[number].units) do
		if ValidUnitID(unitID) then
			MoveCtrlSetGravity(unitID, 1)
			SetUnitCrashing(unitID, true)
			local UDID = GetUnitDefID(unitID)
			if UnitDefs[UDID].isBuilding then
				buildings[unitID] = 300
			else
				MoveCtrlDisable(unitID)
			end
			tornadoNumberUnit[unitID] = nil
			tornadoData[number].units[unitID] = nil
		end
	end

	for index, v in pairs(tornadoData[number].projectiles) do
		DeleteProjectile(v.projID)
		tornadoNumberProj[v.projID] = nil
	end
end


local function updateHeading(number)
	local heading = tornadoData[number].heading[1]
	local x,y,z = heading.x,heading.y,heading.z

	local newx1 = -1
    while newx1 < 0 or newx1 > mapX*512 or abs(newx1 - x) < 100 do
     	newx1 = x + floor(random(-800,  800))
    end
	local newz1 = -1
	while newz1 < 0 or newz1 > mapZ*512 or abs(newz1 - z) < 100 do
     	newz1 = z + floor(random(-800,  800))
    end

	local newx2 = -1
    while newx2 < 0 or newx2 > mapX*512 or abs(newx1 - newx2) < 100 do
     	newx2 = newx1 + floor(random(-800,  800))
    end

	local newz2 = -1
	while newz2 < 0 or newz2 > mapZ*512 or abs(newz1 - newz2) < 100 do
     	newz2 = newz1 + floor(random(-800,  800))
    end

	tornadoData[number].heading = {
	[1] = {['x'] = x,
		   ['y'] = y,
		   ['z'] = z},
	[2] = {['x'] = newx1,
		   ['y'] = GetGroundOrigHeight(newx1, newz1),
		   ['z'] = newz1},
	[3] = {['x'] = newx2,
		   ['y'] = GetGroundOrigHeight(newx2, newz2),
		   ['z'] = newz2},
	}
end


local function addTornado()

    local x, z = random_coordinate()
	local y = GetGroundOrigHeight(x,z)
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
		},
		['radius'] 		= 100,
		['duration'] 	= 4000,
		['width'] 		= 100,	-- not used yet
		['height'] 		= 1000, --not used yet
		['n_proj'] 		= 0, --number of projectiles in tornedo
		['projectiles'] = {}, --projectiles
		['units'] 		= {} --units in tornado
	}
	updateHeading(tornadoNumber)
	return tornadoNumber
end


local function updateTornados()

	if #tornados < number_of_tornados then
		tornados[#tornados+1] = addTornado()
	end

	for i=#tornados,1,-1 do

		local remove_tornado = false
		if tornadoData[tornados[i]].duration < 0 then

			removeTornado(tornados[i])
			remove(tornados, i)
			remove_tornado = true
		else

			tornadoData[tornados[i]].duration = tornadoData[tornados[i]].duration - 22

		end

		if not remove_tornado then
			if tornadoData[tornados[i]].n_proj < 50 then

				addProjectile(tornados[i])
				tornadoData[tornados[i]].n_proj = tornadoData[tornados[i]].n_proj + 1

			end

			scanTornadoArea(tornados[i])
		end

	end

end

local function moveUnits(number, dx, dy, dz)
	for unitID, v in pairs(tornadoData[number].units) do
		if ValidUnitID(unitID) then
			local x,y,z = GetUnitPosition(unitID)
			if y < GetGroundOrigHeight(x,z) + 500 then
				local vx,vy,vz = GetUnitVelocity(unitID)
				local rx,ry,rz = GetUnitRotation(unitID)
				MoveCtrlSetPhysics(unitID, x+dx,y+dy,z+dz, vx,vy,vz, rx,ry,rz)
			end
		end
	end
end


local function moveProjectiles(number, dx, dy, dz)
	for index, v in pairs(tornadoData[number].projectiles) do
		local projID = v.projID
		local velo = v.velo
		local x, y, z = GetProjectilePosition(projID)
		if x ~= nil then
			SetProjectilePosition(projID, x+dx,y+dy,z+dz)
		end
	end
end


local function updateLocation(number)

	local heading =  tornadoData[number].heading
	if #heading == 1 then
		updateHeading(number)
	end
	local heading =  tornadoData[number].heading

	local pos = tornadoData[number].pos
	local x, y, z = pos.x, pos.y, pos.z
	local heading = tornadoData[number].heading
	local hx, hy, hz = heading[1].x, heading[1].y, heading[1].z
	if sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z)) < 30 then
		hx, hy, hz = heading[2].x, heading[2].y, heading[2].z
		remove(heading, 1)
		tornadoData[number].heading = heading
	end

	local dx = (hx-x)/sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z))*10
	local dy = (hy-y)/sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z))*10
	local dz = (hz-z)/sqrt((hx-x)*(hx-x)+(hy-y)*(hy-y)+(hz-z)*(hz-z))*10
	tornadoData[number].pos = {
		['x'] = x + dx,
		['y'] = y + dy,
		['z'] = z + dz
	}
	moveUnits(number, dx, dy, dz)
	moveProjectiles(number, dx, dy, dz)

end


local function spinTornados()
	for i=#tornados,1,-1 do

		local number = tornados[i]
		spinProjectiles(number)
		spinUnits(number)

		if random() <0.5 then
			updateLocation(number)
		end
	end
end


local function updateFlyingBuildings()
	for unitID, duration  in pairs(buildings) do
		if ValidUnitID(unitID) then
			local x,y,z = GetUnitPosition(unitID)

			if x < mapX*512 and x > 0 and z < mapZ*512 and z > 0 then

				if duration < 0 then
					MoveCtrlSetVelocity(unitID, 0, 0, 0)
					MoveCtrlDisable(unitID)
				else
					buildings[unitID] = duration - 1
				end

				if y < GetGroundOrigHeight(x,z) + 50 then
					MoveCtrlSetVelocity(unitID, 0, 0, 0)
					MoveCtrlDisable(unitID)
					buildings[unitID] = nil
				end

			else

				if y < GetGroundOrigHeight(x,z) + 50 then
					MoveCtrlSetVelocity(unitID, 0, 0, 0)
					MoveCtrlDisable(unitID)
					buildings[unitID] = nil
					DestroyUnit(unitID)
				end

			end
		end
	end
end


function gadget:GameFrame(f)

	if (f%10000==0) then
		number_of_tornados = random(0, maxTornados)
	end

	updateFlyingBuildings()

	if (f%11 == 0) then

		if (f%2==0) then

			updateTornados()

		else

			spinTornados()


			if (f%1000==0) then
				remake_heatmap()
			end

		end

	end

end


function gadget:ProjectileDestroyed(projID)
	if tornadoNumberProj[projID] ~= nil then
		tornadoData[tornadoNumberProj[projID]].n_proj = max(0, tornadoData[tornadoNumberProj[projID]].n_proj - 1)
	end
end


function gadget:UnitDestroyed(unitID)
	if tornadoNumberUnit[unitID] ~= nil then
		tornadoData[tornadoNumberUnit[unitID]].units[unitID] = nil
		tornadoNumberUnit[unitID] = nil
	end
end

