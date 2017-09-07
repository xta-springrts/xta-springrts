unitDef = {
  airSightDistance		= 0,
  autoHeal				= 100,
  unitname            	= [[cactus_30_metal]],
  name                	= [[cactus_30_metal]],
  iconType 				= "blank",
  description         	= [[Cactus with 30 metal to reclaim!]],
  buildCostEnergy     	= 20,
  buildCostMetal      	= 30,
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
  height 				= 20,
  footprintX          	= 2,
  footprintZ          	= 2,
  idleAutoHeal        	= 0,  
  maxDamage           	= 10,
  moveState           	= 1,
  noAutoFire          	= false,
  noChaseCategory     	= [[MOBILE STATIC]],
  objectName          	= [[Cactus3.s3o]], --
  sonarStealth		  	= true,
  script              	= [[tree.lua]], -- [[tpdude.lua]], 
  maxWaterDepth			= 0,
  minWaterDepth       	= 0,
}

return lowerkeys({ cactus_30_metal = unitDef })