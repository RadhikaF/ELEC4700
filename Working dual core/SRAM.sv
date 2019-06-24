module SRAM(
	input clock,
	
	//CPU interface
	output cpuStall,
	input cpuDoneFlag,
	input cpuWriteEnable,
	input cpuReadEnable,
	
	input [16:0] cpuAddress,
	input [31:0] cpuWriteData,
	output [31:0] readData,

	//SRAM interface
	output [17:0] SRAM_A,
	inout [15:0] SRAM_D,
	output SRAM_CE_n, SRAM_LB_n, SRAM_UB_n, SRAM_OE_n, SRAM_WE_n,
	
	//Serial interface
	input UART_RX,
	output UART_TX
);
	//Spend 1 cycle accessing the lower 16 bit word and then another for the upper 16 bit word
	logic currentWord;
	logic sramStall;
	logic [1:0] opDelay;
	logic [15:0] readBuffer; //Hold the lower 16 bits while waiting for the upper 16 bits
	logic [15:0] writeBuffer; //Buffer output to solve timing
	
	logic [17:0] sramAddress;
	logic [31:0] sramWriteData;
	logic sramWriteEnable, sramReadEnable;
	
	initial begin
		opDelay = 0;
		readBuffer = 0;
		writeBuffer = 0;
		SRAM_A = 0;
		SRAM_WE_n = 1;
	end
	
	//3 cycle read and write operations
	//First cycle spent buffering outputs, other two spent reading the lower and upper words
	
	always @(posedge clock) begin
		if (sramWriteEnable | sramReadEnable) begin
			if (opDelay == 2)
				opDelay <= 0;
			else
				opDelay <= opDelay + 2'b1;
		end
		
		if (opDelay == 1)
			readBuffer <= SRAM_D;
		
		SRAM_A <= sramAddress;
		writeBuffer <= (currentWord ? sramWriteData[31:16] : sramWriteData[15:0]);
		SRAM_WE_n <= ~ (sramWriteEnable & opDelay != 0);
	end
	
	assign currentWord = (sramReadEnable & opDelay >= 1) | (sramWriteEnable & opDelay >= 2);
	assign sramStall = (sramWriteEnable | sramReadEnable) & opDelay != 2;
	assign cpuStall = sramStall | ~cpuActive;


	//Static SRAM assignments
	assign SRAM_CE_n = 1'b0; //Enable chip
	assign SRAM_LB_n = 1'b0; //Enable lower byte
	assign SRAM_UB_n = 1'b0; //Enable upper byte
	assign SRAM_OE_n = 1'b0; //Enable output (overridden by WE)
	
	assign SRAM_D = sramWriteEnable ? writeBuffer : 16'bZ;

	assign readData = {SRAM_D, readBuffer};
	
	assign sramAddress = (state == 3) ? {cpuAddress, currentWord} : {serialMemoryAddress, currentWord};
	assign sramWriteData = (state == 3) ? cpuWriteData : serialWriteData;
	assign sramWriteEnable = (state == 3) ? cpuWriteEnable : serialWriteEnable;
	assign sramReadEnable = (state == 3) ? cpuReadEnable : serialReadEnable;
	
	//Serial - SRAM interface
	logic [16:0] serialMemoryAddress;
	logic [31:0] serialWriteData, serialReadData;
	logic serialWriteEnable, serialReadEnable;
	
	//Serial state
	logic [31:0] state;
	logic [1:0] rxByteIndex, txByteIndex;
	logic [31:0] rxWordBuffer, txWordBuffer;
	logic rxWordReady, txWordReady;
	
	logic cpuActive;
	logic [31:0] cpuTimer, cpuMemoryOperationCounter;
	
	initial begin
		serialWriteEnable = 0;
		serialReadEnable = 0;
		
		state = 0;
		rxByteIndex = 0;
		txByteIndex = 0;
		rxWordReady = 0;
		txWordReady = 1;
		serialMemoryAddress = 17'b11111111111111111;
		
		cpuActive = 0;
		cpuTimer = 0;
		cpuMemoryOperationCounter = 0;
	end
	
	always @(posedge clock) begin
		if(~sramStall) begin
			// Transmit word
			if(~txWordReady & txReadyOut) begin
				txByte <= txWordBuffer[31:24];
				txWordBuffer <= {txWordBuffer[23:0], 8'b0};
				txBegin <= 1;
			
				txByteIndex <= txByteIndex + 1;
				if(txByteIndex == 3)
					txWordReady <= 1;
			end else begin
				txBegin <= 0;
			end
			
			// Receive word
			if(rxAvailableOut) begin
				rxWordBuffer <= {rxWordBuffer[23:0], rxByteOut};
				
				rxByteIndex <= rxByteIndex + 1;
				if(rxByteIndex == 3)
					rxWordReady <= 1;
			end
			
			//Clear indicator bits
			if(rxWordReady)
				rxWordReady <= 0;
			
			if(serialWriteEnable)
				serialWriteEnable <= 0;
				
			if(serialReadEnable) begin
				serialReadEnable <= 0;
				serialReadData <= readData; //Need to buffer it because the SRAM controller resets currentWord on the next clock tick
			end
			
			//Handle current state
			if (serialMemoryAddress == 10000) begin
				state <= 0;
				serialMemoryAddress <= 17'b11111111111111111;
			end else if(state == 0 & rxWordReady) begin
				state <= rxWordBuffer;
			end else if(state == 1 & rxWordReady) begin //Write content of SRAM
				serialWriteData <= rxWordBuffer;
				serialWriteEnable <= 1;
				serialMemoryAddress <= serialMemoryAddress + 1;
			end else if(state == 2 & txWordReady) begin //Read content of SRAM
				txWordBuffer <= serialReadData;
				txWordReady <= 0;
				serialReadEnable <= 1;
				serialMemoryAddress <= serialMemoryAddress + 1;
			end else if(state == 4) begin //Output number of cycles elapsed
				txWordBuffer <= cpuTimer;
				txWordReady <= 0;
				state <= 0;
			end else if(state == 5) begin //Output number of cycles that were spent doing memory operations
				txWordBuffer <= cpuMemoryOperationCounter;
				txWordReady <= 0;
				state <= 0;
			end else if(state == 6) begin //Output static value so we can check connection
				txWordBuffer <= 123456789;
				txWordReady <= 0;
				state <= 0;
			end else if(state > 6) begin
				state <= 0;
			end
		end
		
		if(state == 3) begin //Run CPU
			if(cpuDoneFlag) begin
				state <= 0;
				cpuActive <= 0;
			end else begin
				if(cpuWriteEnable | cpuReadEnable) begin
					cpuMemoryOperationCounter <= cpuMemoryOperationCounter + 1;
				end
				
				cpuTimer <= cpuTimer + 1;
				cpuActive <= 1;
			end
		end
	end
	
	assign rxClear = (~sramStall & rxAvailableOut);
	
	logic [7:0] txByte, rxByteOut;
	logic txBegin, txReadyOut, rxClear, rxAvailableOut;
	
	SerialPort serialPort(clock,
									UART_TX, txByte, txBegin, txReadyOut,
									UART_RX, rxByteOut, rxClear, rxAvailableOut);

endmodule 