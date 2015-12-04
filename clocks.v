
///////////////////////////////////////////////////////////////
//module which generates all necessary clocks in system
///////////////////////////////////////////////////////////////

module clocks (
	input wire clk_100Mhz,
	output reg reset,
	output reg mem_clk,
	output reg video_clk = 0,
	output reg video_clk5 = 0
	);
	
`ifdef __ICARUS__ 
//simplified reset and clock generation for simulator
reg [3:0]rst_delay = 0;
always @(posedge clk_100Mhz)
	rst_delay <= { rst_delay[2:0], 1'b1 };

always @*
	reset = ~rst_delay[3];

always @*
	mem_clk = clk_100Mhz;
	
always
	#6.7 video_clk = ~video_clk;
	
always
	#1.34 video_clk5 = ~video_clk5;
	
`else

//use Quartus PLLs for real clock and reset synthesis
wire w_locked;
wire w_video_clk;
wire w_video_clk5;
wire w_mem_clk;
mypll u_mypll0(
	.inclk0(clk_100Mhz),
	.c0(w_video_clk),
	.c1(w_video_clk5),
	.c2(w_mem_clk),
	.locked(w_locked)
	);
	
always @*
begin
	reset = ~w_locked;
	mem_clk    = w_mem_clk;
	video_clk  = w_video_clk;
	video_clk5 = w_video_clk5;
end

`endif

endmodule

