--Follow Script Client

local PORT_FOLLOW = 0xbf01

local component = require("component")
local event = require("event")
local os = require("os")

local modem = component.modem
local nav = component.navigation

modem.open(PORT_FOLLOW)

local function findDrone()
	modem.broadcast(PORT_FOLLOW,"FOLLOW_REQUEST_LINK")
	local _,_,sender,port,_,msg = event.pull("modem_message",nil,nil,PORT_FOLLOW,nil,"FOLLOW_LINK")
	return sender
end

local drone = findDrone()

local function heartbeatHook(_,_,sender,port,_,msg)
	if sender == drone and port == PORT_FOLLOW and msg == "HEARTBEAT_REQUEST" then
		modem.send(sender,port,"HEARTBEAT_RESPONSE")
	end
end


event.listen("modem_message",heartbeatHook)

modem.send(drone,PORT_FOLLOW,"POS_UPDATE")
local nodes = {select(7,event.pull("modem_message",nil,drone,PORT_FOLLOW,nil,"UPDATE_NODES"))}

local function getNode()
	local tbl = nav.findWaypoints(100)
	for i=1,tbl.n do
		local label = tbl[i].label
		for i2=1,#nodes do
			if label == nodes[i2] then
				return label,table.unpack(tbl[i].position)
			end
		end
	end
end

while true do
        local label,x,y,z = getNode()
        print(label,x,y,z)
	modem.send(drone,PORT_FOLLOW,"POS_UPDATE",label,x,y,z)
	local args = {select(6,event.pull("modem_message",nil,drone,PORT_FOLLOW,nil))}
	if table.remove(args,1) == "UPDATE_NODES" then
		nodes = args
	end
	os.sleep(0.1)
end