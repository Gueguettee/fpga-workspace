#!/bin/bash
set -euo pipefail

echo "=== OSS-CAD-Suite Setup ==="

# Step 1 & 2: Download, extract and install OSS-CAD-Suite
if [ -d /opt/oss-cad-suite ]; then
    echo "[1/5] OSS-CAD-Suite already installed in /opt, skipping download."
    echo "[2/5] Skipping extraction."
else
    echo "[1/5] Downloading latest OSS-CAD-Suite..."
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest \
        | grep -oP '"browser_download_url": "\K[^"]*linux-x64[^"]*\.tgz(?=")' | head -1)
    FILENAME=$(basename "$DOWNLOAD_URL")
    curl -L -o "$FILENAME" "$DOWNLOAD_URL"

    echo "[2/5] Extracting and installing to /opt..."
    tar -xf "$FILENAME"
    sudo mv oss-cad-suite /opt/
    rm "$FILENAME"
fi

# Step 3: Configure PATH in ~/.bashrc
echo "[3/5] Configuring PATH..."
if ! grep -q '/opt/oss-cad-suite/bin' ~/.bashrc; then
    echo 'export PATH=/opt/oss-cad-suite/bin:$PATH' >> ~/.bashrc
    echo "  Added PATH entry to ~/.bashrc"
else
    echo "  PATH entry already exists in ~/.bashrc"
fi

# Step 4: Add user to dialout group (for UART/RS232 access)
echo "[4/5] Adding user to dialout group..."
sudo usermod -a -G dialout "$USER"

# Step 5: Configure USB device access (udev rules for GECKO5/OpenOCD)
echo "[5/5] Installing udev rules for OpenOCD..."
sudo cp /opt/oss-cad-suite/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

echo ""
echo "=== Part 1 complete! ==="
echo ""
echo "=== OpenRISC Cross-Compiler Toolchain Setup ==="

# Step 6: Install required packages
echo "[6/11] Installing required packages..."
sudo apt update
sudo apt install -y gcc guile-3.0 build-essential texinfo git rsync wget

# Step 7: Clone the or1kToolchain repository
echo "[7/11] Cloning or1kToolchain repository..."
WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
git clone https://github.com/EPFL-LAP/or1kToolchain.git
cd or1kToolchain/gnu_src

# Step 8: Download source packages
echo "[8/11] Downloading source packages..."
wget ftp.gnu.org/gnu/binutils/binutils-2.45.tar.bz2
wget mirror.koddos.net/gcc/releases/gcc-15.2.0/gcc-15.2.0.tar.gz
git clone git://sourceware.org/git/cgen.git

# Step 9: Compile the toolchain (this takes a long time)
echo "[9/11] Compiling the toolchain (this will take a while)..."
cd ../patch
sudo ./compile_linux.sh

# Step 10: Build and install convert_or32 utility
echo "[10/11] Building convert_or32 utility..."
cd ../convert_or32
gcc -O2 -o convert_or32 read_elf.c convert_or32.c
sudo mv convert_or32 /opt/or1k_toolchain/bin/

# Step 11: Configure PATH for or1k toolchain
echo "[11/11] Configuring PATH for or1k toolchain..."
if ! grep -q '/opt/or1k_toolchain/bin' ~/.bashrc; then
    echo 'export PATH=/opt/or1k_toolchain/bin:$PATH' >> ~/.bashrc
    echo "  Added or1k PATH entry to ~/.bashrc"
else
    echo "  or1k PATH entry already exists in ~/.bashrc"
fi

cd /
sudo rm -rf "$WORK_DIR"

echo ""
echo "=== Part 2 complete! ==="
echo ""
echo "=== Virtual Prototype (VP) Setup ==="

# Step 12: Clone the cs476 Virtual Prototype repository
echo "[12/12] Cloning cs476 Virtual Prototype repository..."
cd "$HOME"
if [ -d cs476 ]; then
    echo "  cs476 directory already exists, skipping clone."
else
    git clone -c core.symlinks=true https://github.com/EPFL-LAP/cs476.git
    mv cs476 virtualprototype
    del cs476
    del virtualprototype/programs/camera/external
    del virtualprototype/programs/camera/support
    del virtualprototype/programs/helloWorld/external
    del virtualprototype/programs/helloWorld/support
    cp virtualprototype/programs/support virtualprototype/programs/camera/support -r
    cp virtualprototype/programs/external virtualprototype/programs/camera/external -r
    cp virtualprototype/programs/support virtualprototype/programs/helloWorld/support -r
    cp virtualprototype/programs/external virtualprototype/programs/helloWorld/external -r
fi

echo ""
echo "=== Setup complete! ==="
echo "Please log out and log back in for group changes to take effect."
echo "If using a GECKO5 board, disconnect and reconnect it for udev rules to apply."
echo ""
echo "Verify the toolchain with: or1k-elf-gcc --version"
