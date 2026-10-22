# Thermochimica for Molten Salts — Detailed Presenter Script

**Audience:** SaltFoss. Molten salt chemists and code developers.
**Duration:** 60 minutes.
**Scope:** standalone Thermochimica only. The MOOSE coupling has its own session.

## How to read this script

This script uses controlled language. A sentence states one fact. A sentence uses
the active voice. A word has one meaning, every time it appears. The style follows
ASD-STE100 (the aerospace maintenance writing standard), extended with the technical
terms this subject needs. ASD-STE100 does not cover thermochemistry, so this script
adds a **Technical Term List** below. Each term in the list has one fixed meaning
for the rest of the script.

Each demo block has four parts:
- **Say:** the words to speak, in controlled language.
- **Do:** the exact command to run.
- **Show:** the exact numbers the run must produce. If your numbers do not match,
  stop and check `git status` before you continue.
- **Explain:** the science behind the numbers, with the equation that predicts them.

All commands run from the repo root: `/Users/bajpp/projects/thermochimica`.
Total live run time for all demos: under 20 seconds.

---

## Technical Term List

Use each term below with only the meaning given here.

| Term | Meaning |
|---|---|
| **element mass balance** | The rule that the total moles of each chemical element do not change during the calculation. |
| **Gibbs energy** | The energy value that a chemical system moves to make as low as possible, at fixed temperature and pressure. The symbol is G. |
| **equilibrium state** | The one arrangement of phases and species that gives the system the lowest possible Gibbs energy, for the given temperature, pressure, and element mass balance. |
| **phase** | A part of the system with one set of physical properties, for example the molten salt liquid or a gas. |
| **species** | One specific chemical form inside a phase, for example the LiF unit inside the molten salt liquid. |
| **speciation** | The list of species present in a phase, and the amount of each. |
| **chemical potential of an element** | A number, in joules per mole, that states how much the Gibbs energy of the system changes when you add one more mole of that element. The symbol is μ, read "mu." |
| **chemical potential of a species** | The same idea, but for one mole of a specific species instead of one element. |
| **quasichemical model** | The mathematical model Thermochimica uses for a molten salt liquid. The model groups two cations and two anions into one unit, called a quadruplet. |
| **cation** | A positively charged ion in the molten salt liquid, for example Li⁺ or U³⁺. |
| **anion** | A negatively charged ion in the molten salt liquid, for example F⁻. |
| **redox state** | The balance between the reduced form and the oxidized form of an element. For uranium in this salt, the redox state is the balance between U³⁺ and U⁴⁺. |
| **oxidation number** | A whole number that states the charge an atom would have if every bond were fully ionic. UF₃ gives uranium the oxidation number +3. UF₄ gives uranium the oxidation number +4. |
| **mean oxidation number** | The oxidation number of an element, averaged over every form of that element present, weighted by the amount of each form. |
| **redox buffer** | A pair of oxidation states of one element that, together, hold the chemical potential of the melt steady against small changes in composition. |
| **under-determined system** | A chemical system in which the number of independent species is smaller than the number of elements. In this case, you cannot compute every element chemical potential uniquely. |
| **null space** | The set of changes to the chemical potentials that leave the Gibbs energy of every species unchanged. An under-determined system has a null space that is not just zero. |
| **fuzzy stoichiometry** | A Thermochimica option that adds a very small random change to the stoichiometry matrix, to remove an under-determined system. |
| **mass balance ratio** | In this script, the ratio of total fluorine moles supplied to the moles needed for a stated uranium fluoride. |
| **bubble point** | The lowest pressure, at a given temperature and composition, at which a stable gas phase first appears above a liquid. |
| **off-gas** | The gas phase that forms above a molten salt and may carry volatile species out of the system. |
| **volatile species** | A chemical species with a high enough vapor pressure to leave the liquid and enter the gas phase in meaningful amount. |
| **mole fraction** | The amount of one species or ion, divided by the total amount of all species or ions in the same phase or sublattice. |
| **JSON output** | The machine-readable output file Thermochimica writes, in JavaScript Object Notation format. |

