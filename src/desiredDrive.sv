module desiredDrive(clk, rst_n, avg_torque, cadence_vec, incline, setting, target_curr);

input clk, rst_n;
input [11:0]  avg_torque;
input [4:0]   cadence_vec;
input [12:0]  incline;
input [1:0]   setting;
output [11:0] target_curr;

logic [9:0]  incline_sat;
logic [10:0] incline_factor;
logic [8:0]  incline_lim;
logic [5:0] cadence_factor;
logic [11:0] torque_off;
logic [11:0] torque_pos;
logic [28:0] assist_prod, assist_prod1, assist_prod2;

localparam TORQUE_MIN = 12'h380;





//saturated to a 10-bit signed value
assign incline_sat = incline[12] ? (/* negative */ &incline[11:9] ? {1'b1, incline[8:0]} : 10'b1000000000) : ( /* positive */ |incline[11:9] ? 10'b0111111111 : {1'b0, incline[8:0]});
assign incline_factor = {incline_sat[9],incline_sat} + 12'h100;

always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		incline_lim <= 0;
	end
	else begin
		incline_lim <= incline_factor[10] ? /*negetive*/ 0 : /* positive */ (incline_factor[9] ? 511 : incline_factor);
	end
end

//assign incline_lim = incline_factor[10] ? /*negetive*/ 0 : /* positive */ (incline_factor[9] ? 511 : incline_factor);


always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		cadence_factor <= 0;
	end
	else begin
		cadence_factor <= (cadence_vec < 2) ? 0 : cadence_vec + 32;
	end
end

//assign cadence_factor = (cadence_vec < 2) ? 0 : cadence_vec + 32;


always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		torque_off <= 0;
		torque_pos <= 0;
	end
	else begin
		torque_off <= (avg_torque < TORQUE_MIN) ? 0 : avg_torque - TORQUE_MIN;
		torque_pos <= torque_off;
	end
end

//assign torque_off = (avg_torque < TORQUE_MIN) ? 0 : avg_torque - TORQUE_MIN;
//assign torque_pos = torque_off;




always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		assist_prod1 <= 0;
		assist_prod2 <= 0;
		assist_prod  <= 0;
	end
	else begin
		assist_prod1 <= cadence_factor * setting;
		assist_prod2 <= torque_pos * incline_lim;
		assist_prod  <= assist_prod2 * assist_prod1;
	end
end

/* assist_prod = 12bit * 9bit * 6bit * 2bit = 29 bits   */
//assign assist_prod = torque_pos * incline_lim * cadence_factor * setting;
/*
always@(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		target_curr <= 0;
	end
	else begin
		target_curr = |assist_prod[28:26] ? 12'hFFF  : assist_prod[25:14];
	end
end
*/
assign target_curr = |assist_prod[28:26] ? 12'hFFF  : assist_prod[25:14];

endmodule
