--
-- MineCraft Internet Protocol / Zvarpensg
-- Client
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")

-- LOCAL CONSTANTS
modem_side = "back"
mac = os.getComputerID()
-- GLOBAL CONSTANTS
CHN_BROADCAST = 65534 -- intended to be received by all clients
CHN_ROUTING = 65533 -- used for initial routing in lieu of client ARP tables
ETHERNET_TEMPLATE = json.decode("{'source': 0, 'target': 0, 'vlan': 1, 'payload': ''}")
-- END CONSTANTS

-- Initialize modem
modem = peripheral.wrap(modem_side)
modem.open(mac) -- listen on own MAC
modem.open(CHN_BROADCAST) -- listen for broadcasts

function send (recipient, message)
	local packet = ETHERNET_TEMPLATE
	packet.source = mac
	packet.target = recipient
	packet.payload = message
	modem.transmit(CHN_ROUTING, mac, json.encode(packet))
end

while true do
	local message = "foo"
	send(CHN_BROADCAST, message) -- broadcast message
	print("Sent '"..message.."'")
	sleep(5)
end