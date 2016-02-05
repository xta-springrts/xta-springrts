
if addon.InGetInfo then
	return {
		name    = "Main",
		desc    = "displays a simple loadbar",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

local lastLoadMessage = ""
local protips = include("luaintro/addons/configs/protips_defs.lua")
local lineChars = 90

local tip = protips[ math.random(#protips)]
local words = {}
for word in tip:gmatch("%S+") do table.insert(words, word) end

local lines = {}
local i = 1
for _,word in pairs (words) do
	if not lines[i] then
		lines[i] = ""
	end
	
	if #(lines[i]) + #word < lineChars then
		if lines[i] and #(lines[i]) > 0 then
			lines[i] = lines[i] .. " " .. word
		else
			lines[i] = word
		end
	else
		i = i + 1
		lines[i] = word
	end
	
end

Spring.Echo("Lines, words:",i,#words)

function addon.LoadProgress(message, replaceLastLine)
	lastLoadMessage = message
end

------------------------------------------

local font = gl.LoadFont("FreeSansBold.otf", 50, 20, 1.95)
local font2 = gl.LoadFont("luaui/fonts/atlantabook.ttf", 50, 4,2)


function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()

	local vsx, vsy = gl.GetViewSizes()
	local xDiv, yDiv, texy, ar = SG.GetDiv()
	
	-- draw progressbar
	local hbw = 3.5/vsx
	local vbw = 3.5/vsy
	local hsw = 0.2
	local vsw = 0.2
	
	gl.PushMatrix()
	gl.Scale(.4,.4,1)
	gl.Translate(-0.1,0,0)
	
	gl.BeginEnd(GL.QUADS, function()
		--shadow topleft
		gl.Color(0,0,0,0)
			gl.Vertex(0.2-hsw, 0.2    )
			gl.Vertex(0.2-hsw, 0.2+vsw)
			gl.Vertex(0.2    , 0.2+vsw)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.2    , 0.2)

		--shadow top
		gl.Color(0,0,0,0)
			gl.Vertex(0.2, 0.2+vsw)
			gl.Vertex(0.8, 0.2+vsw)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.8, 0.2)
			gl.Vertex(0.2, 0.2)

		--shadow topright
		gl.Color(0,0,0,0)
			gl.Vertex(0.8    , 0.2+vsw)
			gl.Vertex(0.8+hsw, 0.2+vsw)
			gl.Vertex(0.8+hsw, 0.2)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.8    , 0.2)

		--shadow right
		gl.Color(0,0,0,0)
			gl.Vertex(0.8+hsw, 0.2)
			gl.Vertex(0.8+hsw, 0.15)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.8    , 0.15)
			gl.Vertex(0.8    , 0.2)

		--shadow btmright
		gl.Color(0,0,0,0)
			gl.Vertex(0.8    , 0.15-vsw)
			gl.Vertex(0.8+hsw, 0.15-vsw)
			gl.Vertex(0.8+hsw, 0.15)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.8    , 0.15)

		--shadow btm
		gl.Color(0,0,0,0)
			gl.Vertex(0.2, 0.15-vsw)
			gl.Vertex(0.8, 0.15-vsw)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.8, 0.15)
			gl.Vertex(0.2, 0.15)

		--shadow btmleft
		gl.Color(0,0,0,0)
			gl.Vertex(0.2-hsw, 0.15    )
			gl.Vertex(0.2-hsw, 0.15-vsw)
			gl.Vertex(0.2    , 0.15-vsw)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.2    , 0.15)

		--shadow left
		gl.Color(0,0,0,0)
			gl.Vertex(0.2-hsw, 0.2)
			gl.Vertex(0.2-hsw, 0.15)
		gl.Color(0,0,0,0.5)
			gl.Vertex(0.2    , 0.15)
			gl.Vertex(0.2    , 0.2)

		--bar bg
		gl.Color(0,0,0,0.85)
			gl.Vertex(0.2, 0.2)
			gl.Vertex(0.8, 0.2)
			gl.Vertex(0.8, 0.15)
			gl.Vertex(0.2, 0.15)

		--progress
		gl.Color(1,1,1,0.7)
			gl.Vertex(0.2, 0.2)
			gl.Vertex(0.2 + math.max(0, loadProgress-0.01) * 0.6, 0.2)
			gl.Vertex(0.2 + math.max(0, loadProgress-0.01) * 0.6, 0.15)
			gl.Vertex(0.2, 0.15)
		gl.Color(1,1,1,0.7)
			gl.Vertex(0.2 + math.max(0, loadProgress-0.01) * 0.6, 0.2)
			gl.Vertex(0.2 + math.max(0, loadProgress-0.01) * 0.6, 0.15)
		gl.Color(1,1,1,0)
			gl.Vertex(0.2 + math.min(1, math.max(0, loadProgress+0.01)) * 0.6, 0.15)
			gl.Vertex(0.2 + math.min(1, math.max(0, loadProgress+0.01)) * 0.6, 0.2)

		--bar borders
		gl.Color(1,1,1,1)
			gl.Vertex(0.2, 0.2)
			gl.Vertex(0.8, 0.2)
			gl.Vertex(0.8, 0.2-vbw)
			gl.Vertex(0.2, 0.2-vbw)
		gl.Color(1,1,1,1)
			gl.Vertex(0.2, 0.15)
			gl.Vertex(0.8, 0.15)
			gl.Vertex(0.8, 0.15+vbw)
			gl.Vertex(0.2, 0.15+vbw)
		gl.Color(1,1,1,1)
			gl.Vertex(0.2, 0.2)
			gl.Vertex(0.2, 0.15)
			gl.Vertex(0.2+hbw, 0.15)
			gl.Vertex(0.2+hbw, 0.2)
		gl.Color(1,1,1,1)
			gl.Vertex(0.8, 0.2)
			gl.Vertex(0.8, 0.15)
			gl.Vertex(0.8-hbw, 0.15)
			gl.Vertex(0.8-hbw, 0.2)
	end)

