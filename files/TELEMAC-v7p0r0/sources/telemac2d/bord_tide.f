!                    ********************
                     SUBROUTINE BORD_TIDE
!                    ********************
!
     &(ZF,NBOR,LIHBOR,LIUBOR,NPOIN,NPTFR,TEMPS,DT,NCOTE,NVITES,
     & NUMLIQ,KENT,KENTU,NOMIMP,TIDALTYPE,CTIDE,MSL,CTIDEV,NODALCORR,
     & NFOT,BOUNDARY_COLOUR,HBTIDE,UBTIDE,VBTIDE,NUMTIDE,ICALHW,
     & MARDAT,MARTIM,TM2S2N2EQUAL)
!
!***********************************************************************
! TELEMAC2D   V6P3                                   28/10/2010
!***********************************************************************
!
!brief    MODIFIES THE BOUNDARY CONDITIONS ARRAYS FOR TIDES
!+                WHEN THEY VARY IN TIME.
!+
!
!history  C-T PHAM (LNHE)
!+        28/10/2010
!+        V6P1
!+
!history  C-T PHAM (LNHE)
!+        31/10/2012
!+        V6P3
!+   Bug correction when MARTIM not equal to midnight or noon
!+   New calculation of UPVM2 and UPVN2 + new factor UPVS2
!+   in NODALUPV_PUGH subroutine
!
!history  C-T PHAM (LNHE)
!+        08/10/2014
!+        V7P0
!+   Bug correction for option periods of S2 and N2 equal to M2
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| BOUNDARY_COLOUR|-->| AN INTEGER LINKED TO BOUNDARY POINTS
!|                |   | BY DEFAULT THE LAST LINE OF BOUNDARY CONDITIONS 
!|                |   | FILE, HENCE THE GLOBAL BOUNDARY NUMBER, BUT CAN 
!|                |   | BE CHANGED BY USER.
!| CTIDE          |-->| COEFFICIENT TO CALIBRATE THE TIDAL RANGE
!| CTIDEV         |-->| COEFFICIENT TO CALIBRATE THE VELOCITIES
!| DT             |-->| TIME STEP
!| HBTIDE         |<->| WATER DEPTH ON TIDAL BOUNDARY CONDITIONS
!| ICALHW         |<->| NUMBER THAT MAY BE CHOSEN BY THE USER
!|                |   | TO CALIBRATE HIGH WATER OR AUTOMATICALLY CHOSEN
!|                |   | IN CASE OF THE MODELLING OF A SCHEMATIC TIDE
!| KENT           |-->| CONVENTION FOR LIQUID INPUT WITH PRESCRIBED VALUE
!| KENTU          |-->| CONVENTION FOR LIQUID INPUT WITH PRESCRIBED VELOCITY
!| LIHBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON DEPTH
!| LIUBOR         |-->| TYPE OF BOUNDARY CONDITIONS ON VELOCITY
!| MARDAT         |-->| DATE (YEAR,MONTH,DAY)
!| MARTIM         |-->| TIME (HOUR,MINUTE,SECOND)
!| MSL            |-->| COEFFICIENT TO CALIBRATE THE SEA LEVEL
!| NBOR           |-->| GLOBAL NUMBER OF BOUNDARY POINTS
!| NCOTE          |-->| NUMBER OF BOUNDARIES WITH PRESCRIBED ELEVATION
!|                |   | AS GIVEN IN THE PARAMETER FILE
!| NFOT           |-->| LOGICAL UNIT OF HARMONIC CONSTANTS FILE
!| NODALCORR      |-->| OPTION FOR CALCULATION OF NODAL FACTOR CORRECTION F
!| NOMIMP         |-->| NAME OF LIQUID BOUNDARIES FILE
!| NPOIN          |-->| NUMBER OF POINTS
!| NPTFR          |-->| NUMBER OF BOUNDARY POINTS
!| NUMLIQ         |-->| LIQUID BOUNDARY NUMBER OF BOUNDARY POINTS
!| NUMTIDE        |<->| NUMBER OF THE TIDAL BOUNDARY
!|                |   | ASSOCIATED TO EACH POINT OF THE BOUNDARY
!| NVITES         |-->| NUMBER OF BOUNDARIES WITH VELOCITY PRESCRIBED
!|                |   | AS GIVEN IN THE PARAMETER FILE
!| TEMPS          |-->| TIME IN SECONDS
!| TIDALTYPE      |-->| TYPE OF TIDE TO MODEL
!| TM2S2N2EQUAL   |-->| LOGICAL TO IMPOSE THE PERIODS OF S2 AND N2 WAVES
!|                |   | TO BE EQUAL TO THE PERIOD OF M2 WAVE
!| UBTIDE         |<->| VELOCITY ON TIDAL BOUNDARY CONDITIONS
!| VBTIDE         |<->| VELOCITY ON TIDAL BOUNDARY CONDITIONS
!| ZF             |-->| BOTTOM TOPOGRAPHY
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE INTERFACE_TELEMAC2D, EX_BORD_TIDE => BORD_TIDE
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)             :: NPOIN,NPTFR,NCOTE,NVITES,NFOT
      INTEGER, INTENT(IN)             :: KENT,KENTU,NODALCORR
      INTEGER, INTENT(IN)             :: LIHBOR(NPTFR),LIUBOR(NPTFR)
      INTEGER, INTENT(IN)             :: NUMLIQ(NPTFR),NBOR(NPTFR)
      INTEGER, INTENT(IN)             :: TIDALTYPE,MARDAT(3),MARTIM(3)
      INTEGER, INTENT(INOUT)          :: ICALHW
      DOUBLE PRECISION, INTENT(IN)    :: TEMPS,CTIDE,MSL,CTIDEV,DT
      DOUBLE PRECISION, INTENT(IN)    :: ZF(NPOIN)
      LOGICAL, INTENT(IN)             :: TM2S2N2EQUAL
      TYPE(BIEF_OBJ), INTENT(IN)      :: BOUNDARY_COLOUR
      TYPE(BIEF_OBJ), INTENT(INOUT)   :: NUMTIDE,UBTIDE,VBTIDE,HBTIDE
      CHARACTER(LEN=144), INTENT(IN)  :: NOMIMP
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER K,IERR,I
!
!-----------------------------------------------------------------------
!
      INTEGER IPTFR,IPTFRL,NPTFRL,NTIDE
      INTEGER, ALLOCATABLE :: FIRSTTIDE(:),LASTTIDE(:),SHIFTTIDE(:)
