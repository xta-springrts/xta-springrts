
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
local Echo = Spring.Echo

if not gadgetHandler:IsSyncedCode() then
	
	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local STATEMSG = "181072"
	local spGetTeamStartPosition = Spring.GetTeamStartPosition
	local GetGameFrame = Spring.GetGameFrame
			
	function gadget:Update()
		local frame = GetGameFrame()
		if frame > 0 then 
			gadgetHandler:RemoveGadget(self)
		end
		
		for i,player in ipairs(Spring.GetTeamList()) do
			if player ~= Spring.GetGaiaTeamID() then	
				local posx = spGetTeamStartPosition(player)
				local marked
				
				if posx and posx > 0 then -- change 95+: engine places people at 0,0 instantly
					marked = true
				else
					marked = false
				end
				
				if marked then 
					if not playerMarked[i] then
						Spring.SendLuaUIMsg (STATEMSG .. 1 .. player)
						playerMarked[i] = true
					end
				else
					if playerMarked[i] then
						Spring.SendLuaUIMsg (STATEMSG .. 0 .. player)
						playerMarked[i] = false
					end
				end
			end
		end
		return false
	end
	
	function gadget:GameStart()
		gadgetHandler:RemoveGadget(self)
	end
	
else
	-----------------
	-- SYNCED PART --
	-----------------
	
	function gadget:Initialize()
		for i,_ in ipairs(Spring.GetTeamList()) do
			playerMarked[i] = false
		end
	end
		
	function gadget:GameFrame(frame)
		-- Test if gadget is really removed
		if frame > 0 then
			gadgetHandler:RemoveGadget(self)
		end
	end
	
end