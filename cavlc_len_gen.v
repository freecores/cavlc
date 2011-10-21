//2011-8-7 20:19	initial revision

`include "defines.v"

module cavlc_len_gen (
	cavlc_state,
	len_read_total_coeffs_comb,
	len_read_levels_comb,
	len_read_total_zeros_comb,
	len_read_run_befores_comb,
	len_comb
);
//------------------------
// ports
//------------------------
input	[7:0] cavlc_state;
input	[4:0] len_read_total_coeffs_comb;
input 	[4:0] len_read_levels_comb;
input	[3:0] len_read_total_zeros_comb;
input	[3:0] len_read_run_befores_comb;

output	[4:0] len_comb;

//------------------------
// regs
//------------------------
reg	[4:0] len_comb;			//number of bits comsumed by cavlc in a cycle

//------------------------
// len_comb
//------------------------
always @ (*)
case (1'b1)	//synthesis parallel_case
	cavlc_state[`cavlc_read_total_coeffs_bit]	: len_comb <= len_read_total_coeffs_comb;
	cavlc_state[`cavlc_read_t1s_flags_bit],	 
	cavlc_state[`cavlc_read_level_prefix_bit],
	cavlc_state[`cavlc_read_level_suffix_bit]	: len_comb <= len_read_levels_comb;		 
	cavlc_state[`cavlc_read_total_zeros_bit]	: len_comb <= len_read_total_zeros_comb;
	cavlc_state[`cavlc_read_run_befores_bit]	: len_comb <= len_read_run_befores_comb;
	cavlc_state[`cavlc_calc_level_bit],
	cavlc_state[`cavlc_idle_bit]				: len_comb <= 0;
	default										: len_comb <= 'bx;
endcase

endmodule

