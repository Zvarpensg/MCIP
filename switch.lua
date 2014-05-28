os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local interface, raw, source, target, type, payload = mcip.receive()
	mcip.send_raw((interface == "eth0" and "eth1" or "eth0"), raw)
	print("Forwarded "..raw.." from "..interface)
end