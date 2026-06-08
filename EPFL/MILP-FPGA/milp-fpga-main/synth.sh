#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Remote FPGA Synthesis Script
#
# Runs Vitis HLS and Vivado synthesis on a remote server via SSH.
# Reuses hw/build.py on the server side.
#
# Usage: ./synth.sh [target]
#        ./synth.sh all          # Full pipeline (default)
#        ./synth.sh ip           # HLS synthesis only
#        ./synth.sh bitstream    # Vivado bitstream only
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE_SERVER="gjenni@eslsrv2.epfl.ch"
REMOTE_DIR="~/milp-fpga"
XILINX_VIVADO_SETTINGS="/softs/amd/2025.2/vivado/2025.2/Vivado/settings64.sh"
XILINX_VITIS_SETTINGS="/softs/amd/2025.2/vitis/2025.2/Vitis/settings64.sh"
REMOTE_JOBS=32
# TMUX_SESSION and REMOTE_LOG are set per-kernel after CLI parsing so kernels can synth concurrently.

# Kernel selection: must match a key in hw/build.py KERNELS{}.
# PROJECT_NAME is derived from KERNEL + variant suffix (Q-format + algorithm).
KERNEL="dense_solve"
Q_INT_BITS=31
Q_FRAC_BITS=40
USE_GAUSSIAN=false
UNROLL=""   # empty means use kernel default (no --unroll passed to build.py)
PROJECT_NAME="DenseSolve_Q31_40_Ch"

kernel_to_base_project() {
    case "$1" in
        dense_solve)  echo "DenseSolve" ;;
        sparse_solve) echo "SparseSolve" ;;
        *)            fail "Unknown kernel '$1' (expected dense_solve or sparse_solve)" ;;
    esac
}

# Mirrors variant_suffix() in hw/build.py so local rsync paths match the remote build; underscore (not dot) because Vivado BD cell names disallow dots.
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

# ── SSH key setup ────────────────────────────────────────────────────────────

setup_ssh_key() {
    local key_file="$HOME/.ssh/id_ed25519"

    # Check if passwordless SSH already works
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_SERVER" true 2>/dev/null; then
        return 0
    fi

    banner "Setting up SSH key for ${REMOTE_SERVER}"

    if [[ ! -f "$key_file" ]]; then
        info "Generating SSH key..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -f "$key_file" -N ""
        success "SSH key generated at $key_file"
    fi

    info "Copying public key to ${REMOTE_SERVER} (you'll be asked for the password once)..."
    ssh-copy-id -i "${key_file}.pub" "$REMOTE_SERVER"
    success "SSH key installed — password-free access enabled"
}

# ── Remote helpers ───────────────────────────────────────────────────────────

run_remote() {
    local cmd="$1"
    echo -e "  ${DIM}[remote] \$ ${cmd}${NC}"
    ssh -t "$REMOTE_SERVER" -- "$cmd"
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        fail "Remote command failed with exit code $rc"
    fi
    return $rc
}

xilinx_env_cmd() {
    echo "source ${XILINX_VIVADO_SETTINGS} && source ${XILINX_VITIS_SETTINGS} && export XILINX_LOCAL_USER_DATA=no"
}

# ── Targets ──────────────────────────────────────────────────────────────────

target_sync() {
    banner "Syncing project files to ${REMOTE_SERVER}"

    run_remote "mkdir -p ${REMOTE_DIR}/hw"

    info "Uploading project via rsync..."
    rsync -avz --progress \
        --exclude '.git/' \
        --exclude 'build/' \
        --exclude '__pycache__/' \
        --exclude '*.log' \
        --exclude '*.jou' \
        --exclude '*.str' \
        --exclude '.Xil/' \
        --exclude 'NA/' \
        --exclude 'data/' \
        --exclude '*.pyc' \
        --exclude '*_HLS/' \
        "$SCRIPT_DIR/" "${REMOTE_SERVER}:${REMOTE_DIR}/"

    success "Project synced to ${REMOTE_SERVER}:${REMOTE_DIR}"
}

build_py_variant_args() {
    local args="--q-int ${Q_INT_BITS} --q-frac ${Q_FRAC_BITS}"
    if [[ "$USE_GAUSSIAN" == "true" ]]; then
        args="${args} --use-gaussian"
    fi
    if [[ -n "$UNROLL" ]]; then
        args="${args} --unroll ${UNROLL}"
    fi
    echo "$args"
}

target_build() {
    local build_target="${1:-all}"
    local clean_arg=""
    local ila_arg=""
    local variant_args
    variant_args=$(build_py_variant_args)
    [[ "$CLEAN" == "true" ]] && clean_arg=" --clean"
    [[ "$USE_ILA" == "true" ]] && ila_arg=" --ila"

    banner "Running build.py ${build_target} --kernel ${KERNEL} ${variant_args}${clean_arg}${ila_arg} on ${REMOTE_SERVER}"

    run_remote "$(xilinx_env_cmd) && cd ${REMOTE_DIR}/hw && python3 build.py ${build_target} --kernel ${KERNEL} ${variant_args} --jobs ${REMOTE_JOBS}${clean_arg}${ila_arg}"

    success "Remote build '${build_target}' completed"
}

