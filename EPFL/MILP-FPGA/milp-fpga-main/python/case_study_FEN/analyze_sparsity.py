#!/usr/bin/env python3
"""Analyze size, sparsity, and structure of case_study_FEN_ESL data."""

import os
import sys
import numpy as np
from scipy import sparse

DATA_ROOT = os.path.join(os.path.dirname(__file__),
                         "..", "..", "data", "EPFLESL_FEN", "case_study_FEN_ESL")

PERIODS = ["period_12Year", "period_6Year", "period_4Year",
           "period_3Year", "period_2Year", "period_1Year"]


def load_period(period_dir):
    """Load the matrices and bound vectors used by the analysis."""
    A = sparse.load_npz(os.path.join(period_dir, "matrix_A.npz"))
    B = sparse.load_npz(os.path.join(period_dir, "matrix_B.npz"))
    lhs = sparse.load_npz(os.path.join(period_dir, "vector_lhs.npz"))
    rhs = sparse.load_npz(os.path.join(period_dir, "vector_rhs.npz"))
    return A, B, lhs, rhs


def analyze_matrix(name, M):
    """Print basic stats for a sparse matrix."""
    m, n = M.shape
    nnz = M.nnz
    density = nnz / (m * n) if m * n > 0 else 0
    print(f"  {name}: {m:,} x {n:,}  |  nnz = {nnz:,}  |  density = {density:.6%}")
    print(f"    avg nnz/row = {nnz / m:.1f}  |  avg nnz/col = {nnz / n:.1f}")
    return m, n, nnz, density


def analyze_benders_structure(A, B):
    """Check if A has block-diagonal structure (temporal decomposition)."""
    A_csr = A.tocsr()
    m, n = A_csr.shape

    # Approximate block structure by the row-range each column spans.
    print("\n  --- Block-diagonal structure analysis (A matrix) ---")

    A_csc = A.tocsc()
    n_cols = A_csc.shape[1]

    col_row_min = np.full(n_cols, m, dtype=np.int64)
    col_row_max = np.full(n_cols, -1, dtype=np.int64)

    for j in range(n_cols):
        start, end = A_csc.indptr[j], A_csc.indptr[j + 1]
        if end > start:
            rows = A_csc.indices[start:end]
            col_row_min[j] = rows.min()
            col_row_max[j] = rows.max()

    active_cols = col_row_max >= 0
    if active_cols.sum() == 0:
        print("    A matrix is empty!")
        return

    active_idx = np.where(active_cols)[0]
    sort_order = np.argsort(col_row_min[active_idx])
    sorted_cols = active_idx[sort_order]

    # A new block starts when col_row_min exceeds the previous block's max_row.
    blocks = []
    block_start_col = 0
    block_max_row = col_row_max[sorted_cols[0]]
    block_min_row = col_row_min[sorted_cols[0]]

    for i in range(1, len(sorted_cols)):
        j = sorted_cols[i]
        if col_row_min[j] > block_max_row:
            blocks.append((block_start_col, i, block_min_row, block_max_row))
            block_start_col = i
            block_min_row = col_row_min[j]
            block_max_row = col_row_max[j]
        else:
            block_max_row = max(block_max_row, col_row_max[j])

    blocks.append((block_start_col, len(sorted_cols), block_min_row, block_max_row))

    print(f"    Detected {len(blocks)} block(s) in A")
    if len(blocks) <= 20:
        for i, (cs, ce, rmin, rmax) in enumerate(blocks):
            n_block_cols = ce - cs
            n_block_rows = rmax - rmin + 1
            print(f"      Block {i}: cols [{cs}..{ce-1}] ({n_block_cols:,} cols), "
                  f"rows [{rmin}..{rmax}] ({n_block_rows:,} rows)")
    else:
        print(f"    First 5 blocks:")
        for i in range(5):
            cs, ce, rmin, rmax = blocks[i]
            print(f"      Block {i}: {ce-cs:,} cols, {rmax-rmin+1:,} rows")
        print(f"    Last block: {blocks[-1][1]-blocks[-1][0]:,} cols, "
              f"{blocks[-1][3]-blocks[-1][2]+1:,} rows")

    return blocks


def analyze_B_structure(B):
    """Analyze B matrix: column activity, sparsity pattern."""
    B_csc = B.tocsc()
    m, n_y = B_csc.shape

    print(f"\n  --- B matrix structure (investment coupling) ---")
    print(f"    Shape: {m:,} x {n_y}")
    print(f"    nnz: {B_csc.nnz:,}")

    # Per-column nnz
    col_nnz = np.diff(B_csc.indptr)
    active_cols = np.sum(col_nnz > 0)
    print(f"    Active columns (nnz > 0): {active_cols} / {n_y}")
    print(f"    Column nnz: min={col_nnz.min()}, median={np.median(col_nnz):.0f}, "
          f"max={col_nnz.max()}, mean={col_nnz.mean():.1f}")

    # What fraction of rows does B touch?
    B_csr = B.tocsr()
    row_nnz = np.diff(B_csr.indptr)
    rows_with_B = np.sum(row_nnz > 0)
    print(f"    Rows touched by B: {rows_with_B:,} / {m:,} ({100*rows_with_B/m:.2f}%)")


