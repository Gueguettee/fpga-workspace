"""
Runnable example for the UC solver defined in `unit_commitment.py`.

Tune instance size via the CONFIG dict below:
    n_buses, n_gens, n_loads, n_lines, n_timesteps, seed

The synthetic system scales generator capacity to ~1.6x peak demand, and
builds a random connected network on top of a spanning tree with extra
lines added for redundancy. Generator types (base / mid / peaker) are
drawn randomly with different Pmin/Pmax ratios, ramps, min up/down times
and cost structures.
"""

from __future__ import annotations

import math
import random
import time

from python.external_work.UC_example_UrbanTwin.unit_commitment import build_uc_model, solve_uc_model, extract_results


# =============================================================================
# Tunable configuration
# =============================================================================
CONFIG = {
    # Instance size
    "n_buses":      15,
    "n_gens":       20,
    "n_loads":      30,
    "n_lines":      20,
    "n_timesteps":  24,
    "seed":        42,

    # Solver
    "mip_gap":    1e-3,
    "time_limit": None,      # seconds, None for unlimited
    "threads":    None,     # None = Gurobi default
    "solver_log": True,

    # Economics
    "voll": 10000.0,       # $/MWh
}


# =============================================================================
# Synthetic data generator
# =============================================================================
def build_synthetic_data(cfg: dict) -> dict:
    rng = random.Random(cfg["seed"])
    nB, nG, nD = cfg["n_buses"], cfg["n_gens"], cfg["n_loads"]
    nL_req, nT = cfg["n_lines"], cfg["n_timesteps"]

    assert nB >= 2, "need at least 2 buses"
    assert nG >= 1, "need at least 1 generator"
    assert nD >= 1, "need at least 1 load"
    assert nT >= 1, "need at least 1 timestep"
    assert nL_req >= nB - 1, "n_lines must be >= n_buses - 1 for connectivity"

    # --- Buses and time index ---
    B = [f"b{i}" for i in range(nB)]
    T = list(range(nT))

    # --- Network: random spanning tree + extra redundant edges ---
    edges: list[tuple[str, str]] = []
    perm = list(B)
    rng.shuffle(perm)
    for i in range(1, nB):
        a = perm[i]
        b = perm[rng.randrange(i)]
        edges.append((a, b))
    used = {frozenset(e) for e in edges}
    attempts = 0
    while len(edges) < nL_req and attempts < 50 * nL_req:
        a, b = rng.sample(B, 2)
        k = frozenset((a, b))
        if k not in used:
            used.add(k)
            edges.append((a, b))
        attempts += 1

    L = [f"l{i}" for i in range(len(edges))]
    line_from = {L[i]: edges[i][0] for i in range(len(edges))}
    line_to = {L[i]: edges[i][1] for i in range(len(edges))}

    # --- Load profile: smooth daily-like shape ---
    # Peak around 70% into the horizon (evening-ish for nT=24)
    peak_frac = 0.70
    shape = []
    for t in range(nT):
        phase = 2 * math.pi * (t - peak_frac * nT) / max(nT, 1)
        shape.append(0.7 + 0.3 * math.cos(phase))   # in [0.4, 1.0]

    D = [f"d{i}" for i in range(nD)]
    load_bus = {d: rng.choice(B) for d in D}
    peak_per_load = [rng.uniform(30, 90) for _ in D]       # MW
    total_peak = sum(peak_per_load) * max(shape)
    demand = {(D[i], t): peak_per_load[i] * shape[t] for i in range(nD) for t in T}

    # --- Generators: mix of base / mid / peaker ---
    G = [f"g{i}" for i in range(nG)]
    gen_bus = {g: rng.choice(B) for g in G}

    types: list[str] = []
    for _ in range(nG):
        r = rng.random()
        types.append("base" if r < 0.4 else ("mid" if r < 0.8 else "peak"))
    # Force at least one fast unit (peaker or mid) for feasibility
    if all(t == "base" for t in types):
        types[-1] = "peak"

    # Pick raw capacities per type, then scale to ~1.6x peak load
    raw_caps = []
    for t in types:
        if t == "base":
            raw_caps.append(rng.uniform(150, 300))
        elif t == "mid":
            raw_caps.append(rng.uniform(80, 180))
        else:
            raw_caps.append(rng.uniform(40, 120))
    scale = (1.6 * total_peak) / max(sum(raw_caps), 1e-6)

    Pmin, Pmax = {}, {}
    RU, RD, SU, SD = {}, {}, {}, {}
    UT, DT = {}, {}
    c_fuel, c_noload, c_startup, c_shutdown = {}, {}, {}, {}
    for i, g in enumerate(G):
        t = types[i]
        Pmax[g] = raw_caps[i] * scale
        if t == "base":
            Pmin[g] = 0.30 * Pmax[g]
            ramp = 0.25 * Pmax[g]
            UT[g], DT[g] = 6, 6
            c_fuel[g] = rng.uniform(18, 30)
            c_noload[g] = rng.uniform(300, 600)
            c_startup[g] = rng.uniform(5_000, 15_000)
        elif t == "mid":
            Pmin[g] = 0.20 * Pmax[g]
            ramp = 0.50 * Pmax[g]
            UT[g], DT[g] = 3, 3
            c_fuel[g] = rng.uniform(30, 45)
            c_noload[g] = rng.uniform(150, 400)
            c_startup[g] = rng.uniform(1_500, 5_000)
        else:  # peaker
            Pmin[g] = 0.10 * Pmax[g]
            ramp = Pmax[g]
            UT[g], DT[g] = 1, 1
            c_fuel[g] = rng.uniform(55, 90)
            c_noload[g] = rng.uniform(50, 150)
            c_startup[g] = rng.uniform(200, 1_500)
        RU[g], RD[g] = ramp, ramp
        SU[g] = max(Pmin[g], ramp)
        SD[g] = max(Pmin[g], ramp)
        c_shutdown[g] = 0.1 * c_startup[g]

    # --- Initial conditions: base units committed at Pmin, others off ---
    u0, p0, U0, D0 = {}, {}, {}, {}
    for i, g in enumerate(G):
        if types[i] == "base":
            u0[g], p0[g] = 1, Pmin[g]
            U0[g], D0[g] = UT[g], 0
        else:
            u0[g], p0[g] = 0, 0.0
            U0[g], D0[g] = 0, DT[g]

    # --- Line parameters ---
    x_line = {l: rng.uniform(0.03, 0.12) for l in L}   # pu reactance
    f_max = {l: rng.uniform(80, 200) for l in L}       # MW rating

    return dict(
        T=T, B=B, G=G, L=L, D=D,
        gen_bus=gen_bus, load_bus=load_bus,
        line_from=line_from, line_to=line_to,
        demand=demand,
        Pmin=Pmin, Pmax=Pmax, RU=RU, RD=RD, SU=SU, SD=SD,
        UT=UT, DT=DT,
        c_fuel=c_fuel, c_noload=c_noload,
        c_startup=c_startup, c_shutdown=c_shutdown,
        u0=u0, p0=p0, U0=U0, D0=D0,
        x_line=x_line, f_max=f_max,
        base_mva=100.0, ref_bus=B[0],
        VOLL=cfg["voll"],
        _gen_types=types,   # informational (underscore = not used by solver)
    )


