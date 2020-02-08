module DFF_8(clk, rst_n, Q, D);

	input logic Q;
	input logic clk;
	input logic rst_n;
	
	output logic D;

    always @(posedge clk, negedge rst_n)
		D <= (!rst_n) ? 1'b0 : Q;

endmodule

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
	
	
	typedef enum reg[4:0] {INIT_EN_INT, INIT_ST_ACC, INIT_ST_GYR, INIT_ST_R,
						   WAIT, WAIT_INT, 
						   RS_rollL, RS_rollH, RS_yawL, RS_yawH,
						   RS_AYL, RS_AYH, RS_AZL, RS_AZH,
						   SET_VLD} state_t;
	
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
	
	// Double flip-flops for INT signal
	logic D, INT_ff2;
	DFF_8 dff1(.clk(clk), .rst_n(rst_n), .Q(INT), .D(D));
	DFF_8 dff2(.clk(clk), .rst_n(rst_n), .Q(D), .D(INT_ff2));
	
	always @(posedge clk) begin
		if(!rst_n)
			state <= INIT_EN_INT;
		else
			state <= next_state;
	end	
	
	assign roll_rt  = {rollH, rollL};
	assign yaw_rt  = {yawH, yawL};
	assign AY = {AYH, AYL};
	assign AZ = {AZH, AZL};
	
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			rollL <= 0;
			rollH <= 0;
			yawL  <= 0;
			yawH  <= 0;
			AYL   <= 0;
			AYH   <= 0;
			AZL   <= 0;
			AZH   <= 0;
		end
		else begin
			rollL <= (enable[0]) ? rd_data[7:0] : rollL;
			rollH <= (enable[1]) ? rd_data[7:0] : rollH;
			yawL  <= (enable[2]) ? rd_data[7:0] : yawL;
			yawH  <= (enable[3]) ? rd_data[7:0] : yawH;
			AYL   <= (enable[4]) ? rd_data[7:0] : AYL;
			AYH   <= (enable[5]) ? rd_data[7:0] : AYH;
			AZL   <= (enable[6]) ? rd_data[7:0] : AZL;
			AZH   <= (enable[7]) ? rd_data[7:0] : AZH;
		end
	end
	
	always @(posedge clk) begin
		if(vld_en)
			vld = 1'b1;
		else	
			vld = 1'b0;
	end
	
	
	always_comb begin
		next_state = INIT_EN_INT;
		wrt = 1'b0;
		cmd = 16'b0;
		enable = 8'b0;
		vld_en = 1'b0;
		case(state)
			INIT_EN_INT: begin
				wrt = 1'b1;
				cmd = 16'h0D02;
				if(done)
					next_state = INIT_ST_ACC;
				else
					next_state = INIT_EN_INT;				
			end
			INIT_ST_ACC: begin
				wrt = 1'b1;
				cmd = 16'h1053;
				if(done)
					next_state = INIT_ST_GYR;
				else
					next_state = INIT_ST_ACC;		
			end
			INIT_ST_GYR: begin
				wrt = 1'b1;
				cmd = 16'h1150;
				if(done)
					next_state = INIT_ST_R;
				else
					next_state = INIT_ST_GYR;		
			end
			INIT_ST_R: begin
				wrt = 1'b1;
				cmd = 16'h1460;
				if(done)
					next_state = WAIT;
				else
					next_state = INIT_ST_R;		
			end
			WAIT: begin
				if(&cnt_16)	
					next_state = WAIT_INT;
				else
					next_state = WAIT;
			end
			WAIT_INT: begin
				if(INT_ff2)
					next_state = RS_rollL;
				else
					next_state = WAIT_INT;
			end
			RS_rollL: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hA4FF;
					next_state = RS_rollL;
				end				
				else begin
					enable[0] = 1'b1;
					next_state = RS_rollH;
				end				
			end
			RS_rollH: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hA5FF;
					next_state = RS_rollH;
				end				
				else begin
					enable[1] = 1'b1;
					next_state = RS_yawL;
				end	
			end
			RS_yawL: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hA6FF;
					next_state = RS_yawL;
				end				
				else begin
					enable[2] = 1'b1;
					next_state = RS_yawH;
				end	
			end
			RS_yawH: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hA7FF;
					next_state = RS_yawH;
				end				
				else begin
					enable[3] = 1'b1;
					next_state = RS_AYL;
				end	
			end
			RS_AYL: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hAAFF;
					next_state = RS_AYL;
				end				
				else begin
					enable[4] = 1'b1;
					next_state = RS_AYH;
				end	
			end
			RS_AYH: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hABFF;
					next_state = RS_AYH;
				end				
				else begin
					enable[5] = 1'b1;
					next_state = RS_AZL;
				end	
			end
			RS_AZL: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hACFF;
					next_state = RS_AZL;
				end				
				else begin
					enable[6] = 1'b1;
					next_state = RS_AZH;
				end	
			end
			RS_AZH: begin	
				if(!done) begin
					wrt = 1'b1;
					cmd = 16'hADFF;
					next_state = RS_AZH;
				end				
				else begin
					enable[7] = 1'b1;
					next_state = SET_VLD;
				end	
			end
			SET_VLD: begin
				vld_en = 1'b1;
				next_state = WAIT_INT;
			end	
		endcase
	end	

endmodule
