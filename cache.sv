//Cache - 8 way with 17 bit address

// FIRST IMPLEMENTATION IS 2-WAY
// CURRENT IMPLEMENTATION IS 4-WAY

//read data - read the tag registers at set_no address and output all their tags (for each way)
/* assign #sets =  //128 sets - need 7 bits
	assign tag_width = //17-7 = 10 bits
	assign data_width = 6'd32 //32 bit
	assign valid_width = 1'b1;
	assign LRU_width = 1'b1; */

module cache_4way_controller (

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
	output logic rd_cpu, wr_cpu, hit_w0, hit_w1, hit_w2, hit_w3, lru_RD0, lru_RD1, lru_RD2, lru_RD3,
	wrdata_en0, wrdata_en1, wrdata_en2, wrdata_en3, error
);
	
	logic [9:0] tag_no, tag_RD0, tag_RD1, tag_RD2, tag_RD3; 
	logic valid_WD0, valid_WD1, valid_WD2, valid_WD3, lru_WD0, lru_WD1, lru_WD2, lru_WD3, /*wrtag_en0, wrtag_en1, wrtag_en2, wrtag_en3,*/ wrvalid_en0, wrvalid_en1, wrvalid_en2, wrvalid_en3, /*wrdata_en0, wrdata_en1, wrdata_en2, wrdata_en3,*/ wrlru_en0, wrlru_en1, wrlru_en2, wrlru_en3, valid_RD0, valid_RD1, valid_RD2, valid_RD3 /*, lru_RD0, lru_RD1, lru_RD2, lru_RD3*/;
	logic [31:0] data_WD0, data_WD1, data_WD2, data_WD3, read_data, data_RD0, data_RD1, data_RD2, data_RD3, cache_data;
	logic [6:0] set_no;
//	logic hit_w0, hit_w1, hit_w2, hit_w3;
	
	//logic rd_cpu, wr_cpu;	//read and write signals from CPU logic
//	logic not_ready_stall;
	
