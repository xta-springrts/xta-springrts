function widget:GetInfo()
	return {
		name = "Desync warning",
		desc = "Displays warning if client is not in sync",
		author = "Jools",
		date = "Mar, 2015",
		license = "GPLv2",
		version = "1.0",
		layer = 1,
		enabled = true
	}
end


local myFont	 					= gl.LoadFont("FreeSansBold.otf",16, 1.9, 40)
local sizeX, sizeY					= 400, 165
local posx, posy					= 600, 400
local BARWIDTH						= 20
local MARGIN						= 10
local BARLENGTH						= 135
local vsx, vsy 						= gl.GetViewSizes()
local ping							= 0
local myPlayerID					= Spring.GetMyPlayerID()
local pingLabel						= "N/A"
local MAXLAG 						= 1800000 -- 30 minutes
local TITLE							= ""
local Echo							= Spring.Echo
local desync 						= false
local OrangeStr  					= "\255\255\190\128"
local RedStr    					= "\255\255\092\092"
local GreyStr    					= "\255\210\210\210"
local WhiteStr   					= "\255\255\255\255"
local GreenStr   					= "\255\092\255\092"
local DesyncTable					= {}
local desyncs						= {}

function widget:Initialize()
    localTeamID = Spring.GetLocalTeamID()   
end

local function round(num, idp)
	return string.format("%." .. (idp or 0) .. "f", num)
end
	
local function DrawBar()
	
	--back panel
	gl.Color(0, 0, 0, 0.2)
	gl.Rect(posx,posy,posx+sizeX,posy+sizeY)
		
	local x0 = posx + MARGIN
	local y0 = posy + sizeY - 20
	local x1 = posx + sizeX - MARGIN
	local y1 = posy
	
	
	-- text
	myFont:Begin()
	myFont:SetTextColor({1, 0.2, 0.2, 1})
	myFont:Print("Game is out of sync!",x0,y0,16,'bs')
	if desyncs and (desyncs.err or desyncs.warn) then 
		myFont:Print(RedStr .. "Err/" ..  OrangeStr .. "Warn: " .. RedStr .. (desyncs.err or "-") .."/" .. OrangeStr .. (desyncs.warn or "-"),x1,y0,10,'rbs')
	end
	myFont:Print(GreyStr .. "Please help us fix this by giving us your " .. GreenStr .. "replay" ..  GreyStr .. " file and your",x0,y1+16,11,'bs')
	myFont:Print(GreenStr .. "infolog.txt" .. GreyStr .. " file in spring data folder" ,x0,y1+2,11,'bs')
	
	
	
	if DesyncTable and #DesyncTable > 0 then
	
		for i, data in ipairs (DesyncTable) do
			local player = data[1]
			local stype = data[2]
			local frame = data[3]
			--local priority = data[4]
			myFont:SetTextColor({0.5, 0.5, 0.5, 1})
			myFont:Print((stype == "error" and (RedStr .. "Sync error") or (OrangeStr .. "Sync warning")) .. GreyStr .. " for player " .. WhiteStr .. player .. GreyStr .. " in frame " .. frame,x0,y0-5-i*16,10,'bs')
		end
	end
	
	myFont:End()
end

function widget:GameFrame(frame)
	if frame%30 == 0 then
		local buffer = Spring.GetConsoleBuffer(2)
		for _, line in pairs (buffer) do
			if line.priority == 35 and line.text:find("Sync error for") then
				if not desyncs.err then desyncs.err = 0 end
				desyncs.err = desyncs.err + 1
				--local priority = line.priority
				desync = true
				local _,ind1 = line.text:find("Sync error for")
				local ind2 = line.text:find("in frame")
				local player = ind1 and ind2 and line.text:sub(ind1+2,ind2-2) or "N/A"
				--Echo(OrangeStr .. "Game is not in sync: player " .. (player or "N/A") .. " is out of sync")
				DesyncTable[#DesyncTable+1] = {player,"error",frame}
				if #DesyncTable > 6 then
					table.remove(DesyncTable,1)
				end
			elseif line.priority == 50 and line.text:find("DESYNC_WARNING") then
				if not desyncs.warn then desyncs.warn = 0 end
				desyncs.warn = desyncs.warn + 1
				--local priority = line.priority
				desync = true
				local _,ind1 = line.text:find("from player")
				local ind2 = line.text:find("does not match")
				local player = ind1 and ind2 and line.text:sub(ind1+5,ind2-3) or "N/A"
				--Echo(OrangeStr .. "Out of sync warning for player " .. (player or "N/A"))
				DesyncTable[#DesyncTable+1] = {player,"warning",frame}
				if #DesyncTable > 6 then
					table.remove(DesyncTable,1)
				end
			end
		end
	end
end


function widget:Update()
	if Spring.GetGameFrame() == 0 then
		local console = Spring.GetConsoleBuffer(2)[1]
		if console.text:find("DESYNC WARNING") then
			local _,ind1 = console.text:find("for player")
			local ind2 = console.text:find("does not match")
			local player = ind1 and ind2 and console.text:sub(ind1+5,ind2-3) or "N/A"
			Echo(OrangeStr .. "Out of sync warning for player " .. (player or "N/A"))
		end
	end
end

function widget:DrawScreen()
	if (not Spring.IsGUIHidden()) and desync then
		DrawBar()
	end
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
						  and y >= BLcornerY
						  and y <= TRcornerY
end

function widget:MousePress(mx, my, mButton)
	if desync then
		if IsOnButton(mx,my,posx,posy,posx+sizeX,posy+sizeY) then
			-- Dragging
			return true
		end	
	end
end
					
function widget:MouseMove(mx, my, dx, dy, mButton)
	if desync then
		-- Dragging
		posx = math.max(0, math.min(posx+dx, vsx-sizeX))	--prevent moving off screen
		posy = math.max(0, math.min(posy+dy, vsy-sizeY))
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