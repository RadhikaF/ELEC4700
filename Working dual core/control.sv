// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Control variables for every module
module control
(
	input logic [5:0] opcode, input logic Ji, B1, B2, Ii, Mi, Ri, extra_jump, Excep, OutputA, MulDiv, Shift, ALU_op, Jump_Flush_D, init_flush_F,
	output logic alu_en, muldiv_en, shift_en, jump_en, WriteEnable, WriteCheck, WriteRA, AluSrc2, AluSrc1, AluSrc0, MemToReg, lui_en, forwarding_disable_rs, stack_add, stack_subtract,
	output logic [3:0] ALUFunct, 
	output logic [2:0] MulDivFunct, ShiftFunct,
	output logic [4:0] MemOp, JumpBranch 
);
	logic[3:0] ImmInstruction;
	assign lui_en = AluSrc0 & AluSrc1 & AluSrc2;
	assign MemOp = {Mi, opcode[3:0]};
	assign alu_en = (ALU_op & Ri) | Ii;
	assign muldiv_en = (MulDiv | OutputA) & Ri;
	assign shift_en = Shift & Ri;
	assign jump_en = (B1 | B2 | Ji | (Ri & Excep)) & ~Jump_Flush_D & init_flush_F;
	assign WriteEnable = ((Ri & Shift) | (Ri & MulDiv & ~opcode[1]) | (Ri & ALU_op)| (Mi & ~opcode[3]) | Ii) & ~Jump_Flush_D;		// set we so that rd is only written to when R type (but not R type jump) is selected 
	assign WriteRA = ((Ji & extra_jump & ~JumpBranch[4]) | (Ri & Excep & opcode[0]));
	assign WriteCheck = (Ri & Shift) | (Ri & MulDiv & ~opcode[1]) | (Ri & ALU_op);
	//assign AluSrc2D = opcode[1];
	//assign AluSrc1D = opcode[0];
	assign ImmInstruction = Ii ? {{~opcode[2] & opcode[1]}, opcode[2:0]} : opcode[3:0];
	assign ALUFunct = Mi ? {4'b0}:ImmInstruction;
	assign MulDivFunct[2] = (OutputA & ~Jump_Flush_D);
	assign MulDivFunct[1] = (opcode[1] & ~Jump_Flush_D);
	assign MulDivFunct[0] = opcode[0];
	assign ShiftFunct = opcode[2:0];
	assign AluSrc0 = opcode[2] & opcode[1] & opcode[0];		// immediate
	assign AluSrc1 = (opcode[2] & opcode[0]) & Ii;					// immediate
	assign AluSrc2 = ~Ri;								// immediate
	assign JumpBranch[4] = (~opcode[0] & extra_jump) & Ji;		// will be 1 when jumping to return
	assign JumpBranch[3] = B2;
	assign JumpBranch[2] = B1 | (B2 & opcode[1]);
	assign JumpBranch[1] = (Excep & Ri);
	assign JumpBranch[0] = (extra_jump & Ji) | (opcode[0] & (B1 | B2 | (Ri & Excep)));
	assign MemToReg = Mi;
	assign forwarding_disable_rs = (Ri & Shift & opcode[2]);
	assign stack_add = Ji & opcode[0];
	assign stack_subtract = Ji & ~opcode[0] & extra_jump;
	
endmodule

module immediate_control
(
	//	Imm = rd
	input logic AluSrc2, AluSrc1, AluSrc0, input logic [14:0] Imm, input logic [31:0] rt_value, rs_value,
	output logic [31:0] ALU_B
);
	// Immediate operands - decide what B will be for ALU
	logic [31:0] Alu0, Alu1, SignImm, ZeroImm, CompImm;
	
	assign SignImm = {{17{Imm[14]}}, Imm};
	assign ZeroImm = {17'b0, Imm};
	//comp_imm_select select_comp_imm (rs_value[2:0], Imm, CompImm);
	assign CompImm = {~Imm, {15{1'b1}} };
	assign Alu0 = AluSrc0? CompImm : ZeroImm;
	assign Alu1 = AluSrc1? Alu0 : SignImm;
	assign ALU_B = AluSrc2? Alu1 : rt_value;	
	
endmodule

/*module comp_imm_select
(
	input logic [2:0] rs_value, input logic [3:0] Imm, 
	output logic [31:0] CompImm
);
	// selects which CompImm to use for lui instruction, selected by the 3 least significant bits of the rs_value
	// "000" will pick {~Imm, {28{1'b1}}}, while "111" will pick {{28{1'b1}}, ~Imm}
	logic [31:0] temp_least_1, temp_least_2, temp_least_3, temp_least_4, temp_most_1, temp_most_2;
	assign temp_least_1 = rs_value[0] ? {{28{1'b1}}, ~Imm}:{{24{1'b1}}, ~Imm, {4{1'b1}}};
	assign temp_least_2 = rs_value[0] ? {{20{1'b1}}, ~Imm, {8{1'b1}}}:{{16{1'b1}}, ~Imm, {12{1'b1}}};
	assign temp_least_3 = rs_value[0] ? {{12{1'b1}}, ~Imm, {16{1'b1}}}:{{8{1'b1}}, ~Imm, {20{1'b1}}};
	assign temp_least_4 = rs_value[0] ? {{4{1'b1}}, ~Imm, {24{1'b1}}}:{~Imm, {28{1'b1}}};
	assign temp_most_1 = rs_value[1] ? temp_least_1:temp_least_2;
	assign temp_most_2 = rs_value[1] ? temp_least_3:temp_least_4;
	assign CompImm = rs_value[2] ? temp_most_1:temp_most_2;
	
endmodule
*/