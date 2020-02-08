module spi_master(clk, rst_n, wrt, cmd, done, rd_data, SS_n, SCLK, MOSI, MISO);
input clk, rst_n, wrt, MISO;
input [15:0] cmd;
output reg done, SCLK, MOSI, SS_n;
output reg [15:0] rd_data;
logic [5:0] sclk_div;
logic shft, init, smpl, ld_sclk, done15, MISO_smpl, set_done, set_ssn, reset_ssn;
logic [3:0] bit_cntr;
logic [15:0] shft_reg;
logic [15:0] shft_reg_ff;
typedef enum reg [1:0] { IDLE, FRONT_PORCH, SHIFT, BACK_PORCH } state_t;
state_t state, nxt_state;

assign SCLK = sclk_div[5];
always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		sclk_div <= 6'h00;
	else if(ld_sclk)
		sclk_div <= 6'b110000;
	else
		sclk_div <= sclk_div + 1'b1;
end

assign done15 = &bit_cntr;

always@(posedge clk) begin
	if(init)
		bit_cntr <= 4'b0000;
	else if(shft)
		bit_cntr <= bit_cntr + 1'b1;
end

always@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		MISO_smpl <= 1'b0;
	else if(smpl)
		MISO_smpl <= MISO;
end 

always@(init or shft)
begin
unique case ({init,shft})
	2'b00: shft_reg_ff = shft_reg;
	2'b01: shft_reg_ff = {shft_reg[14:0], MISO_smpl};
	2'b10: shft_reg_ff = cmd;
	2'b11: shft_reg_ff = cmd;
endcase;
end

assign MOSI = shft_reg[15];

always@(posedge clk)
begin
	shft_reg <= shft_reg_ff;
end

always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else	
		state <= nxt_state;
end

always_comb
begin
	nxt_state = IDLE;
	smpl = 1'b0;
	shft = 1'b0;
	init = 1'b0;
	ld_sclk = 1'b0;
	set_ssn = 1'b0;
	reset_ssn = 1'b1;
	set_done = 1'b0;
	case(state)
	IDLE: if(wrt) begin
		ld_sclk = 1'b1;
		set_ssn = 1'b1;
		init = 1'b1;
		nxt_state = FRONT_PORCH;
		end 
	FRONT_PORCH: begin
		if(sclk_div == 6'b111111)
			nxt_state = SHIFT;
		else if(sclk_div == 6'b011111)begin
			smpl = 1'b1;
			nxt_state = FRONT_PORCH; end
		else
			nxt_state = FRONT_PORCH; end
	SHIFT: begin
		if(!done15) begin
			if(sclk_div == 6'b111111)
				shft = 1'b1;
			else if(sclk_div == 6'b011111)
				smpl = 1'b1; 
			nxt_state = SHIFT;
			end
		else
			nxt_state = BACK_PORCH;
		end
	BACK_PORCH: begin
			if(sclk_div == 6'b111111) begin
				ld_sclk = 1'b1; 
				shft = 1'b1;
				reset_ssn = 1'b0;
				set_done = 1'b1;
			end
			else if(sclk_div == 6'b011111) begin
				smpl = 1'b1;
				nxt_state = BACK_PORCH; end
			else
				nxt_state = BACK_PORCH;
			end
	default: nxt_state = IDLE;
	endcase
end

assign rd_data = shft_reg;

always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		done <= 1'b0;
	else if(init)
		done <= 1'b0;
	else begin
		done <= set_done;
	end
end

always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		SS_n <= 1'b1;
	else if(!reset_ssn)
		SS_n <= 1'b1;
	else if(set_ssn)
		SS_n <= 1'b0;
end

endmodule

