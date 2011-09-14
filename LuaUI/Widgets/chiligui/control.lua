--//=============================================================================

Control = Object:Inherit{
  classname       = 'control',
  padding         = theme.padding, --//FIXME table.shallowcopy() should be automatically used for all tables!!!!!
  borderThickness = theme.borderThickness,
  borderColor1    = theme.borderColor1,
  borderColor2    = theme.borderColor2,
  backgroundColor = theme.backgroundColor,
  font            = theme.defaultFont,
  fontsize        = theme.defaultFontSize,
  textColor       = theme.defaultTextColor,
  fontOutline	  = theme.fontOutline,
  snapToGrid      = false,
  visible         = true,
  resizeGripSize  = {11, 11},
  dragGripSize    = {10, 10},
  dragUseGrip     = false,
  draggable       = false,
  resizable       = false,
  minimumSize     = {50, 50},
  fixedRatio      = false,
  tooltip         = nil, --// JUST TEXT
  anchors         = {top=true,left=true,bottom=false,right=false},

  safeOpengl      = true, --// enables scissors
}

local this = Control
local inherited = this.inherited

--//=============================================================================

function Control:New(obj)
  obj = inherited.New(self,obj)

  local p = self.padding
  if (obj.clientWidth) then
    obj.width = obj.clientWidth + p[1] + p[3]
  end
  if (obj.clientHeight) then
    obj.height = obj.clientHeight + p[2] + p[4]
  end

  local anchors = obj.anchors
  if (not (anchors.top or anchors.bottom)) then
    anchors.top = true
  end
  if (not (anchors.left or anchors.right)) then
    anchors.left = true
  end

  obj:UpdateClientArea()
  obj:CallChildren("SaveAnchors")
  return obj
end

--//=============================================================================

function Control:SetParent(obj)
  inherited.SetParent(self,obj)
  self:SaveAnchors()
end

function Control:AddChild(obj, dontUpdate)
  inherited.AddChild(self,obj)
  if (not dontUpdate) then
    self:RequestRealign()
  end
end

function Control:RemoveChild(obj)
  local found  = inherited.RemoveChild(self,obj)
  if (found) then
    self:RequestRealign()
  end
  return found
end

--//=============================================================================

function Control:Invalidate()
  self._needRedraw = true
  --Spring.Echo(self.classname,"Invalidate")
end


function Control:SaveAnchors()
  local p = self.parent
  if (p)and(p:InheritsFrom("control")) then
    local pca = p.clientArea
    if (pca) then
      self._anchorOldRight  = pca[3] - self.x - self.width
      self._anchorOldBottom = pca[4] - self.y - self.height
    end
  end
end


function Control:UpdateClientArea()
  local padding = self.padding
  self.clientArea = {
    padding[1],
    padding[2],
    self.width - padding[1] - padding[3],
    self.height - padding[2] - padding[4]
  }

  self:SaveAnchors()
  self:RequestRealign()
  self:Invalidate() --FIXME correct place?
end


function Control:AlignControl()
  local p = self.parent
  if (not p)or(not p:InheritsFrom("control")) then
    return
  end

  if (not (self._anchorOldRight and self._anchorOldBottom)) then
    self:UpdateClientArea()
    return
  end

  local newBounds = {self.x, self.y, self.width, self.height}

  if (self.anchors.right) then
    local right = p.clientArea[3] - self.x - self.width
    if (right ~= self._anchorOldRight) then
      newBounds[3] = newBounds[3] + right - self._anchorOldRight
    end
  end

  if (self.anchors.bottom) then
    local btm = p.clientArea[4] - self.y - self.height
    if (btm ~= self._anchorOldBottom) then
      newBounds[4] = newBounds[4] + btm - self._anchorOldBottom
    end
  end

  if (not self.anchors.left) then
    newBounds[1] = newBounds[1] + newBounds[3] - self.width
    newBounds[3] = self.width
  end

  if (not self.anchors.top) then
    newBounds[2] = newBounds[2] + newBounds[4] - self.height
    newBounds[4] = self.height
  end

  self:SetPos(newBounds[1], newBounds[2], newBounds[3], newBounds[4])
end


function Control:RequestRealign()
  self._realignRequested = true
end


function Control:DisableRealign()
  self._realignDisabled = (self._realignDisabled or 0) + 1
end


function Control:EnableRealign()
  self._realignDisabled = ((self._realignDisabled or 0)>1 and self._realignDisabled - 1) or nil
  if (self._realignRequested) then
    self:Realign()
    self._realignRequested = nil
  end
