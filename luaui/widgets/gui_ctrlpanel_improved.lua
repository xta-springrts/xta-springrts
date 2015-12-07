--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_ctrlpanel_modified.lua
--  Modifications by Adonai_Jr
--  Tnx for Meltrax iceUI who inspired this menu (and some code)
--
--  based heavily on BA layout
--  see the original for credits authors
--
--  Copyright (C) 2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "CtrlPanel Improved",
    desc      = "Sets transparency to control panel and correct icons aspect ratio v2.0",
    author    = "Adonai_Jr, heavily based on BA layout, see original source for credits",
    date      = "Jan 23, 2009", -- Corrected error message spawn, June 2012, Jools
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    handler   = true,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")

local langSuffix = Spring.GetConfigString('Language', 'fr')
local l10nName = 'L10N/commands_' .. langSuffix .. '.lua'
local success, translations = pcall(VFS.Include, l10nName)
if (not success) then
  translations = nil
end

-- for DefaultHandler
local FrameTex   = "bitmaps/icons/frame_slate_128x96.png"
local FrameScale     = "&0.099x0.132&"
local PageNumTex = "bitmaps/circularthingy.tga"

if (true) then  --  disable textured buttons?
  FrameTex   = "" --"false"
  PageNumTex = "" --"false"
end

local PageNumCmd = {
  name     = "1",
  iconname = PageNumTexture,
  tooltip  = "Active Page Number\n(click to toggle buildiconsfirst)",
  actions  = { "buildiconsfirst", "firstmenu" }
}

if (Game.version:find("0.75")==nil)or(Game.version:find("svn")) then
  PageNumCmd.texture  = PageNumCmd.iconname
  PageNumCmd.iconname = nil
end

--------------------------------------------------------------------------------

local function CustomLayoutHandler(xIcons, yIcons, cmdCount, commands)

  widgetHandler.commands   = commands
  --widgetHandler.commands.n = cmdCount
  widgetHandler:CommandsChanged()

  -- FIXME: custom commands
  if (cmdCount <= 0) then
    return "", xIcons, yIcons, {}, {}, {}, {}, {}, {}, {}, {}
  end

  local menuName = ''
  local removeCmds = {}
  local customCmds = widgetHandler.customCommands
  local onlyTexCmds = {}
  local reTexCmds = {}
  local reNamedCmds = {}
  local reTooltipCmds = {}
  local reParamsCmds = {}
  local iconList = {}

  local ipp = (xIcons * yIcons)  -- iconsPerPage

  local activePage = Spring.GetActivePage()

  local prevCmd = cmdCount - 1
  local nextCmd = cmdCount - 0
  local prevPos = ipp - xIcons
  local nextPos = ipp - 1
  if (prevCmd >= 1) then reTexCmds[prevCmd] = FrameTex end
  if (nextCmd >= 1) then reTexCmds[nextCmd] = FrameTex end

  local pageNumCmd = -1
  local pageNumPos = (prevPos + nextPos) / 2
  if (xIcons > 2) then
    local color
    if (commands[1].id < 0) then color = GreenStr else color = RedStr end
    local activePage = activePage or 0
    local pageNum = '' .. (activePage + 1) .. ''
    PageNumCmd.name = color .. '   ' .. pageNum .. '   '
    table.insert(customCmds, PageNumCmd)
    pageNumCmd = cmdCount + 1
  end

  local pos = 0;
  local firstSpecial = (xIcons * (yIcons - 1))

  for cmdSlot = 1, (cmdCount - 2) do

    -- fill the last row with special buttons
    while (math.fmod(pos, ipp) >= firstSpecial) do
      pos = pos + 1
    end
    local onLastRow = (math.abs(math.fmod(pos, ipp)) < 0.1)

    if (onLastRow) then
      local pageStart = math.floor(ipp * math.floor(pos / ipp))
      if (pageStart > 0) then
        iconList[prevPos + pageStart] = prevCmd
        iconList[nextPos + pageStart] = nextCmd
        if (pageNumCmd > 0) then
          iconList[pageNumPos + pageStart] = pageNumCmd
        end
      end
      if (pageStart == ipp) then
        iconList[prevPos] = prevCmd
        iconList[nextPos] = nextCmd
        if (pageNumCmd > 0) then
          iconList[pageNumPos] = pageNumCmd
        end
      end
    end

    -- add the command icons to iconList
    local cmd = commands[cmdSlot]

    if ((cmd ~= nil) and (cmd.hidden == false)) then

      iconList[pos] = cmdSlot
      pos = pos + 1

      local cmdTex = cmd.texture or "" -- FIXME 0.75b2 compatibility

      if (translations) then
        local trans = translations[cmd.id]
        if (trans) then
          reTooltipCmds[cmdSlot] = trans.desc
          if (not trans.params) then
            if (cmd.id ~= CMD.STOCKPILE) then
              reNamedCmds[cmdSlot] = trans.name
            end
          else
            local num = tonumber(cmd.params[1])
            if (num) then
              num = (num + 1)
              cmd.params[num] = trans.params[num]
              reParamsCmds[cmdSlot] = cmd.params
            end
          end
        end
      end
    end
  end

  return menuName, xIcons, yIcons,
         removeCmds, customCmds,
         onlyTexCmds, reTexCmds,
         reNamedCmds, reTooltipCmds, reParamsCmds,
         iconList
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Echo = Spring.Echo

