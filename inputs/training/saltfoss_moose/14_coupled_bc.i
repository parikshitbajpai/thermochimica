# =============================================================================
# SaltFoss MOOSE Training -- Segment 6 (0:54-1:05): Coupling out [HANDS-ON 2]
# =============================================================================
# The other promise from session 1's closing line: "how the redox/corrosion
# quantities from this session become boundary conditions in a coupled
# model." This takes Segment 3's spatial fluorine-potential profile and uses
# it, directly, as the flux driving a toy "corrosion marker" diffusion field
# -- a real finite-element Variable, solved with Newton, not a postprocessor
# sitting off to the side. `mu:F` is a genuine coupled field: any Kernel,
# BC, or Material in the input file can read it like any other variable.
#
# marker solves Diffusion with marker=0 pinned on the left and a Neumann flux
# on the right proportional to the local fluorine potential (mu:F, more
# negative = more reducing) -- i.e. the redox state sets how fast the marker
# field is driven in from that boundary. A real corrosion model would couple
# the Cr dissolution rate (session 1, Segment 5) through the same mechanism.
#
# Run:    <chemical_reactions-opt, next> -i 14_coupled_bc.i
# Verified: "Solve Converged!" (Newton, linear residual to 1e-16).
# =============================================================================
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 8
  []
[]

[GlobalParams]
  elements = 'Li Be U F'
  output_element_potentials = 'mu:F'
[]

[ChemicalComposition]
  [salt]
    thermofile = /Users/bajpp/projects/thermochimica/data/MSD-TC_V4.1_Fluorides_No_Func.dat
    tunit = K
    punit = atm
    munit = moles
    temperature = 900
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
  # Same reducing -> oxidizing sweep as Segment 3
  [F]
    type = FunctionIC
    variable = F
    function = '135.0 + 0.9*x'
  []
[]

[Variables]
  [marker]
  []
[]

[Kernels]
  [diff]
    type = Diffusion
    variable = marker
  []
[]

[BCs]
  [left]
    type = DirichletBC
    variable = marker
    boundary = left
    value = 0
  []
  # The Thermochimica equilibrium output drives a real FE boundary flux.
  [right]
    type = CoupledVarNeumannBC
    variable = marker
    boundary = right
    v = 'mu:F'
    coef = 1e-6
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
[]

[Postprocessors]
  [marker_right]
    type = SideAverageValue
    variable = marker
    boundary = right
  []
[]

[Outputs]
  csv = true
[]
