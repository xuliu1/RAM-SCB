!============================================================================
!    Copyright (c) 2016, Los Alamos National Security, LLC
!    All rights reserved.
!============================================================================

MODULE ModRamInit
! Contains subroutines for initialization of RAM

  use ModRamVariables

  implicit none; save

  contains
!==============================================================================
subroutine ram_allocate

  use ModRamGrids,     ONLY: RadiusMax, RadiusMin, nR, nRExtend, nT, nE, nPa, &
                             Slen, ENG, NCF, NL, nS, nX

  implicit none; save

  nRExtend = NR + 3
  nX = NPA

!!!!!!!! Allocate Arrays
! Main RAM Variables
  ALLOCATE(F2(NS,NR,NT,NE,NPA), FLUX(NS,NR,NT,NE,NPA),PPerH(NR,NT), PParH(NR,NT), &
           PPerE(NR,NT), PParE(NR,NT), PPerO(NR,NT),PParO(NR,NT), PPerHe(NR,NT), &
           PParHe(NR,NT), PAllSum(NR,NT), PParSum(NR,NT), PPerT(NS,NR,NT), &
           PParT(NS,NR,NT), FNHS(NR+1,NT,NPA), FNIS(NR+1,NT,NPA), BOUNHS(NR+1,NT,NPA), &
           BOUNIS(NR+1,NT,NPA), dIdt(NR+1,NT,NPA), dBdt(NR+1,NT), dIbndt(NR+1,NT,NPA), &
           HDNS(NR+1,NT,NPA), BNES(NR+1,NT))
! ModRamInit Variables
  ALLOCATE(RMAS(NS), V(NS,NE), VBND(NS,NE), GREL(NS,NE), GRBND(NS,NE), FACGR(NS,NE), &
           EPP(NS,NE), ERNH(NS,NE), UPA(NR), WE(NE), DE(NE), EKEV(NE), EBND(NE), &
           PHI(NT), LT(NT), MLT(NT), MU(NPA), DMU(NPA), WMU(NPA), PAbn(NPA), LZ(NR+1), &
           RLZ(NR+1), AMLA(Slen), BE(NR+1,Slen), GridExtend(NRExtend), ZRPabn(NR,NPA,Slen), &
           FFACTOR(NS,NR,NE,NPA), PA(NPA))
! ModRamWPI Variables
  ALLOCATE(WALOS1(NR,NE), WALOS2(NR,NE), WALOS3(NR,NE), fpofc(NCF), NDVVJ(NR,ENG,NPA,NCF), &
           NDAAJ(NR,ENG,NPA,NCF), ENOR(ENG), ECHOR(ENG), BDAAR(NR,NT,ENG,NPA), &
           CDAAR(NR,NT,NE,NPA))
! ModRamLoss Variables
  ALLOCATE(ATLOS(nS,NR,NE), CHARGE(nS,NR,NT,NE,NPA))
! ModRamEField Variables
  ALLOCATE(VT(NR+1,NT), EIR(NR+1,NT), EIP(NR+1,NT), VTOL(NR+1,NT), VTN(NR+1,NT))
! ModRamBoundary Variables
  ALLOCATE(FGEOS(NS,NT,NE,NPA))
! ModRamDrift Variables
!  ALLOCATE(P1(NR), VR(NR), P2(NR,NE), EDOT(NR,NE), MUDOT(NR,NPA), CDriftR(NR,NT,NE,NPA), &
!           sgnDriftR(NR,NT,NE,NPA), CDriftP(NR,NT,NE,NPA), CDriftE(NR,NT,NE,NPA), &
!           CDriftMu(NR,NT,NE,NPA))
  ALLOCATE(DtDriftR(nS), DtDriftP(nS), DtDriftE(nS), DtDriftMu(nS))
