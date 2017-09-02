unitDef = {
  unitname            	= [[tree]],
  name                	= [[tree]],
  iconType 				= "blank",
  description         	= [[TREE!]],
  buildCostEnergy     	= 20,
  buildCostMetal      	= 10,
  builder             	= false,
  canAttack           	= false,
  canGuard            	= false,
  canMove             	= false,
  canPatrol           	= false,
  reclaimable         	= true,
  stealth 			 	 = true,
  sonarStealth		  	= true,
  levelGround 			= false,
  isImmobile 			= true,
	----------	

  height 				= 30,
  footprintX          	= 1,
  footprintZ          	= 1,
  idleAutoHeal        	= 0,  
  mass                	= 24,
  maxDamage           	= 10,
  moveState           	= 1,
  noAutoFire          	= false,
  noChaseCategory     	= [[MOBILE STATIC]],
  objectName          	= [[ad0_pine_1_s.s3o]], --
  sonarStealth		  	= true,
  script              	= [[tree.lua]], -- [[tpdude.lua]], 
  maxWaterDepth			= 0,
  minWaterDepth       = 0,
}

return lowerkeys({ tree = unitDef })