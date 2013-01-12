--//=============================================================================
--// Theme

theme = {}

theme.defaultFont     = "LuaUI/Fonts/FreeSansBold_14"
theme.fontOutline 	  = false
theme.defaultFontSize = 11
theme.defaultTextColor= {0,0,0,1}

theme.padding         = {5, 5, 5, 5} -- padding: left, top, right, bottom
theme.borderThickness = 1.5
theme.borderColor1    = {1,1,1,0.6}
theme.borderColor2    = {0,0,0,0.8}
theme.backgroundColor = {0.8, 0.8, 1, 0.7}

theme.imageplaceholder = "luaui/images/placeholder.png"
theme.imageFolder      = "luaui/images/folder.png"
theme.imageFolderUp    = "luaui/images/folder_up.png"

theme.resizeGripTexture = "luaui/images/resizegrip.png"
theme.dragGripTexture = "luaui/images/draggrip.png"



local glColor  = gl.Color
local glVertex = gl.Vertex

function theme.DrawBorder_(x,y,w,h,bt,color1,color2)
  glColor(color1)
  glVertex(x,     y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x,     y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+bt)

  glColor(color2)
  glVertex(x+w-bt,y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+h)
  glVertex(x+w,   y+h)
  glVertex(x+w-bt,y+h-bt)
  glVertex(x+w-bt,y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x+bt,  y+h)
  glVertex(x,     y+h)
end


function theme.DrawBorder(obj,state)
  local x,y = obj.x, obj.y
  local w,h = obj.width, obj.height
  local bt = obj.borderThickness

  glColor((state=='pressed' and obj.borderColor2) or obj.borderColor1)
  glVertex(x,     y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x,     y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y)
  glVertex(x+bt,  y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+bt)

  glColor((state=='pressed' and obj.borderColor1) or obj.borderColor2)
  glVertex(x+w-bt,y+bt)
  glVertex(x+w,   y)
  glVertex(x+w-bt,y+h)
  glVertex(x+w,   y+h)
  glVertex(x+w-bt,y+h-bt)
  glVertex(x+w-bt,y+h)
  glVertex(x+bt,  y+h-bt)
  glVertex(x+bt,  y+h)
  glVertex(x,     y+h)
end


function theme.DrawBackground(obj)
  local x,y = obj.x, obj.y
  local w,h = obj.width, obj.height

  glColor(obj.backgroundColor)
  glVertex(x,   y)
  glVertex(x,   y+h)
  glVertex(x+w, y)
  glVertex(x+w, y+h)
end


local function DrawCheck(rect)
  local x,y,w,h = rect[1],rect[2],rect[3],rect[4]
  glVertex(x+w*0.25, y+h*0.5)
  glVertex(x+w*0.125,y+h*0.625)
  glVertex(x+w*0.375,y+h*0.625)
  glVertex(x+w*0.375,y+h*0.875)
  glVertex(x+w*0.75, y+h*0.25)
  glVertex(x+w*0.875,y+h*0.375)
end


function theme.DrawCheckbox(obj, rect, state)
  glColor(obj.backgroundColor)
  gl.Rect(rect[1]+1,rect[2]+1,rect[1]+1+rect[3]-2,rect[2]+1+rect[4]-2)

  gl.BeginEnd(GL.TRIANGLE_STRIP, theme.DrawBorder_, rect[1],rect[2],rect[3],rect[4], 1, obj.borderColor1, obj.borderColor2)

  if (obj.checked) then
    gl.BeginEnd(GL.TRIANGLE_STRIP,DrawCheck,rect)
  end
end


function theme.DrawTrackbar(x,y,w,h,percent,state,color)
  glColor(color)
  gl.Rect(x,y+h*0.5,x+w,y+h*0.5+1)

  local vc = y+h*0.5 --//verticale center
  local pos = x+percent*w

  glColor(color)
  gl.Rect(pos-2,vc-h*0.5,pos+2,vc+h*0.5)
end


function theme.DrawProgressbar(x,y,w,h,percent,state,color)
  glColor(color)
  gl.Rect(x,y,x+w*percent,y+h)
end



