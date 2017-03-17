local component = require("component")
local event = require("event")
local modem = component.modem
modem.open(2412)
modem.broadcast(2412, "drone=component.proxy(component.list('drone')())")
while true do
  local cmd=io.read()
  if not cmd then return end
  modem.broadcast(2412, cmd)
  print(select(6, event.pull(5, "modem_message")))
end