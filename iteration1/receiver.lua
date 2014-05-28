modem = peripheral.wrap("front")
modem.open(1)

while true do
	local event, recv, sChan, rChan, message, distance = os.pullEvent("modem_message")
	print(message)
end