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
	logic [7:0] rd_data;
	
	// 4 16-bit flip-flops
	logic [15:0] roll_rt;
	logic [15:0] yaw_rt;
	logic [15:0] AY;
	logic [15:0] AZ;
	
	logic INT_ff1, INT_ff2, cnt_full;
    
    
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
	
	
	typedef enum reg [3:0] { IDLE, INIT0, INIT1, INIT2, INIT3, WAIT, ROLL_L, ROLL_H, Y_L, Y_H, AY_L, AY_H, AZ_L, AZ_H } state_t;
	
	state_t state, nxt_state;
	
	logic vld_en;
	// 16-bit counter
	logic [15:0] cnt;
	
	spi_master iSPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));
    inertial_integrator INERT(.clk(clk),.rst_n(rst_n),.vld(vld),.roll_rt({rollH,rollL}),.yaw_rt({yawH,yawL}),.AY({AYH,AYL}),.AZ({AZH,AZL}),.incline(incline));
	
	
	
	always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cnt <= 16'h0000;
	else
		cnt <= cnt +1'b1;
    end
	
	assign cnt_full = &cnt;
	
	// Double flip-flops for INT signal
    always@(posedge clk) begin
	    INT_ff1 <= INT;
	    INT_ff2 <= INT_ff1;
    end
	
	always_ff@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
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
			rollL = (enable[0]) ? rd_data[7:0] : 0;
			rollH = (enable[1]) ? rd_data[7:0] : 0;
			yawL  = (enable[2]) ? rd_data[7:0] : 0;
			yawH  = (enable[3]) ? rd_data[7:0] : 0;
			AYL   = (enable[4]) ? rd_data[7:0] : 0;
			AYH   = (enable[5]) ? rd_data[7:0] : 0;
			AZL   = (enable[6]) ? rd_data[7:0] : 0;
			AZH   = (enable[7]) ? rd_data[7:0] : 0;
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
	
	
always_comb
begin
	nxt_state = IDLE;
	vld_en = 1'b0;
	cmd = 16'h0000;
	wrt = 1'b0;
	enable = 8'h0;
	
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
			enable[0] = 1'b1;
			nxt_state = ROLL_H;
			cmd = 16'hA5xx;
			wrt = 1'b1;
		end
		else
			nxt_state = ROLL_L;
		end
	ROLL_H: begin
		if(done) begin
			enable[1] = 1'b1;
			nxt_state = Y_L;
			cmd = 16'hA6xx;
			wrt = 1'b1;
		end
		else
			nxt_state = ROLL_H;
		end
	Y_L: begin
		if(done) begin
			enable[2] = 1'b1;
			nxt_state = Y_H;
			cmd = 16'hA7xx;
			wrt = 1'b1;
		end
		else
			nxt_state = Y_L;
		end
	Y_H: begin
		if(done) begin
			enable[3] = 1'b1;
			nxt_state = AY_L;
			cmd = 16'hAAxx;
			wrt = 1'b1;
		end
		else
			nxt_state = Y_H;
		end
	AY_L: begin
		if(done) begin
			enable[4] = 1'b1;
			nxt_state = AY_H;
			cmd = 16'hABxx;
			wrt = 1'b1;
		end
		else
			nxt_state = AY_L;
		end
	AY_H: begin
		if(done) begin
			enable[5] = 1'b1;
			nxt_state = AZ_L;
			cmd = 16'hACxx;
			wrt = 1'b1;
		end
		else
			nxt_state = AY_H;
		end	
	AZ_L: begin
		if(done) begin
			enable[6] = 1'b1;
			nxt_state = AZ_H;
			cmd = 16'hADxx;
			wrt = 1'b1;
		end
		else
			nxt_state = AZ_L;
		end
	AZ_H: begin
		if(done) begin
			enable[7] = 1'b1;
			nxt_state = WAIT;
			vld_en = 1'b1;
		end
		else
			nxt_state = AZ_H;
		end
	default: nxt_state = IDLE;
	endcase
end
endmodule
