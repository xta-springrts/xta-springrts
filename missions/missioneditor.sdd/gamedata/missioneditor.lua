--------------------------------------------------------------------------------
-- Populate the buildmenu of Mission Wizzard
--------------------------------------------------------------------------------
for name, def in pairs(UnitDefs) do
	if UnitDefs[name].corpse then
		--Spring.Echo(name, UnitDefs[name].corpse)
	end
end

UnitDefs["zzz_mission_wizzard"].buildoptions = {}
for name in pairs(UnitDefs) do
	if UnitDefs[name].name ~= "Mission Wizzard" then
		table.insert(UnitDefs["zzz_mission_wizzard"].buildoptions, name)
	end
end
table.sort(UnitDefs["zzz_mission_wizzard"].buildoptions)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------