os.loadAPI("lib/json")
os.loadAPI("mcip")

local message, address, target = "foo", "192.168.1.1", "192.168.1.2"

mcip.initialize()
mcip.ipv4_initialize("eth0", address, "255.255.255.0", "192.168.1.254")

mcip.run_with(function() 
	while true do
		mcip.ipv4_send("eth0", target, 0, 128, message)
		print("Sent '"..message.."' to "..target.." from "..address)
		sleep(5)
	end
end)