onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib VNAMI_BLOCK_DESIGN_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {VNAMI_BLOCK_DESIGN.udo}

run 1000ns

quit -force
