os.loadAPI("lib/json")
os.loadAPI("mcip")

mcip.ipv4_initialize("192.168.1.2", "255.255.255.0", "192.168.1.254")
mcip.filter(mcip.UDP, mcip.ENABLED)

mcip.run_with(function() 
	mcip.udp_listen(49152, function(packet)
		print(packet.payload)
	end)
	while true do
		sleep(5)
	end
end)