# =============================================================================
# SaltFoss MOOSE Training -- Segment 3 (0:20-0:34): Spatial redox [HANDS-ON 1]
# =============================================================================
# Session 1 (03_redox_UF3.ti / 03_redox_UF35.ti / 03_redox_UF39.ti) ran three
# separate standalone calculations to sweep F from 135.0 (reducing) to 135.9
# (oxidizing). Here the SAME sweep is one MOOSE mesh: F varies linearly with
# position x, and ChemicalComposition solves an independent Thermochimica
# equilibrium at every node. This is the first thing this hour can do that
# standalone Thermochimica cannot: a spatial redox profile in one solve.
#
# IMPORTANT LIMITATION of the current interface, worth stating out loud: it
# cannot split U into U(III)/U(IV). `output_species` only resolves species
# that appear in a plain species list; MSFL is an MQMQA/SUBQ phase whose
# U(III) and U(IV) forms (`U[3+]`, `U[CN=VI]`, `U[CN=VII]`, `U[Dimer]`) are
# cation CONSTITUENTS, not species, and there is no flat output parameter
# that reaches them. `output_element_phases` ('ep:MSFL:U') only gives total
# U in MSFL -- not split by oxidation state. The fluorine chemical potential
# (`mu:F`) is therefore the best redox proxy available on this interface; the
# oxidation-state split itself has to wait for the `ConstituentFractions`
# typed output introduced in the pending redesign (Segment 7, see
# 20_redox_sweep_typed.i for the side-by-side).
#
# Run:    <chemical_reactions-opt, next, Thermochimica-enabled> -i 11_redox_sweep.i
# Verified (5-node line sample, x=0..1 <-> F=135.0..135.9):
#   mu:F  -534.9 -> -479.4 -> -471.2 -> -463.9 -> -452.6  [kJ/mol]
# Cross-check against session 1: endpoints bracket 03_redox_UF3.ti (F=135.0)
# and 03_redox_UF39.ti (F=135.9).
# =============================================================================
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 4
  []
[]

[GlobalParams]
  elements = 'Li Be U F'
  output_element_potentials = 'mu:F'
[]

[ChemicalComposition]
  [salt]
    # Thermochimica resolves `thermofile` against the input file's own
    # directory, not the shell's CWD -- a bare filename only works when the
    # .dat sits beside this .i. Edit this path if your checkout lives
    # somewhere other than ~/projects/thermochimica.
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
    variable = 'F mu:F'
    sort_by = x
  []
[]

[Outputs]
  csv = true
[]
