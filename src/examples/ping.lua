os.loadAPI("mcip")

TIMEOUT_THRESHOLD = 10

mcip.initialize()
mcip.ipv4_initialize("default", "192.168.1.1", "255.255.255.0", "192.168.1.254")
mcip.filter(mcip.ICMP, mcip.ENABLED)

mcip.run_with(function() 
	while true do
		mcip.icmp_ping("default", "192.168.1.2")
		parallel.waitForAny(
			function()
				local event, interface, packet = os.pullEvent("mcip")
				local reply = packet.payload.payload.payload
				print("Ping Reply "..reply.sequence..": "..((os.clock() - reply.payload) * 1000).."ms")
			end,
			function()
				sleep(TIMEOUT_THRESHOLD)
				print("Ping Timeout.")
			end
		)
		sleep(3)
	end
end)