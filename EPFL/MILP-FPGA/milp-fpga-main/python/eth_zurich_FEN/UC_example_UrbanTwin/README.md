# Unit Commitment MILP with DC Power Flow

This repository contains a compact Python implementation of a thermal unit commitment (UC) mixed-integer linear program using Gurobi. The model schedules generator commitment and dispatch over a multi-period horizon while enforcing generator operating constraints, DC network constraints, and nodal power balance.

## Files

- `unit_commitment.py` — core UC model builder, solver wrapper, result extraction, and data validation.
- `run_example.py` — runnable synthetic test case generator and console reporting script.
- `requirements.txt` — Python package dependency list.

## Model summary

The optimization model is a mixed-integer linear program with a lossless DC power-flow network representation.

### Decision variables

- `u[g,t]`: binary unit commitment status.
- `v[g,t]`: binary startup indicator.
- `w[g,t]`: binary shutdown indicator.
- `p[g,t]`: generator dispatch in MW.
- `theta[b,t]`: bus voltage angle.
- `f[l,t]`: transmission line flow in MW.
- `shed[b,t]`: load shed in MW.

### Objective

Minimize total operating cost:

- fuel cost,
- no-load cost,
- startup cost,
- shutdown cost,
- value-of-lost-load penalty for load shedding.

### Main constraints

- startup and shutdown state-transition logic,
- mutual exclusivity of startup and shutdown in the same period,
- generator minimum and maximum output limits,
- ramp-up and ramp-down limits,
- minimum up-time and down-time logic,
- DC power-flow equations,
- transmission flow limits,
- nodal power balance,
- upper bound on load shedding by local demand.

## Installation

Create and activate a virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
```

## Gurobi requirement

This project requires `gurobipy`, which also requires a working Gurobi installation and license. Confirm that Gurobi is available before running the example:

```bash
python - <<'PY'
import gurobipy as gp
print(gp.gurobi.version())
PY
```

## Run the example

```bash
python run_example.py
```

The example script generates a random connected network, synthetic load profiles, and a mix of base, mid-merit, and peaker generators. It then builds and solves the UC model and prints:

- model size,
- objective value,
- MIP gap,
- runtime,
- cost breakdown,
- total load shed,
- commitment schedule,
- dispatch schedule.

## Configuration

Edit the `CONFIG` dictionary in `run_example.py` to change the synthetic instance size or solver behavior:

```python
CONFIG = {
    "n_buses": 50,
    "n_gens": 40,
    "n_loads": 45,
    "n_lines": 60,
    "n_timesteps": 168,
    "seed": 42,
    "mip_gap": 1e-3,
    "time_limit": None,
    "threads": None,
    "solver_log": True,
    "voll": 10000.0,
}
```

For faster smoke tests, reduce the instance size, for example:

```python
CONFIG.update({
    "n_buses": 5,
    "n_gens": 4,
    "n_loads": 5,
    "n_lines": 6,
    "n_timesteps": 24,
})
```

## Using your own data

Call `build_uc_model(data)` with a dictionary containing the required sets, mappings, generator parameters, initial conditions, line parameters, demand, and system parameters.

Minimal workflow:

```python
from unit_commitment import build_uc_model, solve_uc_model, extract_results

model = build_uc_model(data)
solve_uc_model(model, mip_gap=1e-3, time_limit=300, log_to_console=True)
result = extract_results(model)
```

The `data` dictionary must include these keys:

```text
T, B, G, L,
gen_bus, line_from, line_to,
Pmin, Pmax, RU, RD, SU, SD,
UT, DT,
c_fuel, c_noload, c_startup, c_shutdown,
u0, p0, U0, D0,
x_line, f_max,
base_mva, ref_bus,
demand
```

Optional keys:

- `D`: load labels. If supplied, demand is indexed by `(load, time)` and `load_bus` is required.
- `load_bus`: maps each load to a bus.
- `VOLL`: load-shed penalty in $/MWh. Defaults to `10000.0` if omitted.

Demand can be supplied in either of two forms:

1. Load-indexed demand, when `D` is present:

```python
demand = {(d, t): mw_value for d in D for t in T}
load_bus = {d: b for d in D}
```

2. Bus-indexed demand, when `D` is omitted or `None`:

```python
demand = {(b, t): mw_value for b in B for t in T}
```

## Output format

`extract_results(model)` returns `None` if no incumbent solution is available. Otherwise, it returns a dictionary containing:

- variable values: `u`, `v`, `w`, `p`, `theta`, `f`, `shed`,
- `obj`: objective value,
- `mipgap`: final MIP gap,
- `runtime`: solver runtime in seconds,
- `status`: Gurobi status code.

Variable dictionaries are keyed by the same tuple keys used in the model, such as `(g, t)`, `(b, t)`, or `(l, t)`.

## Notes and limitations

- The network model is lossless DC power flow, not AC power flow.
- Commitment and dispatch periods are treated as uniform time steps.
- Startup and shutdown costs are linear event costs.
- No reserve requirements, fuel constraints, emissions constraints, storage, renewable curtailment, or multi-segment heat-rate curves are included.
- Load shedding is allowed and penalized, which helps keep the model feasible when generation or transmission is insufficient.

## Troubleshooting

### `ModuleNotFoundError: No module named 'gurobipy'`

Install dependencies:

```bash
pip install -r requirements.txt
```

### Gurobi license error

Install or activate a valid Gurobi license. For local installations, verify Gurobi outside this project first.

### Model is slow

Reduce `n_timesteps`, `n_gens`, or `n_buses`; increase `mip_gap`; set a `time_limit`; or use more solver threads.

### No feasible solution found

The model includes load shedding, so complete infeasibility is more likely caused by inconsistent input data, invalid initial conditions, invalid line or generator parameters, or a missing required key.
