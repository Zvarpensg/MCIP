modem = peripheral.wrap("back") -- location of modem
modem.open(1) -- testing broadcast channel

while true do
	modem.transmit(1, 1, "foo") -- send "foo" on channel 1
	print("Sent 'foo'")
	sleep(5)
end