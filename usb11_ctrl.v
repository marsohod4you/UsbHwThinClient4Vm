
module usb11_ctrl(
	input wire reset,
	input wire clk_60Mhz,
	
	//USB11 data and control signals
	input  wire usb0_dp_in,
	input  wire usb0_dm_in,
	output wire usb0_dp_out,
	output wire usb0_dm_out,
	output wire usb0_out,
	input  wire usb1_dp_in,
	input  wire usb1_dm_in,
	output wire usb1_dp_out,
	output wire usb1_dm_out,
	output wire usb1_out,
	
	input wire clk,
	input wire [15:0]data_in,
	input wire data_in_wr,
	input wire data_out_rd,
	output wire [15:0]data_out,
	output wire data_out_rdy
);

//divide input 60Mhz on 5 to get 12MHz clock we need for USB11
reg [2:0]div5=0;
always @( posedge clk_60Mhz )
	if(div5==3'b100)
		div5<=0;
	else
		div5<=div5+1;
		
wire clk12Mhz; assign clk12Mhz = div5[2];


//install input fifo for incoming USB11 commands
wire w_in_fifo_rd; assign w_in_fifo_rd = (state==STATE_READ_USB11_CMD);
wire w_in_fifo_empty;
wire w_out_fifo_empty;
wire [15:0]w_in_fifo_q;
wire [15:0]w_data_result;
wire w_data_result_wr;

assign data_out_rdy = ~w_out_fifo_empty;

//install output fifo for USB11 operation results

`ifdef __ICARUS__

//icarus debug purposes FIFOs here
generic_fifo_dc_gray #( .dw(16), .aw(5) ) u_usb11fifo_in(
	.rst(~reset),
	.rd_clk(clk12Mhz),
	.wr_clk(clk),
	.clr(),
	.din(data_in),
	.we(data_in_wr),
	.dout(w_in_fifo_q),
	.rd(w_in_fifo_rd),
	.full(),
	.empty(w_in_fifo_empty),
	.wr_level(),
	.rd_level()
	);
generic_fifo_dc_gray #( .dw(16), .aw(5) ) u_usb11fifo_out(
	.rst(~reset),
	.rd_clk(clk),
	.wr_clk(clk12Mhz),
	.clr(),
	.din(w_data_result),
	.we(w_data_result_wr),
	.dout(data_out),
	.rd(data_out_rd),
	.full(),
	.empty(w_out_fifo_empty),
	.wr_level(),
	.rd_level()
	);
`else
//native quartus FIFOs are here
usb11fifo u_usb11fifo_in(
	.aclr(reset),
	.data(data_in),
	.rdclk(clk12Mhz),
	.rdreq(w_in_fifo_rd),
	.wrclk(clk),
	.wrreq(data_in_wr),
	.q(w_in_fifo_q),
	.rdempty(w_in_fifo_empty),
	.wrfull()
	);
	
usb11fifo u_usb11fifo_out(
	.aclr(reset),
	.data(),
	.rdclk(clk),
	.rdreq(),
	.wrclk(clk12Mhz),
	.wrreq(),
	.q(),
	.rdempty(),
	.wrfull()
	);
`endif

wire w_dp_send;
wire w_dm_send;
wire w_bus_ena;
wire w_eof;
wire w_sbyte_wr;
wire w_show_next;
assign w_sbyte_wr = (state==STATE_PROCESS_USB11_CMD) & cmd_start_pkt;

//install low speed USB send module
usb11_send u_usb11_send(
	.rst(reset),
	.clk(clk12Mhz),
	.sbyte(w_in_fifo_q[7:0]),
	.sbyte_wr(w_sbyte_wr),
	.last_pkt_byte(1'b0),
	.dp(w_dp_send),
	.dm(w_dm_send),
	.bus_enable(w_bus_ena),
	.show_next(w_show_next),
	.pkt_end(),
	.eof(w_eof)
	);

//make output for USB signals
assign usb0_dp_out = r_cmd_reset0_eof ? 1'b0 : 1'bx;
assign usb0_dm_out = r_cmd_reset0_eof ? 1'b0 : 1'bx;
assign usb0_out = r_cmd_reset0_eof;

//protocol command is 16 bits, some bits mean per channel control
wire cmd_reset0; 		assign cmd_reset0  = w_in_fifo_q[8];
wire cmd_enable0; 	assign cmd_enable0 = w_in_fifo_q[9];
wire cmd_reset1; 		assign cmd_reset1  = w_in_fifo_q[10];
wire cmd_enable1; 	assign cmd_enable1 = w_in_fifo_q[11];
wire cmd_read_lines; assign cmd_read_lines = w_in_fifo_q[12];
wire cmd_channel; 	assign cmd_channel = w_in_fifo_q[13];
wire cmd_start_pkt; 	assign cmd_start_pkt = w_in_fifo_q[15];

reg r_cmd_reset0 =1'b0;
reg r_cmd_enable0=1'b0;
reg r_cmd_reset1 =1'b0;
reg r_cmd_enable1=1'b0;

//reset / enable aligned to 1ms frame (ls EOF)
reg r_cmd_reset0_eof =1'b0;
reg r_cmd_enable0_eof=1'b0;
reg r_cmd_reset1_eof =1'b0;
reg r_cmd_enable1_eof=1'b0;

always @(posedge clk12Mhz)
begin
	if(state==STATE_PROCESS_USB11_CMD)
	begin
		r_cmd_reset0  <= cmd_reset0;
		r_cmd_enable0 <= cmd_enable0;
		r_cmd_reset1  <= cmd_reset1;
		r_cmd_enable1 <= cmd_enable1;
	end
	if(w_eof)
	begin
		r_cmd_reset0_eof  <= r_cmd_reset0;
		r_cmd_enable0_eof <= r_cmd_enable0;
		r_cmd_reset1_eof  <= r_cmd_reset1;
		r_cmd_enable1_eof <= r_cmd_enable1;
	end
end

assign w_data_result_wr = (state==STATE_PROCESS_USB11_CMD) & cmd_read_lines;
assign w_data_result = 
		w_data_result_wr ? { 12'h000, usb1_dp_in, usb1_dm_in, usb0_dp_in, usb0_dm_in } : 16'h0000;

localparam STATE_IDLE = 0;
localparam STATE_READ_USB11_CMD = 1;
localparam STATE_PROCESS_USB11_CMD = 2;

reg [7:0]state = STATE_IDLE;


always @(posedge clk12Mhz)
begin
	case(state)
		STATE_IDLE: begin
			if(~w_in_fifo_empty)
				state <= STATE_READ_USB11_CMD;
		end
		STATE_READ_USB11_CMD: begin
				state <= STATE_PROCESS_USB11_CMD;
		end
		STATE_PROCESS_USB11_CMD: begin
			if( cmd_start_pkt )
				state <= w_show_next ? STATE_IDLE : STATE_PROCESS_USB11_CMD;
			else
				state <= STATE_IDLE;
		end
	endcase
end

endmodule
