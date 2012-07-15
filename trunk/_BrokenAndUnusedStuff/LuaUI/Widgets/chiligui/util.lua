--//=============================================================================

function unpack4(t)
  return t[1], t[2], t[3], t[4]
end

function clamp(min,max,num)
  if (num<min) then
    return min
  elseif (num>max) then
    return max
  end
  return num
end

function ExpandRect(rect,margin)
  return {
    rect[1] - margin[1],              --//left
    rect[2] - margin[2],              --//top
    rect[3] + margin[1] + margin[3], --//width
    rect[4] + margin[2] + margin[4], --//height
  }
end

function InRect(rect,x,y)
  return x>=rect[1]         and y>=rect[2] and
         x<=rect[1]+rect[3] and y<=rect[2]+rect[4]
end

--//=============================================================================

function AreRectsOverlapping(rect1,rect2)
  return (rect1[2]+rect1[4] >= rect2[2]) and
   (rect1[2] <= rect2[2]+rect2[4]) and
   (rect1[1]+rect1[3] >= rect2[1]) and
   (rect1[1] <= rect2[1]+rect2[3]) 
end

--//=============================================================================

local oldPrint = print
function print(...)
  oldPrint(...)
  io.flush()
end


function InvertColor(c)
  return {1 - c[1], 1 - c[2], 1 - c[3], c[4]}
end

--//=============================================================================

function string:findlast(str)
  local i
  local j = 0
  repeat
    i = j
    j = self:find(str,i+1,true)
  until (not j)
  return i
end

function string:GetExt()
  local i = self:findlast('.')
  if (i) then
    return self:sub(i)
  end
end

--//=============================================================================

function table:map(fun)
  local newTable = {}
  for key, value in pairs(self) do
    newTable[key] = fun(key, value)
  end
  return newTable
end

function table:shallowcopy()
  local newTable = {}
  for k, v in pairs(self) do
    newTable[k] = v
  end
  return newTable
end

function table:arrayshallowcopy()
  local newArray = {}
  for i=1, #self do
    newArray[i] = self[i]
  end
end

function table:arraymap(fun)
  for i=1, #self do
    newTable[i] = fun(self[i])
  end
end

function table:fold(fun, state)
  for key, value in pairs(self) do
    fun(state, key, value)
  end
end

function table:arrayreduce(fun)
  local state = self[1]
  for i=2, #self do
    state = fun(state , self[i])
  end
  return state
end

-- removes and returns element from array
-- array, T element -> T element
function table:arrayremovefirst(element)
  for i=1, #self do
    if self[i] == element then
      return self:remove(i)
    end
  end
end

function table:ifind(element)
  for i=1, #self do
    if self[i] == element then
      return true
    end
  end
  return false
end

function color2incolor(r,g,b,a)
	local colortable = {r,g,b,a}
	if type(r) == 'table' then
		colortable = r
	end
	local r,g,b,a = unpack(colortable)			
	if r == 0 then r = 0.01 end
	if g == 0 then g = 0.01 end
	if b == 0 then b = 0.01 end
	--if a == 0 then a = 0.01 end --seems transparent is bad in label text
	a = 1
	
	local inColor = '\255\255\255\255'
	if r then
		inColor = string.char(a*255) .. string.char(r*255) ..  string.char(g*255) .. string.char(b*255)
	end
	return inColor
end

function incolor2color(inColor)
	
	--local a = string.byte(inColor:sub(1,1))
	local a = 255
	local r = string.byte(inColor:sub(2,2))
	local g = string.byte(inColor:sub(3,3))
	local b = string.byte(inColor:sub(4,4))
	color = {r/255, g/255, b/255, a/255}
	
	return color
end


--//=============================================================================
