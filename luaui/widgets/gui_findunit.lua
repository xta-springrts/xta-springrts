function widget:GetInfo()
	return {
		name = "Findunit",
		desc = "Displays a GUI for locating units",
		author = "Jools",
		date = "Mar, 2015",
		license = "GPLv2",
		version = "1.0",
		layer = 1,
		enabled = true
	}
end


local textSize						= 12
local myFont	 					= gl.LoadFont("FreeSansBold.otf",16, 1.9, 40)
local sizeX, sizeY					= 400, 240
local posx, posy					= 600, 400
local BARWIDTH						= 20
local MARGIN						= 10
local BARLENGTH						= 135
local vsx, vsy 						= gl.GetViewSizes()
local mapX 							= Game.mapX * 512
local mapY 							= Game.mapY * 512
local optCheckBoxOn			        = "luaui/images/findunit/chkboxon.png"
local optCheckBoxOff			    = "luaui/images/findunit/chkboxoff.png"

local myPlayerID					= Spring.GetMyPlayerID()
local myTeamID						= select(4,Spring.GetPlayerInfo(myPlayerID))
local Button						= {}
local glColor 						= gl.Color
local glRect						= gl.Rect
local TITLE							= ""
local Echo							= Spring.Echo
local showWindow 					= false
local OrangeStr  					= "\255\255\190\128"
local RedStr    					= "\255\255\092\092"
local GreyStr    					= "\255\210\210\210"
local WhiteStr   					= "\255\255\255\255"
local GreenStr   					= "\255\122\255\122"
local DarkGreenStr   				= "\255\072\185\072"
local BlueStr						= "\255\152\152\255"
local sndButtonOff 					= 'sounds/button6.wav'
local UnitTable						= {}
local TeamNames						= {}
local GL_LINE 						= GL.LINE
local GL_FRONT_AND_BACK 			= GL.FRONT_AND_BACK
local GL_FILL 						= GL.FILL

