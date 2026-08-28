#!/usr/bin/env python3
"""
Valence Economic Extrapolations — Calculations & Visualizations
===========================================================
Generates both matplotlib PNG (300 DPI, publication-quality) and
plotly HTML (interactive) for all 8 valence economic extrapolations.

Output directory: /tmp/valence-foundry/docs/assets/economic/
"""

import os
import io
from pathlib import Path
from typing import Tuple

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots

# ── Output directory ──────────────────────────────────────────────────
OUTPUT = Path("/tmp/valence-foundry/docs/assets/economic")
OUTPUT.mkdir(parents=True, exist_ok=True)

# ── Consistent colour palette ─────────────────────────────────────────
PALETTE = {
    "primary":  "#1b2a4a",   # dark slate
    "secondary": "#2e5a88",  # medium blue
    "accent":   "#e67e22",   # orange
    "safe":     "#27ae60",   # green
    "danger":   "#c0392b",   # red
    "neutral":  "#7f8c8d",   # grey
    "light":    "#ecf0f1",   # light grey
    "bg":       "#ffffff",   # white
}
CYCLE = ["#1b2a4a", "#e67e22", "#27ae60", "#c0392b", "#2e5a88", "#7f8c8d"]

matplotlib.rcParams.update({
    "font.family":       "sans-serif",
    "font.sans-serif":   ["DejaVu Sans", "Arial", "Helvetica"],
    "font.size":         11,
    "axes.titlesize":    13,
    "axes.labelsize":    12,
    "axes.facecolor":    PALETTE["bg"],
    "axes.edgecolor":    "#333333",
    "axes.grid":         True,
    "grid.alpha":        0.25,
    "grid.color":        "#cccccc",
    "figure.facecolor":  PALETTE["bg"],
    "savefig.facecolor": PALETTE["bg"],
    "savefig.dpi":       300,
    "xtick.labelsize":   10,
    "ytick.labelsize":   10,
    "legend.fontsize":   10,
})


# =====================================================================
# 1. Sunk Capacity Equation
# =====================================================================
def extrapolation_1():
    """Departure Cost = Σ_i (C_shed,i / D_i) · R_i"""
    scenarios = ["Career\nChange", "Divorce", "Firm\nExit", "Tech\nMigration", "Geographic\nMove", "Religious\nExit"]
    n = len(scenarios)

    # C_shed — sunk non-recoverable cost (units: arbitrary)
    C_shed = np.array([120, 60, 200, 80, 150, 90])
    # D_i — depth of integration (0-1)
    D_i = np.array([0.85, 0.70, 0.95, 0.60, 0.80, 0.90])
    # R_i — personal relevance weighting (0-1)
    R_i = np.array([0.90, 0.80, 0.95, 0.65, 0.75, 0.85])

    # Departure cost components per scenario × capacity (simulate 3 capacities per scenario)
    np.random.seed(42)
    n_capacities = 3
    capacities = [f"Cap {c+1}" for c in range(n_capacities)]
    departure_matrix = np.zeros((n, n_capacities))
    for i in range(n):
        # Each scenario has 3 sunk capacities with varying C_shed / D_i ratios
        base = C_shed[i] / D_i[i] * R_i[i]
        splits = np.random.dirichlet(np.ones(n_capacities)) * base
        departure_matrix[i] = splits

    total_cost = departure_matrix.sum(axis=1)

    # ── Matplotlib ──
    fig, ax = plt.subplots(figsize=(10, 6))
    x = np.arange(n)
    width = 0.22
    bottoms = np.zeros(n)
    for c_idx, cap in enumerate(capacities):
        ax.bar(x + (c_idx - 1) * width, departure_matrix[:, c_idx], width,
               label=cap, color=PALETTE[["primary", "secondary", "accent"][c_idx]],
               edgecolor="white", linewidth=0.5)
    ax.bar(x + 1.5 * width, total_cost, width * 2, label="Total Cost",
           color=PALETTE["danger"], alpha=0.6, edgecolor="white", linewidth=0.5)
    ax.set_xticks(x + width * 0.5)
    ax.set_xticklabels(scenarios)
    ax.set_ylabel("Departure Cost (arbitrary units)")
    ax.set_title("1. Sunk Capacity Equation\nDeparture Cost = Σᵢ (C_shed,ᵢ / Dᵢ) · Rᵢ")
    ax.legend(loc="upper left", framealpha=0.9)
    fig.tight_layout()
    fig.savefig(OUTPUT / "01_sunk_capacity.png")
    plt.close(fig)
    print("  ✓ 01_sunk_capacity.png")

    # ── Plotly ──
    fig_p = go.Figure()
    for c_idx, cap in enumerate(capacities):
        fig_p.add_trace(go.Bar(
            name=cap, x=scenarios, y=departure_matrix[:, c_idx],
            marker_color=PALETTE[["primary", "secondary", "accent"][c_idx]],
            legendgroup="capacities",
        ))
    fig_p.add_trace(go.Bar(
        name="Total Cost", x=scenarios, y=total_cost,
        marker_color=PALETTE["danger"], marker_opacity=0.6,
    ))
    fig_p.update_layout(
        title="1. Sunk Capacity Equation — Departure Cost = Σᵢ (C_shed,ᵢ / Dᵢ) · Rᵢ",
        xaxis_title="Scenario", yaxis_title="Departure Cost (arbitrary units)",
        barmode="group", template="none",
        hovermode="x unified",
        font=dict(family="DejaVu Sans, Arial", size=12),
        plot_bgcolor=PALETTE["bg"],
    )
    fig_p.write_html(OUTPUT / "01_sunk_capacity.html")
    print("  ✓ 01_sunk_capacity.html")


