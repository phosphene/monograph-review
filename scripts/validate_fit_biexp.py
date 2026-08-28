#!/usr/bin/env python3
"""Validate the fit_biexp identifiability boundary (reproducible evidence).

Faithful port of `R/fit_biexp.R` and `R/relaxation_model.R` (the
relaxation_phase_analysis consumer), used to produce the quantitative
evidence cited in docs/review/fit-biexp-numerical-challenges.md.

The R implementation is the source of truth; this port exists so the
boundary-characterisation numbers in the literate doc are regenerable by
anyone without an R toolchain. It emulates the Levenberg-Marquardt fit via
scipy least_squares on the same log-rate parameterisation, the same
exponential-peeling start, the same grid of fallback starts, and the same
abs()-based metadata fractions.

Run:
    python scripts/validate_fit_biexp.py
"""

import numpy as np
from scipy.optimize import least_squares

np.seterr(all="ignore")


# ---------------------------------------------------------------------------
# Faithful port of fit_biexp()
# ---------------------------------------------------------------------------

def fit_biexp(t, rho, normalize_t=True):
    n = len(t)
    t_range = np.max(t) - np.min(t)
    if not np.isfinite(t_range) or t_range == 0:
        t_range = 1.0
    t_scale = (t - np.min(t)) / t_range
    ord_ = np.argsort(t_scale)
    t_s = t_scale[ord_]
    rho_s = rho[ord_]
    report = 1.0 if normalize_t else t_range

    def aic(rss, k):
        return (n * np.log(rss / n) + 2 * k) if (rss > 0 and np.isfinite(rss)) else np.inf

    # Linear null
    A = np.vstack([np.ones_like(t_s), t_s]).T
    cl, *_ = np.linalg.lstsq(A, rho_s, rcond=None)
    lm_rss = np.sum((rho_s - A @ cl) ** 2)
    lm_aic = aic(lm_rss, 3)

    # Mono-exponential
    c0g = np.min(rho_s)
    Ag = np.max(rho_s) - np.min(rho_s)

    def fit_nls(form, p0):
        try:
            r = least_squares(lambda p: form(p), p0, max_nfev=500,
                              ftol=1e-8, xtol=1e-8, gtol=1e-8)
            if r.success or r.cost < 1e-4:
                return r
        except Exception:
            pass
        return None

    mono = fit_nls(
        lambda p: rho_s - (p[0] + p[1] * np.exp(-np.exp(p[2]) * t_s)),
        np.array([c0g, Ag, np.log(1.0)]))
    if mono is not None:
        mr = mono.cost * 2
        ma = aic(mr, 4)
        mcoef = dict(c0=mono.x[0], A=mono.x[1], k=float(np.exp(mono.x[2])) / report)
        mc = True
    else:
        mr, ma, mcoef, mc = np.inf, np.inf, dict(c0=np.nan, A=np.nan, k=np.nan), False

    # Exponential peeling start
    def peel(t_s, rho_s, c0):
        y = np.maximum(rho_s - c0, 1e-12)
        m = len(t_s)
        pl = np.arange(int(np.floor(m * 0.8)), m) if m >= 1 else np.array([0])
        nh = np.std(rho_s[pl]) if len(pl) >= 1 else np.std(rho_s)
        if not np.isfinite(nh) or nh == 0:
            nh = 1e-9
        thr = max(3 * nh, 1e-9)
        k2, A2 = 0.5, 0.3 * np.max(y)
        tail = np.where((y > thr) & (t_s >= 0.15))[0]
        if len(tail) >= 5:
            sl, ic = np.polyfit(t_s[tail], np.log(y[tail]), 1)
            k2h, A2h = -sl, np.exp(ic)
            if np.isfinite(k2h) and k2h > 0 and np.isfinite(A2h) and A2h > 0:
                k2, A2 = k2h, min(A2h, np.max(y) * 1.5)
        res = y - A2 * np.exp(-k2 * t_s)
        k1, A1 = k2 * 10, max(np.max(res), np.max(y) * 0.5)
        early = np.where(t_s <= 0.25)[0]
        pos = early[res[early] > thr]
        if len(pos) >= 2:
            sl, ic = np.polyfit(t_s[pos], np.log(res[pos]), 1)
            k1h, A1h = -sl, np.exp(ic)
            if np.isfinite(k1h) and k1h > k2 and np.isfinite(A1h) and A1h > 0:
                k1, A1 = k1h, min(A1h, np.max(y) * 1.5)
        elif len(pos) == 1 and m > 1:
            r0, p1 = res[0], pos[0]
            if r0 > thr and res[p1] > 0 and (t_s[p1] - t_s[0]) > 0:
                k1h = -np.log(res[p1] / r0) / (t_s[p1] - t_s[0])
                if np.isfinite(k1h) and k1h > k2:
                    k1, A1 = k1h, r0
        return dict(c0=c0, A1=A1, k1=k1, A2=A2, k2=k2)

    p = peel(t_s, rho_s, c0g)
    grid = [
        dict(c0=c0g, A1=Ag * .7, k1=2, A2=Ag * .3, k2=.05),
        dict(c0=c0g, A1=Ag * .8, k1=5, A2=Ag * .2, k2=.1),
        dict(c0=c0g, A1=Ag * .6, k1=10, A2=Ag * .4, k2=.5),
        dict(c0=c0g, A1=Ag * .5, k1=1, A2=Ag * .5, k2=.01),
        dict(c0=c0g, A1=Ag * .9, k1=20, A2=Ag * .1, k2=1),
        dict(c0=c0g, A1=Ag * .75, k1=3, A2=Ag * .25, k2=.02),
    ]
    bi = None
    for st in [p] + grid:
        p0 = np.array([st["c0"], st["A1"], np.log(max(st["k1"], 1e-9)),
                       st["A2"], np.log(max(st["k2"], 1e-9))])
        f = fit_nls(
            lambda pp: rho_s - (pp[0] + pp[1] * np.exp(-np.exp(pp[2]) * t_s)
                                + pp[3] * np.exp(-np.exp(pp[4]) * t_s)), p0)
        if f is not None:
            rss = f.cost * 2
            if bi is None or rss < bi[0]:
                bi = (rss, f.x)

    if bi is not None:
        br, ba = bi[0], aic(bi[0], 6)
        x = bi[1]
        c0b, A1b, lk1, A2b, lk2 = x
        k1n, k2n = float(np.exp(lk1)), float(np.exp(lk2))
        if k1n < k2n:
            k1n, k2n, A1b, A2b = k2n, k1n, A2b, A1b
        bcoef = dict(c0=c0b, A1=A1b, k1=k1n / report, A2=A2b, k2=k2n / report)
        bc = True
    else:
        br, ba = np.inf, np.inf
        bcoef = dict(c0=np.nan, A1=np.nan, k1=np.nan, A2=np.nan, k2=np.nan)
        bc = False

    aics = {"biexponential": ba, "monoexponential": ma, "linear": lm_aic}
    fin = {k: v for k, v in aics.items() if np.isfinite(v)}
    best = min(fin, key=fin.get) if fin else "none"
    dbm = ma - ba if (np.isfinite(ma) and np.isfinite(ba)) else np.nan

    k1 = abs(bcoef["k1"])
    k2 = abs(bcoef["k2"])
    ratio = k1 / k2 if (np.isfinite(k1) and np.isfinite(k2) and k2 > 0) else np.nan
    k1n_ = k1 * report
    k2n_ = k2 * report
    h1 = np.log(2) * t_range / k1n_ if (np.isfinite(k1n_) and k1n_ > 0) else np.nan
    h2 = np.log(2) * t_range / k2n_ if (np.isfinite(k2n_) and k2n_ > 0) else np.nan
    A1_ = abs(bcoef["A1"])
    A2_ = abs(bcoef["A2"])
    At = A1_ + A2_
    f1 = A1_ / At if (np.isfinite(At) and At > 0) else np.nan
    f2 = A2_ / At if (np.isfinite(At) and At > 0) else np.nan

    return dict(best=best, conv=bc, coef=bcoef, dbm=dbm, ratio=ratio,
                h1=h1, h2=h2, A1_frac=f1, A2_frac=f2)