local ASCIIvalues = {
	[0] = {0x00,'NUL'},
	[1] = {0x01,'SOH'},
	[2] = {0x02,'STX'},
	[3] = {0x03,'ETX'},
	[4] = {0x04,'EOT'},
	[5] = {0x05,'ENQ'},
	[6] = {0x06,'ACK'},
	[7] = {0x07,'BEL'},
	[8] = {0x08,'BS'},
	[9] = {0x09,'TAB'},
	[10] = {0x0A,'LF'},
	[11] = {0x0B,'VT'},
	[12] = {0x0C,'FF'},
	[13] = {0x0D,'CR'},
	[14] = {0x0E,'SO'},
	[15] = {0x0F,'SI'},
	[16] = {0x010,'DLE'},
	[17] = {0x011,'DC1'},
	[18] = {0x012,'DC2'},
	[19] = {0x013,'DC3'},
	[20] = {0x014,'DC4'},
	[21] = {0x015,'NAK'},
	[22] = {0x016,'SYN'},
	[23] = {0x017,'ETB'},
	[24] = {0x018,'CAN'},
	[25] = {0x019,'EM'},
	[26] = {0x01A,'SUB'},
	[27] = {0x01B,'ESC'},
	[28] = {0x01C,'FS'},
	[29] = {0x01D,'GS'},
	[30] = {0x01E,'RS'},
	[31] = {0x01F,'US'},
	[32] = {0x020,'(space)'},
	[33] = {0x021,'!'},
	[34] = {0x022,'"'},
	[35] = {0x023,'#'},
	[36] = {0x024,'$'},
	[37] = {0x025,'%'},
	[38] = {0x026,'&'},
	[39] = {0x027,'\''},
	[40] = {0x028,'('},
	[41] = {0x029,')'},
	[42] = {0x02A,'*'},
	[43] = {0x02B,'+'},
	[44] = {0x02C,','},
	[45] = {0x02D,'-'},
	[46] = {0x02E,'.'},
	[47] = {0x02F,'/'},
	[48] = {0x030,'0'},
	[49] = {0x031,'1'},
	[50] = {0x032,'2'},
	[51] = {0x033,'3'},
	[52] = {0x034,'4'},
	[53] = {0x035,'5'},
	[54] = {0x036,'6'},
	[55] = {0x037,'7'},
	[56] = {0x038,'8'},
	[57] = {0x039,'9'},
	[58] = {0x03A,':'},
	[59] = {0x03B,';'},
	[60] = {0x03C,'<'},
	[61] = {0x03D,'='},
	[62] = {0x03E,'>'},
	[63] = {0x03F,'?'},
	[64] = {0x040,'@'},
	[65] = {0x041,'A'},
	[66] = {0x042,'B'},
	[67] = {0x043,'C'},
	[68] = {0x044,'D'},
	[69] = {0x045,'E'},
	[70] = {0x046,'F'},
	[71] = {0x047,'G'},
	[72] = {0x048,'H'},
	[73] = {0x049,'I'},
	[74] = {0x04A,'J'},
	[75] = {0x04B,'K'},
	[76] = {0x04C,'L'},
	[77] = {0x04D,'M'},
	[78] = {0x04E,'N'},
	[79] = {0x04F,'O'},
	[80] = {0x050,'P'},
	[81] = {0x051,'Q'},
	[82] = {0x052,'R'},
	[83] = {0x053,'S'},
	[84] = {0x054,'T'},
	[85] = {0x055,'U'},
	[86] = {0x056,'V'},
	[87] = {0x057,'W'},
	[88] = {0x058,'X'},
	[89] = {0x059,'Y'},
	[90] = {0x05A,'Z'},
	[91] = {0x05B,'['},
	[92] = {0x05C,'\\'},
	[93] = {0x05D,']'},
	[94] = {0x05E,'^'},
	[95] = {0x05F,'_'},
	[96] = {0x060,'`'},
	[97] = {0x061,'a'},
	[98] = {0x062,'b'},
	[99] = {0x063,'c'},
	[100] = {0x064,'d'},
	[101] = {0x065,'e'},
	[102] = {0x066,'f'},
	[103] = {0x067,'g'},
	[104] = {0x068,'h'},
	[105] = {0x069,'i'},
	[106] = {0x06A,'j'},
	[107] = {0x06B,'k'},
	[108] = {0x06C,'l'},
	[109] = {0x06D,'m'},
	[110] = {0x06E,'n'},
	[111] = {0x06F,'o'},
	[112] = {0x070,'p'},
	[113] = {0x071,'q'},
	[114] = {0x072,'r'},
	[115] = {0x073,'s'},
	[116] = {0x074,'t'},
	[117] = {0x075,'u'},
	[118] = {0x076,'v'},
	[119] = {0x077,'w'},
	[120] = {0x078,'x'},
	[121] = {0x079,'y'},
	[122] = {0x07A,'z'},
	[123] = {0x07B,'{'},
	[124] = {0x07C,'|'},
	[125] = {0x07D,'}'},
	[126] = {0x07E,'~'},
	[127] = {0x07F,''},

}

local function InitButtons()
	
	Button["select"]["x0"] 				= posx + 50
	Button["select"]["x1"] 				= Button["select"]["x0"] + 100
	Button["select"]["y0"] 				= posy + 5
	Button["select"]["y1"] 				= Button["select"]["y0"] + 25
	
	Button["clear"]["x0"] 				= Button["select"]["x1"] + 20
	Button["clear"]["x1"] 				= Button["clear"]["x0"] + 100
	Button["clear"]["y0"] 				= posy + 5
	Button["clear"]["y1"] 				= Button["clear"]["y0"] + 25
	
	Button["close"]["x0"] 				= Button["clear"]["x1"] + 20
	Button["close"]["x1"] 				= Button["close"]["x0"] + 100
	Button["close"]["y0"] 				= posy + 5
	Button["close"]["y1"] 				= Button["close"]["y0"] + 25
	
	Button["textbox"]["x0"] 			= posx + MARGIN
	Button["textbox"]["x1"] 			= Button["textbox"]["x0"] + 200
	Button["textbox"]["y0"] 			= posy + sizeY - 55
	Button["textbox"]["y1"] 			= Button["textbox"]["y0"] + 25
	
	Button["check"]["x0"]				= posx + 250
	Button["check"]["y0"]				= posy + sizeY - 55
	Button["check"]["x1"]				= Button["check"]["x0"] + 15
	Button["check"]["y1"]				= Button["check"]["y0"] + 15
	
