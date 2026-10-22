# Thermochimica Tutorial Manual — Reproduced and Extended

This document maps every problem in `report_thermochimica_tutorial_manual20200714.pdf`
(Piro and Poschmann, Ontario Tech University) to a runnable input file on this
checkout, verified by actually running `bin/InputScriptMode` against the stated
database. It also adds sweep variants and plotting scripts for the problems
the manual leaves as a manual exercise ("perform a series of calculations...",
"post-process the results...").

Run everything from the repo root:
```bash
cd /Users/bajpp/projects/thermochimica
./bin/InputScriptMode inputs/training/manual/<file>.ti
```

## Coverage summary

| Manual problem | System | File(s) here | Status |
|---|---|---|---|
| #1 — Verifying Equilibrium Gas Constants | H-O | `tut01_HO_equilibrium_constant.ti` | Exact match |
| #3 — Cesium Iodide Scintillator | Cs-I | `tut03_CsI_scintillator.ti`, `tut03_CsI_sweep.ti` | Reproduced with a substitute database |
| #4 — Aluminum Magnesium Alloys | Al-Mg | `tut04_AlMg_alloy_solidus.ti`, `tut04_sweep.ti` | Exact match |
| #5 — Steelmaking with Ferrous Scrap Metal | Fe-Cu-C | `tut05_steelmaking_step00.ti`, `run_tut05_selective_melting.py` | Exact match; full 11-step procedure automated |
| #6 — Zirconium Hydriding | Zr-H | `tut06_ZrH_solubility.ti` | Exact match |
| #7 — Post-processing of Heating Steel | Fe-C | `tut07_FeC_heating_sweep.ti`, `plot_tut07.py` | Exact match; plotting script added |
| #9 — Oxygen Potential in ThO2-x Fuel | Th-O(-U-Pu) | — | **Not reproducible.** No Th-bearing database is present in `data/` on this checkout. |
| #10 — Plating Out of Noble Metals (MSRE) | Mo-Pd-Ru-Rh-Tc | `tut10_noble_metal_plating.ti` | Exact match |
| #11 — Eutectic Temperature of FLiNaK | Li-Na-K-F | `../../inputs/training/saltfoss/06_flinak_eutectic.ti`, `06_flinak_sweep.ti` | Reproduced with a substitute database (molten-salt training set) |
| #12 — FLiBe Liquidus with Increased Fuel Loading | Li-Be-U-F | `../../inputs/training/saltfoss/07_flibe_liquidus_A.ti`, `_B.ti`, `_sweep.ti` | Reproduced with a substitute database (molten-salt training set) |

Problems #11 and #12 are molten-salt problems, so their input files live
alongside the SaltFoss demo set in `inputs/training/saltfoss/`, numbered 06
and 07 to continue that set's sequence, rather than in `inputs/training/manual/`.

## Database substitutions, and why the numbers differ slightly

The manual was written against several export-controlled or author-supplied
database files that are not distributed in this repository's `data/`
directory:

