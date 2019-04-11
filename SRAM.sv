module SRAM(
	input clock,
	
	//CPU interface
	output stall,
	input writeEnable,
	input readEnable,
	
	input [16:0] cpuAddress,
	input [31:0] writeData,
	output [31:0] readData,

	//SRAM interface
	output [17:0] SRAM_A,
	inout [15:0] SRAM_D,
	output SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n
);
	//Spend 1 cycle accessing the lower 16 bit word and then another for the upper 16 bit word
	logic currentWord;
	logic [15:0] readBuffer; //Hold the lower 16 bits while waiting for the upper 16 bits
	
	initial begin
		currentWord = 1'b0;
	end
	
	always @(posedge clock) begin
		if((readEnable | writeEnable) & ~currentWord) begin
			readBuffer <= SRAM_D;
			currentWord <= 1'b1;
		end else begin
			currentWord <= 1'b0;
		end
	end
	
	assign stall = (readEnable | writeEnable) & ~currentWord;

	
	//Static SRAM assignments
	assign SRAM_CE_n = 1'b0; //Enable chip
	assign SRAM_LB_n = 1'b0; //Enable lower byte
	assign SRAM_UB_n = 1'b0; //Enable upper byte
	assign SRAM_OE_n = 1'b0; //Enable output (overridden by WE)
	
	assign SRAM_WE_n = ~writeEnable;
	
	assign SRAM_A = {cpuAddress, currentWord};
	assign SRAM_D = writeEnable ? (currentWord ? writeData[31:16] : writeData[15:0]) : 16'bZ;

	assign readData = {SRAM_D, readBuffer};

endmodule 