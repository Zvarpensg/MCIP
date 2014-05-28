--
-- MineCraft Internet Protocol / Zvarpensg
-- Client
-- Written by: supercorey/CoreSystems
-- Version 0.3
--

os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local message, target = "foo", mcip.MAC_BROADCAST
	mcip.send("eth0", target, message)
	print("Sent '"..message.."' to "..target)
	sleep(5)
end