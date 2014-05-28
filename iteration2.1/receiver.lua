--
-- MineCraft Internet Protocol / Zvarpensg
-- Receiver
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local event, side, sChan, rChan, message, distance = os.pullEvent("modem_message")
	print("Source: "..rChan.." / Target: "..sChan.." / Payload: "..message)
end