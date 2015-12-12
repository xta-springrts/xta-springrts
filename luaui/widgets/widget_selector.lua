--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    selector.lua
--  brief:   the widget selector, loads and unloads widgets
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- changes:
--   jK (April@2009) - updated to new font system
--   Bluestone (Jan 2015) - added to BA as a widget, added various stuff 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Widget Selector",
    desc      = "Widget selection widget",
    author    = "trepan, jK",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -math.huge,
    handler   = true, 
    enabled   = true  
  }
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- relies on a gadget to implement "luarules reloadluaui"
-- relies on custom stuff in widgetHandler to implement blankOutConfig and allowUserWidgets

include("colors.h.lua")
include("keysym.h.lua")
include("fonts.lua")

local Echo = Spring.Echo
local sizeMultiplier = 1

local floor = math.floor

local widgetsList = {}
local matchedWidgetsList = {}
local fullWidgetsList = {}
local defaultWidgetList = {}

local vsx, vsy = widgetHandler:GetViewSizes()

local minMaxEntries = 15 
local curMaxEntries = 25

local startEntry = 1
local pageStep  = math.floor(curMaxEntries / 2) - 1

local fontSize = 12
local fontSpace = 7
local yStep = fontSize + fontSpace


local entryFont  = "LuaUI/Fonts/FreeMonoBold_12"
local headerFont  = "LuaUI/Fonts/FreeMonoBold_12"
entryFont  = ":n:" .. entryFont
headerFont = ":n:" .. headerFont

local myFont = gl.LoadFont("FreeSansBold.otf",16, 1.9, 40)
local bgPadding = 3
local bgcorner	= ":n:"..LUAUI_DIRNAME.."images/bgcorner.png"
local sndButton 	= 'sounds/buttn06.wav'

local maxWidth = 0.01
local borderx = yStep * 0.75
local bordery = yStep * 0.75

local midx = vsx * 0.5
local minx = vsx * 0.4
local maxx = vsx * 0.6
local midy = vsy * 0.5
local miny = vsy * 0.4
local maxy = vsy * 0.6

local sbposx = 0.0
local sbposy = 0.0
local sbsizex = 0.0
local sbsizey = 0.0
local sby1 = 0.0
local sby2 = 0.0
local sbsize = 0.0
local sbheight = 0.0
local activescrollbar = false
local scrollbargrabpos = 0.0
local fbheight = 30
local ibheight = 14
local onFB = false
local GreyStr    	= "\255\210\210\210"
local LGreyStr    	= "\152\152\152\152"
local BlueStr		= "\255\152\152\255"
local OrangeStr  	= "\255\255\190\128"
local WhiteStr   	= "\255\255\255\255"
local nocasePattern
local userWidgetState	= false
local viewWidgetState	= false

local show = false
local pagestepped = false
local Button = {}
Button["textbox"] = {}
Button["clear"] = {}


local buttons = { --see MouseRelease for which functions are called by which buttons
    [1] = "Reload LuaUI", 
    [2] = "Reload previously active widgets",
	[3] = "Unload ALL Widgets",
	[4] = "Unload ALL user widgets",
	[5] = "Turn off these widgets (in view/selection)"
}
local titleFontSize = 16
local buttonFontSize = 14
local buttonHeight = 20
local buttonTop = 20 -- offset between top of buttons and bottom of widget

-------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler.knownChanged = true
  Spring.SendCommands('unbindkeyset f11')
  
  Button["textbox"]["y1"] = maxy+20+(bgPadding*sizeMultiplier)
  Button["textbox"]["y2"] = maxy+20+fbheight+(bgPadding*sizeMultiplier)
  Button["textbox"]["x1"] = minx-(bgPadding*sizeMultiplier)
  Button["textbox"]["x2"] = maxx+(bgPadding*sizeMultiplier)
  Button["textbox"]["text"] = ""
  
  defaultWidgetList = {}
  
  for name, order in pairs(widgetHandler.orderList) do
	if order > 0 then 
		defaultWidgetList[name] = true
	end
  end
end


-------------------------------------------------------------------------------
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

local function DrawBorder(x0, y0, x1, y1, width)
	gl.Rect(x0, y0, x1, y0 + width)
	gl.Rect(x0, y1, x1, y1 - width)
	gl.Rect(x0, y0, x0 + width, y1)
	gl.Rect(x1, y0, x1 - width, y1)
end

