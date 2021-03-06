unitDef = {
  unitname               = [[critter_goldfish_big]],
  name                   = [[Goldfish]],
  description            = [[shiny!]],
  iconType = "blank",
  acceleration           = 0.039,
  activateWhenBuilt      = true,
  brakeRate              = 0.25,
  buildCostEnergy        = 10,
  buildCostMetal         = 20,
  builder                = false,
  buildTime              = 600,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = true,
  stealth 				 = true,
  category               = [[NOWEAPON MOBILE NOTLAND NOTAIR NOTSEA SUB]],
  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 1,
  footprintZ             = 1,  
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 1,
  maxDamage              = 10,
  maxVelocity            = 2.9,
  minCloakDistance       = 75,
  minWaterDepth          = 15, -- not used, minWaterDepth in movedef used instead (36)
  maxWaterDepth			= 2000,
  modelCenterOffset      = [[0 0 -4]],
  movementClass          = [[BOATSUB]],
  noAutoFire             = false,
  noChaseCategory        = [[MOBILE STATIC]],
  objectName             = [[critter_goldfish_big.s3o]],
  script                 = [[critter_goldfish_big.lua]],
  seismicSignature       = 4,  
  side                   = [[CORE]],
  sightDistance          = 64,
  sonarDistance          = 550,
  stealth 			  	 = true,
  sonarStealth		  	 = true,
  turninplace            = 0,
  turnRate               = 3000,
  upright                = true,
  waterline              = 20,
  workerTime             = 0
}

return lowerkeys({ critter_goldfish_big = unitDef })
