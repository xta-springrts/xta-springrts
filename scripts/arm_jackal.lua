local torso = piece "torso"
local lthigh = piece "lthigh"
local rthigh = piece "rthigh"
local rleg = piece "rleg"
local lleg = piece "lleg"
local rfoot = piece "rfoot"
local lfoot = piece "lfoot"
local butt = piece "butt"
local head = piece "head"
local buttguard = piece "buttguard"
local hood = piece "hood"
local backshield = piece "backshield"

local SIG_WALK = 2

local tspeed = math.rad (180)
local ta = math.rad (30)

local volume 			= 1.0
local soundPause 		= 300
local lastSound 		= 0
local PlaySoundFile 	= Spring.PlaySoundFile
local GetUnitPosition 	= Spring.GetUnitPosition
local GetGameFrame 		= Spring.GetGameFrame

function script.Create()
	Spring.SetUnitNeutral(unitID,true)
	Spring.SetUnitNoDraw(unitID,true)
end

function walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)		
	while (true) do
		Turn (rfoot, x_axis, ta, tspeed)
		Turn (lfoot, x_axis, -ta, tspeed)
		WaitForTurn (lfoot, x_axis)
		WaitForTurn (lfoot, x_axis)
		
		Turn (rfoot, x_axis, -ta, tspeed)
		Turn (lfoot, x_axis, ta, tspeed)
		WaitForTurn (lfoot, x_axis)
		WaitForTurn (lfoot, x_axis)
		Sleep (10)
	end	
end

function stopwalk()
	Signal(SIG_WALK) --stop the walk thread
	Turn (rfoot, x_axis, 0, tspeed)
	Turn (lfoot, x_axis, 0, tspeed)
	Turn (torso, x_axis, math.rad (0), math.rad (45))
end

function script.StartMoving()
	--Spring.Echo ("start moving")
	Turn (torso, x_axis, math.rad (10), math.rad (45))
	if  GetGameFrame () -lastSound > soundPause then
		local snd
		local rnd = math.random (0,100)
		local x,y,z = GetUnitPosition(unitID)
		if  rnd < 35 then
			snd = 'sounds/critters/duckcall1.wav'
		elseif rnd < 70 then
			snd = 'sounds/critters/duckcall2.wav'
		else
			snd = 'sounds/critters/duckcall3.wav'
		end
		PlaySoundFile(snd,volume,x,y,z,0,0,0,'battle')
		lastSound = GetGameFrame ()
	end
	StartThread(walk)
end
	
function script.StopMoving()
	StartThread(stopwalk)
end

function script.QueryWeapon1() return torso end

function script.AimFromWeapon1() return torso end

function script.AimWeapon1( heading, pitch )
	return true
end

function script.Shot1()
	
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity <= 0.25 then	
		Explode(backshield, SFX.EXPLODE)
		Explode( butt, SFX.EXPLODE)
		Explode( buttguard,SFX.EXPLODE)
		Explode( head,SFX.EXPLODE)
		Explode( hood,SFX.EXPLODE)
		Explode( lfoot,SFX.EXPLODE)
		Explode( lleg,SFX.EXPLODE)
		Explode( lthigh,SFX.EXPLODE)
		Explode( rfoot,SFX.EXPLODE)
		Explode( rleg,SFX.EXPLODE)
		Explode( rthigh,SFX.EXPLODE)
		Explode( torso,SFX.EXPLODE)
		return 1 -- corpsetype
	elseif severity <= 0.50 then
		Explode( backshield,SFX.SHATTER)
		Explode( butt,SFX.NONE)
		Explode( buttguard,SFX.NONE)
		Explode( head,SFX.NONE)
		Explode( hood,SFX.NONE)
		Explode( lfoot,SFX.FALL)
		Explode( lleg,SFX.FALL)
		Explode( lthigh,SFX.FALL)
		Explode( rfoot,SFX.FALL)
		Explode( rleg,SFX.FALL)
		Explode( rthigh,SFX.FALL)
		Explode( torso,SFX.FALL)
		return 2 -- corpsetype
	elseif severity <= 0.99 then
		Explode( backshield,SFX.SHATTER)
		Explode( butt,SFX.FALL)
		Explode( buttguard,SFX.FALL)
		Explode( head, SFX.SMOKE)
		Explode( hood, SFX.SMOKE)
		Explode( lfoot,SFX.FALL)
		Explode( lleg,SFX.FALL)
		Explode( lthigh,SFX.FALL)
		Explode( rfoot,SFX.FALL)
		Explode( rleg,SFX.FALL)
		Explode( rthigh,SFX.FALL)
		Explode( torso, SFX.SMOKE)
		return 3 -- corpsetype
	else
		Explode( backshield,SFX.SHATTER)
		Explode( butt,SFX.FALL)
		Explode( buttguard,SFX.FALL)
		Explode( head,SFX.FALL)
		Explode( hood,SFX.FALL)
		Explode( lfoot,SFX.SMOKE)
		Explode( lleg,SFX.SMOKE)
		Explode( lthigh,SFX.SMOKE)
		Explode( rfoot,SFX.SMOKE)
		Explode( rleg,SFX.SMOKE)
		Explode( rthigh,SFX.SMOKE)
		Explode( torso,SFX.SMOKE)
		return 3 -- corpsetype
	end
end


