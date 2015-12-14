
module ftdi(
	input wire  rst,

	input wire  mem_clk,
	input wire  mem_idle,
	input wire  mem_ack,
	input wire  mem_data_next,
	output wire [24:0]mem_wr_addr,
	output reg  mem_wr_req,
	output reg [31:0]mem_wr_data,
	
	input wire  ft_clk,	//from ftdi chip
	input wire  ft_rxf,	//when low , data is available in the FIFO which can be read by driving RD# low
	input wire  ft_txe,	//when low , data can be written into the FIFO by driving WR#
	input wire  [7:0]ft_data, //data from ftdi chip
	output wire ft_oe,
	output wire ft_rd,
	output wire ft_wr
);

localparam STATE_READ_CMD  		= 0;
localparam STATE_READ_CMD_GET  	= 1;
localparam STATE_READ_ADDR 		= 2;
localparam STATE_READ_ADDR_GET 	= 3;
localparam STATE_COPY_BLK_ 		= 4;
localparam STATE_COPY_BLK  		= 5;

assign mem_wr_addr = addr[24:0];
assign ft_wr = 1'b1;

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
reg  [1:0]make_req_sr;
always @(posedge ft_clk or posedge ft_reset)
	if(ft_reset)
		make_req_sr <= 2'b11;
	else
		make_req_sr <= { make_req_sr[0], ~(~ft_rxf & (w_wr_level<2'b11)) };

assign ft_oe = make_req_sr[0];
assign ft_rd = make_req_sr[1];

wire byte_from_ftdi_ready; assign byte_from_ftdi_ready = ~(ft_rxf | ft_rd | ft_oe);
reg _byte_from_ftdi_ready;
always @(posedge ft_clk or posedge ft_reset)
	if(ft_reset)
		_byte_from_ftdi_ready <= 1'b0;
	else
		_byte_from_ftdi_ready <= byte_from_ftdi_ready;

reg [31:0]dword_from_ftdi;
reg [1:0]fifo_bytes_cnt;
wire fifo_wr; assign fifo_wr = (fifo_bytes_cnt == 2'b00) & _byte_from_ftdi_ready;

always @(posedge ft_clk or posedge ft_reset)
	if(ft_reset)
	begin
		dword_from_ftdi <= 0;
		fifo_bytes_cnt  <= 0;
	end
	else
	if(byte_from_ftdi_ready)
	begin
		dword_from_ftdi <= { ft_data, dword_from_ftdi[31:8] };
		fifo_bytes_cnt  <= fifo_bytes_cnt+1;
	end

wire [31:0]w_fifo_outdata;
wire w_fifo_empty;
wire [1:0]w_rd_level;
wire w_read_fifo; assign w_read_fifo = 
	(mem_data_next & suspend_mem_req ) | 
	(mem_ack & mem_wr_req) | 
	((state==STATE_READ_CMD | state==STATE_READ_ADDR) & (~w_fifo_empty) );

always @(posedge mem_clk)
	if(w_read_fifo)
		mem_wr_data <= w_fifo_outdata;

`define  __ICARUS__X 1

//we need fifo for synchronizing FTDI clock to memory clock
`ifdef __ICARUS__X 
generic_fifo_dc_gray #( .dw(32), .aw(4) ) u_ftdi_fifo(
	.rd_clk(mem_clk),
	.wr_clk(ft_clk),
	.rst(~reset),
	.clr(),
	.din(dword_from_ftdi),
	.we(fifo_wr),
	.dout(w_fifo_outdata),
	.re(w_read_fifo),
	.full(),
	.empty(w_fifo_empty),
	.wr_level(w_wr_level),
	.rd_level(w_rd_level)
	);
`else
//Quartus native FIFO;
wire [3:0]w_rdusedw;
wire [3:0]w_wrusedw;
wrfifo u_wrfifo(
	.aclr(reset),
	.data(dword_from_ftdi),
	.rdclk(mem_clk),
	.rdreq(w_read_fifo),
	.wrclk(ft_clk),
	.wrreq(fifo_wr),
	.q(w_fifo_outdata),
	.rdempty(w_fifo_empty),
	.rdusedw(w_rdusedw),
	.wrusedw(w_wrusedw)
	);
assign w_wr_level = w_wrusedw[3:2];
assign w_rd_level = w_wrusedw[3:2] ^ 2'b11;
`endif

reg [15:0]byte_counter;

reg [7:0]state;

reg  [31:0]cmd;
wire [7:0]len; assign len = cmd[7:0];
always @(posedge mem_clk)
	if( state==STATE_READ_CMD_GET )
		cmd  <= w_fifo_outdata;

reg [31:0]addr;
always @(posedge mem_clk)
	if( state==STATE_READ_ADDR_GET )
		addr <= w_fifo_outdata;
	else
	if( state==STATE_COPY_BLK && mem_ack )
		addr <= addr + 4;
		
reg [7:0]wr_data_cnt;
always @(posedge mem_clk)
	if( state==STATE_READ_ADDR )
		wr_data_cnt <= 0;
	else
	if( state==STATE_COPY_BLK & mem_data_next )
		wr_data_cnt <= wr_data_cnt + 1;

reg suspend_mem_req;
always @(posedge mem_clk)
	if( state==STATE_READ_ADDR || wr_data_cnt[1:0]==2'b11 )
		suspend_mem_req <= 1'b0;
	else
	if( mem_wr_req & mem_ack )
		suspend_mem_req <= 1'b1;
		
always @(posedge mem_clk)
	if( state==STATE_COPY_BLK )
		mem_wr_req <= mem_idle & (w_rd_level!=2'b11) & (len!=0) & (~mem_ack) & (~suspend_mem_req) & (wr_data_cnt!=len) & (wr_data_cnt!=(len-1));
	else
		mem_wr_req <= 1'b0;

always @(posedge mem_clk or posedge reset)
	if(reset)
	begin
		state <= STATE_READ_CMD;
	end
	else
	case(state)
		STATE_READ_CMD: begin
			if(~w_fifo_empty)
				state <= STATE_READ_CMD_GET;
			end
		STATE_READ_CMD_GET: begin
				state <= STATE_READ_ADDR;
			end
		STATE_READ_ADDR: begin
			if(~w_fifo_empty)
				state <= STATE_READ_ADDR_GET;
			end
		STATE_READ_ADDR_GET: begin
				state <= STATE_COPY_BLK_;
			end
		STATE_COPY_BLK_: begin
				state <= STATE_COPY_BLK;
			end
		STATE_COPY_BLK: begin
			if(wr_data_cnt==len)
				state <= STATE_READ_CMD;
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
		else
			out_addr <= 0;
		
reg clk_60Mhz = 1'b0;
always
	#8.33 clk_60Mhz = ~clk_60Mhz;
assign ft_clk = clk_60Mhz;

integer i;
reg [7:0]ftdi_test_content[0:255];
initial
begin
	//fill ftdi initial content with some data
	ftdi_test_content[0] = 8; //CMD&LEN
	ftdi_test_content[1] = 0;
	ftdi_test_content[2] = 0;
	ftdi_test_content[3] = 0;
	
	ftdi_test_content[4] = 16; //WR ADDRESS
	ftdi_test_content[5] = 0;
	ftdi_test_content[6] = 0;
	ftdi_test_content[7] = 0;
	
	for(i=0; i<32; i=i+1)
	begin
		ftdi_test_content[i+8]  = i; //DATA
	end
end

endmodule
`endif
