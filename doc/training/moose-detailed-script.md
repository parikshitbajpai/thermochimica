# Thermochimica + MOOSE — Detailed Presenter Script

**Audience:** SaltFoss. Molten salt chemists and code developers.
**Duration:** 60 to 90 minutes.
**Scope:** the MOOSE coupling. Session 1 (`saltfoss-detailed-script.md`) covers
standalone Thermochimica. This script assumes the audience has attended that
session or read its handout.

## How to read this script

This script uses controlled language, in the same style as
`saltfoss-detailed-script.md`. A sentence states one fact. A sentence uses
the active voice. A word has one meaning, every time it appears. This script
adds four terms to session 1's **Technical Term List**, for the concepts
specific to the MOOSE coupling.

Each demo block has four parts:
- **Say:** the words to speak, in controlled language.
- **Do:** the exact command to run.
- **Show:** the exact numbers the run must produce. If your numbers do not
  match, stop and check `git status` before you continue.
- **Explain:** the mechanism behind the numbers.

All commands run from `inputs/training/saltfoss_moose/` inside the
Thermochimica repo, against a MOOSE executable built with the
`thermochimica` capability. Two different executables are needed: one built
from the published `next` branch, and one built from the pending `tc_api`
branch. See the prerequisites in `doc/training/moose-runsheet.md` before you
start. Total live run time for every demo: well under a minute.

---

## Technical Term List — additions for this session

Use each term below with only the meaning given here. Session 1's term list
still applies; these four terms are new.

| Term | Meaning |
|---|---|
| **Action** | A MOOSE object that runs during input file setup and creates other objects — variables, kernels, UserObjects — on the model's behalf. `[ChemicalComposition]` is an Action, not a kernel or a UserObject itself. |
| **UserObject** | A MOOSE object that computes a value once per requested point in the simulation and stores it for other objects to read. `ThermochimicaData` is the UserObject that actually calls the Thermochimica solver, once per mesh node or element. |
| **auxiliary variable** | A field variable in MOOSE that is computed directly, not solved for by a finite-element equation. Every Thermochimica output in this session is an auxiliary variable. |
| **warm start** | Supplying a Thermochimica solve with a starting guess taken from a previous solve at the same or a nearby point, instead of starting from scratch. The current interface calls this `reinitialization_type`; the pending redesign calls it `warm_start`. |

---

## 0:00–0:08 — Segment 1: Why spatial

### Say

"Session 1 ended with one sentence: this is equilibrium only; rates,
transport, and coupling to a reactor model come next hour with MOOSE. This
hour delivers that."

"Session 1 computed one point at a time — one temperature, one pressure, one
composition, one answer. A real salt system is not one point. The
temperature varies around a loop. The composition varies with burnup and
position. This hour's first result is a single MOOSE run that computes an
independent Thermochimica equilibrium at every node of a mesh, in one solve."

"Here is why that matters, with a real example. The Virtual Test Bed, Idaho
National Laboratory's public library of reactor models, has exactly one
model that couples Thermochimica: a Molten Salt Fast Reactor model,
`msr/msfr/thermochemistry/thermo.i`. It takes a depletion history from the
neutronics code Griffin and a temperature and pressure field from the
thermal-hydraulics code Pronghorn, and runs a spatially-resolved
Thermochimica solve across the reactor. Its documented result: as the fuel
salt depletes without chemistry control, the fluorine potential rises, and
iodine volatility increases by at least four orders of magnitude. That is a
redox drift a single-point calculation cannot show you. A spatial field can."

"Where this lives in MOOSE: inside the `chemical_reactions` module. There is
no dedicated Thermochimica module. `[ChemicalComposition]` is a MOOSE
Action. It creates one scalar auxiliary variable for each element and each
requested output, and it creates one `ThermochimicaData` UserObject that
runs the actual equilibrium solve at every selected node or element. Most of
the inputs in this session have no finite-element system at all —
`[Problem] solve = false` with `[Executioner] type = Steady` is the normal
pattern when Thermochimica is the only physics. A real finite-element field
only appears when something else in the input file couples to a
Thermochimica output variable, which is Segment 6."

