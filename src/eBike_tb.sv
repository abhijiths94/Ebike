module eBike_tb();

reg clk,RST_n;
reg [11:0] BATT; // analog values you apply to AnalogModel
reg [11:0] BRAKE,TORQUE; // analog values
reg cadence; // you have to have some way of applying a cadence signal
reg tgglMd;
reg [15:0] YAW_RT; // models angular rate of incline
logic signed [19:0] omeganormal,omegadownh,omegaup;
wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO; // A2D SPI interface
wire highGrn,lowGrn,highYlw; // FET control
wire lowYlw,highBlu,lowBlu; //   PWM signals
wire hallGrn,hallBlu,hallYlw; // hall sensor outputs
wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT; // Inert sensor SPI bus

wire [1:0] setting; // drive LEDs on real design
wire [11:0] curr; // comes from eBikePhysics back to AnalogModel
wire [7:0]rx_data;
wire rdy;
reg TX,clr_rdy;

reg signed [12:0] error_sgn;
assign error_sgn = iDUT.isensorCondition.error;

//////////////////////////////////////////////////
// Instantiate model of analog input circuitry //
////////////////////////////////////////////////
AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
.MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
  .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

////////////////////////////////////////////////////////////////
// Instantiate model inertial sensor used to measure incline //
//////////////////////////////////////////////////////////////
eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
.MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
.yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
.highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
.lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
.hallBlu(hallBlu),.avg_curr(curr));

//////////////////////
// Instantiate DUT //
////////////////////
eBike #(1) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
.hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
.lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
.highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
.inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
.inertMISO(inertMISO),.inertINT(inertINT),
.cadence(cadence),.tgglMd(tgglMd),.TX(TX),
.setting(setting));

///////////////////////////////////////////////////////////
// Instantiate Something to monitor telemetry output??? //
/////////////////////////////////////////////////////////
UART_rcv ircv(.clk(clk),.rst_n(rst_n),.RX(TX),.rdy(rdy),.rx_data(rx_data),.clr_rdy(clr_rdy));
//$monitor(TX);

 initial begin
clk= 0;
 //This is where you magic occurs
RST_n = 1'b0;
clr_rdy = 1'b1;
//normal operation
//#40;
repeat(20)@(posedge clk);
@(negedge clk);

RST_n = 1'b1;
YAW_RT = 16'b0;
BATT = 12'hffe;
BRAKE = 12'hfff;
TORQUE = 12'h7fe;
tgglMd = 1'b0;
clr_rdy = 1'b0;
//default mode

/*
repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in normal assist mode %5d", iDUT.isensorCondition.error);
$stop;
end

// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end
$display("normal assist mode check success!! Yay!!");

// $stop();
tgglMd = 1'b1;
//#40;
repeat(10)@(posedge clk);
tgglMd = 1'b0;
//YAW_RT = 16'd500;
repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in full assist mode %5d", iDUT.isensorCondition.error);
$stop;
end

// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end
$display("full assist mode check success!! Yay!!");
tgglMd = 1'b1;
//#40;
repeat(10)@(posedge clk);
tgglMd = 1'b0;
//repeat(8200000) @(posedge clk);
//YAW_RT = 16'hFFF;

repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in no assist mode %5d", iDUT.isensorCondition.error);
$stop;
end

// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end
$display("no assist mode check success!! Yay!!");
tgglMd = 1'b1;
//#40;
repeat(10)@(posedge clk);
tgglMd = 1'b0;
//#40;
repeat(10500000)@(posedge clk);

repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in low assist mode %5d", iDUT.isensorCondition.error);
$stop;
end
end
$display("low assist mode check success!! Yay!!");
tgglMd = 1'b1;
//#40;
repeat(10)@(posedge clk);
tgglMd = 1'b0;
//#40;
*/
//check normal mode
repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in normal assist mode %5d", iDUT.isensorCondition.error);
$stop();
end

// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end
$display("normal assist mode check success!! Yay!!");
omeganormal = iPHYS.omega;
repeat(1000)@(posedge clk) 
YAW_RT = 16'hFFFF;
repeat(10500000)@(posedge clk);
omegaup = iPHYS.omega;

repeat(1000)@(posedge clk) begin

if(error_sgn > 50 || omegaup < omeganormal) begin
$display("Error in uphill assist mode %5d", iDUT.isensorCondition.error);
$stop();
end
end
$display("uphill check success!! Yay!!");
YAW_RT = 16'h0000;
BRAKE = 12'h000;
repeat(50000000)@(posedge clk);

