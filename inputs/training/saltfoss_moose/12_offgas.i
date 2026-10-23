# =============================================================================
# SaltFoss MOOSE Training -- Segment 4 (0:34-0:44): Off-gassing
# =============================================================================
# Same composition and conditions as session 1's 05_offgas_lowP.ti, run as a
# single-node MOOSE equilibrium through ChemicalComposition instead of
# InputScriptMode. Cross-checks that the MOOSE action reproduces standalone
# Thermochimica exactly, then shows the typed vapor-pressure outputs
# (`vp:` selectors) that a transport model would read.
#
# PREREQUISITE: this demo needs the `pressure` fix landed on this branch
# (modules/chemical_reactions/src/actions/ChemicalCompositionAction.C,
# coupledInput() -> applyCommonUserSetParameters()). Before that fix,
# `pressure` set inside a named ChemicalComposition subblock was silently
# discarded and every solve ran at 1 atm, where gas_ideal is NOT stable
# (moles = 0) -- the exact wrong answer for this segment. If gas_moles comes
# back 0 here, you are on an unpatched build; put `pressure = 1e-6` on the
# PARENT [ChemicalComposition] block as a workaround and say so out loud.
#
# CAVEAT to repeat from session 1, now spatially: this is the EQUILIBRIUM
# vapor composition, not a release rate. Getting a rate needs transport,
# which is the subject of Segment 6 (hands-on 2).
#
# Run:    <combined-opt> -i 12_offgas.i
# Verified: gas_moles = 99.729 (matches 05_offgas_lowP.ti's "99.729 mol
# gas_ideal" exactly), p_CsI = 1.236e-12 atm.
# =============================================================================
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 1
  []
[]

[GlobalParams]
  elements = 'Li Be U F Cs I'
  output_phases = 'gas_ideal'
  output_vapor_pressures = 'vp:gas_ideal:CsI vp:gas_ideal:CsF vp:gas_ideal:I2'
[]

[ChemicalComposition]
  [salt]
    # Thermochimica resolves `thermofile` against the input file's own
    # directory, not the shell's CWD. Edit this path if your checkout lives
    # somewhere other than ~/projects/thermochimica.
    thermofile = /Users/bajpp/projects/thermochimica/data/MSD-TC_V4.1_Fluorides_No_Func.dat
    tunit = K
    punit = atm
    munit = moles
    temperature = 1200
    pressure = 1.0e-6
    output_species_unit = moles
  []
[]

[ICs]
  [Li]
    type = ConstantIC
    variable = Li
    value = 66.0
  []
  [Be]
    type = ConstantIC
    variable = Be
    value = 33.0
  []
  [U]
    type = ConstantIC
    variable = U
    value = 1.0
  []
  [Cs]
    type = ConstantIC
    variable = Cs
    value = 0.02
  []
  [I]
    type = ConstantIC
    variable = I
    value = 0.02
  []
  [F]
    type = ConstantIC
    variable = F
    value = 135.0
  []
[]

[Problem]
  solve = false
[]
[Executioner]
  type = Steady
[]

[Postprocessors]
  [gas_moles]
    type = NodalVariableValue
    variable = gas_ideal
    nodeid = 0
  []
  [p_CsI]
    type = NodalVariableValue
    variable = 'vp:gas_ideal:CsI'
    nodeid = 0
  []
  [p_CsF]
    type = NodalVariableValue
    variable = 'vp:gas_ideal:CsF'
    nodeid = 0
  []
  [p_I2]
    type = NodalVariableValue
    variable = 'vp:gas_ideal:I2'
    nodeid = 0
  []
[]

[Outputs]
  csv = true
[]