end

function Control:Realign()
  if (not self._realignDisabled) then
    if (not self._inRealign) then
      self._inRealign = true
      self:AlignControl()
      local childrenAligned = false
      if (self.UpdateLayout) then
         childrenAligned = self:UpdateLayout()
      end
      self._realignRequested = nil
      if (not childrenAligned) then
        self:RealignChildren()
      end
      self._inRealign = nil
    end
  else
    self:RequestRealign()
  end
end


function Control:RealignChildren()
  self:CallChildren"Realign"
end


function Control:SetPos(x, y, w, h)
  if x then
    self.x = x
  end
  if y then
    self.y = y
  end
  if w then
    self.width = w
  end
  if h then
    self.height = h
  end
  self:UpdateClientArea()
end


function Control:Resize(w, h)
  if w then
    self.width = w
  end
  if h then
    self.height = h
  end
  self:UpdateClientArea()
end

--//=============================================================================

function Control:LocalToClient(x,y)
  local padding = self.padding
  return x - padding[1], y - padding[2]
end


function Control:ClientToLocal(x,y)
  local padding = self.padding
  return x + padding[1], y + padding[2]
end


function Control:ParentToClient(x,y)
  local padding = self.padding
  return x - self.x - padding[1], y - self.y - padding[2] 
end


function Control:ClientToParent(x,y)
  local padding = self.padding
  return x + self.x + padding[1], y + self.y + padding[2] 
end


function Control:InClientArea(x,y)
  local clientArea = self.clientArea
  return x>=clientArea[1]               and y>=clientArea[2] and
         x<=clientArea[1]+clientArea[3] and y<=clientArea[2]+clientArea[4]
end

--//=============================================================================

function Control:Update()
  if (self._realignRequested) then
    self:Realign()
    self._realignRequested = nil
  end
  if (self._needRedraw) then
    self:_UpdateOwnDListAndTexture()
    self:_UpdateAllDListAndTexture()
  end
end

--//=============================================================================

function Control:_UpdateOwnDListAndTexture()
  self:CallChildren('_UpdateOwnDListAndTexture')

  if (self._needRedraw) then
    if (self._own_dlist) then
      gl.DeleteList(self._own_dlist)
      self._own_dlist = nil
    end

    self._own_dlist = gl.CreateList(self.DrawControl, self)

    self._needRedraw = nil
  end
end

function Control:_UpdateAllDListAndTexture()
  if (self._all_dlist) then
    gl.DeleteList(self._all_dlist)
    self._all_dlist = nil
  end
  self._all_dlist = gl.CreateList(self.DrawForList, self)

  if (self.parent)and(not self.parent._needRedraw)and(self.parent._UpdateAllDListAndTexture) then
    (self.parent):_UpdateAllDListAndTexture()
  end
end

--//=============================================================================

function Control:_DrawInClientArea(fnc,...)
  if (self.safeOpengl) then
    local clientX,clientY,clientWidth,clientHeight = unpack4(self.clientArea)
    local sx,sy = self:LocalToScreen(clientX,clientY)
    sy = select(2,gl.GetViewSizes()) - (sy + clientHeight)
    gl.Scissor(sx,sy,clientWidth,clientHeight)
  end

  gl.PushMatrix()
  gl.Translate(self.x + self.clientArea[1],self.y + self.clientArea[2],0)
  fnc(...)
  gl.PopMatrix()

  if (self.safeOpengl) then
    gl.Scissor(false)
  end
end


function Control:_DrawChildrenInClientArea(event)
  self:_DrawInClientArea(self.CallChildrenInverse,self, event or 'Draw')
end

--//=============================================================================

Control.DrawResizeGrip = theme.DrawResizeGrip
Control.DrawDragGrip = theme.DrawDragGrip


function Control:DrawBackground()
  gl.BeginEnd(GL.TRIANGLE_STRIP, theme.DrawBackground, self)
end


function Control:DrawBorder()
  gl.BeginEnd(GL.TRIANGLE_STRIP, theme.DrawBorder, self)
end


function Control:DrawGrips() -- FIXME this thing is a hack, fix it - todo ideally make grips appear only when mouse hovering over it
  if self.resizable then
    self:DrawResizeGrip()
  end
  if self.draggable and self.dragUseGrip then
    self:DrawDragGrip()
  end
end


function Control:DrawControl()
  --if not self.visible then return end
  if self.snapToGrid then
    self.x = math.floor(self.x) + 0.5
    self.y = math.floor(self.y) + 0.5
  end
  self:DrawBackground()
  self:DrawBorder()
