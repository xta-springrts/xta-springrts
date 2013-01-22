
function widget:GetInfo()
	return {
		name      = 'Next Mission Loader',
		desc      = 'Restart Spring to next mission after victory, displays mission briefing',
		author    = 'Deadnight Warrior',
		date      = '26 Jul 2012',
		license   = 'GNU LGPL v2',
		layer     = -1,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local modOptions = Spring.GetModOptions()
local gameData, briefing = {}, {}
local msgQueue = {}
local campaignData, bonUnits = {}, {}
local curMission, lastMission
local cmpgNotSent = true
local commander

local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitExperience = Spring.GetUnitExperience
local spValidUnitID = Spring.ValidUnitID

local glColor = gl.Color
local glRect = gl.Rect
local glTexRect = gl.TexRect
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local glTexture = gl.Texture

local dispBrief = true
local X, Y = Spring.GetViewGeometry()
local scale = Y/1200
local fs
local lef, rig, top, bot = (X-Y*1.333*.8)*0.5, (X+Y*1.333*.8)*0.5, .9*Y, .1*Y
local okL, okR, okT, okB

local defCmpgData = {
[[campaignData = {
	lastMission = "]],
[[",
	currentMission = "]],
[[",
	bonusUnits = {
]],
[[	},
}
return campaignData]]
}

local function SetBonusUnits(unitID)
	bonUnits[#bonUnits+1] = unitID
end

function widget:Initialize()
	if modOptions and modOptions.mission then
		local mission = "Missions/" .. modOptions.mission ..".lua"
		if VFS.FileExists(mission) then
			gameData, _, _, _, briefing = VFS.Include(mission)
			if gameData.game == Game.modShortName and gameData.minVersion <= Game.modVersion then
				if gameData.map ~= Game.mapName then
					widgetHandler:RemoveWidget()
				else
					widgetHandler:RegisterGlobal("SetBonusUnits", SetBonusUnits)
					cmpgNotSent, campaignData = pcall(include,"Config/" .. gameData.game .."_campaign.lua")
					if not briefing then
						dispBrief = false
					else
						fs = 23 * scale
						okL, okR, okT, okB = X*0.5-2*fs, X*0.5+2*fs, bot+3*fs, bot+fs
					end				
				end
			else
				widgetHandler:RemoveWidget()				
			end
		else
			widgetHandler:RemoveWidget()
		end
	else
		widgetHandler:RemoveWidget()
	end
end

function widget:GameStart()
	if briefing and dispBrief then
		local _, _, paused = Spring.GetGameSpeed()
		if not paused then
			Spring.SendCommands("pause")
		end
	end
end

function widget:GameOver()
	local amIDead = select(3, Spring.GetTeamInfo(Spring.GetMyTeamID()))
	if amIDead==false and gameData.nextMission then
		local nextMission = "Missions/" .. gameData.nextMission ..".txt"
		if VFS.FileExists(nextMission) then
			local file = io.open("LuaUI/Config/" .. gameData.game .. "_campaign.lua","w")
			file:write(defCmpgData[1] .. modOptions.mission .. defCmpgData[2] .. gameData.nextMission .. defCmpgData[3])
			for _, unitID in pairs(bonUnits) do
				if spValidUnitID(unitID) then
					local h, _, _, _, _ = spGetUnitHealth(unitID)
					if h>0 then
						file:write('\t\t"' .. UnitDefs[spGetUnitDefID(unitID)].name .. " " .. spGetUnitExperience(unitID) .. '"\n')
					end
				end
			end
			file:write(defCmpgData[4])
			file:flush()
			file:close()
			local startScript = VFS.LoadFile(nextMission)
			Spring.Restart("-s", startScript)
		end
	end
end

local mouseOverOK = false
function widget:IsAbove(x, y)
	if dispBrief and y>okB and y<okT and x>okL and x<okR then
		mouseOverOK = true
		return true
	end
	mouseOverOK = false
	return false
end

function widget:MousePress(mx, my, mButton)
	if mouseOverOK and mButton==1 then
		dispBrief = false
		widgetHandler:RemoveCallIn("DrawScreen")
		widgetHandler:RemoveCallIn("IsAbove")
		widgetHandler:RemoveCallIn("MousePress")
		local _, _, paused = Spring.GetGameSpeed()
		if paused then
			Spring.SendCommands("pause")
		end
	end
end

function widget:DrawScreen()
	if dispBrief then
		glPushMatrix()
		glTranslate(0,0,-0.1)
		glColor(0,0,0,0.92)
		glRect(lef,bot,rig,top)
		if mouseOverOK then
			glColor(0.2,0.2,0.2,0.75)
			glRect(okL,okB,okR,okT)
		end
		glBeginText()
			for i=1, #briefing, 1 do
				if briefing[i]:sub(1,1)=="$" then
					if briefing[i]:sub(2,2)=="c" then
						glText(briefing[i]:sub(3), X*0.5, top-i*(fs+2)-fs, fs, "cd")
					elseif briefing[i]:sub(2,2)=="r" then
						glText(briefing[i]:sub(3), rig-fs, top-i*(fs+2)-fs, fs, "rd")
					else
						glText(briefing[i], lef+fs, top-i*(fs+2)-fs, fs, "d")
					end
				else
					glText(briefing[i], lef+fs, top-i*(fs+2)-fs, fs, "d")
				end
			end
			glText("OK",X*0.5,bot+fs*1.4,fs,"cd")
		glEndText()
		glPopMatrix()
	end
	if cmpgNotSent then
		if modOptions.mission == campaignData.currentMission then
			local bu = campaignData.bonusUnits
			local mt = " " .. tostring(Spring.GetMyTeamID())
			for i=1, #bu do
				spSendLuaRulesMsg("XTA_cmpg " .. bu[i] .. " " .. mt)
			end
			--spSendLuaRulesMsg("XTA_cmpg " .. commander .. " " .. mt)
			campaignData.bonusUnits = {}
			cmpgNotSent = false
		end
	end
end