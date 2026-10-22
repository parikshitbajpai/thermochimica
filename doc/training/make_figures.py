#!/usr/bin/env python3
"""
SaltFoss Training — fallback figure generator.

Regenerates the JSON sweep (if needed) and produces four presentation-ready
PNGs in doc/training/figures/ for use as a fallback if a live demo misbehaves
during the session.

Run from the repo root with the project's own interpreter, isolated:
    MPLCONFIGDIR=$TMPDIR/mplcache .venv/bin/python3 -I doc/training/make_figures.py

Figures:
  1. fig1_potential_invariance.png — element potentials (wild) vs species
     combinations (invariant) across the 02a/02b/02c under-determined runs.
  2. fig2_redox_uf_ratio.png       — U(IV)/U(III) ratio vs temperature from
     the 03_redox_sweep.ti JSON output (flat at ~1.000).
  3. fig3_corrosion_vs_redox.png   — dissolved Cr2+/Cr3+ (log scale) vs F/U
     redox state, from the three 04_corrosion_*.ti runs (the money figure).
  4. fig4_offgas_speciation.png    — gas-phase composition (log bar chart) at
     1e-6 atm from 05_offgas_lowP.ti.

NOTE on MQMQA/SUBQ JSON structure (verified quirk, documented in the handout):
the molten-salt liquid phase (MSFL) has NO "species" key. It reports
"cations" / "anions" / "quadruplets" instead, and constituent names are
truncated to 8 characters (e.g. "U[CN=VII", "Be[Dimer"). This script parses
that structure directly rather than using python/thermoTools.py's makePlot,
which assumes a simple "species" block.
"""
import json
import os
import subprocess
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TRAIN_INPUTS = os.path.join(REPO, "inputs", "training", "saltfoss")
OUTPUTS = os.path.join(REPO, "outputs")
FIG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "figures")
BIN = os.path.join(REPO, "bin", "InputScriptMode")

# Palette — consistent, colorblind-safe categorical colors used across all figures.
COLOR_REDUCED = "#2E7D6B"      # teal-green: reduced / low-corrosion / safe state
COLOR_MID = "#C9972A"          # amber: midpoint
COLOR_OXIDIZED = "#B3452C"     # brick red: oxidized / high-corrosion state
COLOR_INVARIANT = "#2E7D6B"
COLOR_WILD = "#B3452C"
COLOR_GAS = "#3B6FA0"          # blue: gas-phase bars

plt.rcParams.update({
    "figure.facecolor": "white",
    "axes.facecolor": "white",
    "font.size": 12,
    "axes.titlesize": 15,
    "axes.titleweight": "bold",
    "axes.labelsize": 12,
    "axes.edgecolor": "#444444",
    "axes.grid": True,
    "grid.color": "#dddddd",
    "grid.linewidth": 0.6,
    "savefig.dpi": 150,
    "savefig.bbox": "tight",
})


def run_ti(name):
    path = os.path.join(TRAIN_INPUTS, name)
    result = subprocess.run([BIN, path], cwd=REPO, capture_output=True, text=True)
    return result.stdout + result.stderr


def parse_chem_pots(stdout):
    """Pull element chemical potentials (J/mol) from InputScriptMode screen output."""
    pots = {}
    for line in stdout.splitlines():
        line = line.strip()
        for el in ("F", "Be", "Li"):
            if line.startswith(el + " ") or line.startswith(el + "\t"):
                parts = line.split("|")
                if len(parts) == 3:
                    try:
                        pots[el] = float(parts[2].strip())
                    except ValueError:
                        pass
    return pots


def parse_species_mol_fraction(stdout, species_name):
    """Pull a named gas/melt species' printed mole-fraction-style value.

    Lines look like '                  + 1.0797E-14     Cr[2+]   }' or
    '                  { 1.00000        UF3                           ' —
    the species name is a whitespace-delimited token, possibly followed by
    a stray '}'. Match the token exactly rather than relying on line-endswith.
    """
    for line in stdout.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        tokens = stripped.replace("{", " ").replace("}", " ").split()
        if species_name not in tokens:
            continue
        for t in tokens:
            if t == species_name:
                continue
            try:
                return float(t)
            except ValueError:
                continue
    return None


def ensure_fig_dir():
    os.makedirs(FIG_DIR, exist_ok=True)


