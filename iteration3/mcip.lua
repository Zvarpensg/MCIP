--
-- MineCraft Internet Protocol / Zvarpensg
-- Common Library
-- Written by: supercorey/CoreSystems
-- Version 0.3
--

os.loadAPI("json")

-- CONSTANTS
CHANNEL = 1337

MAC = os.getComputerID() -- unique computer identifier
MAC_BROADCAST = 65534 -- intended to be received by all clients

ETHERNET_TEMPLATE = json.decode("{'source': 0, 'target': 0, 'vlan': 1, 'payload': ''}")
-- END CONSTANTS

interfaces = {}
interface_sides = {}
running = true

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

function quit ()
	for interface, modem in interfaces do
		modem.close(CHANNEL)
	end
	interfaces = {}
	running = false
end

function send (interface, target, message)
	local packet = ETHERNET_TEMPLATE
	packet.source = MAC
	packet.target = target
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
		local interface, message, source, target, payload = receive_promiscuous()
		if target == MAC then
			do return interface, message, source, target, payload end
		end
	end
end

function receive_promiscuous ()
	local event, modem_side, sender_channel, reply_channel, message, distance = os.pullEventRaw("modem_message")
	local packet = json.decode(message)
	return get_interface(modem_side), message, packet.source, packet.target, packet.payload
end

-- Intended for use with Parallel.waitForAll; parallel.waitForAll(mcip.receive_event, <main loop>)
function receive_event ()
	while running do
		local interface, raw, source, target, payload = receive()
		os.queueEvent("mcip_message", interface, source, target, payload)
	end
end

function receive_event_promiscuous ()
	while running do
		local interface, raw, source, target, payload = receive_promiscuous()
		os.queueEvent("mcip_message", interface, source, target, payload)
	end
end