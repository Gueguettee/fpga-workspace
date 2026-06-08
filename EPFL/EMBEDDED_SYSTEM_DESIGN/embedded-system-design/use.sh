# --- Run the testbench ---
cd virtualprototype/modules/profiling/verilog
./profiling_tb_use.sh

# --- Synthesize the OR1200 processor and the .v files for the virtual prototype ---
cd /mnt/c/git/embedded-system-design/virtualprototype/systems/singleCore/sandbox && ../scripts/synthesizeOr1420.sh && cd /mnt/c/git/embedded-system-design && openFPGALoader -f /mnt/c/git/embedded-system-design/virtualprototype/systems/singleCore/sandbox/or1420SingleCore.bit
# If you have already synthesized:
openFPGALoader -f /mnt/c/git/embedded-system-design/virtualprototype/systems/singleCore/sandbox/or1420SingleCore.bit

# If not working, go in powershell in admin mode and run:
usbipd list
# Your FTDI device is BUSID 7-1 (0403:6010 — USB Serial Converter). Now run:
usbipd bind --busid 7-1
usbipd attach --wsl --busid 7-1
# Then when it's done:
usbipd detach --busid 7-1

# --- Compile and send the program to the virtual prototype ---
cd /mnt/c/git/embedded-system-design/virtualprototype/programs/spectrumAnalyzer && make clean && make && cd /mnt/c/git/embedded-system-design
# Open Terminal with COM9, send the .cmem file and then run the program with "**"


# Or from WSL:
stty -F /dev/ttyUSB1 115200 cs8 -cstopb -parenb
cat virtualprototype/programs/spectrumAnalyzer/build-release-or1420/spectrumAnalyzer.cmem > /dev/ttyUSB1
screen /dev/ttyUSB1 115200
# Exit with Ctrl-A, then Ctrl-C


alias area='grep -E "(TRELLIS_COMB|TRELLIS_FF|DP16KD|MULT18X18D):" virtualprototype/systems/singleCore/sandbox/nextpnr.log'
area
