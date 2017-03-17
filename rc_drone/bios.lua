local m=component.proxy(component.list("modem")())
m.open(2412)
local function respond(...)
  local args=table.pack(...)
  pcall(function() m.broadcast(2412, table.unpack(args)) end)
end
local function receive()
  while true do
    local evt,_,_,_,_,cmd=computer.pullSignal()
    if evt=="modem_message" then return load(cmd) end
  end
end
while true do
  local result,reason=pcall(function()
    local result,reason=receive()
    if not result then return respond(reason) end
    respond(result())
  end)
  if not result then respond(reason) end
end