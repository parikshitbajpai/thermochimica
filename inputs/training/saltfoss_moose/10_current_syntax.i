# =============================================================================
# SaltFoss MOOSE Training -- Segment 2 (0:08-0:20): Current interface anatomy
# =============================================================================
# Minimal ChemicalComposition on the published interface (this is the syntax
# the one Thermochimica model in the Virtual Test Bed uses --
# msr/msfr/thermochemistry/thermo.i -- trimmed from its ~2200 lines of
# depletion plumbing down to the Thermochimica block itself):
#   - [GlobalParams] carries the flat `output_*` selectors and `elements`.
#   - `thermofile`/`tunit`/`punit`/`munit` name the database and its units.
#   - Variable names ENCODE the selector: `mu:F` (chemical potential),
#     `BCCN:Mo` (species-in-phase), `vp:gas_ideal:Mo` (vapor pressure),
#     `ep:BCCN:Mo` (element-in-phase). You couple to these names directly --
#     there is no user-chosen variable name on this interface.
#   - `[Problem] solve = false` + `[Executioner] type = Steady`: there is no
#     finite-element system to solve here, just one ThermochimicaData
#     UserObject evaluated at [INITIAL, TIMESTEP_END]. The variables exist so
#     other kernels/materials CAN couple to them (Segment 6).
#
# This example uses the Mo-Ru noble-metal binary (small, fast, no MSTDB
# needed) purely to show the syntax; Segments 3-6 switch to the molten-salt
# database for the physics.
#
# Run:    <chemical_reactions-opt, next> -i 10_current_syntax.i
# =============================================================================
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 2
  []
[]

[GlobalParams]
  elements = 'Mo Ru'
  output_phases = 'BCCN HCPN'
  output_species = 'BCCN:Mo HCPN:Mo'
  output_element_potentials = 'mu:Mo mu:Ru'
  output_vapor_pressures = 'vp:gas_ideal:Mo'
  output_element_phases = 'ep:BCCN:Mo'
[]

[ChemicalComposition]
  [thermo]
    thermofile = /Users/bajpp/projects/thermochimica/data/NobleMetals-Kaye.dat
    tunit = K
    punit = atm
    munit = moles
    temperature = 2250
    output_species_unit = mole_fraction
  []
[]

[ICs]
  [Mo]
    type = FunctionIC
    variable = Mo
    function = '0.8*(1-x)+4.3*x'
  []
  [Ru]
    type = FunctionIC
    variable = Ru
    function = '0.2*(1-x)+4.5*x'
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]

[Outputs]
  exodus = true
[]
