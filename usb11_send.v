
//low speed USB send module
module usb11_send(
	input wire rst,		//async reset signal
	input wire clk,		//clock should be 12Mhz

	input wire [7:0]sbyte,  	//byte for send
	input wire sbyte_wr,		//start sending packet on that signal
	input wire last_pkt_byte,	//mean send EOP at the end
	
	output reg dp,				//usb BUS signals
	output reg dm,
	output reg bus_enable,

	output reg show_next,		//request for next sending byte in packet
	output reg pkt_end,			//mean that packet was sent
	output wire [10:0]ls_bit_time,
	output reg eof,
	output reg eof_ena
	);

//make low speed bit impulse
//divide 12MHz on 8 getting 1,5MHz
reg [2:0]cnt8=0;
wire bit_impulse; assign bit_impulse = (cnt8 == 3'b000);
always @( posedge clk )
	cnt8 <= cnt8 + 1'b1;

//make frame EOF impulse
reg [10:0]bit_time=0; assign ls_bit_time = bit_time;
always @( posedge clk )
	if(bit_impulse)
	begin
		if(bit_time==1499)
			bit_time <= 0;
		else
			bit_time <= bit_time + 1'b1;
		eof <= ( bit_time<2 );
		eof_ena <= ( bit_time<2 ) | eof;
	end

//remember that we need to send new packet
reg need_send=0;
reg [7:0]sbyte_fixed=0;
reg last_pkt_byte_fixed;
always @(posedge clk)
begin
	if( sbyte_wr )
		need_send <= 1'b1;
	else
	if( sending_last_bit )
		need_send <= 1'b0;
	if( sbyte_wr )
	begin
		sbyte_fixed <= sbyte;
		last_pkt_byte_fixed <= last_pkt_byte;
	end
end

reg sbit;
reg  se0;
always @*
begin
	sbit = (prev_sbit ^ (!send_reg[0]) ^ (six_ones & send_reg[0])) & sending_pkt;
	se0 = !(sending_pkt ^ (sending_pkt | sending_pkt_prev[1]));
	show_next = (bit_count==3'b001) & sending_bit & sending_pkt & (!last);
	pkt_end = ~bus_enable & sending_pkt_prev[4] & bit_impulse;
end

//create bus enable signal for packet sending
reg sending_pkt=1'b0;
wire pkt_start_impuls; assign pkt_start_impuls = (need_send & bit_impulse & ~sending_pkt );
always @( posedge clk )
	if( pkt_start_impuls )
		sending_pkt <= 1'b1;
	else
	if( sending_last_bit & last )
		sending_pkt <= 1'b0;

//delay shift register for bus enable for packet
reg [4:0]sending_pkt_prev=5'b00000;
always @( posedge clk )
	if( bit_impulse )
		sending_pkt_prev <= { sending_pkt_prev[3:0],sending_pkt };

//per channel bus enable generation
always @( posedge clk )
	if(bit_impulse)
		bus_enable <= ( sending_pkt | sending_pkt_prev[2] );

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
		dp <= (  sbit  & se0 );
		dm <= ((!sbit) & se0 );
	end
end

//count number of sequential ONEs
reg [2:0]ones_cnt=3'b000;
wire six_ones; assign six_ones = (ones_cnt==3'h6);
wire sending_bit = sending_pkt & bit_impulse & (!six_ones);

always @( posedge clk )
	if(eof)
		ones_cnt <= 0;
	else
	if(bit_impulse & sending_pkt)
	begin
		if(sbit==prev_sbit)
			ones_cnt <= ones_cnt+1'b1;
		else
			ones_cnt <= 0;
	end

//fix just sent bit
reg prev_sbit=1'b0;
always @( posedge clk )
	if( eof )
		prev_sbit <= 1'b0;
	else
	if( bit_impulse & sending_pkt )
		prev_sbit <= sbit;

//fix flag about last byte in packet
reg last=1'b0;
always @( posedge clk )
	if( pkt_end )
		last <= 1'b0;
	else
	if( sending_last_bit )
		last <= last_pkt_byte_fixed;

//count number of sent bits
reg [2:0]bit_count=3'b000;
always @( posedge clk )
	if( eof )
		bit_count <= 3'b000;
	else
	if( sending_bit )
		bit_count <= bit_count + 1'b1;

wire bit_count_eq7; assign bit_count_eq7 = (bit_count==3'h7);
wire sending_last_bit = sending_bit & bit_count_eq7; //sending last bit in byte

//load/shift sending register
reg [7:0]send_reg=0;
always @( posedge clk )
	if( eof )
		send_reg <= 0;
	else
	if( pkt_start_impuls || (bit_count_eq7 && sending_bit) )
		send_reg <= sbyte_fixed; //load first or next bytes for send
	else
	if(sending_bit)
		send_reg <= {1'b0, send_reg[7:1]}; 	//shift out byte

endmodule
