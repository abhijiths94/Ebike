module telemetry( clk, rst_n, batt_v, curr, torque, TX);

input clk, rst_n;
input [11:0] batt_v, curr, torque;
output TX;


logic smpl, trmt, trmt_ff, tx_done, cnt_en, cnt_rst, shft;
logic [3:0] byte_cnt;
logic [19:0] smpl_cnt;   /// dbg change
logic [63:0] tx_buf;



typedef enum {IDLE, SEND, WAIT1, WAIT} state_t;
state_t state, nxt_state;



UART_tx UART_TX(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt_ff), .tx_data(tx_buf[63:56]), .tx_done(tx_done));



/* 48Hz sample counter */
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		smpl_cnt <= 0;
	end
	else
	begin
		smpl_cnt <= smpl_cnt + 1;
	end
end

/* shift register */
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		tx_buf = {64'h0};
	end
	else if(shft)
	begin
		tx_buf = tx_buf << 8;
	end
	else if(smpl)
	begin
		tx_buf = {8'hAA, 8'h55, {4'h0, batt_v[11:8]}, batt_v[7:0], {4'h0, curr[11:8]}, curr[7:0], {4'h0, torque[11:8]}, torque[7:0]};
	end
end

/* flop transmit to avoid glitches */
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		trmt_ff <= 0;
	end
	else
	begin
		trmt_ff <= trmt;
	end
end

/* byte transfer counter */
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		byte_cnt <= 0;
	end
	else if(cnt_rst)
	begin
		byte_cnt <= 0;
	end
	else if(cnt_en)
	begin
		byte_cnt <= byte_cnt + 1;
	end
end



assign smpl = &smpl_cnt;

always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		state = IDLE;
	else
		state = nxt_state;
end

always_comb
begin
	/* Default inputs */
	nxt_state = state;
	trmt = 0;
	cnt_en = 0;
	cnt_rst = 0;
	shft = 0;
	
	case(state)
	IDLE :
	begin
	if(smpl)
		nxt_state = SEND;
	end
	
	SEND:
	begin
		trmt = 1'b1;
		nxt_state = WAIT1;
		cnt_en = 1'b1;
	end
	
	WAIT1:
	begin
		if(!tx_done)
		begin
			nxt_state = WAIT;
		end
	end
	
	default: //WAIT state
	begin
		if(tx_done)
		begin
			if(byte_cnt == 8)
			begin
				/* reset byte_cnt */
				cnt_rst = 1;
				nxt_state = IDLE;
			end
			else /* more bytes to transmit */
			begin
				shft = 1;	/* shift the tx_buff */
				nxt_state = SEND;
			end
		end
	end
	endcase
end

endmodule