end

local function setTeamNames()
	for _, teamID in pairs(Spring.GetTeamList()) do
		local leaderID = select(2,Spring.GetTeamInfo(teamID))
		local name = Spring.GetPlayerInfo(leaderID)
		TeamNames[teamID] = name
	end
end

local function firstToUpper(str)
	return ( str:gsub("%a", string.upper, 1))
end

local function drawBorder(x0, y0, x1, y1, width)
	glRect(x0, y0, x1, y0 + width)
	glRect(x0, y1, x1, y1 - width)
	glRect(x0, y0, x0 + width, y1)
	glRect(x1, y0, x1 - width, y1)
end

local function round(num, idp)
	return string.format("%." .. (idp or 0) .. "f", num)
end

function widget:Initialize()
    localTeamID = Spring.GetLocalTeamID()
	Button["close"]	 = {}
	Button["clear"]	 = {}
	Button["select"]	 = {}
	Button["textbox"] = {}
	Button["check"] = {}
	Button["check"]["checked"] = false
	
	Button["close"]["mouse"] = false
	Button["clear"]["mouse"] = false
	Button["select"]["mouse"] = false
	Button["select"]["enabled"] = false
	Button["textbox"]["mouse"] = false
	Button["textbox"]["text"] = ""
	InitButtons()
	setTeamNames()
end
	
local function GetAlliedUnits(allyID)
	local AlliedUnits = {}
	local count = 0
	for _, unitID in pairs(Spring.GetAllUnits()) do
		local aID = Spring.GetUnitAllyTeam(unitID)
		if aID == allyID then
			local udID = Spring.GetUnitDefID(unitID)
			local name = UnitDefs[udID].humanName
			AlliedUnits[unitID] = name
			count = count +1
		end
	end
	setTeamNames()
	return AlliedUnits,count
end
	
local function CheckMatches()
	local pattern = Button.textbox.text
	local matches = {}
	local count = 0
	Button.textbox.firstMatch = nil
	if not pattern or #pattern == 0 then
		Button.textbox.matches = nil
		Button.textbox.matchcount = 0
		return
	end
		
	for unitID, name in pairs(UnitTable) do
		local lcname = name:lower()
		local isMatch 
		
		if Button["check"]["checked"] then
			isMatch = lcname == pattern
		else
			isMatch = lcname:find(pattern)
		end
		if isMatch then
			count = count + 1
			Button.textbox.firstMatch = Button.textbox.firstMatch or unitID
			
			local newName = lcname:gsub(pattern,OrangeStr..pattern..GreyStr)
			local teamID = Spring.GetUnitTeam(unitID)
			
			matches[unitID] = {firstToUpper(newName),teamID,TeamNames[teamID]}
		end
	end
	Button.textbox.matches = matches
	Button.textbox.matchcount = count
end

