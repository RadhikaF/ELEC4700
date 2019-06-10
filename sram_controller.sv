//Memory controller

/* Scenarios:
	P0 request & SRAM free
	P1 request & SRAM free
	P0 request & SRAM busy (P1 using)
	P1 request & SRAM busy (P0 using)
	P0 & P1 simulataneous request
	Idle (no requests)	*/

module sram_controller (
	//from cache controller of processor 0 (P0) and processor 1 (P1)
	input logic P0_read_req, P0_write_req, P1_read_req P1_write_req,  //read/write requests from processors
	input logic [16:0] P0_addr, P1_addr, //address from processor to read/write to
	input logic [31:0] P0_WD, P1_WD,		//data from processor (to write to sram)
	//sram input
	input logic sram_status, 	//status of sram
	input logic [31:0] sram_RD, //data read from sram
	//cpu output
	output logic P0_stall, P1_stall, //stall signals to processors
	output logic [31:0] P0_data, P1_data, //data from sram to send to procesor
	//sram output
	output logic sram_WE, sram_RE, //write/read enable sram
	output logic [16:0] sram_addr, //address to write to in sram
	output logic [31:0] sram_WD //data to write in sram
);

//if there is no request, clear stall signal
//if there is a request, send sram stall signal or busy signal to indicate the sram is used by other Processor
logic P0_request, P1_request, P0_using, P1_using;
// logic [] P0WD_queue, P0WA_queue, P1WD_queue, P1WA_queue;
assign P0_request = P0_read_req | P0_write_req;
assign P1_request = P1_read_req | P1_write_req;
assign P0_data = sram_RD;
assign P1_data = sram_RD;
assign P0_stall = P0_request? (sram_status | P0_request_flag):1'b0; //stall when it is using sram/when request denied ADD 
assign P1_stall = P1_request? (sram_status | P1_request_flag):1'b0;

always_comb begin
	//add defaults
	P0_using = 1'b0;
	P1_using = 1'b0;
	sram_WE = 1'b0;
	sram_RE = 1'b0;
	sram_addr = P0_addr;
	sram_WD = P0_WD;
	if (P0_request) begin		//check sram availability 
		if (~sram_status) begin //if sram_status = 0 then it is free
			if (P0_using) begin // the request from P0 is complete
				P0_using = 1'b0;
				//check if P1 wants to use (if P1_request_flag = 1), if so let P1 use sram next
			end
			else begin
				P0_using = 1'b1;
				if (P0_read_req) begin		//send read signal to sram with cpu address
					sram_WE = 1'b0;
					sram_RE = 1'b1;
					sram_addr = P0_addr;
					// P0_stall = 1'b1;
				end
				else if (P0_write_req) begin		//send write signal with address and data
					sram_WE = 1'b1;
					sram_RE = 1'b0;
					sram_addr = P0_addr;
					sram_WD = P0_WD;
					// P0_stall = 1'b1;
				end
			end
		end
		// else begin		//sram busy so P1 must be using it
		// 	P0_request_flag = 1'b1;	//set flag indicating P0 is waiting to use sram
		// 	// P0WD_queue = P0_WD;
		// 	// P0WA_queue = P0_addr;
		// end
	end
	if (P1_request) begin		//check sram availability 
		if (~sram_status) begin //if sram_status = 0 then it is free
			if (P1_using) begin //the request from P1 is complete
				P1_using = 1'b0;
			end
			else begin
				P1_using = 1'b1;
				if (P1_read_req) begin		//send read signal to sram with cpu address
					sram_WE = 1'b0;
					sram_RE = 1'b1;
					sram_addr = P1_addr;
					// P1_stall = 1'b1;
				end
				else if (P1_write_req) begin		//send write signal with address and data
					sram_WE = 1'b1;
					sram_RE = 1'b0;
					sram_addr = P1_addr;
					sram_WD = P1_WD;
					// P1_stall = 1'b1;
				end
			end
		end
		// else if (P1_using) begin
		// 	P1_using = 1'b1;
		// else begin		//sram busy so P1 must be using it
		// 	P1_request_flag = 1'b1;	//set flag indicating P0 is waiting to use sram
		// 	// P1WD_queue = P1_WD;
		// 	// P1WA_queue = P1_addr;
		// end
	end
end
endmodule // memory_controller



/*Two Processors - controller that controls access to shared memory. Have a bus coming in and out 
from each Processor. Output bus carries the signal saying whether the Processor wants to access 
main mem. Input bus will carry the signal saying whether it is allowed to access the Processor yet. 
If not then the pipeline needs to be stalled.
Inside controller - input logic bus from two Processors. If Processor one wants the memory, provided it, 
end stall signal if P 2 also wants it (don’t send if it doesn’t want). Set a flag indicating 
Processor 1 is using the sram. If Processor 2 wants to use it while P 1 is using it, stall P 2. 
Then once P 1 is finished, check the flag to see which P just finished. If it was P 1 that 
has just accessed it, and you see that P 2 wants it then give to P 2.

Input P0_request, P1_request, P0_done, P1_done
Output P0_access, P1_access, P0_stall, P1_stall

assign P0_request = P0_read_req | P0_write_req;
assign P1_request = P1_read_req | P1_write_req;

If P0_request
	check sram availability 
	if ~sram_status //if sram_status = 0 then it is free
		if P_read_req
			send read signal to sram with cpu address
		else if P_write_req

	Set P0_access
	Clear P0_stall
	P0using = 1
If P1_request
	If P0using
		Set P1_stall
		Clear P1_access
*/