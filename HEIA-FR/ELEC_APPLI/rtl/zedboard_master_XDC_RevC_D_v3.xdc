# ----------------------------------------------------------------------------
# Clock Source - Bank 13
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y9 [get_ports {clk_i}];

## ----------------------------------------------------------------------------
## JA Pmod - Bank 13
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN Y11  [get_ports {filtered_o[7]}];  # "JA1"
#set_property PACKAGE_PIN AA8  [get_ports {JA10}];  # "JA10"
set_property PACKAGE_PIN AA11 [get_ports {filtered_o[6]}];  # "JA2"
set_property PACKAGE_PIN Y10  [get_ports {filtered_o[5]}];  # "JA3"
set_property PACKAGE_PIN AA9  [get_ports {filtered_o[4]}];  # "JA4"
#set_property PACKAGE_PIN AB11 [get_ports {JA7}];  # "JA7"
#set_property PACKAGE_PIN AB10 [get_ports {JA8}];  # "JA8"
#set_property PACKAGE_PIN AB9  [get_ports {JA9}];  # "JA9"


## ----------------------------------------------------------------------------
## JB Pmod - Bank 13
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN W12 [get_ports {filtered_o[3]}];  # "JB1"
set_property PACKAGE_PIN W11 [get_ports {filtered_o[2]}];  # "JB2"
set_property PACKAGE_PIN V10 [get_ports {filtered_o[1]}];  # "JB3"
set_property PACKAGE_PIN W8  [get_ports {filtered_o[0]}];  # "JB4"
#set_property PACKAGE_PIN V12 [get_ports {JB7}]];   # "JB7"
#set_property PACKAGE_PIN W10 [get_ports {JB8}];    # "JB8"
#set_property PACKAGE_PIN V9  [get_ports {JB9}];    # "JB9"
#set_property PACKAGE_PIN V8  [get_ports {JB10}];   # "JB10"

## ----------------------------------------------------------------------------
## JC Pmod - Bank 13
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN AB6 [get_ports {bitstream_i}];  # "JC1_N"
set_property PACKAGE_PIN AB7 [get_ports {fos_i}];     # "JC1_P"
#set_property PACKAGE_PIN AA4 [get_ports {JC2_N}];  # "JC2_N"
#set_property PACKAGE_PIN Y4  [get_ports {JC2_P}];  # "JC2_P"
#set_property PACKAGE_PIN T6  [get_ports {JC3_N}];  # "JC3_N"
#set_property PACKAGE_PIN R6  [get_ports {JC3_P}];  # "JC3_P"
#set_property PACKAGE_PIN U4  [get_ports {JC4_N}];  # "JC4_N"
#set_property PACKAGE_PIN T4  [get_ports {JC4_P}];  # "JC4_P"

## ----------------------------------------------------------------------------
## JD Pmod - Bank 13
## ----------------------------------------------------------------------------
#set_property PACKAGE_PIN W7 [get_ports {JD1_N}];  # "JD1_N"
#set_property PACKAGE_PIN V7 [get_ports {JD1_P}];  # "JD1_P"
#set_property PACKAGE_PIN V4 [get_ports {JD2_N}];  # "JD2_N"
#set_property PACKAGE_PIN V5 [get_ports {JD2_P}];  # "JD2_P"
#set_property PACKAGE_PIN W5 [get_ports {JD3_N}];  # "JD3_N"
#set_property PACKAGE_PIN W6 [get_ports {JD3_P}];  # "JD3_P"
#set_property PACKAGE_PIN U5 [get_ports {JD4_N}];  # "JD4_N"
#set_property PACKAGE_PIN U6 [get_ports {JD4_P}];  # "JD4_P"

# ----------------------------------------------------------------------------
# User LEDs - Bank 33
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN T21 [get_ports {fir_o}];  # "LD1"
set_property PACKAGE_PIN U22 [get_ports {iir_o}];  # "LD2"
#set_property PACKAGE_PIN U21 [get_ports {LD3}];  # "LD3"
#set_property PACKAGE_PIN V22 [get_ports {LD4}];  # "LD4"
#set_property PACKAGE_PIN W22 [get_ports {LD5}];  # "LD5"
#set_property PACKAGE_PIN U19 [get_ports {LD6}];  # "LD6"
#set_property PACKAGE_PIN U14 [get_ports {LD7}];  # "LD7"

## ----------------------------------------------------------------------------
## User Push Buttons - Bank 34
## ----------------------------------------------------------------------------
set_property PACKAGE_PIN P16 [get_ports {rst_i}]; #"BTNC"
#set_property PACKAGE_PIN R16 [get_ports {BTND}];  # "BTND"
#set_property PACKAGE_PIN N15 [get_ports {BTNL}];  # "BTNL"
#set_property PACKAGE_PIN R18 [get_ports {BTNR}];  # "BTNR"
#set_property PACKAGE_PIN T18 [get_ports {BTNU}];  # "BTNU"

# ----------------------------------------------------------------------------
# User DIP Switches - Bank 35
# ----------------------------------------------------------------------------
set_property PACKAGE_PIN F22 [get_ports {FIRnIIR_i}]; # "SW0"
#set_property PACKAGE_PIN G22 [get_ports {groupid_i[0]}];    # "SW1"
#set_property PACKAGE_PIN H22 [get_ports {groupid_i[1]}];    # "SW2"
#set_property PACKAGE_PIN F21 [get_ports {groupid_i[2]}];    # "SW3"
#set_property PACKAGE_PIN H19 [get_ports {SW4}];    # "SW4"
#set_property PACKAGE_PIN H18 [get_ports {SW5}];    # "SW5"
#set_property PACKAGE_PIN H17 [get_ports {SW6}];    # "SW6"
#set_property PACKAGE_PIN M15 [get_ports {SW7}];    # "SW7"


# ----------------------------------------------------------------------------
# IOSTANDARD Constraints
#
# Note that these IOSTANDARD constraints are applied to all IOs currently
# assigned within an I/O bank.  If these IOSTANDARD constraints are
# evaluated prior to other PACKAGE_PIN constraints being applied, then
# the IOSTANDARD specified will likely not be applied properly to those
# pins.  Therefore, bank wide IOSTANDARD constraints should be placed
# within the XDC file in a location that is evaluated AFTER all
# PACKAGE_PIN constraints within the target bank have been evaluated.
#
# Un-comment one or more of the following IOSTANDARD constraints according to
# the bank pin assignments that are required within a design.
# ----------------------------------------------------------------------------

# Note that the bank voltage for IO Bank 33 is fixed to 3.3V on ZedBoard.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]]

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]]
#set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 34]];
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 35]];
#set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 35]];
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

create_clock -period 10.000 -name clk_i -waveform {0.000 5.000} -add [get_nets clk_i];
