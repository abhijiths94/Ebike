module cadence_filt(clk, rst_n, cadence, cadence_filt);

parameter FAST_SIM = 0;

input clk, rst_n, cadence;
output reg cadence_filt;

reg stg1, stg2, stg3;

reg [15 :0] cnt;
wire stable_cnt;

always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		cnt <= 0;
		stg1 <= 0;
		stg2 <= 0;
		stg3 <= 0;
		cadence_filt <= 0;
	end
	else
	begin
		stg1 <= cadence;
		stg2 <= stg1;
		//stg2 is metastable signal
		stg3 <= stg2;
		
		if(stg2 == stg3)
		begin
			cnt <= cnt + 1;
		end
		else
			cnt <= 0;	
		
		cadence_filt <= stable_cnt ? stg3 : cadence_filt;
		
	end

	
	
end	

generate if(FAST_SIM)
	assign stable_cnt = &cnt[8:0];
else
	assign stable_cnt = &cnt;
endgenerate

endmodule