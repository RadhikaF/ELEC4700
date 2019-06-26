// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Pipelining Hazard Unit

module forwarding (
	input logic RegWriteE, RegWriteM, RegWriteW, forwarding_disable_rs_D, MemToReg_M, jump_enable_D,
	input logic [3:0] rsD, rtD, WriteRegE, WriteRegM, WriteRegW, 
	output logic [1:0] ForwardAD, ForwardBD, branchstall
	);
	
	logic bstall1, bstall2;	
	always_comb begin
	if ((rsD == WriteRegE) & RegWriteE & (~forwarding_disable_rs_D))
		ForwardAD = 2'b11;
	else if((rsD == WriteRegM) & RegWriteM & (~forwarding_disable_rs_D)) 
		ForwardAD = 2'b10;
	else if((rsD == WriteRegW) & RegWriteW & (~forwarding_disable_rs_D)) 
		ForwardAD = 2'b01;
	else
		ForwardAD = 2'b00;
	end
	
	always_comb begin
	if ((rtD == WriteRegE) & RegWriteE)
		ForwardBD = 2'b11;
	else if((rtD == WriteRegM) & RegWriteM) 
		ForwardBD = 2'b10;
	else if((rtD == WriteRegW) & RegWriteW) 
		ForwardBD = 2'b01;
	else
		ForwardBD = 2'b00;
	end
	
	//assign bstall1 = RegWriteE & ((WriteRegE == rsD) | (WriteRegE == rtD));
	assign bstall2 = MemToReg_M & ((WriteRegM == rsD) | (WriteRegM == rtD));
	
	assign branchstall = bstall2;
	
endmodule

/*module check3 (
	input logic RegWriteW, forwarding_disable_rs_D,
	input logic [3:0] rsD, rtD, WriteRegW,
	output logic [1:0] ForwardAD, ForwardBD
	);
	
	always_comb begin
	if((rsD == WriteRegW) & RegWriteW & ~(forwarding_disable_rs_D)) 
		ForwardAD = 1'b1;
	else 
		ForwardAD = 1'b0;
	end
	
	always_comb begin
	if((rtD == WriteRegW) & RegWriteW) 
		ForwardBD = 1'b1;
	else 
		ForwardBD = 1'b0;
	end
endmodule*/
	
module memory_load (
	input logic rs_D, rt_D, rt_E, MemToReg_E, branchstall,
	output logic StallF, StallD, FlushE
	);
	
	logic lwstall;
	assign lwstall = ((rs_D == rt_E) | (rt_D == rt_E)) & MemToReg_E;
	assign StallF = lwstall | branchstall;
	assign StallD = StallF ;
	assign FlushE = StallF ;

endmodule

/*module branch_hazard(
	input logic RegWriteM, RegWriteE, MemToReg_M, jump_enable_D,
	input logic [3:0] rs_D, rt_D, WriteRegE, WriteRegM,
	output logic ForwardAD_branch, ForwardBD_branch, branchstall
);
	logic bstall1, bstall2;
	
	assign ForwardAD_branch = (rs_D == WriteRegM) & RegWriteM;
	assign ForwardBD_branch = (rt_D == WriteRegM) & RegWriteM;
	
	assign bstall1 = RegWriteE & ((WriteRegE == rs_D) | (WriteRegE == rt_D));
	assign bstall2 = MemToReg_M & ((WriteRegM == rs_D) | (WriteRegM == rt_D));
	
	assign branchstall = jump_enable_D & (bstall1 | bstall2);

endmodule*/