---

## 0:00–0:08 — Segment 1: What the calculation does

### Say

"Thermochimica computes the equilibrium state of a chemical system."

"You give the program three things: the temperature, the pressure, and the mass
balance of each element in the system."

"The program computes the Gibbs energy of every possible combination of phases and
species. It finds the combination with the lowest Gibbs energy. That combination is
the equilibrium state."

"You do not give the program a list of compounds. You give it elements. In the
first demo, you will give the program lithium, beryllium, and fluorine. The program
will decide, by itself, that these elements form LiF and BeF₂."

"For a molten salt, Thermochimica reports the liquid phase with a quasichemical
model. The model groups two cations and two anions into one quadruplet. The program
reports speciation as cation mole fractions, anion mole fractions, and quadruplet
mole fractions. It does not report a simple list of molecules the way an ideal gas
phase does. This difference matters when you write code to read the output file. You
will see this difference directly in Segment 4."

"This is an equilibrium calculation. It does not compute a reaction rate. It does
not compute how fast a species moves from one place to another. It computes the end
state and the driving force toward that end state. A reaction-rate model needs this
end state as an input. That kind of model is the subject of the next session, where
Thermochimica couples to MOOSE."

### Explain (no demo, concept only)

The condition for equilibrium at fixed T and P is:

```
dG = 0   at fixed T, P, and total moles of each element
```

G is a function of how much of each phase and species exists. Thermochimica finds
the values that make dG as close to zero as the solver tolerance allows, subject to
the mass balance constraint for each element. The scalar it reports as "functional
norm" is a measure of how close dG is to zero at the reported solution — smaller is
a tighter solution.

---

## 0:08–0:16 — Segment 2: First equilibrium calculation

### Say

"This demo computes the equilibrium state of a mixture of lithium, beryllium, and
fluorine, at 900 kelvin and 1 atmosphere."

"The mass balance is 2 moles of lithium, 1 mole of beryllium, and 4.00001 moles of
fluorine. This ratio is close to 2 LiF plus 1 BeF₂, the eutectic composition of the
LiF-BeF₂ salt system. The reason for the extra 0.00001 moles of fluorine comes in the
next segment."

### Do

```bash
./bin/InputScriptMode inputs/training/saltfoss/01_flibe_basic.ti
```

### Show

```
5.0148 mol MSFL
5.0810E-06 mol gas_ideal
# of stable solution phases       =   2
DEBUG: Successful exit.
```

### Explain

Walk the printed output top to bottom:

1. **Phase assemblage.** The program reports two stable phases: MSFL, the molten
   salt liquid, at 5.0148 mol, and gas_ideal, the ideal gas, at 5.08×10⁻⁶ mol. The
   gas amount is six orders of magnitude smaller than the liquid amount. At 900 K and
   1 atm, this salt is almost entirely liquid.
2. **Speciation inside MSFL.** The program reports cation mole fractions and anion
   mole fractions, not a simple species list, because MSFL uses the quasichemical
   model.
3. **System properties.** The program reports one chemical potential value for each
   element: fluorine, beryllium, and lithium. It also reports the integral Gibbs
   energy of the whole system, in joules, and the functional norm, the convergence
   measure described in Segment 1.

The mass balance you gave the program — 2 Li, 1 Be, 4.00001 F — did not state "LiF"
or "BeF₂" anywhere. The program found those two species by minimizing Gibbs energy,
not because you named them.

---

## 0:16–0:28 — Segment 3: Element chemical potentials in a two-species system ★

This is the most important segment in the hour. The result below is the subject of
the user's own published work: Piro, Poschmann, and Bajpai, *Journal of Nuclear
Materials*, volume 526, page 151756, year 2019.

### Say

"The LiF-BeF₂ liquid you just computed has two independent species: LiF and BeF₂.
The system has three elements: lithium, beryllium, and fluorine."

"Two species cannot fix three independent element chemical potentials. The system
has one fewer independent equation than it has elements. This condition is called an
under-determined system."

