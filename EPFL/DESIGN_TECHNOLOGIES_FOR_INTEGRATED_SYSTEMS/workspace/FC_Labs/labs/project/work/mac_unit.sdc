
set PERIOD  0.4
set CLOCK_NAME clk_i
set UNCERTAINTY 0.1

create_clock -period $PERIOD -name $CLOCK_NAME [get_ports $CLOCK_NAME]

create_clock -name VCLK -period $PERIOD


set_clock_uncertainty -setup $UNCERTAINTY [get_clocks $CLOCK_NAME]

set_clock_uncertainty $UNCERTAINTY [get_clocks {VCLK} ]

