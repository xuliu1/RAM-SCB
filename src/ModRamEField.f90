!============================================================================
!    Copyright (c) 2016, Los Alamos National Security, LLC
!    All rights reserved.
!============================================================================

MODULE ModRamEField
! Contains subroutines related to getting the electric field for RAM

  use ModRamVariables, ONLY: VT, VTOL, VTN, TOLV, EIR, EIP

  implicit none; save; save

  contains

!==============================================================================
subroutine get_electric_field

  use ModRamMain,      ONLY: Real8_
  use ModRamTiming,    ONLY: TimeRamNow, DtEfi, TimeRamElapsed
  use ModRamConst,     ONLY: RE
  use ModRamParams,    ONLY: electric, IsComponent
  use ModRamGrids,     ONLY: NR, NT
  use ModRamVariables, ONLY: KP, PHI, LZ, PHIOFS
  use ModRamCouple,    ONLY: SwmfPot_II

  use ModTimeConvert, ONLY: TimeType, time_real_to_int

  implicit none; save; save

  real(kind=Real8_) :: AVS
  integer :: I, J
  type(TimeType) :: TimeNext
  character(len=200) :: NameEfile

  ! Set "new" values of indices and E-field to "old" values. 
  VTOL = VTN
  print*,'RAM: updating E field at time ', TimeRamElapsed/3600.

  ! Generate name of next electric field file:
  TimeNext = TimeRamNow
  if (electric.ne.'IESC') then
     TimeNext % Time = TimeNext % Time + DtEfi
  else
     TimeNext % Time = TimeNext % Time
  end if
  call time_real_to_int(TimeNext)
  call ram_gen_efilename(TimeNext, NameEfile)

  ! Open this file and save contents.
  if(electric .ne. 'VOLS') call ram_get_electric(NameEfile, vtn)

  ! No interpolation for IESC case.
  if(electric .eq. 'IESC') vtol=vtn

  ! Set time of "old" file for interpolation:
  TOLV=TimeRamElapsed
  if (IsComponent .OR. electric=='WESC' .or. electric=='W5SC') then
     VTOL = SwmfPot_II
     VTN  = SwmfPot_II
  endif

  DO I=1,NR+1
     DO J=1,NT
        if (electric .ne. 'VOLS') then
           VT(I,J)=VTOL(I,J)+(VTN(I,J)-VTOL(I,J))*(TimeRamElapsed-TOLV)/DtEfi
        else
           AVS=7.05E-6/(1.-0.159*KP+0.0093*KP**2)**3/RE  ! Voll-Stern parameter
           VT(I,J)=AVS*(LZ(I)*RE)**2*SIN(PHI(J)-PHIOFS) ! [V]
        endif
     ENDDO
  ENDDO

end subroutine