# =============================================================================
# Reporting
# =============================================================================
def summarize(data: dict, result: dict | None) -> None:
    if result is None:
        print("No feasible solution found.")
        return

    T, G, B = data["T"], data["G"], data["B"]
    fuel = sum(data["c_fuel"][g] * result["p"][g, t] for g in G for t in T)
    nolo = sum(data["c_noload"][g] * result["u"][g, t] for g in G for t in T)
    sup = sum(data["c_startup"][g] * result["v"][g, t] for g in G for t in T)
    sdn = sum(data["c_shutdown"][g] * result["w"][g, t] for g in G for t in T)
    shed_mwh = sum(result["shed"][b, t] for b in B for t in T)

    print()
    print(f"{'='*52}")
    print(f"  Objective : ${result['obj']:>14,.2f}")
    print(f"  MIP gap   : {result['mipgap']*100:>13.4f}%")
    print(f"  Runtime   : {result['runtime']:>13.2f} s")
    print(f"{'='*52}")
    print(f"    fuel       ${fuel:>14,.2f}")
    print(f"    no-load    ${nolo:>14,.2f}")
    print(f"    startup    ${sup:>14,.2f}")
    print(f"    shutdown   ${sdn:>14,.2f}")
    print(f"    load shed  {shed_mwh:>14,.2f} MWh  (penalty ${data['VOLL']*shed_mwh:,.2f})")
    print(f"{'='*52}")

    # Commitment schedule
    print("\nCommitment (1=on, 0=off):")
    _print_schedule(G, T, lambda g, t: int(round(result["u"][g, t])),
                    types=data.get("_gen_types"))

    # Dispatch schedule
    print("\nDispatch (MW):")
    _print_schedule(G, T, lambda g, t: result["p"][g, t],
                    types=data.get("_gen_types"), fmt="{:>6.1f}")


def _print_schedule(G, T, cell, types=None, fmt="{:>3}"):
    label_width = max(len(str(g)) for g in G) + 4
    header = " " * label_width + " ".join(fmt.format(t) for t in T)
    print(header)
    print("-" * len(header))
    for i, g in enumerate(G):
        tag = f"({types[i]})" if types else ""
        left = f"{g}{tag}".ljust(label_width)
        row = left + " ".join(fmt.format(cell(g, t)) for t in T)
        print(row)


# =============================================================================
# Main
# =============================================================================
def main() -> None:
    t0 = time.time()
    data = build_synthetic_data(CONFIG)
    print(f"Built synthetic data in {time.time()-t0:.2f}s:")
    print(f"  buses={len(data['B'])}  gens={len(data['G'])}  "
          f"lines={len(data['L'])}  loads={len(data['D'])}  T={len(data['T'])}")
    total_cap = sum(data["Pmax"].values())
    peak_load = max(
        sum(data["demand"][d, t] for d in data["D"])
        for t in data["T"]
    )
    print(f"  total Pmax={total_cap:.0f} MW   peak load={peak_load:.0f} MW   "
          f"reserve margin={(total_cap/peak_load - 1)*100:.1f}%")

    t0 = time.time()
    model = build_uc_model(data)
    print(f"\nBuilt model in {time.time()-t0:.2f}s "
          f"(vars={model.NumVars:,}, bin={model.NumBinVars:,}, "
          f"constrs={model.NumConstrs:,})")

    solve_uc_model(
        model,
        mip_gap=CONFIG["mip_gap"],
        time_limit=CONFIG["time_limit"],
        threads=CONFIG["threads"],
        log_to_console=CONFIG["solver_log"],
    )

    result = extract_results(model)
    summarize(data, result)


if __name__ == "__main__":
    main()