local function DrawWindow()
	
	--back panel
	gl.Color(0, 0, 0, 0.2)
	gl.Rect(posx,posy,posx+sizeX,posy+sizeY)
		
	local x0 = posx + MARGIN
	local y0 = posy + sizeY - 20
	local x1 = posx + sizeX - MARGIN
	local y1 = posy
	
	-- Buttons
	
	--checkbox
	gl.Color(1, 1, 1, 1)
	if Button["check"]["checked"] then
		gl.Texture(optCheckBoxOn)
	else
		gl.Texture(optCheckBoxOff)
	end
	gl.TexRect(Button["check"]["x0"],Button["check"]["y0"],Button["check"]["x1"],Button["check"]["y1"])
	gl.Texture(false)
	
	-- Close
	glColor(0, 0, 0, 0.4)
	glRect(Button["close"]["x0"],Button["close"]["y0"], Button["close"]["x1"], Button["close"]["y1"])
	glRect(Button["clear"]["x0"],Button["clear"]["y0"], Button["clear"]["x1"], Button["clear"]["y1"])
	if Button.select.enabled then
		glColor(0, 0, 0, 0.4)
	else
		glColor(0.5, 0.5, 0.5, 0.4)
	end
	glRect(Button["select"]["x0"],Button["select"]["y0"], Button["select"]["x1"], Button["select"]["y1"])
	glColor(0.8, 0.8, 0.8, 0.5)
	glRect(Button["textbox"]["x0"],Button["textbox"]["y0"], Button["textbox"]["x1"], Button["textbox"]["y1"])
	glColor(0, 0, 0, 1)
	drawBorder(Button["close"]["x0"],Button["close"]["y0"], Button["close"]["x1"], Button["close"]["y1"],1)
	drawBorder(Button["clear"]["x0"],Button["clear"]["y0"], Button["clear"]["x1"], Button["clear"]["y1"],1)
	if Button.select.enabled then
		drawBorder(Button["select"]["x0"],Button["select"]["y0"], Button["select"]["x1"], Button["select"]["y1"],1)
	end
	glColor(0.3, 0.3, 0.3, 0.8)
	drawBorder(Button["textbox"]["x0"],Button["textbox"]["y0"], Button["textbox"]["x1"], Button["textbox"]["y1"],1)
	if not Button.select.enabled then
		drawBorder(Button["select"]["x0"],Button["select"]["y0"], Button["select"]["x1"], Button["select"]["y1"],1)
	end
	glColor(0.8, 0.8, 0.2, 0.5)
	if Button["close"]["mouse"] then
		glRect(Button["close"]["x0"],Button["close"]["y0"], Button["close"]["x1"], Button["close"]["y1"])
	elseif Button["clear"]["mouse"] then
		glRect(Button["clear"]["x0"],Button["clear"]["y0"], Button["clear"]["x1"], Button["clear"]["y1"])
	elseif Button["select"]["mouse"] and Button["select"]["enabled"] then
		glRect(Button["select"]["x0"],Button["select"]["y0"], Button["select"]["x1"], Button["select"]["y1"])
	elseif Button["check"]["mouse"] then
		glRect(Button["check"]["x0"],Button["check"]["y0"], Button["check"]["x1"], Button["check"]["y1"])
	elseif Button["textbox"]["mouse"] then
		--glRect(Button["textbox"]["x0"],Button["textbox"]["y0"], Button["textbox"]["x1"], Button["textbox"]["y1"])
	end
	
	--caret
	local textpos = x0 + 14 + textSize * gl.GetTextWidth(Button["textbox"]["text"])
	local t = os.clock()
	-- text
	myFont:Begin()
	myFont:SetTextColor({1, 1, 1, 1})
	myFont:Print(GreenStr .. "Where the heck is (unitname):",x0,y0,16,'bs')
	myFont:Print(GreyStr.. "Exact matches",Button["check"]["x1"]+10,Button["check"]["y0"]+2,12,'bs')
	myFont:Print("Close",(Button["close"]["x0"]+Button["close"]["x1"])/2,Button["close"]["y0"]+6,14,'bcs')
	myFont:Print("Clear",(Button["clear"]["x0"]+Button["clear"]["x1"])/2,Button["clear"]["y0"]+6,14,'bcs')
	myFont:Print("Select all",(Button["select"]["x0"]+Button["select"]["x1"])/2,Button["select"]["y0"]+6,14,'bcs')
	myFont:Print(DarkGreenStr .. firstToUpper(Button["textbox"]["text"]),Button["textbox"]["x0"]+MARGIN,Button["textbox"]["y0"]+5,textSize,'bs')
	
	myFont:SetTextColor({0.1, 0.1, 0.1, 1})
	if t%1 < 0.66 then
		myFont:Print("|",textpos,Button["textbox"]["y0"]+4,textSize,'b')
	end
	myFont:SetTextColor({0.8, 0.8, 0.8, 1})
	if Button.textbox.matchcount and Button.textbox.matchcount > 0 then
		local count = 0
		local displayed = 0
		for unitID, data in pairs(Button.textbox.matches) do
			local name = data[1]
			local teamID = data[2]
			local teamName = data[3]
						
			count = count + 1 
			if name and teamID and teamName then
				if count < 8 then
					displayed = displayed + 1
					if teamID == myTeamID then
						myFont:Print(GreyStr..name ..GreenStr.."  ( "..teamName.." )",x0+MARGIN,y0-35-16*count,12,'bs')
					else
						myFont:Print(GreyStr..name ..BlueStr.."  ( "..teamName.." )",x0+MARGIN,y0-35-16*count,12,'bs')
					end
				end
			end
		end
		if count >= 8 then
			myFont:Print(GreyStr.."+" .. count-displayed .. " more matches",x0+MARGIN,y0-30-16*8,12,'bs')
		end
	end
	
	myFont:End()
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
						  and y >= BLcornerY
						  and y <= TRcornerY