! ModRamRun Variables
  ALLOCATE(SETRC(NS), ELORC(NS), LSDR(NS), LSCHA(NS), LSATM(NS), LSCOE(NS), &
           LSCSC(NS), LSWAE(NS), XNN(NS,NR), XND(NS,NR), LNCN(NS,NR), LNCD(NS,NR), &
           LECN(NS,NR), LECD(NS,NR), ENERN(NS,NR), ENERD(NS,NR), ATEW(NR,NT,NE,NPA), &
           ATAW(NR,NT,NE,NPA), ATAC(NR,NT,NE,NPA), ATEC(NR,NT,NE,NPA), XNE(NR,NT), &
           ATMC(NR,NT,NE,NPA), ATAW_emic(NR,NT,NE,NPA), NECR(NL,0:48))
!!!!!!!!!

end subroutine ram_allocate

!==============================================================================
subroutine ram_deallocate

  implicit none; save

!!!!!!!! Deallocate Arrays
! Main RAM Variables
  DEALLOCATE(F2, FLUX,PPerH, PParH, PPerE, PParE, PPerO, PParO, PPerHe, PParHe, &
             PAllSum, PParSum, PPerT, PParT, FNHS, FNIS, BOUNHS, BOUNIS, dIdt, &
             dBdt, dIbndt, HDNS, BNES)
! ModRamInit Variables
  DEALLOCATE(RMAS, V, VBND, GREL, GRBND, FACGR, EPP, ERNH, UPA, WE, DE, EKEV, &
             EBND, PHI, LT, MLT, MU, DMU, WMU, PAbn, LZ, RLZ, AMLA, BE, GridExtend, &
             ZRPabn, FFACTOR)
! ModRamWPI Variables
  DEALLOCATE(WALOS1, WALOS2, WALOS3, fpofc, NDVVJ, NDAAJ, ENOR, ECHOR, BDAAR, &
             CDAAR)
! ModRamLoss Variables
!  DEALLOCATE(ATLOS, ACHAR)
! ModRamEField Variables
  DEALLOCATE(VT, EIR, EIP, VTOL, VTN)
! ModRamBoundary Variables
  DEALLOCATE(FGEOS)
! ModRamDrift Variables
!  DEALLOCATE(P1, VR, P2, EDOT, MUDOT, CDriftR, sgnDriftR, CDriftE, CDriftP, &
!             CDriftMu)
  DEALLOCATE(DtDriftR, DtDriftP, DtDriftE, DtDriftMu)
! ModRamRun Variables
  DEALLOCATE(SETRC, ELORC, LSDR, LSCHA, LSATM, LSCOE, LSCSC, LSWAE, XNN, XND, &
             LNCN, LNCD, LECN, LECD, ENERN, ENERD, ATEW, ATAW, ATAC, ATEC, &
             XNE, ATMC, ATAW_emic, NECR)
!!!!!!!!!

end subroutine ram_deallocate

!==============================================================================
SUBROUTINE ram_init
  !!!! Module Variables
  use ModRamParams,    ONLY: DoUseWPI, DoUseBASDiff
  use ModRamMain,      ONLY: Real8_, S
  use ModRamTiming,    ONLY: TimeRamStart, TimeMax, TimeRamRealStart, TimeRamNow
  use ModRamGrids,     ONLY: RadiusMax, RadiusMin, nR, nRExtend, nT
  use ModRamVariables, ONLY: PParH, PPerH, PParHe, PPerHe, PParO, PPerO, PParE, &
                             PPerE, LSDR, LSCHA, LSATM, LSCOE, LSCSC, LSWAE, ELORC, &
                             SETRC, XNN, XND, ENERN, ENERD, LNCN, LNCD, LECN, LECD
  !!!! Modules Subroutines/Functions
  use ModRamWPI,     ONLY: WAPARA_HISS, WAPARA_BAS, WAPARA_CHORUS, WAVEPARA1, WAVEPARA2
  use ModRamIndices, ONLY: init_indices, get_indices
  !!!! Share Modules
  use ModTimeConvert, ONLY: TimeType, time_real_to_int
  use ModNumConst,    ONLY: cTwoPi

  implicit none; save

  character(len=8)   :: StringSysDate
  character(len=10)  :: StringSysTime
  character(len=200) :: NameEFile

  type(timetype) :: TimeRamStop, TimeNext

  real(kind=Real8_) :: WEIGHT, dR, dPh

  integer :: iR, iPhi, iS
  integer :: nFive, nFiveDay, nHour
  integer :: I, J, K, L, IK

  character (len=*), parameter :: NameSub='init_ram'
  logical                      :: DoTest, DoTestMe
