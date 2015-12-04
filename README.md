# UsbHwThinClient4Vm

Attempt to attach display/mouse/keyboard to VMWAVE virtual machine.
HW device for this: Altera MAX10 FPGA dev kit "marsohod3"
Info about dev kit board is here http://www.marsohod.org/plata-marsokhod3

Board has MAX10 FPGA chip, SDRAM chip, HDMI video output and FTDI chip for connecting board to computer via USB2.
FTDI allows synchronous FIFO mode writing up to 35 megabytes/sec. This should be enough to make "display".

HDMI signals connected directly to chip, so probably we cannot achieve high resolution. Anyway 1280x720 60Hz should be possible.
Plan is:
	1) implement HDMI video output from memory framebuffer. 1280x720 high-color (16bit per pixel) because of memory limitations.
	2) develop communication protocol over FTDI sync FIFO physical transport
	3) implement hw write machine which will allow writing bitmap rectangles from computer to framebuffer
	4) implement USB HID (keyboard and mouse) support in FPGA. Input devices will be attached to board using "connector shield"
	5) where possible make functional simulation of HW development using icarus verilog simulator
	5) develop computer service (c++) which sends screen changes to attached HW thin client, injects user input on desktop.
 Try system in runing VMWARE virtual machine.
 So target would be to use single computer between 2 users. Second user should work remotely over USB HW "marsohod3" device.
 
 
	
	
