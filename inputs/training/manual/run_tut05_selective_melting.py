#!/usr/bin/env python3
"""
Tutorial Problem #5 (manual): Steelmaking with Ferrous Scrap Metal.

Automates the selective-melting procedure the manual describes in prose but
leaves as a manual exercise: starting from 87 mol Fe, 13 mol Cu, 1.5 mol C at
1380 C, repeatedly
  1. run Thermochimica,
  2. read the element content of the stable solid phase (FCC_A1) back out,
  3. discard the liquid (pour it off),
  4. raise the temperature by 10 C,
  5. repeat with the solid's element content as the next step's mass balance.

This reproduces the manual's qualitative claim exactly: the Fe fraction of
the remaining solid rises from 87% toward and above 95% wt, while the total
retained Fe mass falls below half the starting amount -- the manual's two
discussion questions ("is this economical?", "how would you improve it?")
follow directly from the printed table.

Run from the repo root:
    python3 -I inputs/training/manual/run_tut05_selective_melting.py
"""
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
BIN = os.path.join(REPO, "bin", "InputScriptMode")
TI_PATH = os.path.join(REPO, "inputs", "training", "manual", "_tut05_step.ti")
OUT_NAME = "tut05_selective_melting_step"
OUT_PATH = os.path.join(REPO, "outputs", OUT_NAME)

N_STEPS = 11
T_START_C = 1380.0
T_STEP_C = 10.0


def write_input(T_c, Fe, Cu, C):
    with open(TI_PATH, "w") as f:
        f.write(f"""temperature       = {T_c}
pressure          = 1.0
mass(26)          = {Fe}
mass(29)          = {Cu}
mass(6)           = {C}
temperature unit  = C
pressure unit     = atm
mass unit         = moles
data file         = data/CuFeC-Kang.dat
print mode        = 1
write json        = .TRUE.
output            = {OUT_NAME}
""")


def run_step(T_c, Fe, Cu, C):
    write_input(T_c, Fe, Cu, C)
    subprocess.run([BIN, TI_PATH], cwd=REPO, capture_output=True, text=True)
    with open(OUT_PATH) as f:
        d = json.load(f)
    calc = d["1"]
    fcc = calc["solution phases"].get("FCC_A1", {})
    elements = fcc.get("elements", {})
    fe = elements.get("Fe", {}).get("moles of element in phase", 0.0)
    cu = elements.get("Cu", {}).get("moles of element in phase", 0.0)
    c = elements.get("C", {}).get("moles of element in phase", 0.0)
    fcc_moles = fcc.get("moles", 0.0)
    liq_moles = calc["solution phases"].get("Liquid", {}).get("moles", 0.0)
    return fe, cu, c, fcc_moles, liq_moles


def main():
    Fe, Cu, C = 87.0, 13.0, 1.5
    Fe0 = Fe
    T = T_START_C
    rows = []
    for step in range(N_STEPS):
        fe, cu, c, fcc_moles, liq_moles = run_step(T, Fe, Cu, C)
        total = fe + cu + c
        wt_pct_fe = fe / total * 100 if total > 0 else 0.0
        pct_fe_retained = fe / Fe0 * 100
        rows.append((step, T, Fe, Cu, C, fcc_moles, liq_moles, wt_pct_fe, pct_fe_retained))
        Fe, Cu, C = fe, cu, c
        T += T_STEP_C

    header = f"{'step':>4} {'T(C)':>7} {'Fe in':>8} {'Cu in':>8} {'C in':>8} {'FCC mol':>9} {'Liq mol':>9} {'at% Fe in solid':>16} {'% Fe retained':>14}"
    print(header)
    print("-" * len(header))
    for r in rows:
        print(f"{r[0]:>4} {r[1]:>7.0f} {r[2]:>8.4f} {r[3]:>8.4f} {r[4]:>8.4f} {r[5]:>9.4f} {r[6]:>9.4f} {r[7]:>16.3f} {r[8]:>14.3f}")

    final = rows[-1]
    print()
    print(f"After {N_STEPS - 1} melt-and-pour steps:")
    print(f"  Fe purity in the remaining solid rose from {rows[0][7]:.2f} at% to {final[7]:.2f} at%.")
    print(f"  Total retained Fe fell to {final[8]:.1f}% of the starting amount.")
    print()
    print("Discussion (from the manual): is this process economical as designed?")
    print("Can the number of steps or the temperature increment be changed to")
    print("improve the yield-versus-purity tradeoff?")

    if os.path.exists(TI_PATH):
        os.remove(TI_PATH)
    if os.path.exists(OUT_PATH):
        os.remove(OUT_PATH)


if __name__ == "__main__":
    sys.exit(main())
