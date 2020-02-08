module brushless(input clk, input [11:0]drv_mag, input hallGrn, input hallYlw, input hallBlu, input brake_n, output [10:0]duty,	output reg [1:0]sel_grn, output reg [1:0]sel_yellow, output reg [1:0]sel_blue);
	reg[2:0] rotation_state;				
	
	assign rotation_state = {hallGrn,hallYlw,hallBlu};
	assign duty = (!brake_n) ? 11'h600 : 11'h400+drv_mag[11:2];

	always_comb begin
		case(rotation_state) 
			3'b111:begin
				if(!brake_n)begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
					end
				else begin
					sel_grn = 2'b00;
					sel_yellow = 2'b00;
					sel_blue = 2'b00;
					end
				end
			3'b101: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b10;
					sel_yellow = 2'b01;
					sel_blue = 2'b00;
				end
			end
			3'b100: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b10;
					sel_yellow = 2'b00;
					sel_blue = 2'b01;
				end
			end
			3'b110: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b00;
					sel_yellow = 2'b10;
					sel_blue = 2'b01;
				end
			end
			3'b010: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b01;
					sel_yellow = 2'b10;
					sel_blue = 2'b00;
				end
			end
			3'b011: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b01;
					sel_yellow = 2'b00;
					sel_blue = 2'b10;
				end
			end
			3'b001: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b00;
					sel_yellow = 2'b01;
					sel_blue = 2'b10;
				end
			end
			3'b000: begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b00;
					sel_yellow = 2'b00;
					sel_blue = 2'b00;
				end
			end
			default:begin
				if(!brake_n) begin
					sel_grn = 2'b11;
					sel_yellow = 2'b11;
					sel_blue = 2'b11;
				end
				else begin
					sel_grn = 2'b00;
					sel_yellow = 2'b00;
					sel_blue = 2'b00;
				end
			end
		endcase

	end

endmodule
				
