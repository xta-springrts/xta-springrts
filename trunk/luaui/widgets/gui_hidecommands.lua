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

local HiddenCommands = {
   [105] = true, --dgun
   [0] = true, --stop
   [10] = true, --move
   [15] = true, --patrol
   [16] = true, --fight
   [25] = true, --guard
   [20] = true, --attack
   [5] = true, --wait
   [40] = true, --repair
   [65] = true, --selfd
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
