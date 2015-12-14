## Generated SDC file "max10_8.out.sdc"

## Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 15.1.0 Build 185 10/21/2015 SJ Lite Edition"

## DATE    "Fri Dec 11 13:55:53 2015"

##
## DEVICE  "10M08SAE144C8GES"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLK100MHZ} -period 10.000 -waveform { 0.000 5.000 } [get_ports {CLK100MHZ}]
create_clock -name {clk60MHz} -period 16.667 -waveform { 0.000 8.333 } [get_ports {ft_clk}]
create_clock -name {clk_hsync} -period 22200.000 -waveform { 0.000 11100.000 } [get_nets {u_hvsync|hsync}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 37 -divide_by 50 -master_clock {CLK100MHZ} [get_pins {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 37 -divide_by 10 -master_clock {CLK100MHZ} [get_pins {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 37 -divide_by 25 -master_clock {CLK100MHZ} [get_pins {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -rise_to [get_clocks {clk_hsync}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -fall_to [get_clocks {clk_hsync}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.200  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.220  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.200  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.220  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.200  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.220  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.200  
set_clock_uncertainty -rise_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.220  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -rise_to [get_clocks {clk_hsync}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -fall_to [get_clocks {clk_hsync}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.200  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.220  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.200  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.220  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.200  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.220  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.200  
set_clock_uncertainty -fall_from [get_clocks {clk_hsync}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.220  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_hsync}] -setup 0.220  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_hsync}] -hold 0.200  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_hsync}] -setup 0.220  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_hsync}] -hold 0.200  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk60MHz}] -setup 0.200  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk60MHz}] -hold 0.190  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk60MHz}] -setup 0.200  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk60MHz}] -hold 0.190  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_hsync}] -setup 0.220  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_hsync}] -hold 0.200  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_hsync}] -setup 0.220  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_hsync}] -hold 0.200  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk60MHz}] -setup 0.200  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk60MHz}] -hold 0.190  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk60MHz}] -setup 0.200  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk60MHz}] -hold 0.190  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[2]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[1]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {u_clocks|u_mypll0|altpll_component|auto_generated|pll1|clk[0]}]  0.070  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

