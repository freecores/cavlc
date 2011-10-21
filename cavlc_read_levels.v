//2011-8-6 	initiial revision
//2011-8-19	reverse the order of level

//  include TrailingOnes

`include "defines.v"

module cavlc_read_levels (
	clk,
	rst_n,
	ena,
	t1s_sel,
	prefix_sel,
	suffix_sel,
	calc_sel,
	TrailingOnes,
	TotalCoeff,
	rbsp,
	i,
	level_0, level_1, level_2, level_3, level_4, level_5, level_6, level_7,
	level_8, level_9, level_10, level_11, level_12, level_13, level_14, level_15,
	len_comb
);
//------------------------
// ports
//------------------------
input	clk;
input	rst_n;

input	ena;
input	t1s_sel;
input	prefix_sel;
input	suffix_sel;
input	calc_sel;

input	[1:0]	TrailingOnes;
input	[4:0]	TotalCoeff;
input	[0:15]	rbsp;
input	[3:0]	i;

output	[8:0]	level_0, level_1, level_2, level_3, level_4, level_5, level_6, level_7;
output	[8:0]	level_8, level_9, level_10, level_11, level_12, level_13, level_14, level_15;
output	[4:0]	len_comb;

//------------------------
//  regs
//------------------------
reg		[0:15]	rbsp_prefix;		//for level_prefix_comb
reg		[3:0]	level_prefix_comb;
reg		[8:0]	level_suffix;
reg		[4:0]	len_comb;

//------------------------
// FFs
//------------------------
reg 	[3:0]	level_prefix;
reg		[2:0]	suffixLength;	// range from 0 to 6
reg		[8:0]	level;
reg		[8:0]	level_abs;
reg		[8:0]	level_code_tmp;
reg		[8:0]	level_0, level_1, level_2, level_3, level_4, level_5, level_6, level_7;
reg		[8:0]	level_8, level_9, level_10, level_11, level_12, level_13, level_14, level_15;

//------------------------
// level_prefix_comb
//------------------------
wire	level_prefix_refresh;
assign level_prefix_refresh = (prefix_sel && ena);

always @(level_prefix_refresh or rbsp)
if (level_prefix_refresh)
	rbsp_prefix <= rbsp;
else
	rbsp_prefix <= 'hffff;
	
always @(*)
if (rbsp_prefix[0]) 		level_prefix_comb <= 0;
else if (rbsp_prefix[1]) 	level_prefix_comb <= 1;
else if (rbsp_prefix[2]) 	level_prefix_comb <= 2;
else if (rbsp_prefix[3])	level_prefix_comb <= 3;
else if (rbsp_prefix[4]) 	level_prefix_comb <= 4;
else if (rbsp_prefix[5]) 	level_prefix_comb <= 5;
else if (rbsp_prefix[6]) 	level_prefix_comb <= 6;
else if (rbsp_prefix[7]) 	level_prefix_comb <= 7;
else if (rbsp_prefix[8]) 	level_prefix_comb <= 8;
else if (rbsp_prefix[9]) 	level_prefix_comb <= 9;
else if (rbsp_prefix[10]) 	level_prefix_comb <= 10;
else if (rbsp_prefix[11])	level_prefix_comb <= 11;
else if (rbsp_prefix[12])	level_prefix_comb <= 12; 
else if (rbsp_prefix[13]) 	level_prefix_comb <= 13; 
else if (rbsp_prefix[14]) 	level_prefix_comb <= 14;
else if (rbsp_prefix[15])	level_prefix_comb <= 15;
else 						level_prefix_comb <= 'bx;
	

//------------------------
// level_prefix
//------------------------
always @(posedge clk or negedge rst_n)
if (~rst_n)
	level_prefix <= 0;
else if (level_prefix_refresh) begin
	level_prefix <= level_prefix_comb;
end

//------------------------
// suffixLength
//------------------------
wire first_level;
assign first_level = (i == TotalCoeff - TrailingOnes - 1);

wire suffixLength_refresh;
assign suffixLength_refresh = prefix_sel && ena;

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	suffixLength <= 0;
end
else if (suffixLength_refresh) begin
	if (TotalCoeff > 10 && TrailingOnes < 3 && first_level )	//initialize suffixLength before proceeding first level_suffix
		suffixLength <= 1;
	else if (first_level)
		suffixLength <= 0;
	else if (suffixLength == 0 && level_abs > 2'd3)
		suffixLength <= 2;
	else if (suffixLength == 0)
		suffixLength <= 1;
	else if (  level_abs > (2'd3 << (suffixLength - 1'b1) ) && suffixLength < 6)
		suffixLength <= suffixLength + 1'b1;
end


//------------------------
// level_suffix
//------------------------
wire level_suffix_refresh;
assign level_suffix_refresh = suffix_sel && ena;

always @(*)
if (level_suffix_refresh) begin
	if (suffixLength > 0 && level_prefix <= 14) begin
		level_suffix <= {3'b0, rbsp[0:5] >> (3'd6 - suffixLength)};
	end
	else if (level_prefix == 14) begin	//level_prefix == 14 && suffixLength == 0
		level_suffix <= {3'b0, rbsp[0:3] };
	end
	else if (level_prefix == 15) begin
		level_suffix <= rbsp[3:11];	    
	end
	else begin
		level_suffix <= 0;	    
	end		
end
else begin
	level_suffix <= 0;	    
end

//------------------------
// level_code_tmp
//------------------------
always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	level_code_tmp <=  0;
end
else if (level_suffix_refresh) begin
	level_code_tmp <= (level_prefix << suffixLength) + level_suffix + 
	((suffixLength == 0 && level_prefix == 15) ? 4'd15 : 0);
end


//------------------------
// level
//------------------------
wire	[2:0]	tmp1;

assign tmp1 = (first_level && TrailingOnes < 3)? 2'd2 : 2'd0;

always @(*)
begin
	if (level_code_tmp % 2 == 0) begin
		level <= ( level_code_tmp + tmp1 + 2 ) >> 1;
	end
	else begin
		level <= (-level_code_tmp - tmp1 - 1 ) >> 1;
	end
end

//------------------------
// level_abs
//------------------------
wire level_abs_refresh;
assign level_abs_refresh = calc_sel && ena;

always @(posedge clk or negedge rst_n)
if (~rst_n) begin
	level_abs <= 0;
end
else if (level_abs_refresh) begin
	level_abs <= level[8] ? -level : level;
end

//------------------------
// level regfile
//------------------------
always @ (posedge clk or negedge rst_n)
if (!rst_n) begin
	level_0 <= 0;	level_1 <= 0;	level_2 <= 0;	level_3 <= 0;
	level_4 <= 0;	level_5 <= 0;	level_6 <= 0;	level_7 <= 0;
	level_8 <= 0;	level_9 <= 0;	level_10<= 0;	level_11<= 0;
	level_12<= 0;	level_13<= 0;	level_14<= 0;	level_15<= 0;
end
else if (t1s_sel && ena)
	case (i)
	0 : level_0 <= rbsp[0]? -1 : 1;
	1 : begin
			level_1 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_0 <= rbsp[1]? -1 : 1;
		end
	2 : begin
			level_2 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_1 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_0 <= rbsp[2]? -1 : 1;
		end			
	3 : begin
			level_3 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_2 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_1 <= rbsp[2]? -1 : 1;
		end	
	4 : begin
			level_4 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_3 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_2 <= rbsp[2]? -1 : 1;
		end	
	5 : begin
			level_5 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_4 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_3 <= rbsp[2]? -1 : 1;
		end	
	6 : begin
			level_6 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_5 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_4 <= rbsp[2]? -1 : 1;
		end	
	7 : begin
			level_7 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_6 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_5 <= rbsp[2]? -1 : 1;
		end	
	8 : begin
			level_8 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_7 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_6 <= rbsp[2]? -1 : 1;
		end	
	9 : begin
			level_9 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_8 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_7 <= rbsp[2]? -1 : 1;
		end	
	10: begin
			level_10 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_9 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_8 <= rbsp[2]? -1 : 1;
		end	
	11: begin
			level_11 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_10 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_9 <= rbsp[2]? -1 : 1;
		end	
	12: begin
			level_12 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_11 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_10 <= rbsp[2]? -1 : 1;
		end	
	13: begin
			level_13 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_12 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_11 <= rbsp[2]? -1 : 1;
		end	
	14: begin
			level_14 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_13 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_12 <= rbsp[2]? -1 : 1;
		end	
	15: begin
			level_15 <= rbsp[0]? -1 : 1;
			if (TrailingOnes[1])
				level_14 <= rbsp[1]? -1 : 1;
			if (TrailingOnes == 3)
				level_13 <= rbsp[2]? -1 : 1;
		end	
endcase
else if (calc_sel && ena)
case (i)
	0 :level_0 <= level;
	1 :level_1 <= level;
	2 :level_2 <= level;
	3 :level_3 <= level;
	4 :level_4 <= level;
	5 :level_5 <= level;
	6 :level_6 <= level;
	7 :level_7 <= level;
	8 :level_8 <= level;
	9 :level_9 <= level;
	10:level_10<= level;
	11:level_11<= level;
	12:level_12<= level;
	13:level_13<= level;
	14:level_14<= level;
	15:level_15<= level;
endcase

always @(*)
if(t1s_sel)
	len_comb <= TrailingOnes;
else if(prefix_sel)
	len_comb <= level_prefix_comb + 1;
else if(suffix_sel && suffixLength > 0 && level_prefix <= 14)
	len_comb <= suffixLength;  
else if(suffix_sel && level_prefix == 14)
	len_comb <= 4;
else if(suffix_sel && level_prefix == 15)
	len_comb <= 12;
else
	len_comb <= 0;	      

endmodule
