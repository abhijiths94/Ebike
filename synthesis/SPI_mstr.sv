module SPI_mstr(clk, rst_n, wrt, cmd, done, rd_data, SS_n, SCLK, MOSI, MISO);

    input clk;
    input rst_n;
    input wrt;
    input MISO;
    input [15:0] cmd;
    output logic done, SCLK, MOSI, SS_n;
    output logic [15:0] rd_data;
	
	/* State machine and intermediate variables */
	logic shft, clr_bit_cntr, smpl, ld_sclk, bit_cntr_full, smpl_MISO, set_done, set_ssn, reset_ssn;
    logic [3:0] bit_cntr;
    logic [5:0] sclk_div;
    logic [15:0] shft_reg;
    logic [15:0] shft_reg_ff;
    
    typedef enum reg [1:0] {IDLE, FRONT, SHIFT, BACK } state_t;
    state_t state, nxt_state; 
	
	/* Counter to track no of bits shifted */
    always@(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			bit_cntr <= 4'h0;
		end
		else if(clr_bit_cntr)
		    bit_cntr <= 4'h0;
	    else if(shft)
		    bit_cntr <= bit_cntr + 1'b1;
    end
	
	/* Leading bit of sclk_div is SCLK */
    assign SCLK = sclk_div[5];
	
	/* Generating SCLK from sclk_div counter */
    always@(posedge clk, negedge rst_n)
    begin
	    if(!rst_n)
		    sclk_div <= 6'h00;
	    else if(ld_sclk) begin
		    sclk_div <= 6'b110000;
		end
	    else begin
		    sclk_div <= sclk_div + 1'b1;
		end
    end
	
	/* MSB of shift register is MOSI */
    assign MOSI = shft_reg[15];
	
	/* Sample MISO on posedge of SCLK which is signalled through FSM */
    always@(posedge clk, negedge rst_n) begin
	    if(!rst_n)
		    smpl_MISO <= 1'b0;
	    else if(smpl)
		    smpl_MISO <= MISO;
    end 

	/* ???????????? 
    always_comb begin
    case ({clr_bit_cntr,shft})
	2'b00: shft_reg_ff = shft_reg;
    2'b01: shft_reg_ff = {shft_reg[14:0], smpl_MISO};
    2'b10: shft_reg_ff = cmd;
    2'b11: shft_reg_ff = cmd;
    endcase;
    end
	*/
    
	/* shift register */
    always@(posedge clk, negedge rst_n)
    begin
		if(!rst_n)
			shft_reg <= 0;
		else if(clr_bit_cntr)
			/* load new data on clear on transition to FRONT */
			shft_reg <= cmd;
		else if(shft)
			shft_reg <= {shft_reg[14:0], smpl_MISO};
    end
	
	/* Set done signal */
	always@(posedge clk, negedge rst_n)
    begin
	    if(!rst_n)
		    done <= 1'b0;
	    else if(clr_bit_cntr)
		    done <= 1'b0;
	    else begin
		    done <= set_done;
	    end
    end

	/* Set/reset SS_n */
    always@(posedge clk, negedge rst_n)
    begin
	    if(!rst_n)
		    SS_n <= 1'b1;
	    else if(!reset_ssn)
		    SS_n <= 1'b1;
	    else if(set_ssn)
		    SS_n <= 1'b0;
    end

	/* FSM */
    always @(posedge clk, negedge rst_n)
    begin
	    if(!rst_n)
		    state <= IDLE;
	    else	
		    state <= nxt_state;
    end

    always_comb
    begin
		/* Default all sm variables*/
	    nxt_state = IDLE;
	    smpl = 1'b0;
	    shft = 1'b0;
	    clr_bit_cntr = 1'b0;
	    ld_sclk = 1'b0;
	    set_ssn = 1'b0;
	    reset_ssn = 1'b1;
	    set_done = 1'b0;
		
	    case(state)
	    IDLE: if(wrt) begin
		    ld_sclk = 1'b1;
		    set_ssn = 1'b1;
		    clr_bit_cntr = 1'b1;
		    nxt_state = FRONT;
		    end 
	    FRONT: begin
		    if(sclk_div == 6'b111111)
			    nxt_state = SHIFT;
		    else if(sclk_div == 6'b011111)begin
			    smpl = 1'b1;
			    nxt_state = FRONT; end
		    else
			    nxt_state = FRONT; end
	    SHIFT: begin
		    if(!(&bit_cntr)) begin
			    if(sclk_div == 6'b111111)
				    shft = 1'b1;
			    else if(sclk_div == 6'b011111)
				    smpl = 1'b1; 
			    nxt_state = SHIFT;
			    end
		    else
			    nxt_state = BACK;
		    end
	    BACK: begin
			    if(sclk_div == 6'b111111) begin
				    ld_sclk = 1'b1; 
				    shft = 1'b1;
				    reset_ssn = 1'b0;
				    set_done = 1'b1;
			    end
			    else if(sclk_div == 6'b011111) begin
				    smpl = 1'b1;
				    nxt_state = BACK; end
			    else
				    nxt_state = BACK;
			    end
	    default: nxt_state = IDLE;
	    endcase
    end

    assign rd_data = shft_reg;

   

endmodule

