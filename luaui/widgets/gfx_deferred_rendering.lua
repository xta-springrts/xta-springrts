--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Deferred rendering",
    version   = 3,
    desc      = "Deferred rendering widget",
    author    = "beherith, DeadnightWarrior",
    date      = "2013 july",
    license   = "CC-BY-ND",
    layer     = -1000000000,
    enabled   = true
  }
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Automatically generated local definitions

local GL_MODELVIEW           = GL.MODELVIEW
local GL_NEAREST             = GL.NEAREST
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_PROJECTION          = GL.PROJECTION
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glColorMask            = gl.ColorMask
local glCopyToTexture        = gl.CopyToTexture
local glCreateList           = gl.CreateList
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glDepthMask            = gl.DepthMask
local glDepthTest            = gl.DepthTest
local glGetMatrixData        = gl.GetMatrixData
local glGetShaderLog         = gl.GetShaderLog
local glGetUniformLocation   = gl.GetUniformLocation
local glGetViewSizes         = gl.GetViewSizes
local glLoadIdentity         = gl.LoadIdentity
local glLoadMatrix           = gl.LoadMatrix
local glMatrixMode           = gl.MatrixMode
local glMultiTexCoord        = gl.MultiTexCoord
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glResetMatrices        = gl.ResetMatrices
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glTexRect              = gl.TexRect
local glRect                 = gl.Rect
local glUniform              = gl.Uniform
local glUniformMatrix        = gl.UniformMatrix
local glUseShader            = gl.UseShader
local glVertex               = gl.Vertex
local glTranslate            = gl.Translate
local spEcho                 = Spring.Echo
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetCameraVectors     = Spring.GetCameraVectors
local spGetDrawFrame         = Spring.GetDrawFrame
local spIsSphereInView       = Spring.IsSphereInView
local spWorldToScreenCoords  = Spring.WorldToScreenCoords
local spTraceScreenRay       = Spring.TraceScreenRay
local spGetVisibleProjectiles = Spring.GetVisibleProjectiles
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileType    = Spring.GetProjectileType
local spGetProjectileDefID   = Spring.GetProjectileDefID
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetPieceProjectileParams = Spring.GetPieceProjectileParams 
local spGetProjectileVelocity = Spring.GetProjectileVelocity 
local spGetGameSpeed         = Spring.GetGameSpeed

local max		= math.max
local min		= math.min
local sqrt		= math.sqrt
local diag		= math.diag
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Extra GL constants
--

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config


local debugGfx = false --or true
local GLSLRenderer = true

local BlackList = include("Configs/gfx_projectile_lights_defs.lua")	-- weapons that shouldn't use projectile lights


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local gnd_min, gnd_max = Spring.GetGroundExtremes()
if (gnd_min < 0) then gnd_min = 0 end
if (gnd_max < 0) then gnd_max = 0 end
local vsx, vsy
local ivsx = 1.0 
local ivsy = 1.0 

local depthPointShader
local depthBeamShader

local lightposlocPoint = nil
local lightcolorlocPoint = nil
local lightparamslocPoint = nil
local uniformEyePosPoint
local uniformViewPrjInvPoint

local lightposlocBeam = nil
local lightpos2locBeam = nil
local lightcolorlocBeam = nil
local lightparamslocBeam = nil
local uniformEyePosBeam 
local uniformViewPrjInvBeam 

local projectileLightTypes = {}
	--[1] red
	--[2] green
	--[3] blue
	--[4] radius
	--[5] constant 
	--[6] squared
	--[7] linear
	--[8] BEAMTYPE, true if BEAM
local lights = {}

-- parameters for each light:
-- RGBA: strength in each color channel, radius in elmos.
-- pos: xyz positions
-- params: ABC: where A is constant, B is quadratic, C is linear

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Light falloff functions: http://gamedev.stackexchange.com/questions/56897/glsl-light-attenuation-color-and-intensity-formula

