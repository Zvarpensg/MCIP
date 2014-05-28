red_nodes = peripheral.wrap("front") -- modem for hosts behind the switch
red_link  = peripheral.wrap("back")  -- modem for uplink from switch

red_nodes.open(1)
red_link.open(1)

function comm (interface, recipient, message) -- wrapper on modem api
	interface.transmit(recipient, recipient, message) 
end

function forward (incoming, message) -- use comm to send frame to other modem
	local outgoing = red_nodes
	if incoming == "front" then
		outgoing = red_link
	end
	comm(outgoing, 1, message)
end

print ("Switch Started")

while true do
	-- Switch node messages
	local event, recv, sChan, rChan, message, distance = os.pullEvent("modem_message")
	forward(recv, message)
	print("Forwarded '"..message.."' from "..recv)
end