# =====================================================================
# 2. Dual Trap Function
# =====================================================================
def extrapolation_2():
    """Lock-in(t) = S(t) × V(t) — multiplicative interaction"""
    # S = CDI (0-1), V = calibration (0-1)
    S = np.linspace(0, 1, 50)
    V = np.linspace(0, 1, 50)
    S_grid, V_grid = np.meshgrid(S, V)
    Lock_in = S_grid * V_grid  # multiplicative

    # ── Matplotlib: 2D heatmap (cleaner for paper) ──
    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.pcolormesh(S_grid, V_grid, Lock_in, shading="auto",
                       cmap="RdYlGn_r", vmin=0, vmax=1)
    cbar = fig.colorbar(im, ax=ax, label="Lock-in Severity")
    ax.contour(S_grid, V_grid, Lock_in, levels=[0.3, 0.6], colors="white", linewidths=1.5, linestyles="--")

    # Annotate regions
    ax.text(0.15, 0.85, "Escapable\n(low S)", ha="center", va="center",
            fontsize=11, color="green", fontweight="bold", bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8))
    ax.text(0.85, 0.15, "Escapable\n(low V)", ha="center", va="center",
            fontsize=11, color="green", fontweight="bold", bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8))
    ax.text(0.75, 0.75, "Deep\nLock-in", ha="center", va="center",
            fontsize=13, color="darkred", fontweight="bold", bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8))

    ax.set_xlabel("S(t) — CDI (Concentration / Depth of Integration)")
    ax.set_ylabel("V(t) — Reward Calibration (Value Alignment)")
    ax.set_title("2. Dual Trap Function\nLock-in = S(t) × V(t) — Multiplicative Interaction")
    fig.tight_layout()
    fig.savefig(OUTPUT / "02_dual_trap.png")
    plt.close(fig)
    print("  ✓ 02_dual_trap.png")

    # ── Plotly: 3D surface ──
    fig_p = go.Figure(data=[go.Surface(
        z=Lock_in, x=S, y=V, colorscale="RdYlGn_r",
        colorbar=dict(title="Lock-in", x=1.02),
        contours=dict(z=dict(show=True, usecolormap=True, project=dict(z=True))),
        hovertemplate="S(t)=%{x:.2f}<br>V(t)=%{y:.2f}<br>Lock-in=%{z:.2f}<extra></extra>"
    )])
    fig_p.update_layout(
        title="2. Dual Trap Function — Lock-in = S(t) × V(t)",
        scene=dict(
            xaxis_title="S(t) — CDI", yaxis_title="V(t) — Reward Calibration",
            zaxis_title="Lock-in Severity",
            camera=dict(eye=dict(x=1.5, y=1.5, z=0.8)),
        ),
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        width=800, height=600,
    )
    fig_p.write_html(OUTPUT / "02_dual_trap.html")
    print("  ✓ 02_dual_trap.html")


