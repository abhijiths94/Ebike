module SPI_mstr(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, cmd, done, rd_data);

input clk, rst_n, MISO, wrt;
input [15:0] cmd;
output reg done, SCLK, MOSI, SS_n;
output reg [15:0] rd_data;

reg [5:0] cnt_sclk; //6 bit counter to generate SCLK
reg [4:0] bit_cntr; // 4 bit counter to count shifts 

///////////////////////////////////////////////////////////////
////////////////////// SM Variables //////////////////////////
/////////////////////////////////////////////////////////////
reg  ld_SCLK;      
reg shift, sample, init;

reg sclk_pos, sclk_neg;

/* shift register variables */
reg [15:0] shift_reg;
reg sample_bit, set_done, clear_done ;

typedef enum {IDLE, FRONT, SMPL, SHFT, BACK} state_t;
state_t state, nxt_state;
reg start_clk;

assign SCLK = cnt_sclk[5];

/* Generate the sclk from clk 
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		cnt_sclk <= 6'b110000;
		sclk_neg <= 0;
		sclk_pos <= 0;
	end
	else if(ld_SCLK)
	begin
		cnt_sclk <= 6'b110000;
		sclk_neg <= 0;
		sclk_pos <= 0;
	end
	else if (start_clk)
	begin
		if(cnt_sclk == 16'h3F)
		begin
			// Special condtion to handle negedge 
			cnt_sclk <= 16'h0000;
			sclk_neg <= 1;
			sclk_pos <= 0;
		end
		else if(cnt_sclk == 16'h1F)
		begin
			// Special condtion to handle posedge 
			sclk_pos <= 1;
			sclk_neg <= 0;
		end
		else
		begin
			// Increment clock counter 
			cnt_sclk <= cnt_sclk + 1;
			sclk_neg <= 0;
			sclk_pos <= 0;
		end
	end
	else
	begin
		sclk_neg <= 0;
		sclk_pos <= 0;
	end
end
*/


always@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		cnt_sclk <= 6'b0;
		sclk_neg <= 0;
		sclk_pos <= 0;
	end
	else if(ld_SCLK)
	begin
		cnt_sclk = 6'b110000;
		sclk_neg = 0;
		sclk_pos = 0;
	end
	else if (start_clk)
	begin
		if(cnt_sclk == 16'h3F)
		begin
			/* Special condtion to handle negedge */
			cnt_sclk = 16'h0000;
			sclk_pos = 0;
			sclk_neg = 1;
		end
		else
		begin
			/* Increment clock counter */
			cnt_sclk = cnt_sclk + 1;
			sclk_neg = 0;
			sclk_pos = 0;
		end
		
		/* Special condtion to handle posedge */
		if(cnt_sclk == 16'h1F)
		begin
			sclk_pos = 1;
			sclk_neg = 0;
		end
	end
	else
	begin
		sclk_neg = 0;
		sclk_pos = 0;
	end
end

always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		done <= 1'b0;
	else
		if(set_done)
			done <= 1;
		else if(clear_done)
			done <= 0;
end

/* Shift register */
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
	begin
		bit_cntr = 0;
		rd_data = 0;
		shift_reg = 0;
	end
	else
	begin
		if(bit_cntr == 5'h11)
			bit_cntr = 5'b0;
		
		if(sample)
		begin
			// posedge detected sample
			rd_data = {rd_data[14:0],MISO};
			
		end
		else if(shift)
		begin
			// negedge detected shift
			shift_reg = shift_reg << 1;
			bit_cntr = (bit_cntr + 1);
		end
		else if(init)
		begin
			//load value to shift register 
			shift_reg = cmd;
		end
	end
end

assign MOSI = shift_reg[15];


/***************************************
*   done - 15 bits done (i/p) to SM
*	sample - sample the MISO
*	shift - shift reg for MOSI
*	ld_SCLK - load clk with initial value
*   start_clk - start clk
*	init - init the blocks
* 	set_done - tx/rx done , set the done bit 
--------------------------------------
*	wrt
* 	clk
* 	rst_n 
****************************************/

/* state machine */
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		state = IDLE;
	else
		state = nxt_state;
end


always_comb
begin
	//default outputs
	sample = 0;
	shift = 0;
	ld_SCLK = 0;
	init = 0;
	set_done = 0; 
	clear_done = 0;
	nxt_state = state ;
	start_clk = 1;
	SS_n = 0;
	
	case(state)	
		IDLE:
		begin
			start_clk = 0;
			SS_n = 1;
			if(wrt)
			begin
				clear_done = 1;
				/* wrt asserted, start the state machine*/
				ld_SCLK = 1;
				init = 1;
				nxt_state = FRONT;
			end
		end
		
		FRONT:
		begin
			ld_SCLK = 0;
			start_clk = 1;
			init = 0;
			if(sclk_pos)
			begin
				nxt_state = SMPL;
			end
		end
		SMPL:
		begin
			/* Sample the value on MISO */
			sample = 1;
			nxt_state = SHFT;
		end
		SHFT:
		begin
			/* Shift the value in the shift register */
			if(sclk_neg)
			begin
				shift = 1;
			end
			
			if(sclk_pos)
			begin
				if(bit_cntr == 5'h10)
				begin
					//sample = 1;
					nxt_state = BACK;
				end
				else
					nxt_state = SMPL;
				
			end
		end
		
		default : //BACK case
		begin
			/* Back porch condition, shift one last time and assert SS_n */
			shift = 1;
			SS_n = 1;
			set_done = 1;
			nxt_state = IDLE;
		end
	endcase
end


endmodule