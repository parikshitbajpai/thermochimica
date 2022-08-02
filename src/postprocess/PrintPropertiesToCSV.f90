subroutine PrintPropertiesToCSV

    USE ModuleThermo
    USE ModuleThermoIO
    USE ModuleGEMSolver

    implicit none

    integer :: i
    logical :: exist

    iPrintResultsMode     = 2

    ! Return if the print results mode is zero.
    if (iPrintResultsMode == 0) return

    ! Only proceed for a successful calculation:
    IF_PASS: if (INFOThermo == 0) then
      inquire(file="/Users/parikshitbajpai/projects/thermochimica/thermoout.txt", exist=exist)
      if (exist) then
        open(1, file='/Users/parikshitbajpai/projects/thermochimica/thermoout.txt', status='old', position='append', action='write')
      else
        open(1, file='/Users/parikshitbajpai/projects/thermochimica/thermoout.txt', status='new', action='write')
        write(1,*) 'T [K],P [atm],x_Ni [mol],x_F [mol],x_Li [mol],mu_Ni [J/mol],mu_F [J/mol],mu_Li [J/mol],G [J]'
      end if

      if ((dPressure < 1D3).AND.(dPressure > 1D-1)) then
          write(1,'(F10.2,A1,F10.4,A1)',advance="no") dTemperature, ',', dPressure, ','
      else
          write(1,'(F11.2,A1,ES11.3,A1)',advance="no") dTemperature, ',', dPressure, ','
      end if
      do i = 1, nElements
          write(1,'(ES20.12,A1)',advance="no") dMolesElement(i), ','
      end do
      do i = 1, nElements
          write(1,'(ES20.12,A1)',advance="no") dElementPotential(i) * dIdealConstant * dTemperature, ','
      end do
      write(1,'(ES15.8)') dGibbsEnergySys

      close (1)
    else
        ! Do nothing, let the debugger take over.

    end if IF_PASS

    return

end subroutine PrintPropertiesToCSV
