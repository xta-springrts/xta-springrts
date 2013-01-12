
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Repair Pad",
    desc      = "Tells the plane to go" ..
                "a repair pad",
    author    = "thor",
    date      = "July 12, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Speed-ups

local GetUnitDefID    = Spring.GetUnitDefID
local GetUnitCommands = Spring.GetUnitCommands
local FindUnitCmdDesc = Spring.FindUnitCmdDesc

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CMD_REFUEL = 33457


local airDefs = {

 arm_construction_aircraft = true,
 arm_peeper = true,
 arm_freedom_fighter = true,
 arm_thunder = true,
 arm_atlas = true,
 arm_ornith = true,
 arm_tornado = true,
 arm_adv_construction_aircraft = true,
 arm_brawler = true,
 arm_phoenix = true,
 arm_lancet = true,
 arm_hawk = true,
 arm_albatross = true,
 arm_harpoon = true,
 arm_seahawk = true, 
 arm_construction_seaplane = true,
 core_construction_aircraft = true,
 core_fink = true,
 core_avenger = true,
 core_shadow = true,
 core_valkyrie = true,
 core_voodoo = true,
 core_vulture = true,
 core_adv_construction_aircraft = true,
 core_rapier = true,
 core_titan = true,
 core_hurricane = true,
 core_vamp = true,
 core_typhoon = true,
 core_hunter = true,
 core_silhouette = true,
 core_construction_seaplane = true,
 core_zeppelin = true,

}

local refuelCmdDesc = {
  id      = CMD_REFUEL,
  type    = CMDTYPE.ICON_MODE,
  name    = 'Repair Pad',
  cursor  = 'Refuel',
  action  = 'Refuel',
  tooltip = 'Return Immediately to Repair Pad',
  params  = { 'Refuel'}
}
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddrefuelCmdDesc(unitID)
  if (FindUnitCmdDesc(unitID, CMD_REFUEL)) then
    return  -- already exists
  end
  local insertID = 
    FindUnitCmdDesc(unitID, CMD.CLOAK)      or
    FindUnitCmdDesc(unitID, CMD.ONOFF)      or
    FindUnitCmdDesc(unitID, CMD.TRAJECTORY) or
    FindUnitCmdDesc(unitID, CMD.REPEAT)     or
    FindUnitCmdDesc(unitID, CMD.MOVE_STATE) or
    FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or
    FindUnitCmdDesc(unitID, CMD.AREA_ATTACK) or
    123456 -- back of the pack
  refuelCmdDesc.params[1] = '0'
  Spring.InsertUnitCmdDesc(unitID, insertID + 1, refuelCmdDesc)
end


local function UpdateButton(unitID, statusStr)
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_REFUEL)
  if (cmdDescID == nil) then
    return
  end

  refuelCmdDesc.params[1] = statusStr

  Spring.EditUnitCmdDesc(unitID, cmdDescID, { 
    params  = refuelCmdDesc.params, 
    tooltip = tooltip,
  })
end


local function refuelCommand(unitID, unitDefID, cmdParams, teamID)

  local ud = UnitDefs[unitDefID]
  if (airDefs[ud.name]) then

    --Spring.CallCOBScript(unitID, "Refuel", 0)
    Spring.SetUnitFuel(unitID, 0)

     local status
      status = '0'

  UpdateButton(unitID, status)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
  local ud = UnitDefs[unitDefID]
  if (airDefs[ud.name]) then
    AddrefuelCmdDesc(unitID)
    UpdateButton(unitID, '0')
    --RetreatCommand(unitID, unitDefID, { builderInfo[1] }, teamID)
  end
end


function gadget:Initialize()
  gadgetHandler:RegisterCMDID(CMD_REFUEL)
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local teamID = Spring.GetUnitTeam(unitID)
    local unitDefID = GetUnitDefID(unitID)
    gadget:UnitCreated(unitID, unitDefID, teamID)
  end
end




function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
  local returnvalue
  if cmdID ~= CMD_REFUEL then
    return true
  end
  refuelCommand(unitID, unitDefID, cmdParams, teamID)  
  return false
end

function gadget:Shutdown()
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local cmdDescID = FindUnitCmdDesc(unitID, CMD_REFUEL)
    if (cmdDescID) then
      Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