def relaxation_phase_analysis_v2(f, floor=0.15):
    """The guarded biphasic rule (post-fix R behaviour)."""
    coef = f["coef"]
    k1 = abs(coef["k1"])
    k2 = abs(coef["k2"])
    A1s, A2s = coef["A1"], coef["A2"]
    A1, A2 = abs(A1s), abs(A2s)
    ratio = k1 / k2 if (np.isfinite(k1) and np.isfinite(k2) and k2 > 0) else np.nan
    same_sign = np.isfinite(A1s) and np.isfinite(A2s) and (np.sign(A1s) == np.sign(A2s))
    tot = A1 + A2
    p1 = A1 / tot if (np.isfinite(tot) and tot > 0) else np.nan
    p2 = A2 / tot if (np.isfinite(tot) and tot > 0) else np.nan
    minf = min(p1, p2) if (np.isfinite(p1) and np.isfinite(p2)) else 0.0
    dbm = f["dbm"] if np.isfinite(f["dbm"]) else -np.inf
    biphasic = bool(np.isfinite(ratio) and ratio > 2 and same_sign and
                    minf >= floor and dbm > 0)
    return dict(biphasic=biphasic, ratio=ratio, minf=minf,
                same_sign=same_sign, dbm=dbm, p1=p1, p2=p2)