!============================================================================
subroutine ram_gen_efilename(TimeIn,NameOut)
!    Generate the correct filname given TimeIn, start time TimeRamStart,
!    and electric field model Electric.  Returned is a 100-character character
!    with the full file name.
!    Copyright (c) 2016, Los Alamos National Security, LLC
!    All rights reserved.
!******************************************************************************

  use ModRamFunctions, ONLY: RamFileName
  use ModRamMain,      ONLY: PathRamIn
  use ModScbMain,      ONLY: PathScbOut
  use ModRamParams,    ONLY: electric

  use ModTimeConvert, ONLY: TimeType

  implicit none; save; save

  ! Args and return value.
  type(TimeType), intent(in) :: TimeIn
  character(len=200), intent(out):: NameOut

  integer :: nDay, nFile, nFive
  character(len=*), parameter :: NameSub = 'ram_gen_efilename'
  !--------------------------------------------------------------------------

  ! Generate file name based on time of simulation and file type.
  select case(trim(electric))

  case('WESC')
     ! use weimer 2001  along sc field lines.
     RETURN

  case('W5SC')
     ! use weimer 2005 along sc field lines.
     RETURN

  case('IESC') !SWMF IE potential traced to equitorial plane using SCB.
     NameOut = trim(PathScbOut)//RamFileName('/IE_SCB','in',TimeIn)

  case('IE89') !SWMF IE potential traced to equitorial plane using T89.
     NameOut = trim(PathRamIn)//RamFileName('/IE','in',TimeIn)

  case('WE01') !Weimer 2001 electric potential.
     NameOut = trim(PathRamIn)//RamFileName('/weq01','in',TimeIn)

  case('VOLS') !Volland-Stern electric potential.
     NameOut = trim(PathRamIn)//RamFileName('/vsc02','in',TimeIn)
  
  case default
     call CON_stop(NameSub//' ERROR: Unsupported electric field file type')

  end select

end subroutine ram_gen_efilename

!============================================================================
subroutine ram_get_electric(NextEfile, EOut_II)
  ! Open E-field file "NextFile", collect E-field and indices, update
  ! "NextFile" and return all of the above to the caller.

  use ModRamMain,      ONLY: Real8_, PathRamIn, PathScbOut
  Use ModRamTiming,    ONLY: TimeRamElapsed, TimeRamNow
  use ModRamParams,    ONLY: electric, IsComponent, IsRestart
  use ModRamGrids,     ONLY: NR, NT, RadiusMax
  use ModRamVariables, ONLY: PHIOFS, Kp, F107
  use ModRamCouple,    ONLY: SwmfPot_II
  use ModRamFunctions, ONLY: RamFileName
  use ModRamGSL,       ONLY: GSL_Interpolation_2D
  use ModScbMain,      ONLY: prefixOut
  use ModScbGrids,     ONLY: npsi, nzeta
  use ModScbVariables, ONLY: PhiIono, radRaw, azimRaw, x, y, nThetaEquator

  use ModTimeConvert, ONLY: TimeType
  use ModIOUnit,      ONLY: UNITTMP_

  use nrtype, ONLY: DP,pi_d

  implicit none; save; save

  integer :: GSLerr
  ! Arguments
  character(len=200),intent(in)  :: NextEfile
  real(kind=Real8_), intent(out) :: EOut_II(NR+1, NT)
  ! Kp, F10.7 no longer acquired through E-field files.
  real(kind=Real8_):: KpOut, f107Out
  
  type(TimeType) :: TimeNext
  integer :: nDay, nFile, iError, i, j, k, jw
  character(len=200) :: StringHeader, NameFileOut
  REAL(kind=Real8_) :: Epot_Cart(0:nR,nT)
  real(kind=Real8_) :: day, tth, ap, rsun, RRL, PH, wep(49)
  REAL(kind=Real8_) :: radOut
  REAL(kind=Real8_) :: xo(nR,nT), yo(nR,nT)
  character(len=*), parameter :: NameSub = 'ram_get_electric'
  !--------------------------------------------------------------------------
  radOut = RadiusMax+0.25

  ! Initialize efield to zero.
  ! NOTE THAT ON RESTART, WE MUST CHANGE THIS.
  if (.not.IsRestart) THEN
     EOut_II  = 0.0
     Epot_Cart = 0.0
  endif

  IF ((electric.EQ.'WESC').or.(electric.eq.'IESC').or.(electric.eq.'W5SC')) THEN
     DO j = 0,nR
        radRaw(j) = 1.75 + (radOut-1.75) * REAL(j,DP)/REAL(nR,DP)
     END DO
     DO k = 1,nT
        azimRaw(k) = 24.0 * REAL(k-1,DP)/REAL(nT-1,DP)
     END DO

     ! print*, 'Reading electric potentials from SCB directly'
     CALL ionospheric_potential
     PRINT*, '3DEQ: mapping iono. potentials along B-field lines'
     DO i = 1,nR
        DO j = 1,nT
           xo(i,j) = radRaw(i) * COS(azimRaw(j)*2._dp*pi_d/24._dp - pi_d)
           yo(i,j) = radRaw(i) * SIN(azimRaw(j)*2._dp*pi_d/24._dp - pi_d)
        ENDDO
     ENDDO
     CALL GSL_Interpolation_2D(x(nThetaEquator,:,2:nzeta),y(nThetaEquator,:,2:nzeta), &
                               PhiIono(:,2:nzeta), xo(:,:), yo(:,:), Epot_Cart(:,:), GSLerr)
     Epot_Cart(0,:) = Epot_Cart(1,:) ! 3Dcode domain only extends to 2 RE; at 1.75 RE the potential is very small anyway

     SWMF_electric_potential:  IF (electric=='IESC') THEN
           NameFileOut=trim(prefixOut)//trim(RamFileName('IE_SCB','in',TimeRamNow))
           PRINT*, 'Writing to file ', NameFileOut
           OPEN(UNITTMP_, file = NameFileOut, &
                action = 'write', status = 'unknown')
           ! Write header to file.  
           WRITE(UNITTMP_, '(A, i4.4)') ' DOM   UT      Kp   F107   Ap   Rs PHIOFS, Year ', TimeRamNow%iYear
           WRITE(UNITTMP_, '(f5.0, 2x, f6.3, 2x, f4.2, 2x, f5.1, 2x, 2(f4.1,2x), f3.1)') &
                REAL(TimeRamNow%iDay), REAL(TimeRamNow%iHour) + &
                REAL(TimeRamNow%iMinute)/60.0, kp, f107, 0.0, 0.0, 0.0
           WRITE(UNITTMP_, '(A)') 'SWMF ionospheric potential mapped along SCB lines'
           WRITE(UNITTMP_, '(A)') 'L     PHI       Epot(kV)'
           DO i = 0, nR
              DO j = 1, nT
                 WRITE(UNITTMP_, 22) radRaw(i), azimRaw(j)*2.*pi_d/24., Epot_Cart(i,j)
              END DO
           END DO
           CLOSE(UNITTMP_)

           ! Save traced potential to ModRamCouple::SwmfPot_II
           IF(IsComponent) SwmfPot_II(1:nR+1,1:nT) = Epot_Cart(0:nR,  1:nT)
     END IF SWMF_electric_potential
22   FORMAT(F4.2, 2X, F8.6, 2X, E11.4)

     Weimer_electric_potential_along_SCB: IF (electric=='WESC' .or. electric=='W5SC') THEN
           if ((maxval(Epot_Cart).lt.300000).and.(minval(Epot_Cart).gt.-300000)) then
              SwmfPot_II(1:nR+1,1:nT) = Epot_Cart(0:nR, 1:nT)
           endif
           print*, 'SwmfPot_II here SwmfPot_II mm', maxval(swmfpot_II), minval(swmfpot_ii)
     END IF Weimer_electric_potential_along_SCB

     RETURN
  END IF

  call write_prefix
  write(*,*) 'Reading EFile ', trim(NextEFile)
  write(*,'(a,f10.1)')'          at Sim Time', TimeRamElapsed

  !\
  ! Read first file and indices.
  !/
  open(file=NextEfile, unit=UNITTMP_, status='OLD', &
       action='READ', IOSTAT=ierror)

  if(ierror .ne. 0) &
       call CON_stop(NameSub//': ERROR opening file '//trim(NextEfile))

  ! Read header, get Kp and F107 (skip the other crap)
  read(UNITTMP_,'(a)') StringHeader
  read(UNITTMP_,*) day, tth, KpOut, f107Out, ap, rsun, phiofs
  read(UNITTMP_,'(a)') StringHeader
  read(UNITTMP_,'(a)') StringHeader

  ! If coupled to SWMF IE, first E-field is zero.
  if(IsComponent .and. electric .eq. 'IESC') then 
     close(UNITTMP_)
     return
  endif

  do i=1,nR+1
     if (electric.EQ.'IESC') then
        do JW=1,NT
           read(UNITTMP_,*) RRL,PH,WEP(JW) ! conv potential in kV
        enddo
     else
        do JW=1,49
           read(UNITTMP_,*) RRL,PH,WEP(JW) ! conv potential in kV
        enddo
     end if
     do J=1,NT
        if(NT.EQ.49 .OR. electric.EQ.'IESC') JW=J
        if(NT.EQ.25 .AND. electric.NE.'IESC') JW=2*J-1
        EOut_II(I,J)=WEP(JW)*1e3 ! to convert in [V]
     enddo
  enddo

  close(UNITTMP_)

  do J=1,NT
     do I=NR,1,-1
        if (EOut_II(I,J).EQ.0) EOut_II(I,J) = EOut_II(I+1,J)/2
     enddo
  enddo

end subroutine ram_get_electric

!============================================================================
SUBROUTINE ionospheric_potential
  !!!! Module Variables
  use ModRamMain,      ONLY: PathSwmfOut
  use ModRamTiming,    ONLY: TimeRamNow, TimeRamElapsed
  use ModRamParams,    ONLY: IsComponent, electric, UseSWMFFile
  use ModRamCouple,    ONLY: SwmfIonoPot_II, nIePhi, nIeTheta
  use ModRamIndices,   ONLY: NameOmniFile
  use ModScbMain,      ONLY: iConvE
  use ModScbGrids,     ONLY: npsi, nzeta, nthe, nzetap
  use ModScbVariables, ONLY: phiiono, x, y, z, r0Start, dPhiIonodAlpha, &
                             dPhiIonodBeta, f, fzet, zetaVal, rhoVal, tilt
  !!!! Module Subroutine/Functions
  use ModRamGSL,    ONLY: GSL_Interpolation_2D, GSL_Derivs
  use ModScbIO,     ONLY: Write_Ionospheric_Potential
  !!!! Share Modules
  use ModTimeConvert, ONLY: n_day_of_year
  use ModIOUnit, ONLY: UNITTMP_
  !!!! Extra Modules
  use w05
  !!!! NR Modules
  use nrtype, ONLY: DP

  IMPLICIT NONE

  integer :: doy, GSLerr
  INTEGER :: i, ierralloc, j, j1, k1, k, ierr, ierrDom, idealerr
  REAL(DP) :: dPhiIonodRho(npsi, nzeta+1), dPhiIonodZeta(npsi, nzeta+1), &
       colatGrid(npsi,nzeta+1), lonGrid(npsi,nzeta+1), latGrid(npsi,nzeta+1)
  REAL(DP) :: radius, angle, lineData(3)
  REAL(DP) :: thangle, zangle, byimf, bzimf_l
  REAL(DP) :: bt, swvel, swden, alindex, bndylat
  INTEGER :: ier, iCount_neighbor, iDomain
  INTEGER :: iTimeArr(0:24), dstArr(0:24)
  INTEGER :: iYear_l, iDoy_l, iHour_l, iMin_l, iLines
  integer :: isec_l, imsec_l, imonth_l, iday_l
  REAL(DP) :: bzimfArr_l, byimf_l, pdyn_l, Nk_l, Vk_l, bTot_l
  real(DP) :: bximf_l, vx_l, vy_l, vz_l, t_l
  INTEGER :: AL_l, SymH_l
  REAL(DP), ALLOCATABLE :: colat(:), lon(:), phiIonoRaw(:,:)
  REAL(DP), EXTERNAL :: EpotVal, BoundaryLat
  CHARACTER(LEN = 3) :: zeroChars
  CHARACTER(LEN = 15) :: StringDateTime
  CHARACTER(LEN = 100) :: header
  LOGICAL :: UseAL

  INTEGER, PARAMETER :: mlat_range = 36, mlon_range = 91
  REAL(DP), PARAMETER :: tiny = 1.E-6_dp

  DO k = 2, nzeta
     DO j = 1, npsi
        radius = SQRT((x(1,j,k))**2 + y(1,j,k)**2)
        angle = ATAN2(y(1,j,k), x(1,j,k)) ! Angle from noon
        IF (angle < 0.) angle = angle + 2.*pi_d
        colatGrid(j,k) = 0.5_dp*pi_d - ASIN(-z(1,j,k)/r0Start)
        latGrid(j,k) = 0.5 * pi_d - colatGrid(j,k) ! In radians
        lonGrid(j,k) = angle
     END DO
  END DO

  ! Periodicity
  colatGrid(:,nzetap) = colatGrid(:,2)
  lonGrid(:,nzetap) = lonGrid(:,2) + 2.*pi_d
  latGrid(:,nzetap) = latGrid(:,2)
  colatGrid(:,1) = colatGrid(:,nzeta)
  lonGrid(:,1) = lonGrid(:,nzeta) - 2.*pi_d
  latGrid(:,1) = latGrid(:,nzeta)

  SELECT CASE (electric)

  CASE('IESC') ! interpolate SWMF iono potentials on 3Dcode ionospheric grid
     if(IsComponent) then
        ! If coupled to SWMF, we don't need to open any files and crap.
        ! Initialize arrays and fill with correct values.
        ! IM_wrapper ensures that, despite the IE grid, we always
        ! have values from and including 10 to 80 degrees colat.
        if(.not. allocated(PhiIonoRaw)) &
             allocate(PhiIonoRaw(nIeTheta, nIePhi))
        if(.not. allocated(colat) .and. .not. allocated(lon)) then
           allocate(colat(nIeTheta), lon(nIePhi))
           colat = 0.0
           lon   = 0.0
           do i=2, nIePhi ! Longitude goes from 0 to 360.
              lon(i) = lon(i-1) + 2.0_dp*pi_d/real(nIePhi-1)
           end do
           do i=2, nIeTheta ! Colat goes from 10 to 80.
              colat(i) = colat(i-1) + (7.0_dp/18.0_dp) *pi_d/real(nIeTheta-1)
           end do
           colat = colat + pi_d/18.0_dp
        end if
        ! Plug SWMF/IE potential into PhiIonoRaw; then we're all set.
        PhiIonoRaw = SwmfIonoPot_II

     else
        ! We now return you to your regularly scheduled 3DEQ code.
        ! Potential from self-consistent electric field calculated in the ionosphere
        ! Yu. 2016 August
!        if(.not. allocated(PhiIonoRaw)) &
!             allocate(PhiIonoRaw(IONO_nTheta, IONO_nPsi))
!        if(.not. allocated(colat) .and. .not. allocated(lon)) then
!           allocate(colat(IONO_nTheta), lon(IONO_nPsi))
!           colat = 0.0
!           lon   = 0.0
!           do i=2, IONO_nPsi ! Longitude goes from 0 to 360.
!              lon(i) = lon(i-1) + 2.0_dp*pi_d/real(IONO_nPsi-1)
!           end do
!           do i=2, IONO_nTheta ! Colat goes from 0 to 90.
!              colat(i) = colat(i-1) +  0.5*pi_d/real(IONO_nTheta-1)
!           end do
!        end if
!        ! Plug self-consisent/IE potential into PhiIonoRaw (only northern)
!        CALL IE_Run(TimeRamElapsed, TimeRamNow%Time)
!        PhiIonoRaw = Iono_North_Phi
     end if

     ! Now there should be no difference between what 
     ! we do for coupled and non-coupled cases.

     !   lon(mlon_range) = 2._dp*pi_d + lon(1)
     !   phiIonoRaw(:,mlon_range) = phiIonoRaw(:,1)

     CALL GSL_Interpolation_2D(colat, lon, PhiIonoRaw, colatGrid(1:npsi,2:nzetap), &
                               lonGrid(1:npsi,2:nzetap), PhiIono(1:npsi,2:nzetap), GSLerr)

  CASE('WESC') ! Potential by calling Weimer function 
     !C OPEN(UNITTMP_, FILE='./omni_5min_Sep2005.txt', status = 'UNKNOWN',
     !action = 'READ')
     OPEN(UNITTMP_, FILE=NameOmniFile, status = 'UNKNOWN', action = 'READ')
     i = 0
     ierr = 0
     DO WHILE (ierr == 0)
        READ(UNITTMP_, *, IOSTAT=ierr) header
        i = i+1
     END DO
     iLines = i-1
     !C PRINT*, 'IP: the file has ', iLines, ' lines.'

     ! Rewind file
     REWIND(UNITTMP_)

     if (UseSWMFFile) then
        UseAL = .false.
        print*, 'IP: year, month, day, hour, min, btot, bz, v, n'
        Read_SWMF_file: DO i = 1, iLines
           read(UNITTMP_,*) iyear_l, imonth_l, iday_l, ihour_l, imin_l, isec_l, imsec_l, &
                            bximf_l, byimf_l, bzimf_l, vx_l, vy_l, vz_l, nk_l, t_l
           if ((TimeRamNow%iYear.eq.iyear_l).and.(TimeRamNow%iMonth.eq.imonth_l).and. &
               (TimeRamNow%iDay.eq.iday_l).and. &
               (TimeRamNow%iHour.eq.ihour_l).and.(TimeRamNow%iMinute.eq.imin_l)) then
              bTot_l = SQRT(bximf_l**2 + byimf_l**2 + bzimf_l**2)
              vk_l   = SQRT(vx_l**2 + vy_l**2 + vz_l**2)
              write(*,*)iyear_l,imonth_l,iday_l, ihour_l, imin_l, btot_l, bzimf_l, vk_l, nk_l
              EXIT Read_SWMF_file
           END IF
        END DO Read_SWMF_file
     else
        UseAL = .true.
        PRINT*, 'IP: Year, Day, Hour, Min, Bt, By, Bz, V, N, Pdyn, AL, SYMH'
        Read_OMNI_file: DO i = 1, iLines
           READ(UNITTMP_,*) iYear_l, iDoy_l, iHour_l, iMin_l, bTot_l, byimf_l, &
                            bzimf_l, Vk_l, Nk_l, pdyn_l, AL_l, SymH_l
           doy = n_day_of_year(TimeRamNow%iYear, TimeRamNow%iMonth, TimeRamNow%iDay)
           if ((TimeRamNow%iYear.eq.iyear_l).and.(doy.eq.idoy_l).and. &
               (TimeRamNow%iHour.eq.ihour_l).and.(TimeRamNow%iMinute.eq.imin_l)) then
              WRITE(*,*) iYear_l, iDoy_l, iHour_l, iMin_l, bTot_l, byimf_l, &
                         bzimf_l, Vk_l, Nk_l, pdyn_l, AL_l, SymH_l
              EXIT Read_OMNI_file
           END IF
        END DO Read_OMNI_file
     endif
     CLOSE(UNITTMP_)

     angle = 180._dp/pi_d*ACOS(bzimf_l/bTot_l)
     CALL SetModel(angle,bTot_l,tilt,Vk_l,Nk_l,REAL(AL_l,dp),UseAL)
     latGrid = 180._dp/pi_d * latGrid ! Transform latitude to degrees for Weimer EpotVal function
     lonGrid = 12._dp/pi_d * lonGrid ! Transform lonGrid to hours (MLT) for Weimer EpotVal function
     ! Translate to correct MLT
     DO k = 2, nzeta
        DO j = 1, npsi
           IF (lonGrid(j,k) <= 12._dp) THEN
              lonGrid(j,k) = lonGrid(j,k) + 12._dp
           ELSE
              lonGrid(j,k) = lonGrid(j,k) - 12._dp
           END IF
        END DO
     END DO

     Weimer_potential_loop: DO k = 2, nzeta
        DO j = 1, npsi
           PhiIono(j,k) = 1.E3 * EpotVal(latGrid(j,k), lonGrid(j,k)) !!! Achtung RAM needs it in volts !!!
           bndylat = BoundaryLat(lonGrid(j,k))
           ! Add corotation potential - only if RAM takes all E-field info from the equilibrium code 
           ! PhiIono(j,k) = PhiIono(j,k) - 2._dp*pi_d*0.31_dp*6.4**2 *
           ! 1.E3_dp/(24._dp*36._dp*SQRT(x(nThetaEquator,j,k)**2+y(nThetaEquator,j,k)**2))
        END DO
     END DO Weimer_potential_loop

  CASE('W5SC') ! Potential by calling Weimer 2005 function 'W5SC'
     OPEN(UNITTMP_, FILE=NameOmniFile, status = 'UNKNOWN', action = 'READ')
     i = 0
     ierr = 0
     DO WHILE (ierr == 0)
        READ(UNITTMP_, *, IOSTAT=ierr) header
        i = i+1
     END DO
     iLines = i-1
     !C PRINT*, 'IP: the file has ', iLines, ' lines.'

     ! Rewind file
     REWIND(UNITTMP_)

     if (UseSWMFFile) then
        UseAL = .false.
        print*, 'IP: year, month, day, hour, min, by, bz, v, n'
        Read_SWMF_file_05: DO i = 1, iLines
           read(UNITTMP_,*) iyear_l, imonth_l, iday_l, ihour_l, imin_l, isec_l, imsec_l, &
                            bximf_l, byimf_l, bzimf_l, vx_l, vy_l, vz_l, nk_l, t_l
           if ((TimeRamNow%iYear.eq.iyear_l).and.(TimeRamNow%iMonth.eq.imonth_l).and. &
               (TimeRamNow%iDay.eq.iday_l).and. &
               (TimeRamNow%iHour.eq.ihour_l).and.(TimeRamNow%iMinute.eq.imin_l)) then
              vk_l   = SQRT(vx_l**2 + vy_l**2 + vz_l**2)
              write(*,*)iyear_l,imonth_l,iday_l, ihour_l, imin_l, byimf_l, bzimf_l, vk_l, nk_l
              EXIT Read_SWMF_file_05
           END IF
        END DO Read_SWMF_file_05
     else
        UseAL = .true.
        PRINT*, 'IP: Year, Day, Hour, Min, Bt, By, Bz, V, N, Pdyn, AL, SYMH'
        Read_OMNI_file_05: DO i = 1, iLines
           READ(UNITTMP_,*) iYear_l, iDoy_l, iHour_l, iMin_l, bTot_l, byimf_l, &
                            bzimf_l, Vk_l, Nk_l, pdyn_l, AL_l, SymH_l
           doy = n_day_of_year(TimeRamNow%iYear, TimeRamNow%iMonth, TimeRamNow%iDay)
           if ((TimeRamNow%iYear.eq.iyear_l).and.(doy.eq.idoy_l).and. &
               (TimeRamNow%iHour.eq.ihour_l).and.(TimeRamNow%iMinute.eq.imin_l)) then
              WRITE(*,*) iYear_l, iDoy_l, iHour_l, iMin_l, bTot_l, byimf_l, &
                         bzimf_l, Vk_l, Nk_l, pdyn_l, AL_l, SymH_l
              EXIT Read_OMNI_file_05
           END IF
        END DO Read_OMNI_file_05
     endif
     CLOSE(UNITTMP_)

     if (bzimf_l.lt.-20) bzimf_l = -20
     if (bzimf_l.gt.20) bzimf_l = 20
     CALL SetModel05(byimf_l, bzimf_l, tilt, Vk_l, Nk_l)
     latGrid = 180._dp/pi_d * latGrid ! Transform latitude to degrees for Weimer EpotVal function
     lonGrid = 12._dp/pi_d * lonGrid ! Transform lonGrid to hours (MLT) for Weimer EpotVal function
     ! Translate to correct MLT
     DO k = 2, nzeta
        DO j = 1, npsi
           IF (lonGrid(j,k) <= 12._dp) THEN
              lonGrid(j,k) = lonGrid(j,k) + 12._dp
           ELSE
              lonGrid(j,k) = lonGrid(j,k) - 12._dp
           END IF
        END DO
     END DO

     Weimer_potential_loop1: DO k = 2, nzeta
        DO j = 1, npsi
           IF (ABS(pdyn_l-99.99_dp) < 1E-3_dp) THEN
              PRINT*, 'IP: not calling Weimer model, bad SW data'
              PRINT*, ' '
              EXIT Weimer_potential_loop1 ! Bad SW data, do not call Weimer model
           END IF
           call EpotVal05(latGrid(j,k), lonGrid(j,k), 0.0_dp, PhiIono(j,k))
           PhiIono(j,k) = PhiIono(j,k) * 1.0e3   ! ram needs it in Volts
           ! Add corotation potential - only if RAM takes all E-field info from
           ! the equilibrium code 
           ! PhiIono(j,k) = PhiIono(j,k) - 2._dp*pi_d*0.31_dp*6.4**2 *
           ! 1.E3_dp/(24._dp*36._dp*SQRT(x(nThetaEquator,j,k)**2+y(nThetaEquator,j,k)**2))
        END DO

     END DO Weimer_potential_loop1


  CASE DEFAULT
     STOP 'ionospheric_potential: problem.'

  END SELECT

  ! Azimuthal periodicity
  PhiIono(:,nzetap) = PhiIono(:,2)
  PhiIono(:,1) = PhiIono(:,nzeta)

  IF (iConvE /= 1) RETURN

  CALL GSL_Derivs(rhoVal, zetaVal(2:nzeta), PhiIono(:,2:nzeta), &
                  dPhiIonodRho(:,2:nzeta), dPhiIonodZeta(:,2:nzeta), GSLerr)

  dPhiIonodRho(:,nzetap) = dPhiIonodRho(:,2)
  dPhiIonodRho(:,1) = dPhiIonodRho(:,nzeta)
  dPhiIonodZeta(:,nzetap) = dPhiIonodZeta(:,2)
  dPhiIonodZeta(:,1) = dPhiIonodZeta(:,nzeta)

  DO j = 1, npsi
     dPhiIonodAlpha(j,1:nzetap) = dPhiIonodRho(j,1:nzetap) / f(j)
  END DO
  DO k = 1, nzetap
     dPhiIonodBeta(1:npsi, k) = dPhiIonodZeta(1:npsi,k) / fzet(k)
  END DO

  call Write_Ionospheric_Potential

  RETURN

END SUBROUTINE ionospheric_potential

!============================================================================

END MODULE ModRamEField
