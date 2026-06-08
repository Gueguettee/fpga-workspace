#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# ZCU104 Deploy, Build, Program & Test Script
#
# Usage: ./deploy.sh <host> <target> [target2 ...]
#        ./deploy.sh pynq all
#        ./deploy.sh pynq sync build
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────

PROJECT_NAME="milp-fpga"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_USER="xilinx"
REMOTE_DIR="/home/xilinx/milp-fpga"
DEFAULT_HOST="172.22.22.70"

# Kernel selection — must match a kernel registered in hw/build.py KERNELS{}.
# Set via the --kernel flag; BITSTREAM_NAME is derived from KERNEL + variant.
KERNEL="dense_solve"
Q_INT_BITS=31
Q_FRAC_BITS=40
USE_GAUSSIAN=false
UNROLL=""   # empty means use kernel default
BITSTREAM_NAME="DenseSolve_Q31_40_Ch"

kernel_to_base_project() {
    case "$1" in
        dense_solve)  echo "DenseSolve" ;;
        sparse_solve) echo "SparseSolve" ;;
        *)            fail "Unknown kernel '$1' (expected dense_solve or sparse_solve)" ;;
    esac
}

# Mirrors variant_suffix() in hw/build.py + synth.sh so bitstream artefact names
# match across local build / remote synth / on-board program. Underscore (not
# dot) between Q-int and Q-frac because Vivado disallows dots in BD cell names.
variant_suffix() {
    local kernel="$1" q_int="$2" q_frac="$3" use_gaussian="$4" unroll="$5"
    local suffix="_Q${q_int}_${q_frac}"
    if [[ -n "$unroll" ]]; then
        suffix="${suffix}_U${unroll}"
    fi
    if [[ "$kernel" == "dense_solve" ]]; then
        if [[ "$use_gaussian" == "true" ]]; then
            suffix="${suffix}_Ga"
        else
            suffix="${suffix}_Ch"
        fi
    fi
    echo "$suffix"
}

kernel_to_project() {
    local base
    base=$(kernel_to_base_project "$1")
    local suffix
    suffix=$(variant_suffix "$1" "$Q_INT_BITS" "$Q_FRAC_BITS" "$USE_GAUSSIAN" "$UNROLL")
    echo "${base}${suffix}"
}

# SYNC_FILES is rebuilt from KERNEL in apply_kernel_config() so that every
# rsync uses the selected kernel's bitstream + (for sparse) test fixtures.
SYNC_FILES=()

apply_kernel_config() {
    BITSTREAM_NAME=$(kernel_to_project "$KERNEL")

    SYNC_FILES=(
        # Bitstream (local build output → flat hw/ on board)
        "hw/build/bitstream/${BITSTREAM_NAME}.bit:hw/${BITSTREAM_NAME}.bit"
        "hw/build/bitstream/${BITSTREAM_NAME}.hwh:hw/${BITSTREAM_NAME}.hwh"
        # Software for both kernels; unused .cpp files just won't be linked.
        "sw"
        # Shared headers (fixed-point types)
        "shared"
    )

    # Sparse kernel needs its test fixtures on the board for the standalone tb.
    if [[ "$KERNEL" == "sparse_solve" ]]; then
        SYNC_FILES+=(
            "hw/kernels/sparse_solve/tb/fixtures:hw/sparse_solve/fixtures"
        )
    fi
}

# ── Colors ───────────────────────────────────────────────────────────────────

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[DONE]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