repeat(1000)@(posedge clk) begin
if(iDUT.isensorCondition.avg_curr != 0) begin
$display("Error in braking %5d", iDUT.isensorCondition.error);
$stop();
end
end
$display("brake check success!! Yay!!");
BRAKE = 12'h000;
repeat(5000000)@(posedge clk);
repeat(100000)@(posedge clk) BATT = 12'h00;
repeat(1000)@(posedge clk) begin
if(error_sgn != 0) begin
$display("Error in low battery mode %5d", iDUT.isensorCondition.error);
$stop();
end
end
$display("low battery check success!! Yay!!");
$stop();
end

always begin
#200000 cadence = 1'b1;
#200000 cadence = 1'b0;
end
always
#10 clk = ~clk;



endmodule

/*module eBike_tb();

reg clk,RST_n;
reg [11:0] BATT; // analog values you apply to AnalogModel
reg [11:0] BRAKE,TORQUE; // analog values
reg cadence; // you have to have some way of applying a cadence signal
reg tgglMd;
reg [15:0] YAW_RT; // models angular rate of incline

wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO; // A2D SPI interface
wire highGrn,lowGrn,highYlw; // FET control
wire lowYlw,highBlu,lowBlu; //   PWM signals
wire hallGrn,hallBlu,hallYlw; // hall sensor outputs
wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT; // Inert sensor SPI bus

wire [1:0] setting; // drive LEDs on real design
wire [11:0] curr; // comes from eBikePhysics back to AnalogModel
wire [7:0]rx_data;
wire rdy;
reg TX,clr_rdy;

reg signed [12:0] error_sgn;
assign error_sgn = iDUT.isensorCondition.error;

//////////////////////////////////////////////////
// Instantiate model of analog input circuitry //
////////////////////////////////////////////////
AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
.MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
  .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

////////////////////////////////////////////////////////////////
// Instantiate model inertial sensor used to measure incline //
//////////////////////////////////////////////////////////////
eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
.MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
.yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
.highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
.lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
.hallBlu(hallBlu),.avg_curr(curr));

//////////////////////
// Instantiate DUT //
////////////////////
eBike #(1) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
.hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
.lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
.highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
.inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
.inertMISO(inertMISO),.inertINT(inertINT),
.cadence(cadence),.tgglMd(tgglMd),.TX(TX),
.setting(setting));

///////////////////////////////////////////////////////////
// Instantiate Something to monitor telemetry output??? //
/////////////////////////////////////////////////////////
UART_rcv ircv(.clk(clk),.rst_n(rst_n),.RX(TX),.rdy(rdy),.rx_data(rx_data),.clr_rdy(clr_rdy));
//$monitor(TX);

 initial begin
clk= 0;
 //This is where you magic occurs
RST_n = 1'b0;
clr_rdy = 1'b1;
//normal operation
//#40;
repeat(20)@(posedge clk);
@(negedge clk);

RST_n = 1'b1;
YAW_RT = 16'b0;
BATT = 12'hffe;
BRAKE = 12'b0;
TORQUE = 12'h7fe;
tgglMd = 1'b0;
clr_rdy = 1'b0;
//default mode

repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in normal assist mode %5d", iDUT.isensorCondition.error);
$stop;
end
// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end


// $stop();
tgglMd = 1'b1;
//#40;
repeat(10)@(posedge clk);
//YAW_RT = 16'd500;
repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn > 50) begin
$display("Error in normal assist mode %5d", iDUT.isensorCondition.error);
$stop;
end
// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end

repeat(8200000) @(posedge clk);
YAW_RT = 16'h2000;
//BATT = 12'h10;
repeat(10500000)@(posedge clk);
repeat(1000)@(posedge clk) begin
if(error_sgn != 0) begin
$display("Error in normal assist mode %5d", iDUT.isensorCondition.error);
$stop;
end
// if(target_curr - avg_curr > 12'd50) begin
// $display("Error in normal assist mode");
// $stop;
// end
end

tgglMd = 1'b0;
//#40;
repeat(1000000000)@(posedge clk);
tgglMd = 1'b1;
//#40;
repeat(10)@(posedge clk);
tgglMd = 1'b0;
//#40;
repeat(1000000000)@(posedge clk);
tgglMd = 1'b1;
//#500;
repeat(10)@(posedge clk);
tgglMd = 1'b0;
//#40;
repeat(1000000000)@(posedge clk);
tgglMd = 1'b1;
end

always begin
#200000 cadence = 1'b1;
#200000 cadence = 1'b0;
end
always
#10 clk = ~clk;

initial begin
#900000000
$stop();

end

endmodule*/
