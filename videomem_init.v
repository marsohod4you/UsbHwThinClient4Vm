
module videomem_init(
	input wire mem_clock,
	input wire mem_ready,
	input wire mem_req_ack,
	input wire give_next_data,

	output reg wr_request,
	output wire [24:0]wr_addr,
	output wire [31:0]wr_data,
	output reg complete
	);

parameter NUM_HORZ_WR_REQ = 32;
parameter NUM_WR_LINES = 720;

reg [3:0]mem_ready_delay = 0;
always @(posedge mem_clock)
		mem_ready_delay <= { mem_ready_delay[2:0],mem_ready };
wire mem_ready_d; assign mem_ready_d = mem_ready_delay[3];

always @(posedge mem_clock)
	//complete <= mem_ready;
	if( ~mem_ready)
		complete <= 1'b0;
	else
		complete <= (nline==NUM_WR_LINES);

reg [9:0]nreq;
reg [12:0]nline;

always @(posedge mem_clock)
	if( ~mem_ready)
	begin
		nreq <= 0;
		nline <= 0;
	end
	else
	if( wr_request & mem_req_ack )
	begin
		if( nreq==(NUM_HORZ_WR_REQ-1) )
			nline <= nline + 1;
		if( nreq==(NUM_HORZ_WR_REQ-1) )
			nreq  <= 0;
		else
			nreq  <= nreq+1;
	end

assign wr_addr = { nline , nreq, 2'b00 };

reg [1:0]num_data = 0;
reg wr_started;
always @(posedge mem_clock)
	if(~mem_ready)
		wr_request <= 1'b0;
	else
	if(mem_req_ack)
		wr_request <= 1'b0;
	else
	if( mem_ready_d & ~complete & num_data==0 & ~wr_started )
		wr_request <= 1'b1;

always @(posedge mem_clock)
	if(~mem_ready)
		wr_started <= 1'b0;
	else
	if( mem_ready_d & ~complete & num_data==0 & ~wr_started )
		wr_started <= 1'b1;
	else
	if(num_data)
		wr_started <= 1'b0;

always @(posedge mem_clock)
	if( ~mem_ready)
		num_data <= 0;
	else
	if(give_next_data)
		num_data <= num_data+1;

reg [5:0]data_h;
reg [1:0]data_l;
always @(posedge mem_clock)
	if( wr_request && mem_req_ack )
	begin
		data_h <= nreq[5:0];
		data_l <= 2'b00;
	end
	else
	if(give_next_data)
		data_l <= data_l+1;

wire [7:0]data; assign data = { data_h, data_l };
wire [2:0]x3; assign x3 = data[7:5];
wire [4:0]r; assign r = x3[2] ? data[4:0] : 0;
wire [5:0]g; assign g = x3[1] ? {data[4:0],1'b0} : 0;
wire [4:0]b; assign b = x3[0] ? data[4:0] : 0;
assign wr_data = (x3==3'b000) ? 32'hFFFFFFFF : {r,g,b,r,g,b};

endmodule

