module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);

	input clk;
	input rst_n;
	input logic highIn;
	input logic lowIn;
	
	output logic highOut;
	output logic lowOut;
	
	logic[4:0] cnt;
	logic die = 1'b0, change = 1'b0;

	always @(highIn or lowIn) begin			
		change = 1'b1;
	end
		
	always@(posedge clk)	begin
		if (!rst_n)
			cnt = 0;
		else if(!change)
			cnt = 0;
		else if(!(&cnt))
			cnt = cnt + 1;
		else
			cnt = cnt;			
	end
	
	always @(posedge clk) begin
		
		highOut = (change)? (&cnt)? highIn : 1'b0 : highIn;
		lowOut  = (change)? (&cnt)? lowIn  : 1'b0 : lowIn;
		
		// if(change) begin
			// cnt = 0;
			// die  = 1;
		// end
		// if((die == 1'b1) & (rst_n == 1'b1)) begin
			// if(&cnt != 1) begin
				// highOut  = 1'b0;
				// lowOut	 = 1'b0;
				// cnt  = cnt + 1'b1;
			// end else begin
				// cnt  = 5'b0;
				// highOut  = highIn;
				// lowOut  = lowIn;
				// die  = 0;
			// end
		// end
		// else if(rst_n)begin
			// highOut  = highIn;
			// lowOut  = lowIn;
			// cnt = 5'b0;
		// end else begin
			// highOut  = 1'b0;
			// lowOut = 1'b0;
			// cnt = 5'b0;
		// end
	end
	

endmodule





//module nonoverlap(clk, rst_n, highIn, lowIn, highOut, lowOut);
//
//input clk;            //50 Mhz clk
//input rst_n;        //async negative reset
//input highIn;    //Control for high side FET
//input lowIn;    //Control for low side FET
//output reg highOut;    //Control for high side FET with ensured non overlap
//output reg lowOut;    //Control for low side FET with ensured non overlap
//reg deadTime;
//reg [4:0]cnt;
//reg changed_high, changed_low;
//reg changed;
//reg highbuf,lowbuf;
//always@(posedge clk)
//begin
//highbuf = highIn;
//lowbuf = lowIn;
//
//end
//always@(posedge clk )
//	begin
//			  if(highIn!=highbuf)
//					changed_high=1;
//			  else
//					changed_high=0;
//			  if(lowIn!=lowbuf)
//					changed_low=1;
//			  else
//					changed_low=0;
//		lowOut = (changed)? (deadTime)? lowIn:1'b0 :lowIn;
//		highOut =(changed)? (deadTime)? highIn:1'b0 :highIn;
//
//	end
//assign changed = changed_high|changed_low;
//
//always@(posedge clk  )
//begin
//        if (!rst_n)
//        cnt = 0;
//        else if(changed)
//        cnt = 0;
//        else if(cnt!=31)
//        cnt = cnt + 1;
//        else
//        cnt = cnt;
//        deadTime = &cnt;
//end
//endmodule