### Explain (no demo, concept only)

The architecture has three pieces, in order of execution:

```
[ChemicalComposition]  ->  an Action, runs at setup, creates variables
       |
       v
ThermochimicaData       ->  a UserObject, runs at execute_on, calls the solver
       |
       v
auxiliary variables      ->  hold the result, readable by any later block
```

The Action never calls Thermochimica itself. It only builds the
configuration — which elements, which database, which outputs — and hands
that configuration to the UserObject. The UserObject does the actual solve,
once per node or element, at the times given by `execute_on` (by default,
`INITIAL` and `TIMESTEP_END`).

---

## 0:08–0:20 — Segment 2: Current interface anatomy

### Say

"This demo shows the published interface — the one on the MOOSE `next`
branch, the one the Virtual Test Bed model uses. It is a four-piece pattern,
and every Thermochimica input file you will see today, on either interface,
follows some version of it."

"First: `[GlobalParams]` carries the flat output selectors — which phases,
which species, which element potentials, which vapor pressures, which
element-in-phase amounts to report — and the list of elements."

"Second: `thermofile`, `tunit`, `punit`, `munit` name the database and its
units, inside the named `[ChemicalComposition]` subblock."

"Third, and this is the detail to remember for the rest of the hour: on this
interface, the variable name encodes the selector. `mu:Mo` is the chemical
potential of molybdenum. `BCCN:Mo` is molybdenum inside the BCCN phase.
`vp:gas_ideal:Mo` is the vapor pressure of molybdenum in the ideal gas phase.
`ep:BCCN:Mo` is the amount of molybdenum element found in the BCCN phase.
You couple to these names directly, in any later block, exactly like any
other MOOSE variable — but you did not choose the name. The pending redesign
changes this, in Segment 7."

"Fourth: `[Problem] solve = false` and `[Executioner] type = Steady`. There
is no finite-element equation here. One UserObject runs once and writes its
results into the auxiliary variables."

### Do

```bash
<chemical_reactions-opt, next> -i 10_current_syntax.i
```

### Show

```
Auxiliary System:
  Variables: { "Mo" "Ru" "BCCN" "HCPN" "BCCN:Mo" "HCPN:Mo" "mu:Mo" "mu:Ru"
               "vp:gas_ideal:Mo" "ep:BCCN:Mo" }
 Solve Skipped!
```

### Explain

Point at the variable list on screen and read four names aloud, matching
each to the selector that produced it: `output_phases = 'BCCN HCPN'` made
`BCCN` and `HCPN`; `output_species = 'BCCN:Mo HCPN:Mo'` made `BCCN:Mo` and
`HCPN:Mo`; `output_element_potentials = 'mu:Mo mu:Ru'` made `mu:Mo` and
`mu:Ru`; `output_vapor_pressures = 'vp:gas_ideal:Mo'` made `vp:gas_ideal:Mo`.
This demo uses the small Mo-Ru noble-metal database, not MSTDB, purely to
show the syntax cleanly. Segments 3 onward switch to the molten-salt
database for the physics.

---

## 0:20–0:34 — Segment 3: Spatial redox ★ [HANDS-ON 1]

This is the segment that justifies the whole hour: the first result neither
session can produce any other way.

### Say

"Session 1 ran three separate calculations to sweep the fluorine mass
balance from 135.0 moles, the reducing end, to 135.9 moles, the oxidizing
end. Three runs, three single points."

"This demo runs the identical sweep as one MOOSE mesh. A `FunctionIC` varies
the fluorine composition linearly with position along a one-dimensional
mesh. `ChemicalComposition` solves an independent Thermochimica equilibrium
at every node. One solve, five points, a continuous redox profile instead
of three disconnected numbers."

### Do

```bash
<chemical_reactions-opt, next> -i 11_redox_sweep.i
cat 11_redox_sweep_out_line_0001.csv
```

### Show

