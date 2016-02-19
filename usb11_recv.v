
//simplest low speed USB receiver module

module usb11_recv(
	input wire rst,		//async rst
	input wire clk,		//clock should be 12Mhz

	input wire dp,		//usb11 BUS signals
	input wire dm,

	input wire enable,
	output wire eop_r,

	//output received bytes interface
	output reg [7:0]rdata,
	output reg [3:0]rbyte_cnt,
	output reg rdata_ready,
	output wire end_of_recv
	);

//fix current USB line values
reg [1:0]dp_fixed;
reg [1:0]dm_fixed;

always @(posedge clk)
begin		
	dp_fixed <= { dp_fixed[0], dp };
	dm_fixed <= { dm_fixed[0], dm };
end

//detect EOP USB BUS state
//if both DP/DM lines in ZERO this is low speed EOP
//EOP reinitializes receiver
assign eop_r  = ~( |dp_fixed | |dm_fixed);

//find edge of receive EOP
reg eop_r_fixed;
always @(posedge clk)
	eop_r_fixed <= eop_r;
assign end_of_recv = eop_r_fixed & (~eop_r);

//logic for enabling/disabling receiver
reg receiver_enabled;
always @(posedge clk or posedge rst )
begin		
	if(rst)
		receiver_enabled <= 1'b0;
	else
	begin
		//enable receiver on raising edge of DP line and disable on any EOP
		if( dp_fixed[0] | eop_r)
			receiver_enabled <= enable & (~eop_r);
	end
end

//detect change on DP line
//this defines strobing
wire dp_change; assign dp_change = dp_fixed[0] ^ dp_fixed[1];

//generate clocked receiver strobe with this counter
reg [2:0]clk_counter;
always @(posedge clk or posedge rst )
begin		
	if(rst)
		clk_counter <= 3'b000;
	else
	begin		
		//every edge on line resynchronizes receiver clock
		if(dp_change | eop_r)
			clk_counter <= 3'b000;
		else
			clk_counter <= clk_counter + 1'b1;
	end
end

reg r_strobe;
always @*
	r_strobe = (clk_counter == 3'b011) & receiver_enabled;

//on receiver strobe remember last fixed DP value
reg last_fixed_dp;
always @(posedge clk or posedge rst)
begin
	if(rst)
		last_fixed_dp <= 1'b0;
	else
	begin
		if(r_strobe | eop_r)
		begin
			last_fixed_dp <= dp_fixed[1] & (~eop_r);
		end	
	end
end

//count number of sequental ones for bit staffling
reg [2:0]num_ones;
always @(posedge clk or posedge rst)
begin
	if(rst)
		num_ones <= 3'b000;
	else
	begin
		if(r_strobe)
		begin
			if(last_fixed_dp == dp_fixed[1])
				num_ones <= num_ones + 1'b1;
			else
				num_ones <= 3'b000;
		end
	end
end

//zero should be removed from bit stream because of bit-stuffling
wire do_remove_zero; assign do_remove_zero = (num_ones == 6);

reg [2:0]receiver_cnt;

//receiver process
always @(posedge clk or posedge rst )
begin		
	if(rst)
	begin
		//async rst
		receiver_cnt <= 0;
		rdata <= 0;
		rdata_ready <= 1'b0;
	end
	else
	begin
		if(r_strobe & (!do_remove_zero) | eop_r)
		begin
			//decode NRZI
			//shift-in ONE  if older and new values are same
			//shift-in ZERO if older and new values are different
			//BUT (bit-stuffling) do not shift-in one ZERO after 6 ONEs
			if(eop_r)
			begin
				receiver_cnt <= 0;
				rdata  <= 0;
			end
			else
			begin
				receiver_cnt <= receiver_cnt + 1'b1;
				rdata  <= { (last_fixed_dp == dp_fixed[1]) , rdata[7:1]};
			end
		end

		//set write-enable signal (write into receiver buffer)
		rdata_ready <= (receiver_cnt == 7) & r_strobe & (!do_remove_zero) & (~eop_r);
	end
end

//count number of received bytes
always @(posedge clk or posedge rst )
begin		
	if(rst)
		rbyte_cnt <= 0;
	else
	begin
		if(end_of_recv)
			rbyte_cnt <= 0;
		else
		if(rdata_ready)
			rbyte_cnt <= rbyte_cnt + 1'b1;
	end
end

endmodule
