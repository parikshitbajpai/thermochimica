# Thermochimica for Molten Salt Developers — Handout

Companion to the SaltFoss training session (Hour 1: standalone Thermochimica + MSTDB).
Demo files are in `inputs/training/saltfoss/`; figures in `doc/training/figures/`.

## Running a calculation — no compilation needed

```bash
cd thermochimica          # repo root
./bin/InputScriptMode inputs/training/saltfoss/01_flibe_basic.ti
```

`InputScriptMode` reads a plain-text `.ti` input file: temperature, pressure, and
composition (by element, in moles) go in; phase assemblage, speciation, and
thermodynamic properties come out. No Fortran, no rebuild, for any composition or
condition you want to explore.

## `.ti` input file keyword reference

One `tag = value` per line. Comment lines start with `!` (or `@#$%&*/\?|`). Element
masses use the **atomic number** in parentheses.

| Keyword | Meaning |
|---|---|
| `temperature` | Scalar, or `lo:hi:step` for a sweep (e.g. `800:1400:50`) |
| `pressure` | Scalar, or `lo:hi:step` |
| `mass(Z) = x` | Moles of element with atomic number Z (e.g. `mass(92)` = U) |
| `temperature unit` | `K`, `C`, `F`, or `R` |
| `pressure unit` | `atm`, `psi`, `bar`, `Pa`, `kPa` |
| `mass unit` | e.g. `moles` |
| `data file` | path to the ChemSage `.dat` database |
| `print mode` | `0` silent, `1` summary, `2` full screen output |
| `write json` / `output` | enable JSON output / set its filename (default `.TRUE.`) |
| `heat capacity` | `.TRUE.` to also compute/report Cp, H, S |
| `reinit` | `.TRUE.` to warm-start each point in a sweep from the previous solution (faster) |
| `step together` | `.TRUE.` to step T and P as paired sequences instead of a nested grid |
| `fuzzy` / `fuzzy mag` | perturb the stoichiometry matrix to resolve under-determined systems (see below); default magnitude 1e-12 |
| `number excluded` / `phases excluded` | exclude named phases (count first, then space-separated names) |
| `number excluded except` / `phases excluded except` | whitelist — exclude everything except the named phases |
| `gibbs min` | `.TRUE.` for a post-hoc global-minimum verification pass |

Full parser: `src/parser/ParseInput.f90`. `RunCalculationList` (via
`bin/RunCalculationList`) takes the same unit/data-file/exclusion keywords plus
`nEl`/`iEl`/`nCalc` for an explicit list of (T, P, composition) rows rather than a grid.

## The rule that will save you the most debugging time

**A stoichiometric salt under-determines individual element chemical potentials.**

If your melt forms only 2 species (e.g. LiF, BeF₂) from 3 elements (Li, Be, F), the
system has one fewer independent equation than elements. The *species-level*
potentials (μ_LiF, μ_BeF₂) are physical and reproducible; the *individual element*
potentials (μ_Li, μ_Be, μ_F individually) are not — they can swing tens of kJ/mol on a
sub-ppm composition change while the species combinations stay fixed to <0.1 kJ/mol.

**Never report or couple a bare element chemical potential out of a stoichiometric
salt calculation.** Three remedies, in order of preference:
1. Use the species-level combination (μ_cation + ν·μ_anion) instead of individual
   element potentials.
2. Perturb one input mass slightly off the exact stoichiometric ratio (e.g. F =
   4.00001 instead of 4.0).
3. Set `fuzzy = .TRUE.` to let Thermochimica perturb the stoichiometry matrix for you
   (`src/setup/RandomizeStoichiometry.f90`). Caveat: can introduce tiny spurious trace
   phases — inspect your output.

Reference: Piro, Poschmann & Bajpai, *J. Nucl. Mater.* 526:151756 (2019). Also
`doc/thermochimica_user_manual.pdf` §3.9 "Fuzzy Stoichiometry".

## MQMQA / SUBQ JSON output — structural gotchas