target_build_bg() {
    local build_target="${1:-all}"
    local clean_arg=""
    local ila_arg=""
    local variant_args
    variant_args=$(build_py_variant_args)
    [[ "$CLEAN" == "true" ]] && clean_arg=" --clean"
    [[ "$USE_ILA" == "true" ]] && ila_arg=" --ila"

    banner "Starting background synthesis: ${build_target} --kernel ${KERNEL} ${variant_args}${clean_arg}${ila_arg}"

    ssh "$REMOTE_SERVER" "tmux kill-session -t ${TMUX_SESSION} 2>/dev/null || true"

    # Self-contained build script on the server avoids SSH quoting issues.
    ssh "$REMOTE_SERVER" "cat > /tmp/milp_synth_${SESSION_TAG}.sh" << EOF
#!/bin/bash
exec > ${REMOTE_LOG} 2>&1
echo "=== Synthesis started: \$(date) ==="
export PYTHONPATH=\${PYTHONPATH:-}
source ${XILINX_VIVADO_SETTINGS}
source ${XILINX_VITIS_SETTINGS}
export XILINX_LOCAL_USER_DATA=no
cd ${REMOTE_DIR}/hw
python3 build.py ${build_target} --kernel ${KERNEL} ${variant_args} --jobs ${REMOTE_JOBS}${clean_arg}${ila_arg}
echo "EXIT_CODE=\$?"
echo "=== Synthesis ended: \$(date) ==="
EOF

    ssh "$REMOTE_SERVER" "chmod +x /tmp/milp_synth_${SESSION_TAG}.sh && tmux new-session -d -s ${TMUX_SESSION} '/tmp/milp_synth_${SESSION_TAG}.sh'"

    success "Synthesis started in tmux session '${TMUX_SESSION}'"
    info "Use  ./synth.sh logs    to follow progress"
    info "Use  ./synth.sh status  to check if it's done"
    info "Use  ./synth.sh fetch   to retrieve results when done"
}

target_status() {
    banner "Synthesis status"

    if ssh "$REMOTE_SERVER" "tmux has-session -t ${TMUX_SESSION} 2>/dev/null"; then
        info "Status: ${YELLOW}RUNNING${NC} (tmux session '${TMUX_SESSION}' is active)"
        info "Last 5 log lines:"
        ssh "$REMOTE_SERVER" "tail -5 ${REMOTE_LOG} 2>/dev/null" | sed 's/^/    /'
    else
        # Check exit code in log
        local exit_line
        exit_line=$(ssh "$REMOTE_SERVER" "grep '^EXIT_CODE=' ${REMOTE_LOG} 2>/dev/null | tail -1" || true)
        if [[ -z "$exit_line" ]]; then
            warn "No active session and no log found — has synthesis been started?"
        elif [[ "$exit_line" == "EXIT_CODE=0" ]]; then
            success "Status: DONE (completed successfully)"
            target_fetch
            target_fetch_hls_project
            target_report
        else
            fail "Status: FAILED (${exit_line}) — run  ./synth.sh logs  to inspect"
        fi
    fi
}

target_logs() {
    banner "Synthesis logs (Ctrl+C to stop following)"
    info "Streaming ${REMOTE_LOG} — synthesis continues in background"

    # Background tail -f locally, stopped automatically when the remote tmux session ends.
    ssh "$REMOTE_SERVER" "tail -f ${REMOTE_LOG} 2>/dev/null" &
    local tail_pid=$!

    while ssh -o ConnectTimeout=5 "$REMOTE_SERVER" "tmux has-session -t ${TMUX_SESSION} 2>/dev/null"; do
        if ! kill -0 $tail_pid 2>/dev/null; then break; fi
        sleep 5
    done

    sleep 2
    kill $tail_pid 2>/dev/null
    wait $tail_pid 2>/dev/null

    # Check if synthesis succeeded and auto-fetch
    local exit_line
    exit_line=$(ssh "$REMOTE_SERVER" "grep '^EXIT_CODE=' ${REMOTE_LOG} 2>/dev/null | tail -1" || true)
    if [[ "$exit_line" == "EXIT_CODE=0" ]]; then
        success "Synthesis completed successfully"
        target_fetch
        target_fetch_hls_project
        target_report
    elif [[ -n "$exit_line" ]]; then
        fail "Synthesis failed (${exit_line})"
    else
        info "Log streaming interrupted — synthesis may still be running"
    fi
}