def fig1_potential_invariance():
    """Element potentials (wild) vs species combinations (invariant)."""
    runs = {
        "02a: F=4.0 exact": run_ti("02a_underdetermined.ti"),
        "02b: F=4.00001": run_ti("02b_perturbed.ti"),
        "02c: F=4.0 + fuzzy": run_ti("02c_fuzzy.ti"),
    }
    labels = list(runs.keys())
    mu_F, mu_Be, mu_Li, mu_LiF, mu_BeF2 = [], [], [], [], []
    for stdout in runs.values():
        p = parse_chem_pots(stdout)
        mu_F.append(p["F"] / 1000)
        mu_Be.append(p["Be"] / 1000)
        mu_Li.append(p["Li"] / 1000)
        mu_LiF.append((p["Li"] + p["F"]) / 1000)
        mu_BeF2.append((p["Be"] + 2 * p["F"]) / 1000)

    fig, axes = plt.subplots(1, 2, figsize=(12, 5.2))

    ax = axes[0]
    x = range(len(labels))
    width = 0.25
    ax.bar([i - width for i in x], mu_F, width, label=r"$\mu_F$", color=COLOR_WILD, alpha=0.9)
    ax.bar(x, mu_Be, width, label=r"$\mu_{Be}$", color="#8B3A2E", alpha=0.9)
    ax.bar([i + width for i in x], mu_Li, width, label=r"$\mu_{Li}$", color="#D9896F", alpha=0.9)
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels, rotation=12, ha="right")
    ax.set_ylabel("Element chemical potential [kJ/mol]")
    ax.set_title("Individual element potentials: WILD\n(swing 20-40 kJ/mol on a 0.00025% F change)")
    ax.legend(loc="lower right")
    ax.axhline(0, color="#888", linewidth=0.8)

    ax = axes[1]
    ax.bar([i - width / 2 for i in x], mu_LiF, width, label=r"$\mu_{LiF} = \mu_{Li}+\mu_F$", color=COLOR_INVARIANT, alpha=0.9)
    ax.bar([i + width / 2 for i in x], mu_BeF2, width, label=r"$\mu_{BeF_2} = \mu_{Be}+2\mu_F$", color="#1E5A4C", alpha=0.9)
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels, rotation=12, ha="right")
    ax.set_ylabel("Species-level potential [kJ/mol]")
    ax.set_title("Species combinations: INVARIANT\n(identical to <0.1 kJ/mol across all three runs)")
    ax.legend(loc="lower right")

    fig.suptitle("The Chemical Potential Trap in Under-Determined Salt Systems", fontsize=16, fontweight="bold", y=1.02)
    fig.tight_layout()
    out = os.path.join(FIG_DIR, "fig1_potential_invariance.png")
    fig.savefig(out)
    plt.close(fig)
    print("wrote", out)
    print("  mu_LiF  :", [round(v, 3) for v in mu_LiF])
    print("  mu_BeF2 :", [round(v, 3) for v in mu_BeF2])


def get_or_run_sweep_json():
    path = os.path.join(OUTPUTS, "salt_training_sweep")
    if not os.path.exists(path):
        run_ti("03_redox_sweep.ti")
    with open(path) as f:
        return json.load(f)


def u4_u3_from_cations(cations):
    u3 = cations.get("U[3+]", {}).get("mole fraction", 0.0)
    u4 = 0.0
    for name in ("U[CN=VI]", "U[CN=VII", "U[Dimer]"):
        frac = cations.get(name, {}).get("mole fraction", 0.0)
        weight = 2.0 if "Dimer" in name else 1.0
        u4 += frac * weight
    return u3, u4