MSTDB's molten salt liquid (`MSFL` for fluorides, `MSCL` for chlorides) is a
quasichemical (MQMQA/SUBQ) phase. Its JSON block is **not** shaped like a simple
solution phase:

- **No `"species"` key.** Instead: `"cations"`, `"anions"`, `"quadruplets"`,
  `"endmembers"`. Code written against a generic `species` block will raise
  `KeyError` on this phase.
- **Constituent names are truncated to 8 characters** in some printed/JSON contexts —
  `U[CN=VII` (actually `U[CN=VII]`), `Be[Dimer` (actually `Be[Dimer]`).
- **Dimer constituents count double.** `U[Dimer]` represents a U₂ unit — weight its
  mole fraction ×2 when summing total U content by oxidation state.
- `python/thermoTools.py`'s `makePlot()` assumes the simple `species` shape and will
  not plot MQMQA phases correctly — write your own parser against `cations`/
  `anions`/`quadruplets` (see `doc/training/make_figures.py` for a worked example).

## MSTDB databases available in this repo

| File | Elements | Salt phase | Gas phase |
|---|---|---|---|
| `data/MSD-TC_V4.1_Fluorides_No_Func.dat` | 33, incl. Li/Be/Na/K/Cs, Cr/Fe/Ni, U/Pu/Th + lanthanides | `MSFL` (SUBQ) | `gas_ideal`, 148 species |
| `data/MSD-TC_V4.1_Chlorides_No_Func.dat` | 33, incl. Li/Na/K/Mg/Ca, Cr/Fe/Ni, U/Pu + lanthanides | `MSCL` (SUBQ) | `gas_ideal`, 149 species |

Both cover redox pairs (UF₃/UF₄, UCl₃/UCl₄), structural-metal fluorides/chlorides
(Cr, Fe, Ni), and volatile fission-product species (Cs, I, Xe, Kr halides).

**MSTDB-TC licensing note:** these database files are redistributed in this repo for
internal/training use; MSTDB-TC is separately licensed — confirm your own
distribution terms with the MSTDB maintainers before using it outside this
engagement.

## Known-broken example programs — avoid these

`bin/TestMSTDB01`–`04`, `bin/carpet-MSRE`, `bin/Thermo`, `bin/json`,
`bin/heatCapacityLiF`, `bin/compoundNiKF`, `bin/compoundReinit` all reference
database files that are not present in `data/` on this checkout (e.g.
`LiBeUPuThF_T1.dat`, `C-O.dat` vs. the actual `CO.dat`). Everything in this
training uses `bin/InputScriptMode`, which does not have this problem.

## Where to go next

- `doc/numerical_tolerances.md` — minimum resolvable mole fraction, GEM conditioning,
  the `SetMinMoleFraction` API (relevant for trace fission products / dilute redox
  tracers).
- `doc/thermochimica_user_manual.pdf` — API reference, phase exclusion (§3.8), fuzzy
  stoichiometry (§3.9), reinitialization (§3.10 — the mechanism behind
  `reinit = .TRUE.`, and the basis for the MOOSE coupling in the second session).
- `python/thermoTools.py` — programmatic `.ti` generation and JSON plotting (for
  simple, non-MQMQA phases).
- `doc/training/manual-tutorials.md` — the official Thermochimica tutorial manual's
  twelve worked problems, each mapped to a runnable input file on this checkout
  (H-O, CsI, Al-Mg, Fe-Cu-C, Zr-H, Fe-C heating, noble metal plating, FLiNaK, and
  FLiBe liquidus), including two liquidus demos (`inputs/training/saltfoss/06_*`,
  `07_*`) not covered in the scripted hour.
- Second training session: MOOSE coupling — the C/C++ API (`Thermochimica.h`,
  `Thermochimica-cxx.h`), the reinitialization mechanism that makes per-timestep,
  per-integration-point calls affordable, and how the redox/corrosion quantities from
  this session become boundary conditions in a coupled model.
