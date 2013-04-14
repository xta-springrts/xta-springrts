--//=============================================================================

Trackbar = Control:Inherit{
  classname = "trackbar",
  value     = 50,
  min       = 0,
  max       = 100,
  step      = 1,

  width     = 90,
  height    = 20,

  trackColor = {0,0,0,1},
  
  OnChange = {},
}

local this = Trackbar
local inherited = this.inherited

--//=============================================================================

function Trackbar:New(obj)
  obj = inherited.New(self,obj)
  obj:SetMinMax(obj.min,obj.max)
  return obj
end

--//=============================================================================

function Trackbar:_Clamp(v)
  if (self.min<self.max) then
    if (v<self.min) then
      v = self.min
    elseif (v>self.max) then
      v = self.max
    end
  else
    if (v>self.min) then
      v = self.min
    elseif (v<self.max) then
      v = self.max
    end
  end
  return v
end

--//=============================================================================

function Trackbar:SetMinMax(min,max)
  self.min = tonumber(min) or 0
  self.max = tonumber(max) or 1
  self:SetValue(self.value)
end


function Trackbar:SetValue(v)
  v = self:_Clamp(v)
  self:CallListeners(self.OnChange,v)
  self.value = v
  self:Invalidate()
end

--//=============================================================================

function Trackbar:DrawControl()
  local percent = (self.value-self.min)/(self.max-self.min)
  theme.DrawTrackbar(self.x,self.y,self.width,self.height,percent,self.state,self.trackColor)
end

--//=============================================================================

function Trackbar:HitTest()
  return self
end

function Trackbar:MouseDown(x,y)
  self:SetValue(self.min + (x/self.width)*(self.max-self.min))
  return self
end

function Trackbar:MouseMove(x,y,dx,dy,button)
  if (button==1) then
    self:SetValue(self.min + (x/self.width)*(self.max-self.min))
    return self
  end
end

--//=============================================================================