end

--callins

function widget:KeyPress(key, mods, isRepeat)
	--Echo("Key:",key,mods.ctrl)
	if showWindow then
		if key < 127 then
			local str = ASCIIvalues[key][2]
			--Echo("Key:",key,str)
			if key == 8 then --backspace
				local text = Button["textbox"]["text"]
				local len = text:len()
				if len > 0 then
					Button["textbox"]["text"] = text:sub(1,len-1)
					Button.select.enabled = len > 1
					CheckMatches()
					return true	
				end
			elseif key == 27 then -- ESC
				showWindow = false
				Spring.PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				return true
			elseif not isRepeat then
				if key == 32 then --space
					Button["textbox"]["text"] = Button["textbox"]["text"] .. " "
					CheckMatches()
					return true
				elseif key == 45 and mods.shift then
					Button["textbox"]["text"] = Button["textbox"]["text"] .. "_"
					Button.select.enabled = true
					CheckMatches()
					return true
				elseif str and #str == 1 then -- only normal letters
					Button["textbox"]["text"] = Button["textbox"]["text"] .. str
					Button.select.enabled = true
					CheckMatches()
					return true
				end	
			end
		end
	elseif mods.ctrl then
		if not isRepeat then
			if key == 102 then -- F
				Spring.SendCommands("findunit")
				return true
			end
		end
	end
	return false
end

function widget:TextCommand(cmd)
	
	if cmd:match("^findunit") then
		
		myPlayerID = Spring.GetMyPlayerID()
		myTeamID   = select(4,Spring.GetPlayerInfo(myPlayerID))
		
		local allyID = select(5,Spring.GetPlayerInfo(myPlayerID))
		local unitCount
		UnitTable,unitCount = GetAlliedUnits(allyID)
		--Echo("Allied unit count:",unitCount)
		if UnitTable and unitCount > 0 then
			showWindow = true
			CheckMatches()
		else
			Echo("Findunit: no allied units found!")
		end
	end
end

function widget:DrawScreen()
	if (not Spring.IsGUIHidden()) and showWindow then
		DrawWindow()
	end
end

function widget:DrawInMiniMap(sx, sy)
	if (not Spring.IsGUIHidden()) and showWindow then
		
		local ratioX = sx / mapX
		local ratioY = sy / mapY
		
		if Button.textbox.matchcount and Button.textbox.matchcount > 0 then
			for unitID, data in pairs(Button.textbox.matches) do
				local name = data[1]
				local teamID = data[2]
				local teamName = data[3]
				local x = data[4]
				local y = data[5]
				
				if x and y then
					local x0 = x * ratioX
					local y0 = sy-y * ratioY
					
					if teamID == myTeamID then
						gl.Color(0.5, 1, 0.5, 1)
					else
						gl.Color(0.5, 0.5, 1, 1)
					end
					gl.Rect(x0-2,y0-2,x0+2,y0+2)
					gl.Color(1, 1, 1, 1)
				end
			end
		end
	end
end

