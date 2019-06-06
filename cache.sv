//Cache - 8 way with 17 bit address

// FIRST IMPLEMENTATION IS 2-WAY

//read data - read the tag registers at set_no address and output all their tags (for each way)
/* assign #sets = 6 //64 sets - need 6 bits
	assign tag_width = 4'd11 //17-6 = 11 bits
	assign data_width = 6'd32 //32 bit
	assign valid_width = 1'b1;
	assign LRU_width = 1'b1; */

module cache_8way_controller (

	input logic [4:0] F,
	
	input logic clk,		//Clock input same as CPU and Memory controller(if MemController work on same freq.)	
	input logic [31:0] data_fromcpu,	//Data bus from CPU
	input logic [16:0] addr_cpu,	//Address bus from CPU (and to SRAM)
	input logic [31:0] data_fromsram,	//Data bus from SRAM
	input logic sram_stalled,	//Active High Ready signal from SRAM, to know the status of memory
	//output logic [16:0] addr_sram,	//Address bus to SRAM
	output logic rd_sram,		//Active High Read signal to SRAM
	output logic wr_sram,		//Active High Write signal to SRAM
//	output logic stall_cpu,	//Active High Stall Signal to CPU, to halt the CPU while undergoing any other operation	
	output logic [31:0] data_tocpu,	//data to send to cpu
	output logic [31:0] data_tosram, //data to sram
	output logic hit,
	output logic rd_cpu, wr_cpu, not_ready_stall, valid_RD0, valid_RD1
);
	
	logic [10:0] tag_WD0, tag_WD1, tag_no, tag_RD0, tag_RD1; 
	logic valid_WD0, valid_WD1, lru_WD0, lru_WD1, wrtag_en0, wrtag_en1, wrvalid_en0, wrvalid_en1, wrdata_en0, wrdata_en1, wrlru_en0, wrlru_en1, /*valid_RD0, valid_RD1,*/ lru_RD0, lru_RD1;
	logic [31:0] data_WD0, data_WD1, read_data, data_RD0, data_RD1;
	logic [5:0] set_no;
	logic hit_w0, hit_w1;
	
	//logic rd_cpu, wr_cpu;	//read and write signals from CPU logic
	//logic not_ready_stall;
	
//	assign stall_cpu = (rd_cpu | wr_cpu)? (not_ready_stall | ready_sram): 1'b0;
	//if not_ready_stall = 1, then sram is busy, so stall current processor.
	
	//set number
	assign set_no = addr_cpu[5:0];
	assign tag_no = addr_cpu[16:6];
	
	//Tag registers
	cache_RAM #(6, 11) tag_way0(set_no, tag_WD0, clk, wrtag_en0, tag_RD0);
	cache_RAM #(6, 11) tag_way1(set_no, tag_WD1, clk, wrtag_en1, tag_RD1);
	
	//Valid registers
	cache_1bit_RAM #(6) valid_way0(set_no, valid_WD0, clk, wrvalid_en0, valid_RD0);
	cache_1bit_RAM #(6) valid_way1(set_no, valid_WD1, clk, wrvalid_en1, valid_RD1);
	
	//Data registers
	cache_RAM #(6, 32) data_way0(set_no, data_WD0, clk, wrdata_en0, data_RD0);
	cache_RAM #(6, 32) data_way1(set_no, data_WD1, clk, wrdata_en1, data_RD1);
	
	//LRU registers
	cache_1bit_RAM #(6) LRU_way0(set_no, lru_WD0, clk, wrlru_en0, lru_RD0);
	cache_1bit_RAM #(6) LRU_way1(set_no, lru_WD1, clk, wrlru_en1, lru_RD1);
	
	assign hit_w0 = valid_RD0 & (tag_no == tag_RD0);
	assign hit_w1 = valid_RD1 & (tag_no == tag_RD1);
	assign hit = hit_w0 | hit_w1;
	
	assign rd_cpu = F[4] & ~F[3] & ~F[2] & F[1] & F[0];
	assign wr_cpu = F[4] & F[3] & ~F[2] & F[1] & F[0];
	
	always_comb begin
		//Defaults
		data_tocpu = data_RD0;
		lru_WD0 = 1'b0;
		lru_WD1 = 1'b0;
		wrlru_en0 = 1'b0;
		wrlru_en1 = 1'b0;
		rd_sram = 1'b0;
		wr_sram = 1'b0;
		not_ready_stall = 1'b0;
		tag_WD0 = tag_no;
		tag_WD1 = tag_no;
		wrtag_en0 = 1'b0;
		wrtag_en1 = 1'b0;
		valid_WD0 = 1'b0;
		valid_WD1 = 1'b0;
		wrvalid_en0 = 1'b0;
		wrvalid_en1 = 1'b0;
		data_WD0 = data_fromcpu;
		data_WD1 = data_fromcpu;		
		wrdata_en0 = 1'b0;
		wrdata_en1 = 1'b0;
		data_tosram = data_fromcpu;
	if (rd_cpu) begin		//if cpu wants to read
		//check for cache miss/hit
		if (hit) begin	//if a hit
			if (hit_w0) begin		//find out which way was hit
				data_tocpu = data_RD0;		//transfer data from the way
				lru_WD0 = 1'b1;				//set LRU bit of the way
				wrlru_en0 = 1'b1;
				if (lru_RD1) begin		//AND with the other ways once more are added
				 lru_WD1 = 1'b0;
				 wrlru_en1 = 1'b1;
				end
				else begin
					wrlru_en1 = 1'b0;
				end
			end
			else if (hit_w1) begin //else if (hit_w1)
				data_tocpu = data_RD1;
				lru_WD1 = 1'b1;
				wrlru_en1 = 1'b1;
				if (lru_RD0) begin		//AND with the other ways once more are added
				 lru_WD0 = 1'b0;
				 wrlru_en0 = 1'b1;
				end
				else begin
					wrlru_en0 = 1'b0;
				end
			end
		end
		else begin	//if miss, fetch from memory
			//if (~sram_stalled)	begin	//check if sram ready to receive signal
				rd_sram = 1'b1;		//send read signal
				wr_sram = 1'b0;
				data_tocpu = data_fromsram;
				not_ready_stall = 1'b0;
				//write data to cache
				if (lru_RD0) begin		//according to lru bit, update tag, data and valid, lru
					tag_WD0 = tag_no;
					wrtag_en0 = 1'b1;
					valid_WD0 = 1'b1;
					wrvalid_en0 = 1'b1;
					data_WD0 = data_fromsram;
					wrdata_en0 = 1'b1;
					lru_WD0 = 1'b1;
					wrlru_en0 = 1'b1;
					if (lru_RD1) begin
						lru_WD1 = 1'b0;
						wrlru_en1 = 1'b1;
					end
					else begin
						wrlru_en1 = 1'b0;
					end
				end
				else if (lru_RD1) begin //else if (lru_RD1) 
					tag_WD1 = tag_no;
					wrtag_en1 = 1'b1;
					valid_WD1 = 1'b1;
					wrvalid_en1 = 1'b1;
					data_WD1 = data_fromsram;
					wrdata_en1 = 1'b1;
					lru_WD1 = 1'b1;
					wrlru_en1 = 1'b1;
					if (lru_RD0) begin			//do for other ways are well once 8-way)
						lru_WD0 = 1'b0;
						wrlru_en0 = 1'b1;
					end
					else begin
						wrlru_en0 = 1'b0;
					end
				end
			//end
			else begin //sram is not ready to receive signal, so wait??
				not_ready_stall = 1'b1;
			end
		end
	end
	else if (wr_cpu) begin		//if cpu wants to write
		//if (~sram_stalled) begin	//if sram ready, send write signal and data and address
			rd_sram = 1'b0;
			wr_sram = 1'b1;
			//addr_sram = addr_cpu;
			data_tosram = data_fromcpu; 
