# TIDE v3.3
**Background Implementation Guide (Density-Screened Relaxation)**

**Purpose:** Provide a formal and simulation-ready implementation of the TIDE v3.3 background equation of state for Sentinel production runs.

---

## Executive Summary

TIDE v3.3 replaces the constant relaxation timescale used in v3.2.1 with a density-screened timescale. This removes early-time rigidity while preserving late-time flexibility.

Core implementation equation:

$$
w(a) = -1 - \frac{A_{vac}\,a^{-1.5}}{\sqrt{1 + \alpha a^{-3}}}
$$

where:

$$
A_{vac} \equiv \kappa\,\tau_{vac}\,H_0,
\qquad
\alpha \equiv \beta\,\rho_{m,0}.
$$

This is the only expression required at background level.

---

## 1. Physical Rationale

In v3.2.1, a constant global relaxation time produced:

$$
w(a) = -1 - \kappa(\tau H_0)a^{-1.5}.
$$

That form improves late-time expansion fits but can be too rigid at early times. TIDE v3.3 introduces a density-dependent relaxation law:

$$
\tau(\rho) = \frac{\tau_{vac}}{\sqrt{1 + \beta\rho(a)}}.
$$

For homogeneous cosmology, using $\bar\rho(a)=\rho_{m,0}a^{-3}$ and $\alpha=\beta\rho_{m,0}$:

$$
\tau(a) = \frac{\tau_{vac}}{\sqrt{1 + \alpha a^{-3}}}.
$$

Substituting into the EoS yields the production form stated above.

---

## 2. Asymptotic Behavior (for Diagnostics)

**Early Universe ($a\to 0$):**

$$
\sqrt{1+\alpha a^{-3}}\sim \sqrt{\alpha}\,a^{-1.5}
$$

so $a^{-1.5}$ cancels and the correction becomes finite/suppressed; effectively $w_{TIDE}\to -1$ in the high-density regime.

**Late Universe ($a\to 1$):**

$$
\tau(a)\to \tau_{vac}
$$

and the torsional lag is fully active, reproducing the intended late-time behavior.

---

## 3. Sentinel Implementation Specification

### 3.1 Required Parameters

Use the following sampled parameters:

1. **$A_{vac}$** (effective vacuum amplitude)
2. **$\alpha$** (density coupling)

Keep standard cosmological parameters free as in baseline Sentinel runs.

### 3.2 Recommended Priors (practical start)

- $A_{vac}$: broad positive prior (e.g., uniform around previous best-fit scale)
- $\alpha$: non-negative prior (e.g., $\alpha\ge 0$)

Note: exact bounds can be tightened after a short pilot chain.

### 3.3 Drop-in EoS Function

Use this directly in the background module:

```text
w(a) = -1 - (A_vac * a^(-1.5)) / sqrt(1 + alpha * a^(-3))
```

Numerical safeguards:

- enforce `a > 0`
- enforce `1 + alpha * a^(-3) > 0`
- use stable power/sqrt evaluation at very small `a`

---

## 4. Minimal Validation Protocol (before full production)

Run these checks in order:

1. **Background sanity**
   - Verify smooth $w(a)$ over target range.
   - Confirm no NaN/Inf in $w(a)$ and $H(z)$.

2. **Asymptotic check**
   - High-$z$: confirm approach to near-$\Lambda$CDM behavior.
   - Low-$z$: confirm activation of torsional correction.

3. **Likelihood smoke test**
   - Short chain with CC+BAO+SN subset.
   - Confirm parameter mixing and finite acceptance.

4. **Full run readiness**
   - Freeze tested module.
   - Launch full Sentinel production with same data vector used in v3.2.1 comparison.

---

## 5. Interpretation Notes for the Team

- The ratio between vacuum and cluster relaxation scales is expected from density screening, not from parameter inconsistency.
- At background level, v3.3 adds flexibility through a physically motivated density law, not via ad-hoc smoothing terms.
- The implementation remains low-dimensional (two effective parameters: $A_{vac}$ and $\alpha$).

---

## 6. Final Production Equation (Reference)

$$
\boxed{w(a) = -1 - \frac{A_{vac}\,a^{-1.5}}{\sqrt{1 + \alpha a^{-3}}}}
$$

This is the recommended v3.3 EoS for Sentinel background production.
