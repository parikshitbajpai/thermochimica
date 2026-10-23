# SaltFoss Training — Presenter Run-Sheet (Hour 2: MOOSE Coupling)

**Format:** two short hands-on exercises, rest you drive and they watch. Inputs
are in `inputs/training/saltfoss_moose/`, numbered to continue session 1
(`inputs/training/saltfoss/`). Every number below was verified on this
machine; if a live run disagrees by more than rounding, stop and check before
continuing.

**Prerequisites** (confirm before the session, not live):
- A Thermochimica-enabled MOOSE executable. The current-interface decks
  (10-14) need `modules/chemical_reactions/chemical_reactions-opt` built from
  the `next` branch with `git submodule update --init --checkout
  modules/chemical_reactions/contrib/thermochimica`. The redesigned-interface
  decks (20-22) need `modules/combined/combined-opt` built from the `tc_api`
  branch. Check `<exe> --show-capabilities | grep -A2 thermochimica` reports
  `"value": true` on both before the session.
- The input files hard-code `/Users/bajpp/projects/thermochimica/data/...` as
  the database path (Thermochimica resolves `thermodynamic_database` /
  `thermofile` against the INPUT FILE's directory, not the shell's CWD, so a
  bare filename only works when the `.dat` sits beside the `.i`). Edit the
  path in each file if running from a different checkout.

Total live run time for every demo: well under a minute. The hour is for
talking and for the two hands-on exercises, not for waiting on solves.

---

## 0:00–0:08 — Why spatial (no live code)

Say, in this order:

1. Recap session 1's closing line: *"This is equilibrium only. Rates,
   transport, and coupling to a reactor model come next hour with MOOSE."*
   This hour delivers exactly that hand-off.
2. The real-world motivation: the Virtual Test Bed's one Thermochimica model
   (`msr/msfr/thermochemistry/thermo.i`, Molten Salt Fast Reactor) couples
   Griffin depletion + Pronghorn thermal-hydraulics into a spatially-resolved
   Thermochimica solve. Its documented result: as the fuel salt depletes
   without chemistry control, the fluorine potential rises and **iodine
   volatility increases by at least four orders of magnitude** — directly
   relevant to off-gas system design.
3. Where this lives in MOOSE: inside the `chemical_reactions` module, not a
   dedicated Thermochimica module. `[ChemicalComposition]` is an Action that
   creates scalar auxiliary variables and one `ThermochimicaData` UserObject
   that solves an independent equilibrium at every selected node or element.
   There is no finite-element system here unless you add one — `[Problem]
   solve = false` is the normal pattern when Thermochimica is the only
   physics (Segment 6 adds a real FE solve on top).

---

## 0:08–0:20 — Current interface anatomy

```bash
cd inputs/training/saltfoss_moose
<chemical_reactions-opt> -i 10_current_syntax.i
```

Walk the four load-bearing pieces, in this order:
- `[GlobalParams]` carries the flat `output_*` selectors (`output_phases`,
  `output_species`, `output_element_potentials`, `output_vapor_pressures`,
  `output_element_phases`) and `elements`.
- `thermofile` / `tunit` / `punit` / `munit` name the database and units.
- **Variable names encode the selector**: `mu:Mo` (chemical potential),
  `BCCN:Mo` (species-in-phase), `vp:gas_ideal:Mo` (vapor pressure),
  `ep:BCCN:Mo` (element-in-phase). You couple to these names directly in any
  later block — there is no user-chosen variable name on this interface.
  (Contrast with Segment 7: the redesign lets you name the variable.)
- `[Problem] solve = false` + `[Executioner] type = Steady`.

**Expect:** runs clean, `Variables: {Mo Ru BCCN HCPN BCCN:Mo HCPN:Mo mu:Mo
mu:Ru vp:gas_ideal:Mo ep:BCCN:Mo}`.

---

## 0:20–0:34 — Spatial redox ★ [HANDS-ON 1]

```bash
<chemical_reactions-opt> -i 11_redox_sweep.i
cat 11_redox_sweep_out_line_0001.csv
```

Same F-sweep idea as session 1's three separate `03_redox_UF3*.ti` runs
(F = 135.0 reducing → 135.9 oxidizing), but as ONE mesh: `FunctionIC` varies
F linearly with position, and the UserObject solves an independent
equilibrium at every node. This is the first thing this hour can do that
standalone Thermochimica cannot.

