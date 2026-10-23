# =============================================================================
# SaltFoss MOOSE Training -- Segment 7 (1:05-1:20): The redesign, side by side
# =============================================================================
# Same physics as 11_redox_sweep.i (identical mesh, identical F sweep,
# identical database), rewritten against the pending `tc_api` redesign. Two
# things change, and only one is "just new syntax":
#
#   1. Syntax: [GlobalParams]/flat output_* -> a typed [Outputs] subblock
#      under the named ChemicalComposition system. `mu_F` is a name YOU
#      chose (the `variable` parameter, or the leaf-block name by default) --
#      not an encoded selector like `mu:F`.
#   2. NEW CAPABILITY, not just new syntax: `ConstituentFractions` can read
#      U(III)/U(IV) MQMQA cation fractions directly. 11_redox_sweep.i could
#      not do this at all on the current interface -- there is no flat
#      output parameter that reaches a constituent (only a species or a
#      whole-element amount). This is the actual redox split session 1
#      computed with three separate standalone runs; here it's two more
#      typed-output leaves on the same spatial sweep already built.
#
# Run:    <combined-opt, tc_api branch> -i 20_redox_sweep_typed.i
# Verified (5-node line sample, matches 11_redox_sweep.i's mu_F to 5-6 figs):
#   mu_F   -534935.85 -> -479362.62 -> -471244.52 -> -463923.71 -> -453007.99 [J/mol]
#   x_U3   1.137e-02 -> 8.898e-03 -> 6.320e-03 -> 3.740e-03 -> 1.208e-03
#   x_U4   1.729e-06 -> 2.156e-03 -> 4.300e-03 -> 6.424e-03 -> 8.480e-03
# =============================================================================
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 4
  []
[]

[ChemicalComposition]
  [salt]
    elements = 'Li Be U F'
    thermodynamic_database = /Users/bajpp/projects/thermochimica/data/MSD-TC_V4.1_Fluorides_No_Func.dat
    temperature_unit = K
    pressure_unit = atm
    composition_unit = moles
    temperature = 900

    [Outputs]
      [ElementPotentials]
        [mu_F]
          element = F
        []
      []
      [ConstituentFractions]
        [x_U3]
          phase = MSFL
          sublattice = 1
          constituent = 'U[3+]'
        []
        [x_U4]
          phase = MSFL
          sublattice = 1
          constituent = 'U[CN=VI]'
        []
      []
    []
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
  # F sweeps 135.0 (reducing, UF3-rich) -> 135.9 (oxidizing, UF4-rich)
  [F]
    type = FunctionIC
    variable = F
    function = '135.0 + 0.9*x'
  []
[]

[Problem]
  solve = false
[]
[Executioner]
  type = Steady
[]

[VectorPostprocessors]
  [line]
    type = NodalValueSampler
    variable = 'F mu_F x_U3 x_U4'
    sort_by = x
  []
[]

[Outputs]
  csv = true
[]
