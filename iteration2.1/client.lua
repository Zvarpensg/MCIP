--
-- MineCraft Internet Protocol / Zvarpensg
-- Client
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local message = "foo"
	mcip.send("eth0", mcip.CHN_BROADCAST, message)
	print("Sent '"..message.."'")
	sleep(5)
end