def fig2_redox_uf_ratio():
    data = get_or_run_sweep_json()
    temps, ratios = [], []
    for key in sorted(data, key=int):
        calc = data[key]
        cations = calc["solution phases"]["MSFL"]["cations"]
        u3, u4 = u4_u3_from_cations(cations)
        if u3 > 0:
            temps.append(calc["temperature"])
            ratios.append(u4 / u3)

    fig, ax = plt.subplots(figsize=(9, 5.2))
    ax.plot(temps, ratios, marker="o", color=COLOR_MID, linewidth=2.2, markersize=6)
    ax.axhline(1.0, color="#888", linestyle="--", linewidth=1, label="U(IV)/U(III) = 1 (target)")
    ax.set_xlabel("Temperature [K]")
    ax.set_ylabel("U(IV) / U(III) mole ratio in MSFL")
    ax.set_title("Redox State Set by F Mass Balance\n66 LiF - 33 BeF$_2$ - 1 U, F = 135.5 mol (midpoint)")
    ax.set_ylim(0.97, 1.02)
    ax.legend(loc="lower left")
    fig.tight_layout()
    out = os.path.join(FIG_DIR, "fig2_redox_uf_ratio.png")
    fig.savefig(out)
    plt.close(fig)
    print("wrote", out)
    print("  T range:", temps[0], "-", temps[-1], "K;  ratio range:", round(min(ratios), 4), "-", round(max(ratios), 4))


def fig3_corrosion_vs_redox():
    runs = [
        ("F = 135.0\n(reducing)", "04_corrosion_reducing.ti", COLOR_REDUCED),
        ("F = 135.5\n(mid)", "04_corrosion_mid.ti", COLOR_MID),
        ("F = 135.9\n(oxidizing)", "04_corrosion_oxidizing.ti", COLOR_OXIDIZED),
    ]
    labels, cr2, cr3, colors = [], [], [], []
    for label, fname, color in runs:
        stdout = run_ti(fname)
        c2 = parse_species_mol_fraction(stdout, "Cr[2+]")
        c3 = parse_species_mol_fraction(stdout, "Cr[3+]")
        labels.append(label)
        cr2.append(c2)
        cr3.append(c3)
        colors.append(color)

    fig, ax = plt.subplots(figsize=(9, 5.6))
    x = range(len(labels))
    width = 0.35
    ax.bar([i - width / 2 for i in x], cr2, width, label=r"Cr$^{2+}$", color=colors, alpha=0.95)
    ax.bar([i + width / 2 for i in x], cr3, width, label=r"Cr$^{3+}$", color=colors, alpha=0.55, hatch="//")
    ax.set_yscale("log")
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels)
    ax.set_ylabel("Dissolved Cr mole fraction in melt (log scale)")
    ax.set_title("Corrosion Tracks the Redox Buffer:\nDissolved Cr Rises ~8 Orders of Magnitude")
    ax.legend(loc="upper left")
    ax.set_ylim(1e-23, 1e-3)
    fig.tight_layout()
    out = os.path.join(FIG_DIR, "fig3_corrosion_vs_redox.png")
    fig.savefig(out)
    plt.close(fig)
    print("wrote", out)
    print("  Cr2+:", cr2)
    print("  Cr3+:", cr3)


def fig4_offgas_speciation():
    stdout = run_ti("05_offgas_lowP.ti")
    species = ["FLi", "F2Be", "UF4", "Li", "F2Li2", "F3BeLi", "UF3", "ILi", "Cs", "CsF", "UF5Li", "UF2"]
    names, values = [], []
    for sp in species:
        v = parse_species_mol_fraction(stdout, sp)
        if v is not None and v > 0:
            names.append(sp)
            values.append(v)
    pairs = sorted(zip(names, values), key=lambda t: -t[1])[:10]
    names, values = zip(*pairs)

    fig, ax = plt.subplots(figsize=(10, 5.6))
    y = range(len(names))
    ax.barh(list(y), values, color=COLOR_GAS, alpha=0.9)
    ax.set_yticks(list(y))
    ax.set_yticklabels(names)
    ax.invert_yaxis()
    ax.set_xscale("log")
    ax.set_xlabel("Gas-phase mole fraction (log scale)")
    ax.set_title("Vapor Speciation at P = 1e-6 atm, T = 1200 K\n(no stable gas phase exists at 1 atm for the same melt)")
    fig.tight_layout()
    out = os.path.join(FIG_DIR, "fig4_offgas_speciation.png")
    fig.savefig(out)
    plt.close(fig)
    print("wrote", out)
    print("  top species:", list(zip(names, values)))


def main():
    ensure_fig_dir()
    fig1_potential_invariance()
    fig2_redox_uf_ratio()
    fig3_corrosion_vs_redox()
    fig4_offgas_speciation()
    print("\nAll figures written to", FIG_DIR)


if __name__ == "__main__":
    sys.exit(main())
