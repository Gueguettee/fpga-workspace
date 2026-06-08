"""
Unit Commitment (UC) problem builder using gurobipy.

Formulation
-----------
Mixed-integer linear program for thermal unit commitment with a lossless
DC power-flow network model.

  Variables
    u[g,t] in {0,1}   commitment (on/off)
    v[g,t] in {0,1}   startup indicator
    w[g,t] in {0,1}   shutdown indicator
    p[g,t]  >= 0      generation (MW)
    theta[b,t]        bus voltage angle (rad), theta[ref] = 0
    f[l,t]            line flow (MW), -fmax <= f <= fmax
    shed[b,t] >= 0    load shed (MW), penalized at VOLL

  Objective
    min  sum_{g,t} [ c_fuel[g]*p + c_noload[g]*u + c_startup[g]*v + c_shutdown[g]*w ]
       + sum_{b,t} VOLL * shed[b,t]

  Constraints
    u[t] - u[t-1] = v[t] - w[t]                  (startup/shutdown logic)
    v[t] + w[t] <= 1                             (can't both in same period)
    Pmin*u <= p <= Pmax*u                        (output bounds, coupled to commitment)
    p[t] - p[t-1] <= RU*u[t-1] + SU*v[t]         (ramp up, relaxed on startup)
    p[t-1] - p[t] <= RD*u[t]   + SD*w[t]         (ramp down, relaxed on shutdown)
    sum_{tau=t-UT+1}^{t} v[tau] <= u[t]          (min up time, Rajan-Takriti)
    sum_{tau=t-DT+1}^{t} w[tau] <= 1 - u[t]      (min down time)
    f[l] = (base_mva / x[l]) * (theta_from - theta_to)   (DC flow)
    bus power balance:  generation + inflow + shed = demand + outflow

Data schema
-----------
`data` is a dict with the following keys:

  # Sets (lists of hashable labels)
  T, B, G, L           periods, buses, generators, lines
  D                    loads (optional; see `demand` below)

  # Topology / mappings
  gen_bus     : {g: bus}
  line_from   : {l: bus}
  line_to     : {l: bus}
  load_bus    : {d: bus}               only if 'D' provided

  # Time series
  demand      : {(d, t): MW}  if 'D' provided
             OR {(b, t): MW}  (bus-indexed) otherwise

  # Generator parameters (dicts keyed by g)
  Pmin, Pmax                           MW
  RU, RD                               MW per period
  SU, SD                               MW, startup/shutdown ramp (>= Pmin)
  UT, DT                               periods (int), minimum up / down time
  c_fuel                               $/MWh
  c_noload                             $ per period when committed
  c_startup, c_shutdown                $ per event

  # Generator initial conditions (dicts keyed by g)
  u0  : 0/1           state before horizon start
  p0  : MW            dispatch at t=-1
  U0  : periods       how long it's been up  (relevant iff u0 == 1)
  D0  : periods       how long it's been down (relevant iff u0 == 0)

  # Line parameters
  x_line  : {l: reactance (pu)}
  f_max   : {l: MW}

  # System parameters
  base_mva  : float (MVA base for pu -> MW conversion)
  ref_bus   : a bus in B
  VOLL      : $/MWh, load-shed penalty (default 10000)
"""

from __future__ import annotations

import gurobipy as gp
from gurobipy import GRB


# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------
def build_uc_model(data: dict, name: str = "UC") -> gp.Model:
    """Construct the UC MILP and return a Gurobi model.

    Variable and data handles are attached to the model via attributes
    `_vars` and `_data` for convenience.
    """
    _validate_data(data)
    m = gp.Model(name)

    T = data["T"]
    B = data["B"]
    G = data["G"]
    L = data["L"]
    has_D = "D" in data and data["D"] is not None

    # ---- Variables -------------------------------------------------------
    u = m.addVars(G, T, vtype=GRB.BINARY, name="u")
    v = m.addVars(G, T, vtype=GRB.BINARY, name="v")
    w = m.addVars(G, T, vtype=GRB.BINARY, name="w")
    p = m.addVars(G, T, lb=0.0, name="p")
    theta = m.addVars(B, T, lb=-GRB.INFINITY, name="theta")
    f = m.addVars(L, T, lb=-GRB.INFINITY, name="f")
    shed = m.addVars(B, T, lb=0.0, name="shed")

    m._vars = dict(u=u, v=v, w=w, p=p, theta=theta, f=f, shed=shed)
    m._data = data

    # ---- Objective -------------------------------------------------------
    VOLL = data.get("VOLL", 10000.0)
    m.setObjective(
        gp.quicksum(
            data["c_fuel"][g] * p[g, t]
            + data["c_noload"][g] * u[g, t]
            + data["c_startup"][g] * v[g, t]
            + data["c_shutdown"][g] * w[g, t]
            for g in G
            for t in T
        )
        + gp.quicksum(VOLL * shed[b, t] for b in B for t in T),
        GRB.MINIMIZE,
    )

    # ---- Constraints -----------------------------------------------------
    _add_commitment_logic(m, data)
    _add_generation_limits(m, data)
    _add_ramp_constraints(m, data)
    _add_min_up_down(m, data)
    _add_dc_power_flow(m, data)
    _add_power_balance(m, data, has_D=has_D)

    return m


