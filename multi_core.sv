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
	output logic [6:0] HEX0,HEX1,HEX2,HEX3,
	
	output [17:0] SRAM_A,
	inout [15:0] SRAM_D,
	output SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n
);

	logic [31:0] q;		// clock stuff
	logic clk;
	//assign clk = q[25];     // Uncomment these lines and choose the appropriate bit of q if a slower clock is needed
	assign clk = (SW[9] & CLOCK_50_B5B);
	//assign clk = KEY[0];
    assign LEDG[0] = clk;   // Can see the clock if it is slow enough
	//assign clk = q[25];
	
	logic P0_stall, P1_stall, P0_wr, P0_rd, P1_wr, P1_rd, sram_status, sram_WE, sram_RE, cpu_done_final;
	logic [31:0] MOut_M, P0_WD, P1_WD, sram_WD;
	logic [16:0] P0_addr, P1_addr, sram_addr;
	logic MemToReg_D, MemToReg_E, MemToReg_M, MemToReg_W,
		MemToReg_D1, MemToReg_E1, MemToReg_M1, MemToReg_W1;
	
	logic [6:0] HEX01, HEX11, HEX21, HEX31;
	cpu0 core0(clk, P0_stall, MOut_M, P0_wr, P0_rd, P0_addr, P0_WD, HEX01,HEX11,HEX21,HEX31, MemToReg_D, MemToReg_E, MemToReg_M, MemToReg_W, cpu_done_M1);
	
	cpu1 core1(clk, P1_stall, MOut_M, P1_wr, P1_rd, P1_addr, P1_WD, HEX0,HEX1,HEX2,HEX3, MemToReg_D1, MemToReg_E1, MemToReg_M1, MemToReg_W1, cpu_done_M2);

	logic P0_using, P1_using;
	
	//this for when Kenrick's new SRAM is implemented, probably best to test that this still works first before adding that
	//assign cpu_done_final = cpu_done_M1 & cpu_done_M2;
		
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
			if (P0_request & ~P1_request) //if P0 request, and P1 no request)
				using <= 1'b0;		//let P0 use it
			else if (~P0_request & P1_request)		//if P0 no request, P1 request
				using <= 1'b1;		//let P1 use it
			else if (P0_request & P1_request) //if request from both P0 and P1
				using <= ~using; //if P1 using, let P0 use it, and vice versa	
		end
	end
	
	SRAM test_sram(clk, sram_status/* output stall from SRAM */, sram_WE, sram_RE, sram_addr, sram_WD, MOut_M, SRAM_A, SRAM_D, SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n);
  	
	assign LEDR[0] = P0_stall;
	assign LEDR[1] = P1_stall;
	assign LEDR[2] = P0_rd;
	assign LEDR[3] = P0_wr;
	assign LEDR[4] = P1_rd;
	assign LEDR[5] = P1_wr;
	assign LEDR[6] = sram_WE;
	assign LEDR[7] = sram_RE;
	assign LEDR[8] = sram_status;
	assign LEDR[9] = using;
	
	assign LEDG[7] = MemToReg_D;
	assign LEDG[6] = MemToReg_E;
	assign LEDG[5] = MemToReg_M;
	assign LEDG[4] = MemToReg_W;
	assign LEDG[3] = write_accepted0;
	assign LEDG[2] = write_accepted1;
//	cache_4way_controller cache_2way(MemOp_M, clk, rt_value_M, write_out_M[16:0], MOut_M, Stall_M, rd_sram, wr_sram, rd_RAM_M, MemIn_M);
	
	//SRAM test_sram(clk, Stall_M/* output stall from SRAM */, wr_sram, rd_sram, write_out_M[16:0], MemIn_M, MOut_M, SRAM_A, SRAM_D, SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n);
	
	
//  	sram_controller mem(P0_rd, P0_wr, P1_rd, P1_wr, P0_addr, P1_addr, P0_WD, P1_WD,
//  		sram_status, /*sram_RD,*/ P0_stall,P1_stall, /*P0_data, P1_data,*/ sram_WE, sram_RE,sram_addr,sram_WD, free);
endmodule