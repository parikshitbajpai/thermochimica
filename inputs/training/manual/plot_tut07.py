#!/usr/bin/env python3
"""
Tutorial Problem #7 (manual): Post-processing of Heating Steel.

The manual's exercise is to run the temperature sweep and then post-process
the JSON output in an external plotting tool to reproduce its Figure 4
(moles of each phase versus temperature for Fe-0.15wt%C steel). This script
does that step.

Run from the repo root:
    ./bin/InputScriptMode inputs/training/manual/tut07_FeC_heating_sweep.ti
    MPLCONFIGDIR=$TMPDIR/mplcache .venv/bin/python3 -I inputs/training/manual/plot_tut07.py

Writes outputs/tut07_phase_stability.png.
"""
import json
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
JSON_PATH = os.path.join(REPO, "outputs", "tut07_FeC_heating")
OUT_PATH = os.path.join(REPO, "outputs", "tut07_phase_stability.png")

PHASE_COLORS = {
    "BCC_A2": "#2c5f8a",
    "FCC_A1": "#c0392b",
    "Liquid": "#e1b12c",
    "C_GRAPHITE(s)": "#27632a",
}


def main():
    if not os.path.exists(JSON_PATH):
        print(f"Run the sweep first: {JSON_PATH} not found.")
        print("  ./bin/InputScriptMode inputs/training/manual/tut07_FeC_heating_sweep.ti")
        return 1

    with open(JSON_PATH) as f:
        data = json.load(f)

    temps = []
    series = {name: [] for name in PHASE_COLORS}
    for key in sorted(data, key=int):
        calc = data[key]
        T_c = calc["temperature"] - 273.15
        temps.append(T_c)
        soln = calc.get("solution phases", {})
        pure = calc.get("pure condensed phases", {})
        for name in PHASE_COLORS:
            moles = soln.get(name, {}).get("moles", 0.0) or pure.get(name, {}).get("moles", 0.0)
            series[name].append(moles)

    fig, ax = plt.subplots(figsize=(8, 5.2))
    for name, color in PHASE_COLORS.items():
        ax.plot(temps, series[name], marker="o", markersize=3, label=name, color=color)
    ax.set_xlabel("Temperature [C]")
    ax.set_ylabel("Moles of phase")
    ax.set_title("Fe-0.15wt%C Phase Stability")
    ax.legend(loc="center right")
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    fig.savefig(OUT_PATH, dpi=150)
    print("wrote", OUT_PATH)

    # print the two transition brackets for a quick text check
    prev_bcc_fcc = None
    for i in range(1, len(temps)):
        if series["BCC_A2"][i - 1] > 1e-6 and series["FCC_A1"][i] > series["BCC_A2"][i] and prev_bcc_fcc is None:
            prev_bcc_fcc = (temps[i - 1], temps[i])
    prev_melt = None
    for i in range(1, len(temps)):
        if series["Liquid"][i - 1] < 1e-6 and series["Liquid"][i] > 1e-6 and prev_melt is None:
            prev_melt = (temps[i - 1], temps[i])
    print("BCC->FCC transition bracket (C):", prev_bcc_fcc)
    print("Melting onset bracket (C):", prev_melt)
    return 0


if __name__ == "__main__":
    sys.exit(main())
