function gadget:GetInfo()
  return {
    name      = "enablecheats",
    desc      = "Enable cheat and nocost mode",
	version   = "1.0",
    author    = "Jools",
    date      = "Jan, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
	handler   = true,
  }
end
	
if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	local Echo = Spring.Echo
	
	function gadget:Initialize()
		
		--gadgetHandler.actionHandler.AddChatAction(gadget,'start-profile', startProfile, "Start profiling")
		--gadgetHandler.actionHandler.AddChatAction(gadget,'stop-profile', stopProfile, "Stop profiling")
		
		local modOptions = Spring.GetModOptions()
		
		local enable = false
		-- allow cheats only for SVN version or if chosen in modoptions
		if modOptions and modOptions.debugmode then
			if modOptions.debugmode == '1' then 
				enable = true 
			end
		else
			if Game.modVersion =='$VERSION' then 
				enable = true 
			end
		end
		
		if enable then			
			Spring.SendCommands ("cheat 1") 
			--Spring.SendCommands ("nocost")
			--Spring.SendCommands ("globallos")
			Spring.Echo("dbg_cheats.lua: loaded for XTA version " .. Game.modVersion)
		end
	end
	
	function startProfile()
		Spring.Echo("Started profiling")
		gadgetHandler:EnableGadget("Profiler")
	end
	
	function stopProfile()
		Spring.Echo("Stopped profiling")
		gadgetHandler:DisableGadget("Profiler")
	end
	
else
end