```
F = 135.000   mu:F = -534,935.85 J/mol
F = 135.225   mu:F = -479,362.62 J/mol
F = 135.450   mu:F = -471,243.21 J/mol
F = 135.675   mu:F = -463,913.82 J/mol
F = 135.900   mu:F = -452,596.32 J/mol
```

### Explain

"The fluorine chemical potential rises monotonically as the fluorine mass
balance rises — exactly the trend session 1 established pointwise, now
produced as a continuous field by one solve instead of five."

"Here is the limitation to state without exception on this interface: it
cannot split uranium into U(III) and U(IV) at all. `output_species` only
resolves a plain species name. MSFL's U(III) and U(IV) forms —
`U[3+]`, `U[CN=VI]`, `U[CN=VII]`, `U[Dimer]` — are MQMQA cation
constituents, not species, and there is no flat output parameter on this
interface that reaches a constituent. `output_element_phases` only gives the
total amount of uranium in the MSFL phase, not split by oxidation state. The
fluorine chemical potential, `mu:F`, is therefore the best redox proxy
available on this interface. The actual oxidation-state split has to wait
for the `ConstituentFractions` typed output in the pending redesign —
Segment 7 shows it, on the identical sweep, producing the two columns this
interface cannot produce."

### Hands-on

Hand the file to the attendees. Have them change the `FunctionIC` endpoints
— for example, sweep 134.0 to 137.0 instead of 135.0 to 135.9 — or change
`nx` from 4 to a larger number, and rerun. Confirm the profile still runs
cleanly and the `mu:F` trend still rises with the fluorine mass balance.

---

## 0:34–0:44 — Segment 4: Off-gassing

### Say

"This demo repeats session 1's low-pressure off-gas calculation —
`05_offgas_lowP.ti` — but runs it through the MOOSE action instead of
`InputScriptMode`, to show the two give identical physics."

"Same composition: 66 moles lithium, 33 moles beryllium, 1 mole uranium,
0.02 moles cesium, 0.02 moles iodine, 135.0 moles fluorine. Same conditions:
1200 kelvin, 1 times 10 to the minus 6 atmospheres."

### Do

```bash
<chemical_reactions-opt, next> -i 12_offgas.i
```

### Show

```
gas_moles = 99.729
p_CsF     = 6.133e-11 atm
p_CsI     = 1.236e-12 atm
p_I2      = 2.369e-24 atm
```

### Explain

"Session 1's standalone run reported 99.729 moles of gas_ideal, at this
exact composition and pressure. This MOOSE run reports 99.729 moles. The two
numbers match to five significant figures, because both runs call the same
Thermochimica Gibbs-energy minimizer underneath — MOOSE only adds the
spatial wrapper."

"Repeat session 1's caveat, because it matters more here, not less: this is
the equilibrium vapor composition at this one point, not a release rate.
Getting from this number to an actual off-gas rate needs a transport model.
That gap is exactly what Segment 6 starts to close."

---

## 0:44–0:54 — Segment 5: Making it affordable

### Say

"A single equilibrium solve is fast. Forty-one of them, one per mesh node,
in one MOOSE run, are not free. This demo runs the same redox sweep as
Segment 3, on a forty-element mesh — forty-one independent equilibrium
solves — twice, with one setting changed."

"`reinitialization_type` controls whether each node's solve starts from
scratch or from the previous solution at that same node. This is the
per-node version of session 1's `reinit = .TRUE.` option — the same idea,
applied once per mesh location instead of once per sweep point."

### Do

```bash
time <chemical_reactions-opt, next> -i 13_performance.i
time <chemical_reactions-opt, next> -i 13_performance.i \
     ChemicalComposition/salt/reinitialization_type=none
```

### Show

```
reinitialization_type = nodal   ->  5.6 s wall time
reinitialization_type = none    ->  9.1 s wall time
```

### Explain

"Warm-starting from the previous solution at each node cuts the wall time by
about 40% on this machine, for this sweep. That is a real, measurable
saving, from one enum value."

