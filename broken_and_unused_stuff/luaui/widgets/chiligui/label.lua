--//=============================================================================

Label = Control:Inherit{
  classname= "label",

  width = 70,
  height = 20,

  padding = {0,0,0,0},

  autosize = true,

  align    = "left",
  valign   = "center",
  caption  = "no text",
  
  _lastcaption = nil,
}

local this = Label
local inherited = this.inherited

--//=============================================================================

function Label:New(obj)
  obj = inherited.New(self,obj)
  obj:SetCaption(obj.caption)
  return obj
end

--//=============================================================================

function Label:SetCaption(newcaption)
  if (self._lastcaption == newcaption) then return end 
  self._lastcaption = newcaption
  newcaption = color2incolor(self.textColor) .. newcaption
  self.caption = newcaption
  if (self.autosize) then
    self._caption  = self.caption
    local w = fh.GetTextWidth(self.caption,self.fontsize);
    local h,d = fh.GetTextHeight(self.caption,self.fontsize);
    h = h-d

    local x = self.x
    local y = self.y

    if self.valign == "center" then
      y = y + (self.height - h) * 0.5
    elseif self.valign == "bottom" then
      y = y + self.height - h
    elseif self.valign == "top" then
    else
    end

    if self.align == "left" then
    elseif self.align == "right" then
      x = x + self.width - w
    elseif self.align == "center" then
      x = x + (self.width - w) * 0.5
    end

    self:SetPos(x,y,w,h)
  else
    local _caption = self.caption
    self._caption  = _caption
    if (fh.GetTextWidth(_caption,self.fontsize) > self.width) then
      repeat 
        _caption = _caption:sub(1,-2)
      until (fh.GetTextWidth(_caption .. '...',self.fontsize) <= self.width);
      self._caption = _caption .. '...'
    end
  end
  self:Invalidate()
end

--//=============================================================================

local TextDraw            = fh.Draw
local TextDrawCentered    = fh.DrawCentered
local TextDrawRight       = fh.DrawRight
local UseFont             = fh.UseFont

--//=============================================================================

function Label:DrawControl()
  gl.Color(self.textColor)
  UseFont(self.font)

  local tx = self.x
  local ty = self.y
  local extra = ''

  --// vertical alignment
  if self.valign == "center" then
    --// vertical center
    ty = ty + self.height/2
    extra = 'v'
  elseif self.valign == "top" then
    --// top
    extra = 't'
  elseif self.valign == "bottom" then
    --// bottom
    ty = ty + self.height
    extra = 'b'
  else
    --// ascender
    extra = 'a'
  end
  
  if self.fontOutline then
	extra = extra..'o'
  end 

  if self.align == "left" then
    TextDraw(self._caption, tx, ty, self.fontsize, extra)
  elseif self.align == "right" then
    TextDrawRight(self._caption, tx + self.width, ty, self.fontsize, extra)
  elseif self.align == "center" then
    TextDrawCentered(self._caption, tx + self.width / 2, ty, self.fontsize, extra)
  end

  if (self.debug) then
    gl.Color(1,1,1,1)
    gl.PointSize(3)
    gl.BeginEnd(GL.POINTS, gl.Vertex, self.x, ty + fh.GetTextHeight(self.caption,self.fontsize));
    gl.Color(0,0,0,1)
    gl.BeginEnd(GL.POINTS, gl.Vertex, self.x, ty);
    gl.PointSize(1)
  end
end

--//=============================================================================