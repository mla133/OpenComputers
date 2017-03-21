local comp = require ('component')
local radar = comp.radar
local gpu = comp.gpu
local term = require('term')
local z,x = 0
----SETTINGS----
local range = 100 --radar scan range
local zoom = 0.3  --the lower the number, the more you'll see (1 is default as no zoom)
local scrf = 1    --which way is the screen facing (values 0-3)
----------------
local w,h  = gpu.getResolution()
local cw = math.floor(w/2)
local ch = math.floor(h/2)
 
local function orientation(k)
if scrf == 0 then
z = cw+math.floor(k['x'] * zoom)
x = ch+math.floor(k['z'] * zoom)
elseif scrf == 1 then
z = cw+math.floor(k['z'] * zoom)
x = ch-math.floor(k['x'] * zoom)
elseif scrf == 2 then
z = cw-math.floor(k['x'] * zoom)
x = ch-math.floor(k['z'] * zoom)
elseif scrf == 3 then
z = cw-math.floor(k['z'] * zoom)
x = ch+math.floor(k['x'] * zoom)
else
term.setCursor(1,1)
term.clear()
print('Wrong screen orientation variable, it is has to be a number 0-3')
os.exit()
end
return z, x
end
 
local function display(table)
for i,k in pairs(table) do
orientation(k)
if z > 0 and z <= w then
  if x > 0 and x <= h then
  term.setCursor(z,x)
  term.write(string.sub(k['name'],0,1)) end end
end
end
 
 
 
repeat
local pdsp = ''
 
local players = radar.getPlayers(range)
local mobs = radar.getMobs(range)
 
term.clear()
gpu.setForeground(0xFF0000)
term.setCursor(cw,ch)
term.write('+')
 
gpu.setForeground(0xFFFFFF)
display(mobs)
 
gpu.setForeground(0x66FF00)
display(players)
 
term.setCursor(1,1)
for i,k in pairs(players) do
if type(k) == 'table' then
pdsp = pdsp .. (k['name'] .. ': ' .. math.floor(k['distance']) .. 'm ')
end
end
print (pdsp)
 
os.sleep(1)
until false