!
      DOUBLE PRECISION, PARAMETER :: TM2 = 44714.D0
      DOUBLE PRECISION, PARAMETER :: TM4 = 22357.D0
!
      DOUBLE PRECISION PI,TWOPI
      DOUBLE PRECISION TS2,TN2
      DOUBLE PRECISION HM2,HS2,HN2,HM4
      DOUBLE PRECISION UM2,US2,UN2,UM4,VM2,VS2,VN2,VM4
      DOUBLE PRECISION UPVM2,UPVN2,UPVS2,FFMN2,FFM4
      DOUBLE PRECISION PHM2CALHW,PHS2CALHW,PHN2CALHW,PHM4CALHW
      DOUBLE PRECISION FM2,FS2,FN2,FM4
      DOUBLE PRECISION, ALLOCATABLE :: AHM2(:),PHM2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AHS2(:),PHS2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AHN2(:),PHN2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AHM4(:),PHM4(:)
      DOUBLE PRECISION, ALLOCATABLE :: AUM2(:),PUM2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AUS2(:),PUS2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AUN2(:),PUN2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AUM4(:),PUM4(:)
      DOUBLE PRECISION, ALLOCATABLE :: AVM2(:),PVM2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AVS2(:),PVS2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AVN2(:),PVN2(:)
      DOUBLE PRECISION, ALLOCATABLE :: AVM4(:),PVM4(:)
      DOUBLE PRECISION, ALLOCATABLE :: FHXM2(:),FHYM2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FHXS2(:),FHYS2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FHXN2(:),FHYN2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FHXM4(:),FHYM4(:)
      DOUBLE PRECISION, ALLOCATABLE :: FUXM2(:),FUYM2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FUXS2(:),FUYS2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FUXN2(:),FUYN2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FUXM4(:),FUYM4(:)
      DOUBLE PRECISION, ALLOCATABLE :: FVXM2(:),FVYM2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FVXS2(:),FVYS2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FVXN2(:),FVYN2(:)
      DOUBLE PRECISION, ALLOCATABLE :: FVXM4(:),FVYM4(:)
!
      LOGICAL DEJA
      DATA    DEJA /.FALSE./
!
      SAVE  
!
!-----------------------------------------------------------------------
!
      PI = ATAN(1.D0)*4.D0
      TWOPI = 2.D0*PI
!
!  WAVE PERIODES (SEE p.61 JMJ REPORT)
!  JANIN J.-M., BLANCHARD X. (1992).
!  SIMULATION DES COURANTS DE MAREE EN MANCHE ET PROCHE ATLANTIQUE
!  EDF REPORT HE-42/92.58
!
      IF(TM2S2N2EQUAL.AND.TIDALTYPE.GE.2.AND.TIDALTYPE.LE.6) THEN
        TS2 = TM2
        TN2 = TM2
      ELSE
        TS2 = 43200.D0
        TN2 = 45570.D0
      ENDIF
