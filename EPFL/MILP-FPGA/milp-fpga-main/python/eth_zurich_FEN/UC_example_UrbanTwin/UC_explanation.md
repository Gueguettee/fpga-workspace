# Unit Commitment Problem – Overview and Formulation

## 1. What is the Unit Commitment (UC) Problem?

The Unit Commitment (UC) problem is a fundamental optimization problem in power systems. It determines:

- **Which generators should be ON or OFF**
- **How much power each generator should produce**

over a given time horizon (e.g., 24 hours, 168 hours), while satisfying demand and operational constraints.

### Key Objectives:
- Meet electricity demand at every time step
- Minimize total operational cost
- Respect physical and operational limits of generators and the network

---

## 2. Why is UC Important?

Electricity cannot be easily stored at scale, so supply must continuously match demand. The UC problem ensures:

- Reliable system operation
- Cost efficiency
- Feasible generator schedules

It is widely used by system operators (e.g., ISOs/TSOs).

---

## 3. Decision Variables

In the provided implementation, the UC problem includes:

### Binary Variables
- **u[g,t]**: Generator on/off status
- **v[g,t]**: Startup indicator
- **w[g,t]**: Shutdown indicator

### Continuous Variables
- **p[g,t]**: Power generation (MW)
- **θ[b,t]**: Voltage angle at bus
- **f[l,t]**: Power flow on line
- **shed[b,t]**: Load shedding (penalized)

---

## 4. Objective Function

The goal is to minimize total cost:

- Fuel cost
- No-load (fixed running) cost
- Startup cost
- Shutdown cost
- Load shedding penalty (VOLL)

### Mathematical Form:

minimize:

Σ (fuel + no-load + startup + shutdown) + Σ (VOLL × load shedding)

---

## 5. Constraints

### 5.1 Commitment Logic
Ensures consistency between on/off states and transitions:

u[t] - u[t-1] = v[t] - w[t]

---

### 5.2 Generation Limits
A generator can only produce when it is ON:

Pmin × u ≤ p ≤ Pmax × u

---

### 5.3 Ramp Constraints
Limits how fast generators can change output:

- Ramp-up constraint
- Ramp-down constraint

Startup/shutdown relaxations are included.

---

### 5.4 Minimum Up/Down Time
Generators must remain ON or OFF for a minimum duration after switching.

---

### 5.5 Power Flow (DC Approximation)

The model uses a **DC power flow approximation**:

f[l,t] = (base_mva / x[l]) × (θ_from - θ_to)

Assumptions:
- Lossless network
- Linearized physics
- Voltage magnitudes ignored

---

### 5.6 Power Balance

At each bus and time:

generation + inflow + shedding = demand + outflow

---

### 5.7 Load Shedding Constraint

Load shedding is allowed but penalized heavily:

shed ≤ demand

---

## 6. Key Modeling Choices in This Implementation

This formulation uses:

- **Mixed-Integer Linear Programming (MILP)**
- **Gurobi solver**
- **DC power flow (not AC)**
- **Rajan–Takriti formulation** for minimum up/down time

### Advantages:
- Tractable for medium-to-large systems
- Industry-standard formulation
- Captures key operational constraints

### Limitations:
- No AC power flow (voltage/reactive power ignored)
- No stochasticity (deterministic demand)
- No unit commitment uncertainty or renewables variability

---

## 7. Summary

The UC problem here is a realistic but computationally manageable model that balances:

- Economic efficiency
- Physical feasibility
- Computational tractability

It is suitable for:
- Research
- Prototyping
- Medium-scale system studies

---

## 8. References (Suggested Reading)

- Wood & Wollenberg – *Power Generation, Operation, and Control*
- Carrion & Arroyo (2006) – UC formulation improvements
- Rajan & Takriti (2005) – Minimum up/down time modeling