!------------------------------------------------------------------------------
  TimeRamStop%Time = TimeRamStart%Time + TimeMax
  call time_real_to_int(TimeRamStop)
  call init_indices(TimeRamRealStart, TimeRamStop)
  call get_indices(TimeRamNow%Time, Kp, f107)

!!!!!!!!! Zero Values
  ! Initialize Pressures.
  PPerH  = 0
  PParH  = 0
  PPerO  = 0
  PParO  = 0
  PPerHe = 0
  PParHe = 0
  PPerE  = 0
  PParE  = 0

  ! Initial loss is zero
  LNCN  = 0.
  LNCD  = 0.
  LECN  = 0.
  LECD  = 0.
  LSDR  = 0.
  LSCHA = 0.
  LSATM = 0.
  LSCOE = 0.
  LSCSC = 0.
  LSWAE = 0.
  ELORC = 0.
  SETRC = 0.

  ! Initial energy and density
  XNN   = 0
  XND   = 0
  ENERN = 0
  ENERD = 0
!!!!!!!!!

!!!!!!!!!! Initialize grid.
  ! Radial distance
  dR = (RadiusMax - RadiusMin)/(nR - 1)
  do iR = 1, nR+1 ! DANGER WE SHOULD CHANGE THIS AND ALL ARRAYS USING NR+1
     Lz(iR) = RadiusMin + (iR - 1)*dR
  end do

  ! Create extended radial grid for coupling:
  do iR=1, nRextend
     GridExtend(iR) = RadiusMin + (iR-1)*dR
  end do

  ! Longitude in radians
  dPh = cTwoPi/(nT - 1)
  do iPhi = 1, nT
     Phi(iPhi) = (iPhi - 1)*dPh
  end do

  ! Intialize arrays
  do S=1,4
     call Arrays
     IF (DoUseWPI) THEN
        if (S.EQ.1) then
           CALL WAPARA_HISS
           IF (DoUseBASdiff) then
              print*, 'RAM-e: using BAS diff coeffic '
              CALL WAPARA_BAS
           ELSE
              print*, 'RAM-e: user-supplied diff coeffic '
              CALL WAPARA_CHORUS
           ENDIF
        end if
     ELSE
        if (S.EQ.1) then
           print*, 'RAM-e: using electron lifetimes '
           CALL WAVEPARA1
           CALL WAVEPARA2
        end if
     ENDIF
  end do

END SUBROUTINE ram_init

