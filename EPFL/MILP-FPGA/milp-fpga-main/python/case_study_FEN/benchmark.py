#!/usr/bin/env python3
"""Benchmark Gurobi and HiGHS on the FEN urban-energy case study.

Strategies: gurobi (barrier on the full model), highs (IPM on the full model),
hybrid (Gurobi presolve then HiGHS IPM on the presolved system).
"""

import argparse
import os
import sys
import time
import tracemalloc

import numpy as np
from scipy import sparse

try:
    import psutil
    _HAS_PSUTIL = True
except ImportError:
    _HAS_PSUTIL = False


DATA_ROOT = os.path.join(os.path.dirname(__file__),
                         "..", "..", "data", "EPFLESL_FEN", "case_study_FEN_ESL")

PERIODS = ["period_12Year", "period_6Year", "period_4Year",
           "period_3Year", "period_2Year", "period_1Year"]

SOLVER_NAMES = ("gurobi", "highs", "hybrid")


# ---------------------------------------------------------------------------
# Memory helpers (used under --detail)
# ---------------------------------------------------------------------------

def snapshot_memory():
    py_current, py_peak = tracemalloc.get_traced_memory()
    result = {"python_current_mb": py_current / 1e6,
              "python_peak_mb": py_peak / 1e6,
              "rss_mb": (psutil.Process(os.getpid()).memory_info().rss / 1e6
                        if _HAS_PSUTIL else None)}
    return result


def sparse_memory_report(name, M):
    M_csr = M.tocsr()
    total_mb = (M_csr.data.nbytes + M_csr.indices.nbytes + M_csr.indptr.nbytes) / 1e6
    density = M_csr.nnz / (M_csr.shape[0] * M_csr.shape[1]) * 100
    print(f"  {name:8s}  {M_csr.shape[0]:>10,} x {M_csr.shape[1]:>8,}"
          f"  nnz={M_csr.nnz:>12,}  density={density:.4f}%"
          f"  mem={total_mb:>8.1f} MB")


# ---------------------------------------------------------------------------
# Data loading and Gurobi model construction (shared)
# ---------------------------------------------------------------------------

def load_data(period):
    d = os.path.join(DATA_ROOT, period)
    A = sparse.load_npz(os.path.join(d, "matrix_A.npz"))
    B = sparse.load_npz(os.path.join(d, "matrix_B.npz"))
    b = np.asarray(sparse.load_npz(os.path.join(d, "vector_b.npz")).todense()).flatten()
    c = np.asarray(sparse.load_npz(os.path.join(d, "vector_c.npz")).todense()).flatten()
    d_const = float(np.sum(np.asarray(
        sparse.load_npz(os.path.join(d, "vector_d.npz")).todense())))
    lhs = np.asarray(sparse.load_npz(os.path.join(d, "vector_lhs.npz")).todense()).flatten()
    rhs = np.asarray(sparse.load_npz(os.path.join(d, "vector_rhs.npz")).todense()).flatten()
    return A, B, b, c, d_const, lhs, rhs


def build_gurobi_model(A, B, b, c, d_const, lhs, rhs, name="fen", output=False):
    import gurobipy as gp
    from gurobipy import GRB

    m = gp.Model(name)
    m.setParam("OutputFlag", 1 if output else 0)
    if output:
        m.setParam("LogToConsole", 1)

    n_x, n_y = A.shape[1], B.shape[1]
    x = m.addMVar(shape=n_x, vtype=GRB.CONTINUOUS, lb=-GRB.INFINITY, ub=GRB.INFINITY)
    y = m.addMVar(shape=n_y, vtype=GRB.CONTINUOUS, lb=-GRB.INFINITY, ub=GRB.INFINITY)
    m.setObjective(b @ x + c @ y + d_const, GRB.MINIMIZE)

    chunk = 500_000
    n_rows = A.shape[0]
    for i in range(0, n_rows, chunk):
        sl = slice(i, min(i + chunk, n_rows))
        expr = A[sl] @ x + B[sl] @ y
        m.addConstr(expr >= lhs[sl], name=f"LHS_{i}")
        m.addConstr(expr <= rhs[sl], name=f"RHS_{i}")

    m.update()
    return m


