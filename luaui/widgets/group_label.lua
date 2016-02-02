
function widget:GetInfo()
  return {
    name      = "Group Label - new",
    desc      = "Displays label on units in a group",
    author    = "gunblob, Pako",
    date      = "June 12, 2008, 29.01.2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end
 
local img  = ":l:LuaUI/Images/groups1_10.png"
--'LuaUI/Images/group_labels_atlas.png'
local Size = 10 
local ScreenOffsetXY = "-7,-7"
local HeightOffset = 5

--Trying to microoptimize this widget is useless 
--Spring.GetGroupUnits table could be cached with widget:GroupChanged but that should be done in LuaUI/Utilities/cache.lua or with an api widget

local USE_SHADER = true --geometric shader
---------------------------------------------------------------------------
if not USE_SHADER then --the legacy way of drawing 
--TODO if some degenerates have shitty GPUs which fail with shaders then use the old way of drawing for those people

function widget:DrawWorld()    
    gl.Texture(img)
    gl.Color(1,1,1,0.75)
    local s = 1/10
    for number, _ in pairs(Spring.GetGroupList()) do
      for _,unit in ipairs(Spring.GetGroupUnits(number)) do
	local ux, uy, uz = Spring.GetUnitViewPosition(unit)
	if ux then --Spring_IsUnitInView(unit) then
	  gl.PushMatrix()
	  gl.Translate(ux, uy, uz)
	  gl.Billboard()
	  local number = number == 0 and 10 or number -- 0 is 10 which is the last image in the atlas 
	  gl.TexRect(-20,-15,0,5,s*number-s,1,s*number,0)
	  gl.PopMatrix()
	end
      end
    end
    gl.Color(1,1,1,1)
    gl.Texture(false)
end
  
else ----------------------------------------------------------------------
  
local shader
  
function widget:Shutdown()
  gl.DeleteShader(shader)
end

function widget:Initialize()

  shader = gl.CreateShader({
    uniformInt = {tex=0},    
    vertex = [[
      varying vec4 viTexCoord0;

      void main()
      {
	gl_Position = gl_Vertex;
	viTexCoord0 = gl_MultiTexCoord0;
      }
    ]],  
    geoInputType = GL.POINTS,
    geoOutputType = GL.QUADS,
    geoOutputVerts = 4,
    geometry = [[
      #extension GL_EXT_geometry_shader4 : enable
      varying in vec4 viTexCoord0;
      varying out vec2 vTexCoord0;
      const float size = ]].. Size ..[[;
      
      void main()
      {
	vec4 P = gl_ModelViewProjectionMatrix*gl_PositionIn[0]+gl_ProjectionMatrix*vec4(]]..ScreenOffsetXY..[[,0,1);
        gl_Position = P+gl_ProjectionMatrix*vec4(-size,-size,0,1);
	vTexCoord0 = viTexCoord0.xy;
	EmitVertex();
        gl_Position = P+gl_ProjectionMatrix*vec4(size,-size,0,1);
	vTexCoord0 = viTexCoord0.zy;
	EmitVertex();
	gl_Position = P+gl_ProjectionMatrix*vec4(-size,size,0,1);
	vTexCoord0 = viTexCoord0.xw;
	EmitVertex();
	gl_Position = P+gl_ProjectionMatrix*vec4(size,size,0,1);
	vTexCoord0 = viTexCoord0.zw;
	EmitVertex();
	EndPrimitive();
      }
      ]],
      
    fragment = [[
      varying vec2 vTexCoord0;
      uniform sampler2D tex;

      void main()
      {
	gl_FragColor = texture2D(tex, vTexCoord0);
      }
    ]],
  })

  if (shader == nil) then
    Spring.Echo(gl.GetShaderLog())
    Spring.Echo("Group Label - shader compilation failed.")
    widgetHandler:RemoveWidget()
  end

end  

local function gl_draw_points()	
  local GetUnitViewPosition = Spring.GetUnitViewPosition
  local Vertex,TexCoord = gl.Vertex,gl.TexCoord
  local s = 1/10
  for number, _ in pairs(Spring.GetGroupList()) do
    local n = number == 0 and 10 or number -- 0 is 10 which is the last image in the atlas 
    TexCoord(s*n-s,1,s*n,0)--gl.MultiTexCoord(0,s*number-s,1,s*number,0)
    for _,unit in ipairs(Spring.GetGroupUnits(number)) do
      local x, y, z = GetUnitViewPosition(unit)
      if x then --Spring_IsUnitInView(unit) then
	Vertex(x, y+HeightOffset, z)
      end
    end
  end
end

function widget:DrawWorld()    
  gl.Texture(img)
  gl.Color(1,1,1,0.75)
  gl.UseShader(shader)
  
  gl.BeginEnd(GL.POINTS, gl_draw_points)
  
  gl.UseShader(0)
  gl.Color(1,1,1,1)
  gl.Texture(false)
end

end