//		end
//		else begin
//			rd_sram = 1'b0;
//			wr_sram = 1'b0;
//			not_ready_stall = 1'b1;
//			//addr_sram = addr_cpu;
//			data_tosram = data_fromcpu; 
//		end
		if (hit) begin		//if cache hit, write to cache
			if(hit_w0) begin		//if the hit was from way 0						
			tag_WD0 = tag_no;
			wrtag_en0 = 1'b1;
			valid_WD0 = 1'b1;
			wrvalid_en0 = 1'b1;
			data_WD0 = data_fromcpu;
			wrdata_en0 = 1'b1;
			lru_WD0 = 1'b1;
			wrlru_en0 = 1'b1;
				if (lru_RD1) begin
					lru_WD1 = 1'b0;
					wrlru_en1 = 1'b1;
				end
				else begin
					wrlru_en1 = 1'b0;
				end
			end
			else if (hit_w1) begin		//if(hit_w1): if the hit was from way 1						
			tag_WD1 = tag_no;
			wrtag_en1 = 1'b1;
			valid_WD1 = 1'b1;
			wrvalid_en1 = 1'b1;
			data_WD1 = data_fromcpu;
			wrdata_en1 = 1'b1;
			lru_WD1 = 1'b1;
			wrlru_en1 = 1'b1;
				if (lru_RD0) begin
					lru_WD0 = 1'b0;
					wrlru_en0 = 1'b1;
				end
				else begin
					wrlru_en0 = 1'b0;
				end
			end
		end
		else begin
			wrtag_en0 = 1'b0;
			wrtag_en1 = 1'b0;
			wrvalid_en0 = 1'b0;
			wrvalid_en1 = 1'b0;
			wrdata_en0 = 1'b0;
			wrdata_en1 = 1'b0;
			wrlru_en0 = 1'b0;
			wrlru_en1 = 1'b0;
		end
	end
	else begin //if cpu doesn't want to read or write, disable all control signals
		wrtag_en0 = 1'b0;
		wrtag_en1 = 1'b0;
		wrvalid_en0 = 1'b0;
		wrvalid_en1 = 1'b0;
		wrdata_en0 = 1'b0;
		wrdata_en1 = 1'b0;
		wrlru_en0 = 1'b0;
		wrlru_en1 = 1'b0;
		rd_sram = 1'b0;
		wr_sram = 1'b0;
	end
end	
endmodule