# -----------------------------------------------------------------------------
# Constraint groups
# -----------------------------------------------------------------------------
def _add_commitment_logic(m: gp.Model, data: dict) -> None:
    u, v, w = m._vars["u"], m._vars["v"], m._vars["w"]
    T, G = data["T"], data["G"]
    for g in G:
        u0g = data["u0"][g]
        for i, t in enumerate(T):
            prev = u[g, T[i - 1]] if i > 0 else u0g
            m.addConstr(u[g, t] - prev == v[g, t] - w[g, t], name=f"ss[{g},{t}]")
            m.addConstr(v[g, t] + w[g, t] <= 1, name=f"swex[{g},{t}]")


def _add_generation_limits(m: gp.Model, data: dict) -> None:
    u, p = m._vars["u"], m._vars["p"]
    for g in data["G"]:
        for t in data["T"]:
            m.addConstr(p[g, t] >= data["Pmin"][g] * u[g, t], name=f"pmin[{g},{t}]")
            m.addConstr(p[g, t] <= data["Pmax"][g] * u[g, t], name=f"pmax[{g},{t}]")


def _add_ramp_constraints(m: gp.Model, data: dict) -> None:
    u, v, w, p = m._vars["u"], m._vars["v"], m._vars["w"], m._vars["p"]
    T, G = data["T"], data["G"]
    for g in G:
        RU, RD = data["RU"][g], data["RD"][g]
        SU, SD = data["SU"][g], data["SD"][g]
        for i, t in enumerate(T):
            if i == 0:
                p_prev, u_prev = data["p0"][g], data["u0"][g]
            else:
                p_prev, u_prev = p[g, T[i - 1]], u[g, T[i - 1]]
            m.addConstr(p[g, t] - p_prev <= RU * u_prev + SU * v[g, t],
                        name=f"rup[{g},{t}]")
            m.addConstr(p_prev - p[g, t] <= RD * u[g, t] + SD * w[g, t],
                        name=f"rdn[{g},{t}]")


def _add_min_up_down(m: gp.Model, data: dict) -> None:
    u, v, w = m._vars["u"], m._vars["v"], m._vars["w"]
    T, G = data["T"], data["G"]
    for g in G:
        UT = int(data["UT"][g])
        DT = int(data["DT"][g])
        u0g = data["u0"][g]
        U0 = data["U0"][g]
        D0 = data["D0"][g]

        # ---- Initial-condition enforcement ----
        must_on = max(0, UT - U0) if u0g == 1 else 0
        must_off = max(0, DT - D0) if u0g == 0 else 0
        for i, t in enumerate(T):
            if i < must_on:
                m.addConstr(u[g, t] == 1, name=f"mustOn[{g},{t}]")
            if i < must_off:
                m.addConstr(u[g, t] == 0, name=f"mustOff[{g},{t}]")

        # ---- Rajan-Takriti window cuts ----
        if UT > 1:
            for i, t in enumerate(T):
                lo = max(0, i - UT + 1)
                m.addConstr(
                    gp.quicksum(v[g, T[k]] for k in range(lo, i + 1)) <= u[g, t],
                    name=f"minup[{g},{t}]",
                )
        if DT > 1:
            for i, t in enumerate(T):
                lo = max(0, i - DT + 1)
                m.addConstr(
                    gp.quicksum(w[g, T[k]] for k in range(lo, i + 1)) <= 1 - u[g, t],
                    name=f"mindn[{g},{t}]",
                )


