--[[
--  Tree Muncher v0.1 for OpenComputers v1.51(?)
--  Written by Matt 03/16/17, based off Black Hole Tutorial 4 found at:
--  https://oc.cil.li/index.php?/topic/484-black-hole-tutorial-04-so-you-want-to-write-a-program/
--
--  Purpose:
--    To collect the trunk of a 1x1 tree and return to starting location.
--
--  How to use:
--    Put robot at the base of a 1x1 tree, facing the tree before starting program.
--
--  Needed:
--  minimum Tier 1 Robot
--  --]]

--[[  Version 0.4 - Full LUA implementation --]]

local r = require("robot")

r.swing()    -- remove first stump of tree
r.forward()  -- move forward into tree base
while r.swingUp() do r.up() end          -- while something is above (wood) swingUp and move up
while not r.detectDown() do r.down() end -- while nothing is underneath, move down
r.back()  -- return back to starting position

--[[  Version 0.3 "Make it right"
--
robot.swing()
robot.forward()
while robot.swingUp() do robot.up() end
--]]


--[[  Version 0.2 "Make it right"
--
robot.swing()
robot.forward()
for i=1,7 -- loop 7 times
do
  robot.swingUp()
  robot.up()
end
--
--  Easier to read and more concise
--]]


--[[  Version 0.1 "Make it run"
--
robot.swing()
robot.forward()
robot.swingUp()
robot.up()
robot.swingUp()
robot.up()
robot.swingUp()
robot.up()
robot.swingUp()
--
--]]


