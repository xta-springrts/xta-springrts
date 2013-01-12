In order to play a mission, drag and drop the XTA_*_mission.txt file over the Spring.exe
dunno how this works on linux, but linux users should be smart enough to figure
it out on their own

XTA_test_mission will load XTA_tutorial_mission upon victory

So far both missions use "Altair_Crossing_v3" map  http://springfiles.com/spring/spring-maps/altair-crossing


XTA_long_sea_mission uses "SailAway" map  http://springfiles.com/spring/spring-maps/sailaway

XTA_easy_mission uses "Red Comet" map  http://springfiles.com/spring/spring-maps/redcomet

XTA_sniper_alley_mission uses "Hide_and_Seek_v03" map  http://springfiles.com/spring/spring-maps/hideandseekv03


If you want to use mission editor, extract it into Spring/games or equivalent folder,
so that it looks like this Spring/games/MissionEditor.sdd/ (bunch of folders and files)
and start the Spring.exe and choose "Deadnight Warrior's Mission Editor 1.0" game

After you're done placing units and buildings on the map (give something to other teams too),
select the "Mission Wizzard" unit and give it the "Dump" command. That will save the unit,
building, and feature (wrecks and walls) placement to Spring/LuaUI/XTA_mission_editor_dump.lua

Now you can manualy add triggers and locations to the mission template, then save it to
Spring/Missions folder. Trigger documentation is in the TestMission.lua inside XTA/Missions
archive

For more than one opponent, start a game with allied NullAIs from a lobby, edit the generated
start script afterwards by adding the mission=missionname; tag to the modoptions array.
The missionname must corespond to the previously generated mission.lua file.