"State this plainly, because the next segment changes it: this is the
current interface's entire performance story — one enum, one Thermochimica
call per node, synchronous. The pending redesign replaces this single knob
with a forked-worker, shared-memory execution model. `batch_size` groups
multiple states into one request to a worker process. `warm_start` has
three modes instead of one on-off switch. `report_performance` reports exact
counters — states solved, batches sent, warm starts used. And the worker
pool runs under real thread and MPI parallelism, not just a smarter initial
guess. The number you just saw, 5.6 seconds against 9.1, is real, but it is
the smaller of the two savings this architecture can deliver. Don't let it
stand in for the redesign's number, which you have not seen yet because it
needs the other executable."

---

## 0:54–1:05 — Coupling out ★ [HANDS-ON 2]

### Say

"Session 1 made one more promise beyond the equilibrium-only caveat: 'how
the redox and corrosion quantities from this session become boundary
conditions in a coupled model.' This demo is that promise, kept, in the
smallest form that still proves the point."

"It takes Segment 3's fluorine chemical potential profile and uses it,
directly, as the flux driving a toy field called `marker` — a stand-in for
a real corrosion-tracking variable. `marker` is a genuine finite-element
field, in `[Variables]`, solved by Newton's method. It is not a
postprocessor sitting off to the side, printed once and otherwise unused.
`mu:F` is a real coupled variable: any Kernel, boundary condition, or
Material in the input file can read it exactly like any other MOOSE
variable."

### Do

```bash
<chemical_reactions-opt, next> -i 14_coupled_bc.i
```

### Show

```
Solve Converged!
marker_right = -0.4526
```

### Explain

"The boundary condition on the right-hand boundary is a
`CoupledVarNeumannBC` — a Neumann flux condition whose magnitude comes from
a coupled variable instead of a fixed number. Here that coupled variable is
`mu:F`. The solve converges in one Newton iteration because the underlying
equation is linear, but the mechanism is the one a real model would use: an
equilibrium chemistry output, read every timestep, driving a boundary
condition on a transport equation."

"Say this explicitly, because it is the payoff of the whole segment: a real
corrosion model would couple the chromium dissolution rate from session 1 —
Segment 5 there, where Cr²⁺ spanned about nine orders of magnitude as the
redox state moved from reducing to oxidizing — through this exact
mechanism. Equilibrium chemistry output, as a boundary condition, for a
transport or kinetics model. That is the hand-off session 1 promised, and it
is now a working pattern in front of you, not a sentence on a slide."

### Hands-on

Have attendees swap `CoupledVarNeumannBC` for a different boundary condition
type — a `DirichletBC` whose value comes from an `AuxVariable`, for
instance — or point the flux at a different Thermochimica output variable
from the file, and confirm the solve still converges.

---

## 1:05–1:20 — Segment 7: The redesign, side by side

### Say

"Everything so far ran on the published interface. There is a pending pull
request — branch `tc_api`, referencing issue #22711 — that redesigns this
interface. This segment shows the same physics, twice, so you can read
either form when you see it."

"Two things change between the two forms, and only one of them is syntax."

"The syntax change: the flat selectors under `[GlobalParams]` become a typed
`[Outputs]` subblock, nested inside the named `ChemicalComposition` system.
The parameter names change too — `thermofile` becomes
`thermodynamic_database`, `tunit` becomes `temperature_unit`, and so on, all
listed in the cheatsheet. The variable names stop being encoded selectors.
You name the leaf block, and that name becomes the variable — `mu_F` instead
of `mu:F` — or you give it an explicit `variable` parameter."

"The capability change, and this is the one to remember: a new typed output
family, `ConstituentFractions`, reads an MQMQA cation fraction directly. Go
back to Segment 3's limitation. The current interface cannot split uranium
into U(III) and U(IV), full stop — there is no selector that reaches a
constituent. `ConstituentFractions` is exactly that selector. This is not a
rename of something that already existed. It is new."

### Do

```bash
<combined-opt, tc_api branch> -i 20_redox_sweep_typed.i
cat 20_redox_sweep_typed_out_line_0001.csv
<combined-opt, tc_api branch> -i 21_offgas_typed.i
```

### Show