"An under-determined system still gives one correct value for the Gibbs energy of
the whole system. It still gives one correct value for the chemical potential of
each species. It does not give one correct value for the chemical potential of each
element, taken alone."

"The next three runs show this directly."

### Do — run 1: exact stoichiometry

```bash
./bin/InputScriptMode inputs/training/saltfoss/02a_underdetermined.ti
```

### Show — run 1

```
F     4.0000E+00    -1.189198E+05 J/mol
Be    1.0000E+00    -8.850279E+05 J/mol
Li    2.0000E+00    -5.532193E+05 J/mol
Integral Gibbs energy = -2.46715E+06 J
```

### Do — run 2: fluorine perturbed by one part in 400,000

```bash
./bin/InputScriptMode inputs/training/saltfoss/02b_perturbed.ti
```

### Show — run 2

```
F     4.0000E+00    -9.790519E+04 J/mol
Be    1.0000E+00    -9.271442E+05 J/mol
Li    2.0000E+00    -5.741906E+05 J/mol
Integral Gibbs energy = -2.46715E+06 J
```

### Do — run 3: exact stoichiometry, with the fuzzy stoichiometry option set

```bash
./bin/InputScriptMode inputs/training/saltfoss/02c_fuzzy.ti
```

### Show — run 3

```
F     4.0000E+00    -9.790519E+04 J/mol
Be    1.0000E+00    -9.271440E+05 J/mol
Li    2.0000E+00    -5.741907E+05 J/mol
Integral Gibbs energy = -2.46715E+06 J
```

### Explain

Put the three results in one table on screen or on a whiteboard:

| Run | μ_F (kJ/mol) | μ_Be (kJ/mol) | μ_Li (kJ/mol) |
|---|---|---|---|
| 1. Exact | −118.9 | −885.0 | −553.2 |
| 2. Perturbed | −97.9 | −927.1 | −574.2 |
| 3. Fuzzy | −97.9 | −927.1 | −574.2 |

The three element chemical potentials change between run 1 and run 2. The change in
each one is:

```
Δμ_F  = μ_F(run 2)  − μ_F(run 1)  = +21.01 kJ/mol
Δμ_Be = μ_Be(run 2) − μ_Be(run 1) = −42.12 kJ/mol
Δμ_Li = μ_Li(run 2) − μ_Li(run 1) = −20.97 kJ/mol
```

Take the ratio of each change to Δμ_F:

```
Δμ_Li / Δμ_F = −20.97 / 21.01 = −0.998   ≈ −1
Δμ_Be / Δμ_F = −42.12 / 21.01 = −2.004   ≈ −2
```

This is not a coincidence. It comes directly from the two species in the system.

LiF has one lithium atom and one fluorine atom. The chemical potential of the
species LiF is a fixed, well-defined number:

```
μ(LiF) = μ_Li + μ_F
```

BeF₂ has one beryllium atom and two fluorine atoms. Its chemical potential is also
fixed:

```
μ(BeF₂) = μ_Be + 2·μ_F
```

For μ(LiF) and μ(BeF₂) to stay fixed while μ_F changes by some amount Δμ_F, the
other two element potentials must change to cancel that amount exactly:

```
μ_Li must change by  −Δμ_F   to hold μ_Li + μ_F fixed
μ_Be must change by  −2·Δμ_F to hold μ_Be + 2·μ_F fixed
```

This is exactly the −1 and −2 ratios measured above. The set of changes
(Δμ_F, Δμ_Li, Δμ_Be) = (1, −1, −2)·Δμ_F is called the null space of the
stoichiometry matrix for this system: any multiple of this direction leaves every
species chemical potential, and the total Gibbs energy, unchanged. The solver found
a different point in this one-parameter family in run 1 than in run 2, because the
tiny change in the fluorine mass balance moved the numerical solution along the null
space direction.

Confirm the species-level chemical potentials stayed fixed:

