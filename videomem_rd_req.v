

//////////////////////////////////////////////////////////
//module which generates video memory read requests
//////////////////////////////////////////////////////////

module videomem_rd_req(
	// inputs synchronous to mem_clock:
	input wire mem_clock,
	input wire mem_ready,
	input wire rdata_valid,
	input wire [1:0]fifo_level,
	
	// inputs synchronous to pixel_clock
	input wire hsync,
	input wire vsync,

	// pins synchronous to mem_clock:
	input wire read_req_ack,
	output reg read_request,
	output wire [24:0]read_addr
	);

parameter THRESHOLD_HIGH = 2'b11;
parameter THRESHOLD_LOW  = 2'b01;
parameter MAX_NUM_HREAD  = 160; /* 1280 pixels / 8 burst words = 160 burst requests */
parameter LINE_NUM  	 = 720;

//resynchronize vsync from pixel clock to memory clock
reg [3:0]vsync_shift;
always @(posedge mem_clock)
	vsync_shift <= { vsync_shift[2:0], vsync };
wire _vsync; assign _vsync = (vsync_shift[3:2]==2'b10);

reg [8:0]num_hread=0;
reg [12:0]num_lines=0;
assign read_addr =  { num_lines, num_hread, 3'b000 };

//check FIFO level and decide to feed
reg fifo_need_feed; 
always @(posedge mem_clock)
	if(fifo_level<=THRESHOLD_LOW)
		fifo_need_feed <= 1'b1;
	else
	if(fifo_level>=THRESHOLD_HIGH)
		fifo_need_feed <= 1'b0;
	
wire end_of_screen;  assign end_of_screen  = (num_lines==LINE_NUM-1);
	
always @(posedge mem_clock)
begin
	read_request <= (mem_ready && fifo_need_feed && ~end_of_screen );
end

always @(posedge mem_clock)
	if(_vsync)
	begin
		//start reading frame buffer from zero address
		num_hread <= 0;
		num_lines <= 0;
	end
	else
	if(read_request && read_req_ack)
	begin
		num_hread <= (num_hread==MAX_NUM_HREAD-1) ? 0 : num_hread+1'b1;
		num_lines <= (num_hread==MAX_NUM_HREAD-1) ? num_lines+1'b1 : num_lines;
	end

endmodule