!
!  TEST TO CHECK CORRECT VALUES FOR TIDALTYPE
!
      IF(.NOT.DEJA) THEN
        IF(TIDALTYPE.LT.0.OR.TIDALTYPE.GT.7) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'MAUVAISE VALEUR POUR TIDALTYPE =',TIDALTYPE
            WRITE(LU,*) 'ELLE DOIT ETRE COMPRISE ENTRE 0 ET 7'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'UNEXPECTED VALUE FOR TIDALTYPE=',TIDALTYPE
            WRITE(LU,*) 'IT MUST BE CHOSEN BETWEEN 0 AND 7'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
!  MAGNITUDES AND PHASES ARE READ IN TIDAL FILE
!  CANAL NFOT = 26 CORRESPONDS TO FORMATTED FILE 1
!  TIDAL FILE IS OBTAINED BY APPLYING BORD_TIDAL_BC SUBROUTINE
!  WHICH INTERPOLATES JMJ MODEL RESULTS ON THE CURRENT MESH
!
!  NTIDE:  NUMBER OF THE TIDAL BOUNDARIES
!  NPTFRL: NUMBERS OF BOUNDARY POINTS WHERE TIDE IS PRESCRIBED
!
      IF(.NOT.DEJA) THEN
!
        REWIND NFOT
!
        NPTFRL = 0
!
        READ(NFOT,*,END=2) NTIDE
        DO K=1,NTIDE
          READ(NFOT,*,END=2)
        ENDDO
!
1       CONTINUE
        READ(NFOT,*,END=2,ERR=3)
        READ(NFOT,*,END=2,ERR=3)
        READ(NFOT,*,END=2,ERR=3)
        READ(NFOT,*,END=2,ERR=3)
        READ(NFOT,*,END=2,ERR=3)
        NPTFRL = NPTFRL + 1
        GOTO 1
3       CONTINUE
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'BORD_TIDE: FICHIER DES CONSTANTES HARMONIQUES'
          WRITE(LU,*) 'ERREUR DE LECTURE AU POINT',NPTFRL+1
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'BORD_TIDE: HARMONIC CONSTANTS FILE'
          WRITE(LU,*) 'READ ERROR AT POINT',NPTFRL+1
        ENDIF
        CALL PLANTE(1)
        STOP      
      ENDIF
!
2     CONTINUE
!
      IF(.NOT.DEJA) THEN
        ALLOCATE(FIRSTTIDE(NTIDE),STAT=IERR)
        ALLOCATE(LASTTIDE(NTIDE), STAT=IERR)
        ALLOCATE(SHIFTTIDE(NTIDE),STAT=IERR)
!
        IF(TIDALTYPE.GE.1.AND.TIDALTYPE.LE.6) THEN
          ALLOCATE(AHM2(NPTFRL),STAT=IERR)
          ALLOCATE(PHM2(NPTFRL),STAT=IERR)
          ALLOCATE(AHS2(NPTFRL),STAT=IERR)
          ALLOCATE(PHS2(NPTFRL),STAT=IERR)
          ALLOCATE(AHN2(NPTFRL),STAT=IERR)
          ALLOCATE(PHN2(NPTFRL),STAT=IERR)
          ALLOCATE(AHM4(NPTFRL),STAT=IERR)
          ALLOCATE(PHM4(NPTFRL),STAT=IERR)
          ALLOCATE(AUM2(NPTFRL),STAT=IERR)
          ALLOCATE(PUM2(NPTFRL),STAT=IERR)
          ALLOCATE(AUS2(NPTFRL),STAT=IERR)
          ALLOCATE(PUS2(NPTFRL),STAT=IERR)
          ALLOCATE(AUN2(NPTFRL),STAT=IERR)
          ALLOCATE(PUN2(NPTFRL),STAT=IERR)
          ALLOCATE(AUM4(NPTFRL),STAT=IERR)
          ALLOCATE(PUM4(NPTFRL),STAT=IERR)
          ALLOCATE(AVM2(NPTFRL),STAT=IERR)
          ALLOCATE(PVM2(NPTFRL),STAT=IERR)
          ALLOCATE(AVS2(NPTFRL),STAT=IERR)
          ALLOCATE(PVS2(NPTFRL),STAT=IERR)
          ALLOCATE(AVN2(NPTFRL),STAT=IERR)
          ALLOCATE(PVN2(NPTFRL),STAT=IERR)
          ALLOCATE(AVM4(NPTFRL),STAT=IERR)
          ALLOCATE(PVM4(NPTFRL),STAT=IERR)
        ELSEIF(TIDALTYPE.EQ.7) THEN
          ALLOCATE(FHXM2(NPTFRL),STAT=IERR)
          ALLOCATE(FHYM2(NPTFRL),STAT=IERR)
          ALLOCATE(FHXS2(NPTFRL),STAT=IERR)
          ALLOCATE(FHYS2(NPTFRL),STAT=IERR)
          ALLOCATE(FHXN2(NPTFRL),STAT=IERR)
          ALLOCATE(FHYN2(NPTFRL),STAT=IERR)
          ALLOCATE(FHXM4(NPTFRL),STAT=IERR)
          ALLOCATE(FHYM4(NPTFRL),STAT=IERR)
          ALLOCATE(FUXM2(NPTFRL),STAT=IERR)
          ALLOCATE(FUYM2(NPTFRL),STAT=IERR)
          ALLOCATE(FUXS2(NPTFRL),STAT=IERR)
          ALLOCATE(FUYS2(NPTFRL),STAT=IERR)
          ALLOCATE(FUXN2(NPTFRL),STAT=IERR)
          ALLOCATE(FUYN2(NPTFRL),STAT=IERR)
          ALLOCATE(FUXM4(NPTFRL),STAT=IERR)
          ALLOCATE(FUYM4(NPTFRL),STAT=IERR)
          ALLOCATE(FVXM2(NPTFRL),STAT=IERR)
          ALLOCATE(FVYM2(NPTFRL),STAT=IERR)
          ALLOCATE(FVXS2(NPTFRL),STAT=IERR)
          ALLOCATE(FVYS2(NPTFRL),STAT=IERR)
          ALLOCATE(FVXN2(NPTFRL),STAT=IERR)
          ALLOCATE(FVYN2(NPTFRL),STAT=IERR)
          ALLOCATE(FVXM4(NPTFRL),STAT=IERR)
          ALLOCATE(FVYM4(NPTFRL),STAT=IERR)
        ENDIF
      ENDIF
