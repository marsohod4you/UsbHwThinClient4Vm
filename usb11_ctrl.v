
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
	.data(w_data_result),
	.rdclk(clk),
	.rdreq(data_out_rd),
	.wrclk(clk12Mhz),
	.wrreq(w_data_result_wr),
	.q(data_out),
	.rdempty(w_out_fifo_empty),
	.wrfull()
	);
`endif

wire w_dp_send;
wire w_dm_send;
wire w_bus_ena;
wire w_eof;
wire w_eof_ena;
wire w_sbyte_wr;
reg  [7:0]r_sbyte;
wire w_show_next;
wire w_pkt_end;
wire [10:0]w_ls_bit_time;
wire time_for_new_pkt; assign time_for_new_pkt = (w_ls_bit_time==8);
reg r_time_for_new_pkt;
always @(posedge clk12Mhz)
	r_time_for_new_pkt <= time_for_new_pkt;
wire w_new_pkt_start; assign w_new_pkt_start = ~r_time_for_new_pkt & time_for_new_pkt;

reg r_sbyte_wr;
reg r_last_sbyte;
reg r_channel;
reg r_autoack;
always @(posedge clk12Mhz)
	begin
		r_sbyte_wr <= ((state==STATE_PROCESS_USB11_CMD) & (cmd_usb_byte_out & ~cmd_usb_pkt) ) || (state==STATE_SEND_ACK_80);
		if(state==STATE_PROCESS_USB11_CMD)
		begin
			r_channel <= cmd_channel;
			r_autoack <= cmd_usb_autoack;
		end
		if(state==STATE_PROCESS_USB11_CMD)
			r_last_sbyte <= cmd_usb_last_byte;
	end
assign w_sbyte_wr = r_sbyte_wr || ((state==STATE_WAIT_USB11_SOF) & w_new_pkt_start );

//protocol command is 16 bits, some bits mean per channel control
wire [7:0]cmd_usb_byte;	assign cmd_usb_byte= w_in_fifo_q[7:0];	//bye for send via USB
wire cmd_usb_rst;		assign cmd_usb_rst = w_in_fifo_q[0];	//mean DP/DM both drive low
wire cmd_usb_ena; 		assign cmd_usb_ena = w_in_fifo_q[1];	//mean enable bus SOF/EOP generation

wire cmd_channel;		assign cmd_channel = w_in_fifo_q[8];	//select USB0 or USB1 channel
wire cmd_read_lines;	assign cmd_read_lines = w_in_fifo_q[9];	//used for poll USB lines and detection of attached devices
wire cmd_set_rstena;	assign cmd_set_rstena = w_in_fifo_q[10];	//used for poll USB lines and detection of attached devices
wire cmd_usb_wait_d;	assign cmd_usb_wait_d = w_in_fifo_q[11]; //after this byte sent we expect data from attached device
wire cmd_usb_autoack;	assign cmd_usb_autoack= w_in_fifo_q[12]; //
wire cmd_usb_last_byte;	assign cmd_usb_last_byte= w_in_fifo_q[13];//after this byte sent make EOP
wire cmd_usb_byte_out;	assign cmd_usb_byte_out= w_in_fifo_q[14];//mean actual start of byte transfer
wire cmd_usb_pkt;		assign cmd_usb_pkt = w_in_fifo_q[15];	 //byte transfer starts from new frame

//install low speed USB send module
usb11_send u_usb11_send(
	.rst(reset),
	.clk(clk12Mhz),
	.sbyte(r_sbyte),
	.sbyte_wr(w_sbyte_wr),
	.last_pkt_byte(r_last_sbyte),
	.dp(w_dp_send),
	.dm(w_dm_send),
	.bus_enable(w_bus_ena),
	.show_next(w_show_next),
	.pkt_end(w_pkt_end),
	.ls_bit_time(w_ls_bit_time),
	.eof(w_eof),
	.eof_ena(w_eof_ena)
	);

wire [7:0]w_recv_data;
wire w_recv_data_rdy;
wire w_end_of_recv;
usb11_recv u_usb11_recv(
	.rst(reset),
	.clk(clk12Mhz),
	.dp( r_channel ? usb1_dp_in : usb0_dp_in),
	.dm( r_channel ? usb1_dm_in : usb0_dm_in),
	.enable( ~w_bus_ena ),
	.eop_r(),
	.rdata(w_recv_data),
	.rbyte_cnt(),
	.rdata_ready(w_recv_data_rdy),
	.end_of_recv(w_end_of_recv)
	);
	
//make output for USB signals
assign usb0_dp_out = r_cmd_reset0_eof | (r_cmd_enable0_eof & w_eof) ? 1'b0 : w_dp_send;
assign usb0_dm_out = r_cmd_reset0_eof | (r_cmd_enable0_eof & w_eof) ? 1'b0 : w_dm_send;
assign usb0_out = r_cmd_reset0_eof | (r_cmd_enable0_eof & w_eof_ena) | (r_channel==1'b0 & w_bus_ena);

assign usb1_dp_out = r_cmd_reset1_eof | (r_cmd_enable1_eof & w_eof) ? 1'b0 : w_dp_send;
assign usb1_dm_out = r_cmd_reset1_eof | (r_cmd_enable1_eof & w_eof) ? 1'b0 : w_dm_send;
assign usb1_out = r_cmd_reset1_eof | (r_cmd_enable1_eof & w_eof_ena) | (r_channel==1'b1 & w_bus_ena);

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
	if( state==STATE_PROCESS_USB11_CMD && cmd_set_rstena && cmd_channel==1'b0 )
	begin
		r_cmd_reset0  <= cmd_usb_rst;
		r_cmd_enable0 <= cmd_usb_ena;
	end
	if( state==STATE_PROCESS_USB11_CMD && cmd_set_rstena && cmd_channel==1'b1 )
	begin
		r_cmd_reset1  <= cmd_usb_rst;
		r_cmd_enable1 <= cmd_usb_ena;
	end
	if(w_eof)
	begin
		r_cmd_reset0_eof  <= r_cmd_reset0;
		r_cmd_enable0_eof <= r_cmd_enable0;
		r_cmd_reset1_eof  <= r_cmd_reset1;
		r_cmd_enable1_eof <= r_cmd_enable1;
	end
end

always @(posedge clk12Mhz)
	if(state==STATE_PROCESS_USB11_CMD)
		r_sbyte <= w_in_fifo_q[7:0];
	else
	if(state==STATE_SEND_ACK_80)
		r_sbyte <= 8'h80;
	else
	if(state==STATE_SEND_ACK_D2)
		r_sbyte <= 8'hD2;

assign w_data_result_wr = ((state==STATE_PROCESS_USB11_CMD) & cmd_read_lines) | w_recv_data_rdy;
assign w_data_result = 
		w_recv_data_rdy ? { 8'h00, w_recv_data } : { 12'h000, usb1_dp_in, usb1_dm_in, usb0_dp_in, usb0_dm_in };

localparam STATE_IDLE = 0;
localparam STATE_READ_USB11_CMD = 1;
localparam STATE_PROCESS_USB11_CMD = 2;
localparam STATE_WAIT_USB11_BYTE_SENT = 3;
localparam STATE_WAIT_USB11_SOF = 4;
localparam STATE_WAIT_RDATA = 5;
localparam STATE_SEND_ACK_80 = 6;
localparam STATE_WAIT_SENT_80 = 7;
localparam STATE_SEND_ACK_D2 = 8;
localparam STATE_WAIT_SENT_D2 = 9;

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
			if( cmd_usb_pkt )
				state <= STATE_WAIT_USB11_SOF; //need to wait for new frame start
			else
			if( cmd_usb_byte_out )
				state <= STATE_WAIT_USB11_BYTE_SENT; //write USB byte out
			else
				state <= STATE_IDLE; //read lines of RST/ENA commands are short, so go to idle now
		end
		STATE_WAIT_USB11_SOF: begin
			if( w_new_pkt_start ) //new packet at begin of frame starts here
				state <= STATE_WAIT_USB11_BYTE_SENT;
		end
		STATE_WAIT_USB11_BYTE_SENT: begin
			if( w_show_next || w_pkt_end )
				state <= r_autoack ? STATE_WAIT_RDATA : STATE_IDLE;
		end
		STATE_WAIT_RDATA: begin
			if(w_eof)
				state <= STATE_IDLE; //no data received but frame ended, error..
			else
			if(w_end_of_recv)
				state <= STATE_SEND_ACK_80;
		end
		STATE_SEND_ACK_80: begin
			state <= STATE_WAIT_SENT_80;
		end
		STATE_WAIT_SENT_80: begin
			if( w_show_next  )
				state <= STATE_SEND_ACK_D2;
		end
		STATE_SEND_ACK_D2: begin
			state <= STATE_WAIT_SENT_D2;
		end
		STATE_WAIT_SENT_80: begin
			if( w_pkt_end  )
				state <= STATE_IDLE;
		end
	endcase
end

endmodule