function theme.DrawScrollbar(type, x,y,w,h, pos, visiblePercent, state)
  glColor(theme.backgroundColor)
  gl.Rect(x,y,x+w,y+h)

  if (type=='horizontal') then
    local gripx,gripw = x+w*pos, w*visiblePercent
    gl.BeginEnd(GL.TRIANGLE_STRIP, theme.DrawBorder_, gripx,y,gripw,h, 1, theme.borderColor1, theme.borderColor2)
  else
    local gripy,griph = y+h*pos, h*visiblePercent
    gl.BeginEnd(GL.TRIANGLE_STRIP, theme.DrawBorder_, x,gripy,w,griph, 1, theme.borderColor1, theme.borderColor2)
  end
end


function theme.DrawSelectionItemBkGnd(x,y,w,h,state)
  if (state=="selected") then
    glColor(0.15,0.15,0.9,1)   
  else
    glColor({0.8, 0.8, 1, 0.45})
  end
  gl.Rect(x,y,x+w,y+h)

  gl.BeginEnd(GL.TRIANGLE_STRIP, theme.DrawBorder_, x,y,w,h, 1, theme.borderColor1, theme.borderColor2)
end


function theme._DrawDragGrip(obj)
  local x = obj.x + theme.borderThickness + 1
  local y = obj.y + theme.borderThickness + 1
  local w = obj.dragGripSize[1]
  local h = obj.dragGripSize[2]
--[[
  gl.Vertex(x, y)
  gl.Vertex(x + w, y)
  gl.Vertex(x, y + h)
  gl.Vertex(x + w, y + h)
--]]
  gl.Color(0.8,0.8,0.8,0.9)
  gl.Vertex(x, y + h*0.5)
  gl.Vertex(x + w*0.5, y)
  gl.Vertex(x + w*0.5, y + h*0.5)

  gl.Color(0.3,0.3,0.3,0.9)
  gl.Vertex(x + w*0.5, y + h*0.5)
  gl.Vertex(x + w*0.5, y)
  gl.Vertex(x + w, y + h*0.5)

  gl.Vertex(x + w*0.5, y + h)
  gl.Vertex(x, y + h*0.5)
  gl.Vertex(x + w*0.5, y + h*0.5)

  gl.Color(0.1,0.1,0.1,0.9)
  gl.Vertex(x + w*0.5, y + h)
  gl.Vertex(x + w*0.5, y + h*0.5)
  gl.Vertex(x + w, y + h*0.5)
end


function theme.DrawDragGrip(obj)
--[[
  gl.Color(obj.dragGripColor)
  gl.BeginEnd(GL.TRIANGLE_STRIP, theme._DrawDragGrip, obj)
--]]
  gl.BeginEnd(GL.TRIANGLES, theme._DrawDragGrip, obj)
end


function theme._DrawResizeGrip(obj)
  if (obj.resizable) then
    local x = obj.x + obj.width - theme.borderThickness - 1
    local y = obj.y + obj.height - theme.borderThickness - 1
    local w = obj.resizeGripSize[1]
    local h = obj.resizeGripSize[2]
--[[
    gl.Vertex(x, y)
    gl.Vertex(x - w, y)
    gl.Vertex(x, y - h)
    gl.Vertex(x - w, y - h)
--]]

    x = x-1
    y = y-1
    gl.Color(1,1,1,0.2)
      gl.Vertex(x - w, y)
      gl.Vertex(x, y - h)

      gl.Vertex(x - math.floor(w*0.66), y)
      gl.Vertex(x, y - math.floor(h*0.66))

      gl.Vertex(x - math.floor(w*0.33), y)
      gl.Vertex(x, y - math.floor(h*0.33))

    x = x+1
    y = y+1
    gl.Color(0.1, 0.1, 0.1, 0.9)
      gl.Vertex(x - w, y)
      gl.Vertex(x, y - h)

      gl.Vertex(x - math.floor(w*0.66), y)
      gl.Vertex(x, y - math.floor(h*0.66))

      gl.Vertex(x - math.floor(w*0.33), y)
      gl.Vertex(x, y - math.floor(h*0.33))

  end
end


function theme.DrawResizeGrip(obj)
--[[
  gl.Color(obj.resizeGripColor)
  gl.BeginEnd(GL.TRIANGLE_STRIP, theme._DrawResizeGrip, obj)
--]]

  gl.BeginEnd(GL.LINES, theme._DrawResizeGrip, obj)
end
