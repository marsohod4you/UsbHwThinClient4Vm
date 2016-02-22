
`timescale  1 ns / 1 ns

module tb_usb();

//12 MHz clock
reg clk_12Mhz = 1'b0;
always
	#41.67 clk_12Mhz = ~clk_12Mhz;

reg r_rst;
reg [7:0]r_sbyte;
reg r_start_pkt;
reg r_cmd_rst;
reg r_cmd_ena;
reg r_last_pkt_byte;

wire w_dp;
wire w_dm;
wire w_bus_enable;
wire w_show_next;
wire w_pkt_end;
wire w_eop;

usb11_send u_send(
	.rst(r_rst),
	.clk(clk_12Mhz),

	.sbyte(r_sbyte),
	.start_pkt(r_start_pkt),
	.last_pkt_byte(r_last_pkt_byte),
	.cmd_rst(r_cmd_rst),
	.cmd_ena(r_cmd_ena),
	
	.dp(w_dp),
	.dm(w_dm),
	.bus_enable(w_bus_enable),
	.show_next(w_show_next),
	.pkt_end(w_pkt_end),
	.eop(w_eop)
	);

initial
    begin
	r_rst=1;
	r_sbyte=0;
	r_start_pkt=0;
	r_cmd_rst=0;
	r_cmd_ena=0;
	r_last_pkt_byte=0;

	$display("hello!");
	$dumpfile("out.vcd");
	$dumpvars(0,tb_usb);
	#10;
	r_rst=0;
	#1100000;
	r_sbyte = 8'h80;
	@(posedge clk_12Mhz);
	r_start_pkt=1;
	r_cmd_ena=1;
	@(posedge clk_12Mhz);
	r_start_pkt=0;
	@(posedge w_show_next);
	r_sbyte=8'h2D;
	@(posedge w_show_next);
	r_sbyte=8'h40;
	@(posedge w_show_next);
	r_sbyte=8'h55;
	r_last_pkt_byte=1;

	#4000000;
	$finish;
    end

endmodule

