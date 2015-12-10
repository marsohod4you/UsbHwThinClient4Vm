
module ftdi(
	input wire  reset,

	input wire  mem_clk,
	input wire  mem_idle,
	input wire  mem_ack,
	input wire  mem_data_next,
	output wire [24:0]mem_wr_addr,
	output reg  mem_wr_req,
	output wire [31:0]mem_wr_data,
	
	input wire  ft_clk,	//from ftdi chip
	input wire  ft_rxf,	//when low , data is available in the FIFO which can be read by driving RD# low
	input wire  ft_txe,	//when low , data can be written into the FIFO by driving WR#
	input wire  [7:0]ft_data, //data from ftdi chip
	output wire ft_oe,
	output wire ft_rd,
	output wire ft_wr	
);

assign mem_wr_data = w_fifo_outdata;
assign mem_wr_addr = addr[24:0];
assign ft_wr = 1'b1;

//resynchronize reset (mem clk) to ft_clk
reg [1:0]ft_reset_sr;
wire ft_reset; assign ft_reset = ft_reset_sr[1]; 
always @(posedge ft_clk)
	ft_reset_sr <= { ft_reset_sr[0],reset };
	
wire [1:0]w_wr_level;

//think to read from FTDI if it has data AND our FIFO is not full
reg  [1:0]make_req_sr;
always @(posedge ft_clk or posedge ft_reset)
	if(reset)
		make_req_sr <= 2'b11;
	else
		make_req_sr <= { make_req_sr[0], ~(~ft_rxf & (w_wr_level<2'b11)) };

assign ft_oe = make_req_sr[0];
assign ft_rd = make_req_sr[1];

wire byte_from_ftdi_ready; assign byte_from_ftdi_ready = ~(ft_rxf | ft_rd);

reg [31:0]dword_from_ftdi;
reg [1:0]fifo_bytes_cnt;
wire fifo_wr; assign fifo_wr = (fifo_bytes_cnt == 2'b11);

always @(posedge ft_clk or posedge ft_reset)
	if(ft_reset)
	begin
		dword_from_ftdi <= 0;
		fifo_bytes_cnt  <= 0;
	end
	else
	if(byte_from_ftdi_ready)
	begin
		dword_from_ftdi <= { dword_from_ftdi[23:0], ft_data };
		fifo_bytes_cnt  <= fifo_bytes_cnt+1;
	end

wire [31:0]w_fifo_outdata;
wire w_fifo_empty;
wire [1:0]w_rd_level;

//we need fifo for synchronizing FTDI clock to memory clock
`ifdef __ICARUS__ 
generic_fifo_dc_gray #( .dw(32), .aw(4) ) u_ftdi_fifo(
	.rd_clk(mem_clk),
	.wr_clk(ft_clk),
	.rst(~reset),
	.clr(),
	.din(dword_from_ftdi),
	.we(fifo_wr),
	.dout(w_fifo_outdata),
	.re(mem_data_next),
	.full(),
	.empty(w_fifo_empty),
	.wr_level(w_wr_level),
	.rd_level(w_rd_level)
	);
`else
//Quartus native FIFO;
`endif

reg [15:0]byte_counter;

localparam STATE_READ_CMD  = 0;
localparam STATE_READ_ADDR = 1;
localparam STATE_COPY_BLK  = 2;

reg [7:0]state;

reg  [31:0]cmd;
wire [7:0]len; assign len = cmd[7:0];
always @(posedge mem_clk)
	if( state==STATE_READ_CMD && ~w_fifo_empty )
		cmd  <= w_fifo_outdata;

reg [31:0]addr;
always @(posedge mem_clk)
	if( state==STATE_READ_ADDR && ~w_fifo_empty )
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
	
always @(posedge mem_clk)
	if( state==STATE_COPY_BLK )
		mem_wr_req <= mem_idle & (w_rd_level!=0) & (len!=0);
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
				state <= STATE_READ_ADDR;
			end
		STATE_READ_ADDR: begin
			if(~w_fifo_empty)
				state <= STATE_COPY_BLK;
			end
		STATE_COPY_BLK: begin
			if(wr_data_cnt==len)
				state <= STATE_READ_CMD;
			end
	endcase

endmodule