target_fetch() {
    banner "Fetching build results from ${REMOTE_SERVER}"

    mkdir -p "${SCRIPT_DIR}/hw/build/bitstream"
    mkdir -p "${SCRIPT_DIR}/hw/build/ip_repo"

    info "Downloading bitstream files..."
    rsync -avz --progress \
        "${REMOTE_SERVER}:${REMOTE_DIR}/hw/build/bitstream/" \
        "${SCRIPT_DIR}/hw/build/bitstream/" \
        2>/dev/null || warn "No bitstream files found on server"

    info "Downloading IP repo..."
    rsync -avz --progress \
        --include '*.zip' \
        --exclude '*' \
        "${REMOTE_SERVER}:${REMOTE_DIR}/hw/build/ip_repo/" \
        "${SCRIPT_DIR}/hw/build/ip_repo/" \
        2>/dev/null || warn "No IP files found on server"

    # Fetch HLS csynth reports (latency, resources, interfaces)
    info "Downloading Vitis HLS reports..."
    mkdir -p "${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS/hls/syn/report"
    rsync -avz --progress \
        "${REMOTE_SERVER}:${REMOTE_DIR}/hw/${PROJECT_NAME}_HLS/hls/syn/report/" \
        "${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS/hls/syn/report/" \
        2>/dev/null || warn "No HLS reports found on server"

    # Fetch Vivado implementation reports (utilization, timing, power)
    local vivado_runs="hw/build/${PROJECT_NAME}_Vivado/${PROJECT_NAME}_Vivado.runs"
    info "Downloading Vivado reports..."

    # HLS kernel synthesis utilization
    mkdir -p "${SCRIPT_DIR}/${vivado_runs}/design_1_${PROJECT_NAME}_0_0_synth_1"
    rsync -avz --progress \
        --include '*.rpt' --exclude '*' \
        "${REMOTE_SERVER}:${REMOTE_DIR}/${vivado_runs}/design_1_${PROJECT_NAME}_0_0_synth_1/" \
        "${SCRIPT_DIR}/${vivado_runs}/design_1_${PROJECT_NAME}_0_0_synth_1/" \
        2>/dev/null || warn "No HLS kernel synth reports found"

    # Implementation reports (utilization_placed, timing_summary_routed, power_routed)
    mkdir -p "${SCRIPT_DIR}/${vivado_runs}/impl_1"
    rsync -avz --progress \
        --include '*.rpt' --exclude '*' \
        "${REMOTE_SERVER}:${REMOTE_DIR}/${vivado_runs}/impl_1/" \
        "${SCRIPT_DIR}/${vivado_runs}/impl_1/" \
        2>/dev/null || warn "No Vivado impl reports found"

    success "Build results and reports fetched"
}

# ── Report display ───────────────────────────────────────────────────────────

color_util() {
    # Color a utilization percentage: green <50, yellow 50-80, red >80
    local val="$1"
    local int_val="${val%.*}"
    int_val="${int_val:-0}"
    if   (( int_val >= 80 )); then echo -e "${RED}${val}%${NC}"
    elif (( int_val >= 50 )); then echo -e "${YELLOW}${val}%${NC}"
    else                           echo -e "${GREEN}${val}%${NC}"
    fi
}

draw_bar() {
    local val="$1"
    local width=20
    local int_val="${val%.*}"
    int_val="${int_val:-0}"
    local filled
    filled=$(awk "BEGIN {printf \"%d\", ($val * $width / 100) + 0.5}")
    (( filled > width )) && filled=$width
    local empty=$(( width - filled ))

    local color
    if   (( int_val >= 80 )); then color="${RED}"
    elif (( int_val >= 50 )); then color="${YELLOW}"
    else                           color="${GREEN}"
    fi

    local bar="${color}"
    for ((i=0; i<filled; i++)); do bar+="█"; done
    bar+="${DIM}"
    for ((i=0; i<empty; i++)); do bar+="░"; done
    bar+="${NC}"
    echo -e "$bar"
}