!
!  COMPUTE THE FIRST AND LAST INDICES OF THE OPEN LIQUID BOUNDARY WITH TIDE TO PRESCRIBE
!
      IF(.NOT.DEJA) THEN
        REWIND NFOT
!
        READ(NFOT,*)
        DO I=1,NTIDE
          READ(NFOT,*,END=4) FIRSTTIDE(I),LASTTIDE(I)
        ENDDO
4       CONTINUE
!
!  SHIFTS WHEN CHANGING TIDAL BOUNDARY
!
        SHIFTTIDE(1) = 0
!
        DO I=2,NTIDE
          SHIFTTIDE(I) = LASTTIDE(I-1) - FIRSTTIDE(I-1) + 1 
     &                 + SHIFTTIDE(I-1)
        ENDDO
!
!  READING OF TIDAL DATA AT THE FIRST TIME STEP
!
        IF(TIDALTYPE.GE.1.AND.TIDALTYPE.LE.6) THEN
          DO IPTFRL = 1,NPTFRL
            READ(NFOT,*)
            READ(NFOT,*) AHM2(IPTFRL),PHM2(IPTFRL),
     &                   AUM2(IPTFRL),PUM2(IPTFRL),
     &                   AVM2(IPTFRL),PVM2(IPTFRL)
            READ(NFOT,*) AHS2(IPTFRL),PHS2(IPTFRL),
     &                   AUS2(IPTFRL),PUS2(IPTFRL),
     &                   AVS2(IPTFRL),PVS2(IPTFRL)
            READ(NFOT,*) AHN2(IPTFRL),PHN2(IPTFRL),
     &                   AUN2(IPTFRL),PUN2(IPTFRL),
     &                   AVN2(IPTFRL),PVN2(IPTFRL)
            READ(NFOT,*) AHM4(IPTFRL),PHM4(IPTFRL),
     &                   AUM4(IPTFRL),PUM4(IPTFRL),
     &                   AVM4(IPTFRL),PVM4(IPTFRL)
          ENDDO
        ELSEIF(TIDALTYPE.EQ.7) THEN
          DO IPTFRL = 1,NPTFRL
            READ(NFOT,*)
            READ(NFOT,*) FHXM2(IPTFRL),FHYM2(IPTFRL),
     &                   FUXM2(IPTFRL),FUYM2(IPTFRL),
     &                   FVXM2(IPTFRL),FVYM2(IPTFRL)
            READ(NFOT,*) FHXS2(IPTFRL),FHYS2(IPTFRL),
     &                   FUXS2(IPTFRL),FUYS2(IPTFRL),
     &                   FVXS2(IPTFRL),FVYS2(IPTFRL)
            READ(NFOT,*) FHXN2(IPTFRL),FHYN2(IPTFRL),
     &                   FUXN2(IPTFRL),FUYN2(IPTFRL),
     &                   FVXN2(IPTFRL),FVYN2(IPTFRL)
            READ(NFOT,*) FHXM4(IPTFRL),FHYM4(IPTFRL),
     &                   FUXM4(IPTFRL),FUYM4(IPTFRL),
     &                   FVXM4(IPTFRL),FVYM4(IPTFRL)
          ENDDO
        ENDIF
