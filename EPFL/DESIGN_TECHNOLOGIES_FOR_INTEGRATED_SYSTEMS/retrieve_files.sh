#!/usr/bin/env bash
set -euo pipefail

# Retrieve files from jed.hpc.epfl.ch to local workspace by creating a zip on the
# remote host, copying that single zip file (faster than many small files),
# extracting locally, and cleaning up.
#
# NOTE: This script is intended to run inside WSL (paths use /mnt/c/...):
# cd EPFL/DESIGN_TECHNOLOGIES_FOR_INTEGRATED_SYSTEMS
# bash retrieve_files.sh

REMOTE_USER="gjenni"
REMOTE_HOST="jed.hpc.epfl.ch"
REMOTE_DIR="/home/gjenni/Synopsys_Labs/Lab1/CS472/FC_Labs/FC_Labs"
# REMOTE_DIR="/education/classes/2025-2026/CS472/FC_Labs/FC_Labs"
LOCAL_DEST="/mnt/c/git/fpga-workspace/EPFL/DESIGN_TECHNOLOGIES_FOR_INTEGRATED_SYSTEMS/workspace"
# LOCAL_DEST="/mnt/c/git/fpga-workspace/EPFL/DESIGN_TECHNOLOGIES_FOR_INTEGRATED_SYSTEMS/workspace/original_files"

ZIP_BASENAME="FC_Labs_$(date +%Y%m%d_%H%M%S).zip"

# Compute remote paths after REMOTE_DIR so we can prefer creating the archive
# next to the source directory (more likely to be writable and easier to inspect).
remote_parent=$(dirname "$REMOTE_DIR")
remote_name=$(basename "$REMOTE_DIR")

# Remote temporary directory for the zip; defaults to user scratch to remain writable
# outside the container (override via REMOTE_ZIP_DIR env var).
DEFAULT_REMOTE_SCRATCH="/scratch/$REMOTE_USER/fc_labs_zip"
REMOTE_ZIP_DIR="${REMOTE_ZIP_DIR:-$DEFAULT_REMOTE_SCRATCH}"
REMOTE_ZIP="$REMOTE_ZIP_DIR/$ZIP_BASENAME"
LOCAL_ZIP="$LOCAL_DEST/$ZIP_BASENAME"

# Optional: pass --install-key to generate (if missing) and install a local
# SSH key on the remote host so subsequent runs don't require the password.
INSTALL_KEY=0
if [[ "${1:-}" == "--install-key" ]]; then
	INSTALL_KEY=1
	shift
fi

# SSH key and connection options
KEY_PATH="$HOME/.ssh/id_ed25519"
PUB_KEY="$KEY_PATH.pub"
PUB_BASENAME=$(basename "$PUB_KEY")
SSH_OPTS_COMMON="-o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r"
SSH_KEY_OPT=""

# Ensure required tools are available
for cmd in ssh scp zip unzip; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Error: required command '$cmd' not found in PATH. Install it and retry." >&2
		exit 1
	fi
done

mkdir -p "$LOCAL_DEST"

### Optional: install SSH key on remote so future runs don't prompt for password
if [[ "$INSTALL_KEY" -eq 1 ]]; then
	echo "Installing SSH key to ${REMOTE_USER}@${REMOTE_HOST}..."

	# generate key locally if missing (no passphrase by default for automation)
	if [[ ! -f "$PUB_KEY" ]]; then
		mkdir -p "$(dirname "$KEY_PATH")"
		echo "Generating SSH key: $KEY_PATH (no passphrase)..."
		ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$REMOTE_USER@$(hostname)-$(date +%Y%m%d)"
	else
		echo "Using existing key: $PUB_KEY"
	fi

	# Try ssh-copy-id first (convenient). If not available, fallback to scp+append method.
	if command -v ssh-copy-id >/dev/null 2>&1; then
		echo "Copying public key with ssh-copy-id (you will be prompted for the remote password once)..."
		ssh-copy-id -i "$PUB_KEY" "$REMOTE_USER@$REMOTE_HOST" || true
	else
		echo "ssh-copy-id not available; using scp+remote-append fallback. You will be prompted for the remote password once..."
		scp "$PUB_KEY" "$REMOTE_USER@$REMOTE_HOST:/tmp/$PUB_BASENAME"
		ssh $SSH_OPTS_COMMON "$REMOTE_USER@$REMOTE_HOST" \
			"mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && \
			grep -F -x -f /tmp/$PUB_BASENAME ~/.ssh/authorized_keys >/dev/null 2>&1 || cat /tmp/$PUB_BASENAME >> ~/.ssh/authorized_keys && \
			chmod 600 ~/.ssh/authorized_keys && rm -f /tmp/$PUB_BASENAME"
	fi

	# After installation, enable key option for further ssh/scp commands
	SSH_KEY_OPT="-i $KEY_PATH"
fi

## If the key already exists locally and user didn't request install, use it
if [[ -f "$KEY_PATH" && -f "$PUB_KEY" && -z "$SSH_KEY_OPT" ]]; then
	SSH_KEY_OPT="-i $KEY_PATH"
fi

printf -v remote_commands 'echo Zipping...\ncd %q\nmkdir -p %q\nzip -r %q %q\nexit\n' \
	"$remote_parent" "$REMOTE_ZIP_DIR" "$REMOTE_ZIP" "$remote_name"

echo "Creating zip '$REMOTE_ZIP' on ${REMOTE_HOST}..."
printf '%s' "$remote_commands" | ssh -tt $SSH_OPTS_COMMON $SSH_KEY_OPT "$REMOTE_USER@$REMOTE_HOST" "/work/fvlsi/run_edadk"

# Verify the remote zip was created and show its size; if missing, provide diagnostics.
echo "Verifying remote zip exists..."
if ! ssh $SSH_OPTS_COMMON $SSH_KEY_OPT "$REMOTE_USER@$REMOTE_HOST" "ls -l '$REMOTE_ZIP'" >/dev/null 2>&1; then
	echo "Error: remote zip '$REMOTE_ZIP' not found after creation." >&2
	echo "Remote '$REMOTE_ZIP_DIR' contents:" >&2
	ssh $SSH_OPTS_COMMON $SSH_KEY_OPT "$REMOTE_USER@$REMOTE_HOST" "ls -la '$REMOTE_ZIP_DIR'" || true
	echo "If the source directory resides only inside the container, its listing may be unavailable outside run_edadk." >&2
	exit 1
fi

echo "Copying zip to local: $LOCAL_ZIP..."
scp $SSH_OPTS_COMMON $SSH_KEY_OPT "$REMOTE_USER@$REMOTE_HOST:$REMOTE_ZIP" "$LOCAL_DEST/"

echo "Extracting into $LOCAL_DEST..."
unzip -o "$LOCAL_ZIP" -d "$LOCAL_DEST"

echo "Cleaning up remote and local zip files..."
ssh $SSH_OPTS_COMMON $SSH_KEY_OPT "$REMOTE_USER@$REMOTE_HOST" "rm -f '$REMOTE_ZIP'" || true
rm -f "$LOCAL_ZIP"

echo "Done. Files extracted to: $LOCAL_DEST/$remote_name"

# End of script