def _add_dc_power_flow(m: gp.Model, data: dict) -> None:
    theta, f = m._vars["theta"], m._vars["f"]
    T, L = data["T"], data["L"]
    ref_bus = data["ref_bus"]
    base_mva = data["base_mva"]

    for t in T:
        m.addConstr(theta[ref_bus, t] == 0, name=f"ref[{t}]")

    for l in L:
        b_from, b_to = data["line_from"][l], data["line_to"][l]
        b_l = base_mva / data["x_line"][l]
        fmax_l = data["f_max"][l]
        for t in T:
            m.addConstr(f[l, t] == b_l * (theta[b_from, t] - theta[b_to, t]),
                        name=f"dcf[{l},{t}]")
            m.addConstr(f[l, t] <= fmax_l, name=f"fup[{l},{t}]")
            m.addConstr(f[l, t] >= -fmax_l, name=f"fdn[{l},{t}]")


def _add_power_balance(m: gp.Model, data: dict, has_D: bool) -> None:
    p, f, shed = m._vars["p"], m._vars["f"], m._vars["shed"]
    T, B, G, L = data["T"], data["B"], data["G"], data["L"]
    gen_bus = data["gen_bus"]

    # Pre-index for speed
    gens_at = {b: [] for b in B}
    for g in G:
        gens_at[gen_bus[g]].append(g)
    lines_out = {b: [] for b in B}
    lines_in = {b: [] for b in B}
    for l in L:
        lines_out[data["line_from"][l]].append(l)
        lines_in[data["line_to"][l]].append(l)

    if has_D:
        loads_at = {b: [] for b in B}
        for d in data["D"]:
            loads_at[data["load_bus"][d]].append(d)

    for b in B:
        for t in T:
            if has_D:
                dem_bt = sum(data["demand"][d, t] for d in loads_at[b])
            else:
                dem_bt = data["demand"].get((b, t), 0.0)
            m.addConstr(
                gp.quicksum(p[g, t] for g in gens_at[b])
                + gp.quicksum(f[l, t] for l in lines_in[b])
                + shed[b, t]
                - gp.quicksum(f[l, t] for l in lines_out[b])
                == dem_bt,
                name=f"bal[{b},{t}]",
            )
            # Can't shed more than the local demand
            m.addConstr(shed[b, t] <= dem_bt, name=f"shedub[{b},{t}]")


# -----------------------------------------------------------------------------
# Solve / extract
# -----------------------------------------------------------------------------
def solve_uc_model(
    model: gp.Model,
    mip_gap: float = 1e-3,
    time_limit: float | None = None,
    threads: int | None = None,
    log_to_console: bool = True,
) -> gp.Model:
    """Optimize in place. Returns the same model for chaining."""
    model.Params.MIPGap = mip_gap
    if time_limit is not None:
        model.Params.TimeLimit = time_limit
    if threads is not None:
        model.Params.Threads = threads
    model.Params.OutputFlag = 1 if log_to_console else 0
    model.optimize()
    return model


def extract_results(model: gp.Model) -> dict | None:
    """Pull variable values into plain dicts keyed like the Gurobi tupledicts."""
    if model.Status not in (GRB.OPTIMAL, GRB.SUBOPTIMAL, GRB.TIME_LIMIT):
        return None
    if model.SolCount == 0:
        return None
    result: dict = {}
    for name, var in model._vars.items():
        result[name] = {k: v.X for k, v in var.items()}
    result["obj"] = model.ObjVal
    result["mipgap"] = model.MIPGap
    result["runtime"] = model.Runtime
    result["status"] = int(model.Status)
    return result


# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------
def _validate_data(d: dict) -> None:
    required = [
        "T", "B", "G", "L",
        "gen_bus", "line_from", "line_to",
        "Pmin", "Pmax", "RU", "RD", "SU", "SD",
        "UT", "DT",
        "c_fuel", "c_noload", "c_startup", "c_shutdown",
        "u0", "p0", "U0", "D0",
        "x_line", "f_max",
        "base_mva", "ref_bus",
        "demand",
    ]
    missing = [k for k in required if k not in d]
    if missing:
        raise ValueError(f"Missing data keys: {missing}")
    if d["ref_bus"] not in d["B"]:
        raise ValueError("ref_bus must be in B")
    for g in d["G"]:
        if d["Pmin"][g] > d["Pmax"][g]:
            raise ValueError(f"Pmin>Pmax for generator {g}")
        if d["u0"][g] not in (0, 1):
            raise ValueError(f"u0[{g}] must be 0 or 1")
        if d["SU"][g] < d["Pmin"][g] or d["SD"][g] < d["Pmin"][g]:
            # Not strictly a bug, but the unit will never be able to start/stop.
            raise ValueError(
                f"SU/SD for {g} must be >= Pmin to allow startup/shutdown "
                f"(got SU={d['SU'][g]}, SD={d['SD'][g]}, Pmin={d['Pmin'][g]})"
            )