!
!       POTENTIAL SPECIFIC TREATMENTS
!
        IF(TIDALTYPE.EQ.1) THEN
!
!         DEGREES TO RADIANS CONVERSIONS
          DO IPTFRL = 1,NPTFRL
            PHM2(IPTFRL) = PHM2(IPTFRL) / 180.D0 * PI
            PUM2(IPTFRL) = PUM2(IPTFRL) / 180.D0 * PI
            PVM2(IPTFRL) = PVM2(IPTFRL) / 180.D0 * PI
!
            PHS2(IPTFRL) = PHS2(IPTFRL) / 180.D0 * PI
            PUS2(IPTFRL) = PUS2(IPTFRL) / 180.D0 * PI
            PVS2(IPTFRL) = PVS2(IPTFRL) / 180.D0 * PI
!
            PHN2(IPTFRL) = PHN2(IPTFRL) / 180.D0 * PI
            PUN2(IPTFRL) = PUN2(IPTFRL) / 180.D0 * PI
            PVN2(IPTFRL) = PVN2(IPTFRL) / 180.D0 * PI
!
            PHM4(IPTFRL) = PHM4(IPTFRL) / 180.D0 * PI
            PUM4(IPTFRL) = PUM4(IPTFRL) / 180.D0 * PI
            PVM4(IPTFRL) = PVM4(IPTFRL) / 180.D0 * PI
          ENDDO
!
        ELSEIF(TIDALTYPE.GE.2.AND.TIDALTYPE.LE.6) THEN
!
!         ARBITRARY CHOICE
          IF(ICALHW.EQ.0) ICALHW = NPTFRL/2
!
!  CALIBRATION WITH RESPECT TO HIGH WATER!!!
!  PHASES FOR HEIGHTS ARE READ IN JMJ TIDAL FILE
!  EXCEPT M4: 2*PHM2 MOD 360 IS APPLIED
! --------------------------------------------------
!
          PHM2CALHW = PHM2(ICALHW)
          PHS2CALHW = PHS2(ICALHW)
          PHN2CALHW = PHN2(ICALHW)
          PHM4CALHW = MOD(2.D0*PHM2(ICALHW),360.D0)
!
          DO IPTFRL = 1,NPTFRL
            PHM2(IPTFRL) = (PHM2(IPTFRL) - PHM2CALHW) / 180.D0 * PI
            PUM2(IPTFRL) = (PUM2(IPTFRL) - PHM2CALHW) / 180.D0 * PI
            PVM2(IPTFRL) = (PVM2(IPTFRL) - PHM2CALHW) / 180.D0 * PI
!
            PHS2(IPTFRL) = (PHS2(IPTFRL) - PHS2CALHW) / 180.D0 * PI
            PUS2(IPTFRL) = (PUS2(IPTFRL) - PHS2CALHW) / 180.D0 * PI
            PVS2(IPTFRL) = (PVS2(IPTFRL) - PHS2CALHW) / 180.D0 * PI
!
            PHN2(IPTFRL) = (PHN2(IPTFRL) - PHN2CALHW) / 180.D0 * PI
            PUN2(IPTFRL) = (PUN2(IPTFRL) - PHN2CALHW) / 180.D0 * PI
            PVN2(IPTFRL) = (PVN2(IPTFRL) - PHN2CALHW) / 180.D0 * PI
!
            PHM4(IPTFRL) = (PHM4(IPTFRL) - PHM4CALHW) / 180.D0 * PI
            PUM4(IPTFRL) = (PUM4(IPTFRL) - PHM4CALHW) / 180.D0 * PI
            PVM4(IPTFRL) = (PVM4(IPTFRL) - PHM4CALHW) / 180.D0 * PI
          ENDDO
        ENDIF
!
!  NUMBER OF THE TIDAL BOUNDARY ASSOCIATED TO EACH POINT OF THE BOUNDARY
!  REMAINS 0 IF POINT IS NOT ON AN OPEN BOUNDARY WITH TIDE
!
        DO K=1,NPTFR
          NUMTIDE%I(K) = 0
          IPTFR=BOUNDARY_COLOUR%I(K)
          DO I=1,NTIDE
            IF(IPTFR.GE.FIRSTTIDE(I).AND.IPTFR.LE.LASTTIDE(I)) THEN
              NUMTIDE%I(K) = I
            ENDIF
          ENDDO
        ENDDO
!
!  FOR THE SIMULATION OF REAL TIDES, NODAL FACTOR CORRECTIONS ARE COMPUTED WITH PUGH FORMULAE
!  PUGH D. (1987). TIDES, SURGES AND MEAN SEA LEVEL.
!
        IF(TIDALTYPE.EQ.1.OR.TIDALTYPE.EQ.7) THEN
          CALL NODALUPV_PUGH(UPVM2,UPVN2,UPVS2,MARDAT,MARTIM)