# =====================================================================
# 3. Specialization Risk Premium
# =====================================================================
def extrapolation_3():
    """r_specialist = r_generalist + λ·CDI − μ·F_c"""
    r_generalist = 0.07
    lmbda = 0.08
    mu = 0.06

    CDI = np.linspace(0, 1, 60)
    F_c = np.linspace(0, 1, 60)
    CDI_grid, Fc_grid = np.meshgrid(CDI, F_c)
    r_spec = r_generalist + lmbda * CDI_grid - mu * Fc_grid
    risk_premium = r_spec - r_generalist  # λ·CDI − μ·F_c

    # ── Matplotlib: contour plot ──
    fig, ax = plt.subplots(figsize=(8, 6))
    levels = np.linspace(risk_premium.min(), risk_premium.max(), 15)
    cf = ax.contourf(CDI_grid, Fc_grid, risk_premium, levels=levels, cmap="RdBu_r", extend="both")
    cbar = fig.colorbar(cf, ax=ax, label="Risk Premium (r_spec − r_gen)")
    cont = ax.contour(CDI_grid, Fc_grid, risk_premium, levels=8, colors="k", linewidths=0.5)
    ax.clabel(cont, inline=True, fontsize=8, fmt="%.3f")

    # Mark zones
    ax.axhline(0.5, color=PALETTE["neutral"], linestyle=":", linewidth=1.5, alpha=0.7)
    ax.text(0.25, 0.75, "CAPM Zone\n(F_c has no effect)", ha="center", va="center",
            fontsize=10, color=PALETTE["safe"], fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8))
    ax.text(0.75, 0.25, "valence Zone\n(CDI dominates)", ha="center", va="center",
            fontsize=10, color=PALETTE["danger"], fontweight="bold",
            bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8))

    ax.set_xlabel("CDI — Concentration / Depth of Integration (0-1)")
    ax.set_ylabel("F_c — Conservation Force (0-1)")
    ax.set_title("3. Specialization Risk Premium\nr_specialist = r_generalist + λ·CDI − μ·F_c\n"
                 f"λ={lmbda}, μ={mu}, r_generalist={r_generalist}")
    fig.tight_layout()
    fig.savefig(OUTPUT / "03_specialization_risk_premium.png")
    plt.close(fig)
    print("  ✓ 03_specialization_risk_premium.png")

    # ── Plotly: interactive contour ──
    fig_p = go.Figure(data=[go.Contour(
        z=risk_premium, x=CDI, y=F_c,
        colorscale="RdBu", contours=dict(showlabels=True),
        colorbar=dict(title="Risk Premium", x=1.02),
        hovertemplate="CDI=%{x:.2f}<br>F_c=%{y:.2f}<br>Premium=%{z:.4f}<extra></extra>"
    )])
    fig_p.update_layout(
        title="3. Specialization Risk Premium — r_spec = r_gen + λ·CDI − μ·F_c",
        xaxis_title="CDI — Concentration / Depth of Integration", yaxis_title="F_c — Conservation Force",
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        width=800, height=600,
        annotations=[
            dict(x=0.25, y=0.75, text="CAPM Zone", showarrow=False,
                 font=dict(color="green", size=14), bgcolor="rgba(255,255,255,0.8)"),
            dict(x=0.75, y=0.25, text="valence Zone", showarrow=False,
                 font=dict(color="red", size=14), bgcolor="rgba(255,255,255,0.8)"),
        ]
    )
    fig_p.write_html(OUTPUT / "03_specialization_risk_premium.html")
    print("  ✓ 03_specialization_risk_premium.html")