def analyze_bounds(lhs, rhs):
    """Analyze constraint bounds for structure."""
    lhs_arr = np.asarray(lhs.todense()).flatten() if sparse.issparse(lhs) else lhs.flatten()
    rhs_arr = np.asarray(rhs.todense()).flatten() if sparse.issparse(rhs) else rhs.flatten()

    n_eq = np.sum(np.abs(lhs_arr - rhs_arr) < 1e-10)
    n_lb_only = np.sum((lhs_arr > -1e90) & (rhs_arr > 1e90))
    n_ub_only = np.sum((lhs_arr < -1e90) & (rhs_arr < 1e90))
    n_range = np.sum((lhs_arr > -1e90) & (rhs_arr < 1e90) & (np.abs(lhs_arr - rhs_arr) >= 1e-10))
    n_free = np.sum((lhs_arr < -1e90) & (rhs_arr > 1e90))

    total = len(lhs_arr)
    print(f"\n  --- Constraint types ---")
    print(f"    Equality (lhs == rhs):  {n_eq:,} ({100*n_eq/total:.1f}%)")
    print(f"    Lower bound only:       {n_lb_only:,} ({100*n_lb_only/total:.1f}%)")
    print(f"    Upper bound only:       {n_ub_only:,} ({100*n_ub_only/total:.1f}%)")
    print(f"    Range (lhs < rhs):      {n_range:,} ({100*n_range/total:.1f}%)")
    print(f"    Free (unbounded):       {n_free:,} ({100*n_free/total:.1f}%)")


def main():
    periods_to_run = sys.argv[1:] if len(sys.argv) > 1 else PERIODS

    print("=" * 70)
    print("  case_study_FEN_ESL — Sparsity & Structure Analysis")
    print("=" * 70)

    results = []

    for period in periods_to_run:
        period_dir = os.path.join(DATA_ROOT, period)
        if not os.path.isdir(period_dir):
            print(f"\n  {period}: directory not found, skipping")
            continue

        print(f"\n{'-' * 70}")
        print(f"  Period: {period}")
        print(f"{'-' * 70}")

        try:
            A, B, lhs, rhs = load_period(period_dir)
        except Exception as e:
            print(f"    Error loading: {e}")
            continue

        # Basic matrix stats
        m_A, n_A, nnz_A, d_A = analyze_matrix("A", A)
        m_B, n_B, nnz_B, d_B = analyze_matrix("B", B)

        print(f"\n  Summary: {m_A:,} constraints, {n_A:,} operational + {n_B} investment = "
              f"{n_A + n_B:,} total variables")

        # Combined G = [A, B]
        G_nnz = nnz_A + nnz_B
        G_density = G_nnz / (m_A * (n_A + n_B))
        print(f"  Combined G=[A|B]: nnz = {G_nnz:,}, density = {G_density:.6%}")

        results.append({
            "period": period,
            "m": m_A,
            "n_x": n_A,
            "n_y": n_B,
            "n_total": n_A + n_B,
            "nnz_A": nnz_A,
            "nnz_B": nnz_B,
            "nnz_G": G_nnz,
            "density_A": d_A,
            "density_B": d_B,
            "density_G": G_density,
        })

        # Memory estimates
        csr_bytes = 12 * G_nnz + 4 * (m_A + 1)
        print(f"  CSR storage for G: {csr_bytes / 1e6:.1f} MB")

        # Analyze bounds
        analyze_bounds(lhs, rhs)

        # B structure
        analyze_B_structure(B)

        # Block structure (only for smallest period to avoid long runtime)
        if period in ["period_12Year", "period_6Year"]:
            analyze_benders_structure(A, B)
        else:
            print(f"\n  (Skipping block analysis for large period — run with: "
                  f"python analyze_sparsity.py {period})")

    # ---- Summary table ----
    if results:
        print(f"\n{'=' * 120}")
        print("  SUMMARY — All periods")
        print(f"{'=' * 120}")
        header = (f"  {'Period':<18} {'Rows':>10} {'Cols(x)':>10} {'Cols(y)':>10} "
                  f"{'Total vars':>12} {'nnz(A)':>12} {'nnz(B)':>12} {'nnz(G)':>12} "
                  f"{'dens(A)':>10} {'dens(B)':>10} {'dens(G)':>10}")
        print(header)
        print(f"  {'-' * 116}")
        for r in results:
            print(f"  {r['period']:<18} {r['m']:>10,} {r['n_x']:>10,} {r['n_y']:>10,} "
                  f"{r['n_total']:>12,} {r['nnz_A']:>12,} {r['nnz_B']:>12,} {r['nnz_G']:>12,} "
                  f"{r['density_A']:>9.4%} {r['density_B']:>9.4%} {r['density_G']:>9.4%}")
        print(f"{'=' * 120}")

        # ---- Compact summary (m, n, nnz%, sparsity%) ----
        print(f"\n  COMPACT SUMMARY — m, n, nnz%, sparsity%")
        print(f"  {'Period':<18} {'m':>12} {'n':>12} "
              f"{'nnz%(A)':>10} {'nnz%(B)':>10} {'nnz%(G)':>10} "
              f"{'spar%(A)':>10} {'spar%(B)':>10} {'spar%(G)':>10}")
        print(f"  {'-' * 102}")
        for r in results:
            nz_A = r['density_A'] * 100
            nz_B = r['density_B'] * 100
            nz_G = r['density_G'] * 100
            sp_A = (1 - r['density_A']) * 100
            sp_B = (1 - r['density_B']) * 100
            sp_G = (1 - r['density_G']) * 100
            print(f"  {r['period']:<18} {r['m']:>12,} {r['n_total']:>12,} "
                  f"{nz_A:>9.4f}% {nz_B:>9.4f}% {nz_G:>9.4f}% "
                  f"{sp_A:>9.4f}% {sp_B:>9.4f}% {sp_G:>9.4f}%")
        print(f"{'=' * 120}")

    print(f"\n  Done.")


if __name__ == "__main__":
    main()
