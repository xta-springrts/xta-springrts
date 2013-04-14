--//=============================================================================
--// FontSystem

fh = {}

function fh.UseFont(fontname)
end

function fh.GetTextWidth(text, size) 
  return gl.GetTextWidth(text) * size
end

function fh.GetTextHeight(text, size)
  local h,descender = gl.GetTextHeight(text)
  return h*size, descender*size
end

fh.StripColors = fontHandler.StripColors

fh.Begin = gl.BeginText
fh.End   = gl.EndText

function fh.Draw(text, x, y, size, extra)
  gl.PushMatrix()
  gl.Translate(x,y,0)
  gl.Scale(1,-1,1)
  gl.Text(text,0,0,size,extra)
  gl.PopMatrix()
end

function fh.DrawRight(text, x, y, size, extra)
  gl.PushMatrix()
  gl.Translate(x,y,0)
  gl.Scale(1,-1,1)
  gl.Text(text,0,0,size,'r'..(extra or ''))
  gl.PopMatrix()
end

function fh.DrawCentered(text, x, y, size, extra)
  gl.PushMatrix()
  gl.Translate(x,y,0)
  gl.Scale(1,-1,1)
  gl.Text(text,0,0,size,'c'..(extra or ''))
  gl.PopMatrix()
end
