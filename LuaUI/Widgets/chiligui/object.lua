--//=============================================================================

Object = {
  classname = 'object',
  x         = 0,
  y         = 0,
  width     = 10,
  height    = 10,

  children  = {},

  OnClick      = {},
  OnDblClick   = {},
  OnMouseDown  = {},
  OnMouseUp    = {},
  OnMouseMove  = {},
  OnMouseWheel = {},

  disableChildrenHitTest = false, -- if set childrens are not clickable/draggable etc - their mouse events are not processed
}

local this = Object
local inherited = this.inherited

--//=============================================================================

function Object:New(obj)
  obj = obj or {}
  local t
  for i,v in pairs(self) do
    if (not obj[i])and(i ~= "inherited") then
      t = type(v)
      if (t == "table") --[[or(t=="metatable")--]] then
        obj[i] = table.shallowcopy(v)
      end
    end
  end
  setmetatable(obj,{__index = self})
  local parent = obj.parent
  local cn = obj.children
  obj.children = {}
  for i=1,#cn do
    obj:AddChild(cn[i],true)
  end
  if (parent) then
    parent:AddChild(obj)
  end
  TaskHandler.AddObject(obj)
  return obj
end


-- calling this releases unmanaged resources like display lists and disposes of the object
-- children are disposed too
-- todo: use scream, in case the user forgets
-- nil -> nil
function Object:Dispose()
  if (self.parent) then
    (self.parent):RemoveChild(self)
  end
  -- todo: kill display list
  self:CallChildren("Dispose")
end


function Object:clone()
  local newinst = {}
   -- FIXME
  return newinst
end


function Object:Inherit(class)
  class.inherited = self

  for i,v in pairs(self) do
    if (class[i] == nil)and(i ~= "inherited") then
      t = type(v)
      if (t == "table") --[[or(t=="metatable")--]] then
        class[i] = table.shallowcopy(v)
      else
        class[i] = v
      end
    end
  end

  --setmetatable(class,{__index=self})

  return class
end

--//=============================================================================

function Object:SetParent(obj)
  self.parent = obj
end


function Object:AddChild(obj, dontUpdate)
  if (not obj.parent) then
    obj:SetParent(self)
  end

  local children = self.children
  local i = #children+1
  children[i] = obj
  children[obj] = i
  self:Invalidate()
end


function Object:RemoveChild(child)
  if (child.parent == self) then
    child:SetParent(nil)
  end

  local children = self.children
  local cn = #children
  --// todo: add a new tag to keep children order! (and then use table.remove if needed)
  for i=1,cn do
    if (child == children[i]) then
      children[i] = children[cn]
      children[cn] = nil
      children[child] = nil
      self:Invalidate()
      return true
    end
  end
  return false
end

--//=============================================================================

function Object:SetLayer(child,layer)
  local children = self.children
  table.remove(children,children[child])
  table.insert(children,layer,child)
  children[child] = 1
  for i=layer,#children do
    children[children[i]] = i
  end
  self:Invalidate()
end


function Object:BringToFront()
  if (self.parent) then
    (self.parent):SetLayer(self,1)
  end
end

--//=============================================================================

function Object:InheritsFrom(classname)
  if (self.classname == classname) then
    return true
  elseif not self.inherited then
    return false
  else
    return self.inherited.InheritsFrom(self.inherited,classname)
  end
end

--//=============================================================================

function Object:GetChild(name)
  local cn = self.children
  for i=1,#cn do
    if (name == cn[i].name) then
      return cn[i]
    end
  end
end

-- Climbs the family tree and returns the first parent that satisfies a 
-- predicate function or inherites the given class.
-- Returns nil if not found.
function Object:FindParent(predicate)
  if not self.parent then
    return -- not parent with such class name found, return nil
  elseif (type(predicate) == "string" and (self.parent):InheritsFrom(predicate)) or
         (type(predicate) == "function" and predicate(self.parent)) then 
    return self.parent
  else
    return self.parent:FindParent(predicate)
  end
end


function Object:IsDescendantOf(object)
  if (self == object) then
    return true
  end
  if (self.parent) then
    return (self.parent):IsDescendantOf(object)
  end
  return false
end


function Object:IsAncestorOf(object, _level)
  _level = _level or 1

  local children = self.children

  for i=1,#children do
    if (children[i] == object) then
      return true, _level
    end
  end

  _level = _level + 1
  for i=1,#children do
    local c = children[i]
    local res,lvl = c:IsAncestorOf(object, _level)
    if (res) then
      return true, lvl
    end
  end

  return false
