local WAIT_TIME = 60 -- time to wait between cycles

local drone = component.proxy(component.list("drone")())
local nav = component.proxy(component.list("navigation")())

local vector
vector = {
	__add = function(vec1,vec2)
		local vec3 = vector {}
		for i = 1,#vec1  do
			vec3[i] = vec1[i] + vec2[i]
		end
		return vec3
	end,
	__sub = function(vec1,vec2)
		local vec3 = vector {}
		for i = 1,#vec1  do
			vec3[i] = vec1[i] - vec2[i]
		end
		return vec3
	end,
	__unm = function(vec1)
		local vec2 = vector {}
		for i = 1,#vec1  do
			vec2[i] = vec1[i]
		end
		return vec2
	end,
	unpack = function(tbl)
		return table.unpack(tbl)
	end
}
vector.__index = vector

setmetatable(vector,
	{
		__call = function(mt,arg1,...)
			return setmetatable(type(arg1) == "table" and arg1 or {arg1,...},vector)
		end
	}
)
local plants = {}
local charger = vector {0,0,0}
local chest = charger

do
	local list = nav.findWaypoints(16) -- Change to increase waypoint search radius, probably uses more power idk
	
	for i = 1,#list do
		local wp = list[i]
		local direction,length = wp.label:match("^plant:([2-5]):([0-9]+)$") 
		if direction then
			direction = tonumber(direction)
			local axis,negate = direction > 3 and 1 or 3, (direction % 2)*2 - 1
			for i = 0,negate*(length-1),negate do
				local pos = {table.unpack(wp.position)}
				pos[axis] = pos[axis] + i
				pos[2] = pos[2] + 3 -- Crop height
				plants[#plants+1] = vector(pos)
			end
		end
		if wp.label:find"chest" then
			chest = vector(wp.position)
		end
		if wp.label:find"charger" then
			WAIT_TIME = tonumber(wp.label:match("%[([0-9]+)%]")) or WAIT_TIME -- if charger waypoint label contains [number] the waittime will become that number
			charger = vector(wp.position)
		end
	end
end

local pos = vector {0,0,0}

local function move(vec,halt)

	drone.move(vec:unpack())
	
	if(halt) then
		local speed = drone.getVelocity()
		while(true) do
			computer.pullSignal(0.1)
			local tmpspeed = drone.getVelocity() 
			if tmpspeed < speed and tmpspeed < 2 then break end
			speed = tmpspeed
		end
		computer.pullSignal(0.5)
	end
	
	pos = pos + vec
end

local invSize = drone.inventorySize()
local currSlot = 1

while true do
	for i = 1,#plants do
		move(plants[i] - pos,true)
		if drone.detect(0) then 
			drone.swing(0)
			move(vector{0,-1,0},true)
			drone.swing(0)
		end
		
		if drone.count(currSlot) == 64 then
			currSlot = currSlot + 1
			if currSlot > invSize then
				move(chest - pos,true)
				for i = 1,invSize do
					drone.select(i)
					drone.drop(0)
				end
				currSlot = 1
			end
		end
		
	end
	move(chest - pos,true)
	for i = 1,currSlot do
		drone.select(i)
		drone.drop(0)
	end
	currSlot = 1
	move(charger - pos)
	computer.pullSignal(WAIT_TIME)
end
