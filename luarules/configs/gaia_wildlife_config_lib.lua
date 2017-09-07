local rnd	= math.random
local floor = math.floor

local lib = {}

function lib.emptySlot(areaNumber, unitRole)
	local empty = {
		spawn= {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} },
		unitNames = {["none"] = 0},
		radius = 300,
		name = "none",
		area = areaNumber,
		role = unitRole,
		maxInRadius = 3
	}
	return empty
end 


function lib.setup4sector(areaNumber, unitRole, unitName, number, unitRadius, maxIn)
	local unitSpawn = {}
	if areaNumber == 1 then
		unitSpawn = {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} }
	elseif areaNumber == 2 then 
		unitSpawn = {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} }
	elseif areaNumber ==3 then
		unitSpawn = {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} }
	else
		unitSpawn = {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} }
	end
	local setup4sectors = {
		spawn 		= unitSpawn,
		unitNames 	= {[unitName] = number},
		radius 		= unitRadius,
		name 		= unitName,
		area 		= areaNumber,
		role 		= unitRole,
		maxInRadius = maxIn
	}
	return setup4sectors
end 


function lib.setup4sectorMobile(areaNumber, unitRole, unitName, number, unitRadius, maxIn)
	local unitSpawn = {}
	if areaNumber == 1 then
		unitSpawn = {shape = "box", dim = {x1=0, z1=0, x2= floor(mapX/2 * 512), z2=floor(mapY/2 * 512)} }
	elseif areaNumber == 2 then 
		unitSpawn = {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=floor(mapY/2 * 512), x2= mapX * 512, z2=mapY * 512} }
	elseif areaNumber ==3 then
		unitSpawn = {shape = "box", dim = {x1=floor(mapX/2 * 512), z1=0, x2= mapX * 512, z2=floor(mapY/2 * 512)} }
	else
		unitSpawn = {shape = "box", dim = {x1=0, z1=floor(mapY/2 * 512), x2= floor(mapX/2 * 512), z2=mapY * 512} }
	end
	local setup4sectors = {
		spawn 		= unitSpawn,
		unitNames 	= {[unitName] = number},
		radius 		= unitRadius,
		name 		= unitName,
		area 		= areaNumber,
		role 		= unitRole,
		maxInRadius = maxIn,
		immobile    = "noNil",
		noGrowing   = "noNil",
	}
	return setup4sectors
end 


function lib.treeGroupings(unitName, number, radius, maxInRadius)
	local Setup = {
		[1] = {
			["food1"] = lib.setup4sector(1, "food1", unitName, number, radius, maxInRadius),
			["prey1"] = lib.emptySlot(1, "prey1"),
			["pred1"] = lib.emptySlot(1, "pred1"),
			["food2"] = lib.emptySlot(1, "food2"),
			["prey2"] = lib.emptySlot(1, "prey2"),
			["pred2"] = lib.emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = lib.setup4sector(2, "food1", unitName, number, radius, maxInRadius),
			["prey1"] = lib.emptySlot(2, "prey1"),
			["pred1"] = lib.emptySlot(2, "pred1"),
			["food2"] = lib.emptySlot(2, "food2"),
			["prey2"] = lib.emptySlot(2, "prey2"),
			["pred2"] = lib.emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = lib.setup4sector(3, "food1", unitName, number, radius, maxInRadius),
			["prey1"] = lib.emptySlot(3, "prey1"),
			["pred1"] = lib.emptySlot(3, "pred1"),
			["food2"] = lib.emptySlot(3, "food2"),
			["prey2"] = lib.emptySlot(3, "prey2"),
			["pred2"] = lib.emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = lib.setup4sector(4, "food1", unitName, number, radius, maxInRadius),
			["prey1"] = lib.emptySlot(4, "prey1"),
			["pred1"] = lib.emptySlot(4, "pred1"),
			["food2"] = lib.emptySlot(4, "food2"),
			["prey2"] = lib.emptySlot(4, "prey2"),
			["pred2"] = lib.emptySlot(4, "pred2"),
		},
	}
	return Setup
end


