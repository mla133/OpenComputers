--[[
  Author:  7Rose
  date:    2017-01-15
  description:
    deamon for monitoring the computers/robots internal energy
    if your using this on a computer know that this is the total of all
    the battery/computers energy buffers.
 
  release notes:
    version 1.0: initial release, currently this only shows
                 you a percent on the right bottom corner of your screen.
    version 1.1: added stop functionality for stopping this service.
]]
 
 
local gpu = require("component").gpu
local event = require("event");
local computer = require("computer");
 
local timeout = 0.5;
local timer = nil;
 
local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
 
local getBatteryPercent = function()
  return round(computer.energy() / computer.maxEnergy(),2);
end
 
local showMessage= function(level)
  -- check monitor, if monochrome then send only text
  -- if multicollor -> green=70+,orange=40+, red = 40-
  -- for first release only send the number.
  local monitorDepth = 1;
  local w,h = gpu.getResolution();
  if level>0.99 then level = 1 end
 
  if monitorDepth ==1 then
      gpu.set(w-3,h,(level*100) .. "% ");
  end
end
 
local function timerCallBack()
  showMessage(getBatteryPercent());
  timer = event.timer(timeout,timerCallBack);
end
 
function start(config)
  if timer==nil then
    timer = event.timer(timeout,timerCallBack);
  else
    gpu.set(w,h,"!");
  end
end
 
function stop(config)
  if timer~=nil then
    event.cancel(timer);
  end
end