!  TEMPS-DT RATHER THAN TEMPS BECAUSE THE FIRST CALL TO BORD_TIDE
!  IS AT THE FIRST TIME STEP
          CALL NODALF_PUGH(FFMN2,FFM4,NODALCORR,TEMPS-DT,DEJA,
     &                     MARDAT,MARTIM)
        ENDIF
!
        DEJA = .TRUE.
!
      ENDIF
!
      IF((TIDALTYPE.EQ.1.OR.TIDALTYPE.EQ.7).AND.NODALCORR.EQ.0) THEN
        CALL NODALF_PUGH(FFMN2,FFM4,NODALCORR,TEMPS,DEJA,MARDAT,MARTIM)
      ENDIF
!
      IF(TIDALTYPE.EQ.7) THEN
!       PHASES COMPUTATION
        FM2=DMOD( UPVM2  + TWOPI/TM2*TEMPS, TWOPI)
        FN2=DMOD( UPVN2  + TWOPI/TN2*TEMPS, TWOPI)
        FS2=DMOD( UPVS2  + TWOPI/TS2*TEMPS, TWOPI)
        FM4=DMOD(2.D0*FM2                 , TWOPI)
      ENDIF
!
!  LOOP ON ALL BOUNDARY POINTS
!
      DO K=1,NPTFR
!
        IPTFR=BOUNDARY_COLOUR%I(K)
!
!     LEVEL IMPOSED WITH VALUE GIVEN IN THE CAS FILE (NCOTE0)
!
        IF(LIHBOR(K).EQ.KENT) THEN
!         BEGINNING OF PRESCRIBED DEPTHS
          IF(NUMTIDE%I(K).GT.0) THEN
            IPTFRL=IPTFR-FIRSTTIDE(NUMTIDE%I(K))+1
     &                  +SHIFTTIDE(NUMTIDE%I(K))
!
!  TYPE OF TIDE TO MODEL
!  1: REAL TIDE (RECOMMENDED METHODOLOGY)
!  2: ASTRONOMICAL TIDE      (COEF. NEARLY 120)
!  3: MEAN SPRING TIDE       (COEF. NEARLY 95)
!  4: MEAN TIDE              (COEF. NEARLY 70)
!  5: MEAN NEAP TIDE         (COEF. NEARLY 45)
!  6: ASTRONOMICAL NEAP TIDE (COEF. NEARLY 20)
!  7: REAL TIDE (METHODOLOGY BEFORE 2010)
!
            IF(TIDALTYPE.EQ.1) THEN
              HM2 = FFMN2*AHM2(IPTFRL)
     &                   *COS(TWOPI*TEMPS/TM2-PHM2(IPTFRL)+UPVM2)
            ELSEIF(TIDALTYPE.GE.2.AND.TIDALTYPE.LE.6) THEN
              HM2 = AHM2(IPTFRL)*COS(TWOPI*TEMPS/TM2-PHM2(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.7) THEN
              HM2 = FFMN2*(FHXM2(IPTFRL)*COS(FM2)
     &                    +FHYM2(IPTFRL)*SIN(FM2))
            ENDIF
!
!  S2 WAVE is not ACCOUNTED FOR MEAN TIDES
!
            IF(TIDALTYPE.EQ.1) THEN
              HS2 = AHS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PHS2(IPTFRL)+UPVS2)
            ELSEIF(TIDALTYPE.EQ.2.OR.TIDALTYPE.EQ.3) THEN
              HS2 = AHS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PHS2(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.5.OR.TIDALTYPE.EQ.6) THEN
              HS2 = AHS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PHS2(IPTFRL)-PI)
            ELSEIF(TIDALTYPE.EQ.7) THEN
              HS2 = FHXS2(IPTFRL)*COS(FS2) + FHYS2(IPTFRL)*SIN(FS2)
            ENDIF