_target_report_inner() {
    banner "FPGA Utilization & Timing Report"

    local vivado_runs="${SCRIPT_DIR}/hw/build/${PROJECT_NAME}_Vivado/${PROJECT_NAME}_Vivado.runs"
    local util_rpt="${vivado_runs}/impl_1/design_1_wrapper_utilization_placed.rpt"
    local timing_rpt="${vivado_runs}/impl_1/design_1_wrapper_timing_summary_routed.rpt"
    local power_rpt="${vivado_runs}/impl_1/design_1_wrapper_power_routed.rpt"

    # ── Utilization ──────────────────────────────────────────────────────
    if [[ ! -f "$util_rpt" ]]; then
        warn "Utilization report not found at ${util_rpt}"
        warn "Run './synth.sh fetch' or './synth.sh all' first"
        return 1
    fi

    local device
    device=$(grep -m1 "| Device" "$util_rpt" | sed 's/.*: *//' | tr -d '[:space:]|')

    echo -e "${BOLD}${CYAN}  Device: ${NC}${device}"
    echo ""
    echo -e "${BOLD}  ┌─────────────────────┬────────────┬────────────┬──────────┬──────────────────────┐${NC}"
    echo -e "${BOLD}  │ Resource            │       Used │  Available │   Util%  │                      │${NC}"
    echo -e "${BOLD}  ├─────────────────────┼────────────┼────────────┼──────────┼──────────────────────┤${NC}"

    # Parse key resources from the utilization report
    local resources=("CLB LUTs" "CLB Registers" "Block RAM Tile" "URAM" "DSPs" "CARRY8")
    local labels=("LUT" "Flip-Flop" "Block RAM" "URAM" "DSP" "CARRY8")

    for i in "${!resources[@]}"; do
        local res="${resources[$i]}"
        local label="${labels[$i]}"
        # Match lines like: | CLB LUTs                   | 12353 |     0 |          0 |    230400 |  5.36 |
        local line
        line=$(grep -m1 "^| ${res} " "$util_rpt" || true)
        if [[ -z "$line" ]]; then continue; fi

        local used avail util
        used=$(echo "$line" | awk -F'|' '{gsub(/[ ]+/,"",$3); print $3}')
        avail=$(echo "$line" | awk -F'|' '{gsub(/[ ]+/,"",$6); print $6}')
        util=$(echo "$line" | awk -F'|' '{gsub(/[ ]+/,"",$7); print $7}')

        if [[ -z "$util" || "$util" == "" ]]; then continue; fi

        local bar
        bar=$(draw_bar "$util")

        # Color the util% value
        local int_val="${util%.*}"
        int_val="${int_val:-0}"
        local color="${GREEN}"
        if   (( int_val >= 80 )); then color="${RED}"
        elif (( int_val >= 50 )); then color="${YELLOW}"
        fi

        # Fixed 7-char util field: right-align "XX.XX%" in 7 chars
        local util_padded
        util_padded=$(printf "%7s" "${util}%")

        printf "  │ %-19s │ %10s │ %10s │ ${color}%s${NC}  │ " "$label" "$used" "$avail" "$util_padded"
        echo -ne "${bar}"
        echo " │"
    done

    echo -e "${BOLD}  └─────────────────────┴────────────┴────────────┴──────────┴──────────────────────┘${NC}"

    # ── Timing ───────────────────────────────────────────────────────────
    echo ""
    if [[ -f "$timing_rpt" ]]; then
        # Extract WNS and clock frequency from the main clock
        local wns_line
        wns_line=$(grep -A2 "clk_out1_design_1_clk_wiz" "$timing_rpt" | grep -m1 "Slack\|Worst Slack\|0 *Failing" || true)

        # Get the intra-clock timing line
        local timing_line
        timing_line=$(grep -m1 "^clk_out1_design_1_clk_wiz_0_0 " "$timing_rpt" || true)

        # Parse WNS from the Setup section
        # Get clock period
        local period=""
        period=$(grep "period=" "$timing_rpt" | head -1 | sed 's/.*period=\([0-9.]*\)ns.*/\1/' || true)
        local freq=""
        if [[ -n "$period" && "$period" != "0" ]]; then
            freq=$(awk "BEGIN {printf \"%.0f\", 1000/$period}")
        fi

        # Find the intra-clock section for the design clock (skip clk_pl_0 which has NA)
        # Get Setup/Hold from the first non-NA Setup line
        local setup_line=""
        local hold_line=""
        while IFS= read -r line; do
            if [[ "$line" == Setup* && "$line" != *"NA"* ]]; then
                setup_line="$line"
                break
            fi
        done < "$timing_rpt"
        # Hold is always right after Setup
        if [[ -n "$setup_line" ]]; then
            local setup_lineno
            setup_lineno=$(grep -n "^${setup_line}$" "$timing_rpt" | head -1 | cut -d: -f1)
            hold_line=$(sed -n "$((setup_lineno+1))p" "$timing_rpt")
        fi

        local wns="" failing=""
        if [[ -n "$setup_line" ]]; then
            failing=$(echo "$setup_line" | awk '{print $3}')
            wns=$(echo "$setup_line" | sed 's/.*Worst Slack *//' | awk '{print $1}' | tr -d ',')
        fi

        echo -e "${BOLD}${CYAN}  Timing Summary${NC}"
        echo -e "  ────────────────────────────────────"

        if [[ -n "$freq" ]]; then
            echo -e "  Clock frequency:  ${BOLD}${freq} MHz${NC} (period = ${period} ns)"
        fi

        if [[ -n "$wns" ]]; then
            local wns_num="${wns%ns}"
            local wns_color="${GREEN}"
            if [[ "$wns_num" == -* ]]; then
                wns_color="${RED}"
            elif (( $(awk "BEGIN {print ($wns_num < 0.5) ? 1 : 0}") )); then
                wns_color="${YELLOW}"
            fi
            echo -e "  Setup WNS:        ${wns_color}${BOLD}${wns}${NC}  (${failing} failing endpoints)"
        fi

        if [[ -n "$hold_line" && "$hold_line" != *"NA"* ]]; then
            local hold_wns hold_failing
            hold_failing=$(echo "$hold_line" | awk '{print $3}')
            hold_wns=$(echo "$hold_line" | sed 's/.*Worst Slack *//' | awk '{print $1}' | tr -d ',')
            local hold_color="${GREEN}"
            if [[ "${hold_wns%ns}" == -* ]]; then hold_color="${RED}"; fi
            echo -e "  Hold WHS:         ${hold_color}${BOLD}${hold_wns}${NC}  (${hold_failing} failing endpoints)"
        fi

        if [[ -n "$wns" ]]; then
            local wns_val="${wns%ns}"
            if [[ "$wns_val" == -* ]]; then
                echo -e "\n  ${RED}${BOLD}  TIMING VIOLATED — design will not meet frequency target${NC}"
            else
                echo -e "\n  ${GREEN}  Timing met${NC}"
            fi
        fi
    else
        warn "Timing report not found"
    fi

    # ── Power (brief) ────────────────────────────────────────────────────
    if [[ -f "$power_rpt" ]]; then
        echo ""
        echo -e "${BOLD}${CYAN}  Power Summary${NC}"
        echo -e "  ────────────────────────────────────"
        local total_power
        total_power=$(grep -m1 "Total On-Chip Power" "$power_rpt" | awk -F'|' '{gsub(/[ ]+/,"",$3); print $3}' || true)
        local dynamic_power
        dynamic_power=$(grep -m1 "Dynamic" "$power_rpt" | head -1 | awk -F'|' '{gsub(/[ ]+/,"",$3); print $3}' || true)
        if [[ -n "$total_power" ]]; then
            echo -e "  Total on-chip:    ${BOLD}${total_power}${NC}"
        fi
        if [[ -n "$dynamic_power" ]]; then
            echo -e "  Dynamic:          ${BOLD}${dynamic_power}${NC}"
        fi
    fi

    # ── Warnings & Methodology ───────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${CYAN}  Warnings${NC}"
    echo -e "  ────────────────────────────────────"

    local has_warnings=false

    # Check for CRITICAL WARNINGs in all .rpt files
    local critical_count=0
    for rpt in "${vivado_runs}/impl_1/"*.rpt; do
        [[ -f "$rpt" ]] || continue
        local c
        c=$(grep -ci "CRITICAL WARNING" "$rpt" 2>/dev/null || true)
        critical_count=$(( critical_count + c ))
    done
    if (( critical_count > 0 )); then
        echo -e "  ${RED}${BOLD}CRITICAL WARNINGS: ${critical_count}${NC}"
        has_warnings=true
    fi

    # Parse methodology violations from timing report
    if [[ -f "$timing_rpt" ]]; then
        local in_methodology=false
        while IFS= read -r line; do
            if [[ "$line" == *"Report Methodology"* ]]; then
                in_methodology=true
                continue
            fi
            if [[ "$in_methodology" == true ]]; then
                # Parse lines like: LUTAR-1  Warning   LUT drives async reset alert  8
                if [[ "$line" =~ ^[A-Z].*Warning ]]; then
                    local rule severity desc violations
                    rule=$(echo "$line" | awk '{print $1}')
                    violations=$(echo "$line" | awk '{print $NF}')
                    desc=$(echo "$line" | sed "s/^${rule}[[:space:]]*Warning[[:space:]]*//" | sed "s/[[:space:]]*${violations}[[:space:]]*$//")
                    echo -e "  ${YELLOW}${rule}${NC}  ${desc} (${violations} violations)"
                    has_warnings=true
                elif [[ "$line" =~ ^[A-Z].*Critical ]]; then
                    local rule violations
                    rule=$(echo "$line" | awk '{print $1}')
                    violations=$(echo "$line" | awk '{print $NF}')
                    desc=$(echo "$line" | sed "s/^${rule}[[:space:]]*Critical[[:space:]]*//" | sed "s/[[:space:]]*${violations}[[:space:]]*$//")
                    echo -e "  ${RED}${BOLD}${rule}${NC}  ${desc} (${violations} violations)"
                    has_warnings=true
                elif [[ "$line" == "" && "$in_methodology" == true && "$has_warnings" == true ]]; then
                    break
                elif [[ "$line" == *"Note:"* ]]; then
                    break
                fi
            fi
        done < "$timing_rpt"
    fi

    if [[ "$has_warnings" == false ]]; then
        echo -e "  ${GREEN}No warnings${NC}"
    fi

    # ── Vitis HLS Summary ────────────────────────────────────────────
    local hls_xml="${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS/hls/syn/report/${PROJECT_NAME}_csynth.xml"
    local hls_rpt="${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS/hls/syn/report/csynth.rpt"

    echo ""
    echo -e "${BOLD}${CYAN}  Vitis HLS Summary${NC}"
    echo -e "  ────────────────────────────────────"

    if [[ ! -f "$hls_xml" && ! -f "$hls_rpt" ]]; then
        warn "No HLS reports found — run './synth.sh fetch' first"
    else
        # ── HLS Timing ──────────────────────────────────────────────
        if [[ -f "$hls_xml" ]]; then
            local hls_target hls_estimated
            hls_target=$(grep -o '<TargetClockPeriod>[^<]*</TargetClockPeriod>' "$hls_xml" | sed 's/<[^>]*>//g')
            hls_estimated=$(grep -o '<EstimatedClockPeriod>[^<]*</EstimatedClockPeriod>' "$hls_xml" | sed 's/<[^>]*>//g')

            if [[ -n "$hls_target" && -n "$hls_estimated" ]]; then
                local hls_freq
                hls_freq=$(awk "BEGIN {printf \"%.0f\", 1000/$hls_target}")
                local hls_margin
                hls_margin=$(awk "BEGIN {printf \"%.2f\", $hls_target - $hls_estimated}")

                local hls_color="${GREEN}"
                if (( $(awk "BEGIN {print ($hls_estimated > $hls_target) ? 1 : 0}") )); then
                    hls_color="${RED}"
                elif (( $(awk "BEGIN {print ($hls_margin < 0.5) ? 1 : 0}") )); then
                    hls_color="${YELLOW}"
                fi

                echo -e "  Target clock:     ${BOLD}${hls_target} ns${NC} (${hls_freq} MHz)"
                echo -e "  Estimated clock:  ${hls_color}${BOLD}${hls_estimated} ns${NC}  (margin: ${hls_color}${hls_margin} ns${NC})"
            fi
        fi

        # ── HLS II / Issue Violations ───────────────────────────────
        local hls_has_violations=false
        if [[ -f "$hls_rpt" ]]; then
            # Extract only the Performance & Resource Estimates table (between the two +--- borders
            # after "Performance & Resource Estimates"), then check for non-"-" Issue/Violation columns
            local in_perf_table=false
            local header_seen=false
            while IFS= read -r line; do
                # Detect start of performance section
                if [[ "$line" == *"Performance & Resource Estimates"* ]]; then
                    in_perf_table=true
                    continue
                fi
                if [[ "$in_perf_table" == false ]]; then continue; fi

                # Stop at next section delimiter
                if [[ "$line" == "=="* ]]; then break; fi

                # Skip separator and header rows
                if [[ "$line" == +* ]]; then continue; fi
                if [[ "$line" == *"Issue"* ]]; then continue; fi
                if [[ "$line" == *"& Loops"* ]]; then continue; fi
                if [[ "$line" == *"Name Prefix"* ]]; then break; fi

                # Data rows start with |
                if [[ "$line" != "|"* ]]; then continue; fi

                local module issue_type violation_type
                module=$(echo "$line" | awk -F'|' '{gsub(/^[ +o*]+/,"",$2); gsub(/[ ]+$/,"",$2); print $2}')
                issue_type=$(echo "$line" | awk -F'|' '{gsub(/[ ]+/,"",$3); print $3}')
                violation_type=$(echo "$line" | awk -F'|' '{gsub(/[ ]+/,"",$4); print $4}')

                if [[ -n "$issue_type" && "$issue_type" != "-" ]]; then
                    echo -e "  ${RED}${BOLD}Issue:${NC} ${module}  ${RED}${issue_type}${NC} — ${violation_type}"
                    hls_has_violations=true
                elif [[ -n "$violation_type" && "$violation_type" != "-" ]]; then
                    echo -e "  ${RED}${BOLD}Violation:${NC} ${module}  ${violation_type}"
                    hls_has_violations=true
                fi
            done < "$hls_rpt"
        fi

        if [[ "$hls_has_violations" == false ]]; then
            echo -e "  ${GREEN}No HLS violations${NC}"
        fi
    fi

    echo ""
}

