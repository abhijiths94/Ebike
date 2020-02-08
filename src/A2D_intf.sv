module A2D_intf(input logic clk,
		input logic rst_n,
		input logic MISO,
		output logic[11:0] batt,
		output logic[11:0] curr,
		output logic[11:0] brake,
		output logic[11:0] torque,
		output logic SS_n,
		output logic SCLK,
		output logic MOSI);
				

	logic en_batt,en_brake,en_curr,en_torq,wrt;
	logic[15:0] rd_data;
	logic[2:0] channel_inter,channel;
	SPI_mstr iSPI( .done(done), .rd_data(rd_data), .cmd({2'b00,channel,11'h0}), .wrt(wrt), 
					 .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .clk(clk), .rst_n(rst_n));
	logic[3:0] n;
	logic[13:0] cnt;
	logic[1:0] c_cnt;
	logic cnv_cmplt;
	
	typedef enum reg[2:0] {SEND,PRECIEVE,RECEIVE,PSEND} state_t;
	state_t state,nxt_state;

	always@(posedge clk)begin
		if(!rst_n) 
			cnt <= 14'h0;
		/*else if (done)
			cnt <= 14'h0;*/
		else
			cnt <= cnt + 1;
	end
	always@(posedge clk)begin
		if(!rst_n) 
			state <= SEND;
		else
			state <= nxt_state;
	end

	assign channel = (!(|c_cnt)) ? 3'b000 : 
						(c_cnt == 2'b01) ? 3'b001 :
						(c_cnt == 2'b10) ? 3'b011 :
						(c_cnt == 2'b11) ? 3'b100 : 3'b111;

	always_ff @(posedge clk)
		c_cnt = (!rst_n)? 1'b0 : (cnv_cmplt) ? c_cnt + 1'b1 : c_cnt;
	
	assign en_batt  = (c_cnt == 2'b00 && cnv_cmplt) ? 1'b1 : 1'b0;								//0
	assign en_curr  = (c_cnt == 2'b01 && cnv_cmplt) ? 1'b1 : 1'b0;								//1
	assign en_brake = (c_cnt == 2'b10 && cnv_cmplt) ? 1'b1 : 1'b0;								//2
	assign en_torq  = (c_cnt == 2'b11 && cnv_cmplt) ? 1'b1 : 1'b0;								//3	

	always_comb begin
		nxt_state = SEND;
		cnv_cmplt = 0;
		wrt = 1'b0;
		
		case (state)
			SEND: begin
				if(&cnt) begin
					wrt = 1'b1;
					nxt_state = PRECIEVE;
				end
			end
			PRECIEVE: begin
				if(done)
					nxt_state = RECEIVE;	
				else
					nxt_state = PRECIEVE;
			end
			RECEIVE: begin
				if(&cnt) begin
					wrt = 1'b1;
					nxt_state = PSEND;					
				end
				else
					nxt_state = RECEIVE;
			end
			PSEND: begin
				if(done) begin
					nxt_state = SEND;
					cnv_cmplt = 1;
				end
				else
					nxt_state = PSEND;
			end		
		endcase
				
	end
	
	
	always@(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			batt <= 12'h0;
			curr <= 12'h0;
			brake <= 12'h0;
			torque <= 12'h0;
		end
		else begin
			batt <= (en_batt) ? rd_data[11:0] : batt;
			curr <= (en_curr) ? rd_data[11:0] : curr;
			torque <= (en_torq) ? rd_data[11:0] : torque;
			brake <= (en_brake) ? rd_data[11:0] : brake;
		end
	end
		
		
		
		
		
		
		
		
		
/*		case(state)
		send:begin
				en_batt=1'b0;
				en_curr=1'b0;
				en_brake=1'b0;
				en_torq=1'b0;
				wrt=1'b0;
				if(cnt==14'h3FFF) begin
					channel=channel_inter;
				end
				else begin
					channel=3'b111;
				end
				if(done==1'b1)
				begin
					nxt_state=pause_recieve;
					
				end
				else begin
					nxt_state=send;
				end
		end
		pause_recieve:begin
				nxt_state=receive;
		end
		receive:begin
			if(done) begin
				if(cnt==14'h3FFF)
				conv_cmplt=1'b1;
				else conv_cmplt=1'b0;
					if(conv_cmplt) begin
							if(!rst_n)
								rr_cnt = 1'b0;
									else
									rr_cnt = rr_cnt + 1'b1;	
						wrt=1'b1;
						en_batt=~(&channel);
						en_curr=(channel[0])&(~(&channel[2:1]));
						en_brake=channel[1]&channel[0]&(~channel[2]);
						en_torq=(~channel[0])&(~channel[1])&channel[2];
						nxt_state = send;
					end
					else begin
						rr_cnt = rr_cnt;
						en_batt=1'b0;
						en_curr=1'b0;
						en_brake=1'b0;
						en_torq=1'b0;
						wrt=1'b0;
					end
			end
			else begin
				rr_cnt = rr_cnt;
				en_batt=1'b0;
				en_curr=1'b0;
				en_brake=1'b0;
				en_torq=1'b0;
				wrt=1'b0;
			end
		end
		pause_send:nxt_state=send;
		default:begin
					rr_cnt = 2'b00;
					en_batt=1'b0;
					en_curr=1'b0;
					en_brake=1'b0;
					en_torq=1'b0;
					wrt=1'b0;
		end
		endcase
		end
	always@(posedge clk,negedge rst_n) begin
	if(!rst_n) begin
	batt <= 12'h0;
	curr <= 12'h0;
	brake <= 12'h0;
	torque <= 12'h0;
	end
	else begin
	batt <= (en_batt) ? rd_data[11:0] : batt;
	curr <= (en_curr) ? rd_data[11:0] : curr;
	torque <= (en_torq) ? rd_data[11:0] : torque;
	brake <= (en_brake) ? rd_data[11:0] : brake;
	end
	end
	/*dff12_bit batt_reg(.q(batt), .d([11:0]rd_data), .wen(en_batt), .clk(clk), .rst_n(rst_n));
	dff12_bit curr_reg(.q(curr), .d([11:0]rd_data), .wen(en_curr), .clk(clk), .rst_n(rst_n));
	dff12_bit brake_reg(.q(brake), .d([11:0]rd_data), .wen(en_brake), .clk(clk), .rst_n(rst_n));
	dff12_bit torque_reg(.q(torque), .d([11:0]rd_data), .wen(en_torq), .clk(clk), .rst_n(rst_n));*/
endmodule