# =====================================================================
# 4. Niche Saturation Dynamics
# =====================================================================
def extrapolation_4():
    """dS/dt = α·S·(1−S/K) − δ·S·E(t)  with K(cultural) or K(eco)"""
    alpha = 0.3
    delta = 0.05
    K_eco = 100.0
    gamma = 0.01
    T = 100
    dt = 1.0

    def simulate(K_constant: bool):
        S = np.zeros(T)
        K = np.zeros(T)
        S[0] = 1.0
        K[0] = K_eco if K_constant else 60.0
        E = np.linspace(0.01, 0.15, T)  # environmental pressure grows slightly
        for t in range(1, T):
            if K_constant:
                K[t] = K_eco
            else:
                K[t] = K[t-1] + gamma * S[t-1] * dt
            growth = alpha * S[t-1] * (1 - S[t-1] / K[t])
            decay = delta * S[t-1] * E[t]
            S[t] = S[t-1] + (growth - decay) * dt
            S[t] = max(S[t], 0)
        return S, K

    S_eco, K_eco_arr = simulate(K_constant=True)
    S_cult, K_cult_arr = simulate(K_constant=False)

    # ── Matplotlib ──
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
    t = np.arange(T)

    ax1.plot(t, S_eco, color=PALETTE["primary"], linewidth=2.5, label="Population S(t)")
    ax1.plot(t, K_eco_arr, color=PALETTE["accent"], linewidth=2, linestyle="--", label="Carrying Capacity K (constant)")
    ax1.fill_between(t, 0, S_eco, alpha=0.15, color=PALETTE["primary"])
    ax1.axhline(K_eco, color=PALETTE["neutral"], linestyle=":", alpha=0.5)
    ax1.set_xlabel("Time (arbitrary units)")
    ax1.set_ylabel("Population / Capacity")
    ax1.set_title("(a) Ecological Substrate (Finite K)")
    ax1.legend(loc="lower right")

    ax2.plot(t, S_cult, color=PALETTE["secondary"], linewidth=2.5, label="Population S(t)")
    ax2.plot(t, K_cult_arr, color=PALETTE["accent"], linewidth=2, linestyle="--", label="Carrying Capacity K(t) = K₀ + γ·∫S·dt")
    ax2.fill_between(t, 0, S_cult, alpha=0.15, color=PALETTE["secondary"])
    ax2.set_xlabel("Time (arbitrary units)")
    ax2.set_ylabel("Population / Capacity")
    ax2.set_title("(b) Cultural Substrate (Expanding K)")
    ax2.legend(loc="upper left")

    fig.suptitle("4. Niche Saturation Dynamics\n"
                 "dS/dt = α·S·(1−S/K) − δ·S·E(t)     "
                 f"α={alpha}, δ={delta}, K_eco={K_eco}, γ={gamma}",
                 y=1.02, fontsize=13, fontweight="bold")
    fig.tight_layout()
    fig.savefig(OUTPUT / "04_niche_saturation.png", bbox_inches="tight")
    plt.close(fig)
    print("  ✓ 04_niche_saturation.png")

    # ── Plotly ──
    fig_p = make_subplots(rows=1, cols=2, subplot_titles=(
        "(a) Ecological Substrate (Finite K)", "(b) Cultural Substrate (Expanding K)"))
    fig_p.add_trace(go.Scatter(x=t, y=S_eco, mode="lines", name="S(t) Eco",
                                line=dict(color=PALETTE["primary"], width=3)), row=1, col=1)
    fig_p.add_trace(go.Scatter(x=t, y=K_eco_arr, mode="lines", name="K (constant)",
                                line=dict(color=PALETTE["accent"], width=2, dash="dash")), row=1, col=1)
    fig_p.add_trace(go.Scatter(x=t, y=S_cult, mode="lines", name="S(t) Cultural",
                                line=dict(color=PALETTE["secondary"], width=3)), row=1, col=2)
    fig_p.add_trace(go.Scatter(x=t, y=K_cult_arr, mode="lines", name="K(t) expanding",
                                line=dict(color=PALETTE["accent"], width=2, dash="dash")), row=1, col=2)
    fig_p.update_layout(
        title="4. Niche Saturation Dynamics — dS/dt = α·S·(1−S/K) − δ·S·E(t)",
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        showlegend=True, width=1000, height=500,
        hovermode="x unified",
    )
    fig_p.update_xaxes(title_text="Time", row=1, col=1)
    fig_p.update_xaxes(title_text="Time", row=1, col=2)
    fig_p.update_yaxes(title_text="Population / Capacity", row=1, col=1)
    fig_p.update_yaxes(title_text="Population / Capacity", row=1, col=2)
    fig_p.write_html(OUTPUT / "04_niche_saturation.html")
    print("  ✓ 04_niche_saturation.html")


