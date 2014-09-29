
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Fire Rate",
    desc      = "Adds a button that sets the fire rate for Vulcans & Buzzsaws",
    author    = "Deadnight Warrior",
    date      = "Nov 19, 2011",
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
local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local SetUnitBuildspeed = Spring.SetUnitBuildSpeed

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CMD_FIRERATE = 33454

local fireRateDefs = {
  arm_vulcan = 0.25,
  core_buzzsaw = 0.5,
}

local FireRateCmdDesc = {
  id      = CMD_FIRERATE,
  type    = CMDTYPE.ICON_MODE,
  name    = 'FireRate',
  cursor  = 'FireRate',
  action  = 'FireRate',
  tooltip = 'Orders: Fire Rate',
  params  = { '3', '25%', '50%', '75%', '100%'}
}
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddFireRateCmdDesc(unitID)
  if (FindUnitCmdDesc(unitID, CMD_FIRERATE)) then
    return  -- already exists
  end
  local insertID = 
    FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or
    123456 -- back of the pack
  FireRateCmdDesc.params[1] = '3'
  Spring.InsertUnitCmdDesc(unitID, insertID + 1, FireRateCmdDesc)
end


local function UpdateButton(unitID, statusStr)
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_FIRERATE)
  if (cmdDescID == nil) then
    return
  end

  local tooltip
  if (statusStr == '0') then
    tooltip = 'Orders: Fire rate at 25%.'
  elseif (statusStr == '1') then
    tooltip = 'Orders: Fire rate at 50%.'
  elseif (statusStr == '2') then
    tooltip = 'Orders: Fire rate at 75%.'
  else
    tooltip = 'Orders: Full fire rate.'
  end

  FireRateCmdDesc.params[1] = statusStr

  Spring.EditUnitCmdDesc(unitID, cmdDescID, { 
    params  = FireRateCmdDesc.params, 
    tooltip = tooltip,
  })
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
  local ud = UnitDefs[unitDefID]
  if (fireRateDefs[ud.name]) then
    AddFireRateCmdDesc(unitID)
    UpdateButton(unitID, '3')
    --RetreatCommand(unitID, unitDefID, { builderInfo[1] }, teamID)
  end
end

function gadget:Initialize()
  gadgetHandler:RegisterCMDID(CMD_FIRERATE)
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local teamID = Spring.GetUnitTeam(unitID)
    local unitDefID = GetUnitDefID(unitID)
    gadget:UnitCreated(unitID, unitDefID, teamID)
  end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)

  if cmdID ~= CMD_FIRERATE then
    return true
  end
  Spring.SetUnitWeaponState(unitID, 0, "reloadTime", fireRateDefs[UnitDefs[unitDefID].name] * (#FireRateCmdDesc.params-1) / (cmdParams[1]+1))
  UpdateButton(unitID, cmdParams[1])  
  return false
end

function gadget:Shutdown()
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local cmdDescID = FindUnitCmdDesc(unitID, CMD_FIRERATE)
    if (cmdDescID) then
      Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
