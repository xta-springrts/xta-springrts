unitDef = {
airSightDistance		= 0,
  autoHeal				= 100,
  unitname            	= [[tree_water_10_metal]],
  name                	= [[tree_water_10_metal]],
  iconType 				= "blank",
  description         	= [[Tree with 10 metal to reclaim in shallow water!]],
  buildCostEnergy     	= 20,
  buildCostMetal      	= 10,
  builder             	= false,
  blocking				= false,
  canAttack           	= false,
  canGuard            	= false,
  canMove             	= false,
  canPatrol           	= false,
  canFight				= false,
  canRepeat 			= false,
  capturable			= false,
  
  canSelfDestruct		= false,
  collide				= false,
  mass                	= 24,
  crushResistance		= mass,
  reclaimable         	= true,
  stealth 			 	= true,
  levelGround 			= false,
  losRadius 			= 0,
  isImmobile 			= true,
  repairable			= false,
  onOffable 			= false,
  
  --TODO
  --corpse				= [[dead_tree]]
  --remove health bars
  health				= 100,
  height 				= 30,
  footprintX          	= 1,
  footprintZ          	= 1,
  idleAutoHeal        	= 0,  
  maxDamage           	= 10,
  moveState           	= 1,
  noAutoFire          	= false,
  noChaseCategory     	= [[MOBILE STATIC]],
  objectName          	= [[ad0_pine_1_s.s3o]], --
  sonarStealth		  	= true,
  script              	= [[tree.lua]], -- [[tpdude.lua]], 
  minWaterDepth       	= 10,
  maxWaterDepth		  	= 50,
}

return lowerkeys({ tree_water_10_metal = unitDef })