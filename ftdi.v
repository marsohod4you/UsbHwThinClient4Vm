
module ftdi(
	input wire  rst,

	input wire  mem_clk,
	input wire  mem_idle,
	input wire  mem_ack,
	input wire  mem_data_next,
	output wire [24:0]mem_wr_addr,
	output reg  mem_wr_req,
	output wire [15:0]mem_wr_data,
	
	input wire  ft_clk,	//from ftdi chip
	input wire  ft_rxf,	//when low , data is available in the FIFO which can be read by driving RD# low
	input wire  ft_txe,	//when low , data can be written into the FIFO by driving WR#
	input wire  [7:0]ft_data, //data from ftdi chip
	output wire ft_oe,
	output wire ft_rd,
	output wire ft_wr,
	output wire dbg
);

localparam CMD_SIGNATURE		= 16'hAA55;
localparam STATE_READ_CMD_BYTE	= 0;
localparam STATE_READ_ADDR_BYTE	= 1;
localparam STATE_READ_PIX_BYTE 	= 2;
localparam STATE_COPY_BLK 		= 3;

assign mem_wr_addr = addr[24:0];
assign mem_wr_data = wr_word;
assign ft_wr = 1'b1;
assign dbg = (wr_data_cnt>8);

reg [2:0]_rst;
always @(posedge mem_clk)
	_rst <= { _rst[1:0], rst };

wire reset = _rst[2];

//resynchronize reset (mem clk) to ft_clk
reg [1:0]ft_reset_sr;
wire ft_reset; assign ft_reset = ft_reset_sr[1]; 
always @(posedge ft_clk)
	ft_reset_sr <= { ft_reset_sr[0],reset };
	
wire [1:0]w_wr_level;

//think to read from FTDI if it has data AND our FIFO is not full
wire fifo_has_space;
reg  [1:0]make_req_sr;
always @(posedge ft_clk or posedge ft_reset)
	if(ft_reset)
		make_req_sr <= 2'b11;
	else
		make_req_sr <= { make_req_sr[0], ~( (~ft_rxf) & fifo_has_space) };

assign ft_oe = make_req_sr[0];
assign ft_rd = make_req_sr[1];
wire   fifo_wr; assign fifo_wr = ~(ft_rxf | ft_rd /*| ft_oe*/);

wire [7:0]w_fifo_outdata;
wire w_fifo_empty;
wire [1:0]w_rd_level;
wire w_read_fifo; assign w_read_fifo =  
	(w_read_addr_byte | w_read_pix_byte | w_read_cmd_byte );

//we need fifo for synchronizing FTDI clock to memory clock
`ifdef __ICARUS__
generic_fifo_dc_gray #( .dw(8), .aw(4) ) u_ftdi_fifo(
	.rst(~reset),
	.rd_clk(mem_clk),
	.wr_clk(ft_clk),
	.clr(),
	.din(ft_data),
	.we(fifo_wr),
	.dout(w_fifo_outdata),
	.rd(w_read_fifo),
	.full(),
	.empty(w_fifo_empty),
	.wr_level(w_wr_level),
	.rd_level(w_rd_level)
	);
assign fifo_has_space = (w_wr_level<2'b11);
`else
//Quartus native FIFO;
wire [8:0]w_rdusedw;
wire [8:0]w_wrusedw;
wrfifo u_wrfifo(
	.aclr(reset),
	.data(ft_data),
	.rdclk(mem_clk),
	.rdreq(w_read_fifo),
	.wrclk(ft_clk),
	.wrreq(fifo_wr),
	.q(w_fifo_outdata),
	.rdempty(w_fifo_empty),
	.rdusedw(w_rdusedw),
	.wrusedw(w_wrusedw)
	);