!
!  N2 WAVE is not ACCOUNTED FOR MEAN SPRING, MEAN AND MEAN NEAP TIDES
!
            IF(TIDALTYPE.EQ.1) THEN
              HN2 = FFMN2*AHN2(IPTFRL)
     &                   *COS(TWOPI*TEMPS/TN2-PHN2(IPTFRL)+UPVN2)
            ELSEIF(TIDALTYPE.EQ.2) THEN
              HN2 = AHN2(IPTFRL)*COS(TWOPI*TEMPS/TN2-PHN2(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.6) THEN
              HN2 = AHN2(IPTFRL)*COS(TWOPI*TEMPS/TN2-PHN2(IPTFRL)-PI)
            ELSEIF(TIDALTYPE.EQ.7) THEN
              HN2 = FFMN2*(FHXN2(IPTFRL)*COS(FN2)
     &                    +FHYN2(IPTFRL)*SIN(FN2)) 
            ENDIF
!
            IF(TIDALTYPE.EQ.1) THEN
              HM4 = FFM4*AHM4(IPTFRL)
     &                  *COS(TWOPI*TEMPS/TM4-PHM4(IPTFRL)+2.D0*UPVM2)
            ELSEIF(TIDALTYPE.GE.2.AND.TIDALTYPE.LE.6) THEN
              HM4 = AHM4(IPTFRL)*COS(TWOPI*TEMPS/TM4-PHM4(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.7) THEN
              HM4 = FFM4*(FHXM4(IPTFRL)*COS(FM4)
     &                   +FHYM4(IPTFRL)*SIN(FM4))
            ENDIF
!
            IF(TIDALTYPE.EQ.1.OR.TIDALTYPE.EQ.7) THEN
!              HBTIDE%R(K) = -ZF(NBOR(K)) + HM2+HS2+HN2+HM4 + MSL
              HBTIDE%R(K) = -ZF(NBOR(K)) + CTIDE*(HM2+HS2+HN2+HM4) + MSL
            ELSEIF(TIDALTYPE.EQ.2.OR.TIDALTYPE.EQ.6) THEN
              HBTIDE%R(K) = -ZF(NBOR(K)) + CTIDE*(HM2+HS2+HN2+HM4) + MSL
            ELSEIF(TIDALTYPE.EQ.3.OR.TIDALTYPE.EQ.5) THEN
              HBTIDE%R(K) = -ZF(NBOR(K)) + CTIDE*(HM2+HS2+HM4) + MSL
            ELSEIF(TIDALTYPE.EQ.4) THEN
              HBTIDE%R(K) = -ZF(NBOR(K)) + CTIDE*(HM2+HM4) + MSL
            ENDIF
!
          ENDIF
!         ELSE HBOR TAKEN IN BOUNDARY CONDITIONS FILE
        ENDIF
!
!  VELOCITY IMPOSED: ONE USES THE OUTGOING DIRECTION
!                    PROVIDED BY THE USER.
!
      IF(LIUBOR(K).EQ.KENTU) THEN
!
!       POINTS ON WEIRS HAVE NUMLIQ(K)=0
        IF(NUMLIQ(K).GT.0) THEN
!
!         BEGINNING OF PRESCRIBED VELOCITIES
!
          IF(NUMTIDE%I(K).GT.0) THEN
            IPTFRL=IPTFR-FIRSTTIDE(NUMTIDE%I(K))+1
     &                  +SHIFTTIDE(NUMTIDE%I(K))
!
!  TYPE OF TIDE TO MODEL
!  1: REAL TIDE (RECOMMENDED METHODOLOGY)
!  2: ASTRONOMICAL TIDE      (COEF. NEARLY 120)
!  3: MEAN SPRING TIDE       (COEF. NEARLY 95)
!  4: MEAN TIDE              (COEF. NEARLY 70)
!  5: MEAN NEAP TIDE         (COEF. NEARLY 45)
!  6: ASTRONOMICAL NEAP TIDE (COEF. NEARLY 20)
!  7: REAL TIDE (METHODOLOGY BEFORE 2010)
!
            IF(TIDALTYPE.EQ.1) THEN
              UM2 = FFMN2*AUM2(IPTFRL)
     &                   *COS(TWOPI*TEMPS/TM2-PUM2(IPTFRL)+UPVM2)
              VM2 = FFMN2*AVM2(IPTFRL)
     &                   *COS(TWOPI*TEMPS/TM2-PVM2(IPTFRL)+UPVM2)
            ELSEIF(TIDALTYPE.GE.2.AND.TIDALTYPE.LE.6) THEN
              UM2 = AUM2(IPTFRL)*COS(TWOPI*TEMPS/TM2-PUM2(IPTFRL))
              VM2 = AVM2(IPTFRL)*COS(TWOPI*TEMPS/TM2-PVM2(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.7) THEN
              UM2 = FUXM2(IPTFRL)*COS(FM2) + FUYM2(IPTFRL)*SIN(FM2)
              VM2 = FVXM2(IPTFRL)*COS(FM2) + FVYM2(IPTFRL)*SIN(FM2)
            ENDIF
!
!  S2 WAVE is not ACCOUNTED FOR MEAN TIDES
!
            IF(TIDALTYPE.EQ.1) THEN
              US2 = AUS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PUS2(IPTFRL)+UPVS2)
              VS2 = AVS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PVS2(IPTFRL)+UPVS2)
            ELSEIF(TIDALTYPE.EQ.2.OR.TIDALTYPE.EQ.3) THEN
              US2 = AUS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PUS2(IPTFRL))
              VS2 = AVS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PVS2(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.5.OR.TIDALTYPE.EQ.6) THEN
              US2 = AUS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PUS2(IPTFRL)-PI)
              VS2 = AVS2(IPTFRL)*COS(TWOPI*TEMPS/TS2-PVS2(IPTFRL)-PI)
            ELSEIF(TIDALTYPE.EQ.7) THEN
              US2 = FUXS2(IPTFRL)*COS(FS2) + FUYS2(IPTFRL)*SIN(FS2)
              VS2 = FVXS2(IPTFRL)*COS(FS2) + FVYS2(IPTFRL)*SIN(FS2)
            ENDIF
