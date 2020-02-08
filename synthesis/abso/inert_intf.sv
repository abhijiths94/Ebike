/* ABSO changed */
module inert_intf(clk, rst_n, INT, SS_n, SCLK, MOSI, MISO, incline, vld);
	input logic clk;
	input logic rst_n;
	input logic INT;
	input logic MISO;
	output logic SS_n;
	output logic SCLK;
	output logic MOSI;
	output logic [12:0] incline;
	output logic vld;
	
	logic [15:0] cmd;
	logic done;
	logic wrt;
	logic [15:0] rd_data;
	
	// 4 16-bit flip-flops
	logic [15:0] roll_rt;
	logic [15:0] yaw_rt;
	logic [15:0] AY;
	logic [15:0] AZ;
	
	logic INT_ff1, INT_ff2, cnt_full;

	
	SPI_mstr spi(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt),
				  .cmd(cmd), .done(done), .rd_data(rd_data));
				  
	inertial_integrator inrt_it(.clk(clk), .rst_n(rst_n), .vld(vld),
								 .roll_rt(roll_rt),
								 .yaw_rt(yaw_rt),
								 .AY(AY), 
								 .AZ(AZ), 
								 .incline(incline));
	
	// 8 8-bit flip flops
	logic [7:0] rollL;
	logic [7:0] rollH;
	logic [7:0] yawL;
	logic [7:0] yawH;
	logic [7:0] AYL;
	logic [7:0] AYH;
	logic [7:0] AZL;
	logic [7:0] AZH;
	logic [7:0] enable;	
	
	
	typedef enum reg[4:0] {IDLE, INIT_EN_INT, INIT_ST_ACC, INIT_ST_GYR, INIT_ST_R,
				WAIT, RS_rollL, RS_rollH, RS_yawL, RS_yawH,
				RS_AYL, RS_AYH, RS_AZL, RS_AZH} state_t;
	
	state_t state, next_state;
	
	logic vld_en;
	// 16-bit counter
	logic [15:0] cnt_16;
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cnt_16 = 16'b0;
		else
			cnt_16 = cnt_16 + 1'b1;
	end
	
	assign cnt_full = &cnt_16;
	
	// Double flip-flops for INT signal
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			INT_ff1 <= 0;
			INT_ff2 <= 0;
		end
		else begin
			INT_ff1 <= INT;
			INT_ff2 <= INT_ff1;
		end
	end
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	end	
	
	assign roll_rt  = {rollH, rollL};
	assign yaw_rt  = {yawH, yawL};
	assign AY = {AYH, AYL};
	assign AZ = {AZH, AZL};
	
	always @(posedge clk, negedge rst_n ) begin
		if(!rst_n) begin
			rollL = 8'h0;
			rollH = 8'h0;
			yawL  = 8'h0;
			yawH  = 8'h0;
			AYL   = 8'h0;
			AYH   = 8'h0;
			AZL   = 8'h0;
			AZH   = 8'h0;
		end
		else begin
			rollL = (enable[0]) ? rd_data[7:0] : rollL;
			rollH = (enable[1]) ? rd_data[7:0] : rollH;
			yawL  = (enable[2]) ? rd_data[7:0] : yawL;
			yawH  = (enable[3]) ? rd_data[7:0] : yawH;
			AYL   = (enable[4]) ? rd_data[7:0] : AYL;
			AYH   = (enable[5]) ? rd_data[7:0] : AYH;
			AZL   = (enable[6]) ? rd_data[7:0] : AZL;
			AZH   = (enable[7]) ? rd_data[7:0] : AZH;
		end
	end
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			vld = 1'b0;
		end
		else begin
			if(vld_en)
				vld = 1'b1;
			else	
				vld = 1'b0;
		end
	end
	
	
	always_comb begin
		next_state = state;
		wrt = 1'h0;
		//cmd = 16'h0;
		enable = 8'h0;
		vld_en = 1'h0;
		case(state)
			IDLE : begin
				if(cnt_full) begin
					next_state = INIT_EN_INT;
					wrt = 1'b1;
					cmd = 16'h0D02;
				end
			end
			INIT_EN_INT: begin
				if(done) begin
					next_state = INIT_ST_ACC;
					wrt = 1'b1;
					cmd = 16'h1053;
				end
			end
			INIT_ST_ACC: begin
				if(done) begin
					next_state = INIT_ST_GYR;
					wrt = 1'b1;
					cmd = 16'h1150;
				end		
			end
			INIT_ST_GYR: begin
				if(done) begin
					next_state = INIT_ST_R;
					wrt = 1'b1;
					cmd = 16'h1460;
				end		
			end
			INIT_ST_R: begin
				if(done) begin
    				cmd = 16'h0;
					next_state = WAIT;
				end	
			end
			WAIT: begin
				if(INT_ff2) begin
					wrt = 1'b1;
					cmd = 16'hA4FF;
					next_state = RS_rollL;
				end
			end
			RS_rollL: begin	
				if(done) begin
					enable[0] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hA5FF;
					next_state = RS_rollH;
				end								
			end
			RS_rollH: begin	
				if(done) begin
					enable[1] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hA6FF;
					next_state = RS_yawL;
				end	
			end
			RS_yawL: begin	
				if(done) begin
					enable[2] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hA7FF;
					next_state = RS_yawH;
				end	
			end
			RS_yawH: begin	
				if(done) begin
					enable[3] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hAAFF;
					next_state = RS_AYL;
				end	
			end
			RS_AYL: begin	
				if(done) begin
					enable[4] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hABFF;
					next_state = RS_AYH;
				end	
			end
			RS_AYH: begin	
				if(done) begin
					enable[5] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hACFF;
					next_state = RS_AZL;
				end	
			end
			RS_AZL: begin	
				if(done) begin
					enable[6] = 1'b1;
					wrt = 1'b1;
					cmd = 16'hADFF;
					next_state = RS_AZH;
				end	
			end
			RS_AZH: begin	
				if(done) begin
					enable[7] = 1'b1;
					vld_en = 1'b1;
					next_state = WAIT;
					cmd = 16'h0;
				end	
			end
			default: next_state = IDLE;
		endcase
	end
endmodule