local commonConfig = {
"outlinefont 	1",
"dropShadows 	1",
"useOptionLEDs 	1",
"textureAlpha 	0.75",
"frameAlpha 	0.30",
"selectGaps 	1",
"selectThrough 	1",

"xPos           0",
"xSelectionPos 0.45",
"ySelectionPos 0.11",
"prevPageSlot 	auto",
"deadIconSlot 	none",
"nextPageSlot 	auto",
"textBorder 	0.002",
"iconBorder 	0.0015",
"frameBorder 	0.0015"
}

local config = {
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	local X, Y = Spring.GetViewGeometry()

	if (X == 800 and Y == 600) then
		config = {"xIcons 5", "yIcons 9", "xIconSize 0.044", "yIconSize 0.0586", "yPos 0.14" }
	elseif (X == 1024 and Y == 768) then
		config = {"xIcons 5", "yIcons 9", "xIconSize 0.0435", "yIconSize 0.0580", "yPos 0.13"}
	elseif (X == 1152 and Y == 864) then
		config = {"xIcons 5", "yIcons 9", "xIconSize 0.0435", "yIconSize 0.0580", "yPos 0.13"}
	elseif (X == 1280 and Y == 800) then
		config = {"xIcons 5", "yIcons 9", "xIconSize 0.036", "yIconSize 0.0576", "yPos 0.13"}
	elseif (X == 1280 and Y == 960) then
		config = {"xIcons 5", "yIcons 10", "xIconSize 0.041", "yIconSize 0.0546", "yPos 0.11"}
	elseif (X == 1280 and Y == 1024) then
		config = {"xIcons 3", "yIcons 9", "xIconSize 0.055", "yIconSize 0.056", "yPos 0.12"}
	elseif (X == 1440 and Y == 900) then
		config = {"xIcons 5", "yIcons 10", "xIconSize 0.035", "yIconSize 0.056", "yPos 0.1"}
	elseif (X == 1600 and Y == 1200) then
		config = {"xIcons 5", "yIcons 10", "xIconSize 0.042", "yIconSize 0.056", "yPos 0.1"}
	elseif (X == 1680 and Y == 1050) then
		config = {"xIcons 5", "yIcons 10", "xIconSize 0.035", "yIconSize 0.056", "yPos 0.1"}
	elseif (X == 1920 and Y == 1200) then
		config = {"xIcons 5", "yIcons 10", "xIconSize 0.035", "yIconSize 0.056", "yPos 0.1"}
	else
		Echo("Control Panel Widget doens't support your " ..X.. "x" ..Y.. " resolution.")
		Echo("Call back your default Layout.")
		Shutdown()
		return
	end

	local file = io.open('ctrlpanelImp.txt', 'w')

	for k, v in pairs(commonConfig) do
		file:write(v .. '\n')
	end
	for k, v in pairs(config) do
		file:write(v .. '\n')
	end

	file:close()
    Spring.SendCommands('ctrlpanel ctrlpanelImp.txt')

	widgetHandler:ConfigLayoutHandler(CustomLayoutHandler)
end

function widget:Shutdown()
  Spring.SendCommands({"ctrlpanel " .. LUAUI_DIRNAME .. "ctrlpanel.txt"})
  widgetHandler:ConfigLayoutHandler(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--function widget:DrawScreen()
	--if hideGUI then return end
	--DrawBackground()
--end

-- function DrawBackground()
	-- local y1 = 95
	-- local y2 = 1024
	-- local x1 = 2
	-- local x2 = 230
	-- gl.Color(0,0,0,0.1)                              -- draws background rectangle
	-- gl.Rect(x1,y1,x2,y2)
	-- gl.Color(0,0,0,0.2)
	-- gl.Rect(x1-1,y1-1,x1,y2+1)
	-- gl.Rect(x2-1,y1-1,x2,y2+1)
	-- gl.Rect(x1-1,y1-1,x2+1,y1)
	-- gl.Rect(x1-1,y2-1,x2+1,y2)
	-- gl.Color(1,1,1,1)
-- end

