# Thermochimica + MOOSE — Handout

Companion to the SaltFoss MOOSE training (Hour 2: MOOSE coupling). Picks up
where `doc/training/saltfoss-handout.md` (Hour 1) left off. Demo files are in
`inputs/training/saltfoss_moose/`; the interface comparison is in
`doc/training/moose-interface-cheatsheet.md`.

## Where Thermochimica lives in MOOSE

Inside the `chemical_reactions` module (`modules/chemical_reactions/` in the
MOOSE repo) — there is no dedicated Thermochimica module.
`[ChemicalComposition]` is a MOOSE Action: it creates one scalar
AuxVariable per configured element plus one per requested output, and sets
up a single `ThermochimicaData` UserObject that runs the actual equilibrium
solve at every selected node or element. There is usually no finite-element
system in play — `[Problem] solve = false` with `[Executioner] type =
Steady` is the normal pattern when Thermochimica is the only physics; a real
FE field only appears when something else couples to the Thermochimica
output variables (Segment 6).

## Running a calculation

```bash
cd ~/projects/thermochimica/inputs/training/saltfoss_moose
<chemical_reactions-opt or combined-opt> -i 11_redox_sweep.i
```

Any MOOSE executable built with the `thermochimica` capability works; check
with `<exe> --show-capabilities | grep -A2 thermochimica`.

## The one thing that's genuinely new here, not in session 1

**A spatial equilibrium field.** Session 1 computed one (T, p, composition)
point per run. `[ChemicalComposition]` solves an independent equilibrium at
every mesh node or element in a single MOOSE run — a redox or off-gas
profile across a reactor geometry, not a single point.

## Current (`next`) interface — minimal pattern

```
[GlobalParams]
  elements = 'Li Be U F'
  output_element_potentials = 'mu:F'
[]

[ChemicalComposition]
  [salt]
    thermofile = /path/to/MSD-TC_V4.1_Fluorides_No_Func.dat
    tunit = K
    punit = atm
    munit = moles
    temperature = 900
    output_species_unit = moles   # always required, even with no species requested
  []
[]
```

Variable names encode their selector: `mu:F`, `BCCN:Mo`, `vp:gas_ideal:Mo`,
`ep:BCCN:Mo`. Couple to them in any later block exactly like a normal
variable.

## Pending redesign (`tc_api`) — typed output pattern

```
[ChemicalComposition]
  [salt]
    elements = 'Li Be U F'
    thermodynamic_database = /path/to/MSD-TC_V4.1_Fluorides_No_Func.dat
    temperature_unit = K
    pressure_unit = atm
    composition_unit = moles
    temperature = 900

    [Outputs]
      [ElementPotentials]
        [mu_F]          # this name is yours to choose
          element = F
        []
      []
      [ConstituentFractions]   # NEW capability: reads U(III)/U(IV) directly
        [x_U4]
          phase = MSFL
          sublattice = 1
          constituent = 'U[CN=VI]'
        []
      []
    []
  []
[]
```

Full old-vs-new parameter table, selector table, and the 11 typed output
families: `doc/training/moose-interface-cheatsheet.md`.

## Gotchas carried over from this training

- Database path resolves against the INPUT FILE's directory, not your
  shell's CWD — use an absolute path or keep the `.dat` beside the `.i`.
- `output_species_unit` is required on the current interface even when you
  request no species output.
- A constituent fails to resolve ("Constituent '...' was not found...") if
  its element isn't in `elements` — always list every element you query.
- No oxygen in either MSTDB file — redox goes through the halide mass
  balance, never pO2.

## What's next

A MOOSE-driven corrosion or off-gas model couples a transport/kinetics
equation to the Thermochimica output variables shown here (Segment 6) — the
redox and corrosion numbers from session 1 become spatial fields that a real
reactor model can act on.
