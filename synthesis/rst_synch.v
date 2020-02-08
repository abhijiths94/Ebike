module rst_synch(RST_n, clk, rst_n);
	input wire RST_n;
	input wire clk;
	
	output rst_n;
	
	reg ff1;
	reg ff2;
	
	always @(negedge clk, negedge RST_n) begin
		if(!RST_n) begin
			ff1 <= 0;
			ff2 <= 0;
		end else begin
			ff1 <= 1;
			ff2 <= ff1;
		end
	end
	
	assign rst_n = ff2;
	
endmodule