//	assign stall_cpu = (rd_cpu | wr_cpu)? (not_ready_stall | ready_sram): 1'b0;
	//if not_ready_stall = 1, then sram is busy, so stall current processor.
	
	//set number
	assign set_no = addr_cpu[6:0];
	assign tag_no = addr_cpu[16:7];
	
	//Tag registers
	cache_RAM #(7, 10) tag_way0(set_no, tag_no, clk, wrtag_en0, tag_RD0);
	cache_RAM #(7, 10) tag_way1(set_no, tag_no, clk, wrtag_en1, tag_RD1);
	cache_RAM #(7, 10) tag_way2(set_no, tag_no, clk, wrtag_en2, tag_RD2);
	cache_RAM #(7, 10) tag_way3(set_no, tag_no, clk, wrtag_en3, tag_RD3);
	
	//Valid registers
	cache_1bit_RAM #(7) valid_way0(set_no, valid_WD0, clk, wrvalid_en0, valid_RD0);
	cache_1bit_RAM #(7) valid_way1(set_no, valid_WD1, clk, wrvalid_en1, valid_RD1);
	cache_1bit_RAM #(7) valid_way2(set_no, valid_WD2, clk, wrvalid_en2, valid_RD2);
	cache_1bit_RAM #(7) valid_way3(set_no, valid_WD3, clk, wrvalid_en3, valid_RD3);
	
	//Data registers
	cache_RAM #(7, 32) data_way0(set_no, data_WD0, clk, wrdata_en0, data_RD0);
	cache_RAM #(7, 32) data_way1(set_no, data_WD1, clk, wrdata_en1, data_RD1);
	cache_RAM #(7, 32) data_way2(set_no, data_WD2, clk, wrdata_en2, data_RD2);
	cache_RAM #(7, 32) data_way3(set_no, data_WD3, clk, wrdata_en3, data_RD3);

	//LRU registers
	cache_1bit_RAM #(7) LRU_way0(set_no, lru_WD0, clk, wrlru_en0, lru_RD0);
	cache_1bit_RAM #(7) LRU_way1(set_no, lru_WD1, clk, wrlru_en1, lru_RD1);
	cache_1bit_RAM #(7) LRU_way2(set_no, lru_WD2, clk, wrlru_en2, lru_RD2);
	cache_1bit_RAM #(7) LRU_way3(set_no, lru_WD3, clk, wrlru_en3, lru_RD3);
	
	assign hit_w0 = valid_RD0 & (tag_no == tag_RD0);
	assign hit_w1 = valid_RD1 & (tag_no == tag_RD1);
	assign hit_w2 = valid_RD2 & (tag_no == tag_RD2);
	assign hit_w3 = valid_RD3 & (tag_no == tag_RD3);
	assign hit = hit_w0 | hit_w1 | hit_w2 | hit_w3;
	
	assign rd_cpu = F[4] & ~F[3] & ~F[2] & F[1] & F[0];
	assign wr_cpu = F[4] & F[3] & ~F[2] & F[1] & F[0];

	always_comb begin
		if (hit_w0)
			cache_data = data_RD0;
		else if (hit_w1)
			cache_data = data_RD1;
		else if (hit_w2)
			cache_data = data_RD2;
		else
			cache_data = data_RD3;
	end

	assign data_WD0 = rd_cpu? data_fromsram : data_fromcpu;
	assign data_WD1 = rd_cpu? data_fromsram : data_fromcpu;
	assign data_WD2 = rd_cpu? data_fromsram : data_fromcpu;
	assign data_WD3 = rd_cpu? data_fromsram : data_fromcpu;
	
	assign data_tocpu = hit? cache_data : data_fromsram;

	/*each way has lru bit, bit is set when way accessed, 
	when all bits set, all except currently accessed bit are reset, 
	when block replaced, randomly choose block in way with bit off.*/
	always_comb begin
		//Defaults
		lru_WD0 = 1'b0;
		lru_WD1 = 1'b0;
		lru_WD2 = 1'b0;
		lru_WD3 = 1'b0;
		wrlru_en0 = 1'b0;
		wrlru_en1 = 1'b0;
		wrlru_en2 = 1'b0;
		wrlru_en3 = 1'b0;
		rd_sram = 1'b0;
		wr_sram = 1'b0;
		wrtag_en0 = 1'b0;
		wrtag_en1 = 1'b0;
		wrtag_en2 = 1'b0;
		wrtag_en3 = 1'b0;
		valid_WD0 = 1'b0;
		valid_WD1 = 1'b0;
		valid_WD2 = 1'b0;
		valid_WD3 = 1'b0;
		wrvalid_en0 = 1'b0;
		wrvalid_en1 = 1'b0;
		wrvalid_en2 = 1'b0;
		wrvalid_en3 = 1'b0;
		wrdata_en0 = 1'b0;
		wrdata_en1 = 1'b0;
		wrdata_en2 = 1'b0;
		wrdata_en3 = 1'b0;
		data_tosram = data_fromcpu;
		error = 1'b0;
	if (rd_cpu) begin		//if cpu wants to read
		//check for cache miss/hit
		if (hit) begin	//if a hit
			if (hit_w0) begin		//find out which way was hit
				lru_WD0 = 1'b1;				//set LRU bit of the way
				wrlru_en0 = 1'b1;
				if (lru_RD1 & lru_RD2 & lru_RD3) begin		//AND with the other ways once more are added
				 lru_WD1 = 1'b0;
				 wrlru_en1 = 1'b1;
				 lru_WD2 = 1'b0;
				 wrlru_en2 = 1'b1;
				 lru_WD3 = 1'b0;
				 wrlru_en3 = 1'b1;
				end
			end
			else if (hit_w1) begin //else if (hit_w1)
				lru_WD1 = 1'b1;
				wrlru_en1 = 1'b1;
				if (lru_RD0 & lru_RD2 & lru_RD3) begin		//AND with the other ways once more are added
				 lru_WD0 = 1'b0;
				 wrlru_en0 = 1'b1;
				 lru_WD2 = 1'b0;
				 wrlru_en2 = 1'b1;
				 lru_WD3 = 1'b0;
				 wrlru_en3 = 1'b1;
				end
			end
			else if (hit_w2) begin //else if (hit_w1)
				lru_WD2 = 1'b1;
				wrlru_en2 = 1'b1;
				if (lru_RD0 & lru_RD1 & lru_RD3) begin		//AND with the other ways once more are added
				 lru_WD0 = 1'b0;
				 wrlru_en0 = 1'b1;
				 lru_WD1 = 1'b0;
				 wrlru_en1 = 1'b1;
				 lru_WD3 = 1'b0;
				 wrlru_en3 = 1'b1;
				end
			end
			else if (hit_w3) begin //else if (hit_w1)
				lru_WD3 = 1'b1;
				wrlru_en3 = 1'b1;
				if (lru_RD0 & lru_RD2 & lru_RD1) begin		//AND with the other ways once more are added
				 lru_WD0 = 1'b0;
				 wrlru_en0 = 1'b1;
				 lru_WD2 = 1'b0;
				 wrlru_en2 = 1'b1;
				 lru_WD1 = 1'b0;
				 wrlru_en1 = 1'b1;
				end
			end
		end
		else begin	//if miss, fetch from memory
				rd_sram = 1'b1;		//send read signal
				wr_sram = 1'b0;
				//write data to cache
				//if lru bit is off, then write to that
				if (~sram_stalled) begin
					if (~lru_RD0) begin		//If way 0 has lru bit off, then write to that way and set the lru bit: according to lru bit, update tag, data and valid, lru
						wrtag_en0 = 1'b1;
						valid_WD0 = 1'b1;
						wrvalid_en0 = 1'b1;
						wrdata_en0 = 1'b1;
						lru_WD0 = 1'b1;
						wrlru_en0 = 1'b1;
						if (lru_RD1 & lru_RD2 & lru_RD3) begin
							lru_WD1 = 1'b0;
							wrlru_en1 = 1'b1;
							lru_WD2 = 1'b0;
							wrlru_en2 = 1'b1;
							lru_WD3 = 1'b0;
							wrlru_en3 = 1'b1;
						end
					end
					else if (~lru_RD1) begin //else if (lru_RD1) 
						wrtag_en1 = 1'b1;
						valid_WD1 = 1'b1;
						wrvalid_en1 = 1'b1;
						wrdata_en1 = 1'b1;
						lru_WD1 = 1'b1;
						wrlru_en1 = 1'b1;
						if (lru_RD0 & lru_RD2 & lru_RD3) begin			//do for other ways are well once 8-way)
							lru_WD0 = 1'b0;
							wrlru_en0 = 1'b1;
							lru_WD2 = 1'b0;
							wrlru_en2 = 1'b1;
							lru_WD3 = 1'b0;
							wrlru_en3 = 1'b1;
						end
					end
					else if (~lru_RD2) begin //else if (lru_RD1) 
						wrtag_en2 = 1'b1;
						valid_WD2 = 1'b1;
						wrvalid_en2 = 1'b1;
						wrdata_en2 = 1'b1;
						lru_WD2 = 1'b1;
						wrlru_en2 = 1'b1;
						if (lru_RD0 & lru_RD1 & lru_RD3) begin			//do for other ways are well once 8-way)
							lru_WD0 = 1'b0;
							wrlru_en0 = 1'b1;
							lru_WD1 = 1'b0;
							wrlru_en1 = 1'b1;
							lru_WD3 = 1'b0;
							wrlru_en3 = 1'b1;
						end
					end
					else if (~lru_RD3) begin //else if (lru_RD1) 
						wrtag_en3 = 1'b1;
						valid_WD3 = 1'b1;
						wrvalid_en3 = 1'b1;
						wrdata_en3 = 1'b1;
						lru_WD3 = 1'b1;
						wrlru_en3 = 1'b1;
						if (lru_RD0 & lru_RD2 & lru_RD1) begin			//do for other ways are well once 8-way)
							lru_WD0 = 1'b0;
							wrlru_en0 = 1'b1;
							lru_WD2 = 1'b0;
							wrlru_en2 = 1'b1;
							lru_WD1 = 1'b0;
							wrlru_en1 = 1'b1;
						end
					end
					else
						error=1'b1;
				end
		end
	end
	else if (wr_cpu) begin		//if cpu wants to write
			rd_sram = 1'b0;
			wr_sram = 1'b1;
			data_tosram = data_fromcpu; 
		if (hit) begin		//if cache hit, write to cache
			if(hit_w0) begin		//if the hit was from way 0						
				wrtag_en0 = 1'b1;
				valid_WD0 = 1'b1;
				wrvalid_en0 = 1'b1;
				wrdata_en0 = 1'b1;
				lru_WD0 = 1'b1;
				wrlru_en0 = 1'b1;
				if (lru_RD1 & lru_RD2 & lru_RD3) begin
					lru_WD1 = 1'b0;
					wrlru_en1 = 1'b1;
					lru_WD2 = 1'b0;
					wrlru_en2 = 1'b1;
					lru_WD3 = 1'b0;
					wrlru_en3 = 1'b1;
				end
			end
			else if (hit_w1) begin		//if(hit_w1): if the hit was from way 1						
			wrtag_en1 = 1'b1;
			valid_WD1 = 1'b1;
			wrvalid_en1 = 1'b1;
			wrdata_en1 = 1'b1;
			lru_WD1 = 1'b1;
			wrlru_en1 = 1'b1;
				if (lru_RD0 & lru_RD2 & lru_RD3) begin
					lru_WD0 = 1'b0;
					wrlru_en0 = 1'b1;
					lru_WD2 = 1'b0;
					wrlru_en2 = 1'b1;
					lru_WD3 = 1'b0;
					wrlru_en3 = 1'b1;
				end
			end
			else if (hit_w2) begin		//if(hit_w1): if the hit was from way 1						
			wrtag_en2 = 1'b1;
			valid_WD2 = 1'b1;
			wrvalid_en2 = 1'b1;
			wrdata_en2 = 1'b1;
			lru_WD2 = 1'b1;
			wrlru_en2 = 1'b1;
				if (lru_RD0 & lru_RD1 & lru_RD3) begin
					lru_WD0 = 1'b0;
					wrlru_en0 = 1'b1;
					lru_WD1 = 1'b0;
					wrlru_en1 = 1'b1;
					lru_WD3 = 1'b0;
					wrlru_en3 = 1'b1;
				end
			end
			else if (hit_w3) begin		//if(hit_w1): if the hit was from way 1						
			wrtag_en3 = 1'b1;
			valid_WD3 = 1'b1;
			wrvalid_en3 = 1'b1;
			wrdata_en3 = 1'b1;
			lru_WD3 = 1'b1;
			wrlru_en3 = 1'b1;
				if (lru_RD0 & lru_RD2 & lru_RD1) begin
					lru_WD0 = 1'b0;
					wrlru_en0 = 1'b1;
					lru_WD2 = 1'b0;
					wrlru_en2 = 1'b1;
					lru_WD1 = 1'b0;
					wrlru_en1 = 1'b1;
				end
			end
		end
	end
end	
endmodule
