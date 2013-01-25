
function gadget:GetInfo()
  return {
    name      = "State Broadcast",
    desc      = "Broadcast player state in game setup phase",
	version   = "1.1",
    author    = "Jools",
    date      = "October,2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

local playerMarked = {}

if not gadgetHandler:IsSyncedCode() then
	
	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local positionRegex = "181072"
	local spGetTeamStartPosition = Spring.GetTeamStartPosition
		
	function gadget:Update()
		--Spring.Echo("State Broadcasting...")
		for i,player in ipairs(Spring.GetTeamList()) do
			if player ~= Spring.GetGaiaTeamID() then	
				local posx = spGetTeamStartPosition(player)
				local marked
				
				if posx and posx >= 0 then
					marked = true
				else
					marked = false
				end
				
				if marked then 
					if not playerMarked[i] then
						Spring.SendLuaUIMsg (positionRegex .. 1 .. player)
						playerMarked[i] = true
						--Spring.Echo("mark state: ",i,player, marked)
					end
				else
					if playerMarked[i] then
						Spring.SendLuaUIMsg (positionRegex .. 0 .. player)
						playerMarked[i] = false
						--Spring.Echo("mark state: ",i,player, marked)
					end
				end
			end
		end
		return false
	end
	
	--function gadget:MapDrawCmd(playerID, cmdType, px, py, pz, labeltext) 
		-- the ideal location to catch changes in player state would be this callin, but it is not yet implemented in Spring (marked FIXME)
		-- https://github.com/spring/spring/blob/master/cont/base/springcontent/LuaGadgets/gadgets.lua
		-- We use mousepress as a temporal fix
	--end
	
	
else
	-----------------
	-- SYNCED PART --
	-----------------
	
	function gadget:Initialize()
		for i,_ in ipairs(Spring.GetTeamList()) do
			playerMarked[i] = false
		end
	end
	
	function gadget:GameStart()
		--Spring.Echo("State Broadcast ended")
		gadgetHandler:RemoveGadget(self)
	end
	
end