function widget:GetInfo()
   return {
   version   = "1",
   name      = "Hide commands",
   desc      = "Hides some commands",
   author    = "Regret",
   date      = "February 19, 2010", --last change February 19, 2010
   license   = "Public Domain",
   layer     = 0,
   enabled   = false, --enabled by default
   handler   = true, --access to handler
   }
end
local CMD_ATTACK					= CMD.ATTACK
local CMD_GUARD						= CMD.GUARD
local CMD_AREA_GUARD				= 14001
local CMD_PATROL					= CMD.PATROL
local CMD_FIGHT						= CMD.FIGHT
local CMD_DGUN						= CMD.DGUN
local CMD_REPAIR					= CMD.REPAIR
local CMD_WAIT						= CMD.WAIT -- "Wait" ID = "5"
local CMD_STOP						= CMD.STOP -- "Stop" ID = "0"
local CMD_MOVE						= CMD.MOVE -- "Move" ID = "10"
local CMD_MOVESTATE					= CMD.MOVE_STATE -- "Move state" ID = "50"
local CMD_FIRESTATE					= CMD.FIRE_STATE -- "Fire state" ID = "45"
local CMD_AREA_ATTACK_AIR			= 21 -- "Area Attack" ID = "39954", this is the one for aircraft, provided by engine, xta has a gadget for area attack too
local CMD_SELFD						= CMD.SELFD -- "SelfD" ID = "65"

-- Add/Remove commands here that you want removed from the control panel buttons. Commands are really numbers, but it is better to not
-- hardcode them unless neccessary. Commands still work with the shortcut even if they are hidden.
local HiddenCommands = {
   [CMD_DGUN] = true, --dgun
   [CMD_STOP] = true, --stop
   [CMD_MOVE] = true, --move
   [CMD_PATROL] = true, --patrol
   [CMD_FIGHT] = true, --fight
   [CMD_GUARD] = true, --guard
   [CMD_ATTACK] = true, --attack
   [CMD_WAIT] = true, --wait
   [CMD_REPAIR] = true, --repair
   [CMD_SELFD] = true, --selfd
}

function widget:CommandsChanged()
    local cmds = widgetHandler.commands
    local n = #(widgetHandler.commands)
    for i=1,n do
      if (HiddenCommands[cmds[i].id]) then
         cmds[i].hidden = true
      end
    end
end

--[[
"Stop" ID = "0"
"Wait" ID = "5"
"TimeWait" ID = "6"
"DeathWait" ID = "7"
"SquadWait" ID = "8"
"GatherWait" ID = "9"
"SelfD" ID = "65"
"Fire state" ID = "45"
"Repeat" ID = "115"
"Cloak state" ID = "95"
"Move state" ID = "50"
"Load units" ID = "76"
"Move" ID = "10"
"Patrol" ID = "15"
"Fight" ID = "16"
"Guard" ID = "25"
"Area guard" ID = "14001"
"Repair level" ID = "135"
"Land mode" ID = "145"
"Area attack" ID = "21"
"Attack" ID = "20"
"Repair" ID = "40"
"Reclaim" ID = "90"
"Restore" ID = "110"
"Load units" ID = "75"
"Unload units" ID = "80"
"Active state" ID = "85"
"apLandAt" ID = "34569"
"apAirRepair" ID = "34570"
"Automatic Mex Upgrade" ID = "31243"
"Upgrade Mex" ID = "31244"
"Area Attack" ID = "39954"
"Trajectory" ID = "120"
"Resurrect" ID = "125"
"0/0" ID = "100"
"Stagger" ID = "34566"
"DGun" ID = "105"
"ntPassiveMode" ID = "34571"
"Capture" ID = "130"
]]--
