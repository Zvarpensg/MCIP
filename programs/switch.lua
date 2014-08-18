os.loadAPI("lib/json")
os.loadAPI("mcip")

mcip.initialize()
mcip.ipv4_initialize("eth0", "192.168.1.3", "255.255.255.0", "192.168.1.254")
mcip.filter(mcip.ETHERNET, mcip.PROMISCUOUS)

mcip.run_with(function() 
	while true do
		local event, interface, packet = os.pullEvent("mcip")
		mcip.send_raw((interface == "eth0" and "eth1" or "eth0"), json.encode(packet))
		print("Forwarded "..json.encode(packet).." from "..interface)
	end
end)