# MCIP
## v0.4
**Currently a work-in-progress. Expect bugs!**

Implementation of a network stack in ComputerCraft for MineCraft.  
MCIP is designed to be accurate to a real-world TCP/IP setup with a focus on 
accuracy to the OSI model (actual encapsulation!) and the ability to simulate 
real networks.

## Usage
1. Put src/mcip.lua in computer filesystem's root as 'ncip'.
2. Put src/lib/json in computer filesystem under lib/.
3. Run examples or begin coding!

## Boilerplate Example
```lua
os.loadAPI("mcip")

mcip.initialize()
-- Change values as needed
mcip.ipv4_initialize("default", "192.168.1.1", "255.255.255.0", "192.168.1.254")

mcip.run_with(function() 
	while true do
		-- Your code here
	end
end)
```

## Contributors
@coreymatyas - Development (initial and ongoing).   
@cmhull42 - Development.   
All of Zvarpensg - General reference, rubber ducking, and (hopefully) ongoing 
                   development.
