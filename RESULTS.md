# Simulation Results

This document describes the simulation results and implementation details
of the mass-spring-damper system modeled in MATLAB and Simulink.

---

## MATLAB Simulation — Command Window Output

Both simulations — linear and nonlinear damping — were executed using the ODE23 solver
with 300 001 data points over a 30-second time span.

**Numerical results:**

| Quantity              | Value         |
| --------------------- | ------------- |
| Natural frequency ωₙ  | 25.82 rad/s   |
| Damping ratio ζ       | 0.0726        |
| Peak displacement (linear)    | 8.15 mm |
| Peak displacement (nonlinear) | 5.56 mm |
| Steady-state displacement     | 2.775 mm (both cases) |
| Amplitude reduction           | 31.8 %  |

![MATLAB Command Window output](results/Masseschwinger_Konstant.png)

---

## MATLAB Plots

The following four plots summarize the simulation results:

![All simulation plots](results/Vergleich.png)

**Top left — Excitation force F(t):**
Three distinct phases are clearly visible: no excitation before t = 1 s,
sinusoidal excitation between t = 1 s and t = 3 s (peak 1111 N),
and constant force of 555.5 N after t = 3 s.

**Top right — Linear damping response:**
The system oscillates significantly after the excitation phase.
The transient response lasts approximately 15–20 seconds before
converging to the steady-state value of 2.775 mm.

**Bottom left — Nonlinear damping response:**
The system settles much faster — within approximately 4 seconds.
The nonlinear Lookup Table provides stronger damping at high velocities,
which suppresses large oscillations effectively.

**Bottom right — Direct comparison:**
Blue curve: linear damping. Red curve: nonlinear damping.
Both curves converge to the same steady-state value of 2.777 mm.
The amplitude reduction of 31.8% is clearly visible.

---

## Simulink Implementation

### Model 1 — Linear Damping (`Masseschwinger_Konstant.slx`)

![Simulink linear model](results/Masseschwinger_Konstant.png)

The model implements the state-space form of the second-order ODE directly.

**Block structure (left to right):**

| Block | Function | Value |
|-------|----------|-------|
| `F_t` | MATLAB Function — computes F(t) | — |
| Sum | Computes net force: F(t) − D·z' − C·z | +, −, − |
| `Gain_1M` | Divides by mass M | 1/300 |
| `Int_dz` | Integrates z'' → z' | IC = 0 |
| `Int_z` | Integrates z' → z | IC = 0 |
| `Gain_C` | Spring feedback: C·z | 200 000 |
| `Gain_D` | Damper feedback: D·z' | 1125 |
| Scope | Visualizes z(t) | — |

---

### Model 2 — Nonlinear Damping (`Masseschwinger_Variabel.slx`)

![Simulink nonlinear model](results/Masseschwinger_Variabel.png)

The structure is identical to Model 1, with one key difference:
the constant `Gain_D` block is replaced by a **1-D Lookup Table** (`LUT_D`).

**Lookup Table block parameters:**
- Input: instantaneous velocity z'
- Output: nonlinear damping force F_D
- Interpolation method: linear
- Data source: provided by course instructor

![LUT block parameters](results/Masseschwinger_Variabel2.png)

The Lookup Table breakpoints and table data entered in the block dialog:

| Velocity z' [m/s] | Damping force F_D [N] |
| ----------------- | --------------------- |
| −0.52 | −433 |
| −0.40 | −400 |
| −0.20 | −325 |
| −0.10 | −257 |
|  0.00 |    0 |
|  0.05 |  500 |
|  0.10 |  770 |
|  0.20 |  975 |
|  0.40 | 1200 |
|  0.52 | 1300 |

---

## Comparison of Results

![Comparison](results/Vergleich.png)

| Metric                    | Linear Damping | Nonlinear Damping |
| ------------------------- | -------------- | ----------------- |
| Peak displacement         | 8.15 mm        | 5.56 mm           |
| Steady-state displacement | 2.775 mm       | 2.775 mm          |
| Settling time             | ~20 s          | ~4 s              |
| Amplitude reduction       | —              | **31.8 %**        |

**Key observation:**
The steady-state displacement is identical in both cases because it depends
only on the static force and spring stiffness:

```
z_ss = F_ss / C = 555.5 / 200 000 = 2.775 mm
```

This value is independent of the damping coefficient D.

---

## Conclusion

The nonlinear damping model based on a 1-D Lookup Table reduces the peak displacement
by **31.8%** and decreases the settling time from approximately 20 s to 4 s,
while maintaining the same steady-state response.

The Lookup Table provides an effective and realistic model for nonlinear hydraulic dampers,
such as those used in automotive suspension systems.
