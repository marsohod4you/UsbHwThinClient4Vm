
//low speed USB send module
module usb11_send(
	input wire rst,		//async reset signal
	input wire clk,		//clock should be 12Mhz

	input wire [7:0]sbyte,  	//byte for send
	input wire start_pkt,		//start sending packet on that signal
	input wire last_pkt_byte,	//mean send EOP at the end

	input wire cmd_rst,			//commands received
	input wire cmd_ena,
	
	output reg dp,				//usb BUS signals
	output reg dm,
	output reg bus_enable,

	output reg show_next,		//request for next sending byte in packet
	output reg pkt_end,			//mean that packet was sent
	output reg eop
	);

//make low speed bit impulse
reg [2:0]cnt8;
reg bit_impulse;
always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		cnt8 <= 0;
		bit_impulse <= 1'b0;
	end
	else
	begin
		cnt8 <= cnt8 + 1'b1;
		bit_impulse <= (cnt8 == 3'b111);
	end
end

//make frame EOP impulse
reg [10:0]bit_time;
always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		bit_time <= 0;
		eop <= 1'b0;
	end
	else
	begin
		if(bit_impulse)
		begin
			if(bit_time==1499)
				bit_time <= 0;
			else
				bit_time <= bit_time + 1'b1;
		end
		
		eop <= (bit_time > 1497 );
	end	
end	

reg sbit;
reg  se0;
always @*
begin
	sbit = (prev_sbit ^ (!send_reg[0]) ^ (six_ones & send_reg[0])) & bus_ena_pkt;
	se0 = !(bus_ena_pkt ^ (bus_ena_pkt | bus_ena_prev[1]));
	show_next = (bit_count==3'b001) & sending_bit & bus_ena_pkt & (!last);
	pkt_end = bus_enable & (!bus_ena_pkt) & (bit_count==3'h3) & bit_impulse;
end

//USB Reset and USB Enable become actual with frame start only
reg usb_rst_fixed;
always @(posedge clk or posedge rst)
	if(rst)
		usb_rst_fixed <= 1'b0;
	else
	if(eop)
		usb_rst_fixed <= cmd_rst;

reg usb_ena_fixed;
always @(posedge clk or posedge rst)
	if(rst)
		usb_ena_fixed <= 1'b0;
	else
	if(eop)
		usb_ena_fixed <= cmd_ena;

//create bus enable signal for packet sending
reg bus_ena_pkt;
always @(posedge clk or posedge rst)
begin
	if(rst)
		bus_ena_pkt <= 1'b0;
	else
	begin
		if(start_pkt)
			bus_ena_pkt <= 1'b1;
		else
		if( sending_last_bit & last | eop)
			bus_ena_pkt <= 1'b0;
	end
end

//delay shift register for bus enable for packet
reg [2:0]bus_ena_prev;
always @(posedge clk or posedge rst)
begin
	if(rst)
		bus_ena_prev <= 3'b000;
	else
	if(bit_impulse)
		bus_ena_prev <= {bus_ena_prev[1:0],bus_ena_pkt};
end

reg eop_f;

//per channel bus enable generation
always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		eop_f <= 1'b0;
		bus_enable <= 1'b0;
	end
	else
	if(bit_impulse)
	begin
		eop_f <= eop;

		bus_enable <= ( bus_ena_pkt | bus_ena_prev[2] ) 
			| usb_rst_fixed 	//bus enabled when rst
			| (usb_ena_fixed & (eop|eop_f) ); //bus enabled for keep-alive messages
	end
end

wire suppress; assign suppress = usb_rst_fixed | (usb_ena_fixed & eop);

//make output on USB buses
always @(posedge clk or posedge rst)
begin
	if(rst)
	begin
		dp <= 1'b0;
		dm <= 1'b0;
	end
	else
	if(bit_impulse)
	begin
		if(suppress)
		begin
			dp <= 1'b0;
			dm <= 1'b0;
		end
		else
		begin
			dp <= (  sbit  & se0 );
			dm <= ((!sbit) & se0 );
		end
	end
end

//count number of sequential ONEs
reg [2:0]ones_cnt;
wire six_ones; assign six_ones = (ones_cnt==3'h6);
wire sending_bit = bit_impulse & (!six_ones);

always @(posedge clk or posedge rst)
begin
	if(rst)
		ones_cnt <= 0;
	else
	begin
		if(eop)
			ones_cnt <= 0;
		else
		if(bit_impulse & bus_ena_pkt)
		begin
			if(sbit==prev_sbit)
				ones_cnt <= ones_cnt+1'b1;
			else
				ones_cnt <= 0;
		end
	end
end

//fix just sent bit
reg prev_sbit;
always @(posedge clk or posedge rst)
begin
	if(rst)
		prev_sbit <= 1'b0;
	else
	begin
		if(start_pkt | eop)
			prev_sbit <= 1'b0;
		else
		if(bit_impulse & bus_ena_pkt )
			prev_sbit <= sbit;
	end
end

//fix flag about last byte in packet
reg last;
always @(posedge clk or posedge rst)
begin
	if(rst)
		last <= 1'b0;
	else
	begin
		if(start_pkt | eop)
			last <= 1'b0;
		else
		if(sending_last_bit)
			last <= last_pkt_byte;
	end
end

//count number of sent bits
reg [2:0]bit_count;
always @(posedge clk or posedge rst)
begin
	if(rst)
		bit_count <= 3'b000;
	else
	begin
		if(start_pkt | eop)
			bit_count <= 3'b000;
		else
		if( sending_bit)
			bit_count <= bit_count + 1'b1;
	end
end

wire bit_count_eq7; assign bit_count_eq7 = (bit_count==3'h7);
wire sending_last_bit = sending_bit & bit_count_eq7; //sending last bit in byte

//load/shift sending register
reg [7:0]send_reg;
always @(posedge clk or posedge rst)
begin
	if(rst)
		send_reg <= 0;
	else
	begin
		if(eop)
			send_reg <= 0;
		else
		if(sending_bit | start_pkt)
		begin	 
			if(bit_count_eq7 | start_pkt)
				send_reg <= sbyte;					//load first or next bytes for send
			else
				send_reg <= {1'b0, send_reg[7:1]}; 	//shift out byte
		end
	end
end

endmodule