**Expect** (5-node line sample, `mu:F` in J/mol):
```
F=135.0  mu:F=-534935.85
F=135.225 mu:F=-479362.62
F=135.45  mu:F=-471243.21
F=135.675 mu:F=-463913.82
F=135.9  mu:F=-452596.32
```

**State out loud, this is the segment's teaching point:** the current
interface cannot split U into U(III)/U(IV) at all. `output_species` only
resolves plain species; MSFL's U(III)/U(IV) forms are MQMQA cation
CONSTITUENTS, which have no flat output parameter. `mu:F` is the best redox
proxy available here — the actual oxidation-state split waits for Segment 7's
`ConstituentFractions`.

**Attendees run this themselves.** Point them at the file; have them edit the
`FunctionIC` endpoints or `nx` and rerun to see the profile change.

---

## 0:34–0:44 — Off-gassing

```bash
<chemical_reactions-opt> -i 12_offgas.i
```

Same composition and conditions as session 1's `05_offgas_lowP.ti`
(Li=66, Be=33, U=1, Cs=0.02, I=0.02, F=135.0, 1200 K, 1e-6 atm), run through
the MOOSE action instead of `InputScriptMode`, to show the two give
identical physics.

**Expect:** `gas_moles = 99.729` — matches session 1's "99.729 mol gas_ideal"
exactly. `p_CsI = 1.236e-12`, `p_CsF = 6.133e-11` atm.

Repeat the session-1 caveat, now spatially relevant: this is the EQUILIBRIUM
vapor composition, not a release rate. A real off-gas rate needs transport.

---

## 0:44–0:54 — Making it affordable

```bash
time <chemical_reactions-opt> -i 13_performance.i
time <chemical_reactions-opt> -i 13_performance.i ChemicalComposition/salt/reinitialization_type=none
```

