#!/usr/bin/env python3
"""Build script for FPGA HLS kernels."""

import argparse
import glob
import os
import shutil
import subprocess
import sys
import zipfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(SCRIPT_DIR, "build")

# ── Kernel registry ───────────────────────────────────────────────────────────

KERNELS = {
    "dense_solve": {
        "project_name": "DenseSolve",
        "top_function": "DenseSolve",
        "src_files": [
            "kernels/dense_solve/src/dense_solve.h",
            "kernels/dense_solve/src/dense_solve.cpp",
            "kernels/dense_solve/src/gaussian_solve.h",
            "kernels/dense_solve/src/gaussian_solve.cpp",
            "kernels/dense_solve/src/cholesky_solve.h",
            "kernels/dense_solve/src/cholesky_solve.cpp",
        ],
        "tb_file": "kernels/dense_solve/tb/dense_solve_tb.cpp",
        "tb_cflags": "-Ikernels/dense_solve/src -Ikernels/common",
        "clk_freq_mhz": 200,
    },
    "sparse_solve": {
        "project_name": "SparseSolve",
        "top_function": "SparseSolve",
        "src_files": [
            "kernels/sparse_solve/src/sparse_solve.h",
            "kernels/sparse_solve/src/sparse_solve.cpp",
            "kernels/sparse_solve/src/sparse_kform.h",
            "kernels/sparse_solve/src/sparse_kform.cpp",
            "kernels/sparse_solve/src/sparse_factor.h",
            "kernels/sparse_solve/src/sparse_factor.cpp",
            "kernels/sparse_solve/src/sparse_triangular_solve.h",
            "kernels/sparse_solve/src/sparse_triangular_solve.cpp",
        ],
        "tb_file": "kernels/sparse_solve/tb/sparse_solve_tb.cpp",
        "tb_cflags": "-Ikernels/sparse_solve/src -Ikernels/common",
        "clock_period_ns": 5.5,
        "clk_freq_mhz": 150,
    },
}

PROJECT_NAME = None  # Set at runtime from --kernel + variant args
KERNEL_CFG = None    # Set at runtime from --kernel arg
NUM_JOBS = 4         # Set at runtime from --jobs arg
CLEAN_BEFORE_BUILD = False  # Set at runtime from --clean arg
USE_ILA = False      # Set at runtime from --ila arg
Q_INT_BITS = 31      # Set at runtime from --q-int arg
Q_FRAC_BITS = 40     # Set at runtime from --q-frac arg
USE_GAUSSIAN = False # Set at runtime from --use-gaussian arg (dense only)
UNROLL = None        # Set at runtime from --unroll arg; None means use kernel default
VARIANT_DEFINES = "" # Computed at runtime; injected into HLS cflags

# ── Colors ───────────────────────────────────────────────────────────────────

if sys.platform == "win32":
    # Enable ANSI escape codes on Windows 10+
    os.system("")

BOLD = "\033[1m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
DIM = "\033[2m"
RESET = "\033[0m"


def info(msg):
    print(f"{CYAN}[INFO]{RESET} {msg}")


def success(msg):
    print(f"{GREEN}[DONE]{RESET} {msg}")


def warn(msg):
    print(f"{YELLOW}[WARN]{RESET} {msg}")


def error(msg):
    print(f"{RED}[ERROR]{RESET} {msg}")

# Auto-detect Xilinx installation and add to PATH
XILINX_SEARCH_PATHS = [
    r"C:\Xilinx",
    r"D:\Xilinx",
    os.path.expanduser(r"~\Xilinx"),
]


