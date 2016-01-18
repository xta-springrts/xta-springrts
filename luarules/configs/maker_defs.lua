local convertCapacities = {
		--ARM
		[UnitDefNames.arm_energy_drill.id]  = { c = 60, e = 1/60 }, -- Normal
		[UnitDefNames.arm_metal_maker.id]  = { c = 60, e = 1/60 }, -- Normal
		[UnitDefNames.arm_floating_metal_maker.id]  = { c = 180, e = 1/60 }, -- Floating
		[UnitDefNames.arm_moho_metal_maker.id]  = { c = 960, e = 1/60 }, -- Moho

		--CORE
		[UnitDefNames.core_energy_drill.id]  = { c = 60, e = 1/60 }, -- Normal
		[UnitDefNames.core_metal_maker.id]  = { c = 60, e = 1/60 }, -- Normal
		[UnitDefNames.core_floating_metal_maker.id]  = { c = 180, e = 1/60 }, -- Floating
		[UnitDefNames.core_moho_metal_maker.id]  = { c = 720, e = 1/60 }, -- Moho
		
		--TLL
		[UnitDefNames.lost_metal_maker.id]  = { c = 60, e = 1/60 }, -- Normal
		[UnitDefNames.lost_floating_metal_maker.id]  = { c = 180, e = 1/60 }, -- Floating
		[UnitDefNames.lost_moho_metal_maker.id]  = { c = 960, e = 1/60 }, -- Moho
		--Guardian
		[UnitDefNames.guardian_metal_maker.id]  = { c = 90, e = 1/60 }, -- Normal Floating
    }

return convertCapacities

