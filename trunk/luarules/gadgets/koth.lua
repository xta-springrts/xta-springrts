-- $Id$
-- CA Version

-- King of the Hill for ModOptions -------------------------------------
-- Set up an empty box on Spring Lobby (other clients might crash) ------
-- Set up the time to control the box in ModOptions --------------------
--------------------------------------------------------------------
local versionNumber = "1.1"

function gadget:GetInfo()
	return {
		name = "King of the Hill",
		desc = "obvious",
		author = "Alchemist, Licho, Jools",
		date = "Feb 2012",
		license = "Public domain",
		layer = 1,
		enabled = true
	}
end


local blockedDefs = {
	[ UnitDefNames['enterprise'].id ] = true,
}

---------------------------------------------------------------------------------

if(not Spring.GetModOptions()) then
	return false
end

local teamBoxes = {}

for _, allyTeamID in ipairs(Spring.GetAllyTeamList()) do 
	local teams = Spring.GetTeamList(allyTeamID)
	if  (teams == nil or #teams == 0) then
		local x1, z1, x2, z2 = Spring.GetAllyTeamStartBox(allyTeamID)
		if (x1 ~= nil) then
			Spring.Echo("box ally" .. allyTeamID)
			table.insert(teamBoxes, {x1, z1, x2, z2})
		end 
	end 
end 

LUAUI_DIRNAME							= 'LuaUI/'
local sndnotify 					= "Sounds/ding.wav"

--UNSYNCED-------------------------------------------------------------------
if(not gadgetHandler:IsSyncedCode()) then
	
	local fontHandler					= loadstring(VFS.LoadFile(LUAUI_DIRNAME.."modfonts.lua", VFS.ZIP_FIRST))()
	local UseFont             		 	= fontHandler.UseFont
	local TextDraw            		 	= fontHandler.Draw
	local teams = {}
	local teamTimer = nil
	local nagged = false
	local ticked = false
	local teamControl = -2
	local r, g, b = 255, 255, 255
	local grace = 1
	local sndtick 						= "Sounds/ticktock.wav"
	local font  						= "LuaUI/Fonts/FreeMonoBold_12"
	local font2     					= "LuaUI/Fonts/FreeSansBold_16"
		
local enabled = tonumber(Spring.GetModOptions().kingofthehill) or 0

if (enabled == 0) then 
  return false
end
	
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("changeColor", setBoxColor)
		gadgetHandler:AddSyncAction("changeTime", updateTimers)
	end
	
	function gadget:DrawWorldPreUnit()
		gl.DepthTest(false)
		gl.Color(r, g, b, 0.4)
		for _, box in ipairs(teamBoxes) do 
			gl.DrawGroundQuad(box[1], box[2], box[3], box[4], true)
		end 
	end

	
	function DrawScreen()
		local vsx, vsy = gl.GetViewSizes()
		local posx = vsx * 0.5
		if(grace > 0) then
			posy = vsy * 0.75
			gl.Color(255, 255, 255, 1)
			if(grace % 60 < 10) then
				gl.Text("Grace period over in " .. math.floor(grace/60) .. ":0" .. math.floor(grace%60), posx, posy, 14, "ocn")
			else
				gl.Text("Grace period over in " .. math.floor(grace/60) .. ":" .. math.floor(grace%60), posx, posy, 14, "ocn")
			end
		end
		if (teamControl >= 0) then 
			local posy = vsy * 0.25
			gl.Color(255, 255, 255, 1)
			if teamTimer > 0 then
				if teamTimer > 30 then
					if(teamTimer % 60 < 10) then				
						gl.Text("Team " .. teamControl + 1 .. " - " .. math.floor(teamTimer/60) .. ":0" .. math.floor(teamTimer%60), posx, posy, 12, "ocn")
					else
						gl.Text("Team " .. teamControl + 1 .. " - " .. math.floor(teamTimer/60) .. ":" .. math.floor(teamTimer%60), posx, posy, 12, "ocn")
					end
				else -- timer <= 30
					local gs 
					gs,_,_ = Spring.GetGameSpeed() or 1
					local f = Spring.GetGameFrame()
					local sf = math.sin(f/gs)
		
					if teamTimer == 30 and not nagged then
						Spring.PlaySoundFile(sndnotify)
						nagged = true
					end
					if teamTimer < 30 then nagged = false end
					
					gl.Color(1, 0, 0, 1-0.2*sf)
					if(teamTimer < 10) then				
						gl.Text("Team " .. teamControl + 1 .. " - " .. math.floor(teamTimer/60) .. ":0" .. math.floor(teamTimer%60), posx, posy, 12, "cn")
					else
						gl.Text("Team " .. teamControl + 1 .. " - " .. math.floor(teamTimer/60) .. ":" .. math.floor(teamTimer%60), posx, posy, 12, "cn")
					end
					
					if teamTimer > 25 then	
						UseFont(font2)
						gl.Color(1-0.2*sf,1-0.8*sf, 1-0.8*sf, 0.8)
						--Spring.Echo(sf)
						gl.Text("Time is running out!",posx+sf,posy+100+sf,16,"c")
						gl.Color(255, 255, 255, 1)
						UseFont(font)
					end
					
					if not ticked then
						if teamTimer < 30 then
							Spring.PlaySoundFile(sndtick)
						end
						ticked = true
					end
				end
			else
				gl.Text("KING OF THE HILL!", posx, posy, 12, "ocn")
			end
		end
	end
	
	function updateTimers(cmd, team, newTime, graceT)
		if(graceT) then
			grace = graceT
		else
			teamTimer = newTime
			teamControl = team
			nagged = false
			ticked = false
		end
	end
	
	function setBoxColor(cmd, team)
		if(team < 0) then
			r, g, b = 255, 255, 255
		else
			r, g, b = Spring.GetTeamColor(team)
		end
	end
	
end
---------------------------------------------------------------------------------

--SYNCED-----------------------------------------------------------------------
if(gadgetHandler:IsSyncedCode()) then

	local actualTeam = -1
	local control = -1
	local goalTime = 0 -- in seconds
	local timer = -1
	local lastControl = nil
	local lastHolder = nil
	local grace = 0
	local lG = 0

local enabled = tonumber(Spring.GetModOptions().kingofthehill) or 0

if (enabled == 0) then 
  return false
end

	
	function gadget:Initialize()
		goalTime = (Spring.GetModOptions().hilltime or 0) * 60
		lG = Spring.GetModOptions().gracetime
		if lG then
			grace = lG * 60
		else
			grace = 0
		end
		timer = goalTime
	end
	
	function gadget:GameStart()
		Spring.Echo("Goal time is " .. goalTime / 60 .. " minutes.")
	end

	function gadget:GameFrame(f)
		if(f%30 == 0 and f < grace * 30 + lG*30*60) then
			grace = grace - 1
			SendToUnsynced("changeTime", nil, nil, grace)
		end
		if(f == grace*30 + lG*30*60) then
			SendToUnsynced("changeTime", nil, nil, grace)
			Spring.PlaySoundFile(sndnotify)
			Spring.Echo("Grace period is over. GET THE HILL!")
		end
		if(f % 32 == 15 and f > grace*30 + lG*30*60) then
			local control = -2 
			local team = nil 
			local present = false 
			
			for _, box in ipairs(teamBoxes) do 
				for _, u in ipairs(Spring.GetUnitsInRectangle(box[1], box[2], box[3], box[4])) do
					local ally = Spring.GetUnitAllyTeam(u)
					local x,altitude,z = Spring.GetUnitBasePosition(u)
					local cloaked = Spring.GetUnitIsCloaked(u)
					local stunned = Spring.GetUnitIsStunned(u)
					local canControl = cloaked == false and stunned == false and altitude < Spring.GetGroundHeight(x,z) + 10
					--Spring.Echo("Cloaked:",cloaked,"Stunned:",stunned,"Alt:",altitude,"Ground",Spring.GetGroundHeight(x,z))
					if (lastControl == ally) then
						if canControl then
							present = true
						end
					end
				
					if (control == -2)  then 
						if (not blockedDefs[Spring.GetUnitDefID(u)]) then
							if canControl then
								control = ally
								team = Spring.GetUnitTeam(u)
							end
						end 
					else 
						if (control ~= ally) then 
							if canControl then
								control = -1
								break
							end
						end 
					end
				end 
			end 
			
			if(control ~= lastControl) then
				if (control == -1) then
					Spring.Echo("Control contested.")
					--Spring.PlaySoundFile(sndnotify)
					SendToUnsynced("changeColor", -1)
				else
					if (control == -2) then 
						Spring.Echo("Team " .. control + 1 .. " lost control.")
						--Spring.PlaySoundFile(sndnotify)
						SendToUnsynced("changeColor", -1)
						timer = goalTime
						SendToUnsynced("changeTime", control, timer)
					else 
						actualTeam = team
						if (lastHolder ~= control) then 
							timer = goalTime
							lastHolder = control
						end 
						
						Spring.Echo("Team " .. control + 1 .. " is now in control.")
						Spring.PlaySoundFile(sndnotify)
						SendToUnsynced("changeColor", actualTeam)
						lastHolder = control
					end
				end 
			end
			
			if (control >= 0) then 
				timer = timer - 1  
				SendToUnsynced("changeTime", control, timer)				
			end

			if(control >= 0 and timer == 0) then
				Spring.Echo("Team " .. control + 1 .. " has won!")
				gameOver(actualTeam)
			end 
			
			lastControl = control						

		end
	end
	
	
	function gameOver(team)
		for _, u in ipairs(Spring.GetAllUnits()) do
			if(not Spring.AreTeamsAllied(Spring.GetUnitTeam(u), team)) then
				Spring.DestroyUnit(u, true)
			end
		end
	end

end

