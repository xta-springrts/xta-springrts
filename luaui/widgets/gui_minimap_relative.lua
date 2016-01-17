--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    minimap_relative.lua
--  brief:   keeps the minimap at a relative size (maxspect)
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "RelativeMinimap",
    desc      = "Keeps the minimap at a relative size (maxspect)",
    author    = "trepan, updated by Jools",
    date      = "Sep 11, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--
-- Updated by Jools to work with CtrlPanel Improved
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Adjust these setting to your liking
--

-- offsets, in pixels
local xoff = 2
local yoff = 2

-- maximum fraction of screen size,
-- set one value to 1 to calibrate the other
local xmax = 0.262
local ymax = 0.310


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Make sure these are floored
--

xoff = math.floor(xoff)
yoff = math.floor(yoff)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
    
	local file = VFS.LoadFile('ctrlpanelImp.txt') 
	if file then
		Spring.Log("widget",LOG.INFO,"RelativeMinimap: found ctrlpanelImp.txt and using its config")
		--Spring.Echo(file:find('xIcons'), " AND ",file:find('xIconSize'))
		local XColsPos = file:find('xIcons')
		local XSizePos = file:find('xIconSize')
		local xcols = tonumber(string.sub(file, XColsPos+6, XColsPos + 8))
		local xsize = tonumber(string.sub(file, XSizePos+9, XSizePos + 14))
		
		xmax = xcols * (xsize + 0.003) -- 0.003 is sum of default textborder (0.002) and iconborder (0.001) of ctrlpanelImp
		--Spring.Echo("Variables:",xcols,xsize,xmax)
	end
	widget:ViewResize(widgetHandler:GetViewSizes())
end


function widget:ViewResize(viewSizeX, viewSizeY)
  -- the extra 2 pixels are for the minimap border
  local xp = math.floor(viewSizeX * xmax) - xoff - 2
  local yp = math.floor(viewSizeY * ymax) - yoff - 2
  local limitAspect = (xp / yp)
  local mapAspect = (Game.mapSizeX / Game.mapSizeZ)

  local sx, sy
  if (mapAspect > limitAspect) then
    sx = xp
    sy = xp / mapAspect
  else
    sx = yp * mapAspect
    sy = yp
  end
  sx = math.floor(sx)
  sy = math.floor(sy)
  gl.ConfigMiniMap(xoff, viewSizeY - sy - yoff, sx, sy)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