!**************************************************************************
!                               ARRAYS
!                       Set up all the arrays
!**************************************************************************
  SUBROUTINE ARRAYS
    !!!! Module Variables
    use ModRamMain,  ONLY: Real8_, S
    use ModRamConst, ONLY: RE, PI, M1, MP, CS, Q, HMIN
    use ModRamGrids, ONLY: RadiusMax, RadiusMin, NR, NPA, Slen, NT, NE, &
                           NS, NLT, EnergyMin
    use ModRamParams, ONLY: DoUsePlane_SCB
    !!!! Module Subroutines/Functions
    use ModRamFunctions, ONLY: ACOSD, ASIND, COSD, SIND

    implicit none; save

    real(kind=Real8_) :: degrad, camlra, elb, rw, rwu
    real(kind=Real8_) :: clc, spa, MUBOUN
    real(kind=Real8_), ALLOCATABLE :: CONE(:),RLAMBDA(:)

    integer :: i, j, k, l, iml, ic, ip

    character(len=80) TITLE

    ALLOCATE(CONE(NR+4),RLAMBDA(NPA))

    ! Grid size of L shell
    DL1 = (RadiusMax - RadiusMin)/(nR - 1)
    IF ((MOD(DL1,0.25_8).NE.0).and.(DoUsePlane_SCB)) THEN
      write(*,*) MOD(DL1,0.25_8)
      WRITE(6,*) 'RAM: Error : DL is not a multiple of 0.25 '
      STOP
    END IF

    degrad=pi/180.
    amla(1)=0. ! Magnetic latitude grid in degrees
    DO I=2,6
      amla(i)=amla(i-1)+0.2
    ENDDO
    DO I=7,24
      amla(i)=amla(i-1)+0.5
    ENDDO
    DO I=25,Slen
      amla(i)=amla(i-1)+2.
    ENDDO

    IR1=DL1/0.25
    MDR=DL1*RE               ! Grid size for Z=RO
    DO I=1,NR+1
      LZ(I)=2.+(I-2)*DL1
      RLZ(I)=RE*LZ(I)
      DO IML=1,Slen
        camlra=amla(iml)*degrad
        BE(I,IML)=0.32/LZ(I)**3*SQRT(1.+3.*SIN(camlra)**2)/COS(camlra)**6
      ENDDO
    END DO

    DPHI=2.*PI/(NT-1)      ! Grid size for local time [rad]
    IF (MOD(NLT,NT-1).NE.0) THEN
      WRITE(6,*) ' Error : NT-1 is not a factor of NLT '
      STOP
    END IF

    DO J=1,NT
      PHI(J)=(J-1)*DPHI ! Magnetic local time in radian
      MLT(J)=PHI(J)*12./PI ! Magnetic local time in hour
    END DO
    IP1=(MLT(2)-MLT(1))/0.5

    DO I=1,4
      RMAS(I)=MP*M1(I) ! rest mass of each species (kg)
    END DO

    ! Calculate Kinetic Energy EKEV [keV] at cent, RW depends on NE
    ELB=EnergyMin ! Lower limit of energy in keV
    IF (ELB.EQ.0.01) THEN
      WE(1)=2.8E-3 !  |_._|___.___|____.____|______.______|
      RW=1.36 !    .     <   DE   >    <      WE     >
    END IF                  !   EKEV                EBND
    IF (ELB.EQ.0.1) THEN ! relativistic
      WE(1)=3E-2
      RW=1.27
    END IF
    IF (ELB.EQ.1) THEN
      WE(1)=0.31
      RW=1.16
    END IF

    EKEV(1)=ELB+0.5*WE(1)
    GREL(S,1)=1.+EKEV(1)*1000.*Q/RMAS(S)/CS/CS
    V(S,1)=CS*SQRT(GREL(S,1)**2-1.)/GREL(S,1)
    EBND(1)=ELB+WE(1)
    GRBND(S,1)=1.+EBND(1)*1000.*Q/RMAS(S)/CS/CS
    VBND(S,1)=CS*SQRT(GRBND(S,1)**2-1.)/GRBND(S,1)
    DO K=1,NE-1
      WE(K+1)=WE(K)*RW                   ! WE(K) [keV] is a power series
      EBND(K+1)=EBND(K)+WE(K+1)          ! E[keV] at bound of grid
      DE(K)=0.5*(WE(K)+WE(K+1))
      EKEV(K+1)=EKEV(K)+DE(K)     ! E[keV] at cent of grid
      GREL(S,K+1)=1.+EKEV(K+1)*1000.*Q/RMAS(S)/CS/CS
      V(S,K+1)=CS*SQRT(GREL(S,K+1)**2-1.)/GREL(S,K+1)   ! Veloc [m/s] at cent
      GRBND(S,K+1)=1.+EBND(K+1)*1000.*Q/RMAS(S)/CS/CS
      VBND(S,K+1)=CS*SQRT(GRBND(S,K+1)**2-1.)/GRBND(S,K+1) ! Veloc [m/s] at bound
    END DO
    DE(NE)=0.5*WE(NE)*(1.+RW)

    ! CONE - pitch angle loss cone in degree
    DO I=1,NR
      CLC=(RE+HMIN)/RLZ(I)
      CONE(I)=ASIND(SQRT(CLC**3/SQRT(4.-3.*CLC)))
    END DO
    CONE(NR+1)=2.5 ! to calcul PA grid near 0 deg
    CONE(NR+2)=1.5
    CONE(NR+3)=1.
    CONE(NR+4)=0.

    ! PA is equatorial pitch angle in deg - PA(1)=90, PA(NPA)=0.
    ! MU is cosine of equatorial PA
    PA(1)=90.
    MU(1)=0.
    PA(NPA)=0.
    MU(NPA)=1.
    RWU=0.98
    WMU(1)=(MU(NPA)-MU(1))/32
                         ! |_._|___.___|____.____|______.______| 
    DO L=1,46            !   MU    <  DMU   >    <     WMU     >
      WMU(L+1)=WMU(L)*RWU
      DMU(L)=0.5*(WMU(L)+WMU(L+1))
      MU(L+1)=MU(L)+DMU(L)
      PA(L+1)=ACOSD(MU(L+1))
    END DO
    PA(48)=18.7
    MU(48)=COSD(PA(48))
    DMU(47)=(MU(48)-MU(47))
    IC=2
    DO L=48,NPA-1
      PA(L+1)=CONE(IC)
      IF(L.EQ.49) THEN
        PA(50)=16.
      ELSE
        if (IC.lt.nR) then
           IC=IC+(nR-1)/19
        else
           IC=IC+1
        endif
      ENDIF
      MU(L+1)=COSD(PA(L+1))
      DMU(L)=(MU(L+1)-MU(L))       ! Grid size in cos pitch angle
      WMU(L)=2.*(DMU(L-1)-0.5*WMU(L-1))
      IF (L.GT.55) WMU(L)=0.5*(DMU(L)+DMU(L-1))
    END DO
    DMU(NPA)=DMU(NPA-1)
    WMU(NPA)=DMU(NPA-1)
    DO L=1,NPA-1
      MUBOUN=MU(L)+0.5*WMU(L)
      PAbn(L)=ACOSD(MUBOUN) ! PA at boundary of grid
    ENDDO
    PAbn(NPA)=0.

    ! Determine the range of NPA such that PA is outside the loss cone:
    ! UPA is upper boundary for pitch angle for given Z
    DO I=1,NR
      UPA(I) = NPA ! SZ, otherwise UPA = 0 for small enough loss cones
      DO L=NPA,1,-1
        IF(PA(L).LE.CONE(I)) UPA(I) = L     ! F(UPA)=0. - in loss cone
      END DO
    END DO

    ! calculate pitch angles for mlat
    DO I=1,NR
       DO IML=1,Slen
          DO IP=1,NPA
             spa=SQRT(SIND(PAbn(ip))**2*BE(i,iml)/BE(i,1))
             IF (spa.GT.1.0) spa=1.0
                ZRpabn(i,ip,iml)=ASIN(spa)
             IF (spa.EQ.1.0) THEN
                ZRpabn(i,ip,iml)=-1.0
             END IF
          ENDDO
       ENDDO
    ENDDO

    ! FFACTOR is ratio of F2 in conservative space to flux
    ! E* are factors to calculate temperature anisotropy
    DO I=1,NR
      DO K=1,NE
        DO L=2,NPA
          FFACTOR(S,I,K,L)=LZ(I)*LZ(I)*GREL(S,K)/SQRT(GREL(S,K)**2-1.)*MU(L)
          if (ffactor(s,i,k,l).le.0) print*,'s,i,k,l,ffactor=',s,i,k,l,ffactor(s,i,k,l)
        ENDDO
        FFACTOR(S,I,K,1)=FFACTOR(S,I,K,2)
      END DO
    END DO

    DO K=1,NE
      ERNH(S,K)=WE(K)*GREL(S,K)/SQRT((GREL(S,K)-1.)*(GREL(S,K)+1.)) ! [1/cm3]
      EPP(S,K)=ERNH(S,K)*EKEV(K)
      FACGR(S,K)=GREL(S,K)*SQRT((GREL(S,K)-1.)*(GREL(S,K)+1.))
    END DO

    ! to keep F constant at boundary 
    CONF1=((LZ(NR)+DL1)/LZ(NR))**2
    CONF2=((LZ(NR)+2.*DL1)/LZ(NR))**2

    RFACTOR=3.4027E10*MDR*DPHI

    DEALLOCATE(CONE,RLAMBDA)
    RETURN
  END SUBROUTINE ARRAYS