def _find_xilinx_env():
    """Find Xilinx installation and return PATH additions."""
    for base in XILINX_SEARCH_PATHS:
        if not os.path.isdir(base):
            continue
        # Find the latest version directory
        versions = sorted(
            [d for d in os.listdir(base) if os.path.isdir(os.path.join(base, d, "Vivado"))],
            reverse=True,
        )
        if not versions:
            continue
        ver = versions[0]
        vivado_bin = os.path.join(base, ver, "Vivado", "bin")
        vitis_bin = os.path.join(base, ver, "Vitis", "bin")
        vitis_hls_bin = os.path.join(base, ver, "Vitis_HLS", "bin")
        paths = []
        if os.path.isdir(vivado_bin):
            paths.append(vivado_bin)
        if os.path.isdir(vitis_bin):
            paths.append(vitis_bin)
        if os.path.isdir(vitis_hls_bin):
            paths.append(vitis_hls_bin)
        if paths:
            info(f"Found Xilinx {BOLD}{ver}{RESET} at {base}")
            return paths
    return []


def _setup_env():
    """Set up environment with Xilinx tools on PATH."""
    env = os.environ.copy()
    env["XILINX_LOCAL_USER_DATA"] = "no"
    if shutil.which("vivado") and shutil.which("vitis-run"):
        return env
    extra = _find_xilinx_env()
    if extra:
        env["PATH"] = os.pathsep.join(extra) + os.pathsep + env.get("PATH", "")
    return env


BUILD_ENV = _setup_env()


def _colorize_line(line):
    """Apply ANSI color to a tool output line based on its content."""
    if "ERROR:" in line or "CRITICAL:" in line:
        return f"{RED}{line}{RESET}"
    if "WARNING:" in line:
        return f"{YELLOW}{line}{RESET}"
    if "INFO:" in line:
        return f"{DIM}{line}{RESET}"
    return line


def run(cmd, **kwargs):
    """Run a shell command with colorized output, exit on failure."""
    print(f"\n{BOLD}{CYAN}>>>{RESET} {cmd}")
    proc = subprocess.Popen(
        cmd, shell=True, cwd=SCRIPT_DIR, env=BUILD_ENV,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1, **kwargs,
    )
    for line in proc.stdout:
        print(_colorize_line(line), end="")
    proc.wait()
    if proc.returncode != 0:
        error(f"Command failed with exit code {proc.returncode}")
        sys.exit(proc.returncode)
    success(f"Command completed successfully")


def rmrf(*paths):
    """Remove files/directories (like rm -rf), silently ignoring missing ones."""
    for p in paths:
        full = os.path.join(SCRIPT_DIR, p)
        if os.path.isdir(full):
            shutil.rmtree(full, ignore_errors=True)
        elif os.path.isfile(full):
            os.remove(full)


def rmglob(pattern):
    """Remove files matching a glob pattern. Tolerates files vanishing between
    glob and remove (concurrent build.py instances both cleaning the same logs)."""
    for f in glob.glob(os.path.join(SCRIPT_DIR, pattern)):
        try:
            os.remove(f)
        except FileNotFoundError:
            pass


def ensure_build_dirs():
    """Create build output directories if they don't exist."""
    for subdir in ["ip_repo", "bitstream"]:
        os.makedirs(os.path.join(BUILD_DIR, subdir), exist_ok=True)


def cleanup_logs():
    """Delete .jou and .log files left by Vivado/Vitis HLS."""
    rmglob("vivado*.jou")
    rmglob("vivado*.log")
    rmglob("vivado*.str")
    rmrf("vitis_hls.log", "NA", ".Xil")


# ── TCL generation ────────────────────────────────────────────────────────────


def _hls_project_tcl_rel():
    return f"tcl/hls_project_{KERNEL_CFG['project_name']}.tcl"


def _hls_synth_tcl_rel():
    return f"tcl/hls_synth_{KERNEL_CFG['project_name']}.tcl"


def _hls_sim_tcl_rel():
    return f"tcl/hls_sim_{KERNEL_CFG['project_name']}.tcl"


def _hls_cosim_tcl_rel():
    return f"tcl/hls_cosim_{KERNEL_CFG['project_name']}.tcl"


def _vivado_impl_tcl_rel():
    return f"tcl/vivado_impl_{PROJECT_NAME}.tcl"


