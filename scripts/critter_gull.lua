local wingr = piece "rwing"
local wingl = piece "lwing"
local flapSpeed = math.rad(360)
local volume 			= 5.0
local PlaySoundFile 	= Spring.PlaySoundFile
local GetUnitPosition 	= Spring.GetUnitPosition
local GetUnitVelocity   = Spring.GetUnitVelocity

function script.Create()
	StartThread (flapWings)
end

function script.Killed(recentDamage, maxHealth)

end

function flapWings()
	while (true) do
		for i=1,math.random (1,3) do
			Turn (wingr, z_axis, -math.rad(60),flapSpeed)
			Turn (wingl, z_axis, math.rad(60),flapSpeed)		
			WaitForTurn (wingr,z_axis)
			WaitForTurn (wingr,z_axis)
			Sleep (100)
			Turn (wingr, z_axis, 0,flapSpeed)
			Turn (wingl, z_axis, 0,flapSpeed)
			WaitForTurn (wingr,z_axis)
			WaitForTurn (wingr,z_axis)
		end		
		Sleep (math.random (500,2000))
		local x,y,z = GetUnitPosition(unitID)
		local vx,vy,vz = GetUnitVelocity(unitID)
		local snd
		local rnd = math.random (0,100)
		if rnd < 35 then
			snd =  'sounds/critters/seacry1.wav'
		elseif rnd < 70 then 
			snd =  'sounds/critters/seacry2.wav'
		else
			snd =  'sounds/critters/seacry3.wav'
		end
		PlaySoundFile(snd,volume,x,y,z,vx,vy,vz,'battle')
	end
end