# =====================================================================
# 5. Portfolio Entrenchment
# =====================================================================
def extrapolation_5():
    """Entrenchment = (illiquid assets / total assets) × integration depth"""
    np.random.seed(123)
    n = 50
    illiquidity = np.random.beta(2, 3, n)  # 0-1, skewed toward lower
    integration_depth = np.random.beta(2, 2, n)  # 0-1
    entrenchment = illiquidity * integration_depth

    # Add some noise to make the point: same illiquidity → different entrenchment
    # Create two highlight portfolios
    highlight_idx = [10, 25]  # same illiquidity, different entrenchment

    # ── Matplotlib ──
    fig, ax = plt.subplots(figsize=(8, 6))
    scatter = ax.scatter(illiquidity, integration_depth, c=entrenchment,
                         s=100, cmap="RdYlGn_r", vmin=0, vmax=1,
                         edgecolors="#333", linewidth=0.5, alpha=0.85)
    cbar = fig.colorbar(scatter, ax=ax, label="Entrenchment Score")
    cbar.ax.tick_params(labelsize=9)

    # Highlight two points with same illiquidity
    for idx in highlight_idx:
        ax.annotate(f"Point {idx+1}\n(Same illiquidity,\ndifferent depth)",
                     xy=(illiquidity[idx], integration_depth[idx]),
                     xytext=(illiquidity[idx] + 0.12, integration_depth[idx] + 0.12),
                     arrowprops=dict(arrowstyle="->", color=PALETTE["neutral"], lw=1.2),
                     fontsize=9, color=PALETTE["primary"],
                     bbox=dict(boxstyle="round,pad=0.2", facecolor="white", alpha=0.8))

    ax.set_xlabel("Illiquidity Ratio (illiquid / total assets)")
    ax.set_ylabel("Integration Depth of Positions (0-1)")
    ax.set_title("5. Portfolio Entrenchment\n"
                 "Entrenchment = (Illiquid / Total) × Integration Depth")
    fig.tight_layout()
    fig.savefig(OUTPUT / "05_portfolio_entrenchment.png")
    plt.close(fig)
    print("  ✓ 05_portfolio_entrenchment.png")

    # ── Plotly ──
    fig_p = go.Figure()
    fig_p.add_trace(go.Scatter(
        x=illiquidity, y=integration_depth,
        mode="markers+text",
        marker=dict(
            size=12, color=entrenchment, colorscale="RdYlGn_r",
            cmin=0, cmax=1, showscale=True,
            colorbar=dict(title="Entrenchment", x=1.02),
            line=dict(color="#333", width=0.5),
        ),
        text=[f"P{i+1}" for i in range(n)],
        textposition="top center",
        textfont=dict(size=8, color="#555"),
        hovertemplate=(
            "Portfolio %{text}<br>"
            "Illiquidity: %{x:.2f}<br>"
            "Integration Depth: %{y:.2f}<br>"
            "Entrenchment: %{marker.color:.2f}<extra></extra>"
        ),
    ))
    fig_p.update_layout(
        title="5. Portfolio Entrenchment — Entrenchment = (Illiquid / Total) × Integration Depth",
        xaxis_title="Illiquidity Ratio (illiquid / total assets)",
        yaxis_title="Integration Depth of Positions (0-1)",
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        width=800, height=600,
        hovermode="closest",
    )
    fig_p.write_html(OUTPUT / "05_portfolio_entrenchment.html")
    print("  ✓ 05_portfolio_entrenchment.html")