local verbose = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetLightsFromUnitDefs()
	local plighttable = {}
	--These projectiles should have lights:
		--Cannon - projectile size: tempsize = 2.0f + std::min(wd.damages[0] * 0.0025f, wd.damageAreaOfEffect * 0.1f);)
		--EmgCannon - looks a bit shiny when close to ground
		--LaserCannon - über effects
		--Flame - a bit iffy cause of long projectile life... but it looks great.
		--BeamLaser --with Spring 94.1.1163+ super-über-ober effects
		--LightningCannon --same as BeamLasers
	--Shouldn't:
		--Dgun
		--MissileLauncher	-- already has CEG trails, which have both smoke and ground light
		--StarburstLauncher	-- same as MissileLauncher
		--AircraftBomb
		--Melee
		--Shield
		--TorpedoLauncher
	for w=1, #WeaponDefs do 
		local wdID = WeaponDefs[w]
		if not BlackList[wdID.name] then	-- prevent projectile light, if the weapon has some other light effect
			if (wdID.type == 'Cannon' or wdID.type == 'EmgCannon') then
				local colour = wdID.visuals
				plighttable[w] = {colour.colorR, colour.colorG, colour.colorB, 40*wdID.size, 1, 1, 0, false}
			elseif (wdID.type == 'LaserCannon') then
				local colour = wdID.visuals
				plighttable[w] = {
					colour.colorR+colour.color2R*0.06, colour.colorG+colour.color2G*0.06, colour.colorB+colour.color2B*0.06, 75*colour.thickness^0.6, 1.3, 1.69, 0, true}
			elseif (wdID.type == 'LightningCannon') then
				local colour = wdID.visuals
				plighttable[w] = {
					colour.colorR, colour.colorG, colour.colorB, 75*colour.thickness^0.5, 1.5, 2.25, 0, true}			
			elseif (wdID.type == 'BeamLaser') then
				local colour, blend = wdID.visuals, 0.0
				if wdID.largeBeamLaser then blend = 0.05 end
				plighttable[w] = {
					colour.colorR+colour.color2R*0.06+blend, colour.colorG+colour.color2G*0.06+blend, colour.colorB+colour.color2B*0.06+blend, 75*colour.thickness^0.5, 1.4, 1.96, 0, true}
			elseif (wdID.type == 'Flame') then
				plighttable[w]={0.34, 0.34, 0.2, 16*wdID.size, 1, 1, 0, false}  --{0,1,0,0.6}
			end
		end
	end	
	return plighttable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	ivsx = 1.0 / vsx --we can do /n here!
	ivsy = 1.0 / vsy
	if (Spring.GetMiniMapDualScreen()=='left') then
		vsx = vsx/2;
	end
	if (Spring.GetMiniMapDualScreen()=='right') then
		vsx = vsx/2
	end
end

widget:ViewResize()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vertSrc = [[
  void main(void)
  {
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_Position    = gl_Vertex;
  }
]]
local fragSrc
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if ((not forceNonGLSL) and Spring.GetMiniMapDualScreen()~='left') then --FIXME dualscreen
		if (not glCreateShader) then
			spEcho("Shaders not found, reverting to non-GLSL widget")
			GLSLRenderer = false
		else
			fragSrc = VFS.LoadFile("shaders\\deferred_lighting.glsl",VFS.ZIP)
			--Spring.Echo('Shader code:',fragSrc)
			depthPointShader = glCreateShader({
				vertex = vertSrc,
				fragment = fragSrc,
				uniformInt = {
					modelnormals = 0,
					modeldepths = 1,
					mapnormals = 2,
					mapdepths = 3,
				},
			})

			if (not depthPointShader) then
				spEcho(glGetShaderLog())
				spEcho("Bad depth point shader, reverting to non-GLSL widget.")
				GLSLRenderer = false
			else
				lightposlocPoint = glGetUniformLocation(depthPointShader, "lightpos")
				lightcolorlocPoint = glGetUniformLocation(depthPointShader, "lightcolor")
				lightparamslocPoint = glGetUniformLocation(depthPointShader, "lightparams")
				uniformEyePosPoint = glGetUniformLocation(depthPointShader, 'eyePos')
				uniformViewPrjInvPoint = glGetUniformLocation(depthPointShader, 'viewProjectionInv')
			end
			fragSrc = "#define BEAM_LIGHT \n".. fragSrc
			depthBeamShader = glCreateShader({
				vertex = vertSrc,
				fragment = fragSrc,
				uniformInt = {
					modelnormals = 0,
					modeldepths = 1,
					mapnormals = 2,
					mapdepths = 3,
				},
			})

			if (not depthBeamShader) then
				spEcho(glGetShaderLog())
				spEcho("Bad depthBeamShader, reverting to non-GLSL widget.")
				GLSLRenderer = false
			else
				lightposlocBeam = glGetUniformLocation(depthBeamShader, "lightpos")
				lightpos2locBeam = glGetUniformLocation(depthBeamShader, "lightpos2")
				lightcolorlocBeam = glGetUniformLocation(depthBeamShader, "lightcolor")
				lightparamslocBeam = glGetUniformLocation(depthBeamShader, "lightparams")
				uniformEyePosBeam = glGetUniformLocation(depthBeamShader, 'eyePos')
				uniformViewPrjInvBeam = glGetUniformLocation(depthBeamShader, 'viewProjectionInv')
			end
		end
		projectileLightTypes = GetLightsFromUnitDefs()
	else
		GLSLRenderer = false
	end
