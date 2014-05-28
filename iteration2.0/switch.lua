--
-- MineCraft Internet Protocol / Zvarpensg
-- Switch
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")

-- LOCAL CONSTANTS
node_side = "front"
link_side = "back"
mac = os.getComputerID()
-- GLOBAL CONSTANTS
CHN_BROADCAST = 65534 -- intended to be received by all clients
CHN_ROUTING = 65533 -- used for initial routing in lieu of client ARP tables
-- END CONSTANTS

red_node = peripheral.wrap(node_side) -- modem for hosts behind the switch
red_link = peripheral.wrap(link_side) -- modem for uplink from switch

red_node.open(CHN_ROUTING)
red_link.open(CHN_ROUTING)

function forward (side, message) -- use comm to send frame to other modem
	local outgoing = red_nodes
	if side == node_side then
		outgoing = red_link
	end

	local packet = json.decode(message)
	outgoing.transmit(CHN_ROUTING, packet.source, message)
	outgoing.transmit(packet.target, packet.source, message)
end

print ("Switch Started")

while true do
	-- Switch node messages
	local event, side, sChan, rChan, message, distance = os.pullEvent("modem_message")
	forward(side, message)
	
	print("Forwarded "..message.." from "..side)
end