--[[
	gl.Color(0,0,0,1)
	gl.Rect(0.2,0.15,0.8,0.2)
	gl.Color(1,1,1,1)
	gl.Rect(0.2,0.15,0.2 + math.max(0, loadProgress) * 0.6,0.2)
	gl.LineWidth(5)
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
	gl.Rect(0.2,0.15,0.8,0.2)
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	gl.LineWidth(1)
	gl.Color(1,1,1,1)
--]]

	-- progressbar text
	gl.PushMatrix()
	gl.Scale(1/vsx,1/vsy,1)
		local barTextSize = vsy * (0.05 - 0.015)
		local tipTextSize = vsy * (0.05 - 0.005)
		
		local posy = 0.5 * (vsy-vsx/ar)
		
		local y0 = vsy * 0.222 + posy -- vsy-texy > 300 and vsy-texy or vsy * 0.25
		local y1 = y0 + vsy * 0.2
		local dy = 4
		
		--Spring.Echo("XY:",yDiv,vsy * 0.2,yDiv > 0.1,y0,y1,yDiv*vsy,vsx/ar,posy)
		
		--font:Print(lastLoadMessage, vsx * 0.5, vsy * 0.3, 50, "sc")
		--font:Print(Game.gameName, vsx * 0.5, vsy * 0.95, vsy * 0.07, "sca")
		font:Print(lastLoadMessage, vsx * 0.2, vsy * 0.14, barTextSize, "sa")
		if loadProgress>0 then
			font:Print(("%.0f%%"):format(loadProgress * 100), vsx * 0.5, vsy * 0.165, barTextSize, "oc")
		else
			font:Print("Loading...", vsx * 0.5, vsy * 0.165, barTextSize, "oc")
		end
		--Spring.Echo("XY:",vsx,vsy)
		--protip
		gl.Color(0.0,0.0,0.0,0.6)
		
		gl.Rect(0,y0+dy,4*vsx,y1-dy)
		
		gl.Color(0,0,0,0.1)
		gl.Rect(0,y1-dy,4*vsx,y1)
		gl.Rect(0,y0,4*vsx,y0+dy)
		
		gl.Color(1,1,1,0.5)
		gl.Rect(0,y1+1,4*vsx,y1+dy)
		gl.Rect(0,y0-dy,4*vsx,y0)
		
		gl.Color(1,1,1,1)
		
		font2:Begin()
		font2:SetTextColor({1, 1, 1, 0.9 })
		Spring.Echo("lines:",#lines)
		local y2 = #lines == 1 and y1 - vsy * 0.05 or y1 - vsy * 0.02
		local ls = vsy * 0.06
		for line, text in pairs(lines) do
			font2:Print(text,vsx * 0.5,y2 -line*ls,tipTextSize,'vo')
		end
		font2:End()
		
	gl.PopMatrix()
	
	gl.PopMatrix()
end


function addon.MousePress(...)
	--Spring.Echo(...)
end


function addon.Shutdown()
	gl.DeleteFont(font)
end