end


function widget:Shutdown()
  if (GLSLRenderer) then
    if (glDeleteShader) then
      glDeleteShader(depthPointShader)
      glDeleteShader(depthBeamShader)
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawLightType(lights,lighttype) -- point = 0 beam = 1
	--Spring.Echo('Camera FOV=',Spring.GetCameraFOV()) -- default TA cam fov = 45
	-- set uniforms
	local cpx, cpy, cpz = spGetCameraPosition()
	if lighttype==0 then --point
		glUseShader(depthPointShader)
		glUniform(uniformEyePosPoint, cpx, cpy, cpz)
		glUniformMatrix(uniformViewPrjInvPoint,  "viewprojectioninverse")
	else --beam
		glUseShader(depthBeamShader)
		glUniform(uniformEyePosBeam, cpx, cpy, cpz)
		glUniformMatrix(uniformViewPrjInvBeam,  "viewprojectioninverse")
	end

	glTexture(0, "$model_gbuffer_normtex")
	glTexture(1, "$model_gbuffer_zvaltex")
	glTexture(2, "$map_gbuffer_normtex")
	glTexture(3, "$map_gbuffer_zvaltex")
	--f= Spring.GetGameFrame()
	--f=f/50
	for i=1, #lights do
		local light = lights[i]
		local inview = false
		local lightradius = 0
		--Spring.Echo(light)
		local px = light[9] + light[12]*0.5
		local py = light[10] + light[13]*0.5
		local pz = light[11] + light[14]*0.5
		if lighttype==0 then 
			lightradius = light[4]
			inview = spIsSphereInView(light[9],light[10],light[11],lightradius)
		else 
			lightradius = light[4] + diag(light[12], light[13], light[14])*0.5
			inview = spIsSphereInView(px, py, pz, lightradius)
		end
		if (inview) then
			--Spring.Echo("Drawlighttype position=",light[9],light[10],light[11])
			local sx,sy,sz = spWorldToScreenCoords(px, py, pz) -- returns x,y,z, where x and y are screen pixels, and z is z buffer depth.
			--Spring.Echo('screencoords',sx,sy,sz)
			sx = sx/vsx
			sy = sy/vsy --since FOV is static in the Y direction, the Y ratio is the correct one
			local screenratio = vsy/vsx --so we dont overdraw and only always draw a square
			--local cx,cy,cz = spGetCameraPosition()
			--local ratio = lightradius / diag(px-cx, py-cy, pz-cz)
			local ratio = lightradius / diag(px-cpx, py-cpy, pz-cpz)
			local ratio2 = ratio*2
			if lighttype==0 then
				glUniform(lightposlocPoint, light[9],light[10],light[11], light[4]) --IN world space
				glUniform(lightcolorlocPoint, light[1],light[2],light[3], 1) 
				glUniform(lightparamslocPoint, light[5],light[6],light[7], 1) 
			else
				glUniform(lightposlocBeam, light[9],light[10],light[11], light[4]) --IN world space
				glUniform(lightpos2locBeam, light[9]+light[12], light[10]+light[13]+24, light[11]+light[14], light[4]) --IN world space,the magic constant of +24 in the Y pos is needed because of our beam distance calculator function in GLSL
				glUniform(lightcolorlocBeam, light[1],light[2],light[3], 1) 
				glUniform(lightparamslocBeam, light[5],light[6],light[7], 1) 
			end
			
			--Spring.Echo('screenratio',ratio,sx,sy)
			
			glTexRect(
				max(-1 , (sx-0.5)*2-ratio2*screenratio), 
				max(-1 , (sy-0.5)*2-ratio2), 
				min( 1 , (sx-0.5)*2+ratio2*screenratio), 
				min( 1 , (sy-0.5)*2+ratio2), 
				max( 0 , sx - ratio*screenratio), 
				max( 0 , sy - ratio), 
				min( 1 , sx + ratio*screenratio),
				min( 1 , sy + ratio)) -- screen size goes from -1,-1 to 1,1; uvs go from 0,0 to 1,1
			--gl.TexRect(-1, -1, 1, 1, 0, 0, 1, 1) -- screen size goes from -1,-1 to 1,1; uvs go from 0,0 to 1,1
		end
	end
	--gl.TexRect(0.5,0.5, 1, 1, 0.5, 0.5, 1, 1)

	glUseShader(0)
