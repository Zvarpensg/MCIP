os.loadAPI("lib/json")

-- CONSTANTS
-- Program Constants

---- Filtering
ETHERNET = 1
ARP = 2
IPV4 = 3
ICMP = 4

DISABLED = 0
ENABLED = 1
PROMISCUOUS = 2

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
IPV4_TEMPLATE = json.decode("{ 'ttl': 128, 'protocol': 17, 'source': '192.168.1.1', 'destination': '192.168.1.2', 'payload': '' }")
IPV4_BROADCAST = "255.255.255.255"
IPV4_LOCALHOST = "127.0.0.1"
IPV4_PROTOCOL_ICMP = 1
IPV4_PROTOCOL_TCP  = 6
IPV4_PROTOCOL_UDP  = 17
IPV4_DEFAULT_TTL = 128

-- ICMP (Layer 4)
ICMP_TEMPLATE = json.decode("{ 'type': 8, 'code': 0, 'payload': '' }")
ICMP_TYPE_ECHO_REPLY = 0
ICMP_TYPE_DESTINATION_UNREACHABLE = 3
ICMP_TYPE_ECHO = 8
ICMP_TYPE_TIME_EXCEEDED = 11
ICMP_TEMPLATE_ECHO = json.decode("{ 'identifier': 0, 'sequence': 0, 'payload': '' }")

-- END CONSTANTS

-- Runtime Variables
interfaces = {} -- table associating interface names with modems
interface_sides = {} -- table associating block sides with interface names
default_interface = nil -- first interface initialized, referenced as "default"
packet_filters = {} -- protocol type with disabled/enabled/promiscuous

ipv4_packet_queue = {}

-- Networking Variables
arp_cache = {} -- table for caching ARP lookups. arp_cache[protocol address] = HW address

ipv4_interfaces = {} -- interface = address
ipv4_routes = {} -- cidr = { route: "", interface: "", network: "", netmask: "" }

icmp_echo_identifier = 42
icmp_echo_sequence = 0

-- Core Functions
function initialize ()
	local SIDES = {"front", "back", "top", "bottom", "left", "right"}
	local wired, wireless, tower = 0, 0, 0

	for i, side in ipairs(SIDES) do
		local device = peripheral.wrap(side)

		if device ~= nil then
			local interface = nil

			if peripheral.getType(side) == "modem" then
				if device.isWireless() then
					interface = "wlan"..wireless
					wireless = wireless + 1
				else
					interface = "eth"..wired
					wired = wired + 1
				end

				device.open(CHANNEL)
			elseif peripheral.getType(side) == "bitnet_tower" then
				interface = "tower"..tower
				tower = tower + 1
			end

			if interface ~= nil then
				if default_interface == nil then
					default_interface = interface
					interfaces["default"] = device
				end

				interfaces[interface] = device
				interface_sides[side] = interface
			end
		end
	end
end

function stop ()
	for interface, modem in interfaces do
		modem.close(CHANNEL)
	end
	interfaces = {}
end

function send_raw (interface, frame)
	if interface == "default" then
		interface = default_interface
	end

	if string.find(interface, "tower") == 1 then
		interfaces[interface].transmit(frame)
	else
		interfaces[interface].transmit(CHANNEL, CHANNEL, frame)
	end
end

function receive_raw ()
	local event, side, message, distance
	parallel.waitForAny(
		function() -- block for modem message
			event, side, _, _, message, distance = os.pullEventRaw("modem_message")
		end,
		function() -- block for BitNet Tower (MoarPeripherals) message
			event, side, message, distance = os.pullEventRaw("bitnet_message")
		end
	)
	
	local packet = json.decode(message) -- parse JSON to Lua object
	local interface = get_interface(side)

	-- Events: Pre-Processing, Local Processing, Other Processing, Event Propagation
	ethernet_event(interface, packet)

	return interface, packet
end

