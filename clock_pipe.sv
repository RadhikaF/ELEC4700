// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Main module file (clock_pipe.sv), clock, registers

module elec4700(
	input logic [9:0] SW,
	input logic [3:0] KEY,
	//input logic CLOCK_27,
	//input logic CLOCK_125_p,
	output logic [9:0] LEDR,
	output logic [7:0] LEDG,
	output logic [6:0] HEX0,HEX1,HEX2,HEX3
);

	logic [31:0] q;		// clock stuff
	logic clk;
	//assign clk = q[25];     // Uncomment these lines and choose the appropriate bit of q if a slower clock is needed
	//assign clk = CLOCK_125_p;
	assign clk = SW[9];
   assign LEDG[0] = clk;   // Can see the clock if it is slow enough
	//assign clk = q[25];
	
	//***Fetch Define Variables***//
	logic Stall_F, init_flush_F, blank_F;
	logic [4:0] pc_F, pc_out;
	logic [17:0] instruction_F;
	
	//***Decode Define Variables***//
	logic Ji, B1, B2, Ii, Mi, Ri, Excep, OutputA, MulDiv, Shift, ALU_op, 		// result from priority decoders
			alu_en_D, muldiv_en_D, shift_en_D, jump_en_D, WriteEnable_D, WriteCheck_D, WriteRA_D, AluSrc2_D, AluSrc1_D, AluSrc0_D, MemToReg_D,
			jump_check_D, Stall_D, Jump_Flush_D, lui_en_D, forwarding_disable_rs_D, branchstall_D, stack_add_D, stack_subtract_D; // results from control module
	logic [1:0] forwardA_D, forwardB_D, stack_D;
	logic [2:0] MulDivFunct_D, ShiftFunct_D; 		// results from control module
	logic [3:0] rs_D, rt_D, rd_D,	ALUFunct_D;	// 4 bit numbers as used in opcodes
	logic [4:0] MemOp_D, JumpBranch_D, pc_D;
	logic [5:0] opcode_D;
	logic [17:0] instruction_D;
	logic [31:0] rs_value_D, rt_value_D, ra_D, rs_value_forward_D, rt_value_forward_D, latest_ra_D;
	
	//***Execute Define Variables***//
	logic alu_en_E, muldiv_en_E, shift_en_E, WriteEnable_E, WriteCheck_E, WriteRA_E, MemToReg_E, AluSrc2_E, AluSrc1_E, AluSrc0_E, 
			Flush_E, lui_en_E, forward_3rd_E;
	logic [2:0] MulDivFunct_E, ShiftFunct_E; 		// results from control module
	logic [3:0] rs_E, rt_E, rd_E, ALUFunct_E, write_value_E;
	logic [4:0] MemOp_E;
	logic [31:0] write_out_E, ALU_B_E, rs_value_E, rt_value_E, hi_E, lo_E, mul_div_out_E, shift_out_E, ALU_out_E, ra_E, ALU_A_E;
	
	//***Memory Define Variables***//
	logic WriteEnable_M, MemToReg_M, MemEn_M, WriteRA_M;
	logic [3:0] write_value_M;
	logic [4:0] MemOp_M;
	logic [31:0] write_out_M, rd_RAM_M, MemIn_M, MOut_M, ra_M, rt_value_M;
	
	//***Write Define Variables***//
	logic WriteEnable_W, MemToReg_W, WriteRA_W;
	logic [3:0] write_value_W;
	logic [31:0] write_out_W, rd_RAM_W, rd_value_W, ra_W;			
  
	//***Fetch***//
	assign init_flush_F = (|pc_F);
	counter32 #(5) clock(clk, Stall_F, jump_check_D, blank_F, pc_F, pc_out, pc_F);
	ROM_test #(5,18) myrom(pc_F,instruction_F);		// gets instruction from text file
	assign blank_F = ~(|instruction_F);

	// Fetch to Decode on Clock edge
	FDRegister FDReg(clk, Stall_D, jump_check_D, pc_F, instruction_F, pc_D, instruction_D, Jump_Flush_D);
	
	//***Decode***//
	
	// store register instruction to rs, rt, rd
	assign opcode_D = instruction_D[17:12]; 
	assign extra_jump = instruction_D[11];
	assign rs_D = instruction_D[11:8];    //same as shamt
	assign rt_D = instruction_D[7:4];
	assign rd_D = instruction_D[3:0]; 		//same as imm and B1offset and MemImm
	
	regfile test_read(clk, WriteEnable_W, WriteRA_E, stack_D, rs_D, rt_D, write_value_W, ra_E, rd_value_W, 
			HEX0,HEX1,HEX2,HEX3, rs_value_D, rt_value_D, latest_ra_D);		// gets rs, rt values and writes rd value if we = 1 
	priority_decoder main(instruction_D[17:13], Ji, B1, B2, Ii, Mi, Ri);		// priority decoder for main instruction opcode
	priority_decoder_Rtype Rtype(instruction_D[16:13], Excep, OutputA, MulDiv, Shift, ALU_op);		// priority decoder for R type
	
	control control_unit(opcode_D, Ji, B1, B2, Ii, Mi, Ri, extra_jump, Excep, OutputA, MulDiv, Shift, ALU_op, Jump_Flush_D, init_flush_F, 
			alu_en_D, muldiv_en_D, shift_en_D, jump_en_D, WriteEnable_D, WriteCheck_D, WriteRA_D, AluSrc2_D, AluSrc1_D, AluSrc0_D, 
			MemToReg_D, lui_en_D, forwarding_disable_rs_D, stack_add_D, stack_subtract_D, ALUFunct_D, MulDivFunct_D, ShiftFunct_D, MemOp_D, JumpBranch_D); 
	
	// Jump
	jump #(5,5) jump_instruction (rs_value_forward_D, rt_value_forward_D, latest_ra_D, rd_D, pc_D, JumpBranch_D, jump_en_D, pc_out, ra_D, jump_check_D);	// jump function
	
	// Hazard Forwarding
	forwarding forward (WriteEnable_E, WriteEnable_M, WriteEnable_W, forwarding_disable_rs_D, MemToReg_M, jump_en_D, rs_D, rt_D, write_value_E, write_value_M, write_value_W, 
			forwardA_D, forwardB_D, branchstall_D);
	mux4to1_pipeline #(32) forwarding_rs (rs_value_D, rd_value_W, write_out_M, write_out_E, forwardA_D, rs_value_forward_D);
	mux4to1_pipeline #(32) forwarding_rt (rt_value_D, rd_value_W, write_out_M, write_out_E, forwardB_D, rt_value_forward_D);
	
	// Decode to Execute on Clock edge
	DERegister DEReg(clk, Flush_E, WriteRA_D, alu_en_D, muldiv_en_D, shift_en_D, MemToReg_D, WriteEnable_D, WriteCheck_D, lui_en_E, AluSrc2_D, AluSrc1_D, AluSrc0_D, forwarding_disable_rs_D,
			stack_add_D, stack_subtract_D, stack_D, MulDivFunct_D, ShiftFunct_D, rt_D, rs_D, rd_D, ALUFunct_D, MemOp_D, rs_value_forward_D, rt_value_forward_D, ra_D, 
			WriteRA_E, alu_en_E, muldiv_en_E, shift_en_E, MemToReg_E, WriteEnable_E, WriteCheck_E, lui_en_E, AluSrc2_E, AluSrc1_E, AluSrc0_E, forwarding_disable_rs_E,
			stack_D, MulDivFunct_E, ShiftFunct_E, rt_E, rs_E, rd_E, ALUFunct_E, MemOp_E, rs_value_E, rt_value_E, ra_E);
  
	//***Execute***//
	assign write_value_E = WriteCheck_E? {rd_E}:{rt_E};
	assign ALU_A_E = lui_en_E? {32'd0}:rs_value_E;
	
	//Immediate
	immediate_control immediate(AluSrc2_E, AluSrc1_E, AluSrc0_E, rd_E, rt_value_E, rs_value_E, ALU_B_E);
	
	tristate_active_hi shift2 (shift_out_E, shift_en_E, write_out_E);
	tristate_active_hi muldiv2 (mul_div_out_E, muldiv_en_E, write_out_E);
	tristate_active_hi ALU2 (ALU_out_E, alu_en_E, write_out_E);
	//tristate_active_hi ra_out (ra_E, WriteRA_E, write_out_E);
	
	Shifter shift(ShiftFunct_E, rs_E, rt_value_E, rs_value_E, shift_out_E);
	multiply_divide #(32) mul_div(clk, MulDivFunct_E, rs_value_E, rt_value_E, mul_div_out_E, hi_E, lo_E);
	ALU #(32) ALU_module(ALU_A_E, ALU_B_E, ALUFunct_E, ALU_out_E, ALU_cout, ALU_ov);
	
	// Execute to Memory on Clock edge
	EMRegister EMReg (clk, WriteEnable_E, MemToReg_E, WriteRA_E, write_value_E, MemOp_E, write_out_E, ra_E, rt_value_E,
			WriteEnable_M, MemToReg_M, WriteRA_M, write_value_M, MemOp_M, write_out_M, ra_M, rt_value_M);
	
	//***Memory***//
	// = base + offset = [rs] + signimm
	Memory mem(MemToReg_M, MemOp_M, write_out_M[1:0], rt_value_M, MOut_M, rd_RAM_M, MemIn_M, MemEn_M);
	RAM #(6,32) RamMem(write_out_M[7:2], MemIn_M, clk, MemEn_M, MOut_M);
  
	memory_load lw_hazard(rs_D, rt_D, rt_E, MemToReg_E, branchstall_D, Stall_F, Stall_D, Flush_E);
  
	// Memory to Write on Clock edge
	MWRegister MWReg (clk, WriteEnable_M, MemToReg_M, WriteRA_M, write_value_M, write_out_M, rd_RAM_M, ra_M, 
			WriteEnable_W, MemToReg_W, WriteRA_W, write_value_W, write_out_W, rd_RAM_W, ra_W);
  
	//***Write***//
	assign rd_value_W = MemToReg_W ? rd_RAM_W:write_out_W;
	
	//***Other***//
	assign LEDR[4:0] = pc_D;
	assign LEDR[9:5] = pc_F;
	assign LEDG[7] = Stall_F;
	assign LEDG[6] = jump_check_D;
	assign LEDG[5] = blank_F;
	//assign LEDR[9:0] = instruction_F[17:8];
	//assign LEDG[7:1] = instruction_D[7:1];	

  
endmodule

module FDRegister(
	input logic clk, en, clr, input logic [4:0] PCF, input logic [17:0] instruction_F,
	output logic [4:0] PCD, output logic [17:0] instruction_D, output logic JumpFlush_D);
	
	always_ff @(posedge clk) begin
		if (clr) begin
			PCD <= 4'd0;
			instruction_D <= 18'd0;
			JumpFlush_D <= 1'b1;
		end //if (clr)
		else if(~en) begin
			PCD <= PCF;
			instruction_D <= instruction_F;
			JumpFlush_D <= 1'b0;
		end
	end
endmodule // FDRegister

module DERegister(
	input logic clk, clr, WriteRAD, alu_enD, muldiv_enD, shift_enD, MemtoRegD, WriteEnableD, WriteCheckD, lui_en_D, AluSrc2_D, AluSrc1_D, AluSrc0_D, forwarding_disable_rs_D, stack_add_D, stack_subtract_D, 
	input logic [1:0] stack, 
	input logic [2:0] MulDivFunctD, ShiftFunctD, 
	input logic [3:0] rtD, rsD, rdD, ALUFunctD, 
	input logic [4:0] MemOpD,
	input logic [31:0] RD1D, RD2D, ra_D,
	output logic WriteRAE, alu_enE, muldiv_enE, shift_enE, MemtoRegE, WriteEnableE, WriteCheckE, lui_en_E, AluSrc2_E, AluSrc1_E, AluSrc0_E, forwarding_disable_rs_E, 
	output logic [1:0] stack_out, 
	output logic [2:0] MulDivFunctE, ShiftFunctE, 
	output logic [3:0] rtE, rsE, rdE, ALUFunctE, 
	output logic [4:0] MemOpE,
	output logic [31:0] RD1E, RD2E, ra_E);

	always_ff @(posedge clk) begin
		if (stack_add_D) stack_out <= stack + 1'b1;
		else if (stack_subtract_D) stack_out <= stack - 1'b1;
		if(clr) begin
			WriteRAE <= 1'b0;
			alu_enE <= 1'b0;
			muldiv_enE <= 1'b0;
			shift_enE <= 1'b0;
			ALUFunctE <= 4'd0;
			MulDivFunctE <= 3'd0;
			ShiftFunctE <= 3'd0;
			MemOpE <= 5'd0;
			WriteCheckE <= 1'd0;
			lui_en_E <= 1'd0;
			WriteEnableE <= 1'd0;
			MemtoRegE <= 1'b0; 
			rtE <= 4'd0;
			rsE <= 4'd0;
			rdE <= 4'd0;
			RD1E <= 32'd0;
			RD2E <= 32'd0;
			ra_E <= 32'd0;
			AluSrc2_E <= 1'b0;
			AluSrc1_E <= 1'b0;
			AluSrc0_E <= 1'b0;
			forwarding_disable_rs_E <= 1'b0;
		end
		else begin
			WriteRAE <= WriteRAD;
			alu_enE <= alu_enD;
			muldiv_enE <= muldiv_enD;
			shift_enE <= shift_enD;
			ALUFunctE <= ALUFunctD;
			MulDivFunctE <= MulDivFunctD;
			ShiftFunctE <= ShiftFunctD;
			MemOpE <= MemOpD;
			WriteCheckE <= WriteCheckD;
			lui_en_E <= lui_en_D;
			WriteEnableE <= WriteEnableD;
			MemtoRegE <= MemtoRegD; 
			rtE <= rtD;
			rsE <= rsD;
			rdE <= rdD;
			RD1E <= RD1D;
			RD2E <= RD2D;
			ra_E <= ra_D;
			AluSrc2_E <= AluSrc2_D;
			AluSrc1_E <= AluSrc1_D;
			AluSrc0_E <= AluSrc0_D;
			forwarding_disable_rs_E <= forwarding_disable_rs_D;
		end // else	
	end
endmodule // DERegister

module EMRegister(
	input logic clk, WriteEnable_E, MemToReg_E, WriteRA_E,
	input logic [3:0] write_value_E,
	input logic [4:0] MemOp_E,
	input logic [31:0] write_out_E, ra_E, rt_value_E,
	output logic WriteEnable_M, MemToReg_M, WriteRA_M,
	output logic [3:0] write_value_M,
	output logic [4:0] MemOp_M,
	output logic [31:0] write_out_M, ra_M, rt_value_M);

	always_ff @(posedge clk) begin
		WriteEnable_M <= WriteEnable_E;
		MemToReg_M <= MemToReg_E;
		WriteRA_M <= WriteRA_E;
		write_value_M <= write_value_E;
		MemOp_M <= MemOp_E;
		write_out_M <= write_out_E;
		ra_M <= ra_E;
		rt_value_M <= rt_value_E;
	end
endmodule // EMRegister

module MWRegister(
	input logic clk, WriteEnable_M, MemToReg_M, WriteRA_M, 
	input logic [3:0] write_value_M, 
	input logic [31:0] write_out_M, rd_RAM_M, ra_M,
	output logic WriteEnable_W, MemToReg_W, WriteRA_W,
	output logic [3:0] write_value_W, 
	output logic [31:0] write_out_W, rd_RAM_W, ra_W);

	always_ff @(posedge clk) begin
		WriteEnable_W <= WriteEnable_M;
		MemToReg_W <= MemToReg_M;
		WriteRA_W <=  WriteRA_M;
		write_value_W <= write_value_M;
		write_out_W <= write_out_M;
		rd_RAM_W <= rd_RAM_M;
		ra_W <= ra_M;
	end
endmodule // MWRegister

module ROM_test #(parameter clock_length=4,instruction_width=18) (
	input  logic [clock_length-1:0] Ad,
	output logic [instruction_width-1:0] Dout);

	logic [instruction_width-1:0] mem[2**clock_length-1:0];    //18 bit wide registers (16 of them by default)
	
	assign Dout = mem[Ad];
  
	initial begin
		$readmemb("machine_output.txt",mem); // Program is stored in binary at prog4.txt;   use $readmemh for hex format
	end
