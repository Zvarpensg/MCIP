os.loadAPI("lib/json")
os.loadAPI("mcip")

mcip.initialize()
mcip.ipv4_initialize("eth0", "192.168.1.2", "255.255.255.0", "192.168.1.254")
mcip.filter(mcip.IPV4, mcip.ENABLED)

mcip.run_with(function() 
	while true do
		local event, interface, packet = os.pullEvent("mcip")
		if packet.ethertype == mcip.ETHERNET_TYPE_IPV4 then
			print("Source: "..packet.payload.source.." / Target: "..packet.payload.destination.." / Payload: "..packet.payload.payload)
		end
	end
end)