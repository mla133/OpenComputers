--Follow Script EEPROM

local PORT_FOLLOW = 0xbf01
local MAX_DIST = 100

local drone = component.proxy(component.list("drone")())
local modem = component.proxy(component.list("modem")())
local nav = component.proxy(component.list("navigation")())

modem.open(PORT_FOLLOW)

local function findClient()
	while true do
		local evt,_,sender,port,dist,msg = computer.pullSignal()
		if evt == "modem_message" and port == PORT_FOLLOW and dist < MAX_DIST and msg == "FOLLOW_REQUEST_LINK" then
			drone.setStatusText("Linked: "..sender:sub(1,3))
			modem.send(sender,port,"FOLLOW_LINK")
			return sender
		end
	end
end

local function getNearbyNodes(justLabels)
	local waypoints = nav.findWaypoints(MAX_DIST)
	local nodes = {}
	for i = 1,waypoints.n do
		if justLabels then
			nodes[i] = waypoints[i].label
		else
			local wp = waypoints[i]
			nodes[wp.label] = wp.position
		end
	end
	return nodes
end

local client,nodes,noResponse = findClient(),getNearbyNodes()
local timeout = computer.uptime() + 10

while true do
	local evt,_,sender,port,dist,msg,label,ox,oy,oz = computer.pullSignal(timeout - computer.uptime())
	if moving and drone.getOffset() < 0.5 then
		moving = false
		nodes = getNearbyNodes()
	end
	if not evt then
		if noResponse then
			return
		end
		noResponse = true;
		modem.send(client,PORT_FOLLOW,"HEARTBEAT_REQUEST")
		timeout = timeout + 1
	elseif evt == "modem_message" and sender == client and port == PORT_FOLLOW and dist < MAX_DIST then
		if msg == "HEARTBEAT_RESPONSE" then
			noResponse = false
		elseif msg == "HEARTBEAT_REQUEST" then
			modem.send(sender,port,"HEARTBEAT_RESPONSE")
		elseif msg == "POS_UPDATE" and not moving then
			local node = nodes[label]
			if not node then
				modem.send(sender,port,"UPDATE_NODES",label,table.unpack(getNearbyNodes(true)))
			else
				drone.move(node[1] - ox, node[2] - oy, node[3] - oz)
				moving = true
				modem.send(sender,port,"OK")
			end
		end
		timeout = computer.uptime() + 10
	end
end