endmodule

module regfile(
	input logic clk, WE, JUMP,
	input logic [1:0] stack,
	input logic [3:0] RA1, RA2, WA, RA,
	input logic [31:0] WD,
	output logic [6:0] HEX0,HEX1,HEX2,HEX3,
	output logic [31:0] RD1, RD2, RA_OUT);
	
	logic [16:0] rf[31:0];
	always_ff @(posedge clk) begin
		if (WE) rf[WA] <= WD;
		if (JUMP) rf[16 + stack] <= RA;
	end
	 
	assign RD1 = rf[RA1];
   assign RD2 = rf[RA2];
	assign RA_OUT = rf[16 + stack];
	
	seven_segment reg1 (rf[0], HEX0[6:0]);
	seven_segment reg2 (rf[1], HEX1[6:0]);
	seven_segment reg3 (rf[2], HEX2[6:0]);
	seven_segment reg4 (rf[3], HEX3[6:0]);
	//seven_segment reg5 (rf[4], HEX4[6:0]);
	//seven_segment reg6 (rf[5], HEX5[6:0]);
	//seven_segment reg7 (rf[6], HEX6[6:0]);
	//seven_segment reg8 (rf[7], HEX7[6:0]);
	
endmodule

// This is a simple counter module, useful if we need a slow clock
module counter32 #(parameter clock_length=6) (
	input logic clk, en, JUMP, blank, input logic [clock_length-1:0] input_q, jump_dest,
	output logic [clock_length-1:0] q);
	//FIX THIS, REMOVE CLOCK BLOCK, USE MUX TO PICK FROM IF/ELSE
	initial begin
		q <= 5'b0;
	end
	always_ff @(posedge clk)
	if (~en) begin
		if (blank)
		q = (input_q);
		else if (JUMP)
		q = jump_dest;
		else
		q = (input_q + 1);
	end
	//logic lo;
   //assign lo = JUMP ? {jump_dest}:{input_q + 1};
   //assign q = blank ? {input_q}:{lo};
   
	