def generate_hls_project_tcl(extra_tb_cflags=""):
    """Generate tcl/hls_project_<KERNEL>.tcl from the active kernel config."""
    cfg = KERNEL_CFG
    clk = cfg.get("clock_period_ns", 5)
    src_cflags = f"-I../shared {VARIANT_DEFINES}".strip()
    tb_cflags = cfg["tb_cflags"]
    if extra_tb_cflags:
        tb_cflags += " " + extra_tb_cflags
    tb_cflags_full = f"{tb_cflags} -I../shared {VARIANT_DEFINES}".strip()
    lines = [
        f'open_component {cfg["project_name"]}_HLS -flow_target vivado',
        f'set_top {cfg["top_function"]}',
    ]
    for src in cfg["src_files"]:
        lines.append(f'add_files {src} -cflags "{src_cflags}"')
    lines.append(f'add_files -tb {cfg["tb_file"]} -cflags "{tb_cflags_full}"')
    lines.extend([
        "set_part {xczu7ev-ffvc1156-2-e}",
        f"create_clock -period {clk} -name default",
        # `-ipname` gives each variant a unique VLNV; without it all variants share the top-function name.
        f'config_export -display_name {cfg["project_name"]} -ipname {cfg["project_name"]}'
        f' -format ip_catalog -output ./build/ip_repo/{cfg["project_name"]}.zip'
        f' -rtl verilog -vendor EPFL -vivado_clock {clk}',
    ])
    rel = _hls_project_tcl_rel()
    tcl_path = os.path.join(SCRIPT_DIR, rel)
    with open(tcl_path, "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    info(f"Generated {rel} for kernel {BOLD}{cfg['project_name']}{RESET} "
         f"(clock={clk}ns)")


