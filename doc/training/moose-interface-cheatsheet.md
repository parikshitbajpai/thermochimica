# ChemicalComposition Interface Cheatsheet — Current vs. Redesigned

Current = the `next` branch of MOOSE (published, what you can use today).
Redesigned = the pending `tc_api` branch (PR, refs #22711). Both wrap the
same Thermochimica Fortran core; the examples in
`inputs/training/saltfoss_moose/` run both forms against identical physics.

## The interface is a hard break, not a deprecation

The old parameter NAMES are **removed, not deprecated**. An input file
written against `next` will fail with "unused parameter" errors on `tc_api`
— there is no compatibility alias for the renamed parameters (only the
`output_*` family selectors stay, with a deprecation warning; see below).

| Current (`next`) | Redesigned (`tc_api`) |
| :- | :- |
| `thermofile` | `thermodynamic_database` |
| `tunit` | `temperature_unit` |
| `punit` | `pressure_unit` |
| `munit` | `composition_unit` |
| `output_species_unit` | `species_output_unit` (only on the deprecated flat path; typed `[Species]`/`[Phases]` blocks use their own `unit` parameter instead) |
| `initial_values` | `initial_composition_file` |
| `reinitialization_type` (`none`/`time`/`nodal`) | `warm_start` (`none`/`previous_timestep`/`previous_solve`) |
| `is_fv` (`true`/`false`) | `evaluation_location` (`elemental`/`nodal`) |
| `uo_name` | removed — the UserObject name is auto-derived; it is not meant to be referenced directly |
| — | `batch_size`, `report_performance`, `excluded_phases`, `included_phases` (all new) |

`reinitialization_type` → `warm_start` is not a straight rename: `nodal` →
`previous_solve` (the new default), `time` → `previous_timestep`, `none` →
`none`.

## Flat output selectors: same parameter names, selector format changed

These five parameters still exist on `tc_api` (deprecated, with a
`mooseDeprecated` warning, still functional for incremental migration), but
three of their selector strings dropped their prefix:

| Parameter | Current selector | Redesigned selector | Generated variable (unchanged either way) |
| :- | :- | :- | :- |
| `output_phases` | `BCCN` | `BCCN` | `BCCN` |
| `output_species` | `BCCN:Mo` | `BCCN:Mo` | `BCCN:Mo` |
| `output_element_potentials` | `mu:Mo` | `Mo` | `mu:Mo` |
| `output_vapor_pressures` | `vp:gas_ideal:Mo` | `gas_ideal:Mo` | `vp:gas_ideal:Mo` |
| `output_element_phases` | `ep:BCCN:Mo` | `BCCN:Mo` | `ep:BCCN:Mo` |

The generated AuxVariable name is identical in both cases — only what you
type as the selector changes for three of the five.

## Minimal example, both forms (Mo-Ru binary)

**Current:**
```
[GlobalParams]
  elements = 'Mo Ru'
  output_phases = 'BCCN HCPN'
  output_element_potentials = 'mu:Mo mu:Ru'
[]

[ChemicalComposition]
  [thermo]
    thermofile = Kaye_NobleMetals.dat
    tunit = K
    punit = atm
    munit = moles
    temperature = 2250
    output_species_unit = mole_fraction
  []
[]
```

**Redesigned, legacy-compatible path** (same selector names, new parameter
names — a mechanical find-replace, still deprecated at runtime):
```
[GlobalParams]
  elements = 'Mo Ru'
  output_phases = 'BCCN HCPN'
  output_element_potentials = 'Mo Ru'
[]

[ChemicalComposition]
  [thermo]
    thermodynamic_database = Kaye_NobleMetals.dat
    temperature_unit = K
    pressure_unit = atm
    composition_unit = moles
    temperature = 2250
    species_output_unit = mole_fraction
  []
[]
```

**Redesigned, typed form** (the intended target — user-chosen variable
names, no colon-encoding):
```
[ChemicalComposition]
  [thermo]
    elements = 'Mo Ru'
    thermodynamic_database = Kaye_NobleMetals.dat
    temperature_unit = K
    pressure_unit = atm
    composition_unit = moles
    temperature = 2250

    [Outputs]
      [Phases]
        [hcp_amount]
          phase = HCPN
        []
      []
      [ElementPotentials]
        [mo_potential]
          element = Mo
        []
      []
    []
  []
[]
```

## The 11 typed output families (redesign only)

Every leaf block under `[Outputs]` creates one scalar AuxVariable, named
after the leaf block (or the `variable` parameter, if given).

| Block | Required parameters | Quantity | Units |
| :- | :- | :- | :- |
| `[Phases]` | `phase` | Phase amount | `moles` (default) or `mole_fraction` |
| `[Species]` | `phase`, `species` | Species amount within its phase | `moles` (default) or `mole_fraction` |
| `[ElementPotentials]` | `element` | Element chemical potential | J/mol |
| `[VaporPressures]` | `phase` (gas), `species` | Species partial pressure | pressure unit |
| `[ElementDistribution]` | `phase`, `element` | Element amount distributed to a phase | `moles` (default) or `fraction` |
| `[ChemicalPotentials]` | `phase` + exactly one of `species`/`quadruplet`/`endmember`/`pair` | Chemical potential | J/mol |
| `[PhaseGibbsEnergies]` | `phase` | Phase Gibbs energy | `joules` (default) or `joules_per_mole` |
| `[PhaseDrivingForces]` | `phase` | Driving force (negative = formation favorable) | J/mol-atoms |
| `[SystemGibbsEnergies]` | none | Integral system Gibbs energy | J |
| `[SystemProperties]` | `property` (`enthalpy`/`entropy`/`heat_capacity`) | Integral system property | J (enthalpy), J/K (entropy, Cp) |
| `[ConstituentFractions]` | `phase`, `sublattice` (1-based), `constituent` | Site/constituent fraction on an MQMQA or sublattice phase | dimensionless |

**`ConstituentFractions` is new capability, not new syntax** — there is no
flat selector on the current interface that reaches a sublattice
constituent (`output_species` only matches a plain species name; MSFL's
`U[3+]`/`U[CN=VI]`/etc. are cation constituents, not species). This is the
only typed family that lets you read a molten-salt oxidation-state split
directly. See `11_redox_sweep.i` (current, no U(III)/U(IV) split possible)
vs `20_redox_sweep_typed.i` (redesigned, `ConstituentFractions` gives it).

`endmember` and `pair` are equivalent selectors for an MQM phase and report
a stoichiometric potential derived from the system element potentials — NOT
an independently minimized partial potential. Use `species` for a
conventional solution phase, `quadruplet` only for an MQM phase.

## Other new capability in the redesign

- **`excluded_phases` / `included_phases`** — fix the phase set for a whole
  `ChemicalComposition` subblock (mutually exclusive, validated at setup).
  Useful for a phase-restricted Gibbs energy feeding a phase-field model
  (`modules/combined/examples/thermochimica_phase_field/phase_restricted_gibbs.i`).
  Limitation stated in the docs: the phase set is fixed for the whole
  simulation — a phase-field variable cannot toggle it per node/element.
- **`batch_size`, `warm_start`, `report_performance`** — the forked-worker +
  shared-memory execution model and its tuning knobs. No equivalent exists
  on the current interface beyond the single `reinitialization_type` enum.
- **Named, block-restricted `ChemicalComposition` systems sharing
  pre-declared composition variables** — see
  `typed_outputs_subblocks.i` in the MOOSE repo (two systems, one on each
  mesh block, sharing one set of `[AuxVariables]`).

## The bug this training surfaced (now fixed)

`pressure` set on a named `ChemicalComposition` subblock was silently
discarded on `tc_api` — every solve ran at the common block's default
(1 atm) regardless of what the subblock said, because
`ChemicalCompositionAction::initializeConfiguration()` called
`InputParameters::applyParameters()`, which also applies a parameter's
*registered* C++ default, not only values the common block's own user
actually set. `temperature` was unaffected (it has no registered default).
Fixed by switching to `applyCommonUserSetParameters()`. If you are testing
against an unpatched `tc_api` checkout, put `pressure` on the PARENT
`[ChemicalComposition]` block as a workaround.