```
μ(LiF)  = μ_Li + μ_F     run 1: −672.14 kJ/mol   run 2: −672.10 kJ/mol   run 3: −672.10 kJ/mol
μ(BeF₂) = μ_Be + 2·μ_F   run 1: −1122.87 kJ/mol  run 2: −1122.95 kJ/mol  run 3: −1122.95 kJ/mol
```

All three runs agree to under 0.1 kJ/mol. The integral Gibbs energy is identical in
all three runs: −2.46715×10⁶ J.

**The rule:** do not report or use the chemical potential of a single element from a
calculation on a stoichiometric molten salt. Report or use the chemical potential of
a species instead. If your code must compute an element chemical potential, remove
the under-determined condition first. Three ways to do this:

1. Change one input mass away from the exact stoichiometric ratio, as in run 2.
2. Set `fuzzy = .TRUE.` in the input file, as in run 3. This option adds a small
   random change, by default ±1×10⁻¹² mole, to each nonzero entry of the
   stoichiometry matrix before the solver runs. It removes the null space the same
   way a manual perturbation does, without you choosing which mass to change.
3. Use a database with an explicit vacancy species on the relevant sublattice. This
   method is outside the scope of this demo.

**Caution:** the fuzzy stoichiometry option can place a very small, non-physical
amount of an extra phase into the result. Check your phase assemblage after you use
this option.

---

## 0:28–0:40 — Segment 4: Redox state from the fluorine mass balance ★

### Say

"The next three runs hold lithium, beryllium, and uranium fixed. Only the fluorine
mass balance changes."

"UF₃ needs three fluorine atoms for each uranium atom. UF₄ needs four. The ratio of
fluorine moles to uranium moles, after you subtract the fluorine already used by the
lithium and beryllium, sets how much of the uranium in the system takes the +3
oxidation number and how much takes the +4 oxidation number."

### Do

```bash
./bin/InputScriptMode inputs/training/saltfoss/03_redox_UF3.ti      # F = 135.0 mol
./bin/InputScriptMode inputs/training/saltfoss/03_redox_UF35.ti     # F = 135.5 mol
./bin/InputScriptMode inputs/training/saltfoss/03_redox_UF39.ti     # F = 135.9 mol
```

### Explain — the mass balance ratio

Define the mean oxidation number of uranium, v̄, from the input masses alone:

```
v̄ = (n_F − n_Li − 2·n_Be) / n_U
```

n_Li = 66 mol and n_Be = 33 mol take up 66 + 2×33 = 132 mol of fluorine as LiF and
BeF₂. The remaining fluorine goes to uranium. For the three runs:

```
run         n_F      remaining F = n_F − 132     v̄ = remaining F / n_U
F = 135.0   135.0    3.0                          3.00
F = 135.5   135.5    3.5                          3.50
F = 135.9   135.9    3.9                          3.90
```

### Show

The program reports the cation mole fractions of every uranium oxidation state
inside the MSFL liquid. Sum the +4 states — U[CN=VI], U[CN=VII], and U[Dimer]
(counted twice, because each dimer unit holds two uranium atoms) — to get the total
+4 fraction:

| run | x(U³⁺) | x(U⁴⁺) | computed v̄ = 3·x(U³⁺) + 4·x(U⁴⁺) |
|---|---|---|---|
| F = 135.0 | 0.999818 | 0.000182 | 3.000182 |
| F = 135.5 | 0.500000 | 0.500000 | 3.500000 |
| F = 135.9 | 0.100000 | 0.900000 | 3.900000 |

The computed mean oxidation number matches the mass balance ratio you set on input,
to four decimal places or better in every run. **The fluorine mass balance you
choose on input is the redox state of the uranium you get on output.** This is a
direct, checkable identity, not an approximation.

### The equilibrium constant behind the ratio

The redox reaction between the two uranium fluorides, written in terms of one atom
of fluorine, is:

```
UF4 (in melt)  ⇌  UF3 (in melt)  +  F (as tracked by the element chemical potential)
```