# ---------------------------------------------------------------------------
# PhaseTracker (Gurobi callback, only under --detail)
# ---------------------------------------------------------------------------

class PhaseTracker:
    def __init__(self):
        self.phase_starts = {}
        self.phase_ends = {}
        self.presolve_info = {}
        self.barrier_iters = []
        self.messages = []

    def __call__(self, model, where):
        from gurobipy import GRB

        now = time.time()
        if where == GRB.Callback.PRESOLVE:
            if "PRESOLVE" not in self.phase_starts:
                self.phase_starts["PRESOLVE"] = (now, snapshot_memory())
            self.presolve_info = {
                "coldel": int(model.cbGet(GRB.Callback.PRE_COLDEL)),
                "rowdel": int(model.cbGet(GRB.Callback.PRE_ROWDEL)),
                "senchg": int(model.cbGet(GRB.Callback.PRE_SENCHG)),
                "bndchg": int(model.cbGet(GRB.Callback.PRE_BNDCHG)),
            }
            self.phase_ends["PRESOLVE"] = now
        elif where == GRB.Callback.BARRIER:
            if "BARRIER" not in self.phase_starts:
                self.phase_starts["BARRIER"] = (now, snapshot_memory())
            self.barrier_iters.append((
                int(model.cbGet(GRB.Callback.BARRIER_ITRCNT)),
                model.cbGet(GRB.Callback.BARRIER_PRIMOBJ),
                model.cbGet(GRB.Callback.BARRIER_DUALOBJ),
                model.cbGet(GRB.Callback.BARRIER_PRIMINF),
                model.cbGet(GRB.Callback.BARRIER_DUALINF),
                model.cbGet(GRB.Callback.BARRIER_COMPL),
            ))
            self.phase_ends["BARRIER"] = now
        elif where == GRB.Callback.SIMPLEX:
            # Simplex iterations after barrier == crossover
            if "BARRIER" in self.phase_starts and "CROSSOVER" not in self.phase_starts:
                self.phase_starts["CROSSOVER"] = (now, snapshot_memory())
            elif "SIMPLEX" not in self.phase_starts and "BARRIER" not in self.phase_starts:
                self.phase_starts["SIMPLEX"] = (now, snapshot_memory())
            key = "CROSSOVER" if "CROSSOVER" in self.phase_starts else "SIMPLEX"
            self.phase_ends[key] = now
        elif where == GRB.Callback.MESSAGE:
            self.messages.append(model.cbGet(GRB.Callback.MSG_STRING))

    def duration(self, phase):
        if phase in self.phase_starts and phase in self.phase_ends:
            return self.phase_ends[phase] - self.phase_starts[phase][0]
        return 0.0


# ---------------------------------------------------------------------------
# Solver runners
# ---------------------------------------------------------------------------