banner() {
    local msg="$1"
    local width=$(( ${#msg} + 6 ))
    [[ $width -lt 48 ]] && width=48
    echo ""
    echo -e "${BOLD}${CYAN}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo -e "${BOLD}${CYAN}   ${msg}${NC}"
    echo -e "${BOLD}${CYAN}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo ""
}

# ── SSH helpers ──────────────────────────────────────────────────────────────

HOST=""
SSH_TARGET=""

run_remote() {
    local cmd="$1"
    local use_sudo="${2:-false}"
    local check="${3:-true}"

    if [[ "$use_sudo" == "true" ]]; then
        cmd="sudo -E $cmd"
    fi
    echo -e "  ${DIM}[remote] \$ ${cmd}${NC}"
    ssh -t "$SSH_TARGET" -- "$cmd"
    local rc=$?

    if [[ "$check" == "true" && $rc -ne 0 ]]; then
        fail "Remote command failed with exit code $rc"
    fi
    return $rc
}

# Detached via setsid so the job survives an SSH drop; exit code polled via a .rc marker file.
run_remote_detached() {
    local cmd="$1"
    local tag="${2:-job}"
    local base="/tmp/milp_${tag}"

    echo -e "  ${DIM}[remote-detached] \$ ${cmd}${NC}"
    ssh "$SSH_TARGET" -- "rm -f ${base}.log ${base}.rc; setsid bash -c '{ ${cmd}; } > ${base}.log 2>&1; echo \$? > ${base}.rc' </dev/null >/dev/null 2>&1 &"
    info "Launched detached on board (log ${base}.log) — survives SSH drops."

    local shown=0 rc="" total
    while [[ -z "$rc" ]]; do
        sleep 5
        total=$(ssh -o ConnectTimeout=10 "$SSH_TARGET" -- "wc -l < ${base}.log 2>/dev/null || echo $shown" 2>/dev/null || echo "$shown")
        if [[ "$total" =~ ^[0-9]+$ && "$total" -gt "$shown" ]]; then
            ssh -o ConnectTimeout=10 "$SSH_TARGET" -- "sed -n '$((shown + 1)),${total}p' ${base}.log 2>/dev/null" 2>/dev/null || true
            shown=$total
        fi
        rc=$(ssh -o ConnectTimeout=10 "$SSH_TARGET" -- "cat ${base}.rc 2>/dev/null" 2>/dev/null || echo "")
    done
    ssh -o ConnectTimeout=10 "$SSH_TARGET" -- "sed -n '$((shown + 1)),\$p' ${base}.log 2>/dev/null" 2>/dev/null || true
    return "${rc:-1}"
}

# ── Targets ──────────────────────────────────────────────────────────────────

target_sync() {
    banner "Syncing files to board (kernel=${KERNEL})"

    # Create remote directory structure
    run_remote "mkdir -p ${REMOTE_DIR}/hw ${REMOTE_DIR}/sw/src ${REMOTE_DIR}/sw/include ${REMOTE_DIR}/sw/drivers ${REMOTE_DIR}/shared ${REMOTE_DIR}/data ${REMOTE_DIR}/hw/sparse_solve"

    # Check rsync is available
    if ! command -v rsync &>/dev/null; then
        fail "rsync is not installed. Install it with: sudo apt install rsync"
    fi

    info "Using rsync for file transfer"
    cd "$SCRIPT_DIR"
    for entry in "${SYNC_FILES[@]}"; do
        # Support "local_path:remote_path" or just "local_path" (same on both sides)
        local local_path="${entry%%:*}"
        local remote_path="${entry#*:}"
        [[ "$local_path" == "$remote_path" ]] || true  # no-op, just for clarity

        if [[ ! -e "$local_path" ]]; then
            fail "File not found: $local_path"
        fi
        if [[ -d "$local_path" ]]; then
            echo -e "  ${DIM}\$ rsync -avz --progress \"$local_path\" -> ${remote_path}${NC}"
            rsync -avz --progress "$local_path" "${SSH_TARGET}:${REMOTE_DIR}/$(dirname "$remote_path")/"
        else
            echo -e "  ${DIM}\$ rsync -avz --progress \"$local_path\" -> ${remote_path}${NC}"
            rsync -avz --progress "$local_path" "${SSH_TARGET}:${REMOTE_DIR}/${remote_path}"
        fi
    done

    success "Files synced to board"
}

target_build() {
    banner "Building software on board (kernel=${KERNEL})"

    if [[ "$KERNEL" == "sparse_solve" ]]; then
        info "Building SparseSolve testbench..."
        run_remote "cd ${REMOTE_DIR}/sw && make -f Makefile.sparse_solve clean && make -f Makefile.sparse_solve"
        success "SparseSolve testbench built"

        info "Building LP IPM sparse benchmark..."
        run_remote "cd ${REMOTE_DIR}/sw && make -f Makefile.lp_ipm_sparse clean && make -f Makefile.lp_ipm_sparse"
        success "LP IPM sparse benchmark built"
    else
        info "Building LP/MILP testbench..."
        run_remote "cd ${REMOTE_DIR}/sw && make clean && make"
        success "LP/MILP testbench built"

        info "Building DenseSolve testbench..."
        run_remote "cd ${REMOTE_DIR}/sw && make -f Makefile.dense_solve clean && make -f Makefile.dense_solve"
        success "DenseSolve testbench built"

        info "Building full pipeline HW testbench..."
        run_remote "cd ${REMOTE_DIR}/sw && make -f Makefile.milp_bnb clean && make -f Makefile.milp_bnb"
        success "Pipeline HW testbench built"
    fi
}

target_program() {
    banner "Programming FPGA bitstream"

    local bitstream="${REMOTE_DIR}/hw/${BITSTREAM_NAME}.bit"
    local prog_script="${REMOTE_DIR}/hw/program.py"

    # Create programming script on the board
    local pynq_venv="/usr/local/share/pynq-venv"
    run_remote "cat << 'PYEOF' > ${prog_script}
#!/usr/bin/python3
print('Programming FPGA with bitstream [${bitstream}]...')
from pynq import Overlay
ol = Overlay('${bitstream}')
print('Bitstream programmed successfully.')
PYEOF
chmod +x ${prog_script}"

    # XILINX_XRT=/usr is needed for pynq device detection, pynq venv for the pynq package
    info "Loading bitstream via PYNQ overlay..."
    if run_remote "sudo -E XILINX_XRT=/usr ${pynq_venv}/bin/python3 ${prog_script}" "false" "false"; then
        success "FPGA bitstream programmed"
        return
    fi

    # Fallback: fpgautil
    fail "PYNQ overlay failed..."
}

target_test_bench() {
    banner "Running LP/MILP testbench"
    run_remote "cd ${REMOTE_DIR}/sw && ./bench"
    success "LP/MILP testbench completed"
}

target_test_dense_solve() {
    banner "Running DenseSolve hardware testbench"
    info "This requires the bitstream to be loaded first"
    run_remote_detached "cd ${REMOTE_DIR}/sw && sudo -E ./dense_solve_bench" "dense_solve_bench" \
        || warn "dense_solve_bench exited non-zero (see board log) — continuing"
    success "DenseSolve testbench completed"
}

target_test_sparse_solve() {
    banner "Running SparseSolve hardware testbench"
    info "This requires the bitstream to be loaded first"
    run_remote_detached "cd ${REMOTE_DIR}/sw && sudo -E ./sparse_solve_bench" "sparse_solve_bench" \
        || warn "sparse_solve_bench exited non-zero (see board log) — continuing"
    success "SparseSolve testbench completed"
}

target_test_lp_ipm_sparse() {
    banner "Running LP IPM sparse benchmark (HW vs SW sparse vs SW dense)"
    info "This requires the SparseSolve bitstream to be loaded first"
    run_remote_detached "cd ${REMOTE_DIR}/sw && sudo -E ./lp_ipm_sparse_bench" "lp_ipm_sparse_bench" \
        || warn "lp_ipm_sparse_bench exited non-zero (see board log) — continuing"
    success "LP IPM sparse benchmark completed"
}

target_test_milp_bnb() {
    banner "Running full pipeline HW testbench"
    info "This requires the bitstream to be loaded first"
    run_remote_detached "cd ${REMOTE_DIR}/sw && sudo -E ./milp_bnb_bench" "milp_bnb_bench" \
        || warn "milp_bnb_bench exited non-zero (see board log) — continuing"
    success "Pipeline HW testbench completed"
}

target_report() {
    banner "Fetching reports from board (kernel=${KERNEL})"

    mkdir -p "${SCRIPT_DIR}/data"

    local report_base
    if [[ "$KERNEL" == "sparse_solve" ]]; then
        report_base="sparse_solve_report"
    else
        report_base="dense_solve_report"
    fi

    info "Pulling ${report_base}.csv ..."
    rsync -avz --progress "${SSH_TARGET}:${REMOTE_DIR}/data/${report_base}.csv" "${SCRIPT_DIR}/data/" || warn "CSV report not found on board"

    info "Pulling ${report_base}.txt ..."
    rsync -avz --progress "${SSH_TARGET}:${REMOTE_DIR}/data/${report_base}.txt" "${SCRIPT_DIR}/data/" || warn "TXT report not found on board"

    # lp_ipm_sparse_bench produces an extra CSV alongside the sparse_solve_bench report.
    if [[ "$KERNEL" == "sparse_solve" ]]; then
        info "Pulling lp_ipm_sparse_report.csv ..."
        rsync -avz --progress "${SSH_TARGET}:${REMOTE_DIR}/data/lp_ipm_sparse_report.csv" "${SCRIPT_DIR}/data/" || warn "rsync failed"
        info "Pulling lp_ipm_sparse_convergence.csv ..."
        rsync -avz --progress "${SSH_TARGET}:${REMOTE_DIR}/data/lp_ipm_sparse_convergence.csv" "${SCRIPT_DIR}/data/" || warn "rsync failed"
    else
        # milp_bnb_bench produces milp_bnb_energy.csv alongside dense_solve_report.csv.
        info "Pulling milp_bnb_energy.csv ..."
        rsync -avz --progress "${SSH_TARGET}:${REMOTE_DIR}/data/milp_bnb_energy.csv" "${SCRIPT_DIR}/data/" || warn "rsync failed"
        info "Pulling milp_bnb_convergence.csv ..."
        rsync -avz --progress "${SSH_TARGET}:${REMOTE_DIR}/data/milp_bnb_convergence.csv" "${SCRIPT_DIR}/data/" || warn "rsync failed"
    fi

    success "Reports saved to ${SCRIPT_DIR}/data/"
}

target_archive() {
    banner "Archiving test results"

    local timestamp
    timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
    local archive_dir="${SCRIPT_DIR}/data/archive/${timestamp}"

    mkdir -p "${archive_dir}/bitstream" "${archive_dir}/hls" "${archive_dir}/reports"

    # Copy result data
    local has_data=false
    local report_base
    if [[ "$KERNEL" == "sparse_solve" ]]; then
        report_base="sparse_solve_report"
    else
        report_base="dense_solve_report"
    fi
    for f in "${report_base}.csv" "${report_base}.txt" vivado_report.txt; do
        if [[ -f "${SCRIPT_DIR}/data/${f}" ]]; then
            cp "${SCRIPT_DIR}/data/${f}" "${archive_dir}/"
            has_data=true
        fi
    done
    if [[ "$has_data" == "false" ]]; then
        warn "No report files found in data/ — run a test first"
        rm -rf "${archive_dir}"
        return 1
    fi

    # Copy bitstream
    for f in "${BITSTREAM_NAME}.bit" "${BITSTREAM_NAME}.hwh"; do
        if [[ -f "${SCRIPT_DIR}/hw/build/bitstream/${f}" ]]; then
            cp "${SCRIPT_DIR}/hw/build/bitstream/${f}" "${archive_dir}/bitstream/"
        else
            warn "Bitstream file not found: hw/build/bitstream/${f}"
        fi
    done

    # Copy HLS sources
    for f in "${SCRIPT_DIR}"/hw/kernels/${KERNEL}/src/*; do
        [[ -f "$f" ]] && cp "$f" "${archive_dir}/hls/"
    done

    # Copy HLS/Vivado reports
    local vivado_runs="${SCRIPT_DIR}/hw/build/${BITSTREAM_NAME}_Vivado/${BITSTREAM_NAME}_Vivado.runs"
    # HLS kernel synthesis utilization
    local hls_synth="${vivado_runs}/design_1_${BITSTREAM_NAME}_0_0_synth_1/design_1_${BITSTREAM_NAME}_0_0_utilization_synth.rpt"
    [[ -f "$hls_synth" ]] && cp "$hls_synth" "${archive_dir}/reports/hls_kernel_utilization_synth.rpt"
    # Implementation reports (utilization, timing, power)
    local impl_dir="${vivado_runs}/impl_1"
    for rpt in utilization_placed timing_summary_routed power_routed; do
        local f="${impl_dir}/design_1_wrapper_${rpt}.rpt"
        [[ -f "$f" ]] && cp "$f" "${archive_dir}/reports/"
    done
    # HLS csynth reports (latency, resources, interfaces)
    local hls_report_dir="${SCRIPT_DIR}/hw/${BITSTREAM_NAME}_HLS/hls/syn/report"
    for f in csynth.rpt ${BITSTREAM_NAME}_csynth.rpt; do
        [[ -f "${hls_report_dir}/${f}" ]] && cp "${hls_report_dir}/${f}" "${archive_dir}/reports/"
    done
    if [[ -z "$(ls -A "${archive_dir}/reports/" 2>/dev/null)" ]]; then
        warn "No Vivado/HLS reports found in build directory"
        rmdir "${archive_dir}/reports" || warn "rsync failed"
    fi

    # Write info file
    local git_hash
    git_hash="$(git -C "${SCRIPT_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    cat > "${archive_dir}/info.txt" << EOF
Date:    $(date '+%Y-%m-%d %H:%M:%S')
Commit:  ${git_hash}
Kernel:  ${BITSTREAM_NAME}
EOF

    success "Test archived to data/archive/${timestamp}/"
}

target_all() {
    target_sync
    target_build
    target_program
    if [[ "$KERNEL" == "sparse_solve" ]]; then
        target_test_sparse_solve
    else
        target_test_dense_solve
        target_test_milp_bnb
    fi
    target_report
    # Generate Vivado report so it's included in the archive (pass variant flags
    # through so synth.sh looks at the right PROJECT_NAME).
    local synth_variant_args=(--q-int "${Q_INT_BITS}" --q-frac "${Q_FRAC_BITS}")
    if [[ "$USE_GAUSSIAN" == "true" ]]; then
        synth_variant_args+=(--use-gaussian)
    fi
    if [[ -n "$UNROLL" ]]; then
        synth_variant_args+=(--unroll "$UNROLL")
    fi
    "${SCRIPT_DIR}/synth.sh" --kernel "${KERNEL}" "${synth_variant_args[@]}" report
    target_archive
}

target_setup_ssh_key() {
    banner "Setting up SSH key authentication"

    local key_file="$HOME/.ssh/id_ed25519"
    if [[ ! -f "$key_file" ]]; then
        info "Generating SSH key..."
        ssh-keygen -t ed25519 -f "$key_file" -N ""
        success "SSH key generated"
    else
        warn "SSH key already exists at $key_file"
    fi

    info "Copying public key to ${SSH_TARGET}..."
    ssh-copy-id -i "${key_file}.pub" "$SSH_TARGET"
    success "SSH key installed — password-free access enabled"
}

target_setup() {
    banner "Full board setup"

    target_setup_ssh_key

    info "Copying setup.sh to board..."
    rsync -avz --progress "${SCRIPT_DIR}/setup.sh" "${SSH_TARGET}:~/setup.sh"

    info "Running setup.sh on board..."
    run_remote "chmod +x ~/setup.sh && sudo ~/setup.sh" "false"

    success "Board setup complete"
}

target_connect() {
    banner "Connecting to ${HOST}"
    info "Opening SSH session..."
    ssh "$SSH_TARGET"
}

target_shutdown() {
    banner "Shutting down ${HOST}"
    info "Sending shutdown command..."
    run_remote "/sbin/shutdown -h now" "true" "false"
    success "Shutdown command sent. Wait ~10s before cutting power."
}

target_help() {
    echo -e "
${BOLD}${CYAN}ZCU104 Deploy & Test Script${NC}

${BOLD}Usage:${NC} ./deploy.sh [host] [--kernel <name>] <target> [target2 ...]
        Host defaults to '${DEFAULT_HOST}' if omitted.
        Kernel defaults to 'dense_solve' (use ${GREEN}--kernel sparse_solve${NC} to deploy the sparse kernel).

${BOLD}${YELLOW}Targets:${NC}

  ${GREEN}sync${NC}              : Upload project files to the board
  ${GREEN}build${NC}             : Compile software on the board
  ${GREEN}program${NC}           : Load the FPGA bitstream
  ${GREEN}test_bench${NC}        : Run the LP/MILP software testbench
  ${GREEN}test_dense_solve${NC}  : Run the DenseSolve hardware testbench (requires programmed FPGA)
  ${GREEN}test_sparse_solve${NC} : Run the SparseSolve hardware testbench (requires programmed FPGA)
  ${GREEN}test_lp_ipm_sparse${NC}: Run the LP IPM sparse benchmark on UC fixtures (requires programmed FPGA)
  ${GREEN}test_milp_bnb${NC}     : Run the full LP/MILP pipeline with FPGA profiling (requires programmed FPGA)
  ${GREEN}report${NC}            : Fetch CSV + TXT reports from the board to data/
  ${GREEN}archive${NC}           : Snapshot results, bitstream & HLS sources to data/archive/<timestamp>/
  ${GREEN}all${NC}               : Full flow: sync -> build -> program -> test -> archive
  ${GREEN}setup${NC}             : First-time board setup (SSH key + run setup.sh)
  ${GREEN}connect${NC}           : Open an interactive SSH session to the board
  ${GREEN}shutdown${NC}          : Gracefully shut down the board (safe to cut power after)
  ${GREEN}help${NC}              : Show this help message

${BOLD}${YELLOW}Examples:${NC}

  ./deploy.sh pynq all                              ${DIM}# Dense full flow${NC}
  ./deploy.sh --kernel sparse_solve all             ${DIM}# Sparse full flow on default host${NC}
  ./deploy.sh pynq --kernel sparse_solve all        ${DIM}# Sparse full flow on a named host${NC}
  ./deploy.sh 172.22.22.120 sync build              ${DIM}# Sync + build dense${NC}
  ./deploy.sh --kernel sparse_solve test_sparse_solve ${DIM}# Re-run only the sparse HW test${NC}
  ./deploy.sh 192.168.2.99 program                  ${DIM}# Just reprogram the FPGA${NC}

${BOLD}${YELLOW}Notes:${NC}

  - <host> can be a hostname or IP address
  - The board must be reachable via SSH as ${REMOTE_USER}@<host>
  - Hardware tests require sudo on the board (DMA access)
  - Files are deployed to ${REMOTE_DIR} on the board
"
}

# ── CLI ──────────────────────────────────────────────────────────────────────

VALID_TARGETS="sync build program test_bench test_dense_solve test_sparse_solve test_lp_ipm_sparse test_milp_bnb report archive all setup connect shutdown help"

# Extract flags before positional argument parsing.
ARGS=()
i=1
while [[ $i -le $# ]]; do
    arg="${!i}"
    case "$arg" in
        --kernel)
            i=$((i + 1))
            KERNEL="${!i}"
            ;;
        --kernel=*)
            KERNEL="${arg#--kernel=}"
            ;;
        --q-int)
            i=$((i + 1))
            Q_INT_BITS="${!i}"
            ;;
        --q-int=*)
            Q_INT_BITS="${arg#--q-int=}"
            ;;
        --q-frac)
            i=$((i + 1))
            Q_FRAC_BITS="${!i}"
            ;;
        --q-frac=*)
            Q_FRAC_BITS="${arg#--q-frac=}"
            ;;
        --use-gaussian)
            USE_GAUSSIAN=true
            ;;
        --unroll)
            i=$((i + 1))
            UNROLL="${!i}"
            ;;
        --unroll=*)
            UNROLL="${arg#--unroll=}"
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
    i=$((i + 1))
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

if (( Q_INT_BITS < 1 || Q_FRAC_BITS < 1 )); then
    fail "Invalid Q-format: q-int(${Q_INT_BITS}) and q-frac(${Q_FRAC_BITS}) must both be >= 1"
fi
if (( 1 + Q_INT_BITS + Q_FRAC_BITS > 128 )); then
    fail "Invalid Q-format: total TFXP width 1+${Q_INT_BITS}+${Q_FRAC_BITS} exceeds 128-bit host limit (__int128)"
fi

apply_kernel_config

if [[ $# -lt 1 ]]; then
    target_help
    exit 0
fi

# If the first argument is a known target, use default host
if echo "$VALID_TARGETS" | grep -qw "$1"; then
    HOST="$DEFAULT_HOST"
else
    HOST="$1"
    shift
fi

SSH_TARGET="${REMOTE_USER}@${HOST}"
TARGETS=("${@:-help}")

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    target_help
    exit 0
fi

# Auto-setup SSH key if not already done
if ! ssh -o BatchMode=yes -o ConnectTimeout=3 "$SSH_TARGET" true 2>/dev/null; then
    key_file="$HOME/.ssh/id_ed25519"
    if [[ ! -f "$key_file" ]]; then
        info "No SSH key found, generating one..."
        ssh-keygen -t ed25519 -f "$key_file" -N ""
        success "SSH key generated"
    fi
    info "Copying SSH key to ${SSH_TARGET} (you'll be asked for the password one last time)..."
    ssh-copy-id -i "${key_file}.pub" "$SSH_TARGET"
    success "SSH key installed — password-free access enabled"
fi

banner "Deploying to ${HOST}"

for t in "${TARGETS[@]}"; do
    case "$t" in
        sync)       target_sync ;;
        build)      target_build ;;
        program)    target_program ;;
        test_bench) target_test_bench ;;
        test_dense_solve) target_test_dense_solve ;;
        test_sparse_solve) target_test_sparse_solve ;;
        test_lp_ipm_sparse) target_test_lp_ipm_sparse ;;
        test_milp_bnb) target_test_milp_bnb ;;
        report)     target_report ;;
        archive)    target_archive ;;
        all)        target_all ;;
        setup)      target_setup ;;
        connect)    target_connect ;;
        shutdown)   target_shutdown ;;
        help)       target_help; exit 0 ;;
        *)          fail "Unknown target: $t" ;;
    esac
done

echo -e "\n${BOLD}${GREEN}All done!${NC}\n"