!
!  N2 WAVE is not ACCOUNTED FOR MEAN SPRING, MEAN AND MEAN NEAP TIDES
!
            IF(TIDALTYPE.EQ.1) THEN
              UN2 = FFMN2*AUN2(IPTFRL)
     &                   *COS(TWOPI*TEMPS/TN2-PUN2(IPTFRL)+UPVN2)
              VN2 = FFMN2*AVN2(IPTFRL)
     &                   *COS(TWOPI*TEMPS/TN2-PVN2(IPTFRL)+UPVN2)
            ELSEIF(TIDALTYPE.EQ.2) THEN
              UN2 = AUN2(IPTFRL)*COS(TWOPI*TEMPS/TN2-PUN2(IPTFRL))
              VN2 = AVN2(IPTFRL)*COS(TWOPI*TEMPS/TN2-PVN2(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.6) THEN
              UN2 = AUN2(IPTFRL)*COS(TWOPI*TEMPS/TN2-PUN2(IPTFRL)-PI)
              VN2 = AVN2(IPTFRL)*COS(TWOPI*TEMPS/TN2-PVN2(IPTFRL)-PI)
            ELSEIF(TIDALTYPE.EQ.7) THEN
              UN2 = FUXN2(IPTFRL)*COS(FN2) + FUYN2(IPTFRL)*SIN(FN2)
              VN2 = FVXN2(IPTFRL)*COS(FN2) + FVYN2(IPTFRL)*SIN(FN2)
            ENDIF
!
            IF(TIDALTYPE.EQ.1) THEN
              UM4 = FFM4*AUM4(IPTFRL)
     &                  *COS(TWOPI*TEMPS/TM4-PUM4(IPTFRL)+2.D0*UPVM2)
              VM4 = FFM4*AVM4(IPTFRL)
     &                  *COS(TWOPI*TEMPS/TM4-PVM4(IPTFRL)+2.D0*UPVM2)
            ELSEIF(TIDALTYPE.GE.2.AND.TIDALTYPE.LE.6) THEN
              UM4 = AUM4(IPTFRL)*COS(TWOPI*TEMPS/TM4-PUM4(IPTFRL))
              VM4 = AVM4(IPTFRL)*COS(TWOPI*TEMPS/TM4-PVM4(IPTFRL))
            ELSEIF(TIDALTYPE.EQ.7) THEN
              UM4 = FUXM4(IPTFRL)*COS(FM4) + FUYM4(IPTFRL)*SIN(FM4)
              VM4 = FVXM4(IPTFRL)*COS(FM4) + FVYM4(IPTFRL)*SIN(FM4)
            ENDIF
!
!  ACCORDING TO DV, IF A CORRECTION COEFFICIENT IS APPLIED FOR WATER DEPTHS,
!  ANOTHER MUST BE APPLIED FOR VELOCITIES
!
            IF(TIDALTYPE.EQ.1.OR.TIDALTYPE.EQ.7) THEN
!              UBTIDE%R(K) = UM2+US2+UN2+UM4
!              VBTIDE%R(K) = VM2+VS2+VN2+VM4
              UBTIDE%R(K) = CTIDEV*(UM2+US2+UN2+UM4)
              VBTIDE%R(K) = CTIDEV*(VM2+VS2+VN2+VM4)
            ELSEIF(TIDALTYPE.EQ.2.OR.TIDALTYPE.EQ.6) THEN
              UBTIDE%R(K) = CTIDEV*(UM2+US2+UN2+UM4)
              VBTIDE%R(K) = CTIDEV*(VM2+VS2+VN2+VM4)
            ELSEIF(TIDALTYPE.EQ.3.OR.TIDALTYPE.EQ.5) THEN
              UBTIDE%R(K) = CTIDEV*(UM2+US2+UM4)
              VBTIDE%R(K) = CTIDEV*(VM2+VS2+VM4)
            ELSEIF(TIDALTYPE.EQ.4) THEN
              UBTIDE%R(K) = CTIDEV*(UM2+UM4)
              VBTIDE%R(K) = CTIDEV*(VM2+VM4)
            ENDIF
!
          ENDIF
        ENDIF
      ENDIF
!
      ENDDO
!
!-----------------------------------------------------------------------
!
      RETURN
      END