40-element mesh, same redox sweep as Segment 3 — 41 independent equilibrium
solves. `reinitialization_type = nodal` warm-starts each node's solve from
its own previous result (the per-node analog of session 1's `reinit =
.TRUE.`); `none` solves every node from scratch.

**Expect:** nodal ≈ 5.6 s, none ≈ 9.1 s wall time (this machine).

**State out loud:** this is the CURRENT interface's reinit knob — a single
enum, synchronous, one Thermochimica call per node. The pending redesign
(Segment 7) replaces this with a forked-worker + shared-memory execution
model: `batch_size` groups states per worker request, `warm_start` has three
modes (`previous_solve` / `previous_timestep` / `none`), `report_performance`
reports exact counters, and the worker pool runs under real thread/MPI
parallelism — a materially larger speedup than the number above. Don't let
this demo stand in for that; it only exists on the current interface.

---

## 0:54–1:05 — Coupling out ★ [HANDS-ON 2]

```bash
<chemical_reactions-opt> -i 14_coupled_bc.i
```

The other half of session 1's hand-off: "how the redox/corrosion quantities
from this session become boundary conditions in a coupled model." Takes
Segment 3's `mu:F` profile and uses it, directly, as the flux driving a toy
"corrosion marker" diffusion field — a real `[Variables]` field, solved with
Newton, not a postprocessor off to the side. `mu:F` is a genuine coupled
variable: any Kernel, BC, or Material can read it like any other field.

**Expect:** `Solve Converged!`, `marker_right = -0.4526`.

**Attendees run this themselves.** Have them swap `CoupledVarNeumannBC` for
a different BC type, or point the flux at a different output variable, and
confirm it still converges.

Say explicitly: a real corrosion model would couple the Cr dissolution rate
from session 1 (Segment 5, Cr²⁺ spanning ~9 orders of magnitude with redox)
through this same mechanism — equilibrium chemistry output as a boundary
condition for a transport/kinetics model, exactly as promised.

---

## 1:05–1:20 — The redesign, side by side

```bash
<combined-opt, tc_api branch> -i 20_redox_sweep_typed.i
cat 20_redox_sweep_typed_out_line_0001.csv
<combined-opt, tc_api branch> -i 21_offgas_typed.i
```

Same physics as Segments 3 and 4, rewritten against the pending interface
redesign. Walk `doc/training/moose-interface-cheatsheet.md` alongside this.
Two things change, and only one is "just new syntax":

1. **Syntax**: flat `[GlobalParams]` selectors → a typed `[Outputs]`
   subblock per named `ChemicalComposition` system. Variable names are now
   user-chosen (the leaf block name, or the `variable` parameter) instead of
   encoded selectors.
2. **New capability**: `ConstituentFractions` reads U(III)/U(IV) MQMQA
   cation fractions directly — `20_redox_sweep_typed.i` adds `x_U3`/`x_U4` on
   top of the identical `mu_F` sweep from Segment 3, something the current
   interface cannot do at all (see Segment 3's teaching point).

**Expect** (20, matches Segment 3's `mu_F` to 6 figures):
```
mu_F   -534935.85 -> -479362.62 -> -471243.21 -> -463913.82 -> -452596.32
x_U3   1.137e-02 -> 8.898e-03 -> 6.319e-03 -> 3.737e-03 -> 1.151e-03
x_U4   1.729e-06 -> 2.156e-03 -> 4.300e-03 -> 6.427e-03 -> 8.527e-03
```

**Expect** (21, matches Segment 4's off-gas result exactly):
`gas_moles = 99.729`.

Call out the bug this training surfaced and fixed: `pressure` set inside a
named `ChemicalComposition` subblock on `tc_api` was silently overridden by
the common block's registered default (always 1 atm), which would have
broken Segment 4's redesigned demo (`gas_moles` would read 0, the wrong
answer, with no error). Fixed in
`ChemicalCompositionAction::initializeConfiguration()` (switched
`applyParameters()` → `applyCommonUserSetParameters()`); regression test
`[pressure_override]` in `modules/chemical_reactions/test/tests/thermochimica/tests`.

Close with `22_subblocks_typed.i` --
`modules/chemical_reactions/test/tests/thermochimica/typed_outputs_subblocks.i`
in the MOOSE repo -- two independently-configured `ChemicalComposition`
systems on disjoint mesh blocks sharing one set of composition variables:
the pattern for a model with, say, a fuel-salt zone and a cover-gas zone in
one mesh.

---

## Known gotchas

- **Relative database paths** resolve against the input file's directory,
  not the shell's CWD. All decks here use an absolute path for portability.
- **No oxygen in MSTDB.** Neither `MSD-TC_V4.1_Fluorides_No_Func.dat` nor the
  chlorides file contains O — redox here is read through the F/Cl mass
  balance (element potentials, constituent fractions), never through pO2.
- **Not every MQMQA constituent name resolves.** `U[3+]`, `U[CN=VI]`,
  `U[CN=VII]`, `U[Dimer]`, and `Li[1+]` are valid sublattice-1 cations for
  MSFL; `Be[CN=IV]`/`Be[Dimer]` are valid, but only once Be is in the element
  list; omitting an element from `elements`/`output_element_potentials` and
  then asking for its constituent fails with "Constituent '...' was not
  found on sublattice N of phase 'MSFL'" — always include every element you
  want to query.
- **`output_species_unit` is always required** on the current (`next`)
  interface, even if you never request a species output — `next`'s action
  does not scope the check to whether `output_species` is set.
- **`ALL` output selectors can explode.** MSTDB-TC has ~1218 species; `ALL`
  on a flat output parameter or a typed family creates one AuxVariable per
  match. Fine for the small test databases here, costly on MSTDB.
- **`[SystemProperties]` heat-capacity cost** (redesign only): requesting any
  `SystemProperties` output enables Thermochimica's equilibrium
  heat-capacity path, which perturbs temperature and re-solves — budget time
  for it, don't request it by habit.

## If something breaks live

1. `<exe> --show-capabilities | grep -A2 thermochimica` — confirm
   `"value": true`. If false, the build lacks the submodule/capability;
   fall back to describing the input file instead of running it.
2. `git status` on the MOOSE worktree — confirm the pressure fix
   (`ChemicalCompositionAction.C`) is actually applied before Segment 4's
   redesigned demo; without it `gas_moles` silently reads 0.
3. Check the database path in the failing `.i` matches this machine's
   `~/projects/thermochimica/data/` location.