local function DrawRectRound(px,py,sx,sy,cs)
	gl.TexCoord(0.8,0.8)
	gl.Vertex(px+cs, py, 0)
	gl.Vertex(sx-cs, py, 0)
	gl.Vertex(sx-cs, sy, 0)
	gl.Vertex(px+cs, sy, 0)
	
	gl.Vertex(px, py+cs, 0)
	gl.Vertex(px+cs, py+cs, 0)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.Vertex(px, sy-cs, 0)
	
	gl.Vertex(sx, py+cs, 0)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.Vertex(sx, sy-cs, 0)
	
	local offset = 0.07		-- texture offset, because else gaps could show
	local o = offset
	-- top left
	if py <= 0 or px <= 0 then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, py+cs, 0)
	-- top right
	if py <= 0 or sx >= vsx then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, py+cs, 0)
	-- bottom left
	if sy >= vsy or px <= 0 then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, sy-cs, 0)
	-- bottom right
	if sy >= vsy or sx >= vsx then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, sy-cs, 0)
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
						  and y >= BLcornerY
						  and y <= TRcornerY
end

local function nocase (s)
	s = string.gsub(s, "%a", function (c)
		return 	string.format("[%s%s]", string.lower(c),
				string.upper(c))
	end)
	return s
end

function RectRound(px,py,sx,sy,cs)
	local px,py,sx,sy,cs = math.floor(px),math.floor(py),math.ceil(sx),math.ceil(sy),math.floor(cs)
	
	gl.Texture(bgcorner)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px,py,sx,sy,cs)
	gl.Texture(false)
end

local function UpdateGeometry()
  midx  = vsx * 0.5
  midy  = vsy * 0.5

  local halfWidth = ((maxWidth+2) * fontSize) * sizeMultiplier * 0.5
  minx = floor(midx - halfWidth - (borderx*sizeMultiplier))
  maxx = floor(midx + halfWidth + (borderx*sizeMultiplier))

  local ySize = (yStep * sizeMultiplier) * (curMaxEntries) + ibheight
  miny = floor(midy - (0.5 * ySize)) - ((fontSize+bgPadding+bgPadding)*sizeMultiplier)
  maxy = floor(midy + (0.5 * ySize))
end