function loop ()
	while true do
		local interface, packet = receive_raw()
		local send = false

		for protocol, state in pairs(packet_filters) do
			if state ~= DISABLED then
				if     protocol == ETHERNET then 
					if packet.target == MAC or state == PROMISCUOUS then send = true end
				elseif protocol == ARP then
					if packet.ethertype == ETHERNET_TYPE_ARP then
						if packet.payload.tha == MAC 
							or packet.payload.tpa == ipv4_interfaces[interface] 
							or state == PROMISCUOUS then send = true end
					end
				elseif protocol == IPV4 then
					if packet.ethertype == ETHERNET_TYPE_IPV4 then
						if (packet.payload.destination == ipv4_interfaces[interface] or packet.payload.destination == IPV4_BROADCAST) 
							or state == PROMISCUOUS then send = true end
					end
				elseif protocol == ICMP then
					if packet.ethertype == ETHERNET_TYPE_IPV4 and packet.payload.protocol == IPV4_PROTOCOL_ICMP then
						if (packet.payload.destination == ipv4_interfaces[interface] or packet.payload.destination == IPV4_BROADCAST) 
							or state == PROMISCUOUS then send = true end
					end
				end
			end
		end

		if send then os.queueEvent("mcip", interface, packet) end
	end
end

function get_interface (side)
	return interface_sides[side]
end

function filter (protocol, state)
	packet_filters[protocol] = state
end

function run_with (user_function)
	parallel.waitForAny(
		function()
			user_function()
		end,
		function()
			loop()
		end
	)
end

--[[function filter_state (protocol)
	if packet_filters[protocol] == nil then
		return DISABLED
	end
	return packet_filters[protocol]
end]]--

-- Ethernet
function ethernet_send (interface, target, type, message)
	local packet = ETHERNET_TEMPLATE
	packet.source = MAC
	packet.target = target
	packet.ethertype = type
	packet.payload = message

	send_raw(interface, json.encode(packet))
end

function ethernet_event (interface, packet)
	-- Propagate Event
	if packet.ethertype == ETHERNET_TYPE_ARP then 
		arp_event(interface, packet, packet.payload)
	elseif packet.ethertype == ETHERNET_TYPE_IPV4 then 
		ipv4_event(interface, packet, packet.payload)
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

	ethernet_send(interface, (operation == ARP_REQUEST and MAC_BROADCAST or tha), ETHERNET_TYPE_ARP, packet)
end

function arp_request (interface, tpa)
	if arp_cache[tpa] == nil then
		arp_send(interface, ETHERNET_TYPE_IPV4, ARP_REQUEST, MAC, ipv4_interfaces[interface], 0, tpa)
	end
end

function arp_reply (interface, tha, tpa)
	arp_send(interface, ETHERNET_TYPE_IPV4, ARP_REPLY, MAC, ipv4_interfaces[interface], tha, tpa)
end

function arp_event (interface, raw, arp)
	-- Local Processing
	if arp.operation == ARP_REQUEST then
		if arp.tpa == ipv4_interfaces[interface] then 
			arp_reply(interface, arp.sha, arp.spa)
		end
	end
	arp_cache[arp.spa] = arp.sha

	-- Other Processing
	ipv4_process_queue()
end

-- IPv4
function ipv4_initialize (interface, address, subnet, gateway)
	if interface == "default" or interface == default_interface then 
		ipv4_interfaces["default"] = address
		interface = default_interface
	end

	ipv4_interfaces[interface] = address

	arp_cache[IPV4_BROADCAST] = MAC_BROADCAST
	arp_cache[address] = MAC

	-- Invert subnet into host mask and take the logarithm base 2 of it to determine prefix
	prefix = math.ceil(math.log10(bit.bxor(math.pow(2, 32) - 1, ip_to_binary(subnet))) / math.log10(2))
	route_add(address.."/"..prefix, IPV4_BROADCAST, interface)
	route_add("0.0.0.0/0", gateway, interface)
end 

