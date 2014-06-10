os.loadAPI("lib/json")
os.loadAPI("mcip")

mcip.ipv4_initialize("192.168.1.2", "255.255.255.0", "192.168.1.254")

while true do
	local interface, packet = mcip.receive()
	print("Source: "..packet.payload.source.." / Target: "..packet.payload.destination.." / Payload: "..json.encode(packet.payload))
end