-----------------------------------------------------------------
---                     XTA Game Rules                        ---
-----------------------------------------------------------------


local modrules  = {

  movement = {
    allowAirPlanesToLeaveMap = true;  -- defaults to true
    allowPushingEnemyUnits   = true; -- defaults to false
    allowCrushingAlliedUnits = false; -- defaults to false
    allowUnitCollisionDamage = true; -- defaults to false
  },

  construction = {
    constructionDecay      = true, -- defaults to true
    constructionDecayTime  = 6.66,  -- defaults to 6.66
    constructionDecaySpeed = 0.03,  -- defaults to 0.03
  },

  reclaim = {
    multiReclaim  = 1,   -- defaults to 0
    reclaimMethod = (Spring.GetModOptions() and (Spring.GetModOptions().reclaim_method == "1") and 1) or 0,   -- defaults to 1
    unitMethod    = 1,   -- defaults to 1

    unitEnergyCostFactor    = 0,  -- defaults to 0
    unitEfficiency          = 1,  -- defaults to 1
    featureEnergyCostFactor = 0,  -- defaults to 0

    allowEnemies  = true,  -- defaults to true
    allowAllies   = true,  -- defaults to true
  },

  repair = {
    energyCostFactor = 0,  -- defaults to 0
  },

  resurrect = {
    energyCostFactor = 0.5,  -- defaults to 0.5
  },

  capture = {
    energyCostFactor = 0,  -- defaults to 0
  },

  paralyze = {
    paralyzeOnMaxHealth = true, -- defaults to true
  },

  sensors = {   
    requireSonarUnderWater = true,  -- defaults to true
    los = {
      losMipLevel = 2,  -- defaults to 1
      losMul      = 1,  -- defaults to 1
      airMipLevel = 4,  -- defaults to 2
      airMul      = 1,  -- defaults to 1
    },
  },

  fireAtDead = {
    fireAtKilled   = false,  -- defaults to false
    fireAtCrashing = false,  -- defaults to false
  },

  nanospray = {
    allow_team_colors = true,  -- defaults to true
  },
  
  featureLOS = {
    featureVisibility = 2,    -- defaults to 3
    -- 0 - no default LOS for features
    -- 1 - gaia features always visible
    -- 2 - allyteam/gaia features always visible
    -- 3 - all features always visible
  },

  experience = {
    experienceMult = 1.0, -- defaults to 1.0

    -- these are all used in the following form:
    --   value = defValue * (1 + (scale * (exp / (exp + 1))))

    powerScale     = 1,   -- defaults to 1.0
    healthScale    = 1,   -- defaults to 0.7
    reloadScale    = 0.5, -- defaults to 0.4
  },

  flankingbonus = {
    defaultMode = 0,  -- defaults to 1
                    -- 0: no flanking bonus  
                    -- 1: global coords, mobile  
                    -- 2: unit coords, mobile  
                    -- 3: unit coords, locked 
  },

  transportability = {
    transportGround = 1,  -- defaults to 1
    transportHover  = 0,  -- defaults to 0
    transportShip   = 0,  -- defaults to 0
    transportAir    = 1,  -- defaults to 0
  },
  
  system = {
    pathFinderSystem = (Spring.GetModOptions() and (Spring.GetModOptions().qtpfs == "1") and 1) or 0,
	luaThreadingModel = 4,
  },
  
}

-----------------------------------------------------------------
-----------------------------------------------------------------

return modrules