endmodule

module seven_segment(input logic [3:0] switch, output logic [6:0] hex_disp);	// seven segment display module from first assignment, input: hex number in 4 bit bus binary to be displayed, output: 7 bit bus for the seven segment display
	assign hex_disp[0] = ~((~switch[3] & switch[1]) | (switch[2] & switch[1]) | (~switch[2] & ~switch[0]) | (switch[3] & ~switch[0]) | (~switch[3] & switch[2] & switch[0]) | (switch[3] & ~switch[2] & ~switch[1]));	// sum of products for the top segment
	assign hex_disp[1] = ~((~switch[2] & ~switch[0]) | (~switch[2] & ~switch[1]) | (~switch[3] & ~switch[1] & ~switch[0]) | (~switch[3] & switch[1] & switch[0]) | (switch[3] & ~switch[1] & switch[0]));	// sum of products for the top right segment
	assign hex_disp[2] = ~((switch[3] & ~switch[2]) | (~switch[3] & switch[2]) | (~switch[1] & switch[0]) | (~switch[3] & ~switch[1]) | (~switch[3] & switch[0]));	// sum of products for the bottom right segment
	assign hex_disp[3] = ~((switch[2] & ~switch[1] & switch[0]) | (switch[2] & switch[1] & ~switch[0]) | (~switch[2] & switch[1] & switch[0]) | (switch[3] & ~switch[1] & ~switch[0]) | (~switch[3] & ~switch[2] & ~switch[0]));	// sum of products for the bottom segment
	assign hex_disp[4] = ~((switch[3] & switch[2]) | (~switch[2] & ~switch[0]) | (switch[3] & ~switch[0]) | (switch[3] & switch[1]) | (switch[1] & ~switch[0]));	// sum of products for the bottom left segment
	assign hex_disp[5] = ~((switch[3] & ~switch[2]) | (~switch[1] & ~switch[0]) | (switch[3] & switch[1]) | (switch[3] & ~switch[0]) | (switch[2] & ~switch[0]) | (~switch[3] & switch[2] & ~switch[1]));	// sum of products for the top left segment
	assign hex_disp[6] = ~((switch[3] & switch[1]) | (switch[3] & switch[0]) | (~switch[2] & switch[1]) | (switch[3] & ~switch[2]) | (switch[1] & ~switch[0]) | (~switch[3] & switch[2] & ~switch[1]));	// sum of products for the middle segment
endmodule
