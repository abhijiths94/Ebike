module inert_intf(clk, rst_n, SS_n, SCLK, MOSI, MISO, INT, incline, vld);
input clk, rst_n, MISO, INT;
output reg SS_n, SCLK, MOSI, vld;
output [12:0] incline;
logic wrt, done, INT_ff1, INT_ff2, cnt_full;
logic [15:0] cmd;
logic [7:0] rd_data;
logic [15:0] cnt;
logic [7:0] rollL, rollH, yawL, yawH, AYL, AYH, AZL, AZH;
logic C_R_L, C_R_H, C_Y_L, C_Y_H,C_AY_L,C_AY_H,C_AZ_L,C_AZ_H;
typedef enum reg [3:0] { IDLE, INIT0, INIT1, INIT2, INIT3, WAIT, ROLL_L, ROLL_H, Y_L, Y_H, AY_L, AY_H, AZ_L, AZ_H } state_t;
state_t state, nxt_state;


spi_master iSPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));
inertial_integrator INERT(.clk(clk),.rst_n(rst_n),.vld(vld),.roll_rt({rollH,rollL}),.yaw_rt({yawH,yawL}),.AY({AYH,AYL}),.AZ({AZH,AZL}),.incline(incline));

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cnt <= 16'h0000;
	else
		cnt <= cnt +1'b1;
end

always@(posedge clk) begin
	INT_ff1 <= INT;
	INT_ff2 <= INT_ff1;
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else	
		state <= nxt_state;
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		rollL <= 8'h00;
	else if(C_R_L)	
		rollL <= rd_data[7:0];
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		rollH <= 8'h00;
	else if(C_R_H)	
		rollH <= rd_data[7:0];
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		yawL <= 8'h00;
	else if(C_Y_L)	
		yawL <= rd_data[7:0];
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		yawH <= 8'h00;
	else if(C_Y_H)	
		yawH <= rd_data[7:0];
end
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		AYL <= 8'h00;
	else if(C_AY_L)	
		AYL <= rd_data[7:0];
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		AYH <= 8'h00;
	else if(C_AY_H)	
		AYH <= rd_data[7:0];
end
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		AZL <= 8'h00;
	else if(C_AZ_L)	
		AZL <= rd_data[7:0];
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		AZH <= 8'h00;
	else if(C_AZ_H)	
		AZH <= rd_data[7:0];
end

assign cnt_full = &cnt;

always_comb
begin
	nxt_state = IDLE;
	vld = 1'b0;
	cmd = 16'h0000;
	wrt = 1'b0;
	C_R_L = 1'b0;
	C_R_H = 1'b0;
	C_Y_L = 1'b0;
	C_Y_H = 1'b0;
	C_AY_L = 1'b0;
	C_AY_H = 1'b0;
	C_AZ_L = 1'b0;
	C_AZ_H = 1'b0;
	case(state)
	IDLE: if(cnt_full) begin
		nxt_state = INIT0;
		cmd = 16'h0D02;
		wrt = 1'b1; end
	INIT0: begin 
		if(done) begin
			nxt_state = INIT1;
			cmd = 16'h1053;
			wrt = 1'b1; end
		else
			nxt_state = INIT0;
		end
	INIT1: begin 
		if(done) begin
			nxt_state = INIT2;
			cmd = 16'h1150;
			wrt = 1'b1; end
		else
			nxt_state = INIT1;
		end
	INIT2: begin 
		if(done) begin 
			nxt_state = INIT3;
			cmd = 16'h1460;
			wrt = 1'b1; end
		else
			nxt_state = INIT2;
		end
	INIT3: begin 
		if(done)
			nxt_state = WAIT;
		else
			nxt_state = INIT3;
		end
	WAIT: begin
		if(INT_ff2) begin
			nxt_state = ROLL_L;
			cmd = 16'hA4xx;
			wrt = 1'b1; end
		else
			nxt_state = WAIT;
		end
	ROLL_L: begin
		if(done) begin
			C_R_L = 1'b1;
			nxt_state = ROLL_H;
			cmd = 16'hA5xx;
			wrt = 1'b1;
		end
		else
			nxt_state = ROLL_L;
		end
	ROLL_H: begin
		if(done) begin
			C_R_H = 1'b1;
			nxt_state = Y_L;
			cmd = 16'hA6xx;
			wrt = 1'b1;
		end
		else
			nxt_state = ROLL_H;
		end
	Y_L: begin
		if(done) begin
			C_Y_L = 1'b1;
			nxt_state = Y_H;
			cmd = 16'hA7xx;
			wrt = 1'b1;
		end
		else
			nxt_state = Y_L;
		end
	Y_H: begin
		if(done) begin
			C_Y_H = 1'b1;
			nxt_state = AY_L;
			cmd = 16'hAAxx;
			wrt = 1'b1;
		end
		else
			nxt_state = Y_H;
		end
	AY_L: begin
		if(done) begin
			C_AY_L = 1'b1;
			nxt_state = AY_H;
			cmd = 16'hABxx;
			wrt = 1'b1;
		end
		else
			nxt_state = AY_L;
		end
	AY_H: begin
		if(done) begin
			C_AY_H = 1'b1;
			nxt_state = AZ_L;
			cmd = 16'hACxx;
			wrt = 1'b1;
		end
		else
			nxt_state = AY_H;
		end	
	AZ_L: begin
		if(done) begin
			C_AZ_L = 1'b1;
			nxt_state = AZ_H;
			cmd = 16'hADxx;
			wrt = 1'b1;
		end
		else
			nxt_state = AZ_L;
		end
	AZ_H: begin
		if(done) begin
			C_AZ_H = 1'b1;
			nxt_state = WAIT;
			vld = 1'b1;
		end
		else
			nxt_state = AZ_H;
		end
	default: nxt_state = IDLE;
	endcase
end

endmodule
