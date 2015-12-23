
module top 
		(
		input wire CLK100MHZ,
		output wire [7:0]LED,

`ifdef HDMI
		//HDMI output
		output wire [7:0]TMDS,
`else
		//VGA output
		output reg VGA_HSYNC,
		output reg VGA_VSYNC,
		output wire [4:0]VGA_BLUE,
		output wire [5:0]VGA_GREEN,
		output wire [4:0]VGA_RED,
`endif
	
		/* Interface to SDRAM chip  */
		output wire SDRAM_CLK,
`ifdef __ICARUS__ 
		output wire SDRAM_CKE,		// SDRAM CKE
		output wire SDRAM_CS,		// SDRAM Chip Select
`endif
		output wire SDRAM_RAS,		// SDRAM ras
		output wire SDRAM_CAS,		// SDRAM cas
		output wire SDRAM_WE,		// SDRAM write enable
		output wire [1:0]SDRAM_DQM, // SDRAM Data Mask
		output wire [1:0]SDRAM_BA,	// SDRAM Bank Enable
		output wire [11:0]SDRAM_A,	// SDRAM Address
		inout  wire [15:0]SDRAM_DQ, // SDRAM Data Input/output		            

		input wire ft_clk,
		input wire ft_rxf,
		input wire ft_txe,
		inout wire [7:0]ft_d,
		output wire ft_rd,
		output wire ft_wr,
		output wire ft_oe,
		
		input wire KEY0,
		input wire KEY1
	   );

//--------------------------------------------
// appliciation to SDRAM controller Interface 
//--------------------------------------------
wire app_rd_req;					// SDRAM request
wire [24:0]app_req_addr;		// SDRAM Request Address
wire [15:0]app_wr_data;		// sdr write data
wire app_req_ack;				// SDRAM request Accepted
wire app_busy_n;				// 0 -> sdr busy
wire app_wr_next_req;			// Ready to accept the next write
wire app_rd_valid;				// sdr read valid
wire app_last_rd;				// Indicate last Read of Burst Transfer
wire app_last_wr;				// Indicate last Write of Burst Transfer
wire [15:0]app_rd_data;			// sdr read data
wire w_wr_req;
wire [24:0]w_wr_addr;

wire [15:0]sdr_dout;
wire [1:0]sdr_den_n;
assign SDRAM_DQ[7:0]  = (sdr_den_n[0] == 1'b0) ? sdr_dout[7:0]  : 8'hZZ;
assign SDRAM_DQ[15:8] = (sdr_den_n[1] == 1'b0) ? sdr_dout[15:8] : 8'hZZ; 

wire [15:0]pad_sdr_din; assign pad_sdr_din = SDRAM_DQ;

wire w_sdr_init_done;
wire w_reset;
wire w_video_clk;
wire w_video_clk5;
wire w_mem_clk;

//instance of clock generator
clocks u_clocks(
	.clk_100Mhz(CLK100MHZ),
	.reset(w_reset),
	.mem_clk(w_mem_clk),
	.video_clk(w_video_clk),
	.video_clk5(w_video_clk5)
	);

//output memory clock	
assign SDRAM_CLK = w_mem_clk;

//instance of SDR controller core
sdrc_core #( .APP_DW(16), .APP_BW(2), .SDR_DW(16), .SDR_BW(2) )
	u_sdrc_core (
		.clk                (w_mem_clk		),
		.reset_n            (~w_reset			),
		.pad_clk            (w_mem_clk		),

		/* Request from app */
		.app_req            (app_rd_req | w_wr_req ),// Transfer Request
		.app_req_addr       (app_rd_req ? app_req_addr : w_wr_addr ), // SDRAM Address
		.app_req_len        (app_rd_req ? 9'd008 : 9'd001		   ), // Burst Length
		.app_req_wrap       (1'b1				),// Wrap mode request 
		.app_req_wr_n       (app_rd_req 		),// 0 => Write request, 1 => read req
		.app_req_ack        (app_req_ack		),// Request has been accepted
 		
		.app_wr_data        (app_wr_data		),
		.app_wr_en_n        (2'b00				),
		.app_rd_data        (app_rd_data		),
		.app_rd_valid       (app_rd_valid		),
		.app_last_rd        (app_last_rd		),
		.app_last_wr        (app_last_wr		),
		.app_wr_next_req    (app_wr_next_req),
		.app_req_dma_last   (app_rd_req			),
 
		/* Interface to SDRAMs */
`ifdef __ICARUS__ 
		.sdr_cs_n           (SDRAM_CS		),
		.sdr_cke            (SDRAM_CKE		),
`else
		.sdr_cs_n           (),
		.sdr_cke            (),
`endif
		.sdr_ras_n          (SDRAM_RAS		),
		.sdr_cas_n          (SDRAM_CAS		),
		.sdr_we_n           (SDRAM_WE		),
		.sdr_dqm            (SDRAM_DQM		),
		.sdr_ba             (SDRAM_BA		),
		.sdr_addr           (SDRAM_A		),
		.pad_sdr_din        (pad_sdr_din	),
		.sdr_dout           (sdr_dout		),
		.sdr_den_n          (sdr_den_n		),
 
		.sdr_init_done      (w_sdr_init_done),

		/* Parameters */
		.sdr_width			(2'b01 ),
		.cfg_colbits        (2'b00              ), //2'b00 means 8 Bit Column Address
		.cfg_req_depth      (2'h3               ), //how many req. buffer should hold
		.cfg_sdr_en         (1'b1               ),
		.cfg_sdr_mode_reg   (12'h223            ), //single location write, 8 words read
		.cfg_sdr_tras_d     (4'h4               ), //SDRAM active to precharge, specified in clocks
		.cfg_sdr_trp_d      (4'h2               ), //SDRAM precharge command period (tRP), specified in clocks.
		.cfg_sdr_trcd_d     (4'h2               ), //SDRAM active to read or write delay (tRCD), specified in clocks.
		.cfg_sdr_cas        (3'h3               ), //cas latency in clocks, depends on mode reg
		.cfg_sdr_trcar_d    (4'h7               ), //SDRAM active to active / auto-refresh command period (tRC), specified in clocks.
		.cfg_sdr_twr_d      (4'h1               ), //SDRAM write recovery time (tWR), specified in clocks
		.cfg_sdr_rfsh       (12'h100            ), //Period between auto-refresh commands issued by the controller, specified in clocks.
		.cfg_sdr_rfmax      (3'h6               )  //Maximum number of rows to be refreshed at a time(tRFSH)
	);

wire w_hsync;
wire w_vsync;
wire w_active;
wire [11:0]w_pixel_count;
wire [11:0]w_line_count;

hvsync u_hvsync(
	.reset(~w_sdr_init_done), //start video synch only when memory is ready
	.pixel_clock(w_video_clk),

	.hsync(w_hsync),
	.vsync(w_vsync),
	.active(w_active),

	.pixel_count(w_pixel_count),
	.line_count(w_line_count),
	.dbg( LED[0] )
	);

wire [1:0]w_wr_level;

//instance of video memory reader
videomem_rd_req u_videomem_rd_req(
	.mem_clock(w_mem_clk),
	.mem_ready(w_sdr_init_done ),
	.rdata_valid(),
	.fifo_level(w_wr_level),
	.hsync(w_hsync),
	.vsync(w_vsync),
	.read_req_ack(app_req_ack & app_rd_req),
	.read_request(app_rd_req),
	.read_addr(app_req_addr)
	);

/*
videomem_init u_videomem_init(
	.mem_clock( w_mem_clk ),
	.mem_ready( w_sdr_init_done ),
	.mem_req_ack( app_req_ack ),
	.give_next_data( app_wr_next_req ),

	.wr_request( w_wr_req ),
	.wr_addr( w_wr_addr ),
	.wr_data( app_wr_data ),
	.complete( w_complete )
	);
*/
wire w_ft_dbg;

ftdi u_ftdi(
	.rst( (~w_sdr_init_done) | (~(KEY0&KEY1))),
	.mem_clk(w_mem_clk),
	.mem_idle(~app_rd_req),
	.mem_ack(app_req_ack & (~app_rd_req) ),
	.mem_data_next(app_wr_next_req),
	.mem_wr_addr(w_wr_addr),
	.mem_wr_req(w_wr_req),
	.mem_wr_data(app_wr_data),
	.ft_clk( ft_clk ),
	.ft_rxf( ft_rxf ),
	.ft_txe( ft_tfx ),
	.ft_data(ft_d ),
	.ft_oe(  ft_oe ),
	.ft_rd(  ft_rd ),
	.ft_wr(  ft_wr ),
	.dbg( w_ft_dbg)
);

wire [15:0]w_fifo_out;
wire w_fifo_empty;
wire w_fifo_read; assign w_fifo_read = w_active & ~w_fifo_empty;

`ifdef __ICARUS__ 
generic_fifo_dc_gray #( .dw(16), .aw(8) ) u_generic_fifo_dc_gray (
	.rd_clk(w_video_clk),
	.wr_clk(w_mem_clk),
	.rst(~w_reset),
	.clr(),
	.din(app_rd_data),
	.we(app_rd_valid),
	.dout(w_fifo_out),
	.rd(w_fifo_read),
	.full(),
	.empty(w_fifo_empty),
	.wr_level(w_wr_level),
	.rd_level()
	);
`else
//Quartus native FIFO;
wire [7:0]usedw;
vfifo u_vfifo(
	.aclr(w_reset),
	.data(app_rd_data),
	.rdclk(w_video_clk),
	.rdreq(w_fifo_empty ? 1'b0 : w_fifo_read),
	.wrclk(w_mem_clk),
	.wrreq(app_rd_valid),
	.q(w_fifo_out),
	.rdempty(w_fifo_empty),
	.wrusedw(usedw)
	);

assign w_wr_level =  (usedw>=196) ? 2'b11 :
							(usedw>=128) ? 2'b10 :
							(usedw>=64)  ? 2'b01 : 2'b00;
`endif

reg [15:0]out_word;
always @(posedge w_video_clk)
	if(w_active)
		out_word <= w_fifo_out[15:0];
	else
		out_word <= 16'h0;

reg d_active;
reg r_hsync;
reg r_vsync;

always @(posedge w_video_clk)
begin
	r_hsync <= w_hsync;
	r_vsync <= w_vsync;
	d_active  <= w_active;
end

assign LED[7:3] = 0;
assign LED[1] = KEY0;
assign LED[2] = w_ft_dbg;

`ifdef HDMI
wire w_tmds_bh;
wire w_tmds_bl;
wire w_tmds_gh;
wire w_tmds_gl;
wire w_tmds_rh;
wire w_tmds_rl;
hdmi u_hdmi(
	.pixclk( w_video_clk ),
	.clk_TMDS2( w_video_clk5 ),
	.hsync( r_hsync ),
	.vsync( r_vsync ),
	.active( d_active ),
	.red(  { out_word[15:11], 3'b000 } ),
	.green({ out_word[10: 5], 2'b00  } ),
	.blue( { out_word[ 4: 0], 3'b000 } ),
	.TMDS_bh( w_tmds_bh ),
	.TMDS_bl( w_tmds_bl ),
	.TMDS_gh( w_tmds_gh ),
	.TMDS_gl( w_tmds_gl ),
	.TMDS_rh( w_tmds_rh ),
	.TMDS_rl( w_tmds_rl )
);

`ifdef __ICARUS__
	ddio u_ddio1( .d1( w_video_clk), .d0( w_video_clk), .clk(w_video_clk5), .out( TMDS[1] ) );
	ddio u_ddio0( .d1(~w_video_clk), .d0(~w_video_clk), .clk(w_video_clk5), .out( TMDS[0] ) );
	ddio u_ddio3( .d1( w_tmds_bh),   .d0( w_tmds_bl),   .clk(w_video_clk5), .out( TMDS[3] ) );
	ddio u_ddio2( .d1(~w_tmds_bh),   .d0(~w_tmds_bl),   .clk(w_video_clk5), .out( TMDS[2] ) );
	ddio u_ddio5( .d1( w_tmds_gh),   .d0( w_tmds_gl),   .clk(w_video_clk5), .out( TMDS[5] ) );
	ddio u_ddio4( .d1(~w_tmds_gh),   .d0(~w_tmds_gl),   .clk(w_video_clk5), .out( TMDS[4] ) );
	ddio u_ddio7( .d1( w_tmds_rh),   .d0( w_tmds_rl),   .clk(w_video_clk5), .out( TMDS[7] ) );
	ddio u_ddio6( .d1(~w_tmds_rh),   .d0(~w_tmds_rl),   .clk(w_video_clk5), .out( TMDS[6] ) );
`else
	altddio_out1 u_ddio1( .datain_h( w_video_clk), .datain_l( w_video_clk), .outclock(w_video_clk5), .dataout( TMDS[1] ) );
	altddio_out1 u_ddio0( .datain_h(~w_video_clk), .datain_l(~w_video_clk), .outclock(w_video_clk5), .dataout( TMDS[0] ) );
	altddio_out1 u_ddio3( .datain_h( w_tmds_bh),   .datain_l( w_tmds_bl),   .outclock(w_video_clk5), .dataout( TMDS[3] ) );
	altddio_out1 u_ddio2( .datain_h(~w_tmds_bh),   .datain_l(~w_tmds_bl),   .outclock(w_video_clk5), .dataout( TMDS[2] ) );
	altddio_out1 u_ddio5( .datain_h( w_tmds_gh),   .datain_l( w_tmds_gl),   .outclock(w_video_clk5), .dataout( TMDS[5] ) );
	altddio_out1 u_ddio4( .datain_h(~w_tmds_gh),   .datain_l(~w_tmds_gl),   .outclock(w_video_clk5), .dataout( TMDS[4] ) );
	altddio_out1 u_ddio7( .datain_h( w_tmds_rh),   .datain_l( w_tmds_rl),   .outclock(w_video_clk5), .dataout( TMDS[7] ) );
	altddio_out1 u_ddio6( .datain_h(~w_tmds_rh),   .datain_l(~w_tmds_rl),   .outclock(w_video_clk5), .dataout( TMDS[6] ) );
`endif

`else
	//VGA signals
	assign VGA_BLUE = out_word[4 : 0];
	assign VGA_GREEN= out_word[10: 5];
	assign VGA_RED  = out_word[15:11];
	assign VGA_HSYNC = r_hsync;
	assign VGA_VSYNC = r_vsync;
`endif

endmodule
