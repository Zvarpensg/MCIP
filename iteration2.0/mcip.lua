--
-- MineCraft Internet Protocol / Zvarpensg
-- Common Library
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")

-- CONSTANTS
MCIP_MAC = os.getComputerID() -- unique computer identifier
MCIP_CHN_BROADCAST = 65534 -- intended to be received by all clients
MCIP_CHN_ROUTING = 65533 -- used for initial routing in lieu of client ARP tables
-- END CONSTANTS

MCIP_interfaces = {}
local MCIP_interfaces_wired = 0
local MCIP_interfaces_wireless = 0

function mcip_interface_initialize (side) 
	if peripheral.getType(side) == "modem" then
		local modem = peripheral.wrap(side)
		if modem.isWireless() then
			MCIP_interfaces["wlan"..MCIP_interfaces_wireless] = modem
			MCIP_interfaces_wireless = MCIP_interfaces_wireless + 1
		else
			MCIP_interfaces["eth"..MCIP_interfaces_wired] = modem
			MCIP_interfaces_wired = MCIP_interfaces_wired + 1
		end
	end
end

function mcip_interfaces_initialize ()
	local SIDES = {"front", "back", "left", "right", "top", "bottom"}
	for side in SIDES do
		mcip_interface_initialize(side)
	end
end

function mcip_interface_close_all (interface)
	MCIP_interfaces[interface].closeAll()
end