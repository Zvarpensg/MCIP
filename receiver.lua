os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local interface, raw, source, target, type, payload = mcip.receive()
	print("Source: "..source.." / Target: "..target.." / Payload: "..payload)
end