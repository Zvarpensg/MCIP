--
-- MineCraft Internet Protocol / Zvarpensg
-- Receiver
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")

-- LOCAL CONSTANTS
modem_side = "front"
mac = os.getComputerID()
-- GLOBAL CONSTANTS
CHN_BROADCAST = 65534 -- intended to be received by all clients
CHN_ROUTING = 65533 -- used for initial routing in lieu of client ARP tables
-- END CONSTANTS

-- Initialize modem
modem = peripheral.wrap(modem_side)
modem.open(mac) -- listen on own MAC
modem.open(CHN_BROADCAST) -- listen for broadcasts

while true do
	local event, side, sChan, rChan, message, distance = os.pullEvent("modem_message")
	print("Source: "..rChan.." / Target: "..sChan.." / Payload: "..message)
end