target_report() {
    mkdir -p "${SCRIPT_DIR}/data"
    local report_file="${SCRIPT_DIR}/data/vivado_report.txt"
    _target_report_inner | tee >(sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > "$report_file")
    success "Vivado report saved to data/vivado_report.txt"
}

target_help() {
    echo -e "
${BOLD}${CYAN}Remote FPGA Synthesis Script${NC}

${BOLD}Usage:${NC} ./synth.sh [target] [--clean] [--ila] [--kernel <name>]

${BOLD}${DIM}By default, existing HLS / Vivado projects on the server are reused.
Pass ${GREEN}--clean${NC}${DIM} to wipe them before building.
Pass ${GREEN}--ila${NC}${DIM} to add system_ila debug cores (master1 + AXI-Lite). Default off; needs ${GREEN}--clean${NC}${DIM} if Vivado project already exists.
Pass ${GREEN}--kernel sparse_solve${NC}${DIM} (or ${GREEN}dense_solve${NC}${DIM}, default) to pick which kernel to build.${NC}

${BOLD}${YELLOW}Targets (passed to hw/build.py on the remote server):${NC}

  ${GREEN}all${NC}               : Full pipeline: HLS → Vivado → bitstream ${DIM}(default)${NC}
  ${GREEN}ip${NC}                : HLS synthesis + IP export
  ${GREEN}hls_project${NC}       : Create the Vitis HLS project
  ${GREEN}hls_sim${NC}           : Run HLS C++ simulation
  ${GREEN}vivado_project${NC}    : Create the Vivado project
  ${GREEN}bitstream${NC}         : Vivado synthesis → bitstream
  ${GREEN}extract_bitstream${NC} : Extract bitstream from existing build
  ${GREEN}clean${NC}             : Clean build artifacts (keep IP zip)
  ${GREEN}cleanall${NC}          : Delete everything including build/

${BOLD}${YELLOW}Script-only targets:${NC}

  ${GREEN}sync${NC}              : Only sync files to the server (no build)
  ${GREEN}fetch${NC}             : Only fetch results from the server (no build)
  ${GREEN}report${NC}            : Display a friendly utilization & timing summary from Vivado reports
  ${GREEN}status${NC}            : Check if background synthesis is still running
  ${GREEN}logs${NC}              : Follow synthesis log live (Ctrl+C safe — job keeps running)
  ${GREEN}debug${NC}             : Full debug flow: sync → HLS synth → fetch project → open Vitis locally
  ${GREEN}fetch_hls${NC}         : Fetch the full HLS project from the server (for local inspection)
  ${GREEN}open_vitis${NC}        : Open the local HLS project in Vitis (no remote build)
  ${GREEN}connect${NC}           : Open an interactive SSH session to the server (X11)
  ${GREEN}gui_vivado${NC}        : Open the Vivado project GUI remotely (X11)
  ${GREEN}help${NC}              : Show this help message

${BOLD}${YELLOW}Config:${NC}

  Server:  ${REMOTE_SERVER}
  Remote:  ${REMOTE_DIR}
  Vivado:  ${XILINX_VIVADO_SETTINGS}
  Vitis:   ${XILINX_VITIS_SETTINGS}

${BOLD}${YELLOW}Examples:${NC}

  ./synth.sh                                    ${DIM}# Dense full pipeline, reusing projects${NC}
  ./synth.sh --clean                            ${DIM}# Dense full pipeline from scratch${NC}
  ./synth.sh --kernel sparse_solve              ${DIM}# Sparse full pipeline${NC}
  ./synth.sh --kernel sparse_solve --clean ip   ${DIM}# Sparse HLS synthesis from a fresh project${NC}
  ./synth.sh --kernel sparse_solve hls_sim      ${DIM}# Sparse C++ csim only${NC}
  ./synth.sh --kernel sparse_solve status       ${DIM}# Check the running sparse build${NC}
  ./synth.sh --kernel sparse_solve fetch        ${DIM}# Pull sparse results back${NC}
  ./synth.sh --kernel sparse_solve report       ${DIM}# Display the sparse synthesis report${NC}
  ./synth.sh sync                               ${DIM}# Just upload files, don't build${NC}
  ./synth.sh connect                            ${DIM}# SSH into the server${NC}
"
}

