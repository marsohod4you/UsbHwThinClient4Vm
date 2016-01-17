
`timescale  1 ns / 1 ns

module tb();

//100 MHz clock
reg clk_100Mhz = 1'b0;
always
	#5 clk_100Mhz = ~clk_100Mhz;

wire w_sdr_clk;
wire w_sdr_ras_n;
wire w_sdr_cas_n;
wire w_sdr_we_n;
wire [1:0]w_sdr_dqm;
wire [1:0]w_sdr_ba;
wire [11:0]w_sdr_addr;
wire [15:0]w_sdr_dq;

//instance of sdram model
mt48lc4m16a2 u_mt48lc4m16
    (
    .Clk  (w_sdr_clk),
    .Addr(w_sdr_addr),
    .Ba  (w_sdr_ba),
    .Dq  (w_sdr_dq),
    .Dqm (w_sdr_dqm),
    .Ras_n (w_sdr_ras_n),
    .Cas_n (w_sdr_cas_n),
    .We_n  (w_sdr_we_n),
    .Cke  (1'b1),
    .Cs_n  (1'b0)
	);

wire [7:0]test_leds;
wire w_hsync;
wire w_vsync;
wire [7:0]w_tmds;

wire [7:0]w_ft_d;
wire w_ft_clk;
wire w_ft_rxf;
wire w_ft_oe;
wire w_ft_rd;
wire w_ft_wr;
reg start_emu = 1'b0;

ftdi_emu u_ftdi_emu(
	.start_emu(start_emu),
	.ft_clk(w_ft_clk),
	.ft_rxf(w_ft_rxf),
	.ft_d(w_ft_d),
	.ft_oe(w_ft_oe),
	.ft_rd(w_ft_rd),
	.ft_wr(w_ft_wr)
);

//instance of top module for test
top u_top
	(
    .CLK100MHZ(clk_100Mhz),
	.LED(test_leds),
	
`ifdef HDMI
	.TMDS(w_tmds),
`else
	.VGA_BLUE(),
	.VGA_GREEN(),
	.VGA_RED(),
	.VGA_HSYNC(w_hsync),
	.VGA_VSYNC(w_vsync),
`endif

	/* Interface to SDRAM chip  */
	.SDRAM_CLK(w_sdr_clk),
	.SDRAM_A(w_sdr_addr),
	.SDRAM_BA(w_sdr_ba),
	.SDRAM_DQ(w_sdr_dq),
	.SDRAM_DQM(w_sdr_dqm),
	.SDRAM_RAS(w_sdr_ras_n),
	.SDRAM_CAS(w_sdr_cas_n),
	.SDRAM_WE(w_sdr_we_n),
	.SDRAM_CKE(),
	.SDRAM_CS(),
	
	.ft_clk( w_ft_clk ),
	.ft_rxf( w_ft_rxf ),
	.ft_txe( w_ft_tfx ),
	.ft_d  ( w_ft_d   ),
	.ft_oe ( w_ft_oe  ),
	.ft_rd ( w_ft_rd  ),
	.ft_wr ( w_ft_wr  ),
	.KEY0(1'b1),
	.KEY1(1'b1)
	);

initial
    begin
	$display("Init mem?");
	init_sdram_mem();
	$display("Init mem completed");
	$dumpfile("out.vcd");
	$dumpvars(0,tb);
	$display("start debug..");
	//#150000;
	//$finish;
	$dumpon;
	@(posedge u_top.w_sdr_init_done);
	$display("w_sdr_init_done");
	//@(negedge u_top.app_rd_req);
	@(posedge u_top.w_active);
	#10;
	@(posedge u_top.app_rd_req);
	#1966;
	start_emu = 1'b1;
	#1000000;
	print_mem(16);
	$dumpoff;
	
	$finish;
	
	@(posedge u_top.w_vsync);
	$display("w_vsync 0");
	#1;
	@(posedge u_top.w_vsync);
	$display("w_vsync 1");
	$dumpon;
    @(posedge u_top.w_vsync);
	$display("w_vsync 2");
	#1000;
	$display("End of simulation!");
	$finish;
    end

always @(posedge u_top.w_hsync)
begin
	if( (u_top.w_line_count&8'h3F)==0 )
	begin
		$display("hlines %d",u_top.w_line_count);
	end
end

integer x,y,addr,mem_bank;
task init_sdram_mem;
begin
	for(y=0; y<720; y=y+1)
	begin
		for(x=0; x<1280; x=x+1)
		begin
			addr = 4096*y+x;
			mem_bank = addr[9:8];
			addr = { addr[31:10], addr[7:0] };
			//$display("mem %d %08x %04X",mem_bank,addr,x);
			case(mem_bank)
			0:	begin
					u_mt48lc4m16.Bank0[addr] = x; //16'h55aa;
				end
			1:	begin
					u_mt48lc4m16.Bank1[addr] = x; //16'h55aa;
				end
			2:	begin
					u_mt48lc4m16.Bank2[addr] = x; //16'h55aa;
				end
			3:	begin
					u_mt48lc4m16.Bank3[addr] = x; //16'h55aa;
				end
			endcase
		end
		//$finish;
	end
end
endtask

task print_mem;
input [31:0]addr;
begin
	$display("addr %x %x",addr+0,u_mt48lc4m16.Bank0[addr+0]);
	$display("addr %x %x",addr+1,u_mt48lc4m16.Bank0[addr+1]);
	$display("addr %x %x",addr+2,u_mt48lc4m16.Bank0[addr+2]);
	$display("addr %x %x",addr+3,u_mt48lc4m16.Bank0[addr+3]);
	$display("addr %x %x",addr+4,u_mt48lc4m16.Bank0[addr+4]);
	$display("addr %x %x",addr+5,u_mt48lc4m16.Bank0[addr+5]);
	$display("addr %x %x",addr+6,u_mt48lc4m16.Bank0[addr+6]);
	$display("addr %x %x",addr+7,u_mt48lc4m16.Bank0[addr+7]);
end
endtask

endmodule

