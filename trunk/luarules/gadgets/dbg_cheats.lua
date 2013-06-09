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
  }
end
	
if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------

	function gadget:Initialize()
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
			Spring.SendCommands ("cheat") 	
			--Spring.SendCommands ("nocost")
			--Spring.SendCommands ("globallos")
			Spring.Echo("dbg_cheats.lua: loaded for XTA version " .. Game.modVersion)
		end
	end
	
else
end