end

local projectiles = {}
local beamlightprojectiles = {}
local pointlightprojectiles = {}

--[[	projectiles trajectory is interpolated along the video frames, not just game frames
		so updating only on gameframe will make the light lag behing the projectile
function widget:GameFrame()
	GetVisibleProjectiles()
end

local timeDelta = 0
function widget:Update(dt)
	local _, _, paused = spGetGameSpeed()
	if paused then
		timeDelta = timeDelta + dt
		if timeDelta > 0.5 then
			timeDelta = 0
			GetVisibleProjectiles()
		end
	end
end
--]]

function widget:DrawWorld()
	if (GLSLRenderer) then
		local projectiles = spGetVisibleProjectiles(-1)
		if #projectiles == 0 then return end
		beamlightprojectiles = {}
		pointlightprojectiles = {}
		for i=1, #projectiles do
			local pID = projectiles[i]
			local wep, piece = spGetProjectileType(pID)
			if piece then
				local explosionflags = spGetPieceProjectileParams(pID)
				if explosionflags and (explosionflags%32)>15  then --only stuff with the FIRE explode tag gets a light
					local x,y,z = spGetProjectilePosition(pID)
					pointlightprojectiles[#pointlightprojectiles+1] = {0.5,0.5,0.25,100,1,1,0,false,x,y,z,0,0,0}
				end
			else
				local wID = spGetProjectileDefID(pID)
				local lps = projectileLightTypes[wID]	-- light parameters
				if lps then	-- not all weapons need to have projectile lights
					local x,y,z = spGetProjectilePosition(pID)
					if lps[8] then --BEAM type
						local dx,dy,dz = spGetProjectileVelocity(pID)
						if WeaponDefs[wID].type=="LaserCannon" then
							local dur = WeaponDefs[wID].duration*30
							beamlightprojectiles[#beamlightprojectiles+1] = {lps[1],lps[2],lps[3],lps[4],lps[5],lps[6],lps[7],lps[8],x-dx*dur,y-dy*dur,z-dz*dur,dx,dy,dz}
						else	-- BeamLaser, LightningCannon
							beamlightprojectiles[#beamlightprojectiles+1] = {lps[1],lps[2],lps[3],lps[4],lps[5],lps[6],lps[7],lps[8],x,y,z,dx,dy,dz}
						end
					else --point type
						pointlightprojectiles[#pointlightprojectiles+1] = {lps[1],lps[2],lps[3],lps[4],lps[5],lps[6],lps[7],lps[8],x,y,z,0,0,0}
					end
				end
			end
		end 

		--//FIXME handle dualscreen correctly!
		-- copy the depth buffer
		
		-- setup the shader and its uniform values
		glBlending(GL.DST_COLOR, GL.ONE) -- ResultR=LightR*DestinationR+1*DestinationR
			--glBlending(GL.SRC_ALPHA,GL.SRC_COLOR) 
			--http://www.andersriggelsen.dk/glblendfunc.php
			--glBlending(GL.ONE,GL.DST_COLOR) --http://www.andersriggelsen.dk/glblendfunc.php
		--glBlending(GL.ONE,GL.ZERO)
		if #beamlightprojectiles>0 then DrawLightType(beamlightprojectiles, 1) end
		if #pointlightprojectiles>0 then DrawLightType(pointlightprojectiles, 0) end
		glBlending(false)
	else
		Spring.Echo('Removing deferred rendering widget: failed to use GLSL shader')
		widgetHandler:RemoveWidget()
		return
	end
end