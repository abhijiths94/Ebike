 module eBike(clk,RST_n,A2D_SS_n,A2D_MOSI,A2D_SCLK,
             A2D_MISO,hallGrn,hallYlw,hallBlu,highGrn,
			 lowGrn,highYlw,lowYlw,highBlu,lowBlu,
			 inertSS_n,inertSCLK,inertMOSI,inertMISO,
			 inertINT,cadence,TX,tgglMd,setting);
			 
  input clk;				// 50MHz clk
  input RST_n;				// active low RST_n from push button
  output A2D_SS_n;			// Slave select to A2D on DE0
  output A2D_SCLK;			// SPI clock to A2D on DE0
  output A2D_MOSI;			// serial output to A2D (what channel to read)
  input A2D_MISO;			// serial input from A2D
  input hallGrn;			// hall position input for "Green" phase
  input hallYlw;			// hall position input for "Yellow" phase
  input hallBlu;			// hall position input for "Blue" phase
  output highGrn;			// high side gate drive for "Green" phase
  output lowGrn;			// low side gate drive for "Green" phase
  output highYlw;			// high side gate drive for "Yellow" phase
  output lowYlw;			// low side gate drive for "Yellow" phas
  output highBlu;			// high side gate drive for "Blue" phase
  output lowBlu;			// low side gate drive for "Blue" phase
  output inertSS_n;			// Slave select to inertial (tilt) sensor
  output inertSCLK;			// SCLK signal to inertial (tilt) sensor
  output inertMOSI;			// Serial out to inertial (tilt) sensor  
  input inertMISO;			// Serial in from inertial (tilt) sensor
  input inertINT;			// Alerts when inertial sensor has new reading
  input cadence;			// pulse input from pedal cadence sensor
  input tgglMd;				// used to select setting[1:0] (from PB switch)
  output reg [1:0] setting;	// 11 => easy, 10 => normal, 01 => hard, 00 => off
  output TX;				// serial output of measured batt,curr,torque
  
  ///////////////////////////////////////////////
  // Declare any needed internal signals here //
  /////////////////////////////////////////////
  wire rst_n;									// global reset from reset_synch
  wire [11:0] batt,curr,brake,torque;
  wire [10:0] duty;
  wire [1:0] selGrn, selYlw, selBlu;
  wire [11:0] drv_mag;		// pid instantiation - todo
  //wire INT;
  wire [12:0] error;
  wire [12:0] inertIncline;
  
  logic brake_n;
  
  wire en_tgglMd;
  
  
  ///////// Any needed macros follow /////////
  parameter FAST_SIM = 0;
  
  
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  rst_synch irst(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
  
  ///////////////////////////////////////////////////////
  // Instantiate A2D_intf to read torque & batt level //
  /////////////////////////////////////////////////////
  A2D_intf iDUT(.clk(clk),.rst_n(rst_n),.batt(batt),
                .curr(curr),.brake(brake),.torque(torque),
				.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
				.MOSI(A2D_MOSI),.MISO(A2D_MISO));
				 
  ////////////////////////////////////////////////////////////
  // Instantiate SensorCondition block to filter & average //
  // readings and provide cadence_vec, and zero_cadence   //
  // Don't forget to pass FAST_SIM parameter!!           //
  ////////////////////////////////////////////////////////
  sensorCondition #(FAST_SIM) isensorCondition(.clk(clk), .rst_n(rst_n), 
				.torque(torque), .cadence(cadence), .curr(curr), 
				.incline(inertIncline), .setting(setting), .batt(batt),
				.error(error), .not_pedaling(not_pedaling), .TX(TX));

  ///////////////////////////////////////////////////
  // Instantiate PID to determine drive magnitude //
  // Don't forget to pass FAST_SIM parameter!!   //
  ////////////////////////////////////////////////	
  
  PID #(FAST_SIM) iPID(.clk(clk), .rst_n(rst_n), .error(error), 
					.not_pedaling(not_pedaling), .drv_mag(drv_mag));
  
  ////////////////////////////////////////////////
  // Instantiate brushless DC motor controller //
  //////////////////////////////////////////////
  brushless ibrush(.clk(clk), .drv_mag(drv_mag), .hallGrn(hallGrn),
			.hallYlw(hallYlw), .hallBlu(hallBlu), .brake_n(brake_n), 
			.duty(duty), .sel_grn(selGrn), .sel_yellow(selYlw), 
			.sel_blue(selBlu));
						
  ///////////////////////////////
  // Instantiate motor driver //
  /////////////////////////////

  mtr_drv imtr_drv(.clk(clk), .rst_n(rst_n), .duty(duty),
		  .selGrn(selGrn), .selYlw(selYlw), .selBlu(selBlu), 
		  .highGrn(highGrn), .lowGrn(lowGrn), .highYlw(highYlw), 
		  .lowYlw(lowYlw), .highBlu(highBlu), .lowBlu(lowBlu));


  /////////////////////////////////////////////////////////////
  // Instantiate inertial sensor to measure incline (pitch) //
  ///////////////////////////////////////////////////////////
  inert_intf iinert_intf(.clk(clk),.rst_n(rst_n),.incline(inertIncline),.vld(vld),
             .SS_n(inertSS_n),.SCLK(inertSCLK),
			 .MOSI(inertMOSI),.MISO(inertMISO),.INT(inertINT));
					
  ////////////////////////////////////////////////////////
  // Instantiate (or infer) tggleMd/setting[1:0] logic //
  //////////////////////////////////////////////////////
 //PB_intf ipb(.tgglMD(tgglMD), .clk(clk), .rst_n(rst_n),.setting(setting)
		//		);
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  setting <= 2'b10;
	else if (en_tgglMd)
	  setting <= setting + 1'b1;
  
  PB_rise iPB(.clk(clk), .rst_n(rst_n), .PB(tgglMd), .rise(en_tgglMd));
  
  ///////////////////////////////////////////////////////////////////////
  // brake_n should be asserted if brake A2D reading lower than 0x800 //
  /////////////////////////////////////////////////////////////////////
  always @(posedge clk) begin
	if(brake < 12'h800)
	    brake_n = 1'b0;
	else
	    brake_n = 1'b1;
	end

endmodule
