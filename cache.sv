//Cache - 8 way with 17 bit address

// FIRST IMPLEMENTATION IS 2-WAY

module RAM #(parameter N=5, W=8) (
	input logic [N-1:0] Ad,
	input logic [W-1:0] Din,
	input logic Clk, En,
	output logic [W-1:0] Dout);
	
	logic [W-1:0] array[2**N-1:0];
	assign Dout = array[Ad];
	
	always_ff @ (posedge Clk)
		if(En) array[Ad] <= Din;
	
endmodule

//read data - read the tag registers at set_no address and output all their tags (for each way)

module cache_8way_controller (


	input	logic clk,		//Clock input same as CPU and Memory controller(if MemController work on same freq.)
	input	logic reset,	//Active Low Asynchronous Reset Signal Input
	
	inout	[31:0]	data_cpu,	//Bi-directional Data bus from CPU
	inout	[31:0]	data_sram,	//Bi-directional Data bus to Main Memory
	
	input	[16:0]	addr_cpu,	//Address bus from CPU

	output logic [16:0] addr_sram,	//Address bus to Main Memory

	input logic rd_cpu,		//Active High Read signal from CPU
	input logic wr_cpu,		//Active High WRITE signal from CPU

	output logic rd_sram,		//Active High Read signal to Main Memory
	output logic wr_sram,		//Active High Write signal to Main Memory

	output logic stall_cpu,	//Active High Stall Signal to CPU, to halt the CPU while undergoing any other operation	
	input logic ready_sram	//Active High Ready signal from Main memory, to know the status of memory

);
	logic [16:0] addrlatch;
	logic [31:0] wrdata;
	logic rdwr; //1 if read, 0 if write
	logic hit_w0, hit_w1, hit;

	logic [10:0] tag_WD0, tag_WD1, tag_no, tag_RD0, tag_RD1; 
	logic valid_WD0. valid_WD1, lru_WD0, lru_WD1, wrtag_en0, wrtag_en1, wrvalid_en0, wrvalid_en1, wrdata_en0, wrdata_en1, wrlru_en0, wrlru_en1, valid_RD0, valid_RD1, lru_RD0, lru_RD1;
	logic [31:0] data_WD0, data_WD1, read_data, data_RD0, data_RD1;
	logic [5:0] set_no;
	assign set_size = 6 //64 sets - need 6 bits
	assign tag_size = 11 //17-6 = 11 bits
	assign data_size = 32 //32 bit
	assign valid_size = 1
	assign LRU_size = 1
	
	assign set_no = (current_state == IDLE) ? addr_sram[5:0]:addrlatch[5:0];
	assign tag_no = (current_state == IDLE) ? addr_sram[16:6]:addrlatch[16:6];
	
	//data to SRAM and cpu
	assign data_cpu = read_data;
	assign data_sram = wrdata;
	
	//*********************************************************INITIALISE VALID REGISTERS TO ZERO INITIALLY
	//Tag registers
	RAM #(set_size, tag_size) tag_way0(set_no, tag_WD0, clk, wrtag_en0, tag_RD0);
	RAM #(set_size, tag_size) tag_way1(set_no, tag_WD1, clk, wrtag_en1, tag_RD1);

	//Valid registers
	RAM #(set_size, valid_size) valid_way0(set_no, valid_WD0, clk, wrvalid_en0, valid_RD0);
	RAM #(set_size, valid_size) valid_way1(set_no, valid_WD1, clk, wrvalid_en1, valid_RD1);

	//Data registers
	RAM #(set_size, data_size) data_way0(set_no, data_WD0, clk, wrdata_en0, data_RD0);
	RAM #(set_size, data_size) data_way1(set_no, data_WD1, clk, wrdata_en1, data_RD1);

	//LRU registers
	RAM #(set_size, LRU_size) LRU_way0(set_no, lru_WD0, clk, wrlru_en0, lru_RD0);
	RAM #(set_size, LRU_size) LRU_way1(set_no, lru_WD1, clk, wrlru_en1, lru_RD1);
	
	assign hit_w0 = valid_RD0 & (tag_no == tag_RD0);
	assign hit_w1 = valid_RD1 & (tag_no == tag_RD1);
	assign hit = hit_w0 | hit_w1;
	
	typedef enum logic [2:0] {IDLE, READ, WAITFORMM, UPDATECACHE, WRITE, WRITECACHE, WRITEMM} state;
	state current_state;
	
	always_ff @(posedge clk)
		begin
			if (reset)
			begin
				current_state <= IDLE;
				addrlatch <= 17'd0;
				wrtag_en0 <= 1'b0;
				wrtag_en1 <= 1'b0;
				wrvalid_en0 <= 1'b0;
				wrvalid_en1 <= 1'b0;
				wrdata_en0 <= 1'b0;
				wrdata_en1 <= 1'b0;
				wrlru_en0 <= 1'b0;
				wrlru_en1 <= 1'b0;
				stall_cpu <= 1'b0;
				rdwr <= 1'b1; //initially in read state
				tag_WD0 <= 11'b0; 
				tag_WD1	<= 11'b0
				valid_WD0 <= 1'b0;
				valid_WD1 <= 1'b0;
				data_WD0 <= 32'b0;
				data_WD1 <= 32'b0
				lru_WD0 <= 1'b0;
				lru_WD1 <= 1'b0;
				wrdata <= 32'b0;
				wr_sram <= 1'b0; 
			end
			else begin
				case (current_state)
					IDLE: begin
						addrlatch <= addr_cpu;	//latch the address so it doesn't change even if addr_cpu changes
						wrtag_en0 <= 1'b0;				//disable write enables to the cache registers
						wrtag_en1 <= 1'b0;
						wrvalid_en0 <= 1'b0;
						wrvalid_en1 <= 1'b0;
						wrdata_en0 <= 1'b0;
						wrdata_en1 <= 1'b0;
						wrlru_en0 <= 1'b0;
						wrlru_en1 <= 1'b0;
						stall_cpu <= 1'b0;
						rd_sram <= 1'b0;			//kept high until data is read from main memory
						wr_sram <= 1'b0;
						//********************************************
						if (rd_cpu) begin
							current_state <= READ;
							rdwr <= 1'b1;		//set this bit to indicate request to read
						end
						else if (wr_cpu) begin
							current_state <= WRITE;
							wrdata <= data_cpu;		//latch data to be written
							rdwr <= 1'b0;			//clear this bit to indicate request to write
						end
						else
						rdwr <= 1'b1;
							current_state <= current_state;
						end
					READ: begin
					//check for read hit or miss in cache.
					//If hit -> select respective way and push data to cpu, jump to idle
						wrtag_en0 <= 1'b0;				//disable write enables to the cache registers
						wrtag_en1 <= 1'b0;
						wrvalid_en0 <= 1'b0;
						wrvalid_en1 <= 1'b0;
						wrdata_en0 <= 1'b0;
						wrdata_en1 <= 1'b0;
						wr_sram <= 1'b0;
						if (hit) begin
							current_state <= IDLE;
							rd_sram <= 1'b0;
							//***************************MORE
							if(hit_w0) begin		//if the hit was from way 0
								read_data <= data_RD0;		//latch the data from way 0 (to be sent to cpu)
								lru_WD0 <= 1'b1;
								wrlru_en0 <= 1'b1;			//enable the write for lru registers
								//check if all the lru bits for the ways are 1 or will become 1 after this lru bit is set
								if (lru_RD1) begin		//AND with the other ways once more are added
									lru_WD1 <= 1'b0;
									wrlru_en1 <= 1'b1;
								end
							end
							else if (hit_w1) begin
								read_data <= data_RD1;
								lru_WD1 <= 1'b1;
								wrlru_en1 <= 1'b1;
								if (lru_RD0) begin
									lru_WD0 <= 1'b0;
									wrlru_en0 <= 1'b1;
								end
							end
						end
						else begin
						//if a miss occurs, fetch data from memory
							wrlru_en0 <= 1'b0;
							wrlru_en1 <= 1'b0;						
							stall_cpu <= 1'b1;
							addr_sram <= addrlatch;
							if (ready_sram) begin			//check if sram is ready to receive a new request
								rd_sram <= 1'b1;
								current_state <= WAITFORMM;
							end
							else begin
								rd_sram <= 1'b0;
								current_state <= current_state;
							end
						end
					end
					WAITFORMM: begin
						if(ready_sram) begin
							if (rdwr)
								current_state <= UPDATECACHE;
							else
								current_state <= IDLE;
							rd_sram <= 1'b0;	//disable read signal to sram
							wr_sram <= 1'b0; //disable write signal to sram
						end
						else begin
							current_state <= current_state;
							//WHAT IF YOU ARE WRITING????
						end
					end
					UPDATECACHE: begin	//memory is read so fetch the data and send it to cpu and update cache (data and tag and LRU)
						current_state <= IDLE;
						read_data <= data_sram;		//update cache according to LRU policy
						if (lru_RD0) begin		//according to lru bit, update tag, data and valid, lru
							tag_WD0 <= tag_no;
							wrtag_en0 <= 1'b1;
							valid_WD0 <= 1'b1;
							wrvalid_en0 <= 1'b1;
							data_WD0 <= data_sram;
							wrdata_en0 <= 1'b1;
							lru_WD0 <= 1'b1;
							wrlru_en0 <= 1'b1;
							if (lru_RD1) begin
								lru_WD1 <= 1'b0;
								wrlru_en1 <= 1'b1;
							end
						end
						else if (lru_RD1) begin
							tag_WD1 <= tag_no;
							wrtag_en1 <= 1'b1;
							valid_WD1 <= 1'b1;
							wrvalid_en1 <= 1'b1;
							data_WD1 <= data_sram;
							wrdata_en1 <= 1'b1;
							lru_WD1 <= 1'b1;
							wrlru_en1 <= 1'b1;
							if (lru_RD0) begin			//do for other ways are well once 8-way)
								lru_WD0 <= 1'b0;
								wrlru_en0 <= 1'b1;
							end
						end
					end
					WRITE: begin
						stall_cpu <= 1'b1;
						if (hit) begin
							if(hit_w0) begin		//if the hit was from way 0						
							tag_WD0 <= tag_no;
							wrtag_en0 <= 1'b1;
							valid_WD0 <= 1'b1;
							wrvalid_en0 <= 1'b1;
							data_WD0 <= data_cpu;
							wrdata_en0 <= 1'b1;
							lru_WD0 <= 1'b1;
							wrlru_en0 <= 1'b1;
								if (lru_RD1) begin
									lru_WD1 <= 1'b0;
									wrlru_en1 <= 1'b1;
								end
							end
							if(hit_w1) begin		//if the hit was from way 0						
							tag_WD1 <= tag_no;
							wrtag_en1 <= 1'b1;
							valid_WD1 <= 1'b1;
							wrvalid_en1 <= 1'b1;
							data_WD1 <= data_cpu;
							wrdata_en1 <= 1'b1;
							lru_WD1 <= 1'b1;
							wrlru_en1 <= 1'b1;
								if (lru_RD0) begin
									lru_WD0 <= 1'b0;
									wrlru_en0 <= 1'b1;
								end
							end
						end
						if (ready_sram)
							current_state <= WRITEMM;
					end
					WRITEMM: begin
						addr_sram <= addrlatch;
						if (ready_sram) begin
							wr_sram <= 1'b1;
							current_state <= WAITFORMM;
						end
						else begin
							wr_sram <= 1'b0;
							current_state <= current_state;
						end
					end	
					default: begin
						rd_sram <= 1'b0;
						wr_sram <= 1'b0;
						addrlatch <= 17'd0;
						wrtag_en0 <= 1'b0;
						wrtag_en1 <= 1'b0;
						wrvalid_en0 <= 1'b0;
						wrvalid_en1 <= 1'b0;
						wrdata_en0 <= 1'b0;
						wrdata_en1 <= 1'b0;
						wrlru_en0 <= 1'b0;
						wrlru_en1 <= 1'b0;
						stall_cpu <= 1'b0;
						rdwr <= 1'b1; //initially in read state
						tag_WD0 <= 11'b0; 
						tag_WD1	<= 11'b0
						valid_WD0 <= 1'b0;
						valid_WD1 <= 1'b0;
						data_WD0 <= 32'b0;
						data_WD1 <= 32'b0
						lru_WD0 <= 1'b0;
						lru_WD1 <= 1'b0;
						wrdata <= 32'b0;
					end
endmodule
