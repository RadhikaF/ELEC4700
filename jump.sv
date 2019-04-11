// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Jump, Branch and R-type instructions

module jump #(parameter clock_length = 4, f = 5) (
	input logic [31:0] rs_value, rt_value, input logic [4:0] ra_value, constant, input logic [clock_length-1:0] clock, input logic [f-1:0] F, input logic jump_enable,
	output logic [clock_length-1:0] pc, output logic [4:0] ra, output logic final_check);
	
	logic [4:0] jump_to_if_equal, jump_to_if_branch, jump_to_if_not_ra;
	logic branch, equal_check, lt_ge_check, le_gt_check;
	
	assign jump_to_if_equal = F[1] ? {rs_value[4:0]}:{{1'b0}, constant};		// choose between jumping to constant or rs_value
	assign jump_to_if_branch = constant + clock;
	assign equal_check = ((rs_value[3:0] == rt_value[3:0])) ^ F[0];		// 1 when not equal to inside bracket, xor'd with F[0], gives a 1 when beq or bne satisfied
	assign lt_ge_check = rs_value[31] ^ ~F[0];			// 1 when less than
	assign le_gt_check = (~(rs_value[31] | ~(|rs_value))) ^ ~F[0];		// 1 when greater than
	assign final_check = (equal_check & (~F[3] & F[2]) | lt_ge_check & (F[3] & F[2]) | le_gt_check & (F[3] & ~F[2]) | (~(F[2] | F[3]))) & jump_enable;  // finds any 1's in any of the above logic
	//assign pc = final_check ? {jump_to_if_equal}:{clock};
	assign branch = (F[3] | F[2]);
	assign jump_to_if_not_ra = branch ? {jump_to_if_branch}:{jump_to_if_equal};
	assign pc = F[4] ? {ra_value[4:0]}:{jump_to_if_not_ra};
	assign ra = (((~(F[2] | F[3])) & F[0]) & final_check) ? {clock+1'b1}:{6'b0};		// saves ra if selected to
	
endmodule
