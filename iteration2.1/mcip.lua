--
-- MineCraft Internet Protocol / Zvarpensg
-- Common Library
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")

-- CONSTANTS
MAC = os.getComputerID() -- unique computer identifier
CHN_BROADCAST = 65534 -- intended to be received by all clients
CHN_ROUTING = 65533 -- used for initial routing in lieu of client ARP tables

ETHERNET_TEMPLATE = json.decode("{'source': 0, 'target': 0, 'vlan': 1, 'payload': ''}")
-- END CONSTANTS

interfaces = {}

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
			interfaces[interface] = modem
			open(interface, CHN_BROADCAST)
			open(interface, MAC)
		end
	end
end

function quit ()
	for interface, modem in interfaces do
		close_all(interface)
	end
	interfaces = {}
end

function open (interface, channel)
	interfaces[interface].open(channel)
end

function close (interface, channel)
	interfaces[interface].close(channel)
end

function close_all (interface)
	interfaces[interface].closeAll()
end

function send (interface, target, message)
	local packet = ETHERNET_TEMPLATE
	packet.source = MAC
	packet.target = target
	packet.payload = message

	send_raw(interface, target, MAC, json.encode(packet))
end

function send_raw (interface, target, source, frame)
	interfaces[interface].transmit(CHN_ROUTING, source, frame)
	interfaces[interface].transmit(target, source, frame)
end