# =====================================================================
# 6. Human Capital Depreciation
# =====================================================================
def extrapolation_6():
    """H(t) = H₀·e^(−ρt) + Σ_j w_j(t)·S_j"""
    H0 = 100.0
    rho = 0.05
    w_j = 2.0  # annual accumulation per skill unit
    years = np.arange(0, 41)
    T = len(years)

    # Generalist capital decays exponentially
    generalist = H0 * np.exp(-rho * years)

    # Specialist capital accumulates: each year, S_j increments and w_j adds
    # Simulate 3 skills with staggered onset
    specialist = np.zeros(T)
    n_skills = 3
    onset_years = [3, 8, 15]  # when each skill starts accumulating
    for onset in onset_years:
        for t in range(onset, T):
            specialist[t] += w_j * (t - onset)  # linear accumulation

    # Total
    total = generalist + specialist

    # Find crossover where specialist > generalist
    crossover_idx = np.where(specialist > generalist)[0]
    crossover_year = crossover_idx[0] if len(crossover_idx) > 0 else None

    # ── Matplotlib ──
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(years, generalist, color=PALETTE["primary"], linewidth=2.5,
            label="Generalist Capital: H₀·e^(−ρt)")
    ax.plot(years, specialist, color=PALETTE["accent"], linewidth=2.5,
            label="Specialist Capital: Σ wⱼ·Sⱼ")
    ax.plot(years, total, color=PALETTE["secondary"], linewidth=3, linestyle="--",
            label="Total H(t) = Generalist + Specialist")
    ax.fill_between(years, 0, generalist, alpha=0.08, color=PALETTE["primary"])
    ax.fill_between(years, generalist, total, alpha=0.08, color=PALETTE["accent"])

    if crossover_year is not None:
        ax.axvline(crossover_year, color=PALETTE["danger"], linestyle=":", linewidth=2, alpha=0.7)
        ax.annotate(f"Commitment Threshold\nYear {crossover_year}",
                     xy=(crossover_year, specialist[crossover_year]),
                     xytext=(crossover_year + 3, specialist[crossover_year] + 20),
                     arrowprops=dict(arrowstyle="->", color=PALETTE["danger"], lw=1.5),
                     fontsize=11, color=PALETTE["danger"], fontweight="bold",
                     bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.9))

    ax.set_xlabel("Years")
    ax.set_ylabel("Capital (arbitrary units)")
    ax.set_title("6. Human Capital Depreciation\n"
                 f"H(t) = H₀·e^(−ρt) + Σⱼ wⱼ·Sⱼ     H₀={H0}, ρ={rho}, wⱼ={w_j}/year")
    ax.legend(loc="upper right")
    fig.tight_layout()
    fig.savefig(OUTPUT / "06_human_capital_depreciation.png")
    plt.close(fig)
    print("  ✓ 06_human_capital_depreciation.png")

    # ── Plotly ──
    fig_p = go.Figure()
    fig_p.add_trace(go.Scatter(x=years, y=generalist, mode="lines",
                                name="Generalist: H₀·e^(−ρt)",
                                line=dict(color=PALETTE["primary"], width=3)))
    fig_p.add_trace(go.Scatter(x=years, y=specialist, mode="lines",
                                name="Specialist: Σ wⱼ·Sⱼ",
                                line=dict(color=PALETTE["accent"], width=3)))
    fig_p.add_trace(go.Scatter(x=years, y=total, mode="lines",
                                name="Total H(t)",
                                line=dict(color=PALETTE["secondary"], width=3, dash="dash")))
    if crossover_year is not None:
        fig_p.add_vline(x=crossover_year, line=dict(color=PALETTE["danger"], width=2, dash="dot"),
                        annotation_text=f"Commitment Threshold: Year {crossover_year}",
                        annotation_position="top right")
    fig_p.update_layout(
        title="6. Human Capital Depreciation — H(t) = H₀·e^(−ρt) + Σⱼ wⱼ·Sⱼ",
        xaxis_title="Years", yaxis_title="Capital (arbitrary units)",
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        width=900, height=550,
        hovermode="x unified",
        plot_bgcolor=PALETTE["bg"],
    )
    fig_p.write_html(OUTPUT / "06_human_capital_depreciation.html")
    print("  ✓ 06_human_capital_depreciation.html")


