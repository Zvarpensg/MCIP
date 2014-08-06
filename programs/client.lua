os.loadAPI("lib/json")
os.loadAPI("mcip")

mcip.ipv4_initialize("192.168.1.1", "255.255.255.0", "192.168.1.254")

local message, target = "foo", "192.168.1.2"

mcip.run_with(function() 
	while true do
		mcip.ipv4_send("eth0", message, 0, 128, target)
		print("Sent '"..message.."' to "..target.." from "..mcip.ipv4_address)
		sleep(5)
	end
end)