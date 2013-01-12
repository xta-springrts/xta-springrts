-- control + \: enable/disable commands not marked by **
-- control + s: switch message-box rendering mode
-- control + p: switch text overflow handling mode
-- control + g: enable/disable message-box dragging
-- control + e: enable/disable message-box resizing
-- control + f: enable/disable message filtering
-- control + o: enable/disable message outlining
-- control + y: enable/disable font outlining
-- control + m: enable/disable scrollable message history
-- control + ,: scroll up message history **
-- control + .: scroll down message history **
-- control + q: decrease message font-size **
-- control + w: increase message font-size **


include("colors.h.lua")
include("keysym.h.lua")

local math_ceil 		= math.ceil
local math_floor 		= math.floor
local math_min 			= math.min
local math_max			= math.max
local string_char		= string.char
local gl_Color 			= gl.Color
local gl_Text 			= gl.Text
local gl_GetTextWidth 	= gl.GetTextWidth
local gl_Rect 			= gl.Rect

function widget:GetInfo()
	return {
		name      = "Message Separator",
		desc      = "chat console that separates player and system messages",
		author    = "Kloot & BD",
		date      = "April 22, 2009",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = false
	}
end


function widget:Initialize()
	-- disable default console
	Spring.SendCommands({"console 0"})

	-- needed in case widget is enabled mid-game
	setDefaultGlobalVars()
	setDefaultUserVars(-1, -1, false)
	buildTable()
end

function widget:Shutdown()
	-- enable default console
	Spring.SendCommands({"console 1"})
end


-- retrieve config data from widget handler
-- (if no config has been saved yet these
-- will be nil but immediately overwritten
-- by setDefaultUserVars())
function widget:SetConfigData(data)
	FILTER_SYSTEM_MESSAGES = data.filterSystemMessages
	TRANSPARENT_RENDERING = data.transparentRendering
	MESSAGE_WRAPPING = data.messageWrapping
	MSGBOX_DRAGGING = data.messageBoxDragging
	MSGBOX_RESIZING = data.messageBoxResizing
	MSGBOX_SCROLLING = data.messageBoxScrolling
	TEXT_OUTLINING = data.textOutlining
	FONT_OUTLINING = data.fontOutlining
	FONT_SIZE = data.fontSize
	FONT_RENDER_STYLE = data.fontRenderStyle
	PLAYER_MSG_BOX_W = data.playerMsgBoxWidth
	PLAYER_MSG_BOX_H = data.playerMsgBoxHeight
	SYSTEM_MSG_BOX_W = data.systemMsgBoxWidth
	SYSTEM_MSG_BOX_H = data.systemMsgBoxHeight
	-- restore relative message box positions
	PLAYER_MSG_BOX_X_MIN = data.playerMsgBoxXMin
	SYSTEM_MSG_BOX_X_MIN = data.systemMsgBoxXMin
	PLAYER_MSG_BOX_Y_MAX = data.playerMsgBoxYMax
	SYSTEM_MSG_BOX_Y_MAX = data.systemMsgBoxYMax

	return
end

-- return config data to widget handler
-- (called on startup after Initialize()
-- and on shutdown before Shutdown())
function widget:GetConfigData()
	-- if our viewport dimensions are OK then
	-- we've completed initialisation properly
	if (SIZE_X > 1 and SIZE_Y > 1) then
		return {
			filterSystemMessages = FILTER_SYSTEM_MESSAGES,
			transparentRendering = TRANSPARENT_RENDERING,
			messageWrapping = MESSAGE_WRAPPING,
			messageBoxDragging = MSGBOX_DRAGGING,
			messageBoxResizing = MSGBOX_RESIZING,
			messageBoxScrolling = MSGBOX_SCROLLING,
			textOutlining = TEXT_OUTLINING,
			fontOutlining = FONT_OUTLINING,
			fontSize = FONT_SIZE,
			fontRenderStyle = FONT_RENDER_STYLE,
			playerMsgBoxWidth = PLAYER_MSG_BOX_W,
			playerMsgBoxHeight = PLAYER_MSG_BOX_H,
			systemMsgBoxWidth = SYSTEM_MSG_BOX_W,
			systemMsgBoxHeight = SYSTEM_MSG_BOX_H,
			playerMsgBoxXMin = PLAYER_MSG_BOX_X_MIN / SIZE_X,
			systemMsgBoxXMin = SYSTEM_MSG_BOX_X_MIN / SIZE_X,
			playerMsgBoxYMax = PLAYER_MSG_BOX_Y_MAX / SIZE_Y,
			systemMsgBoxYMax = SYSTEM_MSG_BOX_Y_MAX / SIZE_Y
		}
	else
		return {}
	end
end


function convertColor(colorarray)
	local red = math_ceil(colorarray[1]*255)
	local green = math_ceil(colorarray[2]*255)
	local blue = math_ceil(colorarray[3]*255)
	red = math_max( red, 1 )
	green = math_max( green, 1 )
	blue = math_max( blue, 1 )
	red = math_min( red, 255 )
	green = math_min( green, 255 )
	blue = math_min( blue, 255 )
	return string_char(255,red,green,blue)
end