function widget:IsAbove(mx,my)
	if (not Spring.IsGUIHidden()) and showWindow then
		Button["clear"]["mouse"] = false
		Button["close"]["mouse"] = false
		Button["textbox"]["mouse"] = false
		Button["select"]["mouse"] = false
		Button["check"]["mouse"] = false
		
		if IsOnButton(mx,my,Button["close"]["x0"],Button["close"]["y0"],Button["close"]["x1"],Button["close"]["y1"]) then		
			Button["close"]["mouse"] = true
		elseif IsOnButton(mx,my,Button["textbox"]["x0"],Button["textbox"]["y0"],Button["textbox"]["x1"],Button["textbox"]["y1"]) then
			Button["textbox"]["mouse"] = true
		elseif IsOnButton(mx,my,Button["clear"]["x0"],Button["clear"]["y0"],Button["clear"]["x1"],Button["clear"]["y1"]) then
			Button["clear"]["mouse"] = true
		elseif IsOnButton(mx,my,Button["check"]["x0"],Button["check"]["y0"],Button["check"]["x1"],Button["check"]["y1"]) then
			Button["check"]["mouse"] = true
		elseif IsOnButton(mx,my,Button["select"]["x0"],Button["select"]["y0"],Button["select"]["x1"],Button["select"]["y1"]) then
			if Button["select"]["enabled"] then
				Button["select"]["mouse"] = true
			end
		end
	end
end	

function widget:Update()
	if (not Spring.IsGUIHidden()) and showWindow then
		if Button.textbox.matches then
			for unitID, data in pairs(Button.textbox.matches) do
				local name = data[1]
				local teamID = data[2]
				local teamName = data[3]
				
				local x,_,z = Spring.GetUnitPosition(unitID)
				
				Button.textbox.matches[unitID][4] = x
				Button.textbox.matches[unitID][5] = z
			end
		end
	end
end

function widget:MousePress(mx, my, mButton)
	if (not Spring.IsGUIHidden()) and showWindow then
		if mButton == 2 or mButton == 3 then
			if IsOnButton(mx,my,posx,posy,posx+sizeX,posy+sizeY) then
				-- Dragging
				return true
			end	
		elseif mButton == 1 then
			if IsOnButton(mx,my,Button["close"]["x0"],Button["close"]["y0"],Button["close"]["x1"],Button["close"]["y1"]) then
				showWindow = false
				Spring.PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				return true
			elseif IsOnButton(mx,my,Button["clear"]["x0"],Button["clear"]["y0"],Button["clear"]["x1"],Button["clear"]["y1"]) then
				Button["textbox"]["text"] = ""
				Button["select"]["enabled"] = false
				Button.textbox.matchcount = nil
				Spring.PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				return true
			elseif IsOnButton(mx,my,Button["check"]["x0"],Button["check"]["y0"],Button["check"]["x1"],Button["check"]["y1"]) then
				Button["check"]["checked"] = not Button["check"]["checked"]
				CheckMatches()
				Spring.PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				return true
			elseif IsOnButton(mx,my,Button["select"]["x0"],Button["select"]["y0"],Button["select"]["x1"],Button["select"]["y1"]) and Button["select"]["enabled"] then
				showWindow = false
				local unitID = Button.textbox.firstMatch
				--Echo("Matches:",Button.textbox.matches,unitID)
				
				if unitID then
					Spring.SelectUnitMap(Button.textbox.matches)
					local x,y,z = Spring.GetUnitPosition(unitID)
					if x and y and z then
						Spring.SetCameraTarget(x,y,z,0.2)
					end
				end
				Spring.PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				return true
			end
		end
	end
end
					
function widget:MouseMove(mx, my, dx, dy, mButton)
	if showWindow then
		-- Dragging
		posx = math.max(0, math.min(posx+dx, vsx-sizeX))	--prevent moving off screen
		posy = math.max(0, math.min(posy+dy, vsy-sizeY))
		InitButtons()
	end
end

function widget:GetConfigData(data)      -- save
	return {
			posx         		= posx,
			posy				= posy,
		}
	end

function widget:SetConfigData(data)      -- load
	posx         				= data.posx or posx
	posy						= data.posy or posy
end
------------------------------------------------------------------------
------------------------------------------------------------------------