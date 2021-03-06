

    !-------------------------------------------------------------------------------------------------------------
    !
    !> \file    ParseCSDataBlockSUBG.f90
    !> \brief   Parse the data block section corresponding to a SUBG phase of a ChemSage data-file.
    !> \author  M.H.A. Piro 
    !> \date    Mar. 4, 2018
    !> \sa      ParseCSDataFile.f90
    !> \sa      ParseCSDataBlock.f90
    !> \sa      ParseCSDataBlockGibbs.f90
    !> \todo    There are a number of lines in SUBG phases that I do not yet understand. 
    !!           I've asked some experts and they don't know either, which tells me that 
    !!           they're not important. Once I
    !!           gain more experience with these models, this will likely become more clear.
    !
    !
    ! DISCLAIMER
    ! ==========
    ! 
    ! All of the programming herein is original unless otherwise specified and is completely 
    ! independent of ChemApp and related products, including Solgas, Solgasmix, Fact, FactSage 
    ! and ChemSage.  
    !
    !
    ! Revisions:
    ! ==========
    ! 
    !   Date            Programmer      Description of change
    !   ----            ----------      ---------------------
    !   03/04/2018      M.H.A. Piro     Original code
    !
    !
    ! Purpose:
    ! ========
    !
    !> \details The purpose of this subroutine is to parse the "data block" section of a ChemSage data-file 
    !! containing a "SUBG" phase, which represents the modified quasichemical model. This phase differs
    !! from many other types of thermodynamic models in that it attempts to capture Short Range Order (SRO)
    !! in liquid or solid solutions. This is achieved by focusing on pairs of species, rather than the species
    !! themselves. For more information, see the following paper:
    !! 
    !! A.D. Pelton, S.A. Degterov, G. Eriksson, C. Roberlin, Y. Dessureault, "The Modified Quasichemical
    !! Model I -- Binary Solutions", Metallurgical and Materials Transactions B, 31B (2000) 651-659.
    !!
    !
    !
    ! Pertinent variables:
    ! ====================
    !
    ! INFO                      A scalar integer that indicates a successful exit or identifies an error.
    ! nSpeciesCS                Number of species in the system (combined solution species and pure 
    !                            separate phases).
    ! nGibbsEqSpecies           Number of Gibbs energy equations for a particular species.
    ! iSpeciesAtomsCS           Integer matrix representing the number of atoms of a particular 
    !                            elements in a species.
    ! iParticlesPerMoleCS       An integer vector containing the number of particles per mole of the
    !                            constituent species formula mass.  The default value is 1.
    ! cSolnPhaseNameCS          The name of a solution phase.
    ! cSolnPhaseTypeCS          The type of a solution phase.
    ! cSolnPhaseTypeSupport     A character array representing solution phase types that are supported.
    ! iRegularParamCS           An integer matrix representing the parameter index for the first dimension
    !                            and the mixing terms on the second dimension.  For the second dimension, the
    !                            first coefficient indicates whether the parameter is a binary or ternary term (n),
    !                            the next n coefficients correspond to the constituent indices, and the last 
    !                            coefficient corresponds to the exponent. 
    !
    !-------------------------------------------------------------------------------------------------------------


