// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron

// Memory RAM
/*module RAM #(parameter N=5, W=32) (
	input logic [N-1:0] Ad,
	input logic [W-1:0] Din,
	input logic Clk, En,
	output logic [W-1:0] Dout);
	
	logic [16:0] cpuAddress;
	assign cpuAddress = {(17-N)*{1'b0}, Ad};
	
	SRAM test_sram(clk, stall, En, ~En, cpuAddress, Din, Dout);
	
	logic [W-1:0] array[2**N-1:0];
	assign Dout = array[Ad];
	
	always_ff @ (posedge Clk)
		if(En) array[Ad] <= Din;
	
endmodule*/
/* tag -> word width = [10:0], #words = 64
data -> word width = [31:0], #words = 64
valid -> word width = 1, #words = 64
lru -> word width = 1, #words = 64 */

module cache_RAM #(parameter N=6, W=32) (
	input logic [N-1:0] Ad,
	input logic [W-1:0] Din,
	input logic Clk, En,
	output logic [W-1:0] Dout);
	
	logic [W-1:0] array[2**N-1:0];
	assign Dout = array[Ad];
	
	always_ff @ (posedge Clk)
		if(En) array[Ad] <= Din;
	
	initial begin
		for (int k = 0; k < 2**N - 1; k = k + 1) begin
			array[k] = 0;
		end
	end
endmodule

module cache_1bit_RAM #(parameter N=6) (
	input logic [N-1:0] Ad,
	input logic Din,
	input logic Clk, En,
	output logic Dout);
	
	logic array[2**N-1:0];
	assign Dout = array[Ad];
	
	always_ff @ (posedge Clk)
		if(En) array[Ad] <= Din;
	
	initial begin
		for (int k = 0; k < 2**N - 1; k = k + 1) begin
			array[k] = 0;
		end
	end

endmodule

//Memory
module Memory (
	input logic MemToReg_M,
	input logic [4:0] F,
	input logic [1:0] Ad,
	input logic [31:0] WD, Mout,
	output logic [31:0] RD, MemIn,
	output logic MemEn);

	logic [31:0] WB0, WB1, WB2, WB3, WH0, WH1, WH2, SignB0, SignB1, SignB2, SignB3, ZeroB0, ZeroB1, ZeroB2, ZeroB3, SignH0, SignH1, SignH2, ZeroH0, ZeroH1, ZeroH2;
	logic[31:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8, temp9, temp10, WBout, WHout, WBWHout, B01out, B23out, H01out, Bout, Hout,SignZeroOut;
	
	logic s0, s1, s2;

	assign s1 = F[0];
	assign s2 = F[1];
	assign s0 = F[2];
	assign MemEn = F[4] & F[3] & MemToReg_M;

	assign WB0 = {Mout[31:8], WD[7:0]};
	assign WB1 = {Mout[31:16], WD[7:0], Mout[7:0]};
	assign WB2 = {Mout[31:24], WD[7:0], Mout[15:0]};
	assign WB3 = {WD[7:0], Mout[23:0]};
	assign WH0 = {Mout[31:16], WD[15:0]};
	assign WH1 = {Mout[31:24], WD[15:0], Mout[7:0]};
	assign WH2 = {WD[15:0], Mout[15:0]};
	assign SignB0 = {{24{Mout[7]}}, Mout[7:0]};
	assign SignB1 = {{24{Mout[15]}}, Mout[15:8]};
	assign SignB2 = {{24{Mout[23]}}, Mout[23:16]};
	assign SignB3 = {{24{Mout[31]}}, Mout[31:24]};
	assign SignH0 = {{16{Mout[15]}}, Mout[15:0]};
	assign SignH1 = {{16{Mout[23]}}, Mout[23:8]};
	assign SignH2 = {{16{Mout[31]}}, Mout[31:16]};
	assign ZeroB0 = {24'd0, Mout[7:0]};
	assign ZeroB1 = {24'd0, Mout[15:8]};
	assign ZeroB2 = {24'd0, Mout[23:16]};
	assign ZeroB3 = {24'd0, Mout[31:24]};
	assign ZeroH0 = {16'd0, Mout[15:0]};
	assign ZeroH1 = {16'd0, Mout[23:8]};
	assign ZeroH2 = {16'd0, Mout[31:16]};

	//selecting what data will be written to RAM
	assign temp1 = Ad[0]? WB1:WB0;
	assign temp2 = Ad[0]? WB3:WB2;
	assign temp3 = Ad[0]? WH1:WH0;
	assign WBout = Ad[1]? temp2:temp1;
	assign WHout = Ad[1]? WH2: temp3;
	assign WBWHout = s1? WHout:WBout;
	assign MemIn = s2? WD:WBWHout;

	//selecting what data will be written to register rt
	assign temp4 = s0? ZeroB0:SignB0;
	assign temp5 = s0? ZeroB1:SignB1;
	assign temp6 = s0? ZeroB2:SignB2;
	assign temp7 = s0? ZeroB3:SignB3;
	assign temp8 = s0? ZeroH0:SignH0;
	assign temp9 = s0? ZeroH1:SignH1;
	assign temp10 = s0? ZeroH2:SignH2;
	
	assign B01out = Ad[0]? temp5:temp4;
	assign B23out = Ad[0]? temp7:temp6;
	assign H01out = Ad[0]? temp9:temp8;
	
	assign Bout = Ad[1]? B23out:B01out;
	assign Hout = Ad[1]? temp10: H01out;
	
	assign SignZeroOut = s1? Hout:Bout;
	assign RD = s2? Mout:SignZeroOut;

endmodule