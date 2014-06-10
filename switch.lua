os.loadAPI("lib/json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local interface, packet = mcip.receive()
	mcip.send_raw((interface == "eth0" and "eth1" or "eth0"), json.encode(packet))
	print("Forwarded "..packet.." from "..interface)
end