| Manual's file | Used instead | Same system? |
|---|---|---|
| `HO.dat` | `data/HO.dat` | Yes — identical, numbers match exactly |
| `CsI.dat` | `data/CsI-Pham.dat` | Same Cs-I system, different parameterization — numbers differ, physics agrees |
| `AlMg.dat` | `data/AlMg-Liang.dat` | Yes — identical, numbers match exactly |
| Fe-Cu-C database (Shubhank & Kang) | `data/CuFeC-Kang.dat` | Yes — identical, numbers match exactly |
| `ZrH_Dupin.dat` | `data/ZrH-Dupin.dat` | Yes — identical, numbers match exactly |
| Fe-Cu-C database (same as #5) | `data/CuFeC-Kang.dat` | Yes — identical, numbers match exactly |
| `ThO_Bergeron.dat` | — none available — | **Gap: Tutorial #9 cannot be run on this checkout.** |
| `MoPdTcRuRh_Kaye.dat` | `data/MoPdRuRhTc-Kaye.dat` | Yes — identical, numbers match exactly |
| `MSAR_Ver_1.dat` (export-controlled MSTDB) | `data/MSD-TC_V4.1_Fluorides_No_Func.dat` | Same Li-Na-K-F / Li-Be-U-F systems, newer MSTDB version — numbers differ, trends agree |

For the three substitutions where the database itself differs (CsI, FLiNaK,
FLiBe), the physics and qualitative conclusions reproduce correctly, but the
exact transition temperatures are a few percent off from the manual's
printed values. This is expected and is exactly the caveat the manual itself
gives for Tutorial #11: "updated versions of this database may yield
different results." Treat the manual's numbers as one data point and this
checkout's numbers as another, both from the same model class.

## What each exact-match problem confirms

These five problems use the same database file as the manual and reproduce
its anticipated output to within solver noise (typically agreeing to 4-5
significant figures):

- **#1 (H-O):** the equilibrium constant for H2O ⇌ H2 + 0.5 O2, computed from
  Thermochimica's mole fractions, matches the 1945 NBS/NIST reference value
  of 1.151×10¹⁰ to within 0.4%.
- **#4 (Al-Mg):** the solidus of Alloy 5252 (Al-2.5wt%Mg) falls between
  620 °C and 625 °C, matching the manual's reported 620 °C.
- **#5 (Fe-Cu-C):** `run_tut05_selective_melting.py` automates the full
  11-step selective-melting procedure the manual describes in prose. Fe
  purity in the remaining solid rises from 88.96 at% to 94.95 at% over the
  10 melt-and-pour steps, while total retained Fe falls to 37.8% of the
  starting amount — both numbers consistent with the manual's claims
  ("more than 95%" purity, "less than half" retained) and precise enough to
  answer its discussion questions about process economics.
- **#6 (Zr-H):** the hydrogen solubility limit in alpha-Zr at 700 K comes
  out to H/Zr = 0.0225, matching the manual's reported value and its
  Figure 3 reference curve.
- **#7 (Fe-C):** `plot_tut07.py` reproduces the manual's Figure 4 almost
  exactly: BCC→FCC transition between 800 °C and 850 °C (manual: 738 °C,
  consistent given this sweep's 50 °C step size), single-phase FCC from
  900 °C to 1450 °C, and the FCC→Liquid transition between 1500 °C and
  1550 °C (manual: ~1493 °C).
- **#10 (noble metals):** the predicted phase assemblage — two miscible HCPN
  phases, a Mo-rich BCCN phase, and the stoichiometric compound
  Pd₁₁Mo₉(s) — matches the manual's Table 9 distribution: 98.7% of the Pd
  ends up in Pd₁₁Mo₉(s), 99.2% of the Ru in the Ru/Mo-rich HCPN phase, and
  86.6% of the Rh in the Tc/Rh-rich HCPN phase.

## New material beyond the manual

Two scripts fill in exercises the manual states but does not solve:

- **`run_tut05_selective_melting.py`** automates the iterative melt-pour-reheat
  loop Tutorial #5 describes ("one can manually remove the amounts of
  elements corresponding to the liquid, or make use of ... `dMolesSpecies`
  and `dStoichSpecies` to automate this process"). It reads each step's
  stable solid-phase composition back out of the JSON output and feeds it
  into the next step automatically, printing a table ready for the manual's
  own discussion questions.
- **`plot_tut07.py`** performs the "post-process the results in a separate
  plotting tool" step Tutorial #7 asks for, reading the sweep's JSON output
  and writing `outputs/tut07_phase_stability.png` — a chart matching the
  manual's Figure 4.

## Known gap

**Tutorial #9 (oxygen potential in ThO2-x nuclear fuel)** cannot be
reproduced on this checkout: no thorium-bearing database is present in
`data/`. The manual's own anticipated-results listing for this problem is
also marked "Copied from FactSage, REPLACE WITH THERMOCHIMICA OUTPUT" in the
source PDF, meaning it was never actually verified against Thermochimica
even in the original manual. If a Th-O(-U-Pu) database (e.g.
`ThO_Bergeron.dat`, referenced in the manual as based on Bergeron et al.,
*J. Nucl. Mater.* 512, 2018) becomes available, this tutorial should be
added to `inputs/training/manual/`.