def run_gurobi(A, B, b, c, d_const, lhs, rhs,
               method=2, crossover=True, detail=False, verbose=False):
    from gurobipy import GRB

    print("\n" + "=" * 60)
    print(f"  Gurobi (Method={method}, crossover={'on' if crossover else 'off'})")
    print("=" * 60)

    mem_baseline = None
    if detail:
        tracemalloc.start()
        mem_baseline = snapshot_memory()
        print("\n  Sparse matrix footprint:")
        sparse_memory_report("A", A)
        sparse_memory_report("B", B)

    t0 = time.time()
    m = build_gurobi_model(A, B, b, c, d_const, lhs, rhs, name="gurobi", output=True)
    build_time = time.time() - t0
    print(f"  Model build: {build_time:.1f}s")

    m.setParam("Method", method)
    if not crossover:
        m.setParam("Crossover", 0)

    tracker = PhaseTracker() if detail else None
    t0 = time.time()
    if tracker is not None:
        m.optimize(tracker)
    else:
        m.optimize()
    wall_time = time.time() - t0

    result = {
        "strategy": "Gurobi" + (" (no crossover)" if not crossover else ""),
        "status": m.Status,
        "obj": m.ObjVal if m.Status == GRB.OPTIMAL else None,
        "solve_time": m.Runtime,
        "wall_time": wall_time,
        "build_time": build_time,
        "bar_iter": m.BarIterCount,
        "iter_count": m.IterCount,
    }

    if detail:
        try:
            pre = m.presolve()
            result["pre_rows"] = pre.NumConstrs
            result["pre_cols"] = pre.NumVars
            result["pre_nnz"] = pre.NumNZs
            pre.dispose()
        except Exception:
            pass
        result["t_presolve"] = tracker.duration("PRESOLVE")
        result["t_barrier"] = tracker.duration("BARRIER")
        result["t_crossover"] = tracker.duration("CROSSOVER")
        result["t_simplex"] = tracker.duration("SIMPLEX")
        result["presolve_info"] = tracker.presolve_info
        result["barrier_iters"] = tracker.barrier_iters
        result["phase_mem"] = {p: tracker.phase_starts[p][1]
                                for p in ("PRESOLVE", "BARRIER", "CROSSOVER", "SIMPLEX")
                                if p in tracker.phase_starts}
        result["mem_baseline"] = mem_baseline
        result["mem_after_solve"] = snapshot_memory()
        _, py_peak = tracemalloc.get_traced_memory()
        result["python_peak_mb"] = py_peak / 1e6
        tracemalloc.stop()

        if verbose and tracker.messages:
            print("\n  --- Gurobi log (captured) ---")
            for msg in tracker.messages:
                print(f"  {msg}", end="")

    m.dispose()
    return result


def run_highs_full(A, B, b, c, d_const, lhs, rhs):
    import highspy

    print("\n" + "=" * 60)
    print("  HiGHS IPM (full model)")
    print("=" * 60)

    t0 = time.time()
    m = build_gurobi_model(A, B, b, c, d_const, lhs, rhs, name="for_export", output=False)
    mps_path = os.path.join(os.path.dirname(__file__), "_full.mps")
    m.write(mps_path)
    m.dispose()
    build_time = time.time() - t0
    print(f"  Model build + MPS export: {build_time:.1f}s")

    h = highspy.Highs()
    h.setOptionValue("output_flag", True)
    h.setOptionValue("solver", "ipm")
    h.setOptionValue("presolve", "on")
    h.readModel(mps_path)

    t_solve = time.time()
    h.run()
    solve_time = time.time() - t_solve

    obj = h.getInfoValue("objective_function_value")[1]
    ipm_iter = h.getInfoValue("ipm_iteration_count")[1]
    status = h.getInfoValue("primal_solution_status")[1]

    try:
        os.remove(mps_path)
    except OSError:
        pass

    return {
        "strategy": "HiGHS IPM (full)",
        "status": status,
        "obj": obj,
        "solve_time": solve_time,
        "build_time": build_time,
        "ipm_iter": ipm_iter,
    }