subroutine ParseCSDataBlockSUBG( i )
    
    USE ModuleParseCS
    
    implicit none
    
    integer                    :: i, j
    integer,     dimension(10) :: iTempVec
    real(8),     dimension(6)  :: dTempVec
    character(8),dimension(3)  :: cDummyVec


    ! Initialize variables:
    dTempVec = 0D0
    iTempVec = 0

    ! SUBG phases appear to be represented as multi-sublattice phases; however,
    ! they don't appear to make use of any sublattice information. I'm going to
    ! to read these lines for now, but it may need to be revised at a later time.

    ! This line contains N integers (where N is the number of sublattices)
    ! where each integer represents the number of constituents on the respective
    ! sublattice. I think there are always two sublattices for SUBG phases.
    read (1,*,IOSTAT = INFO) iTempVec(1:2)

    ! Read in names of constituents on first sublattice:
    ! NOTE: THIS LINE MAY NEED TO BE REVISED IF THERE ARE A LARGE # OF CONSTITUENTS:
    read (1,*,IOSTAT = INFO) cDummyVec(1:iTempVec(1))

    ! Read in names of constituents on second sublattice: (ignore for now):
    read (1,*,IOSTAT = INFO) cDummyVec(1:iTempVec(2))

    ! Read in the charge of each constituent on the first sublattice.
    ! This seems unnecessary so I'm going to ignore it for now:
    read (1,*,IOSTAT = INFO) dTempVec(1:iTempVec(1))

    ! I think that this entry represents the constituent IDs on the first sublattice (ignore for now):
    read (1,*,IOSTAT = INFO) dTempVec(1:iTempVec(1))

    ! Read in the charge of each constituent on the second sublattice.
    ! This seems unnecessary so I'm going to ignore it for now:        
    read (1,*,IOSTAT = INFO) dTempVec(1:iTempVec(2))

    ! I think that this entry represents the constituent IDs on the second sublattice (ignore for now):
    read (1,*,IOSTAT = INFO) dTempVec(1:iTempVec(2))

    ! This entry appears to represent the IDs matching constituents on the first sublattice to species:
    read (1,*,IOSTAT = INFO) dTempVec(1:iTempVec(1))

    ! This entry appears to represent the IDs matching constituents on the second sublattice to species:
    read (1,*,IOSTAT = INFO) dTempVec(1:iTempVec(1))

    ! Parse the co-ordination numbers corresponding to all pairs in the phase.
    ! Note that since these lines correspond to pairs, there will always be the same number of
    ! integers and reals on a line, but the number of lines corresponds to the number of pairs.
    ! The SUBG model considers quadruplets, which is why there are four sets.
    ! Note that a quadruplet must satisfy the following constraint:
    ! q(i)/Z(i) + q(j)/Z(j) =  q(x)/Z(x) + q(y)/Z(y)
    do j = 1, nPairsSROCS(nSROPhasesCS,2)
        read (1,*,IOSTAT = INFO) iPairIDCS(j, 1:4), dCoordinationNumberCS(j,1:4)
    end do

    ! Loop through excess mixing parameters:
    LOOP_ExcessMixingSUBG: do

        ! Read in number of constituents involved in parameter:
        read (1,*,IOSTAT = INFO) iRegularParamCS(nParamCS+1,1)

        ! The end of the parameter listing is marked by "0":
        if (iRegularParamCS(nParamCS+1,1) == 0) exit LOOP_ExcessMixingSUBG
            
        ! Check if the parameter is binary or ternary:
        if (iRegularParamCS(nParamCS+1,1) == 3) then

            ! Count the number of parameters:
            nParamCS = nParamCS + 1

            ! Mixing terms:
            read (1,*,IOSTAT = INFO) cDummyVec(1), iRegularParamCS(nParamCS,2:9)

            ! According to Patrice Chartrand, he has no idea what these two lines mean. Ignore.
            read (1,*,IOSTAT = INFO) dTempVec(1:6)
            read (1,*,IOSTAT = INFO) dTempVec(1:6)

            ! Read in the first line of the excess gibbs energy of mixing terms.
            read (1,*,IOSTAT = INFO) dTempVec(1:6)
            dRegularParamCS(nParamCS,1:6) = dTempVec(1:6)

            ! I HAVE NO IDEA IF THIS LINE IS NEEDED OR NOT. DON'T DO ANYTHING WITH IT FOR NOW.
            read (1,*,IOSTAT = INFO) dTempVec(1:2)

        else
            !! This parameter is not recognized; record an error.
            INFO = 1600 + i
            return
        end if
        
    end do LOOP_ExcessMixingSUBG

    ! Report an error if necessary:
    if (INFO /= 0) INFO = 1600 + i 
                
    return
    
end subroutine ParseCSDataBlockSUBG
