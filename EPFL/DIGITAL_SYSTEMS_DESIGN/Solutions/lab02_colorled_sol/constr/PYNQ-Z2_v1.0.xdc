## This file is a general .xdc for the PYNQ-Z2 board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal 125 MHz

set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { CLKxCI }]; #IO_L13P_T2_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { CLKxCI }];

#Buttons

set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { RSTxRI }]; #IO_L4P_T0_35 Sch=btn[0]
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { PushBluexSI }]; #IO_L4N_T0_35 Sch=btn[1]
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { PushGreenxSI }]; #IO_L9N_T1_DQS_AD3N_35 Sch=btn[2]
set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { PushRedxSI }]; #IO_L9P_T1_DQS_AD3P_35 Sch=btn[3]

#RGB LEDs

set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { LedBluexSO }]; #IO_L22N_T3_AD7N_35 Sch=led4_b
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { LedGreenxSO }]; #IO_L16P_T2_35 Sch=led4_g
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { LedRedxSO }]; #IO_L21P_T3_DQS_AD14P_35 Sch=led4_r