function ipv4_send (interface, destination, protocol, ttl, payload)
	-- TODO: Routing!

	if arp_cache[destination] == nil then
		local data = json.decode("{ 'interface': '', 'destination': '', 'protocol': 0, 'ttl': 0, 'payload': '' }")
		data.interface = interface
		data.destination = destination
		data.protocol = protocol
		data.ttl = ttl
		data.payload = payload

		arp_request(interface, destination)
		if ipv4_packet_queue == nil then ipv4_packet_queue = {} end
		table.insert(ipv4_packet_queue, json.encode(data))
		return
	end

	local packet = IPV4_TEMPLATE
	packet.source = ipv4_interfaces[interface]
	packet.destination = destination
	packet.protocol = protocol
	packet.ttl = ttl
	packet.payload = payload

	ethernet_send(interface, arp_cache[destination], ETHERNET_TYPE_IPV4, packet)
end

function ipv4_process_queue ()
	if ipv4_packet_queue ~= nil then
		for i, queue_packet in ipairs(ipv4_packet_queue) do
			local data = json.decode(queue_packet)
			if arp_cache[data.destination] ~= nil then
				ipv4_send(data.interface, data.destination, data.protocol, data.ttl, data.payload)
				table.remove(ipv4_packet_queue, i)
			end
		end
	end
end

function ipv4_event (interface, raw, ipv4)
	-- Pre-Processing
	raw.payload.ttl = raw.payload.ttl - 1
	ipv4 = raw.payload

	if raw.payload.ttl == 0 then 
		icmp_send(interface, raw.payload.source, IPV4_DEFAULT_TTL, ICMP_TYPE_TIME_EXCEEDED, 0, "")
		return
	end

	-- Other Processing
	arp_cache[ipv4.source] = raw.source

	-- Propagate Event
	if ipv4.protocol == 1 then
		icmp_event(interface, raw, ipv4.payload)
	end
end

function ip_to_binary (address)
	a, b, c, d = string.match(address, "(%d+).(%d+).(%d+).(%d+)")
	return (bit.blshift(tonumber(a), 24)) 
		 + (bit.blshift(tonumber(b), 16)) 
		 + (bit.blshift(tonumber(c), 8)) 
		 + tonumber(d)
end

function route_add (cidr, route, interface)
	network, prefix = string.match(cidr, "(.+)/(%d+)")
	
	netmask = bit.bxor(math.pow(2, 32 - tonumber(prefix)) - 1, math.pow(2, 32) - 1)
	network_short = bit.band(ip_to_binary(network), netmask)

	ipv4_routes[cidr] = {
		route = route,
		interface = interface,
		network = network_short,
		netmask = netmask
	}
end

function route_remove (cidr)
	ipv4_routes[cidr] = nil
end

-- ICMP
function icmp_send (interface, destination, ttl, type, code, payload)
	local packet = ICMP_TEMPLATE
	packet.type = type
	packet.code = code
	packet.payload = payload

	ipv4_send(interface, destination, IPV4_PROTOCOL_ICMP, ttl, packet)
end

function icmp_ping_ttl (interface, destination, ttl)
	local packet = ICMP_TEMPLATE_ECHO
	packet.identifier = icmp_echo_identifier
	packet.sequence = icmp_echo_sequence
	packet.payload = os.clock()

	icmp_send(interface, destination, ttl, ICMP_TYPE_ECHO, 0, packet)

	icmp_echo_sequence = icmp_echo_sequence + 1
end

function icmp_ping (interface, destination)
	icmp_ping_ttl(interface, destination, IPV4_DEFAULT_TTL)
end

function icmp_event (interface, raw, icmp)
	-- Local Processing
	if icmp.type == ICMP_TYPE_ECHO then
		local packet = ICMP_TEMPLATE_ECHO
		packet.identifier = icmp.payload.identifier
		packet.sequence = icmp.payload.sequence
		packet.payload = icmp.payload.payload

		icmp_send(interface, raw.payload.source, raw.payload.ttl, ICMP_TYPE_ECHO_REPLY, 0, packet)
	end	
end