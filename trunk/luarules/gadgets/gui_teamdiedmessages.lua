function gadget:GetInfo()
  return {
    name      = "TeamDiedMessages",
    desc      = "Prints a message when a Team died",
    author    = "Jools",
    date      = "Sep, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true  --  loaded by default?
  }
end

if gadgetHandler:IsSyncedCode() then
	
	-------------------
	-- SYNCED PART --
	-------------------
	
	local Echo 							= Spring.Echo
	local PlaySoundFile					= Spring.PlaySoundFile
	local GetTeamRulesParam				= Spring.GetTeamRulesParam
	local messages, defaultmessages 	= include("LuaRules/Configs/gui_teamdiedmessages_defs.lua")
	
	function gadget:Initialize()
	end
	
	local function getMsg (attribute)
		local msg
		if attribute == 'Arm' or attribute == 'Core' then
			msg = defaultmessages[math.random(#defaultmessages)]
			return string.gsub(msg,'<side>',attribute)
		elseif attribute and #attribute > 0 then
			msg = messages[math.random(#messages)]
			return string.gsub(msg,'<tn>',attribute)
		else
			return "The enemy forces have been destroyed."
		end
	end

	function gadget:TeamDied(TeamID)
		local teamID, playerid,_,isAi = Spring.GetTeamInfo(TeamID)
		local msg
		
		if playerid and (not isAi) then
			local name = Spring.GetPlayerInfo(playerid)
			msg = getMsg(name)
		else
			local startUnit = GetTeamRulesParam(TeamID, 'startUnit')
			local suName = UnitDefs[startUnit].name
			
			if string.sub(suName,1,1) == 'a' then 
				msg = getMsg('Arm')
			elseif string.sub(suName,1,1) == 'c' then
				msg = getMsg('Core')
			else
				msg = getMsg('Enemy')
			end
		end
		PlaySoundFile("sounds/beep1.wav",3.0,0,0,0,0,0,0,'userinterface')
		Echo(msg)
	end	
end