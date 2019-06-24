// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Main module file (clock_pipe.sv), clock, registers

module elec4700(
	input logic [9:0] SW,
	input logic [3:0] KEY,
	//input logic CLOCK_27,
	input logic CLOCK_50_B5B,
	output logic [9:0] LEDR,
	output logic [7:0] LEDG,
	output logic [6:0] HEX0,HEX1,HEX2,HEX3,
	
	output logic [17:0] SRAM_A,
	inout [15:0] SRAM_D,
	output logic SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n,
	input logic UART_RX,
	output logic UART_TX
);

	logic [31:0] q;		// clock stuff
	logic clk;
	//assign clk = q[25];     // Uncomment these lines and choose the appropriate bit of q if a slower clock is needed
	assign clk = CLOCK_50_B5B;
//	assign clk = KEY[0];
   assign LEDG[0] = clk;   // Can see the clock if it is slow enough
	
	logic P0_stall, P1_stall, P0_wr, P0_rd, P1_wr, P1_rd, sram_status, sram_WE, sram_RE;
	logic [31:0] MOut_M, P0_WD, P1_WD, sram_WD;
	logic [16:0] P0_addr, P1_addr, sram_addr;
	logic MemToReg_D, MemToReg_E, MemToReg_M, MemToReg_W,
		MemToReg_D1, MemToReg_E1, MemToReg_M1, MemToReg_W1;
	logic cpu_done_M1, cpu_done_M2, cpu_done_final, write_accepted1, write_accepted0, read_accepted1, read_accepted0;
	
	logic [6:0] HEX01, HEX11, HEX21, HEX31;
	logic hit_w0, wrtag_en0, wrvalid_en0, wrdata_en0, valid_WD0;
	cpu0 core0(clk, P0_stall, MOut_M, P0_wr, P0_rd, P0_addr, P0_WD, HEX0,HEX1,HEX2,HEX3, MemToReg_D, MemToReg_E, MemToReg_M, MemToReg_W, cpu_done_M1, size_error1,hit_w0, wrtag_en0, wrvalid_en0, wrdata_en0, valid_WD0, LEDR, LEDG[3:1]);
	cpu1 core1(clk, P1_stall, MOut_M, P1_wr, P1_rd, P1_addr, P1_WD, HEX01,HEX11,HEX21,HEX31, MemToReg_D1, MemToReg_E1, MemToReg_M1, MemToReg_W1, cpu_done_M2, size_error2);
	
//	assign P1_wr = 0;
//	assign P1_rd = 0;
//	assign P1_addr = 0;
//	assign P1_WD = 0;
//	assign cpu_done_M2 = 1'b1;

	assign cpu_done_final = cpu_done_M1 & cpu_done_M2;
	logic size_error1, size_error2; 
	
	logic P0_using, P1_using;
		
	assign P0_stall = (P0_request & sram_status) | (P0_request & using);
	assign P1_stall =  (P1_request & sram_status) | (P1_request & ~using);

	assign sram_WD = using ? P1_WD : P0_WD;
	assign sram_addr = using? P1_addr: P0_addr;
	assign write_accepted1 = using & P1_wr;
	assign write_accepted0 = (!using) & P0_wr;
	assign read_accepted1 = using & P1_rd;
	assign read_accepted0 = (!using) & P0_rd;
	assign sram_WE = write_accepted0 | write_accepted1; 
	assign sram_RE = read_accepted0 | read_accepted1; 

	logic P0_request, P1_request, using;
	assign P0_request = P0_rd | P0_wr;
	assign P1_request = P1_rd | P1_wr;
	
	//use register to denote which processor has priority (with using bit)
	always_ff @(posedge clk) begin
		if (~sram_status) begin
			if (P0_request & ~P1_request) //if P0 request, and P1 no request
				using <= 1'b0;		//let P0 use it
			else if (~P0_request & P1_request)		//if P0 no request, P1 request
				using <= 1'b1;		//let P1 use it
			else if (P0_request & P1_request) //if request from both P0 and P1
				using <= ~using; //if P1 using, let P0 use it, and vice versa	
		end
	end
	
	SRAM test_sram(clk, sram_status/* output stall from SRAM */, cpu_done_final, sram_WE, sram_RE, sram_addr, sram_WD, MOut_M, SRAM_A, SRAM_D, SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n, UART_RX, UART_TX);
  	
//	seven_segment reg1 (data_RD0, HEX0[6:0]);
//	seven_segment reg2 (tag_RD0, HEX1[6:0]);
//	seven_segment reg3 (valid_RD0, HEX2[6:0]);
//	seven_segment reg4 (data_WD0, HEX3[6:0]);	
	
//	assign LEDR[0] = P0_wr;
//	assign LEDR[1] = P0_rd;
//	assign LEDR[2] = hit_w0;
//	assign LEDR[3] = wrtag_en0;
//	assign LEDR[4] = wrvalid_en0;
//	assign LEDR[5] = wrdata_en0;
//	assign LEDR[6] = valid_WD0;
//	assign LEDR[7] = hit_w3;
//	assign LEDR[8] = wrlru_en0;
//	assign LEDR[9] = using;
//	
	assign LEDG[7] = MemToReg_D;
	assign LEDG[6] = MemToReg_E;
	assign LEDG[5] = MemToReg_M;
	assign LEDG[4] = MemToReg_W;
//	assign LEDG[3] = wrlru_en1;
//	assign LEDG[2] = wrlru_en2;
//	assign LEDG[1] = wrlru_en3;
			
endmodule