function lib.twoTreeGroupings(unitName1, number1, radius1, maxInRadius1,
							unitName2, number2, radius2, maxInRadius2)
	local Setup = {
		[1] = {
			["food1"] = lib.setup4sector(1, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(1, "prey1"),
			["pred1"] = lib.emptySlot(1, "pred1"),
			["food2"] = lib.setup4sector(1, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(1, "prey2"),
			["pred2"] = lib.emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = lib.setup4sector(2, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(2, "prey1"),
			["pred1"] = lib.emptySlot(2, "pred1"),
			["food2"] = lib.setup4sector(2, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(2, "prey2"),
			["pred2"] = lib.emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = lib.setup4sector(3, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(3, "prey1"),
			["pred1"] = lib.emptySlot(3, "pred1"),
			["food2"] = lib.setup4sector(3, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(3, "prey2"),
			["pred2"] = lib.emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = lib.setup4sector(4, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(4, "prey1"),
			["pred1"] = lib.emptySlot(4, "pred1"),
			["food2"] = lib.setup4sector(4, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(4, "prey2"),
			["pred2"] = lib.emptySlot(4, "pred2"),
		},
	}
	return Setup
end


function lib.twoMobileFoodGroupings(unitName1, number1, radius1, maxInRadius1,
							unitName2, number2, radius2, maxInRadius2)
	local Setup = {
		[1] = {
			["food1"] = lib.setup4sectorMobile(1, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(1, "prey1"),
			["pred1"] = lib.emptySlot(1, "pred1"),
			["food2"] = lib.setup4sectorMobile(1, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(1, "prey2"),
			["pred2"] = lib.emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = lib.setup4sectorMobile(2, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(2, "prey1"),
			["pred1"] = lib.emptySlot(2, "pred1"),
			["food2"] = lib.setup4sectorMobile(2, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(2, "prey2"),
			["pred2"] = lib.emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = lib.setup4sectorMobile(3, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(3, "prey1"),
			["pred1"] = lib.emptySlot(3, "pred1"),
			["food2"] = lib.setup4sectorMobile(3, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(3, "prey2"),
			["pred2"] = lib.emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = lib.setup4sectorMobile(4, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.emptySlot(4, "prey1"),
			["pred1"] = lib.emptySlot(4, "pred1"),
			["food2"] = lib.setup4sectorMobile(4, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(4, "prey2"),
			["pred2"] = lib.emptySlot(4, "pred2"),
		},
	}
	return Setup
end


function lib.twoTreeGroupingPrey(unitName1, number1, radius1, maxInRadius1,
								unitName2, number2, radius2, maxInRadius2,
								unitName3, number3, radius3, maxInRadius3)
	local Setup = {
		[1] = {
			["food1"] = lib.setup4sector(1, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(1, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.emptySlot(1, "pred1"),
			["food2"] = lib.setup4sector(1, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(1, "prey2"),
			["pred2"] = lib.emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = lib.setup4sector(2, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(2, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.emptySlot(2, "pred1"),
			["food2"] = lib.setup4sector(2, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(2, "prey2"),
			["pred2"] = lib.emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = lib.setup4sector(3, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(3, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.emptySlot(3, "pred1"),
			["food2"] = lib.setup4sector(3, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(3, "prey2"),
			["pred2"] = lib.emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = lib.setup4sector(4, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(4, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.emptySlot(4, "pred1"),
			["food2"] = lib.setup4sector(4, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(4, "prey2"),
			["pred2"] = lib.emptySlot(4, "pred2"),
		},
	}
	return Setup
end


function lib.twoTreeGroupingPreyPred(unitName1, number1, radius1, maxInRadius1,
								unitName2, number2, radius2, maxInRadius2,
								unitName3, number3, radius3, maxInRadius3,
								unitName4, number4, radius4, maxInRadius4)
	local Setup = {
		[1] = {
			["food1"] = lib.setup4sector(1, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(1, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.setup4sector(1, "pred1", unitName4, number4, radius4, maxInRadius4),
			["food2"] = lib.setup4sector(1, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(1, "prey2"),
			["pred2"] = lib.emptySlot(1, "pred2"),
		},
		[2] = {
			["food1"] = lib.setup4sector(2, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(2, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.setup4sector(2, "pred1", unitName4, number4, radius4, maxInRadius4),
			["food2"] = lib.setup4sector(2, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(2, "prey2"),
			["pred2"] = lib.emptySlot(2, "pred2"),
		},
		[3] = {
			["food1"] = lib.setup4sector(3, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(3, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.setup4sector(3, "pred1", unitName4, number4, radius4, maxInRadius4),
			["food2"] = lib.setup4sector(3, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(3, "prey2"),
			["pred2"] = lib.emptySlot(3, "pred2"),
		},
		[4] = {
			["food1"] = lib.setup4sector(4, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(4, "prey1", unitName3, number3, radius3, maxInRadius3),
			["pred1"] = lib.setup4sector(4, "pred1", unitName4, number4, radius4, maxInRadius4),
			["food2"] = lib.setup4sector(4, "food2", unitName2, number2, radius2, maxInRadius2),
			["prey2"] = lib.emptySlot(4, "prey2"),
			["pred2"] = lib.emptySlot(4, "pred2"),
		},
	}
	return Setup
end


function lib.twoTreeGroupingTwoPreyTwoPred(unitName1, number1, radius1, maxInRadius1,
										unitName2, number2, radius2, maxInRadius2,
										unitName3, number3, radius3, maxInRadius3,
										unitName4, number4, radius4, maxInRadius4,
										unitName5, number5, radius5, maxInRadius5,
										unitName6, number6, radius6, maxInRadius6)
								
	local Setup = {
		[1] = {
			["food1"] = lib.setup4sector(1, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(1, "prey1", unitName2, number2, radius2, maxInRadius2),
			["pred1"] = lib.setup4sector(1, "pred1", unitName3, number3, radius3, maxInRadius3),
			["food2"] = lib.setup4sector(1, "food2", unitName4, number4, radius4, maxInRadius4),
			["prey2"] = lib.setup4sector(1, "prey2", unitName5, number5, radius5, maxInRadius5),
			["pred2"] = lib.setup4sector(1, "pred2", unitName6, number6, radius6, maxInRadius6),
		},
		[2] = {
			["food1"] = lib.setup4sector(2, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(2, "prey1", unitName2, number2, radius2, maxInRadius2),
			["pred1"] = lib.setup4sector(2, "pred1", unitName3, number3, radius3, maxInRadius3),
			["food2"] = lib.setup4sector(2, "food2", unitName4, number4, radius4, maxInRadius4),
			["prey2"] = lib.setup4sector(2, "prey2", unitName5, number5, radius5, maxInRadius5),
			["pred2"] = lib.setup4sector(2, "pred2", unitName6, number6, radius6, maxInRadius6),
		},
		[3] = {
			["food1"] = lib.setup4sector(3, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(3, "prey1", unitName2, number2, radius2, maxInRadius2),
			["pred1"] = lib.setup4sector(3, "pred1", unitName3, number3, radius3, maxInRadius3),
			["food2"] = lib.setup4sector(3, "food2", unitName4, number4, radius4, maxInRadius4),
			["prey2"] = lib.setup4sector(3, "prey2", unitName5, number5, radius5, maxInRadius5),
			["pred2"] = lib.setup4sector(3, "pred2", unitName6, number6, radius6, maxInRadius6),
		},
		[4] = {
			["food1"] = lib.setup4sector(4, "food1", unitName1, number1, radius1, maxInRadius1),
			["prey1"] = lib.setup4sector(4, "prey1", unitName2, number2, radius2, maxInRadius2),
			["pred1"] = lib.setup4sector(4, "pred1", unitName3, number3, radius3, maxInRadius3),
			["food2"] = lib.setup4sector(4, "food2", unitName4, number4, radius4, maxInRadius4),
			["prey2"] = lib.setup4sector(4, "prey2", unitName5, number5, radius5, maxInRadius5),
			["pred2"] = lib.setup4sector(4, "pred2", unitName6, number6, radius6, maxInRadius6),
		},
	}
	return Setup
end

return lib