function widget:GetInfo()
  return {
    name      = "Performance tests",
    desc      = "LUA performance tests, for debuging purposes only, use with widget profiler",
    author    = "Deadnight Warrior",
    date      = "last thursday",
    license   = "GTFO",
    layer     = 0,
    enabled   = false,  --  loaded by default?
  }
end

--[[
NOTES: All test where conducted under XTA 9.729, with all widgets that continously comsume more
       than 0.1% CPU turned off. The percentage numbers are those shown by Widget Profiler widget.
       Tested in Player Sandbox mode on official Spring 94.1 OMP with no action going on what so ever. 
       Widget Selector was turned on and Test widget was reloaded for each test, with others being
       commented out. After reloading widget was running for ~30s before noting the CPU consumption.
       Test system: Core 2 Duo T9300 (2.5GHz, FSB 200MHz, Intel PM965), 2x2GB DDR2 667 5-5-5-15,
           NVidia QuadroFX 3600M (GPUCLK 500MHz, 64 SU 1250MHz, 512MB GDDR3 800MHz), Windows 7 x64 SP1
--]]

local x,y,a,b,d
local sqrt = math.sqrt
local deg = math.deg
local pi = math.pi
--local math = math

local x1,y1,z1,x2,y2,z2 = 1,2,3,4,5,6

local function EatCPU_Loc()
	a = 2*pi			-- 1.8%
	--a = 2*math.pi		-- 3.1%
end

function EatCPU_Glo()
	a = 2*pi			-- 2.45%
	--a = 2*math.pi		-- 3.8%
end

function widget:Update()
	for i=0, 10000 do	-- empty loop 0.15%
	
	-- Local function  vs  Global function
		--EatCPU_Loc()
		--EatCPU_Glo()
	
	-- Multiplication  vs  division
		--a = pi*0.5	-- 0.55%
		--a = pi/2		-- 0.6%


	-- Sqrt  vs  Math.Sqrt  vs  ^
		--a = math.sqrt(math.sqrt(i))	-- 6.2%		with   local math = math   enabled it's 5.6%
		--a = sqrt(sqrt(i))				-- 4.2%
		--a = i^0.25					-- 4.6%


	-- Multiplication  vs  ^2
		--a = i*i		-- 0.5%
		--a = i^2		-- 0.7%

		
	-- N multiplication  vs  ^N
		--a = i*i*i		-- 1.2%
		--a = i^3		-- 4.6%


	-- Register var  vs  Memory var  (i is loop counter (ECX), pi is var (MEM))
		--a = i*i*i*i		-- 1.45%
		--a = pi*pi*pi*pi		-- 2.3%
		
	
	-- Various ways of computing Euclidian distance between two points in space
		--d = ((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)^0.5						-- 8.5%
		--d = math.sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)					-- 7.3%
		--d = sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2)						-- 6.8%
		--d = sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) + (z1-z2)*(z1-z2))		-- 8.75%
		
		--local dx,dy,dz = x1-x2, y1-y2, z1-z2								-- 6.15%
		--d = sqrt(dx*dx + dy*dy + dz*dz)
		
	-- rad to deg conversion:  math.deg(x)  vs  x*57.295779513082320876798154814105   (you realy don't need more than 8 digits)
		--a = math.deg(i)								-- 3.2%
		--a = deg(i)									-- 2.15%
		--a = i*57.295779513082320876798154814105		-- 0.55%
	end	
end