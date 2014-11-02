function widget:GetInfo()
	return {
		name = "Fix drawmode-stuck",
		desc = "Fixes some key combinations that result in draw-mode being stuck" ,
		author = "Jools",
		date = "Novembris",
		license = "Fishware 1.0",
		layer = 0,
		enabled = true
	}
end

include('keysym.h.lua')
local BACKQUOTE = KEYSYMS.BACKQUOTE
local BACKSLASH = KEYSYMS.BACKSLASH
local PAR = KEYSYMS.WORLD_23 
local RETURN = KEYSYMS.RETURN

function widget:KeyPress(key, mods, isRepeat)
    if key==RETURN and (Spring.GetKeyState(BACKQUOTE) or Spring.GetKeyState(BACKSLASH) or Spring.GetKeyState(PAR)) then
        return true
    end
end