def run_hybrid(A, B, b, c, d_const, lhs, rhs):
    import highspy

    print("\n" + "=" * 60)
    print("  HiGHS IPM on Gurobi-presolved model")
    print("=" * 60)

    t0 = time.time()
    m = build_gurobi_model(A, B, b, c, d_const, lhs, rhs, name="hybrid", output=False)
    build_time = time.time() - t0
    print(f"  Model build: {build_time:.1f}s")

    t_pre = time.time()
    presolved = m.presolve()
    presolve_time = time.time() - t_pre
    pre_rows, pre_cols, pre_nnz = presolved.NumConstrs, presolved.NumVars, presolved.NumNZs
    print(f"  Gurobi presolve: {presolve_time:.1f}s -> "
          f"{pre_rows} rows, {pre_cols} cols, {pre_nnz} nnz")

    mps_path = os.path.join(os.path.dirname(__file__), "_presolved.mps")
    t_export = time.time()
    presolved.write(mps_path)
    export_time = time.time() - t_export
    print(f"  MPS export: {export_time:.1f}s")
    presolved.dispose()
    m.dispose()

    h = highspy.Highs()
    h.setOptionValue("output_flag", True)
    h.setOptionValue("solver", "ipm")
    h.setOptionValue("presolve", "off")

    t_read = time.time()
    h.readModel(mps_path)
    read_time = time.time() - t_read
    print(f"  HiGHS read: {read_time:.1f}s")

    # Wall-clock around h.run(); HiGHS getInfoValue("run_time") is unreliable.
    t_solve = time.time()
    h.run()
    solve_time = time.time() - t_solve

    obj = h.getInfoValue("objective_function_value")[1]
    ipm_iter = h.getInfoValue("ipm_iteration_count")[1]
    status = h.getInfoValue("primal_solution_status")[1]

    try:
        os.remove(mps_path)
    except OSError:
        pass

    return {
        "strategy": "HiGHS IPM (Gurobi-presolved)",
        "status": status,
        "obj": obj,
        "solve_time": solve_time,
        "build_time": build_time,
        "presolve_time": presolve_time,
        "export_time": export_time,
        "read_time": read_time,
        "ipm_iter": ipm_iter,
        "pre_rows": pre_rows,
        "pre_cols": pre_cols,
        "pre_nnz": pre_nnz,
    }


# ---------------------------------------------------------------------------
# Summary printers
# ---------------------------------------------------------------------------

def _fmt_rss(snap):
    rss = snap.get("rss_mb") if snap else None
    py = snap["python_current_mb"] if snap else 0.0
    rss_str = f"RSS={rss:.0f} MB" if rss is not None else "RSS=N/A"
    return f"{rss_str}, py={py:.0f} MB"


def print_compact_summary(period, results):
    print(f"\n{'=' * 70}")
    print(f"  Summary -- {period} (LP relaxation)")
    print(f"{'=' * 70}")
    for r in results:
        print(f"\n  {r['strategy']}")
        print(f"    Status:     {r['status']}")
        if r.get("obj") is not None:
            print(f"    Objective:  {r['obj']:.6e}")
        print(f"    Build:      {r['build_time']:.1f}s")
        print(f"    Solve:      {r['solve_time']:.1f}s")
        if "bar_iter" in r:
            print(f"    Barrier iters: {int(r['bar_iter'])}")
        if "ipm_iter" in r:
            print(f"    IPM iters:    {int(r['ipm_iter'])}")
        if "presolve_time" in r:
            print(f"    Gurobi presolve: {r['presolve_time']:.1f}s "
                  f"({r['pre_rows']} rows, {r['pre_cols']} cols, {r['pre_nnz']} nnz)")