```
mu_F   -534935.85 -> -479362.62 -> -471243.21 -> -463913.82 -> -452596.32   [J/mol]
x_U3    1.137e-02 ->  8.898e-03 ->  6.319e-03 ->  3.737e-03 ->  1.151e-03
x_U4    1.729e-06 ->  2.156e-03 ->  4.300e-03 ->  6.427e-03 ->  8.527e-03
```

```
gas_moles = 99.729
```

### Explain

"Read the `mu_F` row first. It matches Segment 3's `mu:F` row to six
figures, at every point in the sweep. Same mesh, same composition, same
physics, same answer — the rename did not change a single computed value."

"Now read `x_U3` and `x_U4`. These two columns did not exist, could not
exist, on Segment 3's interface. They are the oxidation-state split session
1 asked you to compute by hand, from three separate standalone runs, in its
own Segment 4 — here, produced directly, at every point of a continuous
spatial sweep, by one new typed output block."

"The second run, `21_offgas_typed.i`, reports the same 99.729 moles of gas
as Segment 4. Say why that number is on screen at all: this exact demo
surfaced a real bug during preparation. `pressure` set inside a named
`ChemicalComposition` subblock, on the `tc_api` branch, was being silently
overridden by the common block's registered default — always 1 atmosphere,
no matter what the subblock said. At 1 atmosphere this salt does not boil;
`gas_moles` would have read zero, the wrong answer, with no error printed
anywhere. The fix is one line, in
`ChemicalCompositionAction::initializeConfiguration()` — the call that
merges the common block's parameters into the subblock's switched from
`applyParameters()`, which also reapplies a parameter's compiled-in default,
to `applyCommonUserSetParameters()`, which only reapplies a value the common
block's own user actually set. A regression test, `pressure_override`, now
checks this directly."

"Close with `22_subblocks_typed.i` —
`typed_outputs_subblocks.i` in the MOOSE repository itself — two
independently configured `ChemicalComposition` systems on two disjoint mesh
blocks, sharing one set of composition variables. State the pattern this
enables: a model with, for example, a fuel-salt zone and a cover-gas zone in
one mesh, each with its own typed outputs, computed from one shared
composition state."

---

## 1:20 — Summary

State these four facts, in this order, with no demo:

1. `[ChemicalComposition]` is a MOOSE Action. It builds a configuration and
   hands it to one `ThermochimicaData` UserObject per named system, which
   solves an independent Thermochimica equilibrium at every selected node or
   element — the one thing standalone Thermochimica cannot do.
2. On the published interface, variable names encode their selector
   (`mu:F`, `BCCN:Mo`) and there is no way to read an MQMQA constituent
   fraction. On the pending redesign, you name the variable, and
   `ConstituentFractions` reads the oxidation-state split directly — new
   capability, not a rename.
3. A Thermochimica output is a genuine MOOSE variable. Any Kernel, boundary
   condition, or Material can couple to it — which is how an equilibrium
   redox or corrosion quantity becomes an input to a transport or kinetics
   model, the hand-off session 1 promised.
4. Performance has two layers: the published interface's single
   `reinitialization_type` enum, and the pending redesign's batched,
   warm-started, multi-threaded worker pool. Both exist because one
   Thermochimica call per mesh point, repeated at every timestep, is the
   actual cost of this coupling.

---

## Reference material

- `doc/training/moose-runsheet.md` — the short, timing-focused version of
  this script, for use during the live session.
- `doc/training/moose-interface-cheatsheet.md` — the full parameter and
  selector table, current interface against the pending redesign.
- `doc/training/moose-handout.md` — the attendee one-page reference.
- `inputs/training/saltfoss_moose/*.i` — every input run in this script.
- `typed_outputs_subblocks.i` (under `chemical_reactions/test/tests/
  thermochimica/`) and `phase_restricted_gibbs.i` (under `combined/examples/
  thermochimica_phase_field/`) in the MOOSE repository — the two examples
  closed out in Segment 7 without a full live run.
- `saltfoss-detailed-script.md` — session 1's script, for the chemistry this
  session assumes.
