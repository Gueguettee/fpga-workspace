"""Generate sparse_solve test fixtures: synthetic, uc, and paired subcommands."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import numpy as np
import scipy.linalg as la
import scipy.sparse as sp

from .utilities.symbolic import prepare_sparse_problem
from .utilities.numeric_reference import (
    factor_only,
    solve_only,
    compute_K_values,
)
from .utilities.fixture_format import (
    set_decimals,
    write_trisolve_fixture,
    write_factor_fixture,
    write_kform_fixture,
    write_ipm_fixture,
)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))


def default_fixtures_dir() -> str:
    return os.path.normpath(os.path.join(
        HERE, "..", "..", "hw", "kernels", "sparse_solve", "tb", "fixtures"))


D_LO, D_HI = 0.125, 0.625
B_SCALE = 0.5


def _factor_and_solve(sym, D, b):
    K_values = compute_K_values(sym, D)
    L_values_csc, Dv = factor_only(sym, K_values)
    b_perm = b[sym.P]
    dy_perm = solve_only(sym, L_values_csc, Dv, b_perm)
    return K_values, L_values_csc, Dv, b_perm, dy_perm


# ───────────────────────── synthetic ─────────────────────────

A_SCALE = 0.25

# Keep in sync with shared/constants.h SPARSE_MAX_{M,N} and SPARSE_MAX_NNZ_{A,K,L}.
SPARSE_MAX_M = 8192
SPARSE_MAX_N = 8192
SPARSE_MAX_NNZ = 65536


def _random_sparse_A(m: int, n: int, density: float, rng: np.random.Generator) -> sp.csr_matrix:
    A = sp.random(m, n, density=density, format="csr", random_state=rng,
                  data_rvs=lambda size: rng.uniform(-1.0, 1.0, size=size) * A_SCALE)
    A = A.tocsr()
    for i in range(m):
        if A.indptr[i] == A.indptr[i + 1]:
            j = int(rng.integers(0, n))
            row = sp.csr_matrix(([rng.uniform(-1.0, 1.0) * A_SCALE], ([0], [j])),
                                shape=(1, n))
            top = A[:i] if i > 0 else sp.csr_matrix((0, n))
            bot = A[i + 1:] if i + 1 < m else sp.csr_matrix((0, n))
            A = sp.vstack([top, row, bot]).tocsr()
    A.sort_indices()
    return A


def _banded_sparse_A(m: int, n: int, bw: int, rng: np.random.Generator) -> sp.csr_matrix:
    DIAG_MAG = 1.0
    OFF_MAG = 0.05
    rows, cols, vals = [], [], []
    for i in range(m):
        center = int(round(i * n / max(m, 1)))
        for off in range(-bw, bw + 1):
            j = center + off
            if 0 <= j < n:
                if off == 0:
                    sign = 1.0 if rng.uniform() > 0.5 else -1.0
                    val = sign * rng.uniform(0.5, 1.0) * DIAG_MAG
                else:
                    val = rng.uniform(-1.0, 1.0) * OFF_MAG
                rows.append(i)
                cols.append(j)
                vals.append(val)
    A = sp.csr_matrix((vals, (rows, cols)), shape=(m, n))
    A.sort_indices()
    return A


def _build_A(m: int, n: int, density: float, banded_bw, rng: np.random.Generator):
    if banded_bw is not None:
        return _banded_sparse_A(m, n, banded_bw, rng), f"bw={banded_bw:>2d}"
    return _random_sparse_A(m, n, density, rng), f"dens={density:.3f}"


def _solve_synthetic_case(m, n, density, seed, banded_bw):
    rng = np.random.default_rng(seed)
    A, kind = _build_A(m, n, density, banded_bw, rng)
    D = rng.uniform(D_LO, D_HI, size=n)
    b = rng.uniform(-1.0, 1.0, size=m) * B_SCALE
    sym = prepare_sparse_problem(A, use_rcm=True)
    K_values, L_values_csc, Dv, b_perm, dy_perm = _factor_and_solve(sym, D, b)
    return dict(m=m, n=n, kind=kind, sym=sym, D=D, K_values=K_values,
                L_values_csc=L_values_csc, Dv=Dv, b_perm=b_perm, dy_perm=dy_perm)


def _synthetic_cases():
    return [
        ("dense_4",     4,    4,    1.00,   1001, None),
        ("dense_8",     8,    8,    1.00,   1002, None),
        ("dense_16",    16,   16,   1.00,   1003, None),
        ("dense_32",    32,   32,   1.00,   1004, None),
        ("dense_64",    64,   64,   1.00,   1005, None),
        ("dense_128",   128,  128,  1.00,   1006, None),
        ("dense_256",   256,  256,  1.00,   1007, None),
        # Sparse family (random A, heavy Cholesky fill, so nnz(L)/m climbs with
        # size). The 32/64/128 cases use ~13 non-zeros per row (density = 13/n),
        # reproducing the historical sparse_64/128 fill; sparse_256 keeps its
        # original lower density. Re-measure on the board for comparable numbers.
        ("sparse_32",   32,   64,   0.20,   1102, None),
        ("sparse_64",   64,   128,  0.10,   1103, None),
        ("sparse_128",  128,  256,  0.05,   1104, None),
        ("sparse_256",  256,  512,  0.015,  1101, None),
        ("banded_512",  512,  512,  0.0,    2001, 3),
        ("banded_1024", 1024, 1024, 0.0,    2002, 3),
        ("banded_1848", 1848, 1848, 0.0,    2003, 3),
        ("banded_4096", 4096, 4096, 0.0,    2004, 3),
    ]


def dump_synthetic_ipm(out_dir: str):
    """Write end-to-end IPM (SPLI) fixtures for the synthetic cases, loadable by
    lp_ipm_sparse_bench. Each case's A (random / banded / dense) is wrapped into a
    feasible LP (x=1 feasible via b = A 1, positive cost c). D is set per-iteration
    by the IPM driver, so it is not stored."""
    os.makedirs(out_dir, exist_ok=True)
    print("=== synthetic IPM fixtures (SPLI, for lp_ipm_sparse_bench) ===")
    for name, m, n, dens, seed, bw in _synthetic_cases():
        rng = np.random.default_rng(seed)
        A, kind = _build_A(m, n, dens, bw, rng)
        sym = prepare_sparse_problem(A, use_rcm=True)
        nnz_A = int(sym.A_indptr[-1]); nnz_K = int(sym.K_colptr[-1]); nnz_L = int(sym.L_colptr[-1])
        if (m > SPARSE_MAX_M or n > SPARSE_MAX_N or nnz_A > SPARSE_MAX_NNZ
                or nnz_K > SPARSE_MAX_NNZ or nnz_L > SPARSE_MAX_NNZ):
            print(f"  [{name}] m={m} nnz_A={nnz_A} nnz_K={nnz_K} nnz_L={nnz_L}  "
                  f"SKIP: exceeds SPARSE_MAX_* ceiling")
            continue
        b = np.asarray(A @ np.ones(n), dtype=np.float64).ravel()   # x=1 feasible
        b_perm = b[sym.P]
        c = rng.uniform(0.5, 5.5, size=n)
        c_max = float(np.max(np.abs(c)))
        c = c * (C_SCALE / c_max) if c_max > 0 else np.ones(n, dtype=np.float64) * C_SCALE
        write_ipm_fixture(
            os.path.join(out_dir, f"ipm_{name}.bin"), m=m, n=n,
            A_indptr=sym.A_indptr, A_indices=sym.A_indices, A_values=sym.A_values,
            K_colptr=sym.K_colptr, K_rowidx=sym.K_rowidx,
            L_colptr=sym.L_colptr, L_rowidx_csc=sym.L_rowidx_csc,
            L_rowptr=sym.L_rowptr, L_colidx_csr=sym.L_colidx_csr,
            L_csc_pos=sym.L_csc_pos, L_csr_pos=sym.L_csr_pos,
            b=b_perm, c=c,
        )
        print(f"  wrote ipm_{name}.bin  m={m:5d} n={n:5d} {kind}  "
              f"nnz_K={nnz_K:6d} nnz_L={nnz_L:6d}")
    print(f"\nWrote IPM fixtures to {out_dir}")


def cmd_synthetic(args):
    out_dir = args.out_dir
    os.makedirs(out_dir, exist_ok=True)
    if getattr(args, "ipm", False):
        dump_synthetic_ipm(out_dir)
        return
    solved = []
    for name, m, n, dens, seed, bw in _synthetic_cases():
        r = _solve_synthetic_case(m, n, dens, seed, bw)
        sym = r["sym"]
        nnz_A = int(sym.A_indptr[-1])
        nnz_K = int(sym.K_colptr[-1])
        nnz_L = int(sym.L_colptr[-1])
        if (m > SPARSE_MAX_M or n > SPARSE_MAX_N or nnz_A > SPARSE_MAX_NNZ
                or nnz_K > SPARSE_MAX_NNZ or nnz_L > SPARSE_MAX_NNZ):
            print(f"  [{name}] m={m} n={n} nnz_A={nnz_A} nnz_K={nnz_K} "
                  f"nnz_L={nnz_L}  SKIP: exceeds SPARSE_MAX_* ceiling")
            continue
        solved.append((name, r))

    print("=== trisolve fixtures (M2) ===")
    for name, r in solved:
        sym = r["sym"]
        write_trisolve_fixture(
            os.path.join(out_dir, f"trisolve_{name}.bin"), m=r["m"],
            L_colptr=sym.L_colptr.astype(np.uint32),
            L_rowidx_csc=sym.L_rowidx_csc.astype(np.uint16),
            L_values_csc=r["L_values_csc"], Dv=r["Dv"],
            b=r["b_perm"], dy_expected=r["dy_perm"],
        )
        print(f"  wrote trisolve_{name}.bin  m={r['m']} n={r['n']} {r['kind']} "
              f"nnz_L={int(sym.L_colptr[-1])}")

    print("\n=== factor fixtures (M3) ===")
    for name, r in solved:
        sym = r["sym"]
        write_factor_fixture(
            os.path.join(out_dir, f"factor_{name}.bin"), m=r["m"],
            K_colptr=sym.K_colptr.astype(np.uint32),
            K_rowidx=sym.K_rowidx.astype(np.uint16),
            K_values=r["K_values"],
            L_colptr=sym.L_colptr.astype(np.uint32),
            L_rowidx_csc=sym.L_rowidx_csc.astype(np.uint16),
            L_rowptr=sym.L_rowptr.astype(np.uint32),
            L_colidx_csr=sym.L_colidx_csr.astype(np.uint16),
            L_csc_pos=sym.L_csc_pos.astype(np.uint32),
            b=r["b_perm"], dy_expected=r["dy_perm"],
            L_values_csc_expected=r["L_values_csc"], Dv_expected=r["Dv"],
        )
        print(f"  wrote factor_{name}.bin  m={r['m']} n={r['n']} {r['kind']} "
              f"nnz_K={int(sym.K_colptr[-1])} nnz_L={int(sym.L_colptr[-1])}")

    print("\n=== kform fixtures (M4/M5) ===")
    for name, r in solved:
        sym = r["sym"]
        write_kform_fixture(
            os.path.join(out_dir, f"kform_{name}.bin"), m=r["m"], n=r["n"],
            A_indptr=sym.A_indptr, A_indices=sym.A_indices, A_values=sym.A_values,
            D=r["D"],
            K_colptr=sym.K_colptr, K_rowidx=sym.K_rowidx,
            L_colptr=sym.L_colptr, L_rowidx_csc=sym.L_rowidx_csc,
            L_rowptr=sym.L_rowptr, L_colidx_csr=sym.L_colidx_csr,
            L_csc_pos=sym.L_csc_pos, L_csr_pos=sym.L_csr_pos,
            b=r["b_perm"], dy_expected=r["dy_perm"],
            K_values_expected=r["K_values"],
        )
        print(f"  wrote kform_{name}.bin  m={r['m']} n={r['n']} {r['kind']} "
              f"nnz_A={int(sym.A_indptr[-1])} nnz_K={int(sym.K_colptr[-1])} "
              f"nnz_L={int(sym.L_colptr[-1])}")

    print(f"\nWrote fixtures to {out_dir}")


# ───────────────────────────── uc ─────────────────────────────

A_SCALE_UC = 1.0 / 256.0
C_SCALE = 1.0
MAX_DY_INF = 100.0

PHASE1_MAX_M = 16384
PHASE1_MAX_N = 16384
PHASE1_MAX_NNZ_A = 65536
PHASE1_MAX_NNZ_K = 80000
PHASE1_MAX_NNZ_L = 1100000


def extract_lp_A(model) -> sp.csr_matrix:
    model.update()
    return sp.csr_matrix(model.getA())


def extract_lp_bc(model) -> tuple[np.ndarray, np.ndarray]:
    model.update()
    constrs = model.getConstrs()
    variables = model.getVars()
    b = np.array([cnstr.RHS for cnstr in constrs], dtype=np.float64)
    c = np.array([v.Obj for v in variables], dtype=np.float64)
    return b, c


def filter_to_full_row_rank(A: sp.csr_matrix, tol: float = 1e-3) -> sp.csr_matrix:
    m, n = A.shape
    DENSE_QR_LIMIT_BYTES = 3 * 1024 * 1024 * 1024
    if 2 * n * m * 8 > DENSE_QR_LIMIT_BYTES:
        return _filter_to_full_row_rank_random(A, tol=tol)

    A_dense = np.asarray(A.todense())
    _Q, R, P = la.qr(A_dense.T, pivoting=True, mode="economic")
    diag_R = np.abs(np.diag(R))
    if diag_R.size == 0 or diag_R[0] == 0.0:
        return A[:0, :]
    rank = int(np.sum(diag_R > tol * diag_R[0]))
    keep = np.sort(P[:rank])
    return A[keep, :].tocsr()


def _filter_to_full_row_rank_random(A: sp.csr_matrix,
                                    tol: float = 1e-3,
                                    k: int | None = None,
                                    seed: int = 12345) -> sp.csr_matrix:
    m, n = A.shape
    if k is None:
        k = min(n, int(0.4 * m) + 256)
    rng = np.random.default_rng(seed)
    G = rng.standard_normal((n, k))
    AG = (A @ G).astype(np.float64)
    _Q, R, P = la.qr(AG.T, pivoting=True, mode="economic")
    diag_R = np.abs(np.diag(R))
    if diag_R.size == 0 or diag_R[0] == 0.0:
        return A[:0, :]
    rank = int(np.sum(diag_R > tol * diag_R[0]))
    keep = np.sort(P[:rank])
    return A[keep, :].tocsr()


def _build_uc_A_bc(cfg: dict) -> tuple[sp.csr_matrix, np.ndarray, np.ndarray]:
    data = build_synthetic_data(cfg)
    model = build_uc_model(data)
    model.setParam("OutputFlag", 0)
    try:
        A = extract_lp_A(model)
        b, c = extract_lp_bc(model)
    finally:
        model.dispose()
    nnz_per_row = np.diff(A.indptr)
    keep = np.where(nnz_per_row > 0)[0]
    return A[keep, :].tocsr(), b[keep], c


def dump_uc_kform_fixture(label: str, cfg: dict, out_dir: str, seed: int) -> bool:
    cfg = dict(cfg)
    cfg["solver_log"] = False
    cfg["time_limit"] = 1
    A, _b, _c = _build_uc_A_bc(cfg)
    A = filter_to_full_row_rank(A)
    A.data = A.data * A_SCALE_UC
    m, n = A.shape

    if m > PHASE1_MAX_M or n > PHASE1_MAX_N:
        print(f"  [{label}] m={m} n={n}  SKIP: exceeds m/n ceiling")
        return False

    sym = prepare_sparse_problem(A, use_rcm=True)
    nnz_A = int(sym.A_indptr[-1])
    nnz_K = int(sym.K_colptr[-1])
    nnz_L = int(sym.L_colptr[-1])

    if nnz_A > PHASE1_MAX_NNZ_A or nnz_K > PHASE1_MAX_NNZ_K or nnz_L > PHASE1_MAX_NNZ_L:
        print(f"  [{label}] m={m:5d} nnz_A={nnz_A:6d} nnz_K={nnz_K:6d} "
              f"nnz_L={nnz_L:6d}  SKIP: exceeds nnz ceiling")
        return False

    rng = np.random.default_rng(seed)
    D = rng.uniform(D_LO, D_HI, size=n)
    b = rng.uniform(-1.0, 1.0, size=m) * B_SCALE

    K_values, L_values_csc, Dv, b_perm, dy_perm = _factor_and_solve(sym, D, b)
    dy_inf = float(np.max(np.abs(dy_perm)))

    if dy_inf > MAX_DY_INF:
        scale = MAX_DY_INF / dy_inf
        b *= scale
        b_perm = b[sym.P]
        dy_perm = dy_perm * scale
        dy_inf *= scale

    out_path = os.path.join(out_dir, f"kform_uc_{label}.bin")
    write_kform_fixture(
        out_path, m=m, n=n,
        A_indptr=sym.A_indptr, A_indices=sym.A_indices, A_values=sym.A_values,
        D=D,
        K_colptr=sym.K_colptr, K_rowidx=sym.K_rowidx,
        L_colptr=sym.L_colptr, L_rowidx_csc=sym.L_rowidx_csc,
        L_rowptr=sym.L_rowptr, L_colidx_csr=sym.L_colidx_csr,
        L_csc_pos=sym.L_csc_pos, L_csr_pos=sym.L_csr_pos,
        b=b_perm,
        dy_expected=dy_perm,
        K_values_expected=K_values,
    )
    min_dv = float(np.min(Dv))
    print(f"  [{label}] m={m:5d} nnz_A={nnz_A:6d} nnz_K={nnz_K:6d} "
          f"nnz_L={nnz_L:6d}  ||dy||={dy_inf:8.2f}  min(Dv)={min_dv:.2e}")
    return True


def dump_uc_ipm_fixture(label: str, cfg: dict, out_dir: str, seed: int) -> bool:
    cfg = dict(cfg)
    cfg["solver_log"] = False
    cfg["time_limit"] = 1
    A, _b_orig, c = _build_uc_A_bc(cfg)
    n_unfilt = A.shape[1]
    if n_unfilt > PHASE1_MAX_N:
        print(f"  [{label}] n={n_unfilt}  SKIP: exceeds n ceiling (no QR run)")
        return False
    A = filter_to_full_row_rank(A)
    A.data = A.data * A_SCALE_UC
    m, n = A.shape

    if m > PHASE1_MAX_M or n > PHASE1_MAX_N:
        print(f"  [{label}] m={m} n={n}  SKIP: exceeds m/n ceiling")
        return False

    sym = prepare_sparse_problem(A, use_rcm=True)
    nnz_A = int(sym.A_indptr[-1])
    nnz_K = int(sym.K_colptr[-1])
    nnz_L = int(sym.L_colptr[-1])

    if nnz_A > PHASE1_MAX_NNZ_A or nnz_K > PHASE1_MAX_NNZ_K or nnz_L > PHASE1_MAX_NNZ_L:
        print(f"  [{label}] m={m:5d} nnz_A={nnz_A:6d} nnz_K={nnz_K:6d} "
              f"nnz_L={nnz_L:6d}  SKIP: exceeds nnz ceiling")
        return False

    b = np.asarray(A @ np.ones(n), dtype=np.float64).ravel()
    c_max = float(np.max(np.abs(c))) if c.size > 0 else 0.0
    if c_max > 0:
        c = c * (C_SCALE / c_max)
    else:
        c = np.ones(n, dtype=np.float64) * C_SCALE

    rng = np.random.default_rng(seed)
    D = rng.uniform(D_LO, D_HI, size=n)
    K_values, L_values_csc, Dv, b_perm, dy_perm = _factor_and_solve(sym, D, b)
    dy_inf = float(np.max(np.abs(dy_perm)))
    min_dv = float(np.min(Dv))

    if dy_inf > MAX_DY_INF:
        print(f"  [{label}] m={m:5d}  WARN: ||dy||_inf={dy_inf:.1f} > {MAX_DY_INF}; "
              f"IPM iters may stress Q17.54 dynamic range.")
    if min_dv < 1e-6:
        print(f"  [{label}] m={m:5d}  WARN: min(Dv)={min_dv:.2e} — pivot collapse risk.")

    out_path = os.path.join(out_dir, f"ipm_uc_{label}.bin")
    write_ipm_fixture(
        out_path, m=m, n=n,
        A_indptr=sym.A_indptr, A_indices=sym.A_indices, A_values=sym.A_values,
        K_colptr=sym.K_colptr, K_rowidx=sym.K_rowidx,
        L_colptr=sym.L_colptr, L_rowidx_csc=sym.L_rowidx_csc,
        L_rowptr=sym.L_rowptr, L_colidx_csr=sym.L_colidx_csr,
        L_csc_pos=sym.L_csc_pos, L_csr_pos=sym.L_csr_pos,
        b=b_perm, c=c,
    )
    print(f"  [{label}] m={m:5d} nnz_A={nnz_A:6d} nnz_K={nnz_K:6d} "
          f"nnz_L={nnz_L:6d}  ||dy||={dy_inf:8.2f}  min(Dv)={min_dv:.2e}  "
          f"||c||_inf={C_SCALE:.2f}")
    return True


def _uc_sizes():
    return [
        ("micro_T6",  dict(n_buses=4,  n_gens=3,  n_loads=4,  n_lines=4,  n_timesteps=6)),
        ("micro_T12", dict(n_buses=4,  n_gens=3,  n_loads=4,  n_lines=4,  n_timesteps=12)),
        ("xs_T6",     dict(n_buses=6,  n_gens=5,  n_loads=6,  n_lines=8,  n_timesteps=6)),
        ("xs_T12",    dict(n_buses=6,  n_gens=5,  n_loads=6,  n_lines=8,  n_timesteps=12)),
        ("xs_T24",    dict(n_buses=6,  n_gens=5,  n_loads=6,  n_lines=8,  n_timesteps=24)),
        ("s_T12",     dict(n_buses=10, n_gens=8,  n_loads=10, n_lines=12, n_timesteps=12)),
        ("s_T24",     dict(n_buses=10, n_gens=8,  n_loads=10, n_lines=12, n_timesteps=24)),
        ("m_T12",     dict(n_buses=20, n_gens=15, n_loads=20, n_lines=30, n_timesteps=12)),
        ("m_T24",     dict(n_buses=20, n_gens=15, n_loads=20, n_lines=30, n_timesteps=24)),
        ("l_T6",      dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=6)),
        ("l_T12",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=12)),
        ("l_T18",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=18)),
        ("l_T24",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=24)),
        ("l_T28",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=28)),
        ("l_T30",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=30)),
        ("l_T36",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=36)),
        ("l_T48",     dict(n_buses=30, n_gens=25, n_loads=30, n_lines=40, n_timesteps=48)),
        ("xl_T24",    dict(n_buses=50, n_gens=40, n_loads=45, n_lines=60, n_timesteps=24)),
        ("xl_T36",    dict(n_buses=50, n_gens=40, n_loads=45, n_lines=60, n_timesteps=36)),
    ]


def dump_uc_kform(out_dir: str):
    os.makedirs(out_dir, exist_ok=True)
    print(f"Dumping UC kform fixtures to {out_dir}")
    print(f"Ceilings: m<={PHASE1_MAX_M} nnz_A<={PHASE1_MAX_NNZ_A} "
          f"nnz_K<={PHASE1_MAX_NNZ_K} nnz_L<={PHASE1_MAX_NNZ_L}\n")

    for i, (label, override) in enumerate(_uc_sizes()):
        cfg = dict(CONFIG); cfg.update(override)
        dump_uc_kform_fixture(label, cfg, out_dir, seed=3000 + i)


def dump_uc_ipm(out_dir: str, only: list[str] | None = None,
                skip_existing: bool = False):
    os.makedirs(out_dir, exist_ok=True)
    print(f"Dumping UC IPM fixtures to {out_dir}", flush=True)
    print(f"Ceilings: m<={PHASE1_MAX_M} nnz_A<={PHASE1_MAX_NNZ_A} "
          f"nnz_K<={PHASE1_MAX_NNZ_K} nnz_L<={PHASE1_MAX_NNZ_L}\n", flush=True)

    n_done = 0; n_failed = 0; n_skipped = 0
    for i, (label, override) in enumerate(_uc_sizes()):
        if only is not None and label not in only:
            continue
        out_path = os.path.join(out_dir, f"ipm_uc_{label}.bin")
        if skip_existing and os.path.exists(out_path):
            print(f"  [{label}] SKIP: file already exists", flush=True)
            n_skipped += 1
            continue
        cfg = dict(CONFIG); cfg.update(override)
        try:
            ok = dump_uc_ipm_fixture(label, cfg, out_dir, seed=4000 + i)
            if ok:
                n_done += 1
            else:
                n_failed += 1
        except Exception as e:
            import traceback
            print(f"  [{label}] EXCEPTION: {type(e).__name__}: {e}", flush=True)
            traceback.print_exc()
            n_failed += 1
            continue

    print(f"\nDone. {n_done} written, {n_failed} failed, {n_skipped} skipped.",
          flush=True)


def cmd_uc(args):
    global build_synthetic_data, build_uc_model, CONFIG
    import sys
    sys.path.insert(0, os.path.join(ROOT, "python", "UC_example_UrbanTwin"))
    from run_example import build_synthetic_data, CONFIG
    from unit_commitment import build_uc_model

    if args.kform:
        dump_uc_kform(args.out_dir)
    if args.ipm:
        dump_uc_ipm(args.out_dir, only=args.only, skip_existing=args.skip_existing)


# ──────────────────────────── paired ────────────────────────────

class XS32:
    def __init__(self, seed: int = 1):
        self.state = np.uint32(seed)

    def next(self) -> np.uint32:
        x = self.state
        x ^= np.uint32(x << np.uint32(13)) & np.uint32(0xFFFFFFFF)
        x ^= np.uint32(x >> np.uint32(17))
        x ^= np.uint32(x << np.uint32(5)) & np.uint32(0xFFFFFFFF)
        self.state = x
        return x

    def urand(self) -> float:
        return float(self.next()) / 4294967296.0


def make_random_csr_A(m: int, n: int, density: float, seed: int) -> sp.csr_matrix:
    rng = XS32(seed)
    Ad = np.zeros((m, n), dtype=np.float64)
    for i in range(m):
        for j in range(n):
            if rng.urand() < density:
                v = float(int(rng.urand() * 5.0) + 1)
                Ad[i, j] = v
        if not np.any(Ad[i, :]):
            Ad[i, i % n] = 1.0
    return sp.csr_matrix(Ad), rng


def make_lp_instance(m: int, n: int, density: float, seed: int) -> tuple[sp.csr_matrix, np.ndarray, np.ndarray]:
    A, rng = make_random_csr_A(m, n, density, seed)
    c = np.array([0.5 + 5.0 * rng.urand() for _ in range(n)], dtype=np.float64)
    b = np.asarray(A @ np.ones(n), dtype=np.float64).ravel()
    return A, b, c


def write_paired_kform_fixture(out_path: Path, A: sp.csr_matrix, b: np.ndarray) -> dict:
    m, n = A.shape
    sym = prepare_sparse_problem(A, use_rcm=True)
    D = np.ones(n, dtype=np.float64)
    K_values, L_values_csc, Dv, b_perm, dy_perm = _factor_and_solve(sym, D, b)
    write_kform_fixture(
        str(out_path),
        m=m, n=n,
        A_indptr=sym.A_indptr, A_indices=sym.A_indices, A_values=sym.A_values,
        D=D,
        K_colptr=sym.K_colptr, K_rowidx=sym.K_rowidx,
        L_colptr=sym.L_colptr, L_rowidx_csc=sym.L_rowidx_csc,
        L_rowptr=sym.L_rowptr, L_colidx_csr=sym.L_colidx_csr,
        L_csc_pos=sym.L_csc_pos, L_csr_pos=sym.L_csr_pos,
        b=b_perm, dy_expected=dy_perm,
        K_values_expected=K_values,
    )
    return {"m": m, "n": n, "nnz_A": int(sym.A_indptr[-1]),
            "nnz_K": int(sym.K_colptr[-1]), "nnz_L": int(sym.L_colptr[-1])}


def cmd_paired(args):
    ms = [int(x) for x in args.m_grid.split(",")]
    densities = [float(x) for x in args.density_grid.split(",")]
    seeds = [int(x) for x in args.seeds.split(",")]

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"Writing {len(ms)*len(densities)*len(seeds)} kform paired fixtures to {out_dir}")
    print(f"  m: {ms}")
    print(f"  density: {densities}")
    print(f"  seeds: {seeds}")

    n_written = 0
    n_failed = 0
    for m in ms:
        n = max(int(round(m * args.aspect)), m)  # aspect<=1 -> square n=m
        for density in densities:
            for seed in seeds:
                d_tag = f"{int(round(density * 100)):03d}"
                label = f"paired_m{m:03d}_d{d_tag}_s{seed:02d}"
                out_path = out_dir / f"kform_{label}.bin"
                try:
                    A, b, _c = make_lp_instance(m, n, density, seed)
                    info = write_paired_kform_fixture(out_path, A, b)
                    print(f"  [{label}] m={info['m']:4d} n={info['n']:4d} "
                          f"nnz_A={info['nnz_A']:5d} nnz_K={info['nnz_K']:5d} "
                          f"nnz_L={info['nnz_L']:5d}")
                    n_written += 1
                except Exception as e:
                    print(f"  [{label}] FAILED: {type(e).__name__}: {e}")
                    n_failed += 1

    print(f"\nDone. {n_written} written, {n_failed} failed.")


# ───────────────────────────── cli ─────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--decimals", type=int, default=40,
                        help="Q.frac bit count for fixture raw packing. Must match "
                             "shared/fxp_utils.h's Q_FRAC_BITS for the kernel build "
                             "the fixture targets. Default 40 (Q31.40 baseline).")
    common.add_argument("--out-dir", default=None,
                        help="default: hw/kernels/sparse_solve/tb/fixtures/")

    p = argparse.ArgumentParser(prog="generate_fixtures",
                                description="Generate sparse_solve test fixtures.")
    sub = p.add_subparsers(dest="cmd", required=True)

    syn = sub.add_parser("synthetic", parents=[common],
                         help="random/banded A -> trisolve+factor+kform (default) "
                              "or, with --ipm, end-to-end ipm_*.bin fixtures")
    syn.add_argument("--ipm", action="store_true",
                     help="write ipm_*.bin (SPLI) fixtures for lp_ipm_sparse_bench "
                          "instead of the kernel fixtures")

    uc = sub.add_parser("uc", parents=[common],
                        help="real UC LP -> kform_uc / ipm_uc fixtures (needs gurobipy)")
    uc.add_argument("--kform", action="store_true",
                    help="write kform_uc_*.bin (SPLA) fixtures")
    uc.add_argument("--ipm", action="store_true",
                    help="write ipm_uc_*.bin (SPLI) fixtures for lp_ipm_sparse_bench")
    uc.add_argument("--only", nargs="+", default=None,
                    help="restrict to these UC labels (ipm only)")
    uc.add_argument("--skip-existing", action="store_true",
                    help="skip fixtures whose output file already exists (ipm only)")

    pd = sub.add_parser("paired", parents=[common],
                        help="RNG-paired random LP -> kform_paired_*.bin (SPLA)")
    pd.add_argument("--m-grid", default="64,128,192", help="comma-separated m values")
    pd.add_argument("--density-grid", default="0.05,0.1,0.2,0.5,1.0",
                    help="comma-separated densities")
    pd.add_argument("--seeds", default="1,2,3,4,5,6,7,8,9,10",
                    help="comma-separated seeds (0 is degenerate — xorshift32 fixed point)")
    pd.add_argument("--aspect", type=float, default=1.6,
                    help="n / m ratio (default 1.6, matches milpBnbTestbench.cpp dense sweep)")
    return p


def main():
    args = build_parser().parse_args()
    set_decimals(args.decimals)
    if args.out_dir is None:
        args.out_dir = default_fixtures_dir()

    if args.cmd == "synthetic":
        cmd_synthetic(args)
    elif args.cmd == "uc":
        if not (args.kform or args.ipm):
            raise SystemExit("uc: specify at least one of --kform / --ipm")
        cmd_uc(args)
    elif args.cmd == "paired":
        cmd_paired(args)


if __name__ == "__main__":
    main()