target_connect() {
    banner "Connecting to ${REMOTE_SERVER}"
    ssh -Y "$REMOTE_SERVER"
}

target_fetch_hls_project() {
    banner "Fetching full HLS project from ${REMOTE_SERVER}"

    info "Downloading ${PROJECT_NAME}_HLS/ (needed for Schedule Viewer)..."
    mkdir -p "${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS"
    rsync -avz --progress \
        "${REMOTE_SERVER}:${REMOTE_DIR}/hw/${PROJECT_NAME}_HLS/" \
        "${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS/" \
        || fail "Failed to fetch HLS project from server"

    success "HLS project fetched to hw/${PROJECT_NAME}_HLS/"
}

find_local_vitis() {
    # Auto-detect local Xilinx installation (same paths as build.py)
    local search_paths=("/c/Xilinx" "/d/Xilinx" "$HOME/Xilinx")
    for base in "${search_paths[@]}"; do
        if [[ -d "$base" ]]; then
            local ver
            ver=$(ls -1 "$base" | sort -rV | head -1)
            if [[ -n "$ver" ]]; then
                for bin_name in "Vitis_HLS/bin/vitis_hls" "Vitis/bin/vitis"; do
                    local candidate="${base}/${ver}/${bin_name}"
                    if [[ -f "$candidate" || -f "${candidate}.bat" ]]; then
                        echo "${base}/${ver}"
                        return 0
                    fi
                done
            fi
        fi
    done
    return 1
}