# =====================================================================
# 7. Technology Adoption Lock-In
# =====================================================================
def extrapolation_7():
    """Switching Cost(t) = C₀ + ∫₀ᵗ Σᵢ rᵢ(τ)·Dᵢ dτ"""
    C0 = 10.0
    r_i = 1.5  # per year per capacity
    T = 50
    t = np.arange(T)

    # Three scenarios with different D_i values
    scenarios = {
        "Low Integration (API-based, Dᵢ=0.2)":  0.2,
        "Medium Integration (mixed, Dᵢ=0.5)":  0.5,
        "High Integration (embedded, Dᵢ=0.9)": 0.9,
    }

    n_capacities = 4
    switching_costs = {}
    for label, D in scenarios.items():
        cost = np.full(T, C0)
        for cap in range(n_capacities):
            # r_i varies slightly per capacity
            r_i_cap = r_i * (0.8 + 0.4 * np.random.random())
            cost += r_i_cap * D * t  # integral of constant r_i * D_i
        switching_costs[label] = cost

    # ── Matplotlib ──
    fig, ax = plt.subplots(figsize=(10, 6))
    colors = [PALETTE["primary"], PALETTE["accent"], PALETTE["danger"]]
    for (label, cost), color in zip(switching_costs.items(), colors):
        ax.plot(t, cost, color=color, linewidth=2.5, label=label)
        ax.fill_between(t, C0, cost, alpha=0.08, color=color)

    # Annotate intractability threshold
    ax.axhline(200, color=PALETTE["neutral"], linestyle=":", alpha=0.5, linewidth=1)
    ax.text(52, 200, "Intractability Threshold (200)", fontsize=9, color=PALETTE["neutral"], va="center")

    ax.set_xlabel("Time (years)")
    ax.set_ylabel("Switching Cost (arbitrary units)")
    ax.set_title("7. Technology Adoption Lock-In\n"
                 f"Switching Cost(t) = C₀ + ∫₀ᵗ Σᵢ rᵢ(τ)·Dᵢ dτ     C₀={C0}, rᵢ={r_i}/year")
    ax.legend(loc="upper left")
    fig.tight_layout()
    fig.savefig(OUTPUT / "07_technology_lockin.png")
    plt.close(fig)
    print("  ✓ 07_technology_lockin.png")

    # ── Plotly ──
    fig_p = go.Figure()
    for (label, cost), color in zip(switching_costs.items(), colors):
        fig_p.add_trace(go.Scatter(x=t, y=cost, mode="lines", name=label,
                                    line=dict(color=color, width=3)))
    fig_p.add_hline(y=200, line=dict(color=PALETTE["neutral"], width=1, dash="dot"),
                    annotation_text="Intractability Threshold (200)")
    fig_p.update_layout(
        title="7. Technology Adoption Lock-In — Switching Cost(t) = C₀ + ∫₀ᵗ Σᵢ rᵢ(τ)·Dᵢ dτ",
        xaxis_title="Time (years)", yaxis_title="Switching Cost (arbitrary units)",
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        width=900, height=550,
        hovermode="x unified",
        plot_bgcolor=PALETTE["bg"],
    )
    fig_p.write_html(OUTPUT / "07_technology_lockin.html")
    print("  ✓ 07_technology_lockin.html")