local function UpdateListScroll()
  local wCount = #fullWidgetsList
  local wScreen = #widgetsList
  local lastStart = lastStart or wCount - curMaxEntries + 1
  
  if (lastStart < 1) then lastStart = 1 end
  if (lastStart > wCount - curMaxEntries + 1) then lastStart = 1 end
  if (startEntry > lastStart) then startEntry = lastStart end
  if (startEntry < 1) then startEntry = 1 end
  
  widgetsList = {}
  matchedWidgetsList = {}
  
  local se = startEntry
  local ee = se + curMaxEntries - 1
  local n = 1
  local pattern = Button["textbox"]["text"]
  
  for i, data in pairs(fullWidgetsList) do
	local text = string.lower( fullWidgetsList[i][1] )
	if text:find(pattern) or #pattern == 0 then
		matchedWidgetsList[#matchedWidgetsList+1] = fullWidgetsList[i]
	end
  end
  
  wCount = #matchedWidgetsList
  
  for i = se, wCount do
		if #widgetsList >= curMaxEntries then break end
		widgetsList[n] = matchedWidgetsList[i]
		n = n + 1
  end
  
  if #widgetsList < curMaxEntries then
	for i = 1, se - 1 do
		if #widgetsList >= curMaxEntries then break end
		widgetsList[n] = matchedWidgetsList[i]
		n = n + 1
	end
  end
  
end

local function ScrollUp(step)
  startEntry = startEntry - step
  UpdateListScroll()
end

local function ScrollDown(step)
  startEntry = startEntry + step
  UpdateListScroll()
end

function widget:MouseWheel(up, value)
  if not show then return false end
  
  local a,c,m,s = Spring.GetModKeyState()
  if (a or m) then
    return false  -- alt and meta allow normal control
  end
  local step = (s and 4) or (c and 1) or 2
  if (up) then
    ScrollUp(step)
  else
    ScrollDown(step)
  end
  return true
end

local function SortWidgetListFunc(nd1, nd2) --does nd1 come before nd2?
  -- widget profiler on top
  if nd1[1]=="Widget Profiler" then 
    return true 
  elseif nd2[1]=="Widget Profiler" then
    return false
  end
  
  -- mod widgets first, then user widgets
  if (nd1[2].fromZip ~= nd2[2].fromZip) then
    return nd1[2].fromZip  
  end
  
  -- sort by name
  return (nd1[1] < nd2[1]) 
end

local function UpdateList()
  if (not widgetHandler.knownChanged) then
    return
  end
  widgetHandler.knownChanged = false

  local myName = widget:GetInfo().name
  maxWidth = 0
  widgetsList = {}
    
  for name,data in pairs(widgetHandler.knownWidgets) do
    if (name ~= myName) then
	  
      table.insert(fullWidgetsList, { name, data })
      -- look for the maxWidth
      local width = fontSize * gl.GetTextWidth(name)
      if (width > maxWidth) then
        maxWidth = width
      end
    end
  end
  
  maxWidth = (maxWidth / fontSize)

  local myCount = #fullWidgetsList
  if (widgetHandler.knownCount ~= (myCount + 1)) then
    error('knownCount mismatch')
  end

  table.sort(fullWidgetsList, SortWidgetListFunc)

  UpdateListScroll()
  UpdateGeometry()
end

local function CheckMatches()
	nocasePattern = nocase(Button["textbox"]["text"])
	UpdateListScroll()
	UpdateGeometry()
end

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY

  if customScale == nil then
	customScale = 1
  end
  sizeMultiplier   = 0.6 + (vsx*vsy / 6000000) * customScale
  
  UpdateGeometry()
end


-------------------------------------------------------------------------------

function widget:KeyPress(key, mods, isRepeat)
  if (show and (key == KEYSYMS.ESCAPE) or
      ((key == KEYSYMS.F11) and not isRepeat and
       not (mods.alt or mods.ctrl or mods.meta or mods.shift))) then
    show = not show
    return true
  end
  if (show and key == KEYSYMS.PAGEUP) then
    ScrollUp(pageStep)
    return true
  end
  if (show and key == KEYSYMS.PAGEDOWN) then
    ScrollDown(pageStep)
    return true
  end
  
  if show then
	if key < 127 then
		local str = ASCIIvalues[key][2]
		
		if key == 8 then --backspace
			local text = Button["textbox"]["text"]
			local len = text:len()
			if len > 0 then
				Button["textbox"]["text"] = text:sub(1,len-1)
				CheckMatches()
				return true	
			end
		elseif not isRepeat then
			if key == 32 then --space
				Button["textbox"]["text"] = Button["textbox"]["text"] .. " "
				CheckMatches()
				return true
			elseif key == 45 and mods.shift then
				Button["textbox"]["text"] = Button["textbox"]["text"] .. "_"
				CheckMatches()
				return true
			elseif str and #str == 1 then -- only normal letters
				Button["textbox"]["text"] = Button["textbox"]["text"] .. str
				CheckMatches()
				return true
			end	
		end
	end
  end
	
  return false
end


local activeGuishader = false
local scrollbarOffset = -15


function widget:DrawScreen()

  if not show then 
    if activeGuishader and (WG['guishader_api'] ~= nil) then
      activeGuishader = false
      WG['guishader_api'].RemoveRect('widgetselector')
    end
    return
  end
  UpdateList()
  gl.BeginText()
  if (WG['guishader_api'] == nil) then
    activeGuishader = false 
  end
  if (WG['guishader_api'] ~= nil) and not activeGuishader then
    activeGuishader = true
    WG['guishader_api'].InsertRect(minx-(bgPadding*sizeMultiplier), miny-(bgPadding*sizeMultiplier), maxx+(bgPadding*sizeMultiplier), maxy+(bgPadding*sizeMultiplier),'widgetselector')
  end
  borderx = (yStep*sizeMultiplier) * 0.75
  bordery = (yStep*sizeMultiplier) * 0.75
	
	Button["textbox"]["y1"] = maxy+20+(bgPadding*sizeMultiplier)
	Button["textbox"]["y2"] = maxy+20+fbheight+(bgPadding*sizeMultiplier)
	Button["textbox"]["x1"] = minx-(bgPadding*sizeMultiplier)
	Button["textbox"]["x2"] = maxx+(bgPadding*sizeMultiplier)	
	
  -- draw the header
  gl.Text("Widget Selector", midx, maxy + ((8 + bgPadding)*sizeMultiplier), titleFontSize*sizeMultiplier, "oc")
  
  local mx,my,lmb,mmb,rmb = Spring.GetMouseState()
  local tcol = WhiteStr
    
  -- draw the -/+ buttons
  if maxx-10 < mx and mx < maxx and maxy < my and my < maxy + ((buttonFontSize + 7)*sizeMultiplier) then
    tcol = '\255\031\031\031'
  end
  gl.Text(tcol.."+", maxx, maxy + ((7 + bgPadding)*sizeMultiplier), buttonFontSize*sizeMultiplier, "or")
  tcol = WhiteStr
  if minx < mx and mx < minx+10 and maxy < my and my < maxy + ((buttonFontSize + 7)*sizeMultiplier) then
    tcol = '\255\031\031\031'
  end
  gl.Text(tcol.."-", minx, maxy + ((7 + bgPadding)*sizeMultiplier), buttonFontSize*sizeMultiplier, "ol")
  tcol = WhiteStr

  -- draw filter box
  local y0 = Button["textbox"]["y1"]
  local y1 = Button["textbox"]["y2"]
  local x0 = Button["textbox"]["x1"]
  local x1 = Button["textbox"]["x2"]
  
  
  gl.Color(0,0,0,0.6)
  RectRound(x0,y0 ,x1 ,y1 , 8*sizeMultiplier)
  
  gl.Color(0.33,0.33,0.33,0.2)
  RectRound(x0+1,y0+1, x1 -1, y1 - 1, 8*sizeMultiplier)
  gl.Color(0.4,0.4,0.4,0.2)
  RectRound(x0+3, y0+3, x1-3, y1 - 3, 8*sizeMultiplier)
  
  local text = Button["textbox"]["text"]
  
  if onFB and #text > 0 then
	gl.Color(1.0, 1.0, 1.0, 0.09)
	gl.Blending(GL.SRC_ALPHA, GL.ONE)
    RectRound(x0+2, y0+2, x1-2, y1-2, 5*sizeMultiplier)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	
	gl.Color(0.33,0.33,0.33,0.2)
	RectRound(x0+1,y1+10, x1 -1, y1 +30, 8*sizeMultiplier)
	gl.Color(0.4,0.4,0.4,0.2)
	RectRound(x0+3, y1+12, x1-3, y1 +28, 8*sizeMultiplier)
	gl.Color(1,1,1,1)
	
	gl.Text("Click to clear text",x0 + 20,y1+12,fontSize,'ds')

  end
  
  --text  
  gl.Color(1.0, 1.0, 1.0, 1.0)
  gl.Text(text,x0 + 20,y0+6,fontSize,'do')
    
  --caret
  local textpos = x0 + 20  + fontSize * gl.GetTextWidth(text)
  local t = os.clock()
  if t%1 < 0.66 then
	gl.Text("|",textpos,y0+6,fontSize,'do')
  end
  
  
  -- draw the box
  gl.Color(0,0,0,0.6)
  RectRound(minx-(bgPadding*sizeMultiplier), miny-(bgPadding*sizeMultiplier), maxx+(bgPadding*sizeMultiplier), maxy+(bgPadding*sizeMultiplier), 8*sizeMultiplier)
  
  gl.Color(0.33,0.33,0.33,0.2)
  RectRound(minx, miny, maxx, maxy, 8*sizeMultiplier)
     
  -- draw the text buttons (at the bottom) & their outlines
  for i,name in ipairs(buttons) do
    tcol = WhiteStr
    if minx < mx and mx < maxx and miny - (buttonTop*sizeMultiplier) - i*(buttonHeight*sizeMultiplier) < my and my < miny - (buttonTop*sizeMultiplier) - (i-1)*(buttonHeight*sizeMultiplier) then
      tcol = '\255\031\031\031'
    end
    gl.Text(tcol .. buttons[i], (minx+maxx)/2, miny - (buttonTop*sizeMultiplier) - (i*(buttonHeight*sizeMultiplier)), buttonFontSize*sizeMultiplier, "oc")
  end
  
  
  -- draw the widgets
  local nd = not widgetHandler.tweakMode and self:AboveLabel(mx, my)
  local pointedY = nil
  local pointedEnabled = false
  local pointedName = (nd and nd[1]) or nil
  local posy = maxy - ((yStep+bgPadding)*sizeMultiplier)
  sby1 = posy + ((fontSize + fontSpace)*sizeMultiplier) * 0.5
  for _,namedata in ipairs(widgetsList) do
    local name = namedata[1]
    local data = namedata[2]
    local color = ''
    local pointed = (pointedName == name)
    local order = widgetHandler.orderList[name]
    local enabled = order and (order > 0)
    local active = data.active
    if (pointed and not activescrollbar) then
      pointedY = posy
      pointedEnabled = data.active
      if not pagestepped and (lmb or mmb or rmb) then
        color = WhiteStr
      else
        color = (active  and '\255\128\255\128') or
                (enabled and '\255\255\255\128') or '\255\255\128\128'
      end
    else
      color = (active  and '\255\064\224\064') or
              (enabled and '\255\200\200\064') or '\255\224\064\064'
    end

	
	
    local tmpName
    if (data.fromZip) then
      -- FIXME: extra chars not counted in text length
      tmpName = WhiteStr .. '*' .. color .. name .. WhiteStr .. '*'
	  
    else
      tmpName = color .. name
    end
	
	
	if #text > 0 then
		tmpName = tmpName:gsub(nocasePattern,BlueStr .. string.upper(text) .. color)
	end
	
    gl.Text(color..tmpName, midx, posy + (fontSize*sizeMultiplier) * 0.5, fontSize*sizeMultiplier, "vc")
    posy = posy - (yStep*sizeMultiplier)
  end
  
  -- draw matchcount
  gl.Color(0.33,0.33,0.33,0.3)
  RectRound(x0+1,miny+1, x1 -1, miny+ibheight, 8*sizeMultiplier)
  gl.Color(0.4,0.4,0.4,0.2)
  RectRound(x0+3, miny+2, x1-3, miny+ibheight-2, 8*sizeMultiplier)
  
  gl.Color(1,1,0,0.5)
  local attr = #text == 0 and " widgets" or " matches"
  if #widgetsList == #matchedWidgetsList then
	gl.Text(GreyStr .. "Showing: " .. #widgetsList  .. attr,x1 -20,miny+1,10,'dor')
  else
	gl.Text(GreyStr .. "Showing: " .. #widgetsList .. " of " .. #matchedWidgetsList .. attr,x1 -20,miny+1,10,'dor')
  end
  
  -- scrollbar
  if #matchedWidgetsList > curMaxEntries then
    sby2 = posy + (yStep * sizeMultiplier) - (fontSpace*sizeMultiplier) * 0.5
    sbheight = sby1 - sby2
    sbsize = sbheight * #widgetsList / #fullWidgetsList 
    if activescrollbar then
    	startEntry = math.max(0, math.min(
    	math.floor(#fullWidgetsList * 
    	((sby1 - sbsize) - 
    	(my - math.min(scrollbargrabpos, sbsize)))
    	 / sbheight + 0.5), 
        #fullWidgetsList - curMaxEntries)) + 1
    end
    local sizex = maxx - minx
    sbposx = minx + sizex + 1.0 + scrollbarOffset
    sbposy = sby1 - sbsize - sbheight * (startEntry - 1) / #fullWidgetsList
    sbsizex = (yStep * sizeMultiplier)
    sbsizey = sbsize
    
    local trianglePadding = 4*sizeMultiplier
    local scrollerPadding = 8*sizeMultiplier
    
    -- background
    --gl.Color(0.0, 0.0, 0.0, 0.2)
	--RectRound(sbposx, miny, sbposx + sbsizex, maxy, 6*sizeMultiplier)
    if (sbposx < mx and mx < sbposx + sbsizex and miny < my and my < maxy) or activescrollbar then
      gl.Color(1,1,1,0.04)
	  RectRound(sbposx, miny+ibheight, sbposx + sbsizex, maxy, 6*sizeMultiplier)
    end
    
    --[[gl.Color(1.0, 1.0, 1.0, 0.15)
    gl.Shape(GL.TRIANGLES, {
      { v = { sbposx + sbsizex / 2, miny + trianglePadding } },
      { v = { sbposx + trianglePadding, sby2 - 1 - trianglePadding} },
      { v = { sbposx + sbsizex - trianglePadding, sby2 - 1 - trianglePadding} }
    })
    gl.Shape(GL.TRIANGLES, {
      { v = { sbposx + sbsizex / 2, maxy - trianglePadding } },
      { v = { sbposx - trianglePadding + sbsizex, sby2 + sbheight + 1 + trianglePadding} },
      { v = { sbposx + trianglePadding, sby2 + sbheight + 1 + trianglePadding} }
    })]]--
    
    -- scroller
    if (sbposx < mx and mx < sbposx + sbsizex and sby2 < my and my < sby2 + sbheight) then
      gl.Color(1.0, 1.0, 1.0, 0.4) 
      gl.Blending(GL.SRC_ALPHA, GL.ONE)
	  RectRound(sbposx+scrollerPadding, sbposy, sbposx + sbsizex - scrollerPadding, sbposy + sbsizey, 1.75*sizeMultiplier)
      gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
    end
    gl.Color(0.33, 0.33, 0.33, 0.8)
	RectRound(sbposx+scrollerPadding, sbposy, sbposx + sbsizex - scrollerPadding, sbposy + sbsizey, 1.75*sizeMultiplier)
  else
    sbposx = 0.0
    sbposy = 0.0
    sbsizex = 0.0
    sbsizey = 0.0
  end


  -- highlight label
  if (sbposx < mx and mx < sbposx + sbsizex and miny < my and my < maxy) or activescrollbar then
  
  else
    if (pointedY) then
    gl.Color(1.0, 1.0, 1.0, 0.09)
    local xn = minx + 0.5
    local xp = maxx - 0.5
    local yn = pointedY - ((fontSpace * 0.5 + 1)*sizeMultiplier)
    local yp = pointedY + ((fontSize + fontSpace * 0.5 + 1)*sizeMultiplier)
    if scrollbarOffset < 0 then
    	xp = xp + scrollbarOffset
    	--xn = xn - scrollbarOffset
    end
    yn = yn + 0.5
    yp = yp - 0.5
    gl.Blending(GL.SRC_ALPHA, GL.ONE)
    RectRound(xn, yn, xp, yp, 5*sizeMultiplier)
    gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
end
  end
  
  gl.EndText()
end

function widget:MousePress(x, y, button)
  if (Spring.IsGUIHidden()) or not show then
    return false
  end

  UpdateList()

  if button == 1 then
    -- above a button
    if minx < x and x < maxx and miny - (buttonTop*sizeMultiplier) - #buttons*(buttonHeight*sizeMultiplier) < y and y < miny - (buttonTop*sizeMultiplier) then
      return true
    end
    
    -- above the -/+ 
    if maxx-10 < x and x < maxx and maxy + bgPadding < y and y < maxy + ((buttonFontSize + 7 + bgPadding)*sizeMultiplier) then
      return true
    end
    if minx < x and x < minx+10 and maxy + bgPadding < y and y < maxy + ((buttonFontSize + 7 + bgPadding)*sizeMultiplier) then
      return true
    end
    
  -- above the scrollbar
  if ((x >= minx + scrollbarOffset) and (x <= maxx + scrollbarOffset + (yStep * sizeMultiplier))) then
    if ((y >= (maxy - bordery)) and (y <= maxy)) then
      if x > maxx+scrollbarOffset then
        ScrollUp(1)
      else
        ScrollUp(pageStep)
      end
      return true
    elseif ((y >= miny) and (y <= miny + bordery)) then
      if x > maxx+scrollbarOffset then
        ScrollDown(1)
      else
        ScrollDown(pageStep)
      end
      return true
    end
  end
    
    -- above the list    
    if sbposx < x and x < sbposx + sbsizex and sbposy < y and y < sbposy + sbsizey then
      activescrollbar = true
      scrollbargrabpos = y - sbposy
      return true
    elseif sbposx < x and x < sbposx + sbsizex and sby2 < y and y < sby2 + sbheight then
      if y > sbposy + sbsizey then
        startEntry = math.max(1, math.min(startEntry - curMaxEntries, #fullWidgetsList - curMaxEntries + 1))
      elseif y < sbposy then
        startEntry = math.max(1, math.min(startEntry + curMaxEntries, #fullWidgetsList - curMaxEntries + 1))
      end
      UpdateListScroll()
      pagestepped = true
      return true   
    end
  end
  
  local namedata = self:AboveLabel(x, y)
  
  if (not namedata) then
    show = false
    return false
  elseif namedata == "Click to clear" then
	namedata = nil
	Button["textbox"]["text"] = ""
	CheckMatches()
	return false
  end
  
  
  return true
  
end

function widget:MouseMove(x, y, dx, dy, button)
  if show and activescrollbar then
    startEntry = math.max(0, math.min(math.floor((#fullWidgetsList * ((sby1 - sbsize) - (y - math.min(scrollbargrabpos, sbsize))) / sbheight) + 0.5), 
    #fullWidgetsList - curMaxEntries)) + 1
    UpdateListScroll()
    return true
  end
  return false
end

function widget:MouseRelease(x, y, mb)
  if (Spring.IsGUIHidden()) or not show then
    return -1
  end

  UpdateList()
  if pagestepped then
	  pagestepped = false
	  return true
  end
  
  if mb == 1 and activescrollbar then
    activescrollbar = false
    scrollbargrabpos = 0.0
    return -1
  end
  
  if mb == 1 then
    if maxx-10 < x and x < maxx and maxy + bgPadding < y and y < maxy + buttonFontSize + 7 + bgPadding then
      -- + button
      curMaxEntries = curMaxEntries + 1
      UpdateListScroll()
      UpdateGeometry()
      Spring.WarpMouse(x, y+0.5*(fontSize+fontSpace))
      return -1
    end
    if minx < x and x < minx+10 and maxy + bgPadding < y and y < maxy + buttonFontSize + 7 + bgPadding then
      -- - button
      if curMaxEntries > minMaxEntries then
        curMaxEntries = curMaxEntries - 1
        UpdateListScroll()
        UpdateGeometry()
        Spring.WarpMouse(x, y-0.5*(fontSize+fontSpace))
      end
      return -1
    end
  end

  if mb == 1 then
    local buttonID = nil
    for i,_ in ipairs(buttons) do
        if minx < x and x < maxx and miny - (buttonTop*sizeMultiplier) - i*(buttonHeight*sizeMultiplier) < y and y < miny - (buttonTop*sizeMultiplier) - (i-1)*(buttonHeight*sizeMultiplier) then
            buttonID = i
            break
        end
    end
    if buttonID == 1 then
	  Echo("Reloading LuaUI...")
	  Spring.PlaySoundFile(sndButton,1.0,0,0,0,0,0,0,'userinterface')
      Spring.SendCommands("luarules reloadluaui")
      return -1
    end
    if buttonID == 2 then
		-- load all widgets that were enabled when this widget loaded
		Echo("Reloading widget states from startup...")
		Spring.PlaySoundFile(sndButton,1.0,0,0,0,0,0,0,'userinterface')
		for _,namedata in ipairs(fullWidgetsList) do
			local name = namedata[1]
			local data = namedata[2]
		
			if defaultWidgetList[name] then
				widgetHandler:EnableWidget(name)
			end
		end
		widgetHandler:SaveConfigData()
		return -1
    end
	if buttonID == 3 then
      -- disable all widgets, but don't reload
		Echo("Unloading all widgets, use above button to reload them")
		Spring.PlaySoundFile(sndButton,1.0,0,0,0,0,0,0,'userinterface')
		
      for _,namedata in ipairs(fullWidgetsList) do
        widgetHandler:DisableWidget(namedata[1])
      end
      widgetHandler:SaveConfigData()    
      return -1
    end
    
	if buttonID == 4 then
		-- disable/enable all user widgets
		Echo("Toggle user widgets: " .. (userWidgetState and "on" or "off") )
		Spring.PlaySoundFile(sndButton,1.0,0,0,0,0,0,0,'userinterface')
		for _,namedata in ipairs(fullWidgetsList) do
			local name = namedata[1]
			local data = namedata[2]
			if not data.fromZip then
				if userWidgetState then
					if defaultWidgetList[name] then
						widgetHandler:EnableWidget(name)
					end
				else
					widgetHandler:DisableWidget(name)
				end
			end
		end
		userWidgetState = not userWidgetState
	  
		if userWidgetState then
			buttons[4] = "Turn user widgets back on"
		else
			buttons[4] = "Unload ALL user widgets"
		end
	  
		widgetHandler:SaveConfigData()    
		return -1
	end
	
	if buttonID == 5 then
		-- disable/enable all widgets in view
		Echo("Toggle widgets in view to: " .. (viewWidgetState and "on" or "off"))
		Spring.PlaySoundFile(sndButton,1.0,0,0,0,0,0,0,'userinterface')

		for _,namedata in ipairs(widgetsList) do
			local name = namedata[1]
			if viewWidgetState then
				widgetHandler:EnableWidget(name)
			else
				widgetHandler:DisableWidget(name)
			end
		end
	
		viewWidgetState = not viewWidgetState

		if viewWidgetState then
			buttons[5] = "Turn on these widgets"
		else
			buttons[5] = "Turn off these widgets"
		end

		widgetHandler:SaveConfigData()    
		return -1
	end
  end
  
  local namedata = self:AboveLabel(x, y)
  if (not namedata) then
    return false
  end
  
  local name = namedata[1]
  local data = namedata[2]
  
  if (mb == 1) then
    widgetHandler:ToggleWidget(name)
  elseif ((button == 2) or (button == 3)) then
    local w = widgetHandler:FindWidget(name)
    if (not w) then return -1 end
    if (button == 2) then
      widgetHandler:LowerWidget(w)
    else
      widgetHandler:RaiseWidget(w)
    end
    widgetHandler:SaveConfigData()
  end
  return -1
end

function widget:AboveLabel(x, y)

	if IsOnButton(x,y,Button["textbox"]["x1"],Button["textbox"]["y1"],Button["textbox"]["x2"],Button["textbox"]["y2"]) then
		return "Click to clear" 
	end
	
  if ((x < minx) or (y < (miny + bordery)) or
      (x > maxx) or (y > (maxy - bordery))) then
    return nil
  end
  local count = #widgetsList
  if (count < 1) then return nil end
  
  local i = floor(1 + ((maxy - bordery) - y) / (yStep * sizeMultiplier))
  if     (i < 1)     then i = 1
  elseif (i > count) then i = count end
  
  return widgetsList[i]
end

function widget:IsAbove(x, y)
  if not show then return false end 
  UpdateList()
  
  onFB = IsOnButton(x,y,Button["textbox"]["x1"],Button["textbox"]["y1"],Button["textbox"]["x2"],Button["textbox"]["y2"])
	
  if (x < minx) or (x > maxx + (yStep * sizeMultiplier)) or
      (y < miny - #buttons*buttonHeight) or (y > maxy+bgPadding) then
    return false
  end
  return true
end

function widget:GetTooltip(x, y)
  if not show then return nil end 

  UpdateList()  
  local namedata = self:AboveLabel(x, y)
  if (not namedata) then
    return '\255\200\255\200'..'Widget Selector\n'    ..
           '\255\255\255\200'..'LMB: toggle widget\n' ..
           '\255\255\200\200'..'MMB: lower  widget\n' ..
           '\255\200\200\255'..'RMB: raise  widget'
  end

  local n = namedata[1]
  local d = namedata[2]

  if not n or not d then return nil end
	
  local order = widgetHandler.orderList[n]
  local enabled = order and (order > 0)
  
  local tt = (d.active and GreenStr) or (enabled  and YellowStr) or RedStr
  tt = tt..n..'\n'
  tt = d.desc   and tt..OrangeStr..d.desc..'\n' or tt
  tt = d.author and tt..GreyStr..'Author:  '..WhiteStr..d.author..'\n' or tt
  tt = tt..GreyStr..d.basename
  if (d.fromZip) then
    tt = tt..OrangeStr..' (mod widget)'
  end
  return tt
end

function widget:GetConfigData()
    local data = {startEntry=startEntry, curMaxEntries=curMaxEntries, show=show} 
    return data
end

function widget:SetConfigData(data)
    startEntry = data.startEntry or startEntry
    curMaxEntries = data.curMaxEntries or curMaxEntries
    show = data.show or show
end

function widget:TextCommand(s) 
  -- process request to tell the widgetHandler to blank out the widget config when it shuts down
  local token = {}
  local n = 0
  for w in string.gmatch(s, "%S+") do
    n = n + 1
    token[n] = w		
  end
  if n==1 and token[1]=="reset" then
    -- tell the widget handler to reload with a blank config
    widgetHandler.blankOutConfig = true
    Spring.SendCommands("luarules reloadluaui") 
  end
  if n==1 and token[1]=="factoryreset" then
    -- tell the widget handler to disallow user widgets and reload with a blank config
    widgetHandler.__blankOutConfig = true
    widgetHandler.__allowUserWidgets = false
    Spring.SendCommands("luarules reloadluaui") 
  end
end

function widget:Shutdown()
  Spring.SendCommands('bind f11 luaui selector') -- if this one is removed or crashes, then have the backup one take over.
  
	if (WG['guishader_api'] ~= nil) then
		WG['guishader_api'].RemoveRect('widgetselector')
	end
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