end


function Control:DrawForList()
  if (self._own_dlist) then
    gl.CallList(self._own_dlist)
  else
    self:DrawControl()
  end

  --self:CallChildrenInverse('DrawForList') --FIXME
  self:DrawChildrenForList() --FIXME
  self:DrawGrips()
end


function Control:Draw()
  if (self._all_dlist) then
    gl.CallList(self._all_dlist);
    --gl.Color(1,0,0,0.2)
    --gl.Rect(self.x, self.y, self.x+self.width, self.y+self.height)
    return;
  elseif (self._own_dlist) then
    gl.CallList(self._own_dlist);
    self:DrawChildren();
    return;
  end

  self:DrawControl()
  self:DrawChildren()
  self:DrawGrips()
end


function Control:DrawChildren()
  if (next(self.children)) then
    self:_DrawChildrenInClientArea('Draw')
  end
end

--FIXME
function Control:DrawChildrenForList()
  if (next(self.children)) then
    self:_DrawChildrenInClientArea('DrawForList')
  end
end

--//=============================================================================

local function InLocalRect(cx,cy,w,h)
  return (cx>=0)and(cy>=0)and(cx<=w)and(cy<=h)
end


function Control:HitTest(x,y)
  if not self.disableChildrenHitTest then 
    if self:InClientArea(x,y) then
      local cax,cay = self:LocalToClient(x,y)
      local children = self.children
      for i=1,#children do
        local c = children[i]
        if (c) then
          local cx,cy = c:ParentToLocal(cax,cay)
          if InLocalRect(cx,cy,c.width,c.height) then
            local obj = c:HitTest(cx,cy)
            if (obj) then
              return obj
            end
          end
        end
      end
    end
  end

  if self.resizable and
     x > self.width - self.resizeGripSize[1] and
     y > self.height - self.resizeGripSize[2]
  then
    return self
  end

  if self.draggable then
	if not self.dragUseGrip then
		return self
	elseif x < self.dragGripSize[1] and y < self.dragGripSize[2] then 
		return self
	end
  end

  return false
end


function Control:MouseDown(x, y, ...)
  if self.resizable and
     x > self.width - self.resizeGripSize[1] and
     y > self.height - self.resizeGripSize[2]
  then
    self.resizing = {
      mouse = {x, y}, 
      size  = {self.width, self.height},
      pos   = {self.x, self.y},
    }
    return self
  else
    if self:InClientArea(x,y) then
      local cx,cy = self:LocalToClient(x,y)
      local obj = inherited.MouseDown(self, cx, cy, ...)
      if (obj) then
        return obj
      end
    end
  end

  if self.draggable then
	if not self.dragUseGrip or (x < self.dragGripSize[1] and y < self.dragGripSize[2]) then
		self.dragging = true
		return self
	end
  end
end


function Control:MouseMove(x, y, dx, dy, ...)
  if self.dragging then
    self.x = self.x + dx
    self.y = self.y + dy
    self:Invalidate()
    return self

  elseif self.resizing then
    local oldState = self.resizing
    local deltaMousePosX = x - oldState.mouse[1]
    local deltaMousePosY = y - oldState.mouse[2]

    self.width = math.max(
      self.minimumSize[1], 
      oldState.size[1] + deltaMousePosX
    )
    self.height = math.max(
      self.minimumSize[2], 
      oldState.size[2] + deltaMousePosY
    )

    if self.fixedRatio == true then
      local ratioyx = self.height/self.width
      local ratioxy = self.width/self.height
      local oldSize = oldState.size
      local oldxy   = oldSize[1]/oldSize[2]
      local oldyx   = oldSize[2]/oldSize[1]
      if (ratioxy-oldxy < ratioyx-oldyx) then
        self.width  = self.height*oldxy
      else
        self.height = self.width*oldyx
      end
    end

    self:UpdateClientArea()
    self:Invalidate()
    return self

  end

  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseMove(self, cx, cy, dx, dy, ...)
end


function Control:MouseUp(x, y, ...)
  self.resizing = nil
  self.dragging = nil
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseUp(self, cx, cy, ...)
end


function Control:MouseClick(x, y, ...)
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseClick(self, cx, cy, ...)
end


function Control:MouseDblClick(x, y, ...)
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseDblClick(self, cx, cy, ...)
end


function Control:MouseWheel(x, y, ...)
  local cx,cy = self:LocalToClient(x,y)
  return inherited.MouseWheel(self, cx, cy, ...)
end

--//=============================================================================





