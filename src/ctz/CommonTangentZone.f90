program CommonTangentZone

    USE ModuleThermoIO
    USE ModuleThermo
    USE ModuleGEMSolver
    USE ModuleParseCS
    USE ModuleReinit
    USE ModuleCTZ

    implicit none

    integer :: i, j, k, nnlsInfo, soln, con, nSkipped, nAssemblages, tempInd
    integer :: assemblageMatch, assemblageInd
    real(8) :: li, be, f, cs, u
    real(8) :: tbase, range, dSum, maxNorm, tInterp, startTime, currentTime, tRange!, tempMol
    real(8), dimension(:,:), allocatable :: stoichTemp, stoichInterp
    integer, dimension(:),   allocatable :: indx
    real(8), dimension(:),   allocatable :: dElCon, dElConTemp, x, work
    real(8)                              :: rnorm
    logical                              :: trigger, reinit, unsorted, useNNLS, override
    ! integer, dimension(0:168)            :: iElementsUsed
    real(8), dimension(0:168)            :: dElementMassTemp


    reinit   = .FALSE.
    useNNLS  = .TRUE.
    override = .FALSE.

    tRange  = 25D0
    maxNorm = 1D-16

    nAssemblages = 0
    nMaxAssemblages = 2000
    nMaxElements = 5

    if (.NOT. lCtzInit) then
        allocate(assemblageHistory(nMaxAssemblages+1,nMaxElements),assemblageTlimits(nMaxAssemblages,2))
        allocate(stoichHistory(nMaxAssemblages,2,nMaxElements,nMaxElements))
    end if

    assemblageHistory = 0
    assemblageTlimits(:,1) = 1D5
    assemblageTlimits(:,2) = 0D0
    stoichHistory          = 0D0

    trigger = .TRUE.

    if (useNNLS) then
      call InitThermo
      call CheckSystem
      call CompThermoData
      dElementMass = dElementMassTemp

      allocate(dElCon(nMaxElements),dElConTemp(nMaxElements),x(nMaxElements),work(nMaxElements),indx(nMaxElements))
      allocate(stoichInterp(nMaxElements,nMaxElements),stoichTemp(nMaxElements,nMaxElements))
      dElCon = 0D0
      dElCon(1:nElements) = dMolesElement

      TestAssemblages: do assemblageInd = 1, nAssemblages
          ! i = assemblageInd
          ! if (loopInd == 76) print *, dTemperature, i, assemblageTlimits(i,1), assemblageTlimits(i,2)
          if ((dTemperature < assemblageTlimits(assemblageInd,1)) .OR. (dTemperature > assemblageTlimits(assemblageInd,2))) then
              cycle TestAssemblages
          end if
          dElConTemp = dElCon
          x = 0D0
          ! Use temperature to interpolate into stoichiometry entries
          if (assemblageTlimits(assemblageInd,1) == assemblageTlimits(assemblageInd,2)) then
              tInterp = 0D0
          else
              tInterp = (dTemperature - assemblageTlimits(assemblageInd,1)) &
                      / (assemblageTlimits(assemblageInd,2) - assemblageTlimits(assemblageInd,1))
          end if
          stoichInterp = 0D0
          do i = 1, nMaxElements
              do j = 1, nMaxElements
                  stoichInterp(i,j) = tInterp * stoichHistory(assemblageInd,2,i,j) + &
                                      (1D0 - tInterp) * stoichHistory(assemblageInd,1,i,j)
              end do
          end do
          stoichTemp = stoichInterp
          call nnls(stoichTemp, nMaxElements, nMaxElements, dElConTemp, x, rnorm, work, indx, nnlsInfo)

          rnorm = 0D0
          ! print *, '-----------------'
          do i = 1, nMaxElements
              dSum = 0D0
              do j = 1, nMaxElements
                dSum = dSum + stoichInterp(i,j) * x(j)
              end do
              rnorm = rnorm + (dSum - dElCon(i))**2
              ! print *, i, dSum, dElCon(i)
          end do
          if (rnorm > maxNorm) then
              cycle TestAssemblages
          else
              ! dMolFraction = dMolFraction_Old
              nSkipped = nSkipped + 1
              trigger = .FALSE.
              ! print *, 'skipped'
              ! print *, assemblageHistory(assemblageInd,:)
              ! print *, x / dNormalizeInput
              exit TestAssemblages
          end if
      end do TestAssemblages

      deallocate(dElCon,dElConTemp,x,work,indx)
      deallocate(stoichInterp,stoichTemp)
    end if

    if (trigger) then
        if (INFOThermo == 0)        call Thermochimica
        if (((nConPhases + nSolnPhases) > 1) .AND. (useNNLS .OR. override)) then
            ! reset data
            assemblageHistory(nAssemblages + 1,:) = 0
            assemblageHistory(nAssemblages + 1,1:nElements) = iAssemblage
            if (nAssemblages < nMaxAssemblages) then
                assemblageTlimits(nAssemblages + 1,1) = 1D5
                assemblageTlimits(nAssemblages + 1,2) = 0D0
            end if
            ! Sort the assemblage for easy comparison later
            unsorted = .TRUE.
            do while (unsorted)
                unsorted = .FALSE.
                do i = 1, nMaxElements-1
                    if (assemblageHistory(nAssemblages + 1,i) < assemblageHistory(nAssemblages + 1,i+1)) then
                        tempInd = assemblageHistory(nAssemblages + 1,i+1)
                        assemblageHistory(nAssemblages + 1,i+1) = assemblageHistory(nAssemblages+1,i)
                        assemblageHistory(nAssemblages + 1,i)   = tempInd
                        ! tempMol = dMolesPhase(i+1)
                        ! dMolesPhase(i+1) = dMolesPhase(i)
                        ! dMolesPhase(i)   = tempMol
                        unsorted = .TRUE.
                    end if
                end do
            end do
            ! print *, assemblageHistory(nAssemblages + 1,:)
            ! print *, dMolesPhase
            ! Now compare to past assemblages
            assemblageMatch = 0
            CompareAssemblages: do i = 1, nAssemblages
                do j = 1, nMaxElements
                    if (assemblageHistory(nAssemblages + 1,j) /= assemblageHistory(i,j)) cycle CompareAssemblages
                end do
                ! if (loopInd == 76) print *, dTemperature, i, assemblageTlimits(i,1), assemblageTlimits(i,2)
                ! print *, '-----------------'
                ! print *, assemblageHistory(nAssemblages + 1,:)
                ! print *, assemblageHistory(i,:)
                ! Check if match is within acceptable temperature bounds
                if ((ABS(dTemperature - assemblageTlimits(i,1)) < tRange) .AND. &
                    (ABS(dTemperature - assemblageTlimits(i,2)) < tRange)) then
                    assemblageMatch = i
                    exit CompareAssemblages
                end if
                ! If it isn't within temperature bounds, one limit of it might still be
                if (nAssemblages < nMaxAssemblages) then
                    if (ABS(dTemperature - assemblageTlimits(i,1)) < tRange) then
                        assemblageTlimits(nAssemblages + 1,1) = assemblageTlimits(i,1)
                        assemblageTlimits(nAssemblages + 1,2) = assemblageTlimits(i,1)
                        stoichHistory(nAssemblages + 1,1,:,:) = stoichHistory(i,1,:,:)
                        stoichHistory(nAssemblages + 1,2,:,:) = stoichHistory(i,1,:,:)
                    end if
                    if (ABS(dTemperature - assemblageTlimits(2,1)) < tRange) then
                        assemblageTlimits(nAssemblages + 1,1) = assemblageTlimits(i,2)
                        assemblageTlimits(nAssemblages + 1,2) = assemblageTlimits(i,2)
                        stoichHistory(nAssemblages + 1,1,:,:) = stoichHistory(i,2,:,:)
                        stoichHistory(nAssemblages + 1,2,:,:) = stoichHistory(i,2,:,:)
                    end if
                end if
            end do CompareAssemblages
            ! If no match found create a new record
            if ((assemblageMatch == 0) .AND. (nAssemblages < nMaxAssemblages)) then
                nAssemblages = nAssemblages + 1
                ! print *, loopInd, nAssemblages
                assemblageMatch = nAssemblages
            end if
            ! Adjust limits for match or new assemblage
            if (assemblageMatch > 0) then
                ! low T limit
                if (dTemperature < assemblageTlimits(assemblageMatch,1)) then
                    assemblageTlimits(assemblageMatch,1) = dTemperature
                    stoichHistory(assemblageMatch,1,:,:) = 0D0
                    RecordStoichLow: do i = 1, nMaxElements
                        k = assemblageHistory(assemblageMatch,i)
                        if (k == 0) cycle RecordStoichLow
                        if (k > 0) then
                            do j = 1, nElements
                                stoichHistory(assemblageMatch,1,j,i) = dStoichSpecies(k,j)
                            end do
                        end if
                        if (k < 0) then
                            call CompStoichSolnPhase(-k)
                            do j = 1, nElements
                                stoichHistory(assemblageMatch,1,j,i) = dEffStoichSolnPhase(-k,j)
                            end do
                        end if
                    end do RecordStoichLow
                end if
                ! high T limit
                if (dTemperature > assemblageTlimits(assemblageMatch,2)) then
                    assemblageTlimits(assemblageMatch,2) = dTemperature
                    stoichHistory(assemblageMatch,2,:,:) = 0D0
                    RecordStoichHigh: do i = 1, nMaxElements
                        k = assemblageHistory(assemblageMatch,i)
                        if (k == 0) cycle RecordStoichHigh
                        if (k > 0) then
                            do j = 1, nElements
                                stoichHistory(assemblageMatch,2,j,i) = dStoichSpecies(k,j)
                            end do
                        end if
                        if (k < 0) then
                            call CompStoichSolnPhase(-k)
                            do j = 1, nElements
                                stoichHistory(assemblageMatch,2,j,i) = dEffStoichSolnPhase(-k,j)
                            end do
                        end if
                    end do RecordStoichHigh
                end if
            end if
        end if
        ! print *, 'dMolesPhase', dMolesPhase
        ! if (INFOThermo == 0)        call SaveReinitData
        if (iPrintResultsMode > 0)  call PrintResults
        soln = nSolnPhases
        con  = nConPhases
        lReinitRequested = ((soln + con < 3)) .AND. reinit
        if ((INFOThermo == 0) .AND. lReinitRequested) call SaveReinitData

        trigger = .TRUE.
        if (INFOThermo == 0) call ResetThermo
        if (INFOThermo >  0) call ThermoDebug
    end if

end subroutine CommonTangentZone