end

--//=============================================================================

function Object:CallListeners(listeners, ...)
  for i=1,#listeners do
    local eventListener = listeners[i]
    if eventListener(self, ...) then
      return true
    end
  end
end


function Object:CallListenersInverse(listeners, ...)
  for i=#listeners,1,-1 do
    local eventListener = listeners[i]
    if eventListener(self, ...) then
      return true
    end
  end
end


function Object:CallChildren(eventname, ...)
  local children = self.children
  for i=1,#children do
    local child = children[i]
    if (child) then
      local obj = child[eventname](child, ...)
      if (obj) then
        return obj
      end
    end
  end
end


function Object:CallChildrenInverse(eventname, ...)
  local children = self.children
  for i=#children,1,-1 do
    local child = children[i]
    if (child) then
      local obj = child[eventname](child, ...)
      if (obj) then
        return obj
      end
    end
  end
end


local function InLocalRect(cx,cy,w,h)
  return (cx>=0)and(cy>=0)and(cx<=w)and(cy<=h)
end


function Object:CallChildrenHT(eventname, x, y, ...)
  local children = self.children
  for i=1,#children do
    local c = children[i]
    if (c) then
      local cx,cy = c:ParentToLocal(x,y)
      if InLocalRect(cx,cy,c.width,c.height) and c:HitTest(cx,cy) then
        local obj = c[eventname](c, cx, cy, ...)
        if (obj) then
          return obj
        end
      end
    end
  end
end


function Object:CallChildrenHTWeak(eventname, x, y, ...)
  local children = self.children
  for i=1,#children do
    local c = children[i]
    if (c) then
      local cx,cy = c:ParentToLocal(x,y)
      if InLocalRect(cx,cy,c.width,c.height) then
        local obj = c[eventname](c, cx, cy, ...)
        if (obj) then
          return obj
        end
      end
    end
  end
end

--//=============================================================================

function Object:Invalidate()
  --FIXME should be Control only
end


function Object:Draw()
  self:CallChildrenInverse('Draw')
end

--//=============================================================================

function Object:LocalToParent(x,y)
  return x + self.x, y + self.y
end


function Object:ParentToLocal(x,y)
  return x - self.x, y - self.y
end


Object.ParentToClient = Object.ParentToLocal
Object.ClientToParent = Object.LocalToParent


function Object:LocalToClient(x,y)
  return x,y
end


function Object:LocalToScreen(x,y)
  return (self.parent):ClientToScreen(self:LocalToParent(x,y))
end


function Object:ClientToScreen(x,y)
  return (self.parent):ScreenToClient(self:ClientToParent(x,y))
end


function Object:ScreenToLocal(x,y)
  return self:ParentToLocal((self.parent):ScreenToClient(x,y))
end


function Object:ScreenToClient(x,y)
  return self:ParentToClient((self.parent):ScreenToClient(x,y))
end

--//=============================================================================


function Object:HitTest(x,y)
  if not self.disableChildrenHitTest then 
    local children = self.children
    for i=1,#children do
      local c = children[i]
      if (c) then
        local cx,cy = c:ParentToLocal(x,y)
        if InLocalRect(cx,cy,c.width,c.height) then
          local obj = c:HitTest(cx,cy)
          if (obj) then
            return obj
          end
        end
      end
    end
  end 

  return false
end


function Object:IsAbove(x, y, ...)
  return self:HitTest(x,y)
end


function Object:MouseMove(...)
  if (self:CallListeners(self.OnMouseMove, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseMove', ...)
end


function Object:MouseDown(...)
  if (self:CallListeners(self.OnMouseDown, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseDown', ...)
end


function Object:MouseUp(...)
  if (self:CallListeners(self.OnMouseUp, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseUp', ...)
end


function Object:MouseClick(...)
  if (self:CallListeners(self.OnClick, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseClick', ...)
end


function Object:MouseDblClick(...)
  if (self:CallListeners(self.OnDblClick, ...)) then
    return self
  end

  return self:CallChildrenHT('MouseDblClick', ...)
end


function Object:MouseWheel(...)
  if (self:CallListeners(self.OnMouseWheel, ...)) then
    return self
  end

  return self:CallChildrenHTWeak('MouseWheel', ...)
end

--//=============================================================================