The element chemical potential of fluorine, μ_F, is exactly the quantity
Thermochimica reports for one atom of fluorine, not for the F₂ molecule. At
equilibrium, the ratio of the two uranium cation mole fractions obeys:

```
ln [ x(U⁴⁺) / x(U³⁺) ] = (μ_F − μ_F°) / RT
```

where R is the gas constant, 8.314 J/(mol·K), T is the absolute temperature, and μ_F°
is a reference value fixed by the melt composition and the database. This is a
Nernst-type relation: the log of the redox ratio is linear in the fluorine chemical
potential.

Check this with the three runs, at T = 900 K, so RT = 7483 J/mol:

| run | μ_F (kJ/mol) | ln[x(U⁴⁺)/x(U³⁺)] measured |
|---|---|---|
| F = 135.0 | −534.94 | −8.613 |
| F = 135.5 | −469.66 | 0.000 |
| F = 135.9 | −452.60 | 2.197 |

A least-squares fit of ln(ratio) against μ_F over these three points gives a slope of
1.31×10⁻⁴ mol/J. The predicted slope is 1/RT = 1.336×10⁻⁴ mol/J. The fitted value and
the predicted value agree to within 2%. The small remaining difference comes from the
melt not being an ideal solution — the quasichemical model adds composition-dependent
terms to μ_F° itself, which a three-point fit cannot separate from the ideal term.

### Do — temperature sweep

```bash
./bin/InputScriptMode inputs/training/saltfoss/03_redox_sweep.ti
```

### Show

13 points from 800 K to 1400 K, in 50 K steps, computed in about 4.8 seconds.
U(IV)/U(III) = 1.000 at every temperature in the sweep, because F = 135.5 mol sets
v̄ = 3.5 at every temperature — the mass balance does not depend on temperature. Show
`doc/training/figures/fig2_redox_uf_ratio.png` if you want a static image of this
flat line.

### JSON output structure — two things that will break naive code

**Say:** "If your team writes code to read Thermochimica's JSON output for a molten
salt phase, two structural points will cause errors if you do not know about them in
advance."

1. The MSFL phase block has no key named "species." It has keys named "cations",
   "anions", and "quadruplets" instead, because MSFL uses the quasichemical model.
   Code written for a simple phase will raise a key error on MSFL.
2. Some cation names are eight characters long in the database and get truncated to
   eight characters in the output: `U[CN=VII` instead of `U[CN=VII]`, and
   `Be[Dimer` instead of `Be[Dimer]`. A name ending in `[Dimer` represents two atoms
   of that element bound as one unit — its mole fraction must be multiplied by 2
   when you sum total element content by oxidation state, as shown in the table
   above.

```bash
python3 -I -c "
import json
d = json.load(open('outputs/salt_training_sweep'))
print(list(d['1']['solution phases']['MSFL'].keys()))
"
```

---

## 0:40–0:52 — Segment 5: Corrosion as a function of redox state ★

### Say

"The next three runs add 0.01 mole of chromium metal to the same salt. Chromium
stands in for a structural alloy in contact with the molten salt."

"Only the fluorine mass balance changes between the three runs, exactly as in
Segment 4."

### Do

```bash
./bin/InputScriptMode inputs/training/saltfoss/04_corrosion_reducing.ti    # F = 135.0
./bin/InputScriptMode inputs/training/saltfoss/04_corrosion_mid.ti         # F = 135.5
./bin/InputScriptMode inputs/training/saltfoss/04_corrosion_oxidizing.ti   # F = 135.9
```

### Show

The program reports a stable solid phase, Cr_BCC(s), in every run. This solid phase
is the undissolved chromium metal. The amount of chromium that leaves the metal and
enters the melt, as Cr²⁺ and Cr³⁺ cations, is the mass balance difference:

| run | Cr_BCC(s), mol | Cr dissolved, mol | % of Cr dissolved |
|---|---|---|---|
| F = 135.0 (reducing) | 1.000×10⁻² | 9.41×10⁻¹³ | 0.0000% |
| F = 135.5 (mid) | 9.968×10⁻³ | 3.18×10⁻⁵ | 0.318% |
| F = 135.9 (oxidizing) | 7.495×10⁻³ | 2.50×10⁻³ | 25.05% |

