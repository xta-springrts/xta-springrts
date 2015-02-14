function widget:GetInfo()
	return {
		name = "Customkeys",
		desc = "Binds alt/shift+enter for ally/spec chat, alt+backspace for fullscreen toggle" ,
		author = "",
		date = "",
		license = "Anyone who uses this widget has to email me a horse",
		layer = 0,
		enabled = false
	}
end

local captureKeys 	= false
local setDraw		= false
local setRotate		= false
local Echo			= Spring.Echo

local binds={
	"bind      Alt+backspace  fullscreen",
	"bind          Alt+enter  chatally",
	"bind          Alt+enter  chatswitchally",
	"bind         Ctrl+enter  chatall",
	"bind         Ctrl+enter  chatswitchall",
	"bind        Shift+enter  chatspec",
	"bind        Shift+enter  chatswitchspec",
	"bind 				   o  buildfacing inc",
	--"bind          Any+enter  chat", --default, bound by engine
	--"bind          Any+enter  edit_return", --default, bound by engine
}

local customBinds = {}

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

local unbinds={
	"bind Alt+enter fullscreen",
}

local function updateBinds()
	Echo("Updating binds:")
	for k,v in pairs(customBinds) do
		Echo("Key:" .. k .. " -> " .. v)
		Spring.SendCommands(v)
	end
end

local function SetKeys()
	captureKeys = true
	Echo("Key capture is now active, press ESC to exit")
	Echo("Select option: 1) Set draw key 2) Set rotate building key")
end

function widget:Initialize()
	for k,v in ipairs(unbinds) do
		Spring.SendCommands("un"..v)
	end
	for k,v in ipairs(binds) do
		Spring.SendCommands(v)
	end
	
	for k,v in pairs(customBinds) do
		Spring.SendCommands(v)
	end
end

function widget:Shutdown()
	for k,v in ipairs(binds) do
		Spring.SendCommands("un"..v)
	end
	
	for k,v in pairs(customBinds) do
		Spring.SendCommands("un"..v)
	end
	
	for k,v in ipairs(unbinds) do
		Spring.SendCommands(v)
	end
end

function widget:KeyPress(key, mods, isRepeat)

	if captureKeys and not isRepeat then
		if key == 0x01B then -- escape
			captureKeys = false
			Echo("Key capture is now off")
			setDraw = false
			setRotate = false
			updateBinds()
			return true
		elseif not setDraw and not setRotate then
			if key == 0x031 then -- 1
				setDraw = true
				Echo("Press key to use as the 'Draw' key (0 to clear previous or ESC to cancel):")
				return true
			elseif key == 0x032 then -- 2
				setRotate = true
				Echo("Press key to use as the 'Rotate building' key (0 to clear previous or ESC to cancel):")
				return true
			else 
				Echo("Select option: 1) Set draw key 2) Set rotate building key (or ESC to exit)")
			end
		elseif setDraw then
			local ascii = ASCIIvalues[key]
			if key and key > 0 and ascii then
				if key == 0x030 then -- 0
					Echo("Cleared the draw key information from this widget")
					customBinds["draw"] = nil
					Echo("")
					setDraw = false
					Echo("Select what key to set: 1) Draw key 2) Rotate building key (or ESC to exit)")
					return true
				else
					--Echo("Key pressed was:",key,ascii[1],ascii[2])
					Echo("  --> set key " .. ascii[2] .. " as the drawing key")
					customBinds["draw"] = "bind " .. string.char(key) .. " drawinmap"
					Echo("")
					setDraw = false
					Echo("Select what key to set: 1) Draw key 2) Rotate building key (or ESC to exit)")
					return true
				end
			else
				Echo("Spring does not understand this key, select another one (or edit uikeys.txt manually)")
				Echo("Press key to use as the 'Draw' key (or ESC to cancel):")
				return true
			end
		elseif setRotate then
			local ascii = ASCIIvalues[key]
			if key and key > 0 and ascii then
				if key == 0x030 then -- 0
					Echo("Cleared the rotate buildings  key information from this widget")
					customBinds["rotate"] = nil
					Echo("")
					setRotate = false
					Echo("Select what key to set: 1) Draw key 2) Rotate building key (or ESC to exit)")
					return true
				else
					--Echo("Key pressed was:",key,ascii[1],ascii[2])
					Echo("  --> set key " .. ascii[2] .. " as the rotate buildings key")
					customBinds["rotate"] = "bind " .. string.char(key) .. " buildfacing inc"
					Echo("")
					setRotate = false
					Echo("Select what key to set: 1) Draw key 2) Rotate building key (or ESC to exit)")
					return true
				end
			else
				Echo("Spring does not understand this key, select another one (or edit uikeys.txt manually)")
				Echo("Press key to use as the 'Rotate building' key (or ESC to cancel):")
				return true
			end
		end
	end
	
	return false
end

function widget:GetConfigData(data)      -- save
	return {
			draw         		= customBinds.draw,
			rotate         		= customBinds.rotate,
		}
	end

function widget:SetConfigData(data)      -- load
	if not customBinds then customBinds = {} end
	
	customBinds.draw       		= data.draw
	customBinds.rotate			= data.rotate
end

function widget:TextCommand(command)
	if command == 'setkeys' or command == 'setkeybinds' then
		SetKeys()
	end
end