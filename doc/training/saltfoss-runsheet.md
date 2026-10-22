# SaltFoss Training — Presenter Run-Sheet (Hour 1: Thermochimica + MSTDB)

**Format:** you drive, they watch. All commands run from the repo root:
`/Users/bajpp/projects/thermochimica`. Every number below was verified on this
machine; if your live run disagrees by more than rounding, something changed —
stop and check before continuing (`git status`, rebuild, or fall back to the figure).

Total live run time for all demos: well under 20 seconds. The hour is for talking,
not waiting.

Fallback figures live in `doc/training/figures/*.png` — use them if a demo fails to
reproduce live, or to put a result on screen while you talk instead of a terminal.

---

## 0:00–0:08 — Framing (no live code)

Say, in this order:

1. "Thermochimica minimizes Gibbs energy subject to element mass balance. You give it
   **temperature, pressure, and moles of each element**. It tells you **which phases
   form, how much of each, and the speciation inside them**."
2. "For a molten salt, the liquid is reported as a **SUBQ / MQMQA phase** — in MSTDB
   it's named `MSFL`. Speciation comes back as **cation and anion fractions and
   nearest-neighbour quadruplets**, not a simple species list. That's a real
   structural difference from a dilute-solution or ideal-gas model, and it changes how
   you post-process JSON output — we'll hit this directly in Segment 4."
3. "This is **equilibrium only**. No kinetics, no transport, no release rate. It gives
   you the thermodynamic driving force and end state — which is exactly the input a
   transport model needs. That's next hour's MOOSE coupling."

---

## 0:08–0:16 — First equilibrium

```bash
./bin/InputScriptMode inputs/training/saltfoss/01_flibe_basic.ti
```

Composition: Li=2, Be=1, F=4.00001 mol (2 LiF + 1 BeF₂, perturbed — explain the
perturbation later in Segment 3). 900 K, 1 atm.

**Expect:** `5.0148 mol MSFL`, `5.0810E-06 mol gas_ideal`, 2 stable solution phases,
`DEBUG: Successful exit.`

Walk the screen output top to bottom:
- Phase assemblage block (which phases are stable, how many moles of each)
- Speciation block inside MSFL (cation/anion fractions)
- System properties: element chemical potentials, integral Gibbs energy, functional
  norm (`1.55E-06` — point out this is the convergence residual, smaller is tighter)

Teaching point: **you fed in Li, Be, F — not "LiF" or "BeF₂."** The code decided what
forms. This is the opposite of how a spreadsheet mass-balance works.

---

## 0:16–0:28 — The chemical potential trap ★ (most important segment)

Run all three back to back:

```bash
./bin/InputScriptMode inputs/training/saltfoss/02a_underdetermined.ti   # F = 4.0 exact
./bin/InputScriptMode inputs/training/saltfoss/02b_perturbed.ti         # F = 4.00001
./bin/InputScriptMode inputs/training/saltfoss/02c_fuzzy.ti             # F = 4.0 + fuzzy=.TRUE.
```

Grab the "System properties" block from each (`grep -E "^      (F|Be|Li) "`). Verified:

| Run | μ_F (kJ/mol) | μ_Be | μ_Li | μ(LiF)=μ_Li+μ_F | μ(BeF₂)=μ_Be+2μ_F |
|---|---|---|---|---|---|
| 02a exact | −118.9 | −885.0 | −553.2 | **−672.14** | **−1122.87** |
| 02b perturbed | −97.9 | −927.1 | −574.2 | **−672.10** | **−1122.95** |
| 02c fuzzy | −97.9 | −927.1 | −574.2 | **−672.10** | **−1122.95** |

Integral Gibbs energy is **identical** in all three: `-2.46715E+06 J`.

Fallback figure: `doc/training/figures/fig1_potential_invariance.png`

Deliver the lesson in this exact order:

1. "Look at the individual element potentials — they swing **20 to 40 kJ/mol** between
   runs, on a composition change of 1 part in 400,000."
2. "Now look at the species combinations — μ_Li+μ_F and μ_Be+2μ_F — those are
   **identical to under 0.1 kJ/mol** across all three runs, and the total Gibbs energy
   never moved."
3. "Why: 2 species (LiF, BeF₂) span 3 elements. That's **one equation short** —
   mathematically, the individual element potentials are under-determined. Only the
   species-level combination is physically meaningful."
4. "Rule to take home: **never report or couple a bare element chemical potential out
   of a stoichiometric salt calculation.** Use the species combination, perturb the
   input composition slightly, or set `fuzzy = .TRUE.`"