A quarter of the chromium metal dissolves into the salt at the oxidizing end point,
against essentially none at the reducing end point.

Report the cation mole fractions directly, for the chart on screen:

| F input | Cr²⁺ mole fraction | Cr³⁺ mole fraction |
|---|---|---|
| 135.0 | 1.08×10⁻¹⁴ | 8.56×10⁻²² |
| 135.5 | 3.65×10⁻⁷ | 1.82×10⁻¹⁰ |
| 135.9 | 2.87×10⁻⁵ | 1.35×10⁻⁷ |

Show `doc/training/figures/fig3_corrosion_vs_redox.png` for the chart form of this
table.

### Explain — the reaction and its order

Chromium corrosion in a fluoride melt proceeds by a reaction with the uranium redox
buffer. The two-electron reaction is:

```
Cr (metal)  +  2 UF4 (in melt)  ⇌  CrF2 (in melt)  +  2 UF3 (in melt)
```

The three-electron reaction, for the more oxidized chromium state, is:

```
Cr (metal)  +  3 UF4 (in melt)  ⇌  CrF3 (in melt)  +  3 UF3 (in melt)
```

Each reaction fixes an equilibrium constant, K₂ for the first and K₃ for the second,
in terms of mole fractions:

```
K2 = x(Cr2+) / [ x(UF4)/x(UF3) ]^2
K3 = x(Cr3+) / [ x(UF4)/x(UF3) ]^3
```

If K₂ and K₃ do not change much over the small range of melt composition in these
three runs, then x(Cr²⁺) must scale as the square of the UF₄/UF₃ ratio, and x(Cr³⁺)
must scale as the cube of the same ratio. Check this directly from the computed
mole fractions:

| run | UF₄/UF₃ ratio | x(Cr²⁺) | x(Cr²⁺) ÷ ratio² | x(Cr³⁺) | x(Cr³⁺) ÷ ratio³ |
|---|---|---|---|---|---|
| F = 135.0 | 1.82×10⁻⁴ | 1.08×10⁻¹⁴ | 3.27×10⁻⁷ | 8.56×10⁻²² | 1.42×10⁻¹⁰ |
| F = 135.5 | 1.000 | 3.65×10⁻⁷ | 3.66×10⁻⁷ | 1.82×10⁻¹⁰ | 1.82×10⁻¹⁰ |
| F = 135.9 | 8.522 | 2.87×10⁻⁵ | 3.95×10⁻⁷ | 1.35×10⁻⁷ | 2.18×10⁻¹⁰ |

The column x(Cr²⁺) ÷ ratio² stays close to 3.3–3.9×10⁻⁷ across three runs that span
five orders of magnitude in the UF₄/UF₃ ratio. A least-squares fit of
log[x(Cr²⁺)] against log(ratio) over these three points gives a slope of 2.02. A
matching fit for x(Cr³⁺) gives a slope of 3.04. Both match the integer reaction
orders — 2 and 3 — predicted by the electron count in the two reactions above.

**The result to state plainly:** dissolved chromium rises by about nine orders of
magnitude from the most reducing run to the most oxidizing run, and it rises as a
power of the uranium redox ratio with the exact exponent the reaction chemistry
predicts. This is not a loose trend. It is the signature of a specific chemical
reaction, confirmed by the program's own output.

**Tie to the next session:** this redox-to-corrosion relation is exactly the kind of
quantity a MOOSE corrosion model needs as a boundary condition. The next session
covers how to pass it from Thermochimica into a coupled transport calculation.

---

## 0:52–0:58 — Segment 6: Off-gassing and the bubble point

### Say

"The next two runs add small amounts of cesium and iodine to the same base salt.
Cesium and iodine stand in for two classic volatile fission products."

"The first run uses 1 atmosphere pressure, a normal operating pressure. The second
run uses a much lower pressure, representative of an off-gas or cover-gas system."

