--
-- MineCraft Internet Protocol / Zvarpensg
-- Receiver
-- Written by: supercorey/CoreSystems
-- Version 0.3
--

os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()

while true do
	local interface, raw, source, target, payload = mcip.receive()
	print("Source: "..source.." / Target: "..target.." / Payload: "..payload)
end