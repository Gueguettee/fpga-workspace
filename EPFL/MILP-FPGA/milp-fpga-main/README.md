# milp-fpga

FPGA acceleration for urban digital-twin energy models: solving Mixed-Integer Linear
Programs (MILP) on an FPGA for energy efficiency.

This repository targets the **ZCU104** development board (`xczu7ev-ffvc1156-2-e`) and is built
with **Vitis HLS / Vivado 2025.2**. It contains two HLS C++ kernels that solve the dense linear
systems at the heart of an interior-point / branch-and-bound MILP solver, the on-board C software
that drives them, and Python reference solvers used to validate and benchmark the hardware.

## What it does

The solver follows a classic MILP pipeline: an **interior-point method (IPM)** solves the LP
relaxations, and **branch-and-bound** drives the integer search on top of it. The expensive inner
step — repeatedly solving a symmetric linear system — is offloaded to the FPGA. Two kernels cover
the two regimes:

- **`dense_solve` (`DenseSolve`)** — solves a dense system `A x = b` on-chip via Cholesky (default)
  or Gaussian elimination. Used by the LP-IPM and the MILP branch-and-bound bench.
- **`sparse_solve` (`SparseSolve`)** — sparse symbolic/numeric factorization plus triangular solves,
  for larger systems that don't fit the dense path.

All arithmetic is **fixed-point** (`TFXP`), so the kernels avoid floating-point resources on the
fabric.

## Repository layout

```text
milp-fpga/
├── hw/            HLS kernels, build orchestrator, TCL, generated artefacts
├── sw/            On-board C drivers + testbenches (the LP/MILP solver)
├── shared/        Fixed-point type definitions shared by HLS and host code
├── python/        Reference solvers, fixture generation, case studies
├── data/          Measurements (CSV/TXT), archives, sweeps, figures
├── docs/          Project description + final report
├── synth.sh       Remote synthesis driver (EPFL server)
├── deploy.sh      Board deployment + test driver (ZCU104)
└── setup.sh       One-time board provisioning (static IP, packages)
```

### `hw/` — hardware

- **`hw/kernels/`** — the synthesizable C++:
  - `dense_solve/` — `src/` (`dense_solve`, `gaussian_solve`, `cholesky_solve`) + `tb/`.
  - `sparse_solve/` — `src/` (`sparse_solve`, `sparse_kform`, `sparse_factor`,
    `sparse_triangular_solve`) + `tb/`.
  - `common/` — shared testbench helpers (`tb_utils.h`).
- **`hw/build.py`** — the master orchestrator and the `KERNELS` registry (top function, source list,
  testbench, clock). Both `synth.sh` and the TCL scripts call into it.
- **`hw/tcl/`** — per-kernel HLS and Vivado TCL scripts.

### `sw/` — on-board software

C drivers and testbenches built and run on the ZCU104. Four Makefiles select what to build:
`Makefile.dense_solve`, `Makefile.sparse_solve`, `Makefile.lp_ipm_sparse`, and `Makefile.milp_bnb`. Code lives in `drivers/`, `include/`, `src/`.

### `shared/` — fixed-point types

`fxp_utils.h` and `constants.h` define `TFXP`, the project-wide fixed-point type.

### `python/` — reference solvers & case studies

- `sparse_solve/` — fixture generation (`generate_fixtures.py`) and the numeric/symbolic reference
  used to validate the sparse kernel.
- `case_study_FEN/` — FEN benchmark and sparsity analysis (Gurobi / HiGHS).
- `eth_zurich_FEN/toy_model_FEN/` — a reference LP/MILP model with input matrices from the FEN project from ETH Zurich ([https://www.fen.ethz.ch/](https://www.fen.ethz.ch/)).
- `eth_zurich_FEN/UC_example_UrbanTwin/` — a unit-commitment case study also from the FEN project.

## Prerequisites

- **WSL** or **Linux** to run `synth.sh` / `deploy.sh`.
- **SSH access to the EPFL server** for synthesis (the server hosts Vivado/Vitis 2025.2).
- **SSH access to the ZCU104 board** for deployment. First-time boards are provisioned once with
  `setup.sh` (copy it to the board and run `sudo ./setup.sh` to set a static IP and install packages).

## Quick start

The typical end-to-end flow:

```bash
# 1. C simulation of a kernel (fast sanity check, runs the testbench on the server)
./synth.sh hls_sim --kernel dense_solve        # or --kernel sparse_solve

# 2. Full synthesis from scratch: HLS → Vivado → bitstream, then fetch results
./synth.sh --clean --kernel dense_solve
./synth.sh logs                                # follow the live build log
./synth.sh fetch                               # pull bitstream + reports back

# 3. Deploy to the board, program the FPGA, and run the testbench
./deploy.sh all --kernel dense_solve
```

`--kernel` defaults to `dense_solve`.

## Command reference (most-used)

### `synth.sh` — runs on the EPFL server

`synth.sh [target] [--clean] [--kernel <name>]`

| Target | Does |
| --- | --- |
| `all` *(default)* | Full pipeline: HLS → Vivado → bitstream |
| `ip` | HLS C-synthesis + IP export |
| `hls_sim` | HLS C++ simulation (csim) |
| `status` / `logs` | Check / follow a running background synth |
| `fetch` | Pull bitstream + HLS project + reports back to `hw/build/` |
| `report` | Print a utilization & timing summary |
| `clean` / `cleanall` | Wipe remote artefacts (`cleanall` also wipes local `hw/build/`) |

### `deploy.sh` — runs on the board

`deploy.sh [host] <target> [--kernel <name>]` (host defaults to `172.22.22.70`)

| Target | Does |
| --- | --- |
| `all` | Sync + build + program + test, then fetch reports & archive the run |
| `sync` | Sync source to the board only |
| `test_dense_solve` / `test_sparse_solve` / `test_milp_bnb` / `test_lp_ipm_sparse` | Run one testbench |
| `connect` | Open an SSH shell on the board |

Run `./synth.sh help` for the complete target list.

### `generate_fixtures.py` — sparse-kernel test fixtures

Regenerates the `.bin` fixtures consumed by the `sparse_solve` testbench and the
`lp_ipm_sparse` bench.:

```bash
# Synthetic random/banded systems -> trisolve + factor + kform fixtures
python -m python.sparse_solve.generate_fixtures synthetic

# Same cases wrapped as end-to-end IPM problems (ipm_*.bin)
python -m python.sparse_solve.generate_fixtures synthetic --ipm

# Real unit-commitment LPs (needs gurobipy) -> kform_uc / ipm_uc fixtures
python -m python.sparse_solve.generate_fixtures uc
python -m python.sparse_solve.generate_fixtures uc --ipm
```

Fixtures land in `hw/kernels/sparse_solve/tb/fixtures/` by default (`--out-dir` to override).
`--decimals` sets the Q-format fraction width and must match the kernel build's `Q_FRAC_BITS`
(default 40, the Q31.40 baseline).
