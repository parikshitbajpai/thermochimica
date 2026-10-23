# =============================================================================
# SaltFoss MOOSE Training -- Segment 5 (0:44-0:54): Making it affordable
# =============================================================================
# Session 1 used `reinit = .TRUE.` in InputScriptMode to warm-start a sweep.
# The MOOSE action exposes the SAME mechanism, scaled to a 40-node mesh (one
# independent equilibrium per node, same redox sweep as Segment 3):
# `reinitialization_type = none` solves every node from scratch;
# `nodal` reuses the previous solution at that mesh location as the initial
# guess for the Thermochimica Gibbs-energy minimizer.
#
# This is the CURRENT interface's reinit knob. The pending redesign replaces
# it with a forked-worker + shared-memory execution model with its own
# `warm_start` modes (previous_solve / previous_timestep / none), explicit
# `batch_size` batching, a `report_performance` counter, and real MPI/thread
# parallelism over the worker pool -- a materially larger speedup than what's
# shown here. State that out loud; don't let this timing stand in for that.
#
# Run twice, comparing wall time:
#   <chemical_reactions-opt, next> -i 13_performance.i
#   <chemical_reactions-opt, next> -i 13_performance.i ChemicalComposition/salt/reinitialization_type=none
# Verified (40 elements, 41 nodes): nodal reinit 5.6 s vs none 9.1 s wall time.
# =============================================================================
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 40
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
    reinitialization_type = nodal
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

[Outputs]
  csv = true
[]