assign fifo_has_space = (w_wrusedw<500);
`endif

reg [7:0]state;

//fetching command (4 bytes) from FIFO
reg  [31:0]cmd=0;
wire w_read_cmd_byte; assign w_read_cmd_byte = ~w_fifo_empty & (state==STATE_READ_CMD_BYTE) & ~sign_ok & mem_idle;
reg  r_read_cmd_byte;
wire [15:0]cmd_sign; assign cmd_sign = { w_fifo_outdata,cmd[31:24] }; //expect signature in hi-word
wire sign_ok; assign sign_ok = (cmd_sign==CMD_SIGNATURE && r_read_cmd_byte );
wire [15:0]len; 	 assign len = cmd[15:0];
always @(posedge mem_clk)
begin
	r_read_cmd_byte <= w_read_cmd_byte;
	if( r_read_cmd_byte )
		cmd  <= { w_fifo_outdata, cmd[31:8]};
end

//fetching address from FIFO
reg [31:0]addr = 0;
//count fetched address bytes (need 4 bytes)
reg [1:0]num_addr_bytes = 0;
always @(posedge mem_clk)
	if( r_read_addr_byte )
		num_addr_bytes <= num_addr_bytes + 1;
	else
	if( state==STATE_READ_CMD_BYTE )
		num_addr_bytes <= 2'b00;

//fetch address byte
wire w_read_addr_byte; assign w_read_addr_byte = ~w_fifo_empty & (state==STATE_READ_ADDR_BYTE) & ~addr_ok;
reg  r_read_addr_byte = 1'b0;
wire addr_ok; assign addr_ok = (num_addr_bytes==2'b11 && r_read_addr_byte );
always @(posedge mem_clk)
begin
	r_read_addr_byte <= w_read_addr_byte;
	if( r_read_addr_byte )
		addr <= { w_fifo_outdata, addr[31:8]};
	else
	if( state==STATE_COPY_BLK && mem_ack )
		addr <= addr + 1;
end

//fetching pixel DWORD from FIFO
reg [15:0]pixel = 0;
//count fetched pixel bytes (need 4 bytes)
reg num_pix_bytes = 1'b0;
always @(posedge mem_clk)
	if( r_read_pix_byte )
		num_pix_bytes <= num_pix_bytes + 1;
	else
	if( state==STATE_READ_ADDR_BYTE )
		num_pix_bytes <= 1'b0;

//fetch pixels byte
wire w_read_pix_byte; assign w_read_pix_byte = ~w_fifo_empty & (state==STATE_READ_PIX_BYTE) & ~pixel_ok;
reg  r_read_pix_byte = 1'b0;
wire pixel_ok; assign pixel_ok = (num_pix_bytes==1'b1 && r_read_pix_byte);
always @(posedge mem_clk)
begin
	r_read_pix_byte <= w_read_pix_byte;
	if( r_read_pix_byte )
		pixel <= { w_fifo_outdata, pixel[15:8]};
end

reg [7:0]wr_data_cnt = 0;
always @(posedge mem_clk)
	if( state==STATE_READ_ADDR_BYTE )
		wr_data_cnt <= 0;
	else
	if( write_accepted )
		wr_data_cnt <= wr_data_cnt + 1;

always @(posedge mem_clk or posedge reset)
	if(reset)
		mem_wr_req <= 1'b0;
	else
	if(mem_ack)
		mem_wr_req <= 1'b0;
	else
	if(pixel_ok)
		mem_wr_req <= 1'b1;
	
reg [15:0]wr_word = 0;	
wire write_accepted; assign write_accepted = mem_ack & mem_wr_req;
always @(posedge mem_clk)
	if(write_accepted)
		wr_word <= pixel;

always @(posedge mem_clk or posedge reset)
	if(reset)
	begin
		state <= STATE_READ_CMD_BYTE;
	end
	else
	case(state)
		STATE_READ_CMD_BYTE: begin
			if(sign_ok)
				state <= STATE_READ_ADDR_BYTE;
			end
		STATE_READ_ADDR_BYTE: begin
			if(addr_ok)
				state <= STATE_READ_PIX_BYTE;
			end
		STATE_READ_PIX_BYTE: begin
			if(pixel_ok)
				state <= STATE_COPY_BLK;
			end
		STATE_COPY_BLK: begin
			if( write_accepted )
				state <= (wr_data_cnt==len-1) ? STATE_READ_CMD_BYTE : STATE_READ_PIX_BYTE;
			end
	endcase

endmodule

`ifdef __ICARUS__ 
//FTDI chip emulator for testbench 
module ftdi_emu(
	input  wire start_emu,
	output wire ft_clk,
	output wire ft_rxf,
	inout  wire [7:0]ft_d,
	input  wire ft_oe,
	input  wire ft_rd,
	input  wire ft_wr
);

reg [7:0]out_addr = 0;
assign ft_rxf = ~(out_addr<40 & start_emu);

assign ft_d = ~ft_oe ? ftdi_test_content[out_addr] : 8'hzz;

always @(posedge clk_60Mhz)
	if( ~ft_oe & ~ft_rd )
		if(out_addr<39)
			out_addr <= out_addr + 1;
		//else
			//out_addr <= 0;
		
reg clk_60Mhz = 1'b0;
always
	#8.33 clk_60Mhz = ~clk_60Mhz;
assign ft_clk = clk_60Mhz;

integer i;
reg [7:0]ftdi_test_content[0:255];
initial
begin
	//fill ftdi initial content with some data
	ftdi_test_content[0] = 128; //CMD&LEN
	ftdi_test_content[1] = 0;
	ftdi_test_content[2] = 8'h55;
	ftdi_test_content[3] = 8'hAA;
	
	ftdi_test_content[4] = 16; //WR ADDRESS
	ftdi_test_content[5] = 200;
	ftdi_test_content[6] = 0;
	ftdi_test_content[7] = 0;
	
	for(i=0; i<128+8; i=i+1)
	begin
		ftdi_test_content[i+8]  = i; //DATA
	end
end

endmodule
`endif