### Do — run at 1 atmosphere

```bash
./bin/InputScriptMode inputs/training/saltfoss/05_offgas_1atm.ti
```

### Show

```
164.25 mol MSFL
# of stable pure condensed phases =   1
# of stable solution phases       =   1
```

No gas_ideal phase appears in the assemblage. Its stable amount is zero.

### Explain — the bubble point

A gas phase becomes stable only when the total vapor pressure the melt would exert,
at the given temperature and composition, reaches the system pressure you set. The
pressure at which this first happens is the bubble point.

A bracket search at 1200 K, with this composition, narrows the bubble point to
between 2.2×10⁻³ atm and 2.4×10⁻³ atm. State plainly: this melt does not boil
anywhere near 1 atmosphere. A calculation run at 1 atmosphere will always report
zero gas, for this salt, at this temperature, and will tell you nothing about
volatile release.

### Do — run below the bubble point

```bash
./bin/InputScriptMode inputs/training/saltfoss/05_offgas_lowP.ti
```

### Show

```
99.729 mol gas_ideal
```

with this vapor composition, by mole fraction:

| species | mole fraction |
|---|---|
| FLi (carrier) | 0.647 |
| F2Be (carrier) | 0.330 |
| UF4 | 9.72×10⁻³ |
| Li | 9.58×10⁻³ |
| F2Li2 | 2.03×10⁻³ |
| F3BeLi | 8.64×10⁻⁴ |
| UF3 | 2.85×10⁻⁴ |
| ILi | 1.99×10⁻⁴ |
| Cs | 1.36×10⁻⁴ |
| CsF | 6.13×10⁻⁵ |
| CsI | 1.24×10⁻⁶ |

Show `doc/training/figures/fig4_offgas_speciation.png` for the chart form.

Point out two facts. First, the two carrier species, FLi and F2Be, hold 97.7% of the
gas phase. These come from the bulk salt, not from the fission products. Second, the
uranium and cesium and iodine species are a small part of the vapor by mole
fraction, but they are present, with a defined composition, at any pressure below
the bubble point.

### The one caution to state without exception

"This is the equilibrium vapor composition at that pressure and temperature. It is
not a release rate. The program does not compute how fast a species crosses from
the liquid to the gas, or how fast the gas phase leaves the system. Getting from
this equilibrium composition to an actual off-gas rate needs a transport model. That
model, and how it uses this equilibrium result as an input, is the subject of the
next session."

---

## 0:58–1:00 — Segment 7: Summary

State these four facts, in this order, with no demo:

1. The input to a Thermochimica calculation is temperature, pressure, and the mass
   balance of each element. The output is the stable phases, the amount of each, and
   the speciation inside each phase.
2. A stoichiometric molten salt is an under-determined system for its individual
   element chemical potentials. Report species chemical potentials instead. Use a
   small perturbation or the fuzzy stoichiometry option if you must compute an
   element chemical potential.
3. The halide mass balance sets the redox state of a multivalent element. The redox
   state sets the corrosion rate of a structural metal, through an equilibrium
   reaction with an integer reaction order that this session confirmed directly from
   program output.
4. This is an equilibrium calculation. It does not give you a rate. A rate comes from
   a transport model, coupled to Thermochimica. That coupling is the subject of the
   next session.

---

## Reference material

- Piro, M. H. A., Poschmann, M., and Bajpai, P. "On the interpretation of chemical
  potentials computed from equilibrium thermodynamic codes: Applications to molten
  salts." *Journal of Nuclear Materials*, volume 526, page 151756, 2019.
- `doc/thermochimica_user_manual.pdf`, section 3.9, "Fuzzy Stoichiometry."
- `doc/training/saltfoss-runsheet.md` — the short, timing-focused version of this
  script, for use during the live session.
- `doc/training/saltfoss-handout.md` — the attendee one-page reference.
- `doc/numerical_tolerances.md` — the minimum resolvable mole fraction and solver
  conditioning, relevant to trace fission product and dilute redox tracer
  calculations.