!==============================================================================
SUBROUTINE init_input
  !!!! Module Variables
  use ModRamMain,      ONLY: Real8_, S, PathRamIn, nIter
  use ModRamParams,    ONLY: IsRestart, IsStarttimeSet, electric, IsComponent, &
                             DoUsePlane_SCB, HardRestart
  use ModRamGrids,     ONLY: NR, NT, NE, NPA, NL, NLT
  use ModRamTiming,    ONLY: DtEfi, T, TimeRamNow, TimeRamElapsed, TOld
  use ModRamVariables, ONLY: F2, XNN, XND, ENERD, ENERN, FNHS, Kp, F107, TOLV, &
                             NECR
  use ModScbGrids,     ONLY: nthe, npsi, nzeta
  use ModScbVariables, ONLY: xpsiin, xpsiout, psiVal, alphaVal, f, fp, fzet, &
                             fzetp, xzero3, constZ, psiin, psiout, psitot
  use ModScbParams,    ONLY: method
  !!!! Module Subroutines/Functions
  use ModRamRun,       ONLY: ANISCH
  use ModRamBoundary,  ONLY: get_boundary_flux
  use ModRamRestart,   ONLY: read_restart
  use ModRamIndices,   ONLY: get_indices
  use ModRamIO,        ONLY: read_initial
  use ModRamFunctions, ONLY: ram_sum_pressure
  use ModRamScb,       ONLY: computehI, compute3DFlux
  use ModScbRun,       ONLY: scb_run, pressure
  use ModScbEuler,     ONLY: psiges, alfges
  use ModScbIO,        ONLY: computational_domain
  use ModScbCompute,   ONLY: computeBandJacob_Initial, compute_convergence
  !!!! Share Modules
  use ModIOUnit,      ONLY: UNITTMP_
  use ModTimeConvert, ONLY: TimeType
  !!!!
  use nrtype, ONLY: twopi_d

  implicit none; save

  integer :: iS, i, j, k, l, ik, N, methodTemp
  integer :: iR, iT, iE, iPA
  real(kind=Real8_) :: F2r(NR,NT,36,NPA)
  real(kind=Real8_) :: xpsitot, psis, xpl, phi, dphi

  character(len=100) :: HEADER
  character(len=200) :: fileName

  character(len=*), parameter :: NameSub='init_input'


  !!!!!!!!!! Restart vs Initial Run
  if(IsRestart) then
     ! If Restart, read restart params and set timings appropriately.
     if (IsStarttimeSet) call CON_stop(NameSub//&
          ': Cannot use #STARTTIME command with #RESTART!')

     !!!!!! RESTART DATA !!!!!!!
     call read_restart

     call psiges
     call alfges

     call get_indices(TimeRamNow%Time, Kp, f107)
     TOLV = FLOOR(TimeRamElapsed/DtEfi)*DtEfi

     ! Compute information not stored in restart files
     if (HardRestart) then
        call computational_domain
        call ram_sum_pressure
        call scb_run(0)
        call computehI(0)
        call compute3DFlux
     else
        methodTemp = method
        call ComputeBandJacob_Initial
        call compute3DFlux
     endif

     call get_boundary_flux ! FGEOS
  else
     nIter = 1
     !!!!!! INITIALIZE DATA !!!!!
     call read_initial

     ! Initial indices
     call get_indices(TimeRamNow%Time, Kp, f107)
     TOLV = 0.0

     ! Compute the SCB computational domain
     call write_prefix
     write(*,*) 'Running SCB model to initialize B-field...'

     call computational_domain

     call ram_sum_pressure
     call scb_run(0)

     ! Couple SCB -> RAM
     call computehI(0)

     call compute3DFlux

     call write_prefix
     write(*,*) 'Finished 3D Equilibrium code.'

     if (DoUsePlane_SCB) then
        write(*,*) "Reading in initial plasmasphere density model"
        OPEN(UNITTMP_,FILE='ne_full.dat',STATUS='OLD') ! Kp=1-2 (quiet)
        READ(UNITTMP_,'(A)') HEADER
        READ(UNITTMP_,*) ((NECR(I,J),I=1,NL),J=0,NLT)  ! L= 1.5 to 10
        CLOSE(UNITTMP_)
     endif
  end if
!!!!!!!!

 return

end subroutine init_input

END MODULE ModRamInit
