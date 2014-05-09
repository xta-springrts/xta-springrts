include("keysym.h.lua")
local versionNumber = "1.32"

function widget:GetInfo()
	return {
		name      = "Pause Screen - XTA",
		desc      = "[v" .. string.format("%s", versionNumber ) .. "] Displays pause screen when game is paused.",
		author    = "very_bad_soldier, Jools",
		date      = "Dec, 2013",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

-- Update: Make sure sound to fade in/out is played only once. Change fade-in sound, modify fade-out sound to 
-- include a little silence before to make it sound cleaner. Update minimum transparency to 0, add music.
-- Add text command option to disable/enable music


local spGetGameSeconds      = Spring.GetGameSeconds
local spGetGameFrame		= Spring.GetGameFrame
local spGetMouseState       = Spring.GetMouseState
local spEcho                = Spring.Echo

local spPlaySoundFile		= Spring.PlaySoundFile

local spGetGameSpeed 		= Spring.GetGameSpeed

local max					= math.max

local glColor               = gl.Color
local glTexture             = gl.Texture
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glText                = gl.Text
local glBeginEnd			= gl.BeginEnd
local glTexRect 			= gl.TexRect
local glLoadFont			= gl.LoadFont
local glDeleteFont			= gl.DeleteFont
local glRect				= gl.Rect
local glLineWidth           = gl.LineWidth
local glDepthTest           = gl.DepthTest

local osClock				= os.clock
----------------------------------------------------------------------------------
-- CONFIGURATION
local debug = false	
local boxWidth = 300
local boxHeight = 60
local slideTime = 0.4
local fadeTime = 1
local wndBorderSize = 4
local imgWidth = 160 --drawing size of the image (independent from the real image pixel size)
local imgTexCoordX = 0.625  --image texture coordinate X -- textures image's dimension is a power of 2 (i use 0.625 cause my image has a width of 256, but region to use is only 160 pixel -> 160 / 256 = 0.625 )
local imgTexCoordY = 0.625	--image texture coordinate Y -- enter values other than 1.0 to use just a region of the texture image
local fontSizeHeadline = 36
local fontSizeAddon = 24
local windowIconPath = "LuaUI/Images/SpringIconmkII.png"
local fontPath = "LuaUI/Fonts/MicrogrammaDBold.ttf"
local windowClosePath = "LuaUI/Images/closex_32.png"
local imgCloseWidth = 32
local minTransparency = 0
--Color config in drawPause function
	
----------------
local screenx, screeny
local myFont
local clickTimestamp = 0
local pauseTimestamp = 0 --start or end of pause
local lastPause = false
local screenCenterX = nil
local screenCenterY = nil
local wndX1 = nil
local wndY1 = nil
local wndX2 = nil
local wndY2 = nil
local textX = nil
local textY = nil
local lineOffset = nil
local yCenter = nil
local xCut = nil
local mouseOverClose = false
local forceHideWindow = false
local musicOn = false
local musicDelay = 3 -- seconds
local soundPlayed = false
local disableMusic = false 


local sound_1  = LUAUI_DIRNAME .. 'Sounds/jingle.wav'
local sound_4  = LUAUI_DIRNAME .. 'Sounds/BEEP5.wav'
local music		= LUAUI_DIRNAME .. 'Sounds/streetcollection.ogg'
-- music by David Matthews, available for free on WWW.DAVIDMATHEWS.CO.UK.
-- The original soundtrack is actually called street collection.

local function ResetGl() 
	glColor( { 1.0, 1.0, 1.0, 1.0 } )
	glLineWidth( 1.0 )
	glDepthTest(false)
	glTexture(false)
end

local function isOverWindow(x, y)
	if ( ( x > screenCenterX - boxWidth) and ( y < screenCenterY + boxHeight ) and 
		( x < screenCenterX + boxWidth ) and ( y > screenCenterY - boxHeight ) ) then	
		return true
	end
	return false
 end

local function updateWindowCoords()
	screenx, screeny = widgetHandler:GetViewSizes()
	
	screenCenterX = screenx * 0.5
	screenCenterY = screeny * 0.5
	wndX1 = screenCenterX - boxWidth
	wndY1 = screenCenterY + boxHeight
	wndX2 = screenCenterX + boxWidth
	wndY2 = screenCenterY - boxHeight

	textX = wndX1 + ( wndX2 - wndX1 ) * 0.36
	textY = wndY2 + ( wndY1 - wndY2 ) * 0.53
	lineOffset = ( wndY1 - wndY2 ) * 0.3
	
	yCenter = wndY2 + ( wndY1 - wndY2 ) * 0.5
	xCut = wndX1 + ( wndX2 - wndX1 ) * 0.19
end

local function drawPause()
	local _, _, paused = spGetGameSpeed()
	local now = osClock()
	local diffPauseTime = ( now - pauseTimestamp)

	local text =  { 1.0, 1.0, 1.0, 1.0 }
	local text2 =  { 0.9, 0.9, 0.9, 1.0 }
	local outline =  { 0.4, 0.4, 0.4, 1.0 }	
	local colorWnd = { 0.0, 0.0, 0.0, 0.6 }
	local colorWnd2 = { 0.5, 0.5, 0.5, 0.6 }
	local iconColor = { 1.0, 1.0, 1.0, 1.0 }
	local mouseOverColor = { 1.0, 1.0, 0.0, 1.0 }

	--adjust transparency when clicked
	if ( clickTimestamp ~= nil or forceHideWindow ) then
		local factor = 0.0
		if ( clickTimestamp ) then		
			factor = ( 1.0 - ( now - clickTimestamp ) / fadeTime )
		end
		factor = max( factor, minTransparency )
		colorWnd[4] = colorWnd[4] * factor
		text[4] = max(text[4] * factor, 0.30)
		text2[4] = text2[4] * factor
		outline[4] = outline[4] * factor
		iconColor[4] = iconColor[4] * factor
		mouseOverColor[4] = mouseOverColor[4] * factor			
	end
	local imgWidthHalf = imgWidth * 0.5
	
	--draw window
	glPushMatrix()
	
	if ( diffPauseTime <= slideTime ) then
		local group1XOffset = 0
		--we are sliding
		if ( paused ) then
			if not soundPlayed then
				
				spPlaySoundFile(sound_1, 1)
				soundPlayed = true
			end
			--sliding in
			group1XOffset = ( screenx - wndX1 ) * ( 1.0 - ( diffPauseTime / slideTime ) )
		else
			if not soundPlayed then
				
				spPlaySoundFile(sound_4, 1)
				soundPlayed = true
			end
			--sliding out
			group1XOffset = ( screenx - wndX1 ) * ( ( diffPauseTime / slideTime ) )
		end
		glTranslate( group1XOffset, 0, 0)
	else
		soundPlayed = false
	end
	
	glColor( colorWnd )
	glRect( wndX1, wndY1, wndX2, wndY2 )
	glColor( colorWnd )
	glRect( wndX1 - wndBorderSize, wndY1 + wndBorderSize, wndX2 + wndBorderSize, wndY2 - wndBorderSize)
	
	--draw close icon
	glColor(  iconColor )
	if ( mouseOverClose and clickTimestamp == nil and forceHideWindow == false ) then
		glColor( mouseOverColor )
	end
	
	glTexture( ":n:" .. windowClosePath )
	glTexRect( wndX2 - imgCloseWidth - wndBorderSize, wndY1 - imgCloseWidth - wndBorderSize, wndX2 - wndBorderSize, wndY1 - wndBorderSize, 0.0, 0.0, 1.0, 1.0 )
	
	--draw text
	myFont:Begin()
	myFont:SetOutlineColor( outline )

	myFont:SetTextColor( text )
	myFont:Print( "GAME PAUSED", textX, textY, fontSizeHeadline, "O" )
		
	myFont:SetTextColor( text2 )
	myFont:Print( "Press 'Pause' to continue.", textX, textY - lineOffset, fontSizeAddon, "O" )
	
	myFont:End()
	
	glPopMatrix()
	
	--draw logo
	glColor(  iconColor )
	glTexture( ":n:" .. windowIconPath )
	glPushMatrix()
	
	if ( diffPauseTime <= slideTime ) then
		--we are sliding
		if ( paused ) then
			if not soundPlayed then
				
				spPlaySoundFile(sound_1, 1)
				soundPlayed = true
			end
			--sliding in
			glTranslate( 0, ( ( yCenter + imgWidthHalf ) * ( 1.0 - ( diffPauseTime / slideTime ) ) ), 0)
		else
			if not soundPlayed then
				
				spPlaySoundFile(sound_4, 1)
				soundPlayed = true
			end
			--sliding out
			glTranslate( 0, ( yCenter + imgWidthHalf ) * ( diffPauseTime / slideTime ), 0)
		end
	else
		soundPlayed = false
	end
	
	glTexRect( xCut - imgWidthHalf, yCenter + imgWidthHalf, xCut + imgWidthHalf, yCenter - imgWidthHalf, 0.0, 0.0, imgTexCoordX, imgTexCoordY )
	glPopMatrix()
	
	glTexture(false)
end
 
 function widget:Initialize()
	myFont = glLoadFont( fontPath, fontSizeHeadline )
	updateWindowCoords()
	
end

function widget:Shutdown()
	Spring.StopSoundStream()
	glDeleteFont( myFont )
end

 function widget:TextCommand(command)
	if command == 'musicoff' or command == 'disablemusic' then
		disableMusic = true
	elseif command == 'musicon' or command == 'enablemusic'then
		disableMusic = false
	end
	WG.disablePauseMusic = disableMusic
 end
 
function widget:MousePress(x, y, button)
	local _, _, paused = spGetGameSpeed()
	if not paused then return false end
	
	if ( button == 2) and isOverWindow(x, y) then
		Spring.StopSoundStream()
		return true
	end
	
	if ( not clickTimestamp and not forceHideWindow ) then
		if ( isOverWindow(x, y)) then	
			--do not update clickTimestamp any more after right mouse button click
			if ( not forceHideWindow ) then
				clickTimestamp = osClock()
			end
			--hide window for the rest of the game if it was a right mouse button
			if ( button == 3 ) then
				forceHideWindow = true
				Spring.StopSoundStream()
			end
		
			return true
		end
	elseif not clickTimestamp then
		if ( isOverWindow(x, y)) then
			Spring.StopSoundStream()
		end
	end
  
	return false
end

function widget:IsAbove(x,y)
	local _, _, paused = spGetGameSpeed()
	if ( paused and not forceHideWindow and not clickTimestamp and isOverWindow( x, y ) ) then
		return true
	end
	return false
end

function widget:Update()
	local x,y = spGetMouseState()
	if ( isOverWindow(x, y) ) then	
		mouseOverClose = true
	else
		mouseOverClose = false
	end
end

function widget:GetTooltip(x, y)
	if ( ( clickTimestamp == nil and forceHideWindow == false ) and isOverWindow(x, y) ) then
		return "Click left mouse button to hide pause window.\nClick middle button to stop music.\nClick right mouse button to hide pause window for the rest of the game."
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
  updateWindowCoords()
 end

function widget:DrawScreen()
	if spGetGameFrame() < 15 then return end
	local now = osClock()
	local _, _, paused = spGetGameSpeed()
	local diffPauseTime = ( now - pauseTimestamp)
	
	if ( ( not paused and lastPause ) or ( paused and not lastPause ) ) then
		--pause switch
		pauseTimestamp = osClock()
		if ( diffPauseTime <= slideTime ) then
			pauseTimestamp = pauseTimestamp - ( slideTime - ( diffPauseTime / slideTime ) * slideTime )
		end
	end
	
	if ( paused and not lastPause ) then
		--new pause
		soundPlayed = false
		clickTimestamp = nil
	end

	lastPause = paused
		
	if ( paused or ( ( now - pauseTimestamp) <= slideTime ) ) then
		drawPause()
		if paused and (not disableMusic) then
			if now - pauseTimestamp > musicDelay then
				if (not musicOn) and (not forceHideWindow) then
					Spring.PlaySoundStream(music, 0.3)
					musicOn = true
				end
			end
		else
			if musicOn then
				Spring.StopSoundStream()
				musicOn = false
			end
		end
	end
	
	ResetGl()
end 

function printDebug( value )
	if ( debug ) then
		if ( type( value ) == "boolean" ) then
			if ( value == true ) then spEcho( "true" )
				else spEcho("false") end
		elseif ( type(value ) == "table" ) then
			spEcho("Dumping table:")
			for key,val in pairs(value) do 
				spEcho(key,val) 
			end
		else
			spEcho( value )
		end
	end
end
	
function widget:GetConfigData() -- Save
	return {
		disablemusic = disableMusic
		}
end

function widget:SetConfigData(data) -- Load
	disableMusic = data.disablemusic or false
	WG.disablePauseMusic = disableMusic
end
