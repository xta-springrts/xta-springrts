--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_XTA_Layout.lua
--  author:  jK
--  based heavily on code by: Dave Rodgers (aka trepan)
--  orig. filename: layout.lua
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "XTA Layout",
    desc      = "Sets the control panel to XTA default",
    author    = "jK and trepan, mixed by lurker and DeadnightWarrior",
    date      = "Feb 3, 2008",
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


if (false) then  --  disable textured buttons?
  FrameTex   = "false"
  PageNumTex = "false"
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
  widgetHandler.commands.n = cmdCount
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
"textureAlpha 	1.0",
"frameAlpha 	0.5",
"selectGaps 	1",
"selectThrough 	1",

"xPos           0",
"yPos           0.103",
"xSelectionPos  0.068",
"ySelectionPos  0.1001",
"prevPageSlot 	auto",
"deadIconSlot 	none",
"nextPageSlot 	auto",
"textBorder 	0.0025",
"iconBorder 	0.0005",
"frameBorder 	0.000",

"xIcons         4",
"yIcons         9"
}

local config = {
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	local X, Y = Spring.GetViewGeometry()

	-- 4:3 Screen aspect ratio
	if (X/Y == 4/3) then
		config = {"xIconSize 0.055", "yIconSize 0.0695"}

	-- 5:4 Screen aspect ratio
	elseif (X/Y == 5/4) then
		config = {"xIconSize 0.058", "yIconSize 0.0713"}

	-- 16:9 Screen aspect ratio
	elseif ((X/Y == 16/9) or (X==1366 and Y==768)) then
		config = {"xIconSize 0.043", "yIconSize 0.0643"}

	-- 16:10 Screen aspect ratio
	elseif (X/Y == 16/10) then
		config = {"xIconSize 0.046", "yIconSize 0.0643"}
	else
		Echo("Control Panel Widget doens't support your " ..X.. "x" ..Y.. " resolution.")
		Echo("Call back your default Layout.")
		Shutdown()
		return
	end

	local file = io.open(LUAUI_DIRNAME .. 'ctrlpanelImp.txt', 'w')

	for k, v in pairs(commonConfig) do
		file:write(v .. '\n')
	end
	for k, v in pairs(config) do
		file:write(v .. '\n')
	end

	file:close()
	Spring.SendCommands('ctrlpanel ' .. LUAUI_DIRNAME .. 'ctrlpanelImp.txt')

	widgetHandler:ConfigLayoutHandler(CustomLayoutHandler)
end

function widget:Shutdown()
  Spring.SendCommands({"ctrlpanel " .. LUAUI_DIRNAME .. "ctrlpanel.txt"})
  widgetHandler:ConfigLayoutHandler(true)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