5. "`fuzzy` reproduces the perturbed answer essentially exactly — it randomly perturbs
   the stoichiometry matrix by ±1e-12 by default before solving. One caveat from the
   manual: it can introduce tiny amounts of spurious phases, so check your output."

Citation to drop here (it's the user's own paper): Piro, Poschmann & Bajpai,
*J. Nucl. Mater.* 526:151756 (2019).

---

## 0:28–0:40 — Redox control via F/U ratio ★

```bash
./bin/InputScriptMode inputs/training/saltfoss/03_redox_UF3.ti    # F=135.0, reducing
./bin/InputScriptMode inputs/training/saltfoss/03_redox_UF35.ti   # F=135.5, midpoint
./bin/InputScriptMode inputs/training/saltfoss/03_redox_UF39.ti   # F=135.9, oxidizing
```

Base salt: 66 LiF / 33 BeF₂ / 1 U, 900 K. Only the F mass balance changes.

| F input | UF₃ in melt | μ_U (kJ/mol) |
|---|---|---|
| 135.0 (reducing, UF₃ endpoint) | 1.14e−02 | −57.6 |
| 135.5 (midpoint) | 5.75e−03 | −258.1 |
| 135.9 (oxidizing, near UF₄ endpoint) | 1.15e−03 | −320.9 |

Say: "The F you put in sets the U(III)/U(IV) split you get out — that's the
fluorination state, and it's the redox state of the salt."

Then the sweep:

```bash
./bin/InputScriptMode inputs/training/saltfoss/03_redox_sweep.ti
```

800–1400 K, 50 K steps, `reinit=.TRUE.` (warm-start), `heat capacity=.TRUE.`. Runs in
**~4.8 s** for 13 points. Writes `outputs/salt_training_sweep` (JSON).

**Headline result** (pre-computed, shown as fallback figure
`doc/training/figures/fig2_redox_uf_ratio.png`): at F=135.5 — exactly midway between
the UF₃ endpoint (135.0) and UF₄ endpoint (136.0) — **U(IV)/U(III) = 1.000** at every
temperature from 800 to 1400 K. "The mass balance you type in *is* the redox state you
get."

**JSON gotchas worth showing live** (these will bite anyone who writes their own
post-processing):
- The MSFL phase JSON block has **no `"species"` key** — it has `"cations"`,
  `"anions"`, `"quadruplets"` instead (SUBQ/MQMQA format).
- Cation names are **truncated to 8 characters**: `U[CN=VII` (should be `U[CN=VII]`),
  `Be[Dimer` (should be `Be[Dimer]`). `U[Dimer]` must be weighted **×2** when summing
  total U(IV), since it's a U₂ dimer.

If you want to show this live:
```bash
python3 -I -c "
import json
d = json.load(open('outputs/salt_training_sweep'))
print(list(d['1']['solution phases']['MSFL'].keys()))
"
```

---

## 0:40–0:52 — Corrosion follows redox ★ (the business case)

```bash
./bin/InputScriptMode inputs/training/saltfoss/04_corrosion_reducing.ti    # F=135.0
./bin/InputScriptMode inputs/training/saltfoss/04_corrosion_mid.ti         # F=135.5
./bin/InputScriptMode inputs/training/saltfoss/04_corrosion_oxidizing.ti   # F=135.9
```

Same base salt + 0.01 mol Cr (structural-alloy tracer). Dissolved Cr in the melt:

| F input | Cr²⁺ | Cr³⁺ |
|---|---|---|
| 135.0 (reducing) | 1.08e−14 | 8.56e−22 |
| 135.5 (mid) | 3.65e−07 | 1.82e−10 |
| 135.9 (oxidizing) | 2.87e−05 | 1.35e−07 |

**Dissolved Cr rises ~9 orders of magnitude** across what looks like a narrow F
window. Fallback figure: `doc/training/figures/fig3_corrosion_vs_redox.png`.

Say: "This is the business case. Keep the UF₄/UF₃ buffer reduced and your structural
alloy stays intact. Let it drift oxidizing and Cr dissolves out of the metal — nine
orders of magnitude for a change that would be easy to miss in a plant log. This
number — dissolved Cr as a function of redox buffer — is exactly the kind of quantity
that becomes a **boundary condition for a MOOSE corrosion model**, which is next
session's hour."

---

## 0:52–0:58 — Off-gassing

```bash
./bin/InputScriptMode inputs/training/saltfoss/05_offgas_1atm.ti
```

Same salt + trace Cs, I (classic fission products), at 1 atm, 1200 K.