target_open_vitis_local() {
    banner "Opening Vitis HLS locally"

    local xilinx_dir
    xilinx_dir=$(find_local_vitis) || fail "No local Xilinx/Vitis installation found in C:\\Xilinx, D:\\Xilinx, or ~/Xilinx"
    info "Using Xilinx installation at ${xilinx_dir}"

    local hls_project="${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS"
    if [[ ! -d "$hls_project" ]]; then
        fail "HLS project not found at ${hls_project} — run './synth.sh debug' or './synth.sh fetch_hls' first"
    fi

    # Try vitis_hls first (older/standalone HLS), then vitis (unified 2025+)
    if [[ -f "${xilinx_dir}/Vitis_HLS/bin/vitis_hls" || -f "${xilinx_dir}/Vitis_HLS/bin/vitis_hls.bat" ]]; then
        info "Launching vitis_hls..."
        "${xilinx_dir}/Vitis_HLS/bin/vitis_hls" -p "$hls_project" &
    elif [[ -f "${xilinx_dir}/Vitis/bin/vitis" || -f "${xilinx_dir}/Vitis/bin/vitis.bat" ]]; then
        info "Launching vitis..."
        "${xilinx_dir}/Vitis/bin/vitis" -w "$hls_project" &
    else
        fail "Could not find vitis_hls or vitis binary in ${xilinx_dir}"
    fi

    success "Vitis launched — check your taskbar"
}

