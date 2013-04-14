Screen = Object:Inherit{
  classname = 'screen',
  x         = 0,
  y         = 0,
  width     = 1e9,
  height    = 1e9,

  activeControl = nil,
  hoveredControl = nil,
	currentTooltip = nil,

	
  _lastClicked = Spring.GetTimer(),
  _lastClickedX = 0,
  _lastClickedY = 0,
}

local this = Screen
local inherited = this.inherited
local lastHoveredControl

--//=============================================================================

--FIXME add new coordspace Device (which does y-invert)

function Screen:ParentToLocal(x,y)
  return x, y
end


function Screen:LocalToParent(x,y)
  return x, y
end


function Screen:LocalToScreen(x,y)
  return x, y
end


function Screen:ScreenToLocal(x,y)
  return x, y
end


function Screen:ScreenToClient(x,y)
  return x, y
end


function Screen:ClientToScreen(x,y)
  return x, y
end


--//=============================================================================

function Screen:IsAbove(x,y,...)
  y = select(2,gl.GetViewSizes()) - y
  
	self.hoveredControl = inherited.IsAbove(self,x,y,...)
	if (lastHoveredControl ~= self.hoveredControl) then -- this is perhaps not optimal, if control changes tooltip we wont notice it until user moves away and back
		if self.hoveredControl ~= nil and self.hoveredControl ~= false and self.hoveredControl~=true then
			local control = self.hoveredControl
				
			while (control.tooltip == nil and control.parent ~= nil) do  -- find tooltip in hovered control or its parents
				control = control.parent 
			end 
		
			self.currentTooltip = control.tooltip
		else 
			self.currentTooltip = nil
		end 
		lastHoveredControl = self.hoveredControl
	else 
		if lastHoveredControl ~= nil and lastHoveredControl ~= false and lastHoveredControl~=true then
			self.currentTooltip = lastHoveredControl.tooltip
		end 
	end 
	
	
	
  return (not not self.hoveredControl)
end


function Screen:MouseDown(x,y,...)
  y = select(2,gl.GetViewSizes()) - y
  self.activeControl = inherited.MouseDown(self,x,y,...)
  return (not not self.activeControl)
end


function Screen:MouseUp(x,y,...)
  y = select(2,gl.GetViewSizes()) - y
  if self.activeControl then
    local activeControl = self.activeControl
    local cx,cy = activeControl:ScreenToLocal(x,y)

    local now = Spring.GetTimer()
    if (self.hoveredControl == activeControl) then
      if (math.abs(x - self._lastClickedX)<3) and
         (math.abs(y - self._lastClickedY)<3) and
         (Spring.DiffTimers(now,self._lastClicked) < 0.45 ) --FIXME 0.45 := doubleClick time (use spring config?)
      then
        activeControl:MouseDblClick(cx,cy,...)
      else
        activeControl:MouseClick(cx,cy,...)
      end
    end
    self._lastClicked = now
    self._lastClickedX = x
    self._lastClickedY = y

    local obj = activeControl:MouseUp(cx,cy,...)
    self.activeControl = nil
    return (not not obj)
  else
    return (not not inherited.MouseUp(self,x,y,...))
  end
end


function Screen:MouseMove(x,y,dx,dy,...)
  y = select(2,gl.GetViewSizes()) - y
  if self.activeControl then
    local activeControl = self.activeControl
    local cx,cy = activeControl:ScreenToLocal(x,y)
    local obj = activeControl:MouseMove(cx,cy,dx,-dy,...)
    if (obj==false) then
      self.activeControl = nil
    elseif (not not obj)and(obj ~= activeControl) then
      self.activeControl = obj
      return true
    else
      return true
    end
  end

  return (not not inherited.MouseMove(self,x,y,dx,-dy,...))
end


function Screen:MouseWheel(x,y,...)
  y = select(2,gl.GetViewSizes()) - y
  if self.activeControl then
    local activeControl = self.activeControl
    local cx,cy = activeControl:ScreenToLocal(x,y)
    local obj = activeControl:MouseWheel(cx,cy,...)
    if (obj==false) then
      self.activeControl = nil
    elseif (not not obj)and(obj ~= activeControl) then
      self.activeControl = obj
      return true
    else
      return true
    end
  end

  return (not not inherited.MouseWheel(self,x,y,...))
end

--//=============================================================================