def generate_hls_synth_tcl():
    """Generate tcl/hls_synth_<KERNEL>.tcl from the active kernel config."""
    cfg = KERNEL_CFG
    lines = [
        f"source ./{_hls_project_tcl_rel()}",
        "csynth_design",
        f'export_design -rtl verilog -format ip_catalog -output ./build/ip_repo/{cfg["project_name"]}.zip',
    ]
    rel = _hls_synth_tcl_rel()
    tcl_path = os.path.join(SCRIPT_DIR, rel)
    with open(tcl_path, "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    info(f"Generated {rel} for kernel {BOLD}{cfg['project_name']}{RESET}")


def generate_hls_sim_tcl():
    """Generate tcl/hls_sim_<KERNEL>.tcl from the active kernel config."""
    lines = [
        f"source ./{_hls_project_tcl_rel()}",
        "csim_design -O",
    ]
    tcl_path = os.path.join(SCRIPT_DIR, _hls_sim_tcl_rel())
    with open(tcl_path, "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def generate_hls_cosim_tcl():
    """Generate tcl/hls_cosim_<KERNEL>.tcl: csynth then C/RTL co-simulation."""
    lines = [
        f"source ./{_hls_project_tcl_rel()}",
        "csynth_design",
        # trace_level controls cosim waveform tracing; port keeps the wdb small. 2025.2 values: none|port|all.
        "cosim_design -trace_level port -rtl verilog",
    ]
    tcl_path = os.path.join(SCRIPT_DIR, _hls_cosim_tcl_rel())
    with open(tcl_path, "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def generate_vivado_impl_tcl():
    """Generate tcl/vivado_impl_<KERNEL>.tcl from the active kernel config."""
    proj = f"{PROJECT_NAME}_Vivado"
    rel = _vivado_impl_tcl_rel()
    lines = [
        f"# Usage: vivado -mode batch -source {rel}",
        "",
        f"open_project build/{proj}/{proj}.xpr",
        "update_compile_order -fileset sources_1",
        "",
        "# Refresh the IP catalog",
        "update_ip_catalog",
        "# Upgrade all IP instances in the project",
        "upgrade_ip [get_ips]",
        "# Report the status of IP instances",
        "report_ip_status",
        "",
        "reset_run [get_runs synth_1]",
        "reset_run [get_runs impl_1]",
        "",
        f"launch_runs impl_1 -to_step write_bitstream -jobs {NUM_JOBS}",
        "wait_on_run impl_1",
        "",
        f"write_hw_platform -fixed -include_bit -force -file ./build/{proj}/design_1_wrapper.xsa",
        "",
        '# Check if implementation was successful',
        'set status [get_property STATUS [get_runs impl_1]]',
        'if {$status ne "write_bitstream Complete!"} {',
        '    puts $status',
        '    puts "Error: Implementation failed"',
        '    exit 1',
        '}',
        "",
        "close_project",
        "exit",
    ]
    tcl_path = os.path.join(SCRIPT_DIR, rel)
    with open(tcl_path, "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    info(f"Generated {rel} for kernel {BOLD}{PROJECT_NAME}{RESET}")


# ── Targets ──────────────────────────────────────────────────────────────────


def target_help():
    kernel_list = ", ".join(KERNELS.keys())
    print(f"""
{BOLD}{CYAN}FPGA HLS Build System{RESET}  (kernel: {BOLD}{PROJECT_NAME}{RESET})

{BOLD}{YELLOW}Available kernels{RESET}: {kernel_list}
  Use {GREEN}--kernel <name>{RESET} to select (default: dense_solve)

{BOLD}{YELLOW}VITIS HLS targets{RESET}

  {GREEN}hls_project{RESET}    : Just creates the Vitis HLS project
  {GREEN}hls_sim{RESET}        : Creates the Vitis HLS project and runs the C++ simulation
  {GREEN}hls_cosim{RESET}      : Runs C/RTL co-simulation (csynth + cosim_design); reports actual cycle counts
  {GREEN}ip{RESET}             : Creates the Vitis HLS project, synthesizes the design and exports the IP core

{BOLD}{YELLOW}VIVADO targets{RESET}

  {GREEN}vivado_project{RESET}    : Just creates the Vivado project
  {GREEN}bitstream{RESET}         : Creates the Vivado project and runs synthesis up to bitstream generation
  {GREEN}extract_bitstream{RESET} : If the Vivado bitstream has already been generated, extracts it to build/bitstream/

{BOLD}{YELLOW}Full pipeline{RESET}

  {GREEN}all{RESET}              : Full clean build: HLS synthesis -> Vivado project -> bitstream

{BOLD}{YELLOW}Generic targets{RESET}

  {GREEN}clean{RESET}    : Deletes log files and Vitis HLS and Vivado projects. Keeps the IP catalog ZIP file
  {GREEN}cleanall{RESET} : Additionally, deletes the entire build/ directory
  {GREEN}help{RESET}     : Shows this help message
""")


def refresh_ip_repo():
    """Re-extract the HLS IP zip into build/ip_repo/<PROJECT_NAME>/, running HLS
    first if missing.

    Each variant's IP must extract into its own subdirectory so concurrent
    variant builds don't clobber each other's component.xml — Vivado scans the
    ip_repo_paths root recursively, so per-variant subdirs are discovered
    transparently.

    Also wipes the Vivado project's IP cache when present: with `-ipname`,
    each variant has a unique VLNV, but Vivado still serves stale RTL from
    .cache/ip/ if a previous build of the same VLNV is cached there.
    """
    zip_path = os.path.join(BUILD_DIR, "ip_repo", f"{PROJECT_NAME}.zip")
    if not os.path.isfile(zip_path):
        warn("IP zip not found, running HLS synthesis first...")
        target_ip()
    ip_repo_dir = os.path.join(BUILD_DIR, "ip_repo", PROJECT_NAME)
    if os.path.isdir(ip_repo_dir):
        shutil.rmtree(ip_repo_dir, ignore_errors=True)
    os.makedirs(ip_repo_dir, exist_ok=True)
    info(f"Unzipping {os.path.relpath(zip_path, SCRIPT_DIR)} into build/ip_repo/{PROJECT_NAME}/")
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(ip_repo_dir)

    vivado_ip_cache = os.path.join(
        BUILD_DIR, f"{PROJECT_NAME}_Vivado",
        f"{PROJECT_NAME}_Vivado.cache", "ip",
    )
    if os.path.isdir(vivado_ip_cache):
        info(f"Clearing Vivado IP cache at {os.path.relpath(vivado_ip_cache, SCRIPT_DIR)}")
        shutil.rmtree(vivado_ip_cache, ignore_errors=True)


def target_ip():
    """HLS synthesis + IP export."""
    ensure_build_dirs()
    if CLEAN_BEFORE_BUILD:
        rmrf(f"{PROJECT_NAME}_HLS")
    elif os.path.isdir(os.path.join(SCRIPT_DIR, f"{PROJECT_NAME}_HLS")):
        info(f"Reusing existing {PROJECT_NAME}_HLS/ (use --clean to wipe)")
    generate_hls_project_tcl()
    generate_hls_synth_tcl()
    run(f"vitis-run --mode hls --tcl {_hls_synth_tcl_rel()}")
    cleanup_logs()


def target_hls_project():
    """Just create the HLS project."""
    ensure_build_dirs()
    if CLEAN_BEFORE_BUILD:
        rmrf(f"{PROJECT_NAME}_HLS")
    elif os.path.isdir(os.path.join(SCRIPT_DIR, f"{PROJECT_NAME}_HLS")):
        info(f"Reusing existing {PROJECT_NAME}_HLS/ (use --clean to wipe)")
    generate_hls_project_tcl()
    run(f"vitis-run --mode hls --tcl {_hls_project_tcl_rel()}")
    cleanup_logs()


def target_hls_sim():
    """Create HLS project and run C++ simulation."""
    ensure_build_dirs()
    if CLEAN_BEFORE_BUILD:
        rmrf(f"{PROJECT_NAME}_HLS")
    elif os.path.isdir(os.path.join(SCRIPT_DIR, f"{PROJECT_NAME}_HLS")):
        info(f"Reusing existing {PROJECT_NAME}_HLS/ (use --clean to wipe)")
    generate_hls_project_tcl()
    generate_hls_sim_tcl()
    run(f"vitis-run --mode hls --tcl {_hls_sim_tcl_rel()}")
    cleanup_logs()


def target_hls_cosim():
    """C/RTL co-simulation. Always wipes the HLS project so the testbench is
    re-compiled with -DCOSIM_PROFILE (small fixture subset). Without this guard
    cosim would run all 19 fixtures and take many hours."""
    ensure_build_dirs()
    rmrf(f"{PROJECT_NAME}_HLS")
    generate_hls_project_tcl(extra_tb_cflags="-DCOSIM_PROFILE")
    generate_hls_cosim_tcl()
    run(f"vitis-run --mode hls --tcl {_hls_cosim_tcl_rel()}")
    cleanup_logs()


def target_vivado_project():
    """Create the Vivado project (runs IP target first if needed)."""
    ensure_build_dirs()
    vivado_dir = os.path.join(BUILD_DIR, f"{PROJECT_NAME}_Vivado")

    if CLEAN_BEFORE_BUILD:
        rmrf(f"build/{PROJECT_NAME}_Vivado")

    refresh_ip_repo()

    if os.path.isdir(vivado_dir):
        info(f"Reusing existing build/{PROJECT_NAME}_Vivado/ (use --clean to wipe)")
        return

    ila_arg = " --ila" if USE_ILA else ""
    clk_freq = KERNEL_CFG.get("clk_freq_mhz", 150)
    run(f"vivado -mode batch -source tcl/vivado_project.tcl -tclargs --project_name {PROJECT_NAME}_Vivado --clk_freq {clk_freq}{ila_arg}")
    cleanup_logs()


def target_bitstream():
    """Full flow: IP → Vivado project → synthesis → bitstream."""
    vivado_dir = os.path.join(BUILD_DIR, f"{PROJECT_NAME}_Vivado")
    if CLEAN_BEFORE_BUILD or not os.path.isdir(vivado_dir):
        target_vivado_project()
    else:
        # Project is being reused — still re-extract IP so update_ip_catalog
        # in vivado_impl.tcl picks up any fresh RTL.
        refresh_ip_repo()

    generate_vivado_impl_tcl()
    run(f"vivado -mode batch -source {_vivado_impl_tcl_rel()}")
    target_extract_bitstream()
    cleanup_logs()


def target_extract_bitstream():
    """Copy bitstream outputs to build/bitstream/. .ltx is optional (only emitted
    when system_ila debug cores are present)."""
    bitstream_dir = os.path.join(BUILD_DIR, "bitstream")
    os.makedirs(bitstream_dir, exist_ok=True)
    required_copies = [
        (f"build/{PROJECT_NAME}_Vivado/{PROJECT_NAME}_Vivado.runs/impl_1/design_1_wrapper.bit", f"build/bitstream/{PROJECT_NAME}.bit"),
        (f"build/{PROJECT_NAME}_Vivado/{PROJECT_NAME}_Vivado.gen/sources_1/bd/design_1/hw_handoff/design_1.hwh", f"build/bitstream/{PROJECT_NAME}.hwh"),
    ]
    optional_copies = [
        (f"build/{PROJECT_NAME}_Vivado/{PROJECT_NAME}_Vivado.runs/impl_1/design_1_wrapper.ltx", f"build/bitstream/{PROJECT_NAME}.ltx"),
    ]
    for src, dst in required_copies:
        src_full = os.path.join(SCRIPT_DIR, src)
        dst_full = os.path.join(SCRIPT_DIR, dst)
        info(f"cp {src} -> {BOLD}{dst}{RESET}")
        shutil.copy2(src_full, dst_full)
    # Stale .ltx from a prior --ila build would mismatch the current bitstream;
    # remove it when the new build didn't produce one.
    for src, dst in optional_copies:
        src_full = os.path.join(SCRIPT_DIR, src)
        dst_full = os.path.join(SCRIPT_DIR, dst)
        if os.path.isfile(src_full):
            info(f"cp {src} -> {BOLD}{dst}{RESET}")
            shutil.copy2(src_full, dst_full)
        else:
            info(f"(skip) {src} not produced (no ILAs in design)")
            if os.path.isfile(dst_full):
                os.remove(dst_full)


def target_clean():
    """Delete build artifacts for the current variant; keep its IP zip."""
    cleanup_logs()
    rmrf(f"{PROJECT_NAME}_HLS", f"build/{PROJECT_NAME}_Vivado")
    # Per-variant extracted IP dir; other variants under build/ip_repo/<other>/ stay intact.
    rmrf(f"build/ip_repo/{PROJECT_NAME}")
    # Legacy top-level extraction (pre per-variant-subdir refactor); clean so it doesn't shadow the new layout.
    rmrf("build/ip_repo/component.xml")
    rmrf("build/ip_repo/constraints", "build/ip_repo/doc", "build/ip_repo/drivers",
         "build/ip_repo/hdl", "build/ip_repo/misc", "build/ip_repo/xgui")


def target_cleanall():
    """Delete everything including the entire build directory."""
    target_clean()
    rmrf("build")


def target_all():
    """Clean build from scratch: HLS synthesis → Vivado project → bitstream."""
    info("Running full build pipeline: HLS → Vivado → bitstream")
    target_ip()
    target_vivado_project()
    target_bitstream()
    success("Full build complete! Outputs in build/bitstream/")


# ── CLI ──────────────────────────────────────────────────────────────────────

TARGETS = {
    "help": target_help,
    "all": target_all,
    "ip": target_ip,
    "hls_project": target_hls_project,
    "hls_sim": target_hls_sim,
    "hls_cosim": target_hls_cosim,
    "vivado_project": target_vivado_project,
    "bitstream": target_bitstream,
    "extract_bitstream": target_extract_bitstream,
    "clean": target_clean,
    "cleanall": target_cleanall,
}

def variant_suffix(kernel, q_int, q_frac, use_gaussian, unroll=None):
    """Compute the project-name suffix encoding the build variant.

    Layout:
      Sparse: "_Q{int}_{frac}[_U{n}]"
      Dense:  "_Q{int}_{frac}[_U{n}]_{Ch|Ga}"
    Underscore between int and frac (not dot) because Vivado block-design cell
    names disallow dots. Kept identical to the suffix in synth.sh / deploy.sh
    so artefacts line up.
    """
    suffix = f"_Q{q_int}_{q_frac}"
    if unroll is not None:
        suffix += f"_U{unroll}"
    if kernel == "dense_solve":
        suffix += "_Ga" if use_gaussian else "_Ch"
    return suffix


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FPGA HLS kernel build script")
    parser.add_argument("target", nargs="?", default="help", choices=TARGETS.keys(),
                        help="Build target (default: help)")
    parser.add_argument("--kernel", default="dense_solve", choices=KERNELS.keys(),
                        help="Kernel to build (default: dense_solve)")
    parser.add_argument("--jobs", "-j", type=int, default=32,
                        help="Number of parallel jobs for Vivado (default: 32)")
    parser.add_argument("--clean", action="store_true",
                        help="Wipe HLS / Vivado projects before building (default: reuse if present)")
    parser.add_argument("--ila", action="store_true",
                        help="Add system_ila debug cores (master1 + AXI-Lite). Default off; "
                             "needs --clean if Vivado project already exists.")
    parser.add_argument("--q-int", type=int, default=31,
                        help="Fixed-point integer bits Q_INT_BITS (default: 31, baseline Q31.40)")
    parser.add_argument("--q-frac", type=int, default=40,
                        help="Fixed-point fractional bits Q_FRAC_BITS (default: 40, baseline Q31.40). "
                             "Total TFXP width = 1 + q-int + q-frac and must satisfy 2..128.")
    parser.add_argument("--use-gaussian", action="store_true",
                        help="Dense kernel only: build the Gaussian-HW variant instead of Cholesky-HW.")
    parser.add_argument("--unroll", type=int, default=None,
                        help="Override the HLS unrolling factor (sparse: SPARSE_UNROLL, "
                             "dense: K_BUILDING_UNROLLING_FACTOR). Default: kernel-baked value.")
    args = parser.parse_args()

    if args.q_int < 1 or args.q_frac < 1:
        error(f"Invalid Q-format: q-int({args.q_int}) and q-frac({args.q_frac}) "
              f"must both be >= 1.")
        sys.exit(2)
    tfxp_width = 1 + args.q_int + args.q_frac
    if tfxp_width > 128:
        error(f"Invalid Q-format: total TFXP width 1+{args.q_int}+{args.q_frac} = "
              f"{tfxp_width} exceeds 128-bit host limit (__int128).")
        sys.exit(2)

    KERNEL_CFG = KERNELS[args.kernel]
    suffix = variant_suffix(args.kernel, args.q_int, args.q_frac, args.use_gaussian, args.unroll)
    KERNEL_CFG["project_name"] = KERNEL_CFG["project_name"] + suffix
    PROJECT_NAME = KERNEL_CFG["project_name"]
    NUM_JOBS = args.jobs
    CLEAN_BEFORE_BUILD = args.clean
    USE_ILA = args.ila
    Q_INT_BITS = args.q_int
    Q_FRAC_BITS = args.q_frac
    USE_GAUSSIAN = args.use_gaussian
    UNROLL = args.unroll

    defines = [f"-DQ_INT_BITS={Q_INT_BITS}", f"-DQ_FRAC_BITS={Q_FRAC_BITS}"]
    if args.kernel == "dense_solve" and USE_GAUSSIAN:
        defines.append("-DUSE_GAUSSIAN")
    if UNROLL is not None:
        unroll_macro = ("SPARSE_UNROLL" if args.kernel == "sparse_solve"
                        else "K_BUILDING_UNROLLING_FACTOR")
        defines.append(f"-D{unroll_macro}={UNROLL}")
    VARIANT_DEFINES = " ".join(defines)

    info(f"Build variant: kernel={args.kernel} project={PROJECT_NAME} "
         f"Q{Q_INT_BITS}.{Q_FRAC_BITS}"
         + (f" U={UNROLL}" if UNROLL is not None else "")
         + (" Gaussian" if args.kernel == "dense_solve" and USE_GAUSSIAN
            else (" Cholesky" if args.kernel == "dense_solve" else "")))

    TARGETS[args.target]()
