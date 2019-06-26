module SerialPort(
		input clock,
		
		output txOut, //Serial Tx pin
		input [7:0] txByte, //Byte to transmit
		input txBegin, //Begin transmission
		output txReadyOut, //High when finished transmitting the last byte
		
		input rx, //Serial Rx pin
		output [7:0] rxByteOut, //Received byte
		input rxClear, //Set high to clear rxAvailable
		output rxAvailableOut //High while there is a new byte available
	);
	
	//Serial transmit
	logic tx; //Output bit
	logic [9:0] txDelay; //Delay counter for baud rate
	logic [3:0] txBitIndex; //Current bit in a packet
	logic [7:0] txBuffer; //Output buffer
	logic txReady;
	
	//Serial recieve
	logic [9:0] rxDelay; //Delay counter for baud rate
	logic [3:0] rxBitIndex; //Current bit in a packet
	logic [7:0] rxBuffer; //Byte currently being received
	logic [7:0] rxByte; //Last complete byte received
	logic rxReady;
	logic rxAvailable;
	
	assign txOut = tx;
	assign txReadyOut = txReady && ~txBegin;
	assign rxByteOut = rxByte;
	assign rxAvailableOut = rxAvailable;
	
	initial begin
		tx <= 1;
		txDelay <= 10'b0;
		txBitIndex <= 4'b0;
		txBuffer <= 8'b0;
		txReady <= 1;
		
		rxDelay <= 10'b0;
		rxBitIndex <= 4'b0;
		rxBuffer <= 8'b0;
		rxByte <= 8'b0;
		rxReady <= 1;
		rxAvailable <= 0;
	end
	
	
	always @(posedge clock) begin
		//Serial transmit
		if(txReady && txBegin) begin //Finished the last byte and another byte is available
			txBuffer <= txByte; //Load the byte to be sent into the buffer
			txReady <= 0; //Begin transmission
		end
		
		if(!txReady) begin
			if(txDelay == 194) begin //At 50MHz this delay gives 256000 baud rate
				txDelay <= 10'b0;
				
				txBitIndex <= txBitIndex + 4'b1;
				if(txBitIndex == 0) begin //Start bit
					tx <= 0;
				end else if (txBitIndex == 9) begin //Stop bit
					tx <= 1;
				end else if (txBitIndex == 10) begin //Need to wait the full time for the stop bit, otherwise consequtive characters are lost
					txBitIndex <= 0;
					txReady <= 1;
				end else begin //Data bits
					tx <= txBuffer[0]; //Output current bit
					txBuffer <= {txBuffer[0], txBuffer[7:1]}; //Right circular shift by 1
				end
			end else begin
				txDelay <= txDelay + 10'b1;
			end
		end
		
		
		//Serial receive
		if(rxClear) rxAvailable <= 0; //Clear byte available flag
		
		if(rxReady && !rx) begin //Begin receiving on start bit
			rxReady <= 0;
		end
		
		if(!rxReady) begin //Receiving message
			if(rxDelay == 194) begin
				rxDelay <= 10'b0;
				
				rxBuffer[rxBitIndex] <= rx; //Add next bit into buffer
				rxBitIndex <= rxBitIndex + 4'b1;
			end else begin
				rxDelay <= rxDelay + 10'b1;
			end
		end else begin
			rxDelay <= 10'd950; //Start -97 clock cycles so we sample all the other bits in the middle of their periods
		end
		
		if(rxBitIndex == 9) begin
			rxReady <= 1; //Done receiving
			rxAvailable <= 1; //Byte available
			rxByte <= rxBuffer; //Output received byte
			rxBitIndex <= 4'b0;
		end
	end
endmodule 