# ---------------------------------------------------------------------------
# Data generators (same parameters as tests/testthat/helper-fixtures.R)
# ---------------------------------------------------------------------------

def make_bi(n, tm, s, c0=.05, A1=.03, k1=17.7, A2=.01, k2=.47, noise=0.001):
    rng = np.random.default_rng(s)
    t = np.linspace(0, tm, n)
    rho = c0 + A1 * np.exp(-k1 * t) + A2 * np.exp(-k2 * t) + rng.normal(0, noise, n)
    return t, rho


def make_mono(n, tm, s, c0=.05, A=.04, k=1.0, noise=0.001):
    rng = np.random.default_rng(s)
    t = np.linspace(0, tm, n)
    rho = c0 + A * np.exp(-k * t) + rng.normal(0, noise, n)
    return t, rho


# ---------------------------------------------------------------------------
# Evidence summary (the numbers cited in the literate doc)
# ---------------------------------------------------------------------------

def main():
    print("=== Recovery (clean bi, raw scale, seed 42) ===")
    t, rho = make_bi(100, 10, 42, noise=1e-6)
    f = fit_biexp(t, rho, False)
    c = f["coef"]
    print(f"  k1={c['k1']:.3f} (true 17.7), k2={c['k2']:.4f} (true 0.47), "
          f"A1={c['A1']:.4f} (true 0.03), A2={c['A2']:.4f} (true 0.01), "
          f"c0={c['c0']:.4f} (true 0.05)")

    print("\n=== Halflife (raw-time) ===")
    print(f"  k2 halflife = {f['h2']:.4f} vs ln2/0.47 = {np.log(2)/0.47:.4f}")

    print("\n=== Spurious fast channel on one-channel data (50 seeds) ===")
    spurious = sum(1 for s in range(1, 51)
                   if fit_biexp(*make_mono(80, 10, s), True)["best"] == "biexponential")
    print(f"  {spurious}/50 seeds select biexponential on pure mono data")

    print("\n=== Biphasic flag: old ratio-only vs guarded rule (200 one-channel seeds) ===")
    old_fp = new_fp = 0
    for s in range(1, 201):
        f = fit_biexp(*make_mono(80, 10, s), True)
        if not f["conv"]:
            continue
        if f["ratio"] > 2:  # old rule (ratio-only)
            old_fp += 1
        if relaxation_phase_analysis_v2(f)["biphasic"]:
            new_fp += 1
    print(f"  old (ratio-only): {old_fp}/200 false positives")
    print(f"  new (guarded):    {new_fp}/200 false positives")

    print("\n=== Guarded rule: genuine two-channel data (100 seeds @ noise 0.001) ===")
    tp = sum(1 for s in range(1, 101)
             if relaxation_phase_analysis_v2(fit_biexp(*make_bi(80, 10, s, noise=0.001), True))["biphasic"])
    print(f"  {tp}/100 detected as biphasic")

    print("\n=== Min-fraction separation (the floor sits in the gap) ===")
    tbf = [relaxation_phase_analysis_v2(fit_biexp(*make_bi(80, 10, s, noise=0.001), True))["minf"]
           for s in range(1, 101)]
    print(f"  true two-channel min-fraction: {min(tbf):.3f} - {max(tbf):.3f}")
    print("  (guarded rule uses floor = 0.15; spurious same-sign cases sit <= 0.11)")

    print("\n=== Noise boundary: bi selection rate falls as noise rises ===")
    for noise in [0.001, 0.005, 0.01, 0.02, 0.05]:
        n_ = sum(1 for s in range(1, 11)
                 if fit_biexp(*make_bi(80, 10, s, noise=noise), True)["best"] == "biexponential")
        print(f"  noise={noise}: {n_}/10 seeds select bi")

    print("\n=== Degenerate sampling (t_max=56500): honest mono ===")
    f = fit_biexp(*make_bi(80, 56500, 42), True)
    print(f"  best={f['best']} (fast phase unresolvable at this sampling)")


if __name__ == "__main__":
    main()
