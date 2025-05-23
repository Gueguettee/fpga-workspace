# From the TCL console of Vivado, run the following command:
cd c:/git/lab-on-hardware-software-digital-systems-codesign/S ...

exec vitis_hls -f Vitis.tcl

exec vivado -source Vivado.tcl -tclargs --project_name Vivado


# To transfer files, open Ubutnu:
cd /mnt/c/git/lab-on-hardware-software-digital-systems-codesign/CNN_Dogs_Cats_project
# Tar the directory SW and sent it to the ip address (in the lab: 192.168.2.99)
tar -cvf SW.tar SW/
scp SW.tar xilinx@172.22.22.97:./
# Enter the password: "xilinx"

# On the device, extract the files
tar -xvf SW.tar
cd SW/

# Program device from Vivado or like that:
sudo ./programOverlay.py exercise02.bit 

make
sudo ./VectorAdder

Retrieve files:
scp -r xilinx@172.22.22.97:/home/xilinx/CNN/ /mnt/c/git/lab-on-hardware-software-digital-systems-codesign/CNN/