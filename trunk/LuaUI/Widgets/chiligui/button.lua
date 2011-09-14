--//=============================================================================

Button = Control:Inherit{
  classname= "button",
  caption  = 'button',
  width  = 70,
  height = 20,
}

local this = Button
local inherited = this.inherited

--//=============================================================================

function Button:SetCaption(caption)
  self.caption = caption
  self:Invalidate()
end

--//=============================================================================

local GL_TRIANGLE_STRIP = GL.TRIANGLE_STRIP
local glBeginEnd   = gl.BeginEnd
local UseFont      = fh.UseFont
local DrawCentered = fh.DrawCentered
local glColor      = gl.Color

--//=============================================================================

function Button:DrawControl()
  local tx = self.x + self.width * 0.5
  local ty = self.y + self.height * 0.5

  local state = (self._down and 'pressed') or 'normal'
  glBeginEnd(GL_TRIANGLE_STRIP, theme.DrawBackground, self, state)
  glBeginEnd(GL_TRIANGLE_STRIP, theme.DrawBorder, self, state)
 
  glColor(self.textColor)
  UseFont(self.font)
  DrawCentered(self.caption, tx, ty, self.fontsize,'v')
end

--//=============================================================================

function Button:HitTest(x,y)
  return self
end

function Button:MouseDown(...)
  self._down = true
  inherited.MouseDown(self, ...)
  self:Invalidate()
  self.captured = true
  return self
end

function Button:MouseUp(...)
  if (self._down) then
    self._down = false
    inherited.MouseUp(self, ...)
    self:Invalidate()
    return self
  end
end

--//=============================================================================