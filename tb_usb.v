
`timescale  1 ns / 1 ns

module tb_usb();

//60 MHz clock
reg clk_60Mhz = 1'b0;
always
	#8.33 clk_60Mhz = ~clk_60Mhz;

//148 MHz clock
reg clk_148Mhz = 1'b0;
always
	#3.37 clk_148Mhz = ~clk_148Mhz;

//divide input 60Mhz on 5 to get 12MHz clock we need for USB11
reg [2:0]div5=0;
always @( posedge clk_60Mhz )
	if(div5==3'b100)
		div5<=0;
	else
		div5<=div5+1;
		
wire clk12Mhz; assign clk12Mhz = div5[2];

reg r_rst;

//signals of attached USB device simulator
reg [7:0]r_sbyte_dev;
reg r_sbyte_wr_dev;
reg r_last_sbyte_dev;
wire w_bus_ena_dev;
wire w_show_next_dev;
wire w_pkt_end_dev;
wire w_dp_dev;
wire w_dm_dev;

wire w_usb0_dp;
wire w_usb0_dm;
wire w_usb0_out;
reg  r_usb1_dp;
reg  r_usb1_dm;
wire w_usb1_dp;
wire w_usb1_dm;
wire w_usb1_out;
reg [15:0]r_usb_cmd;
reg r_usb_cmd_wr;
reg r_usb_result_rd;
wire [15:0]w_usb_result;
wire w_usb_result_rdy;

//USB module being tested
usb11_ctrl u_usb11_ctrl(
	.reset(r_rst),
	.clk_60Mhz(clk_60Mhz),
	
	.usb0_dp_in(w_dp_dev),
	.usb0_dm_in(w_dm_dev),
	.usb0_dp_out(w_usb0_dp),
	.usb0_dm_out(w_usb0_dm),
	.usb0_out(w_usb0_out),
	.usb1_dp_in(r_usb1_dp),
	.usb1_dm_in(r_usb1_dm),
	.usb1_dp_out(w_usb1_dp),
	.usb1_dm_out(w_usb1_dm),
	.usb1_out(w_usb1_out),
	
	.clk(clk_148Mhz),
	.data_in(r_usb_cmd),
	.data_in_wr(r_usb_cmd_wr),
	.data_out_rd(r_usb_result_rd),
	.data_out(w_usb_result),
	.data_out_rdy(w_usb_result_rdy)
);

//simulate attached device response
usb11_send u_dev_usb11_send(
	.rst(r_rst),
	.clk(clk12Mhz),
	.sbyte(r_sbyte_dev),
	.sbyte_wr(r_sbyte_wr_dev),
	.last_pkt_byte(r_last_sbyte_dev),
	.dp(w_dp_dev),
	.dm(w_dm_dev),
	.bus_enable(w_bus_ena_dev),
	.show_next(w_show_next_dev),
	.pkt_end(w_pkt_end_dev),
	.ls_bit_time(),
	.eof(),
	.eof_ena()
	);

initial
   begin
	r_sbyte_dev=0;
	r_sbyte_wr_dev=1'b0;
	r_last_sbyte_dev=1'b0;
	r_rst=1;
	r_usb1_dp=1'b0;
	r_usb1_dm=1'b0;
	r_usb_cmd=1'b0;
	r_usb_cmd=0;
	r_usb_cmd_wr=1'b0;
	r_usb_result_rd=1'b0;
	$display("hello!");
	$dumpfile("out.vcd");
	$dumpvars(0,tb_usb);
	#10;
	r_rst=0;
	#800000;

	//give command, read USB lines
	write_cmd(16'h0200);
	
	@(posedge w_usb_result_rdy);
	@(posedge clk_148Mhz)
	#2;
	r_usb_result_rd=1'b1;
	@(posedge clk_148Mhz)
	#2;
	r_usb_result_rd=1'b0;

	#200;
	//give command, reset to USB0
	write_cmd(16'h0401);
	#400000;
	//give command, clear reset and enable USB0
	write_cmd(16'h0402);
	
	#1400000;
	write_cmd(16'hc080);
	write_cmd(16'h402D);
	write_cmd(16'h4000);
	write_cmd(16'h6010);

	write_cmd(16'h4080);
	write_cmd(16'h40E1);
	write_cmd(16'h403F);
	write_cmd(16'h603F);

	//wait data will be sent
	@(negedge w_usb0_out);
	#1;
	@(negedge w_usb0_out);
	#1;
	@(negedge w_usb0_out);
	#1;

	//attached device should respond..
	write_dev_byte(8'h80,1'b0);
	@(posedge w_show_next_dev);
	#1;
	write_dev_byte(8'h5A,1'b1);
	
	//new frame with USB IN read
	write_cmd(16'hc080);
	write_cmd(16'h4069);
	write_cmd(16'h4000);
	write_cmd(16'h7010);

	//wait data will be sent
	@(negedge w_usb0_out);
	#1;
	@(negedge w_usb0_out);
	#1;

	//attached device should respond..
	write_dev_byte(8'h80,1'b0);
	@(posedge w_show_next_dev);
	#1;
	write_dev_byte(8'h4B,1'b0);
	@(posedge w_show_next_dev);
	#1;
	write_dev_byte(8'h12,1'b0);
	@(posedge w_show_next_dev);
	#1;
	write_dev_byte(8'h44,1'b1);

	#2000000;
	$finish;
    end

task write_cmd;
input [15:0]cmd;
begin
	@(posedge clk_148Mhz)
	#4;
	r_usb_cmd = cmd;
	r_usb_cmd_wr = 1'b1;
	@(posedge clk_148Mhz)
	#4;
	r_usb_cmd = 0;
	r_usb_cmd_wr = 1'b0;
end
endtask

task write_dev_byte;
input [7:0]ubyte;
input last;
begin
	@(posedge clk12Mhz)
	#4;
	r_sbyte_dev = ubyte;
	r_sbyte_wr_dev = 1'b1;
	r_last_sbyte_dev = last;
	@(posedge clk12Mhz)
	#4;
	r_sbyte_dev = 0;
	r_sbyte_wr_dev = 1'b0;
	r_last_sbyte_dev = 1'b0;
end
endtask

endmodule

