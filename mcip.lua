os.loadAPI("json")

-- CONSTANTS
-- Modem API (Layer 1)
CHANNEL = 1337
-- Hardware Addresses
MAC = os.getComputerID() -- unique computer identifier
MAC_BROADCAST = 65534
-- Ethernet (Layer 2)
ETHERNET_TEMPLATE = json.decode("{'source': 0, 'target': 0, 'vlan': 1, 'ethertype': 2048, 'payload': ''}")
ETHERNET_TYPE_IPV4 = 0x0800
ETHERNET_TYPE_ARP  = 0x0806
-- ARP (Layer 2)
ARP_TEMPLATE = json.decode("{ 'protocol': 2048, 'operation': 1, 'sha': 0, 'spa': '127.0.0.1', 'tha': 0, 'tpa': '127.0.0.1' }")
ARP_REQUEST = 1
ARP_REPLY   = 2
-- IPv4 (Layer 3)
IPV4_TEMPLATE = json.decode("{ 'ttl': 128, 'protocol': 17, 'source': '192.168.1.1', 'destination': '192.168.1.2' }")
IPV4_BROADCAST = "255.255.255.255"
IPV4_LOCALHOST = "127.0.0.1"
IPV4_PROTOCOL_ICMP = 1
IPV4_PROTOCOL_TCP  = 6
IPV4_PROTOCOL_UDP  = 17
-- END CONSTANTS

-- Runtime Variables
running = true -- are networking functions taking place?
interfaces = {} -- table associating interface names with modems
interface_sides = {} -- table associating block sides with interface names

-- Networking Variables
arp_cache = {} -- table for caching ARP lookups. arp_cache[protocol address] = HW address

ipv4_address = IPV4_LOCALHOST -- TODO: find better defaults
ipv4_subnet  = "255.255.255.0"
ipv4_gateway = "192.168.1.254"

-- Core Functions
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
	running = true
end

function stop ()
	for interface, modem in interfaces do
		modem.close(CHANNEL)
	end
	interfaces = {}
	running = false
end

-- TODO: Remove once it won't break everything and has a valid replacement.
function send (interface, target, message)
	ethernet_send(interface, target, ETHERNET_TYPE_IPV4, message)
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

-- Ethernet
function ethernet_send (interface, target, type, message)
	local packet = ETHERNET_TEMPLATE
	packet.source = MAC
	packet.target = target
	packet.ethertype = type
	packet.payload = message

	send_raw(interface, json.encode(packet))
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

	ethernet_send(interface, (operation == ARP_REQUEST and MAC_BROADCAST or tha), ETHERNET_TYPE_ARP, json.encode(packet))
end

function arp_request (interface, tpa)
	if arp_cache[tpa] ~= nil then
		arp_send(interface, ETHERNET_TYPE_ARP, ARP_REQUEST, MAC, ipv4_address, 0, tpa)
	end
end

function arp_reply (interface, tha, tpa)
	arp_send(interface, ETHERNET_TYPE_ARP, ARP_REPLY, MAC, ipv4_address, tha, tpa)
end

-- IPv4
function ipv4_initialize (address, subnet, gateway)
	if next(interfaces) == nil then
		initialize()
	end

	ipv4_address = address
	arp_cache[IPV4_BROADCAST] = MAC_BROADCAST
end 

function ipv4_send (interface, target, message)
	-- TODO: Implement.
end