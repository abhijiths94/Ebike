module sensorCondition(clk, rst_n, torque, cadence, curr, incline, setting, batt, error, not_pedaling, TX);

parameter FAST_SIM = 1'd1;
input clk, rst_n, cadence;
input [11:0] torque, curr, batt;
input [12:0] incline;
input [1:0] setting;

output [12:0] error;
output not_pedaling, TX;

/* 25 bit vector cadence_per */
logic [24:0] cadence_per ;


logic [4:0] cadence_vec, cadence_cnt;
logic cadence_filt, cadence_filt_ff, cadence_filt_pos, cadence_cnt_clr;

logic not_pedaling_ff, not_pedaling_neg;

logic [11:0] avg_curr;
logic [13:0] curr_accum;  //w = 4 => 12 + 2 = 14 bits 
logic [21:0] include_smpl_curr_cnt;
logic include_smpl_curr;

logic [11:0] avg_torque;
logic [16:0] torque_accum, torque_accum_temp;  //w = 32 => 12 + 5 = 17 bits 

logic [11:0] target_curr;

logic [13:0] curr_accum_temp;


localparam LOW_BATT_THRES = 12'hA98;

cadence_filt #(1)cadence_flt_blk(.clk(clk), .rst_n(rst_n), .cadence(cadence), .cadence_filt(cadence_filt));

/* Cadence_per counter for clearing posedge counter */
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cadence_per <= 0;
	else
		cadence_per <= cadence_per + 1;	
end

generate if (FAST_SIM==1)
	assign cadence_cnt_clr = &cadence_per[15:0];
else
	assign cadence_cnt_clr = &cadence_per;
endgenerate


/* posedge detect for cadence_flt*/
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cadence_filt_ff <= 0;
	else 
		cadence_filt_ff <= cadence_filt;	
end

/* posedge pulse */
assign cadence_filt_pos = cadence_filt & ~cadence_filt_ff;

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cadence_cnt <= 0;
	else if(cadence_cnt_clr)
		cadence_cnt <= 0;
	else if(cadence_filt_pos)
		/* saturate cadence_cnt if it overflows */
		cadence_cnt <= cadence_cnt == 5'h1F ? cadence_cnt : cadence_cnt + 1;	
end

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cadence_vec <= 0;
	else if(cadence_cnt_clr)
		cadence_vec <= cadence_cnt;
end

/* Assert not pedaling if cadence vector is below 2 */
assign not_pedaling = cadence_vec < 5'h02 ? 1 : 0;

/* Negedge detect for not_pedaling*/
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		not_pedaling_ff <= 0;
	else 
		not_pedaling_ff <= not_pedaling;	
end

assign not_pedaling_neg = ~not_pedaling & not_pedaling_ff;



/* Exp averaging for curr */
always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		include_smpl_curr_cnt <= 0;
	else
		include_smpl_curr_cnt <= include_smpl_curr_cnt + 1;
end

generate if(FAST_SIM)
	assign include_smpl_curr = &include_smpl_curr_cnt[15:0];
else
	assign include_smpl_curr = &include_smpl_curr_cnt;
endgenerate


assign curr_accum_temp = (((curr_accum * 3 ) >> 2) + curr);


always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		curr_accum <= 0;
	else begin
		curr_accum <= include_smpl_curr ? curr_accum_temp : curr_accum;
	end
end

assign avg_curr = curr_accum[13:2];


/* Exp averaging for torque */

assign torque_accum_temp = ((torque_accum * 31) >> 5) + torque; 

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		torque_accum <= 0;
	else if(not_pedaling_neg)
		torque_accum <= {1'b0, torque, 4'b0};
	else
		torque_accum <= cadence_filt_pos ? torque_accum_temp : torque_accum;
end

assign avg_torque = torque_accum[16:5];


/* Instantiate desiredDrive module */
desiredDrive Desired_drv(.clk(clk), .rst_n(rst_n), .avg_torque(avg_torque), .cadence_vec(cadence_vec), .incline(incline), .setting(setting), .target_curr(target_curr));


/* Calculate error = target_curr - avg_curr only if batt voltage is above 12'hA98 or if not_pedaling */
assign error = (batt < LOW_BATT_THRES) |  not_pedaling ? 0 : (target_curr - avg_curr) ;

/* Instantiate telemetry module */

telemetry telemetry( .clk(clk), .rst_n(rst_n), .batt_v(batt), .curr(avg_curr), .torque(avg_torque), .TX(TX));



endmodule

