unitDef = {
  airSightDistance		= 0,
  autoHeal				= 100,
  unitname            	= [[cluster_20_metal]],
  name                	= [[cluster_20_metal]],
  iconType 				= "blank",
  description         	= [[Cluster with 20 metal to reclaim!]],
  buildCostEnergy     	= 20,
  buildCostMetal      	= 20,
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
  --corpse				= [[cluster2_dead]]
  --remove health bars
  health				= 100,
  height 				= 20,
  footprintX          	= 4,
  footprintZ          	= 4,
  idleAutoHeal        	= 0,  
  maxDamage           	= 10,
  moveState           	= 1,
  noAutoFire          	= false,
  noChaseCategory     	= [[MOBILE STATIC]],
  objectName          	= [[cluster2.s3o]], --
  sonarStealth		  	= true,
  script              	= [[tree.lua]], -- [[tpdude.lua]], 
  maxWaterDepth			= 0,
  minWaterDepth       	= 0,
}

return lowerkeys({ cluster_20_metal = unitDef })