function widget:KeyPress(key, modifier, isRepeat)
	if (modifier.ctrl) then
		if (key == MASTER_KEY) then
			if (KEYS_ENABLED == 1) then
				Spring.SendCommands({"echo {MessageSeparator} key-shortcuts disabled"})
				KEYS_ENABLED = 0
			else
				Spring.SendCommands({"echo {MessageSeparator} key-shortcuts enabled"})
				KEYS_ENABLED = 1
			end
		end

		if (KEYS_ENABLED == 1) then
			if (key == FILTER_KEY) then
				if (FILTER_SYSTEM_MESSAGES == 1) then
					FILTER_SYSTEM_MESSAGES = 0
					Spring.SendCommands({"echo {MessageSeparator} message filtering disabled"})
				else
					FILTER_SYSTEM_MESSAGES = 1
					Spring.SendCommands({"echo {MessageSeparator} message filtering enabled"})
				end
			end

			if (key == SWITCH_KEY) then
				if (TRANSPARENT_RENDERING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} transparent rendering disabled"})
					TRANSPARENT_RENDERING = 0
				else
					Spring.SendCommands({"echo {MessageSeparator} transparent rendering enabled"})
					TRANSPARENT_RENDERING = 1
				end
			end

			if (key == WRAP_KEY) then
				if (MESSAGE_WRAPPING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} message wrapping disabled"})
					MESSAGE_WRAPPING = 0
				else
					Spring.SendCommands({"echo {MessageSeparator} message wrapping enabled"})
					MESSAGE_WRAPPING = 1
				end
			end

			if (key == DRAG_KEY) then
				if (MSGBOX_DRAGGING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} message-box dragging disabled"})
					MSGBOX_DRAGGING = 0
				else
					if ( TRANSPARENT_RENDERING == 1 ) then
						Spring.SendCommands({"echo {MessageSeparator} Turn off transparent rendering before enabling drag-mode"})						
					else
						Spring.SendCommands({"echo {MessageSeparator} message-box dragging enabled"})
						MSGBOX_DRAGGING = 1
					end
				end
			end

			if (key == RESIZE_KEY) then
				if (MSGBOX_RESIZING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} message-box resizing disabled"})
					MSGBOX_RESIZING = 0
				else
					if ( TRANSPARENT_RENDERING == 1 ) then
						Spring.SendCommands({"echo {MessageSeparator} Turn off transparent rendering before enabling resize-mode"})						
					else
					Spring.SendCommands({"echo {MessageSeparator} message-box resizing enabled"})
					MSGBOX_RESIZING = 1
					end
				end
			end


			if (key == TEXT_OUTLINE_KEY) then
				if (TEXT_OUTLINING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} text-outlining disabled"})
					TEXT_OUTLINING = 0
				else
					Spring.SendCommands({"echo {MessageSeparator} text-outlining enabled"})
					TEXT_OUTLINING = 1
				end
			end

			if (key == FONT_OUTLINE_KEY) then
				if (FONT_OUTLINING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} font-outlining disabled"})
					FONT_OUTLINING = 0
				else
					Spring.SendCommands({"echo {MessageSeparator} font-outlining enabled"})
					FONT_OUTLINING = 1
				end
			end

	-- 		if (key == FONT_OUTLINE_KEY) then
	-- 			FONT_STYLES_INDEX = math_fmod(FONT_STYLES_INDEX, 3) + 1
	-- 			FONT_RENDER_STYLE = FONT_RENDER_STYLES[FONT_STYLES_INDEX]
	--
	-- 			Spring.SendCommands({"echo {MessageSeparator} font-outlining style set to \'" .. FONT_RENDER_STYLE .. "\'"})
	-- 		end


			if (key == SCROLL_KEY) then
				if (MSGBOX_SCROLLING == 1) then
					Spring.SendCommands({"echo {MessageSeparator} scrollable message history disabled"})
					MSGBOX_SCROLLING = 0

					clearPlayerMessageHistory()
				else
					Spring.SendCommands({"echo {MessageSeparator} scrollable message history enabled"})
					MSGBOX_SCROLLING = 1
				end
			end
		end


		if (key == FONTSIZE_INC_KEY) then
			if (FONT_SIZE < FONT_MAX_SIZE) then
				FONT_SIZE = FONT_SIZE + 1
				MAX_NUM_PLAYER_MESSAGES = math_floor((PLAYER_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)
				MAX_NUM_SYSTEM_MESSAGES = math_floor((SYSTEM_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)

				Spring.SendCommands({"echo {MessageSeparator} font-size increased to " .. FONT_SIZE})
			end
		end
		if (key == FONTSIZE_DEC_KEY) then
			if (FONT_SIZE > 1) then
				FONT_SIZE = FONT_SIZE - 1
				MAX_NUM_PLAYER_MESSAGES = math_floor((PLAYER_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)
				MAX_NUM_SYSTEM_MESSAGES = math_floor((SYSTEM_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)

				Spring.SendCommands({"echo {MessageSeparator} font-size decreased to " .. FONT_SIZE})
			end
		end


		if (key == SCROLL_UP_KEY) then
			if (MSGBOX_SCROLLING == 1) then
				-- if we are in non-transparent rendering mode
				-- then make sure scrolling causes box to appear
				-- (as well as any messages in box)
				PLAYER_BOX_ALPHA = MAX_ALPHA
				DRAW_PLAYER_MESSAGES = true

				if (MESSAGE_FRAME_MIN > 1) then
					MESSAGE_FRAME_MIN = MESSAGE_FRAME_MIN - 1
					MESSAGE_FRAME_MAX = MESSAGE_FRAME_MAX - 1
				end
			end
		end
		if (key == SCROLL_DOWN_KEY) then
			if (MSGBOX_SCROLLING == 1) then
				-- if we are in non-transparent rendering mode
				-- then make sure scrolling causes box to appear
				-- (as well as any messages in box)
				PLAYER_BOX_ALPHA = MAX_ALPHA
				DRAW_PLAYER_MESSAGES = true

				if (MESSAGE_FRAME_MAX < NUM_PLAYER_MESSAGES) then
					MESSAGE_FRAME_MIN = MESSAGE_FRAME_MIN + 1
					MESSAGE_FRAME_MAX = MESSAGE_FRAME_MAX + 1
				end
			end
		end
	end
end




function mouseOverPlayerMessageBox(x, y)
	-- use <BOX_BORDER_SIZE>-pixel borders to make resizing less problematic
	if (x > (PLAYER_MSG_BOX_X_MIN + BOX_BORDER_SIZE) and x < (PLAYER_MSG_BOX_X_MAX - BOX_BORDER_SIZE)) then
		if (y < (PLAYER_MSG_BOX_Y_MAX - BOX_BORDER_SIZE) and y > (PLAYER_MSG_BOX_Y_MIN + BOX_BORDER_SIZE)) then
			return true
		end
	end

	return false
end

function mouseOverSystemMessageBox(x, y)
	-- use BOX_BORDER_SIZE-pixel borders to make resizing less problematic
	if (x > (SYSTEM_MSG_BOX_X_MIN + BOX_BORDER_SIZE) and x < (SYSTEM_MSG_BOX_X_MAX + BOX_BORDER_SIZE)) then
		if (y < (SYSTEM_MSG_BOX_Y_MAX - BOX_BORDER_SIZE) and y > (SYSTEM_MSG_BOX_Y_MIN + BOX_BORDER_SIZE)) then
			return true
		end
	end

	return false
end


-- this would be a lot simpler if we had bit-ops...
function mouseOverPlayerMessageBoxBorder(x, y)
	local r = {0, 0, 0, 0}
	local b = false

	-- left vertical boundary
	if (x > PLAYER_MSG_BOX_X_MIN and x < (PLAYER_MSG_BOX_X_MIN + BOX_BORDER_SIZE)) then
		if (y < PLAYER_MSG_BOX_Y_MAX and y > PLAYER_MSG_BOX_Y_MIN) then
			r[1] = 1
			b = true
		end
	end
	-- right vertical boundary
	if (x > (PLAYER_MSG_BOX_X_MAX - BOX_BORDER_SIZE) and x < PLAYER_MSG_BOX_X_MAX) then
		if (y < PLAYER_MSG_BOX_Y_MAX and y > PLAYER_MSG_BOX_Y_MIN) then
			r[2] = 1
			b = true
		end
	end

	-- top horizontal boundary
	if (y < PLAYER_MSG_BOX_Y_MAX and y > (PLAYER_MSG_BOX_Y_MAX - BOX_BORDER_SIZE)) then
		if (x > PLAYER_MSG_BOX_X_MIN and x < PLAYER_MSG_BOX_X_MAX) then
			r[3] = 1
			b = true

		end
	end
	-- bottom horizontal boundary
	if (y > PLAYER_MSG_BOX_Y_MIN and y < (PLAYER_MSG_BOX_Y_MIN + BOX_BORDER_SIZE)) then
		if (x > PLAYER_MSG_BOX_X_MIN and x < PLAYER_MSG_BOX_X_MAX) then
			r[4] = 1
			b = true
		end
	end

	return {b, r}
end

-- this would be a lot simpler if we had bit-ops...
function mouseOverSystemMessageBoxBorder(x, y)
	local r = {0, 0, 0, 0}
	local b = false

	-- left vertical boundary
	if (x > SYSTEM_MSG_BOX_X_MIN and x < (SYSTEM_MSG_BOX_X_MIN + BOX_BORDER_SIZE)) then
		if (y < SYSTEM_MSG_BOX_Y_MAX and y > SYSTEM_MSG_BOX_Y_MIN) then
			r[1] = 1
			b = true
		end
	end
	-- right vertical boundary
	if (x > (SYSTEM_MSG_BOX_X_MAX - BOX_BORDER_SIZE) and x < SYSTEM_MSG_BOX_X_MAX) then
		if (y < SYSTEM_MSG_BOX_Y_MAX and y > SYSTEM_MSG_BOX_Y_MIN) then
			r[2] = 1
			b = true
		end
	end

	-- top horizontal boundary
	if (y < SYSTEM_MSG_BOX_Y_MAX and y > (SYSTEM_MSG_BOX_Y_MAX - BOX_BORDER_SIZE)) then
		if (x > SYSTEM_MSG_BOX_X_MIN and x < SYSTEM_MSG_BOX_X_MAX) then
			r[3] = 1
			b = true
		end
	end
	-- bottom horizontal boundary
	if (y > SYSTEM_MSG_BOX_Y_MIN and y < (SYSTEM_MSG_BOX_Y_MIN + BOX_BORDER_SIZE)) then
		if (x > SYSTEM_MSG_BOX_X_MIN and x < SYSTEM_MSG_BOX_X_MAX) then
			r[4] = 1
			b = true
		end
	end

	return {b, r}
end



-- MouseMove() and MouseRelease() are not presently called by
-- widget manager so just implement dragging and resizing here
function updateBoxes()
	-- if we can neither drag nor resize then there is nothing to update, move along
	-- (also disallow altering geometry when message boxes are invisible to be safe)
	if ((MSGBOX_DRAGGING == 0 and MSGBOX_RESIZING == 0) or TRANSPARENT_RENDERING == 1) then
		return
	end

	local mx, my, lmb, _, _ = Spring.GetMouseState()

	if (lmb == false) then
		-- update where are we now
		MOUSE_X = mx
		MOUSE_Y = my

		-- button was released (or never pressed)
		DRAGGING_PLAYER_BOX = false
		DRAGGING_SYSTEM_BOX = false
		RESIZING_PLAYER_BOX = false
		RESIZING_SYSTEM_BOX = false
	else
		-- mouse button pressed and/or held down
		local dx = mx - MOUSE_X
		local dy = my - MOUSE_Y

		-- update where are we now
		MOUSE_X = mx
		MOUSE_Y = my


		if (MSGBOX_DRAGGING == 1) then
			local mouseOverPlayerBox = mouseOverPlayerMessageBox(mx, my)
			local mouseOverSystemBox = mouseOverSystemMessageBox(mx, my)

			-- we must be over player box and not dragging system box and have at least one message visible
			if (mouseOverPlayerBox == true and DRAGGING_SYSTEM_BOX == false and NUM_PLAYER_MESSAGES > 0) then
				PLAYER_MSG_BOX_X_MIN = PLAYER_MSG_BOX_X_MIN + dx
				PLAYER_MSG_BOX_X_MAX = PLAYER_MSG_BOX_X_MAX + dx
				PLAYER_MSG_BOX_Y_MAX = PLAYER_MSG_BOX_Y_MAX + dy
				PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MAX - PLAYER_MSG_BOX_H
				DRAGGING_PLAYER_BOX = true

				-- return here in case player message box is positioned over
				-- system message box so we don't start moving that as well
				return
			end

			-- we must be over system box and not dragging player box and have at least one message visible
			if (mouseOverSystemBox == true and DRAGGING_PLAYER_BOX == false and NUM_SYSTEM_MESSAGES > 0) then
				SYSTEM_MSG_BOX_X_MIN = SYSTEM_MSG_BOX_X_MIN + dx
				SYSTEM_MSG_BOX_X_MAX = SYSTEM_MSG_BOX_X_MAX + dx
				SYSTEM_MSG_BOX_Y_MAX = SYSTEM_MSG_BOX_Y_MAX + dy
				SYSTEM_MSG_BOX_Y_MIN = SYSTEM_MSG_BOX_Y_MAX - SYSTEM_MSG_BOX_H
				DRAGGING_SYSTEM_BOX = true

				-- dragging takes precedence over resizing if both are enabled
				return
			end
		end


		if (MSGBOX_RESIZING == 1) then
			local mouseOverPlayerBoxBorder = mouseOverPlayerMessageBoxBorder(mx, my)
			local mouseOverSystemBoxBorder = mouseOverSystemMessageBoxBorder(mx, my)

			-- we must be over player box border and not resizing system box and have at least one message visible
			if (mouseOverPlayerBoxBorder[1] == true and RESIZING_SYSTEM_BOX == false and NUM_PLAYER_MESSAGES > 0) then
				if (PLAYER_MSG_BOX_W > PLAYER_MSG_BOX_MIN_W) then
					if (mouseOverPlayerBoxBorder[2][1] == 1) then PLAYER_MSG_BOX_X_MIN = PLAYER_MSG_BOX_X_MIN + dx end
					if (mouseOverPlayerBoxBorder[2][2] == 1) then PLAYER_MSG_BOX_X_MAX = PLAYER_MSG_BOX_X_MAX + dx end
				else
					-- we may only increase horizontal box size (meaning if we are over left border
					-- and moving mouse left or if we are over right border and moving mouse right)
					if (mouseOverPlayerBoxBorder[2][1] == 1 and dx < 0) then PLAYER_MSG_BOX_X_MIN = PLAYER_MSG_BOX_X_MIN + dx end
					if (mouseOverPlayerBoxBorder[2][2] == 1 and dx > 0) then PLAYER_MSG_BOX_X_MAX = PLAYER_MSG_BOX_X_MAX + dx end
				end

				if (PLAYER_MSG_BOX_H > PLAYER_MSG_BOX_MIN_H) then
					if (mouseOverPlayerBoxBorder[2][3] == 1) then PLAYER_MSG_BOX_Y_MAX = PLAYER_MSG_BOX_Y_MAX + dy end
					if (mouseOverPlayerBoxBorder[2][4] == 1) then PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MIN + dy end
				else
					-- we may only increase vertical box size (meaning if we are over top border
					-- and moving mouse up or if we are over bottom border and moving mouse down)
					if (mouseOverPlayerBoxBorder[2][3] == 1 and dy > 0) then PLAYER_MSG_BOX_Y_MAX = PLAYER_MSG_BOX_Y_MAX + dy end
					if (mouseOverPlayerBoxBorder[2][4] == 1 and dy < 0) then PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MIN + dy end
				end

				PLAYER_MSG_BOX_W = PLAYER_MSG_BOX_X_MAX - PLAYER_MSG_BOX_X_MIN
				PLAYER_MSG_BOX_H = PLAYER_MSG_BOX_Y_MAX - PLAYER_MSG_BOX_Y_MIN
				MAX_NUM_PLAYER_MESSAGES = math_floor((PLAYER_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)
				RESIZING_PLAYER_BOX = true

				-- return here in case player message box is stretched out across
				-- system message box so we don't start resizing that as well
				return
			end

			-- we must be over system box border and not resizing player box and have at least one message visible
			if (mouseOverSystemBoxBorder[1] == true and RESIZING_PLAYER_BOX == false and NUM_SYSTEM_MESSAGES > 0) then
				if (SYSTEM_MSG_BOX_W > SYSTEM_MSG_BOX_MIN_W) then
					if (mouseOverSystemBoxBorder[2][1] == 1) then SYSTEM_MSG_BOX_X_MIN = SYSTEM_MSG_BOX_X_MIN + dx end
					if (mouseOverSystemBoxBorder[2][2] == 1) then SYSTEM_MSG_BOX_X_MAX = SYSTEM_MSG_BOX_X_MAX + dx end
				else
					-- we may only increase horizontal box size (meaning if we are over left border
					-- and moving mouse left or if we are over right border and moving mouse right)
					if (mouseOverSystemBoxBorder[2][1] == 1 and dx < 0) then SYSTEM_MSG_BOX_X_MIN = SYSTEM_MSG_BOX_X_MIN + dx end
					if (mouseOverSystemBoxBorder[2][2] == 1 and dx > 0) then SYSTEM_MSG_BOX_X_MAX = SYSTEM_MSG_BOX_X_MAX + dx end
				end

				if (SYSTEM_MSG_BOX_H > SYSTEM_MSG_BOX_MIN_H) then
					if (mouseOverSystemBoxBorder[2][3] == 1) then SYSTEM_MSG_BOX_Y_MAX = SYSTEM_MSG_BOX_Y_MAX + dy end
					if (mouseOverSystemBoxBorder[2][4] == 1) then SYSTEM_MSG_BOX_Y_MIN = SYSTEM_MSG_BOX_Y_MIN + dy end
				else
					-- we may only increase vertical box size (meaning if we are over top border
					-- and moving mouse up or if we are over bottom border and moving mouse down)
					if (mouseOverSystemBoxBorder[2][3] == 1 and dy > 0) then SYSTEM_MSG_BOX_Y_MAX = SYSTEM_MSG_BOX_Y_MAX + dy end
					if (mouseOverSystemBoxBorder[2][4] == 1 and dy < 0) then SYSTEM_MSG_BOX_Y_MIN = SYSTEM_MSG_BOX_Y_MIN + dy end
				end

				SYSTEM_MSG_BOX_W = SYSTEM_MSG_BOX_X_MAX - SYSTEM_MSG_BOX_X_MIN
				SYSTEM_MSG_BOX_H = SYSTEM_MSG_BOX_Y_MAX - SYSTEM_MSG_BOX_Y_MIN
				MAX_NUM_SYSTEM_MESSAGES = math_floor((SYSTEM_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)
				RESIZING_SYSTEM_BOX = true

				return
			end
		end
	end
end




-- set default values for user-configurable vars
-- if they haven't yet been initialized (called
-- (from Initialize() and ViewResize() call-ins)
function setDefaultUserVars(sizeX, sizeY, useParams)
	if (FILTER_SYSTEM_MESSAGES == nil) then FILTER_SYSTEM_MESSAGES = 1 end
	if (TRANSPARENT_RENDERING == nil) then TRANSPARENT_RENDERING = 1 end
	if (MESSAGE_WRAPPING == nil) then MESSAGE_WRAPPING = 1 end
	if (MSGBOX_DRAGGING == nil) then MSGBOX_DRAGGING = 0 end
	if (MSGBOX_RESIZING == nil) then MSGBOX_RESIZING = 0 end
	if (MSGBOX_SCROLLING == nil) then MSGBOX_SCROLLING = 1 end
	if (TEXT_OUTLINING == nil) then TEXT_OUTLINING = 1 end
	if (FONT_OUTLINING == nil) then FONT_OUTLINING = 0 end
	if (FONT_SIZE == nil) then FONT_SIZE = 15 end

	if (FONT_RENDER_STYLE == nil) then FONT_RENDER_STYLE = FONT_RENDER_STYLES[1] end


	if (useParams == true) then
		SIZE_X = sizeX
		SIZE_Y = sizeY
	else
		-- get dimensions of our OGL viewport
		SIZE_X, SIZE_Y = widgetHandler:GetViewSizes()
	end

	if (SIZE_X > 1 and SIZE_Y > 1) then
		-- default positions and dimensions of message boxes are relative to viewport size
		if ((PLAYER_MSG_BOX_W == nil or PLAYER_MSG_BOX_H == nil) or (SYSTEM_MSG_BOX_W == nil or SYSTEM_MSG_BOX_H == nil)) then
			PLAYER_MSG_BOX_X_MIN = (SIZE_X / 4)
			PLAYER_MSG_BOX_X_MAX = (SIZE_X / 4) * 3
			SYSTEM_MSG_BOX_X_MIN = PLAYER_MSG_BOX_X_MIN
			SYSTEM_MSG_BOX_X_MAX = PLAYER_MSG_BOX_X_MAX

			PLAYER_MSG_BOX_W = PLAYER_MSG_BOX_X_MAX - PLAYER_MSG_BOX_X_MIN
			SYSTEM_MSG_BOX_W = SYSTEM_MSG_BOX_X_MAX - SYSTEM_MSG_BOX_X_MIN
			PLAYER_MSG_BOX_H = (SIZE_Y / 8) + (SIZE_Y / 16)
			SYSTEM_MSG_BOX_H = (PLAYER_MSG_BOX_H / 2)

			PLAYER_MSG_BOX_Y_MAX = SIZE_Y - 40
			PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MAX - PLAYER_MSG_BOX_H
			SYSTEM_MSG_BOX_Y_MAX = PLAYER_MSG_BOX_Y_MIN - 50
			SYSTEM_MSG_BOX_Y_MIN = SYSTEM_MSG_BOX_Y_MAX - SYSTEM_MSG_BOX_H
		else
			-- turn serialized relative coordinates into absolute ones again
			-- (if coordinates are already absolute then we should reposition
			-- and/or resize boxes, but for now just do nothing)
			if ((PLAYER_MSG_BOX_X_MIN < 1 and PLAYER_MSG_BOX_Y_MAX < 1) and (SYSTEM_MSG_BOX_X_MIN < 1 and SYSTEM_MSG_BOX_Y_MAX < 1)) then
				PLAYER_MSG_BOX_X_MIN = PLAYER_MSG_BOX_X_MIN * SIZE_X
				SYSTEM_MSG_BOX_X_MIN = SYSTEM_MSG_BOX_X_MIN * SIZE_X
				PLAYER_MSG_BOX_Y_MAX = PLAYER_MSG_BOX_Y_MAX * SIZE_Y
				SYSTEM_MSG_BOX_Y_MAX = SYSTEM_MSG_BOX_Y_MAX * SIZE_Y
				-- restore message box dimensions
				PLAYER_MSG_BOX_X_MAX = PLAYER_MSG_BOX_X_MIN + PLAYER_MSG_BOX_W
				SYSTEM_MSG_BOX_X_MAX = SYSTEM_MSG_BOX_X_MIN + SYSTEM_MSG_BOX_W
				PLAYER_MSG_BOX_Y_MIN = PLAYER_MSG_BOX_Y_MAX - PLAYER_MSG_BOX_H
				SYSTEM_MSG_BOX_Y_MIN = SYSTEM_MSG_BOX_Y_MAX - SYSTEM_MSG_BOX_H
			end
		end

		MAX_NUM_PLAYER_MESSAGES = math_floor((PLAYER_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)
		MAX_NUM_SYSTEM_MESSAGES = math_floor((SYSTEM_MSG_BOX_H - FONT_SIZE) / FONT_SIZE)

		MESSAGE_FRAME_MIN = 1
		MESSAGE_FRAME_MAX = MAX_NUM_PLAYER_MESSAGES
	end
end


-- initialize all (default) non-user global variables
function setDefaultGlobalVars()
	BOX_BORDER_SIZE				= 30
	PLAYER_MSG_BOX_MIN_W		= BOX_BORDER_SIZE * 4
	PLAYER_MSG_BOX_MIN_H		= BOX_BORDER_SIZE * 4
	SYSTEM_MSG_BOX_MIN_W		= BOX_BORDER_SIZE * 4
	SYSTEM_MSG_BOX_MIN_H		= BOX_BORDER_SIZE * 4

	FONT_MAX_SIZE				= 30
	ROSTER_SORT_TYPE			= 1

	NAME_PREFIX_PATTERNS		= {"%<", "%["}
	NAME_POSTFIX_PATTERNS		= {"%> ", "%] "}

	NUM_PLAYER_MESSAGES			= 0
	NUM_SYSTEM_MESSAGES			= 0

	MASTER_KEY					= KEYSYMS.BACKSLASH
	FILTER_KEY					= KEYSYMS.F
	SWITCH_KEY					= KEYSYMS.S
	WRAP_KEY					= KEYSYMS.P
	DRAG_KEY					= KEYSYMS.G
	RESIZE_KEY					= KEYSYMS.E
	TEXT_OUTLINE_KEY			= KEYSYMS.O
	FONT_OUTLINE_KEY			= KEYSYMS.Y
	FONTSIZE_INC_KEY			= KEYSYMS.Q
	FONTSIZE_DEC_KEY			= KEYSYMS.W
	SCROLL_KEY					= KEYSYMS.M
	SCROLL_UP_KEY				= KEYSYMS.COMMA
	SCROLL_DOWN_KEY				= KEYSYMS.PERIOD

	-- how many game-logic frames to wait
	-- before clearing message buffers at
	-- normal (1x) speed, 30 frames per sec
	DELAY_BEFORE_CLEAR			= 900

	-- clear boxes on resize since text
	-- might otherwise end up outside them
	PLAYER_MSG_HISTORY			= {}
	SYSTEM_MSG_HISTORY			= {}

	-- "n": ignore embedded colors, "o/O": black/white outline
	FONT_RENDER_STYLES			= {"", "o", "O"}

	MIN_ALPHA					= 0.0
	MAX_ALPHA					= 0.8
	PLAYER_BOX_ALPHA			= MIN_ALPHA
	SYSTEM_BOX_ALPHA			= MIN_ALPHA

	PLAYER_BOX_FILL_COLOR			= {0.66, 0.66, 0.66, PLAYER_BOX_ALPHA}
	PLAYER_BOX_LINE_COLOR			= {0.22, 0.22, 0.22, PLAYER_BOX_ALPHA}
	SYSTEM_BOX_FILL_COLOR			= {0.66, 0.66, 0.66, SYSTEM_BOX_ALPHA}
	SYSTEM_BOX_LINE_COLOR			= {0.22, 0.22, 0.22, SYSTEM_BOX_ALPHA}
	PLAYER_TEXT_OUTLINE_COLOR		= {0.00, 0.00, 0.20, 0.20}
	PLAYER_TEXT_DEFAULT_COLOR		= {-1.0, -1.0, -1.0, 1.0}
	SYSTEM_TEXT_COLOR				= { 1.0,  1.0,  1.0, 1.0}
	
	USECOLORCODES = true -- use color codes to define font colors, otherwise uses gl_Color, unfortunately, colored font with outline doesn't seems to be supported when this is off


	-- timer-related variables
	CURRENT_FRAME				= 0
	LAST_PLAYER_MSG_CLEAR_FRAME	= 0
	LAST_SYSTEM_MSG_CLEAR_FRAME	= 0

	-- table mapping names to colors
	PLAYER_COLOR_TABLE			= {}

	-- message patterns our filter should match
	MESSAGE_FILTERS				= {"Can't reach destination", "Build pos blocked", "Delayed response", "Sync error"}

	-- mouse-state trackers
	MOUSE_X						= 0
	MOUSE_Y						= 0

	-- are we currently dragging or resizing a message box?
	DRAGGING_PLAYER_BOX			= false
	DRAGGING_SYSTEM_BOX			= false
	RESIZING_PLAYER_BOX			= false
	RESIZING_SYSTEM_BOX			= false

	-- has time to visually clear messages been reached?
	-- (note: only used in scrollable-history mode)
	DRAW_PLAYER_MESSAGES		= true

	-- which font render-style are we currently using?
	-- (currently only set here in favor of formula)
	FONT_STYLES_INDEX			= 1

	-- should key commands be enabled?
	KEYS_ENABLED				= 1
	
	LAST_LINE					= ""
end


function clearPlayerMessageHistory()
	PLAYER_MSG_HISTORY = {}
	NUM_PLAYER_MESSAGES = 0
end
function clearSystemMessageHistory()
	SYSTEM_MSG_HISTORY = {}
	NUM_SYSTEM_MESSAGES = 0
end


-- if our viewport is resized then we need to
-- reposition (and resize?) our message boxes
-- accordingly since they might end up outside
-- viewport (note: also called on startup with
-- nil parameters!)
function widget:ViewResize(newSizeX, newSizeY)
	if (newSizeX ~= nil and newSizeY ~= nil) then
		if (newSizeX > 1 and newSizeY > 1) then
			setDefaultUserVars(newSizeX, newSizeY, true)
		end
	end
end


-- clear our message buffers if it's time
-- (used for lack of an Update() call-in)
function widget:DrawWorld()
	updateBoxes()

	if (Spring.GetGameFrame() ~= CURRENT_FRAME) then
		CURRENT_FRAME = CURRENT_FRAME + 1
	end

	local modifyingPlayerBox = DRAGGING_PLAYER_BOX or RESIZING_PLAYER_BOX
	local modifyingSystemBox = DRAGGING_SYSTEM_BOX or RESIZING_SYSTEM_BOX

	-- is it time to clear our player message buffer and are we not modifying it right now?
	if ((modifyingPlayerBox == false) and ((CURRENT_FRAME - LAST_PLAYER_MSG_CLEAR_FRAME) > DELAY_BEFORE_CLEAR)) then
		if (MSGBOX_SCROLLING == 0) then
			clearPlayerMessageHistory()
		else
			DRAW_PLAYER_MESSAGES = false
		end

		LAST_PLAYER_MSG_CLEAR_FRAME = CURRENT_FRAME
		PLAYER_BOX_ALPHA = MIN_ALPHA
	end

	-- is it time to clear our system message buffer and are we not modifying it right now?
	if ((modifyingSystemBox == false) and ((CURRENT_FRAME - LAST_SYSTEM_MSG_CLEAR_FRAME) > DELAY_BEFORE_CLEAR)) then
		LAST_SYSTEM_MSG_CLEAR_FRAME = CURRENT_FRAME
		SYSTEM_BOX_ALPHA = MIN_ALPHA

		clearSystemMessageHistory()
	end
end




-- add message to player or system buffer
function widget:AddConsoleLine(line)
	if (string.len(line) > 0) then
		local playerName = getPlayerName(line)
		local playerColor = getPlayerColor(playerName)
		local playerFontStyle = getPlayerFontStyle(playerColor)

		if ( line == LAST_LINE ) then
			return -- drop duplicate messages
		end
		LAST_LINE = line

		if (string.len(playerName) > 0) then
			-- if we can't scroll then we need to check
			-- how many messages can still fit inside box
			if (MSGBOX_SCROLLING == 0) then
				-- is player message box about to overflow vertically?
				if (NUM_PLAYER_MESSAGES >= MAX_NUM_PLAYER_MESSAGES) then
					clearPlayerMessageHistory()
				end
			else
				-- autoscroll if bottom of message
				-- frame is equal to last message
				if (MESSAGE_FRAME_MAX == NUM_PLAYER_MESSAGES) then
					MESSAGE_FRAME_MIN = MESSAGE_FRAME_MIN + 1
					MESSAGE_FRAME_MAX = MESSAGE_FRAME_MAX + 1
				end

				DRAW_PLAYER_MESSAGES = true
			end

			LAST_PLAYER_MSG_CLEAR_FRAME = CURRENT_FRAME
			PLAYER_MSG_HISTORY[NUM_PLAYER_MESSAGES + 1] = {playerColor, playerFontStyle, line}
			NUM_PLAYER_MESSAGES = NUM_PLAYER_MESSAGES + 1
			PLAYER_BOX_ALPHA = MAX_ALPHA

		else
			if (FILTER_SYSTEM_MESSAGES == 1) then
				for index = 1, table.getn(MESSAGE_FILTERS), 1 do
					if (string.find(line, MESSAGE_FILTERS[index]) ~= nil) then
						return
					end
				end
			end

			-- is system message box about to overflow vertically?
			if ( NUM_SYSTEM_MESSAGES ~= nil ) then
				if ( MAX_NUM_SYSTEM_MESSAGES ~= nil ) then
					if (NUM_SYSTEM_MESSAGES >= MAX_NUM_SYSTEM_MESSAGES) then
						clearSystemMessageHistory()
					end
				end
			end

			LAST_SYSTEM_MSG_CLEAR_FRAME = CURRENT_FRAME
			SYSTEM_MSG_HISTORY[NUM_SYSTEM_MESSAGES + 1] = line
			NUM_SYSTEM_MESSAGES = NUM_SYSTEM_MESSAGES + 1
			SYSTEM_BOX_ALPHA = MAX_ALPHA
		end
	end
end




function widget:DrawScreen()
	local y

	-- only draw boxes if user wants them to be visible
	-- and there's at least one message present in each
	if (TRANSPARENT_RENDERING == 0) then
		PLAYER_BOX_FILL_COLOR[4] = PLAYER_BOX_ALPHA
		PLAYER_BOX_LINE_COLOR[4] = PLAYER_BOX_ALPHA
		SYSTEM_BOX_FILL_COLOR[4] = SYSTEM_BOX_ALPHA
		SYSTEM_BOX_LINE_COLOR[4] = SYSTEM_BOX_ALPHA

		if (NUM_PLAYER_MESSAGES > 0) then
			drawBox(PLAYER_MSG_BOX_X_MIN, PLAYER_MSG_BOX_Y_MAX, PLAYER_MSG_BOX_W, PLAYER_MSG_BOX_H, PLAYER_BOX_FILL_COLOR, PLAYER_BOX_LINE_COLOR)
		end
		if (NUM_SYSTEM_MESSAGES > 0) then
			drawBox(SYSTEM_MSG_BOX_X_MIN, SYSTEM_MSG_BOX_Y_MAX, SYSTEM_MSG_BOX_W, SYSTEM_MSG_BOX_H, SYSTEM_BOX_FILL_COLOR, SYSTEM_BOX_LINE_COLOR)
		end
	end


	y = PLAYER_MSG_BOX_Y_MAX - (FONT_SIZE + 6)

	if (MSGBOX_SCROLLING == 0) then
		-- draw player message strings
		for index = 1, table.getn(PLAYER_MSG_HISTORY), 1 do
			local playerColor = PLAYER_MSG_HISTORY[index][1]
			local playerFontStyle = PLAYER_MSG_HISTORY[index][2]
			local playerMessage = PLAYER_MSG_HISTORY[index][3]
			local playerMessageWidth = (gl_GetTextWidth(playerMessage) * FONT_SIZE)

			if (MESSAGE_WRAPPING == 1) then
				local bufferIndex, buffer = getMessageParts(playerMessage, playerMessageWidth, PLAYER_MSG_BOX_W)

				if (bufferIndex > 1) then
					-- our buffer was filled with at least two message parts
					copyPlayerMessageBuffer(buffer, bufferIndex, index, playerColor, playerFontStyle)

					-- we've expanded our player message
					-- history, abort drawing this frame
					break
				end
			else
				-- fix horizontal overflow the easy way
				playerMessage, _ = splitMessage(playerMessage, playerMessageWidth, PLAYER_MSG_BOX_W)
			end

			-- make sure messages do not get printed below
			-- bottom edge of box in case user increased
			-- fontsize and box already reasonably full
			if (index <= MAX_NUM_PLAYER_MESSAGES) then
				if (TEXT_OUTLINING == 1 and TRANSPARENT_RENDERING == 1) then
					-- draw bars behind player messages (only if player message box not rendered)
					drawBox((PLAYER_MSG_BOX_X_MIN + 10), (y + FONT_SIZE), PLAYER_MSG_BOX_W, FONT_SIZE, PLAYER_TEXT_OUTLINE_COLOR, PLAYER_TEXT_OUTLINE_COLOR)
				end
				
				local text = playerMessage
				local style = playerFontStyle
				if ( USECOLORCODES ) then
					local colorcode = convertColor(playerColor)
					text = colorcode..playerMessage
				else
					style = playerFontStyle.."n"
				end
				gl_Color(playerColor[1], playerColor[2], playerColor[3], playerColor[4])
				gl_Text(text, SYSTEM_MSG_BOX_X_MIN + 10, y, FONT_SIZE, style)
			end

			y = y - FONT_SIZE
		end

	else
		-- because PLAYER_MSG_HISTORY is never reset to {}
		-- while scrollable history enabled we need another
		-- way to determine if we should draw messages
		if (DRAW_PLAYER_MESSAGES == true) then
			for index = MESSAGE_FRAME_MIN, MESSAGE_FRAME_MAX, 1 do
				if (index <= NUM_PLAYER_MESSAGES) then
					if PLAYER_MSG_HISTORY[index] ~= nil then
						local playerColor = PLAYER_MSG_HISTORY[index][1]
						local playerFontStyle = PLAYER_MSG_HISTORY[index][2]
						local playerMessage = PLAYER_MSG_HISTORY[index][3]
						local playerMessageWidth = (gl_GetTextWidth(playerMessage) * FONT_SIZE )

						if (MESSAGE_WRAPPING == 1) then
							local bufferIndex, buffer = getMessageParts(playerMessage, playerMessageWidth, PLAYER_MSG_BOX_W)

							if (bufferIndex > 1) then
								-- our buffer was filled with at least two message parts
								copyPlayerMessageBuffer(buffer, bufferIndex, index, playerColor, playerFontStyle)

								-- we've expanded our player message
								-- history, abort drawing this frame
								break
							end
						else
							-- fix horizontal overflow the easy way
							playerMessage, _ = splitMessage(playerMessage, playerMessageWidth, PLAYER_MSG_BOX_W)
						end

						if (TEXT_OUTLINING == 1 and TRANSPARENT_RENDERING == 1) then
							-- draw bars behind player messages (only if player message box not rendered)
							drawBox((PLAYER_MSG_BOX_X_MIN + 10), (y + FONT_SIZE), PLAYER_MSG_BOX_W, FONT_SIZE, PLAYER_TEXT_OUTLINE_COLOR, PLAYER_TEXT_OUTLINE_COLOR)
						end

						local text = playerMessage
						local style = playerFontStyle
						if ( USECOLORCODES ) then
							local colorcode = convertColor(playerColor)
							text = colorcode..playerMessage
						else
							style = playerFontStyle.."n"
						end
						gl_Color(playerColor[1], playerColor[2], playerColor[3], playerColor[4])
						gl_Text(text, SYSTEM_MSG_BOX_X_MIN + 10, y, FONT_SIZE, style)
					end
				end

				y = y - FONT_SIZE
			end
		end
	end



	y = SYSTEM_MSG_BOX_Y_MAX - (FONT_SIZE + 6)

	-- draw system message strings
	for index = 1, table.getn(SYSTEM_MSG_HISTORY), 1 do
		local systemMessage = SYSTEM_MSG_HISTORY[index]
		local systemMessageWidth
		if systemMessage ~= nil then
			systemMessageWidth = (gl_GetTextWidth(systemMessage) * FONT_SIZE )
		else
			systemMessageWidth = 0
		end

		if (MESSAGE_WRAPPING == 1) then
			local bufferIndex, buffer = getMessageParts(systemMessage, systemMessageWidth, SYSTEM_MSG_BOX_W)

			if (bufferIndex > 1) then
				-- our buffer was filled with at least two message parts
				copySystemMessageBuffer(buffer, bufferIndex, index)

				-- we've expanded our system message
				-- history so abort drawing this frame
				break
			end
		else
			-- fix horizontal overflow the easy way
			systemMessage, _ = splitMessage(systemMessage, systemMessageWidth, SYSTEM_MSG_BOX_W)
		end

		-- make sure messages do not get printed below
		-- bottom edge of box in case user increased
		-- fontsize and box already reasonably full
		if (index <= MAX_NUM_SYSTEM_MESSAGES) then
			if ( systemMessageWidth > 0 ) then
				local text = systemMessage
				local style = FONT_RENDER_STYLES[1]
				if ( USECOLORCODES ) then
					local colorcode = convertColor(SYSTEM_TEXT_COLOR)
					text = colorcode..systemMessage
				else
					style = FONT_RENDER_STYLES[1].."n"
				end
				gl_Color(SYSTEM_TEXT_COLOR[1], SYSTEM_TEXT_COLOR[2], SYSTEM_TEXT_COLOR[3], SYSTEM_TEXT_COLOR[4])
				gl_Text(text, SYSTEM_MSG_BOX_X_MIN + 10, y, FONT_SIZE, style)
			end
		end

		y = y - FONT_SIZE
	end
end




function copyPlayerMessageBuffer(buffer, bufferIndex, index, color, fontStyle)
	if (MSGBOX_SCROLLING == 0) then
		-- are there more player message parts than we have room left to display?
		-- (if so then set NUM_PLAYER_MESSAGES to number of excess message parts)
		if (((NUM_PLAYER_MESSAGES - 1) + bufferIndex) > MAX_NUM_PLAYER_MESSAGES) then
			NUM_PLAYER_MESSAGES = bufferIndex
			PLAYER_MSG_HISTORY = {}
			index = 1
		else
			NUM_PLAYER_MESSAGES = (NUM_PLAYER_MESSAGES - 1) + bufferIndex
		end
	else
		-- autoscroll <number of message parts> lines if
		-- bottom of message frame is equal to last message
		if (MESSAGE_FRAME_MAX == NUM_PLAYER_MESSAGES) then
			MESSAGE_FRAME_MIN = MESSAGE_FRAME_MIN + bufferIndex
			MESSAGE_FRAME_MAX = MESSAGE_FRAME_MAX + bufferIndex
		end

		NUM_PLAYER_MESSAGES = (NUM_PLAYER_MESSAGES - 1) + bufferIndex
	end

	for i = 1, table.getn(buffer), 1 do
		-- copy over message parts from temporary buffer
		-- (overwrites original overflowing message)
		PLAYER_MSG_HISTORY[index + i - 1] = {color, fontStyle, buffer[i]}
	end
end

function copySystemMessageBuffer(buffer, bufferIndex, index)
	-- are there more system message parts than we have room left to display?
	if (((NUM_SYSTEM_MESSAGES - 1) + bufferIndex) > MAX_NUM_SYSTEM_MESSAGES) then
		NUM_SYSTEM_MESSAGES = bufferIndex
		SYSTEM_MSG_HISTORY = {}
		index = 1
	else
		NUM_SYSTEM_MESSAGES = (NUM_SYSTEM_MESSAGES - 1) + bufferIndex
	end

	for i = 1, table.getn(buffer), 1 do
		-- copy over message parts from temporary buffer
		SYSTEM_MSG_HISTORY[index + i - 1] = buffer[i]
	end
end


function splitMessage(message, messageWidth, boxWidth)
	if (messageWidth >= boxWidth) then
		local messageLen = string.len(message)
		local overflowFactor = messageWidth / boxWidth
		local cutoffIndex = math_floor(messageLen / overflowFactor)

		local messagePartL = string.sub(message, 1, cutoffIndex - 1)
		local messagePartR = string.sub(message, cutoffIndex)

		return messagePartL, messagePartR
	else
		return message, ""
	end
end


-- break message into parts if it's too wide for
-- player or system box and store them in buffer
function getMessageParts(message, messageWidth, boxWidth)
	local buffer = {}
	local bufferIndex = 1
	local messagePartL = ""
	local messagePartR = ""

	while (messageWidth >= boxWidth) do
		-- continue splitting while parts are too long
		messagePartL, messagePartR = splitMessage(message, messageWidth, boxWidth)

		buffer[bufferIndex] = messagePartL
		bufferIndex = bufferIndex + 1

		message = messagePartR
		messageWidth = (gl_GetTextWidth(message) * FONT_SIZE)
	end

	-- copy last remaining message part
	buffer[bufferIndex] = messagePartR

	return bufferIndex, buffer
end




function buildTable()
	local playerRoster = Spring.GetPlayerRoster(ROSTER_SORT_TYPE)

	for index, playerInfo in ipairs(playerRoster) do
		local playerName = playerInfo[1]
		local playerTeam = playerInfo[3]
		local r, g, b, a = Spring.GetTeamColor(playerTeam)

		PLAYER_COLOR_TABLE[playerName] = {r, g, b, a}
	end
end


-- extract a player name from a text message
-- (note: this can generate false positives if
-- player has name of form "<XYZ>" or "[XYZ]"
-- for certain system messages since strings
-- returned will then be "XYZ>" and "XYZ]"
-- rather than "")
function getPlayerName(playerMessage)
	local i1 = string.find(playerMessage, NAME_PREFIX_PATTERNS[1])
	local i2 = string.find(playerMessage, NAME_POSTFIX_PATTERNS[1])

	if (i1 ~= nil and i2 ~= nil and i1 == 1) then
		-- player messages start with "<" so start index is 2
		return (string.sub(playerMessage, 2, i2 - 1))
	end

	local j1 = string.find(playerMessage, NAME_PREFIX_PATTERNS[2])
	local j2 = string.find(playerMessage, NAME_POSTFIX_PATTERNS[2])

	if (j1 ~= nil and j2 ~= nil and j1 == 1) then
		-- spectator messages start with "[" so start index is 2
		return (string.sub(playerMessage, 2, j2 - 1))
	end

	-- no match found
	return ""
end


-- get a player's team-color
function getPlayerColor(playerName)
	-- this should have O(log n) or O(1) time complexity
	local playerColor = PLAYER_COLOR_TABLE[playerName]

	if (playerColor ~= nil) then
		return playerColor
	else
		-- if playerName was not valid key then getPlayerName()
		-- either found no match at all or false positive one,
		-- or table missing entry for actual player (due to
		-- pathing delays etc.)
		if (string.len(playerName) > 0) then
			-- rebuild table in case this was message from real player (ie.
			-- getPlayerName() found true positive) we didn't know about yet
			buildTable()
		end

		return PLAYER_TEXT_DEFAULT_COLOR
	end
end


-- get a player's font outline-mode string
-- (only used if font outlining is enabled)
function getPlayerFontStyle(playerColor)

	local luminance  = (playerColor[1] * 0.299) + (playerColor[2] * 0.587) + (playerColor[3] * 0.114)

	if (luminance > 0.25) then
		-- black outline
		playerFontStyle = FONT_RENDER_STYLES[2]
	else
		-- white outline
		playerFontStyle = FONT_RENDER_STYLES[3]
	end

	return playerFontStyle
end


function drawBox(left, top, width, height, fillColor, lineColor)
	if (width < 2 or height < 2) then
		return false
	end

	gl_Color(lineColor)
	gl_Rect(left - 1, top + 1, left + width + 1, top - height - 1)

	gl_Color(fillColor)
	gl_Rect(left, top, left + width, top - height)
end