**Expect:** only `MSFL` stable (164.25 mol), `# of stable pure condensed phases = 1`,
**no gas_ideal phase** — zero moles. Say: "At a normal operating pressure, this melt
simply does not boil. A naive equilibrium run at 1 atm tells you nothing about
volatile release."

```bash
./bin/InputScriptMode inputs/training/saltfoss/05_offgas_lowP.ti
```

Same composition, **1e-6 atm** (representative of an off-gas/cover-gas system).

**Expect:** `99.729 mol gas_ideal`, speciation (mole fraction): FLi 0.647, F₂Be 0.330,
UF₄ 9.7e-03, Li 9.6e-03, F₂Li₂ 2.0e-03, F₃BeLi 8.6e-04, UF₃ 2.8e-04, ILi 2.0e-04,
Cs 1.4e-04, CsF 6.1e-05, CsI ~1.2e-06.

Fallback figure: `doc/training/figures/fig4_offgas_speciation.png`.

Say explicitly: "This is the **equilibrium** vapor composition at that pressure — not
a release *rate*. Turning this into an actual off-gas rate needs transport, which is
the MOOSE coupling."

---

## 0:58–1:00 — Wrap

Four takeaways, say them plainly, no demo:

1. Input is elements (T, P, moles); output is phases + speciation.
2. Never trust a bare element chemical potential in a stoichiometric salt — use
   species combinations, perturbation, or `fuzzy = .TRUE.`
3. The F (or Cl) mass balance sets the redox state, and redox state sets corrosion —
   quantitatively, not qualitatively.
4. This is equilibrium only. Rates, transport, and coupling to a reactor model come
   next hour with MOOSE.

Hand off to the second session.

---

## Known-broken binaries — do not demo these

`bin/TestMSTDB01`–`04`, `bin/carpet-MSRE` (missing `data/LiBeUPuThF_T1.dat`),
`bin/Thermo` (wants `C-O.dat`, repo has `CO.dat`), `bin/json`, `bin/heatCapacityLiF`,
`bin/compoundNiKF`, `bin/compoundReinit` — all reference data files not present in
`data/`. Everything in this run-sheet goes through `bin/InputScriptMode`, which does
not have this problem.

## If something breaks live

1. `git status` — confirm `inputs/training/saltfoss/*.ti` are unmodified.
2. Re-run with `print mode = 1` if the full-verbose output is too much to scroll
   through live.
3. Show the corresponding PNG in `doc/training/figures/` and keep talking — the
   numbers are the same ones you'd get from a working run.

---

## Appendix — optional liquidus demos (not in the 60-minute script)

These two demos are adapted from the official Thermochimica tutorial manual
(Piro and Poschmann, Ontario Tech University) and cover a topic the scripted
hour does not: **liquidus temperature**, i.e. where a salt is fully molten
versus partly solid. Use them only if time remains, or as follow-up material
for a second meeting — they are not timed into the 0:00–1:00 script above.

```bash
./bin/InputScriptMode inputs/training/saltfoss/06_flinak_eutectic.ti   # FLiNaK, 440 C
./bin/InputScriptMode inputs/training/saltfoss/07_flibe_liquidus_A.ti  # 74-17-9 FLiBe-UF4, 450 C
./bin/InputScriptMode inputs/training/saltfoss/07_flibe_liquidus_B.ti  # 72-16-12 FLiBe-UF4, 450 C
```

**FLiNaK (46.5 LiF - 11.5 NaF - 42 KF mol%):** at 440 °C the melt is still
partly solid (two fluorite-type FM3M phases plus solid NaF). Sweeping
temperature (`06_flinak_sweep.ti`) brackets the eutectic melting point
between 459 °C and 459.5 °C with the MSTDB V4.1 database in this repo —
close to, but not identical to, the manual's reported ~470 °C, which used an
older, export-controlled database version.

**FLiBe with increasing UF4 loading:** composition A (74 LiF-17 BeF2-9 UF4)
is still partly solid at 450 °C; composition B (72 LiF-16 BeF2-12 UF4, more
fuel) is already fully liquid at the same temperature. Bracket search shows
the liquidus falls from 555–560 °C (A) to 495–498 °C (B) — raising the
uranium loading lowers the liquidus, the same direction the manual reports
(550 °C → 480 °C with its database version). This is useful groundwork for
a reactor design conversation: how much fuel can go into the salt before
the liquidus creeps toward the operating temperature.

See `doc/training/manual-tutorials.md` for the full manual-to-input-file
mapping, including five other tutorials (H-O, Al-Mg, Fe-Cu-C, Zr-H, noble
metals) reproduced exactly against this checkout's databases.