target_debug() {
    banner "Debug flow: sync → HLS synthesis → fetch → open locally"
    target_sync
    target_build "ip"
    target_fetch_hls_project
    target_open_vitis_local
}

target_gui_vivado() {
    banner "Opening Vivado GUI on ${REMOTE_SERVER}"
    info "Launching with X11 forwarding — make sure an X server is running locally (e.g. VcXsrv, MobaXterm)"
    ssh -Yt "$REMOTE_SERVER" "$(xilinx_env_cmd) && cd ${REMOTE_DIR}/hw && vivado build/${PROJECT_NAME}_Vivado/${PROJECT_NAME}_Vivado.xpr; exec bash"
}

# ── CLI ──────────────────────────────────────────────────────────────────────

CLEAN=false
USE_ILA=false
ARGS=()
# Two-pass: extract flags first, then positional args.
i=1
while [[ $i -le $# ]]; do
    arg="${!i}"
    case "$arg" in
        --clean)
            CLEAN=true
            ;;
        --ila)
            USE_ILA=true
            ;;
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

PROJECT_NAME=$(kernel_to_project "$KERNEL")

# Per-variant tmux session + log so variants synth in parallel; tmux disallows '.' in session names → substitute '_'.
SESSION_TAG="${PROJECT_NAME//./_}"
TMUX_SESSION="milp_synth_${SESSION_TAG}"
REMOTE_LOG="/home/gjenni/milp-fpga/build_${SESSION_TAG}.log"

TARGET="${1:-all}"

# Script-only targets (no remote build)
case "$TARGET" in
    help)
        target_help
        exit 0
        ;;
    connect)
        setup_ssh_key
        target_connect
        exit 0
        ;;
    debug)
        setup_ssh_key
        target_debug
        exit 0
        ;;
    fetch_hls)
        setup_ssh_key
        target_fetch_hls_project
        exit 0
        ;;
    open_vitis)
        target_open_vitis_local
        exit 0
        ;;
    report)
        target_report
        exit 0
        ;;
    gui_vivado)
        setup_ssh_key
        target_gui_vivado
        exit 0
        ;;
    sync)
        setup_ssh_key
        target_sync
        exit 0
        ;;
    fetch)
        setup_ssh_key
        target_fetch
        target_fetch_hls_project
        target_report
        exit 0
        ;;
    clean|cleanall)
        setup_ssh_key
        banner "Cleaning remote and local build artifacts"
        target_sync
        target_build "$TARGET"
        info "Cleaning local build artifacts..."
        rm -rf "${SCRIPT_DIR}/hw/${PROJECT_NAME}_HLS"
        if [[ "$TARGET" == "cleanall" ]]; then
            rm -rf "${SCRIPT_DIR}/hw/build"
        fi
        success "Local build artifacts cleaned"
        exit 0
        ;;
    status)
        setup_ssh_key
        target_status
        exit 0
        ;;
    logs)
        setup_ssh_key
        target_logs
        exit 0
        ;;
esac

# Build targets: sync → build (background for 'all'/'hls_cosim', foreground otherwise) → fetch
setup_ssh_key
banner "Remote synthesis: ${TARGET}"

target_sync
if [[ "$TARGET" == "all" || "$TARGET" == "hls_cosim" ]]; then
    target_build_bg "$TARGET"
else
    target_build "$TARGET"
    target_fetch
    target_fetch_hls_project
    target_report
fi

echo -e "\n${BOLD}${GREEN}All done!${NC}\n"
