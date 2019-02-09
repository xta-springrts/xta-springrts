unitDef = {
  airSightDistance		= 0,
  --autoHeal				= 100,
  unitname            	= [[meteor]],
  name                	= [[meteor]],
  iconType 				= "blank",
  description         	= [[meteor from sky]],
  buildCostEnergy     	= 200,
  buildCostMetal      	= 100,
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
  mass                	= 240,
  crushResistance		= 400,
  reclaimable         	= true,
  stealth 			 	= true,
  levelGround 			= true,
  losRadius 			= 0,
  isImmobile 			= true,
  repairable			= false,
  onOffable 			= false,
  
  --TODO
  --corpse				= [[dead_tree]]
  --remove health bars
  health				= 1000,
  height 				= 20,
  footprintX          	= 2,
  footprintZ          	= 2,
  idleAutoHeal        	= 0,  
  maxDamage           	= 1000,
  moveState           	= 1,
  noAutoFire          	= false,
  noChaseCategory     	= [[MOBILE STATIC]],
  objectName          	= [[meteor.3do]], --
  sonarStealth		  	= true,
  script              	= [[meteor.lua]], -- [[tpdude.lua]],
  maxWaterDepth			= -100000,
  minWaterDepth       	= 0,
}

return lowerkeys({ meteor = unitDef })