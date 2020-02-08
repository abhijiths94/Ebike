module PWM11(clk, rst_n, duty, PWM_sig);
	
	input logic clk, rst_n;
	input logic[10:0] duty;
	
	output logic PWM_sig;

	logic[10:0] cnt;
	logic temp;	

	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			cnt <= 11'b0;
			PWM_sig <= 0;
		end
		else begin			
			if(cnt <= duty)
				PWM_sig <= 1;
			else if(cnt < 12'd2048)
				PWM_sig <= 0;
			cnt <= cnt + 11'b1;
		end

	end
	
endmodule

