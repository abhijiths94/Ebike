###################################################################

# Created by write_sdc on Tue Dec 10 22:33:39 2019

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA
set_wire_load_model -name 16000 -library saed32rvt_tt0p85v25c
set_max_transition 0.15 [current_design]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports RST_n]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports A2D_MISO]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports hallGrn]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports hallYlw]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports hallBlu]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports inertMISO]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports inertINT]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports cadence]
set_driving_cell -lib_cell NAND2X1_RVT -library saed32rvt_tt0p85v25c           \
[get_ports tgglMd]
set_load -pin_load 0.15 [get_ports A2D_SS_n]
set_load -pin_load 0.15 [get_ports A2D_MOSI]
set_load -pin_load 0.15 [get_ports A2D_SCLK]
set_load -pin_load 0.15 [get_ports highGrn]
set_load -pin_load 0.15 [get_ports lowGrn]
set_load -pin_load 0.15 [get_ports highYlw]
set_load -pin_load 0.15 [get_ports lowYlw]
set_load -pin_load 0.15 [get_ports highBlu]
set_load -pin_load 0.15 [get_ports lowBlu]
set_load -pin_load 0.15 [get_ports inertSS_n]
set_load -pin_load 0.15 [get_ports inertSCLK]
set_load -pin_load 0.15 [get_ports inertMOSI]
set_load -pin_load 0.15 [get_ports TX]
set_load -pin_load 0.15 [get_ports {setting[1]}]
set_load -pin_load 0.15 [get_ports {setting[0]}]
create_clock [get_ports clk]  -period 4  -waveform {0 2}
set_clock_uncertainty 0.12  [get_clocks clk]
set_input_delay -clock clk  0.5  [get_ports RST_n]
set_input_delay -clock clk  0.5  [get_ports A2D_MISO]
set_input_delay -clock clk  0.5  [get_ports hallGrn]
set_input_delay -clock clk  0.5  [get_ports hallYlw]
set_input_delay -clock clk  0.5  [get_ports hallBlu]
set_input_delay -clock clk  0.5  [get_ports inertMISO]
set_input_delay -clock clk  0.5  [get_ports inertINT]
set_input_delay -clock clk  0.5  [get_ports cadence]
set_input_delay -clock clk  0.5  [get_ports tgglMd]
set_output_delay -clock clk  0.5  [get_ports A2D_SS_n]
set_output_delay -clock clk  0.5  [get_ports A2D_MOSI]
set_output_delay -clock clk  0.5  [get_ports A2D_SCLK]
set_output_delay -clock clk  0.5  [get_ports highGrn]
set_output_delay -clock clk  0.5  [get_ports lowGrn]
set_output_delay -clock clk  0.5  [get_ports highYlw]
set_output_delay -clock clk  0.5  [get_ports lowYlw]
set_output_delay -clock clk  0.5  [get_ports highBlu]
set_output_delay -clock clk  0.5  [get_ports lowBlu]
set_output_delay -clock clk  0.5  [get_ports inertSS_n]
set_output_delay -clock clk  0.5  [get_ports inertSCLK]
set_output_delay -clock clk  0.5  [get_ports inertMOSI]
set_output_delay -clock clk  0.5  [get_ports TX]
set_output_delay -clock clk  0.5  [get_ports {setting[1]}]
set_output_delay -clock clk  0.5  [get_ports {setting[0]}]
