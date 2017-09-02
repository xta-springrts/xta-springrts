unitDef = {
  unitname            = [[tree_water]],
  name                = [[tree_water]],
  iconType = "blank",
  description         = [[TREE WITH ENERGY!]],
  buildCostEnergy     = 20,
  buildCostMetal      = 10,
  builder             = false,
  canAttack           = false,
  canGuard            = false,
  canMove             = false,
  canPatrol           = false,
--  corpse              = [[DEAD]],
  reclaimable         = true,
  stealth 			  = true,
  sonarStealth		  = true,
  levelGround 		= false,
  isImmobile 		=true,
  buildcostmetal	= 10,
  repairSpeed 		= 3000,

	----------	
  footprintX          = 1,
  footprintZ          = 1,
  idleAutoHeal        = 0,  
  mass                = 24,
  maxDamage           = 10,
  moveState           = 1,
  noAutoFire          = false,
  noChaseCategory     = [[MOBILE STATIC]],
  objectName          = [[ad0_pine_1_s.s3o]], --
  sonarStealth		  = true,
  script              = [[tree_water.lua]], -- [[tpdude.lua]], 
  minWaterDepth       = 10,
  maxWaterDepth		  = 50,
}

return lowerkeys({ tree_water = unitDef })