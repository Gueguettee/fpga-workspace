transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+Int_PLL  -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.Int_PLL xil_defaultlib.glbl

do {Int_PLL.udo}

run 1000ns

endsim

quit -force
