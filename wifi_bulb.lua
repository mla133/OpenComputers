local event = require('event')  
local net = require('internet')

local myEventHandlers = {}  
local running = true

local con = net.open('192.168.1.110', 5577)

function myEventHandlers.key_up(address, char, code, playerName)

  if (char == 'q') then
    running = false
    print('Goodbye ' .. playerName .. '!')
  end

end

function myEventHandlers.redstone_changed(_, address, side)

  local brightness = 0xff;

  if side > 0 then
    brightness = 0xff
  else
    brightness = 0x00
  end

  print('Sending ' .. brightness .. ' to lamp...')

  con:write(string.char(0x56))
  con:write(string.char(0x00))
  con:write(string.char(0x00))
  con:write(string.char(0x00))
  con:write(string.char(brightness))
  con:write(string.char(0x0f))
  con:write(string.char(0xaa))

  con:flush()

end

function handleEvent(eventID, ...)

  local event = myEventHandlers[eventID]

  if (event) then
    event(...)
  end

end

if con then  
  print('Connected to the bulb!')
end

while running do  
  handleEvent(event.pull())
end  