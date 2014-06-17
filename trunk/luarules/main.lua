if (select == nil) then
  select = function(n,...) 
    local arg = arg
    if (not arg) then arg = {...}; arg.n = #arg end
    return arg[((n=='#') and 'n')or n]
  end
end

VFS.Include(Script.GetName() .. '/gadgets.lua', nil, VFS.ZIP_ONLY)
-- TODO: use default engine gadget handler since it is more up-to-date
-- VFS.Include("LuaGadgets/gadgets.lua")
-- Not yet though: basecontent gadgets.lua hasn't implemented UnitMovefailed Callin yet (jun/14)