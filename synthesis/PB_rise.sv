module PB_rise(PB, clk, rst_n, rise);
	input logic PB;
	input logic clk;
	input logic rst_n;
	
	output logic rise;
	
	reg ff1;
	reg ff2;
	reg ff3;
	
	always	@(posedge clk)
		if(!rst_n) begin
			ff1 <= 1;
			ff2 <= 1;
			ff3 <= 1;
		end else begin
			ff1 <= PB;
			ff2 <= ff1;
			ff3 <= ff2;
		end
	
	assign rise = ff2 & (~ff3);
endmodule