# =====================================================================
# 8. Conservation Force Decay
# =====================================================================
def extrapolation_8():
    """F_c(D) = F₀·e^(−β·D)  +  Survival probability from F_c × CDI"""
    F0 = 100.0
    beta = 2.0
    D = np.linspace(0, 1, 100)
    F_c = F0 * np.exp(-beta * D)

    # ── Matplotlib (two panels) ──
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5.5))

    # Panel (a): F_c vs D
    ax1.plot(D, F_c, color=PALETTE["primary"], linewidth=3, label=f"F_c(D) = {F0}·e^({-beta}·D)")
    ax1.fill_between(D, 0, F_c, alpha=0.12, color=PALETTE["primary"])
    # "Too big to fail" zone
    ax1.axvspan(0, 0.15, alpha=0.15, color=PALETTE["danger"], label='"Too Big to Fail" zone')
    ax1.annotate("Political F_c\nkeeps force\nartificially high",
                 xy=(0.07, F0 * np.exp(-beta * 0.07)),
                 xytext=(0.25, 60),
                 arrowprops=dict(arrowstyle="->", color=PALETTE["danger"], lw=1.2),
                 fontsize=10, color=PALETTE["danger"], fontweight="bold",
                 bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.9))
    ax1.set_xlabel("Commitment Depth D (0-1)")
    ax1.set_ylabel("Conservation Force F_c")
    ax1.set_title("(a) Conservation Force Decay\nF_c(D) = F₀·e^(−β·D)")
    ax1.legend(loc="upper right")

    # Panel (b): Survival probability as function of F_c × CDI
    CDI_vals = [0.2, 0.5, 0.8]
    for cdi, color in zip(CDI_vals, [PALETTE["safe"], PALETTE["accent"], PALETTE["danger"]]):
        # Survival probability ~ logistic of (F_c * CDI)
        interaction = F_c * cdi
        survival = 1 / (1 + np.exp(-0.05 * (interaction - 50)))
        ax2.plot(D, survival, color=color, linewidth=2.5,
                label=f"CDI = {cdi}")
        ax2.fill_between(D, 0, survival, alpha=0.06, color=color)

    ax2.set_xlabel("Commitment Depth D (0-1)")
    ax2.set_ylabel("Survival Probability")
    ax2.set_title("(b) Survival Probability vs F_c × CDI Interaction")
    ax2.legend(loc="lower right")
    ax2.set_ylim(0, 1.05)

    fig.suptitle("8. Conservation Force Decay\n"
                 f"F_c(D) = F₀·e^(−β·D)     F₀={F0}, β={beta}",
                 y=1.02, fontsize=13, fontweight="bold")
    fig.tight_layout()
    fig.savefig(OUTPUT / "08_conservation_force_decay.png", bbox_inches="tight")
    plt.close(fig)
    print("  ✓ 08_conservation_force_decay.png")

    # ── Plotly ──
    fig_p = make_subplots(rows=1, cols=2, subplot_titles=(
        "(a) F_c(D) = F₀·e^(−β·D)", "(b) Survival Probability = f(F_c × CDI)"))
    fig_p.add_trace(go.Scatter(x=D, y=F_c, mode="lines",
                                name=f"F_c(D) = {F0}·e^({-beta}·D)",
                                line=dict(color=PALETTE["primary"], width=3),
                                fill="tozeroy", fillcolor="rgba(27,42,74,0.08)"), row=1, col=1)
    fig_p.add_vrect(x0=0, x1=0.15, fillcolor="red", opacity=0.12,
                     annotation_text="'Too Big to Fail'", annotation_position="top left",
                     row=1, col=1)
    for cdi, color in zip(CDI_vals, [PALETTE["safe"], PALETTE["accent"], PALETTE["danger"]]):
        interaction = F_c * cdi
        survival = 1 / (1 + np.exp(-0.05 * (interaction - 50)))
        fig_p.add_trace(go.Scatter(x=D, y=survival, mode="lines",
                                    name=f"CDI = {cdi}",
                                    line=dict(color=color, width=2.5)), row=1, col=2)
    fig_p.update_layout(
        title="8. Conservation Force Decay — F_c(D) = F₀·e^(−β·D)",
        template="none", font=dict(family="DejaVu Sans, Arial", size=12),
        showlegend=True, width=1000, height=500,
        hovermode="x unified",
    )
    fig_p.update_xaxes(title_text="Commitment Depth D (0-1)", row=1, col=1)
    fig_p.update_xaxes(title_text="Commitment Depth D (0-1)", row=1, col=2)
    fig_p.update_yaxes(title_text="Conservation Force F_c", row=1, col=1)
    fig_p.update_yaxes(title_text="Survival Probability", row=1, col=2, range=[0, 1.05])
    fig_p.write_html(OUTPUT / "08_conservation_force_decay.html")
    print("  ✓ 08_conservation_force_decay.html")


# =====================================================================
# Main
# =====================================================================
def main():
    print("=" * 70)
    print("valence Economic Extrapolations — Generating All 8 Visualizations")
    print("=" * 70)
    print(f"Output: {OUTPUT}\n")

    extrapolation_1()
    extrapolation_2()
    extrapolation_3()
    extrapolation_4()
    extrapolation_5()
    extrapolation_6()
    extrapolation_7()
    extrapolation_8()

    print("\n" + "=" * 70)
    print("All 8 extrapolations generated successfully.")
    print("=" * 70)
    print("\nOutput files:")
    for f in sorted(OUTPUT.iterdir()):
        size = f.stat().st_size
        print(f"  {f.name:50s}  {size:>8,} bytes")


if __name__ == "__main__":
    main()