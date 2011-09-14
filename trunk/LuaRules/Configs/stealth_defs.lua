--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local stealthDefs = {
  core_cloakable_fusion_power_plant = {
    draw   = true,
    init   = false,
    energy = 550,
    delay  = 30,
  },
  arm_cloakable_fusion_reactor = {
    draw   = true,
    init   = false,
    energy = 500,
    delay  = 30,
  },
  arm_infiltrator = {
    draw   = true,
    init   = false,
    energy = 1000,
    delay  = 30,
  },
  core_parasite = {
    draw   = true,
    init   = false,
    energy = 1300,
    delay  = 30,
  },
  core_freaker = {
    draw   = true,
    init   = false,
    energy = 50,
    delay  = 30,
  },
  arm_zipper = {
    draw   = true,
    init   = false,
    energy = 50,
    delay  = 30,
  },
  arm_nincommander = {
    draw   = true,
    init   = false,
    energy = 500,
    delay  = 30,
  },
  core_nincommander = {
    draw   = true,
    init   = false,
    energy = 500,
    delay  = 30,
  },
  arm_fibber = {
    draw   = true,
    init   = false,
    energy = 200,
    delay  = 30,
  },
}


if (Spring.IsDevLuaEnabled()) then
  for k,v in pairs(UnitDefNames) do
    stealthDefs[k] = {
      init   = false,
      energy = v.metalCost * 0.5,
      draw   = true
    }
  end
end


return stealthDefs


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
