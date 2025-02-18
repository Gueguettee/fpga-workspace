# This file is a general .xdc for the PYNQ-Z2 board
# To use it in a project:
# - uncomment the lines corresponding to used pins
# - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal 125 MHz

set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { CLKxCI }]; #IO_L13P_T2_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { CLKxCI }];

#Switches

set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { RSTxRI }]; #IO_L7N_T1_AD2N_35 Sch=sw[0]

#RGB LEDs

set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { GLED0xSO }]; #IO_L16P_T2_35 Sch=led4_g
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { RLED0xSO }]; #IO_L21P_T3_DQS_AD14P_35 Sch=led4_r

set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { GLED1xSO }]; #IO_L22P_T3_AD7P_35 Sch=led5_g
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { RLED1xSO }]; #IO_L23N_T3_35 Sch=led5_r

#Buttons

set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { Key0xSI }]; #IO_L4P_T0_35 Sch=btn[0]
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { Key1xSI }]; #IO_L4N_T0_35 Sch=btn[1]
