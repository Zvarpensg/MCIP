--
-- MineCraft Internet Protocol / Zvarpensg
-- Switch
-- Written by: supercorey/CoreSystems
-- Version 0.2
--

os.loadAPI("json")
os.loadAPI("mcip")

mcip.initialize()
mcip.close_all("eth0")
mcip.close_all("eth1")
mcip.open("eth0", mcip.CHN_ROUTING)
mcip.open("eth1", mcip.CHN_ROUTING)

function forward (side, message) -- use comm to send frame to other modem
	local interface = "eth0"
	if side == "front" then
		interface = "eth1"
	end

	local packet = json.decode(message)
	mcip.send_raw(interface, packet.target, packet.source, message)
end

print ("Switch Started")

while true do
	-- Switch node messages
	local event, side, sChan, rChan, message, distance = os.pullEvent("modem_message")
	forward(side, message)
	
	print("Forwarded "..message.." from "..side)
end