module mtr_drv(clk, rst_n, duty, selGrn, selYlw, selBlu, highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu);

input clk, rst_n;
input [10:0] duty;
input [1:0]selGrn, selYlw, selBlu;
output logic highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;

logic PWM_sig;
logic highGrn_in, lowGrn_in;
logic highYlw_in, lowYlw_in;
logic highBlu_in, lowBlu_in;

PWM11 pwm(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(PWM_sig));

nonoverlap n1(.clk(clk), .rst_n(rst_n), .highIn(highBlu_in), .lowIn(lowBlu_in), .highOut(highBlu), .lowOut(lowBlu));
nonoverlap n2(.clk(clk), .rst_n(rst_n), .highIn(highGrn_in), .lowIn(lowGrn_in), .highOut(highGrn), .lowOut(lowGrn));
nonoverlap n3(.clk(clk), .rst_n(rst_n), .highIn(highYlw_in), .lowIn(lowYlw_in), .highOut(highYlw), .lowOut(lowYlw));

muxA mux_selGrn(.A(1'b0), .B(~PWM_sig), .C(PWM_sig), .D(1'b0), .sel(selGrn), .result(highGrn_in));
muxA mux_selYlw(.A(1'b0), .B(~PWM_sig), .C(PWM_sig), .D(1'b0), .sel(selYlw), .result(highYlw_in));
muxA mux_selBlu(.A(1'b0), .B(~PWM_sig), .C(PWM_sig), .D(1'b0), .sel(selBlu), .result(highBlu_in));

muxA mux_selGrn2(.A(1'b0), .B(PWM_sig), .C(~PWM_sig), .D(PWM_sig), .sel(selGrn), .result(lowGrn_in));
muxA mux_selYlw2(.A(1'b0), .B(PWM_sig), .C(~PWM_sig), .D(PWM_sig), .sel(selYlw), .result(lowYlw_in));
muxA mux_selBlu2(.A(1'b0), .B(PWM_sig), .C(~PWM_sig), .D(PWM_sig), .sel(selBlu), .result(lowBlu_in));




endmodule

module muxA(A, B, C, D, sel, result);
input A, B, C, D;
input [1:0] sel;
output reg result;

always_comb begin
	case(sel)
	2'b00: begin
	result = A;
	end
	2'b01: begin
	result = B;
	end
	2'b10: begin
	result = C;
	end
	2'b11: begin
	result = D;
	end
	endcase
end
endmodule
