os.loadAPI("json")

-- CONSTANTS
CHANNEL = 1337

MAC = os.getComputerID() -- unique computer identifier
MAC_BROADCAST = 65534 -- intended to be received by all clients

-- Ethernet (Layer 2)
ETHERNET_TEMPLATE = json.decode("{'source': 0, 'target': 0, 'vlan': 1, 'ethertype': 2048, 'payload': ''}")
ETHERNET_TYPE_IPV4 = 0x0800
ETHERNET_TYPE_ARP = 0x0806
-- ARP (Layer 2)
ARP_TEMPLATE = json.decode("{ 'protocol': 2048, 'operation': 1, 'sha': 0, 'spa': '127.0.0.1', 'tha': 0, 'tpa': '127.0.0.1' }")
ARP_REQUEST = 1
ARP_REPLY = 2
-- IP (Layer 3)
IP_TEMPLATE = json.decode()
IP_BROADCAST = "255.255.255.255"
-- END CONSTANTS

running = true
interfaces = {}
interface_sides = {}

ipv4_address = "127.0.0.1"
arp_cache = {}

function initialize ()
	local SIDES = {"front", "back", "left", "right", "top", "bottom"}
	local wired, wireless = 0, 0
	for i, side in ipairs(SIDES) do
		if peripheral.getType(side) == "modem" then
			local modem = peripheral.wrap(side)
			local interface = nil
			if modem.isWireless() then
				interface = "wlan"..wireless
				wireless = wireless + 1
			else
				interface = "eth"..wired
				wired = wired + 1
			end
			modem.open(CHANNEL)
			interfaces[interface] = modem
			interface_sides[side] = interface
		end
	end
end

function initialize_ipv4 (address)
	if next(interfaces) == nil then
		initialize()
	end

	ipv4_address = address
	arp_cache[IP_BROADCAST] = MAC_BROADCAST
end 

function quit ()
	for interface, modem in interfaces do
		modem.close(CHANNEL)
	end
	interfaces = {}
	running = false
end

function send (interface, target, message)
	send_type(interface, target, message, ETHERNET_TYPE_IPV4)
end

function send_ipv4 (interface, target_ip, message)
	-- TODO: Find some way to make this work w/ ARP
end

function send_type (interface, target, message, type)
	local packet = ETHERNET_TEMPLATE
	packet.source = MAC
	packet.target = target
	packet.ethertype = type
	packet.payload = message

	send_raw(interface, json.encode(packet))
end

function send_raw (interface, frame)
	interfaces[interface].transmit(CHANNEL, CHANNEL, frame)
end

function get_interface (side)
	return interface_sides[side]
end

function receive ()
	while true do
		local interface, message, source, target, type, payload = receive_promiscuous()
		if target == MAC or target == MAC_BROADCAST then
			do return interface, message, source, target, type, payload end
		end
	end
end

function receive_promiscuous ()
	local event, modem_side, sender_channel, reply_channel, message, distance = os.pullEventRaw("modem_message")
	local packet = json.decode(message)

	if packet.ethertype == ETHERNET_TYPE_ARP then
		local arp = json.decode(packet.payload)
		if arp.operation == ARP_REQUEST then
			if arp.tha == MAC then 
				arp_reply(get_interface[modem_side], arp.sha, arp.spa)
			end
		end
		arp_cache[arp.spa] = arp.sha
	end

	return get_interface(modem_side), message, packet.source, packet.target, packet.ethertype, packet.payload
end

-- Intended for use with Parallel.waitForAll; parallel.waitForAll(mcip.receive_event, <main loop>)
function receive_event ()
	while running do
		local interface, raw, source, target, type, payload = receive()
		os.queueEvent("mcip_message", interface, source, target, type, payload)
	end
end

function receive_event_promiscuous ()
	while running do
		local interface, raw, source, target, type, payload = receive_promiscuous()
		os.queueEvent("mcip_message", interface, source, target, type, payload)
	end
end

-- ARP
function arp_send (interface, protocol, operation, sha, spa, tha, tpa)
	local packet = ARP_TEMPLATE
	packet.protocol = protocol
	packet.operation = operation
	packet.sha = sha
	packet.spa = spa
	packet.tha = tha
	packet.tpa = tpa

	send_type(interface, (operation == ARP_REQUEST and MAC_BROADCAST or tha), json.encode(packet), ETHERNET_TYPE_ARP)
end

function arp_request (interface, tpa)
	if arp_cache[tpa] ~= nil then
		arp_send(interface, ETHERNET_TYPE_ARP, ARP_REQUEST, MAC, ipv4_address, 0, tpa)
	end
end

function arp_reply (interface, tha, tpa)
	arp_send(interface, ETHERNET_TYPE_ARP, ARP_REPLY, MAC, ipv4_address, tha, tpa)
end