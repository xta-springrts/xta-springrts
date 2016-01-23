local body = piece "Sphere"

local volume 			= 5.0
local PlaySoundFile 	= Spring.PlaySoundFile
local GetUnitPosition 	= Spring.GetUnitPosition
local GetGameFrame 		= Spring.GetGameFrame
local SpawnCEG			= Spring.SpawnCEG
local hatchCEG			= "fireballbloom"
local snd 				= 'sounds/unit/egg_hatch.wav'

function script.Create()
	local buildprogress = select(5, Spring.GetUnitHealth(unitID))
	while buildprogress < 1 do
	Sleep(500)
	buildprogress = select(5, Spring.GetUnitHealth(unitID))
	end
	PlaySoundFile(snd,volume,x,y,z,0,0,0,'battle')
	Sleep(2000)
	local x,y,z = GetUnitPosition(unitID)
	local teamID = Spring.GetUnitTeam(unitID)
	local llt = Spring.CreateUnit("guardian_light_laser_tower",x,y,z,"s",teamID)
	-- copy orders
	local cmds = Spring.GetUnitCommands(unitID,10)
	for i = 1, #cmds do  
		local cmd = cmds[i]
		Spring.GiveOrderToUnit(llt, cmd.id, cmd.params, cmd.options.coded)
	end
	Spring.DestroyUnit(unitID)
end

function script.StartMoving()
	
end
	
function script.StopMoving()
	
end

function script.QueryWeapon1() return body end

function script.AimFromWeapon1() return body end

function script.AimWeapon1( heading, pitch )
	return true
end

function script.Shot1()
	
end

function script.Killed(recentDamage, maxHealth)
	local snd
	local rnd = math.random (0,100)
	local x,y,z = GetUnitPosition(unitID)
	SpawnCEG(hatchCEG,x,y,z)
end


