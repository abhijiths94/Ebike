module PID(clk, rst_n, error , not_pedaling, drv_mag);

parameter FAST_SIM = 0;

input clk, rst_n, not_pedaling ;
input [12:0] error;
output [11:0] drv_mag;

localparam P_coeff = 1;		//set to 1
localparam I_coeff = 1;		// in the range 0 to 4
localparam D_coeff = 7;		// in the range 0 to 64

logic [13:0] P_term; // ?????????????????????
logic [11:0] I_term;
logic [9:0] D_term;


logic [17:0] nxt_integrator, integrator, neg_clip, ov_clip, sampled_integ, dff_inp;
logic pos_ov;

logic [14:0] decimator ;
logic decimator_full;

logic [12:0] d_dff1, d_dff2, d_dff3, D_diff; //store previous 
logic [8:0] diff_sat;
logic [13:0] pid_sum, pid_sum1 ;

/*****************************************************************
 ********************** decimator logic **************************
 *****************************************************************/

/* 20 bit counter to select sampling line */
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		decimator <= 0;
	end
	else
	begin
		decimator <= decimator + 1;
	end
end

generate if (FAST_SIM)
	assign decimator_full= &decimator[14:0];
else 
	assign decimator_full= &decimator;
endgenerate




/****************************************************************
*****************************P Term******************************
*****************************************************************/
//// P_term is simply sign extended error times a constant 1 /////
assign P_term = {error[12],error};


/****************************************************************
*****************************I Term******************************
*****************************************************************/
assign nxt_integrator = integrator + {{5{error[12]}}, error};
assign neg_clip = nxt_integrator[17] ? 18'h0 : nxt_integrator;

assign pos_ov = (~integrator[17])&(~error[12])&(nxt_integrator[17]);
//assign pos_ov = (~integrator[17])&(~error[12])&(nxt_integrator[17]);
assign ov_clip = pos_ov ? 18'h1FFFF : neg_clip ;




assign sampled_integ = decimator_full ? ov_clip : integrator;

assign dff_inp = not_pedaling ? 18'h0 : sampled_integ;

always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		integrator <= 0;
	end
	else
	begin
		integrator <= dff_inp;
	end
end

assign I_term = integrator[16:5];


/****************************************************************
*****************************D Term******************************
*****************************************************************/

always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		d_dff1 <= 0;
		d_dff2 <= 0;
		d_dff3 <= 0;
	end
	else
	begin
		if(decimator_full)
		begin
			d_dff1 <= error;
			d_dff2 <= d_dff1;
			d_dff3 <= d_dff2;
		end
	end
end

/* compute difference of prev error and current error */

assign D_diff = error - d_dff3;

/*sat to 9 bits */
assign diff_sat = D_diff[12] ? (/* negative */ &D_diff[11:8] ? {1'b1, D_diff[7:0]} : 9'b100000000) : 
								( /* positive */ |D_diff[11:8] ? 9'b011111111 : {1'b0, D_diff[7:0]});

assign D_term = diff_sat << 1 ; // multiply by 2;


/****************************************************************
********************* Calculate drv_mag *************************
*****************************************************************/

//assign pid_sum = P_term + {{2{1'b0}},I_term} + {{4{D_term[9]}},D_term};	// sum of P, I , D
always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		pid_sum1 = 0;
		pid_sum  = 0;
	end
	else begin
		pid_sum1 = P_term + {{2{1'b0}},I_term};
		pid_sum  = pid_sum1 + {{4{D_term[9]}},D_term};	// sum of P, I , D
	end
end

assign drv_mag = pid_sum[13] ? (12'h000) : ( pid_sum[12] ? 12'hFFF : pid_sum[11:0] ) ;

endmodule
