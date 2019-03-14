// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Decoders
module prioritydecoder_1bit(
  input logic a,
  output logic [1:0] b);
  
  assign b = {a, ~a};
  
endmodule

//2 bit priority decoder using a 1 bit priority decoder
module prioritydecoder_2bit(
  input logic [1:0] a,
  output logic [2:0] b);
  
  logic [1:0] f,e;      //intermediate variables
  
  prioritydecoder_1bit a0_f(a[0], f);
  prioritydecoder_1bit a1_e(a[1], e);
  
  assign b[2] = e[1];
  assign b[0] = e[0] & f[0];
  assign b[1] = e[0] & f[1];
  
endmodule

//4 bit priority decoder using a 2 bit priority decoder
module prioritydecoder_4bit(
  input logic [3:0] a,
  output logic [4:0] b);
  
  logic [2:0] e, f;     //intermediate variables
  
  prioritydecoder_2bit top (a[1:0], f);
  prioritydecoder_2bit bottom (a[3:2], e);  
  
  assign b[4:3] = e[2:1];
  assign b[2:0] = f[2:0] & {3{e[0]}};
  
endmodule

module priority_decoder_Rtype(
  input logic [3:0] opcode,
  output logic Excep, OutputA, MulDiv, Shift, ALU);
  
  prioritydecoder_4bit full (opcode[3:0], {ALU, Shift, MulDiv, OutputA, Excep});    //send bits [3:0] to the 4 bit priority decoder
  
endmodule

module priority_decoder(
  input logic [4:0] opcode,
  output logic Ji, B1, B2, Ii, Mi, Ri);
  
  logic [4:0] f;
  logic [1:0] e;
  
  prioritydecoder_4bit top4 (opcode[3:0], f);
  prioritydecoder_1bit bottom1 (opcode[4], e);
  
  assign Ri = e[1];
  assign {Mi, Ii, B2, B1, Ji} = f[4:0] & {5{e[0]}};

endmodule

module tristate_active_hi (
	input logic [31:0] a,
	input logic en,
	output tri [31:0] y);
	
	assign y = en? a : 4'bz;

endmodule

module mux4to1_pipeline #(parameter W = 3) (
  input logic [W-1:0] A,B,C,D, input logic [1:0] F,
  output logic [W-1:0] Y);
  
  // temp variable
  logic [W-1:0] lo, hi;
  
  assign lo = F[0] ? {B}:{A};
  assign hi = F[0] ? {D}:{C};
  assign Y = F[1] ? {hi}:{lo};
  
endmodule