def print_gurobi_detail(period, r):
    print(f"\n{'=' * 70}")
    print(f"  Gurobi phase timing -- {period}")
    print(f"{'=' * 70}")
    print(f"  {'Phase':<22} {'Time (s)':>10}")
    print(f"  {'-' * 22} {'-' * 10}")
    for name, t in [("Presolve", r.get("t_presolve", 0)),
                    ("Barrier", r.get("t_barrier", 0)),
                    ("Crossover", r.get("t_crossover", 0)),
                    ("Simplex (direct)", r.get("t_simplex", 0))]:
        if t > 0:
            print(f"  {name:<22} {t:>10.2f}")
    print(f"  {'-' * 22} {'-' * 10}")
    print(f"  {'Model build (host)':<22} {r['build_time']:>10.2f}")
    print(f"  {'Solver Runtime':<22} {r['solve_time']:>10.2f}")
    print(f"  {'Wall around solve':<22} {r['wall_time']:>10.2f}")

    pi = r.get("presolve_info") or {}
    if pi:
        print(f"\n  Presolve removed: {pi['coldel']} cols, {pi['rowdel']} rows,"
              f" {pi['senchg']} sense chg, {pi['bndchg']} bound chg")
    if "pre_rows" in r:
        print(f"  Presolved model:  {r['pre_rows']} rows, "
              f"{r['pre_cols']} cols, {r['pre_nnz']} nnz")
    print(f"  Barrier iterations:      {int(r['bar_iter'])}")
    print(f"  Simplex/crossover iters: {int(r['iter_count'])}")
    if r.get("barrier_iters"):
        it, primobj, dualobj, priminf, dualinf, compl = r["barrier_iters"][-1]
        print(f"  Final barrier: primobj={primobj:.6e}  dualobj={dualobj:.6e}"
              f"  priminf={priminf:.2e}  dualinf={dualinf:.2e}  compl={compl:.2e}")
    if r.get("obj") is not None:
        print(f"  Objective: {r['obj']:.6e}")
    print(f"  Status: {r['status']}")

    if "mem_baseline" in r and r["mem_baseline"] is not None:
        print(f"\n  Memory profile:")
        print(f"    Baseline:        {_fmt_rss(r['mem_baseline'])}")
        for phase in ("PRESOLVE", "BARRIER", "CROSSOVER", "SIMPLEX"):
            if phase in r.get("phase_mem", {}):
                print(f"    {phase:14s} start: {_fmt_rss(r['phase_mem'][phase])}")
        print(f"    After solve:     {_fmt_rss(r['mem_after_solve'])}")
        print(f"    Peak Python (tracemalloc): {r['python_peak_mb']:.1f} MB")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Benchmark Gurobi and HiGHS on the FEN urban-energy case study.")
    parser.add_argument("periods", nargs="+",
                        help=f"Period directory name(s). Known: {PERIODS}")
    parser.add_argument("--solvers", default="gurobi,highs,hybrid",
                        help="Comma-separated subset of {gurobi, highs, hybrid}. "
                             "Default: all three.")
    parser.add_argument("--detail", action="store_true",
                        help="Add Gurobi phase callbacks, memory tracing, "
                             "and sparse-matrix footprint.")
    parser.add_argument("--method", type=int, default=2,
                        help="Gurobi Method (0=primal, 1=dual, 2=barrier). Default 2.")
    parser.add_argument("--no-crossover", action="store_true",
                        help="Disable Gurobi crossover.")
    parser.add_argument("--verbose", action="store_true",
                        help="Echo full Gurobi log at the end (only with --detail).")
    args = parser.parse_args()

    solvers = [s.strip() for s in args.solvers.split(",") if s.strip()]
    unknown = [s for s in solvers if s not in SOLVER_NAMES]
    if unknown:
        sys.exit(f"Unknown solver(s): {unknown}. Allowed: {SOLVER_NAMES}")

    if args.detail and not _HAS_PSUTIL:
        print("WARNING: psutil not installed -- RSS tracking disabled. "
              "Install with: pip install psutil\n")

    for period in args.periods:
        if period not in PERIODS:
            print(f"WARNING: '{period}' not in known periods {PERIODS}")
        print(f"\nLoading {period}...")
        A, B, b, c, d_const, lhs, rhs = load_data(period)
        print(f"  A: {A.shape[0]:,} x {A.shape[1]:,}, nnz={A.nnz:,}")
        print(f"  B: {B.shape[0]:,} x {B.shape[1]:,}, nnz={B.nnz:,}")

        results = []
        if "gurobi" in solvers:
            results.append(run_gurobi(
                A, B, b, c, d_const, lhs, rhs,
                method=args.method, crossover=not args.no_crossover,
                detail=args.detail, verbose=args.verbose))
        if "highs" in solvers:
            results.append(run_highs_full(A, B, b, c, d_const, lhs, rhs))
        if "hybrid" in solvers:
            results.append(run_hybrid(A, B, b, c, d_const, lhs, rhs))

        print_compact_summary(period, results)
        if args.detail:
            for r in results:
                if r["strategy"].startswith("Gurobi"):
                    print_gurobi_detail(period, r)


if __name__ == "__main__":
    main()
