!                    *****************
                     SUBROUTINE PROSOU
!                    *****************
!
     &(FU,FV,SMH,    UN,VN,HN,GRAV,NORD,
     & FAIR,WINDX,WINDY,VENT,HWIND,CORIOL,FCOR,
     & SPHERI,YASMH,COSLAT,SINLAT,AT,LT,DT,
     & NREJET,NREJEU,DSCE,ISCE,T1,MESH,MSK,MASKEL,
     & MAREE,MARDAT,MARTIM,PHI0,OPTSOU,
     & COUROU,NPTH,VARCL,NVARCL,VARCLA,UNSV2D,
     & FXWAVE,FYWAVE,RAIN,RAIN_MMPD,PLUIE,
     & T2D_FILES,T2DBI1,BANDEC,OPTBAN,
     & NSIPH,ENTSIP,SORSIP,DSIP,USIP,VSIP,
     & NBUSE,ENTBUS,SORBUS,DBUS,UBUS,VBUS,
     & TYPSEUIL,NWEIRS,NPSING,NDGA1,NDGB1,NBOR)
!
!***********************************************************************
! TELEMAC2D   V7P0                                
!***********************************************************************
!
!brief    PREPARES THE SOURCE TERMS IN THE CONTINUITY EQUATION
!+                AND IN THE DYNAMIC EQUATIONS. ARE TAKEN INTO ACCOUNT :
!+
!+              - WIND
!+
!+              - CORIOLIS FORCE
!+
!+              - TIDAL FORCE
!+
!+              - SOURCES AND SINKS
!+
!+              - WEIRS (IF TYPSEUIL=2)
!code
!+    RESPECTIVE TERMS ARE:
!+    ==========================
!+
!+     * WIND
!+       ---------
!+                                 1                         2      2
!+                FU           =  --- * F    * U    * SQRT( U    + V   )
!+                  VENT           H     AIR    AIR          AIR    AIR
!+
!+                                 1                         2      2
!+                FV           =  --- * F    * V    * SQRT( U    + V   )
!+                  VENT           H     AIR    AIR          AIR    AIR
!+
!+           WHERE :
!+                  UAIR   :  WIND VELOCITY ALONG X
!+                  VAIR   :  WIND VELOCITY ALONG Y
!+                  FAIR   :  AIR FRICTION COEFFICIENT
!+
!+     * CORIOLIS FORCE
!+       ---------------------
!+
!+                FU           =  + FCOR * V
!+                  CORIOLIS
!+
!+                FV           =  - FCOR * U
!+                  CORIOLIS
!+
!+           WHERE :
!+                  U       :  FLOW VELOCITY ALONG X
!+                  V       :  FLOW VELOCITY ALONG Y
!+                  FCOR    :  CORIOLIS PARAMETER
!
!note     BOTTOM FRICTION IS TAKEN INTO ACCOUNT IN THE PROPAGATION
!+         THROUGH CALL TO FROTXY, IT IS SEMI-IMPLICIT.
!note  IF SOURCES OR SINKS TERMS ARE ADDED TO THE CONTINUITY EQUATION,
!+         IT IS IDENTIFIED WITH VARIABLE YASMH (SET TO TRUE).
!note  SOURCE TERMS FU AND FV ARE FIRST COMPUTED IN P1.
!+         THEY ARE THEN EXTENDED TO QUASI-BUBBLE IF REQUIRED.
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        13/07/2010
!+        V6P0
!+   Translation of French comments within the FORTRAN sources into
!+   English comments
!
!history  N.DURAND (HRW), S.E.BOURBAN (HRW)
!+        21/08/2010
!+        V6P0
!+   Creation of DOXYGEN tags for automated documentation and
!+   cross-referencing of the FORTRAN sources
!
!history  J-M HERVOUET (LNHE)
!+        20/02/2012
!+        V6P2
!+   Rain-evaporation added (after initial code provided by O. Boutron, 
!+   Tour du Valat and O. Bertrand, Artelia-group).
!
!history  C.COULET (ARTELIA)
!+        23/05/2012
!+        V6P2
!+   Modification for culvert management
!+   Addition of Tubes management
!
!history  R. KOPMANN (EDF R&D, LNHE)
!+        16/04/2013
!+        V6P3
!+   Adding the file format in calls to FIND_IN_SEL.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        21/05/2013
!+        V6P3
!+   Possibility of negative depths taken into account when limiting
!+   evaporation on dry zones.
!
!history  C.COULET / A.REBAI / E.DAVID (ARTELIA)
!+        07/06/2013
!+        V6P3
!+   Modification for new treatment of weirs
!
!history  D WANG & P TASSI (LNHE)
!+        10/07/2014
!+        V7P0
!+   Secondary flow correction: compute the secondary
!+   stress term \tau_s and secondary source terms S_x, S_y.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| AT             |-->| TIME
!| BANDEC         |-->| IF YES, TIDAL FLATS OR DRY ZONES
!| CORIOL         |-->| IF YES, CORIOLIS FORCE
!| COSLAT         |-->| COSINUS OF LATITUDE (SPHERICAL COORDINATES)
!| COUROU         |-->| IF YES, WAVE DRIVEN CURRENTS TAKEN INTO ACCOUNT
!| DSIP           |-->| DISCHARGE OF TUBES
!| DSCE           |-->| DISCHARGE OF POINT SOURCES
!| DSIP           |-->| DISCHARGE OF CULVERTS
!| DT             |-->| TIME STEP IN SECONDS
!| ENTBUS         |-->| INDICES OF ENTRY OF TUBES IN GLOBAL NUMBERING
!| ENTSIP         |-->| INDICES OF ENTRY OF CULVERTS IN GLOBAL NUMBERING
!| FAIR           |-->| FRICTION COEFFICIENT FOR WIND
!| FCOR           |-->| CORIOLIS PARAMETER
!| FU             |<->| SOURCE TERMS ON VELOCITY U
!| FV             |<->| SOURCE TERMS ON VELOCITY V
!| FXWAVE         |<->| FORCING OF WAVES ALONG X
!| FYWAVE         |<->| FORCING OF WAVES ALONG Y
!| GRAV           |-->| GRAVITY
!| HN             |-->| DEPTH AT TIME T(N)
!| HWIND          |-->| MINIMUM DEPTH FOR TAKING WIND INTO ACCOUNT
!| ISCE           |-->| NEAREST POINTS TO SOURCES
!| LT             |-->| TIME STEP NUMBER
!| MARDAT         |-->| DATE (YEAR, MONTH,DAY)
!| MAREE          |-->| IF YES, TAKES THE TIDAL FORCE INTO ACCOUNT
!| MARTIM         |-->| TIME (HOUR, MINUTE,SECOND)
!| MASKEL         |-->| MASKING OF ELEMENTS
!|                |   | =1. : NORMAL   =0. : MASKED ELEMENT
!| MESH           |-->| MESH STRUCTURE
!| MSK            |-->| IF YES, THERE IS MASKED ELEMENTS.
!| NBOR           |-->| INDICES OF BOUNDARY POINTS
!| NBUSE          |-->| NUMBER OF TUBES
!| NORD           |-->| DIRECTION OF NORTH WITH RESPECT TO Y AXIS
!|                |   | (TRIGONOMETRIC SENSE) IN DEGREES.
!| NPSING         |-->| NUMBER OF POINTS OF WEIRS
!| NPTH           |-->| RECORD NUMBER IN THE WAVE CURRENTS FILE
!| NREJET         |-->| NUMBER OF POINT SOURCES
!| NREJEU         |-->| NUMBER OF POINT SOURCES WITH GIVEN VELOCITY
!|                |   | IF NREJEU=0 VELOCITY OF SOURCES IS TAKEN EQUAL
!|                |   | TO VELOCITY.
!| NSIPH          |-->| NUMBER OF CULVERTS
!| NDGA1,NDGB1    |-->| INDICES OF POINTS OF WEIRS
!| NVARCL         |-->| NUMBER OF CLANDESTINE VARIABLES
!| NWEIRS         |-->| NUMBER OF WEIRS
!| OPTBAN         |-->| OPTION FOR THE TREATMENT OF TIDAL FLATS
!| OPTSOU         |-->| OPTION FOR THE TREATMENT OF SOURCES
!| PHI0           |-->| LATITUDE OF ORIGIN POINT
!| PLUIE          |-->| BIEF_OBJ STRUCTURE WITH RAIN OR EVAPORATION.
!| RAIN           |-->| IF YES, RAIN OR EVAPORATION TAKEN INTO ACCOUNT
!| RAIN_MMPD      |-->| RAIN OR EVAPORATION IN MM PER DAY
!| SINLAT         |-->| SINUS OF LATITUDE (SPHERICAL COORDINATES)
!| SMH            |-->| SOURCE TERM IN CONTINUITY EQUATION
!| SORBUS         |-->| INDICES OF TUBES EXITS IN GLOBAL NUMBERING
!| SORSIP         |-->| INDICES OF CULVERTS EXISTS IN GLOBAL NUMBERING
!| SPHERI         |-->| IF TRUE : SPHERICAL COORDINATES
!| T1             |<->| WORK BIEF_OBJ STRUCTURE
!| T2D_FILES      |-->| BIEF_FILE STRUCTURE WITH ALL TELEMAC-2D FILES
!| T2D_BI1        |-->| RANK OF BINARY FILE 1
!| TYPSEUIL       |-->| TYPE OS WEIRS (ONLY TYPSEUIL=2 IS MANAGE HERE)
!| UBUS           |-->| VELOCITY U AT TUBE EXTREMITY
!| UNSV2D         |-->| INVERSE OF INTEGRALS OF TEST FUNCTIONS
!| USIP           |-->| VELOCITY U AT CULVERT EXTREMITY
!| VBUS           |-->| VELOCITY V AT TUBE EXTREMITY
!| VARCL          |<->| BLOCK OF CLANDESTINE VARIABLES
!| VARCLA         |-->| NAMES OF CLANDESTINE VARIABLES
!| VENT           |-->| IF YES, WIND IS TAKEN INTO ACCOUNT
!| VSIP           |-->| VELOCITY V AT CULVERT EXTREMITY
!| WINDX          |-->| FIRST COMPONENT OF WIND VELOCITY
!| WINDY          |-->| SECOND COMPONENT OF WIND VELOCITY
!| YASMH          |<->| IF TRUE SMH IS TAKEN INTO ACCOUNT
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC
!     FOR SEEING OTHER VARIABLES IN DECLARATIONS_TELEMAC2D:
      USE DECLARATIONS_TELEMAC2D, ONLY : QWA,QWB,U,V,H,
     &                                   SECCURRENTS,NTRAC,SEC_R,
     &                                   SEC_TAU,T2,T3,T7,
     &                                   ROEAU,CF,S,IELMU,T
      USE INTERFACE_TELEMAC2D, EX_PROSOU => PROSOU
      USE M_COUPLING_ESTEL3D
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
!     WORKING ARRAYS
!
      TYPE(BIEF_OBJ)   , INTENT(INOUT) :: T1
!
!-----------------------------------------------------------------------
!
!     VECTORS
!
      TYPE(BIEF_OBJ)   , INTENT(INOUT) :: FU,FV,SMH,FXWAVE,FYWAVE
      TYPE(BIEF_OBJ)   , INTENT(IN)    :: MASKEL,UN,VN,HN,UNSV2D
      TYPE(BIEF_OBJ)   , INTENT(IN)    :: WINDX,WINDY,COSLAT,SINLAT
!
!-----------------------------------------------------------------------
!
!     MESH STRUCTURE
!
      TYPE(BIEF_MESH)  , INTENT(INOUT) :: MESH
!
!-----------------------------------------------------------------------
!
      INTEGER          , INTENT(IN)    :: NVARCL,LT,NREJET,NREJEU,OPTSOU
      INTEGER          , INTENT(IN)    :: NPTH,T2DBI1,OPTBAN
      INTEGER          , INTENT(IN)    :: MARDAT(3),MARTIM(3)
      INTEGER          , INTENT(IN)    :: ISCE(NREJET)
      DOUBLE PRECISION , INTENT(IN)    :: HWIND,AT,FAIR,FCOR
      DOUBLE PRECISION , INTENT(IN)    :: DSCE(NREJET)
      DOUBLE PRECISION , INTENT(IN)    :: GRAV,NORD,PHI0,RAIN_MMPD,DT
      CHARACTER(LEN=32), INTENT(IN)    :: VARCLA(NVARCL)
      LOGICAL          , INTENT(IN)    :: VENT,MAREE,CORIOL,SPHERI,MSK
      LOGICAL          , INTENT(IN)    :: COUROU,RAIN,BANDEC
      LOGICAL          , INTENT(INOUT) :: YASMH
      TYPE(BIEF_OBJ)   , INTENT(INOUT) :: VARCL,PLUIE
      TYPE(BIEF_FILE)  , INTENT(IN)    :: T2D_FILES(*)
!
      INTEGER          , INTENT(IN)    :: NSIPH
      INTEGER          , INTENT(IN)    :: ENTSIP(NSIPH),SORSIP(NSIPH)
      DOUBLE PRECISION , INTENT(IN)    :: DSIP(NSIPH)
      DOUBLE PRECISION , INTENT(IN)    :: USIP(NSIPH,2),VSIP(NSIPH,2)
!
      INTEGER          , INTENT(IN)    :: NBUSE
      INTEGER          , INTENT(IN)    :: ENTBUS(NBUSE),SORBUS(NBUSE)
      DOUBLE PRECISION , INTENT(IN)    :: DBUS(NBUSE)
      DOUBLE PRECISION , INTENT(IN)    :: UBUS(NBUSE,2),VBUS(NBUSE,2)
!
      INTEGER          , INTENT(IN)    :: TYPSEUIL,NWEIRS
      TYPE(BIEF_OBJ)   , INTENT(IN)    :: NBOR,NPSING,NDGA1,NDGB1
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER N,I,IELMH,IELM1,NPOIN,IR,ERR,NP,K
!
      DOUBLE PRECISION PI,WROT,WD,ATH,RAIN_MPS,SURDT,XX
!
      CHARACTER(LEN=16) NOMX,NOMY
      LOGICAL DEJALU,OKX,OKY,OKC
      DATA DEJALU /.FALSE./
      REAL, ALLOCATABLE :: W(:)
      SAVE W
!
      INTRINSIC SQRT,MAX,ACOS
!
!-----------------------------------------------------------------------
!  EXTRACTS X COORDINATES, NUMBER OF POINTS P1
!                          AND P1 ELEMENT OF THE MESH
!-----------------------------------------------------------------------
!
      IELM1 = MESH%X%ELM
      NPOIN = MESH%NPOIN
!
!-----------------------------------------------------------------------
!  INITIALISES
!-----------------------------------------------------------------------
!
      CALL CPSTVC(UN,FU)
      CALL CPSTVC(VN,FV)
      CALL OS( 'X=0     ' , X=FU )
      CALL OS( 'X=0     ' , X=FV )
!
!=======================================================================
!
!  SECONDARY CURRENTS
!  
      IF(SECCURRENTS) THEN
!
!       TAU_SEC
        DO K=1,NPOIN
          XX=H%R(K)*T%ADR(NTRAC)%P%R(K)
     &                        *SQRT(0.5D0*CF%R(K)*(U%R(K)**2+V%R(K)**2))
!         SEC_TAU IS USED ONLY FOR OUTPUTS
          SEC_TAU%R(K)=ROEAU*XX
!         ROEAU NOT CONSIDERED IN TAU_SEC, IT AVOIDS A DIVISION LATER
          T1%R(K) = XX*H%R(K)
        ENDDO
!       COMPUTING THE GRADIENTS OF H*TAU_SEC
!       WITH FACTOR V2DPAR=1/UNSV2D, REMOVED LATER
        CALL VECTOR(T2,'=','GRADF          X',IELMU,
     &              1.D0,T1,S,S,S,S,S,MESH,MSK,MASKEL)
        CALL VECTOR(T3,'=','GRADF          Y',IELMU,
     &              1.D0,T1,S,S,S,S,S,MESH,MSK,MASKEL)
        IF(NCSIZE.GT.1) THEN
          CALL PARCOM (T2, 2, MESH)
          CALL PARCOM (T3, 2, MESH)
        ENDIF
!
        DO K=1,NPOIN
          IF(H%R(K).GE.1.D-4) THEN
            XX=1.D0/MAX(SQRT(U%R(K)**2+V%R(K)**2),1.D-12)
            T2%R(K)=UNSV2D%R(K)*(T2%R(K)*V%R(K)-T3%R(K)*U%R(K))*XX
            T7%R(K)=XX*(2.D0*T1%R(K)*SEC_R%R(K)+T2%R(K))/H%R(K)
!           FORCES ALONG X AND Y
            FU%R(K) = FU%R(K) - U%R(K)*T7%R(K)
            FV%R(K) = FV%R(K) - V%R(K)*T7%R(K)
          ENDIF
        ENDDO
!
      ENDIF
!
!=======================================================================
!
!  WIND
!
!                               1                         2     2
!              FU           =  --- * F    * U    * SQRT( U   + V    )
!                VENT           H     AIR    AIR          AIR   AIR
!
!
!                               1                         2     2
!              FV           =  --- * F    * V    * SQRT( U   + V    )
!                VENT           H     AIR    AIR          AIR   AIR
!
!
      IF(VENT) THEN
!
!  TEMPORARY TREATMENT OF TIDAL FLATS
!  THE WIND EFFECT IS ONLY CONSIDERED IF THE WATER DEPTH IS
!  GREATER THAN 1 M.
!
!  ASSUMES HERE THAT THE WIND IS GIVEN IN P1
!
        DO N=1,NPOIN
          IF (HN%R(N).GT.HWIND) THEN
            WD = SQRT( WINDX%R(N)**2 + WINDY%R(N)**2 )
            FU%R(N) = FU%R(N) + FAIR * WINDX%R(N) * WD / HN%R(N)
            FV%R(N) = FV%R(N) + FAIR * WINDY%R(N) * WD / HN%R(N)
          ENDIF
        ENDDO
!
      ENDIF
!
!=======================================================================
!
! CORIOLIS FORCE
!       
!
!                FU           =  + FCOR * V
!                  CORIOLIS
!
!                FV           =  - FCOR * U
!                  CORIOLIS
!
      IF(CORIOL) THEN
!
      PI = ACOS(-1.D0)
!
        IF(SPHERI) THEN
!
          WROT = 2 * PI / 86164.D0
          DO I=1,NPOIN
!           FORMULATION INDEPENDENT OF THE DIRECTION OF NORTH
            FU%R(I) = FU%R(I) + VN%R(I) * 2 * WROT * SINLAT%R(I)
            FV%R(I) = FV%R(I) - UN%R(I) * 2 * WROT * SINLAT%R(I)
          ENDDO
!
!         TAKES THE TIDAL FORCE INTO ACCOUNT
!
          IF(MAREE) THEN
            CALL MARAST(MARDAT,MARTIM,PHI0,NPOIN,AT,
     &                  FU%R,FV%R,MESH%X%R,SINLAT%R,COSLAT%R,GRAV)
          ENDIF
!
          IF(LT.EQ.1) THEN
            IF(LNG.EQ.1) WRITE(LU,11)
            IF(LNG.EQ.2) WRITE(LU,12)
          ENDIF
11        FORMAT(1X,'PROSOU : EN COORDONNEES SHERIQUES, LE',/,
     &           1X,'         COEFFICIENT DE CORIOLIS EST',/,
     &           1X,'         CALCULE EN FONCTION DE LA LATITUDE.',/,
     &           1X,'         LE MOT-CLE ''COEFFICIENT DE CORIOLIS''',/,
     &           1X,'         N''EST DONC PAS PRIS EN COMPTE.')
12        FORMAT(1X,'PROSOU : IN SPHERICAL COORDINATES, THE CORIOLIS',/,
     &           1X,'         PARAMETER DEPENDS ON THE LATITUDE.',/,
     &           1X,'         THE KEY WORD ''CORIOLIS COEFFICIENT''',/,
     &           1X,'         IS CONSEQUENTLY IGNORED.')
!
        ELSE
!
          CALL OS( 'X=X+CY  ' , FU , VN , VN ,  FCOR )
          CALL OS( 'X=X+CY  ' , FV , UN , UN , -FCOR )
!
          IF(LT.EQ.1) THEN
            IF(LNG.EQ.1) WRITE(LU,21)
            IF(LNG.EQ.2) WRITE(LU,22)
          ENDIF
21        FORMAT(1X,'PROSOU : EN COORDONNEES CARTESIENNES, LE',/,
     &           1X,'         COEFFICIENT DE CORIOLIS EST LU DANS LE',/,
     &           1X,'         FICHIER DES PARAMETRES ET CORRESPOND',/,
     &           1X,'         AU MOT-CLE ''COEFFICIENT DE CORIOLIS''',/,
     &           1X,'         IL EST ALORS CONSTANT EN ESPACE')
22        FORMAT(1X,'PROSOU : IN CARTESIAN COORDINATES, THE CORIOLIS',/,
     &           1X,'         PARAMETER IS READ IN THE STEERING FILE',/,
     &           1X,'         IT IS THE KEY WORD ''CORIOLIS',/,
     &           1X,'         COEFFICIENT'', IT IS UNIFORM IN SPACE')
!
        ENDIF
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!  THE SECOND MEMBERS ARE PROPERLY DISCRETISED
!
      IELMU=UN%ELM
!
      IF(IELMU.NE.IELM1) THEN
        CALL CHGDIS(FU,IELM1,IELMU,MESH)
        CALL CHGDIS(FV,IELM1,IELMU,MESH)
      ENDIF
!
!-----------------------------------------------------------------------
!
      IELMH=HN%ELM
      CALL CPSTVC(HN,SMH)
      YASMH=.FALSE.
      CALL OS('X=0     ',X=SMH)
!
!     RAIN-EVAPORATION
!
      IF(RAIN) THEN
        RAIN_MPS=RAIN_MMPD/86400000.D0
        SURDT=1.D0/DT
        IF(BANDEC) THEN
!         EVAPORATION (TENTATIVELY...) LIMITED BY AVAILABLE WATER
          DO I=1,NPOIN
            PLUIE%R(I)=MAX(RAIN_MPS,-MAX(HN%R(I),0.D0)*SURDT)
          ENDDO
        ELSE
          CALL OS('X=C     ',X=PLUIE,C=RAIN_MPS)
        ENDIF 
      ENDIF
!
!     SOURCES
!
      IF(NREJET.GT.0) THEN
!
        YASMH = .TRUE.
!
!       SOURCE TERMS IN THE CONTINUITY EQUATION
!       BEWARE, SMH IS ALSO USED FOR TRACER
!
        DO I = 1 , NREJET
          IR = ISCE(I)
!         THE TEST IS USEFUL IN PARALLEL MODE, WHEN THE POINT SOURCE
!         IS NOT IN THE SUB-DOMAIN
          IF(IR.GT.0) THEN
            IF(OPTSOU.EQ.1) THEN
!             "NORMAL" VERSION
              SMH%R(IR)=SMH%R(IR)+DSCE(I)*UNSV2D%R(IR)
            ELSE
!             "DIRAC" VERSION
              SMH%R(IR)=SMH%R(IR)+DSCE(I)
            ENDIF
          ENDIF
        ENDDO
!
!       SOURCE TERMS IN THE MOMENTUM EQUATIONS
!       EXPLICIT TREATMENT OF MOMENTUM CONTRIBUTIONS TO THE SOURCES
!
        IF(NREJEU.GT.0) THEN
          DO I = 1 , NREJEU
            IR = ISCE(I)
!           THE TEST IS USEFUL IN PARALLEL MODE, WHEN THE POINT SOURCE
!           IS NOT IN THE SUB-DOMAIN
            IF(IR.GT.0) THEN
!             MOMENTUM ADDED BY THE SOURCE
!      -      MOMENTUM TAKEN BY THE SOURCE
              FU%R(IR)=FU%R(IR) + (VUSCE(AT,I)-UN%R(IR))*
     &        DSCE(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
              FV%R(IR)=FV%R(IR) + (VVSCE(AT,I)-VN%R(IR))*
     &        DSCE(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            ENDIF
          ENDDO
        ENDIF
!
      ENDIF
!
!     CULVERTS
!
      IF(NSIPH.GT.0) THEN
!
        YASMH = .TRUE.
!
        DO I = 1 , NSIPH
        IR = ENTSIP(I)
          IF(IR.GT.0) THEN
            IF(OPTSOU.EQ.1) THEN
!             "NORMAL" VERSION
              SMH%R(IR)=SMH%R(IR)-DSIP(I)*UNSV2D%R(IR)
            ELSE
!             "DIRAC" VERSION
              SMH%R(IR)=SMH%R(IR)-DSIP(I)
            ENDIF
            FU%R(IR) = FU%R(IR) - (USIP(I,1)-UN%R(IR))*
     &      DSIP(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            FV%R(IR) = FV%R(IR) - (VSIP(I,1)-VN%R(IR))*
     &      DSIP(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
          ENDIF
          IR = SORSIP(I)
          IF(IR.GT.0) THEN
            IF(OPTSOU.EQ.1) THEN
!             "NORMAL" VERSION
              SMH%R(IR)=SMH%R(IR)+DSIP(I)*UNSV2D%R(IR)
            ELSE
!             "DIRAC" VERSION
              SMH%R(IR)=SMH%R(IR)+DSIP(I)
            ENDIF
            FU%R(IR) = FU%R(IR) + (USIP(I,2)-UN%R(IR))*
     &      DSIP(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            FV%R(IR) = FV%R(IR) + (VSIP(I,2)-VN%R(IR))*
     &      DSIP(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
          ENDIF
        ENDDO
      ENDIF
!
!     TUBES OR BRIDGES
!
      IF(NBUSE.GT.0) THEN
!
        YASMH = .TRUE.
!
        DO I = 1 , NBUSE
          IR = ENTBUS(I)
          IF(IR.GT.0) THEN
            IF(OPTSOU.EQ.1) THEN
!             "NORMAL" VERSION
              SMH%R(IR)=SMH%R(IR)-DBUS(I)*UNSV2D%R(IR)
            ELSE
!             "DIRAC" VERSION
              SMH%R(IR)=SMH%R(IR)-DBUS(I)
            ENDIF
            FU%R(IR) = FU%R(IR) - (UBUS(I,1)-UN%R(IR))*
     &      DBUS(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            FV%R(IR) = FV%R(IR) - (VBUS(I,1)-VN%R(IR))*
     &      DBUS(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
          ENDIF
          IR = SORBUS(I)
          IF(IR.GT.0) THEN
            IF(OPTSOU.EQ.1) THEN
!             "NORMAL" VERSION
              SMH%R(IR)=SMH%R(IR)+DBUS(I)*UNSV2D%R(IR)
            ELSE
!             "DIRAC" VERSION
              SMH%R(IR)=SMH%R(IR)+DBUS(I)
            ENDIF
            FU%R(IR) = FU%R(IR) + (UBUS(I,2)-UN%R(IR))*
     &      DBUS(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            FV%R(IR) = FV%R(IR) + (VBUS(I,2)-VN%R(IR))*
     &      DBUS(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
          ENDIF
        ENDDO
      ENDIF
!
!     WEIRS (ONLY IF TYPSEUIL=2)
!
      IF(NWEIRS.GT.0.AND.TYPSEUIL.EQ.2) THEN
!
        YASMH = .TRUE.
!
        DO N=1,NWEIRS
          DO I=1,NPSING%I(N)
            IR=NDGA1%ADR(N)%P%I(I)
            IF(IR.GT.0) THEN
              SMH%R(IR)= SMH%R(IR)+QWA%ADR(N)%P%R(I)*UNSV2D%R(IR)
! QUANTITY OF MOVEMENTS NOT TAKEN INTO ACCOUNT FOR THE MOMENT
! The following lines generate instability and crash
! Probably because we would like to impose velocities accross  solid boundaries!
!
!                 FU%R(IR) = FU%R(IR) + (UWEIRA%ADR(N)%P%R(I)-UN%R(IR))*
!     &              QWA%ADR(N)%P%R(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
!                 FV%R(IR) = FV%R(IR) + (VWEIRA%ADR(N)%P%R(I)-VN%R(IR))*
!     &              QWA%ADR(N)%P%R(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            ENDIF
            IR=NDGB1%ADR(N)%P%I(I)
            IF(IR.GT.0) THEN
              SMH%R(IR)=SMH%R(IR)+QWB%ADR(N)%P%R(I)*UNSV2D%R(IR)
!              FU%R(IR) = FU%R(IR) + (UWEIRB%ADR(N)%P%R(I)-UN%R(IR))*
!     &           QWB%ADR(N)%P%R(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
!              FV%R(IR) = FV%R(IR) + (VWEIRB%ADR(N)%P%R(I)-VN%R(IR))*
!     &           QWB%ADR(N)%P%R(I)*UNSV2D%R(IR)/MAX(HN%R(IR),0.1D0)
            ENDIF
          ENDDO
        ENDDO
      ENDIF
!
!=======================================================================
!
!  WAVE DRIVEN CURRENTS
!      
!
!                FU        =  FXWAVE
!                  COUROU
!
!                FV        =  FYWAVE
!                  COUROU
!
!       FXWAVE AND FYWAVE ARE TAKEN IN A RESULTS FILE FROM
!       ARTEMIS OR TOMAWAC
!
!       BEWARE   : 1. MESHES MUST BE THE SAME
!       ---------
!
!                  2. STATIONARY FORCING
!
      IF(COUROU) THEN
!
!       WITH NO COUPLING, TAKING THE WAVE STRESSES ONCE FOR ALL
!       IN A BINARY DATA FILE
!
        IF(.NOT.DEJALU.AND..NOT.INCLUS(COUPLING,'TOMAWAC')) THEN
!
          ALLOCATE(W(NPOIN),STAT=ERR)
          IF(ERR.NE.0) THEN
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'ERREUR D''ALLOCATION DE W DANS PROSOU'
              WRITE(LU,*) 'CODE ERREUR ',ERR
              WRITE(LU,*) 'NOMBRE DE POINTS : ',NPOIN
            ENDIF
            IF(LNG.EQ.2) THEN
              WRITE(LU,*) 'MEMORY ALLOCATION ERROR OF W IN PROSOU'
              WRITE(LU,*) 'ERROR CODE ',ERR
              WRITE(LU,*) 'NUMBER OF POINTS: ',NPOIN
            ENDIF
          ENDIF
!
!         NBI1 : BINARY DATA FILE 1
          NOMX='FORCE FX        '
          NOMY='FORCE FY        '
          CALL FIND_IN_SEL(FXWAVE,NOMX,T2D_FILES(T2DBI1)%LU,
     &                     T2D_FILES(T2DBI1)%FMT,W,OKX,NPTH,NP,ATH)
          CALL FIND_IN_SEL(FYWAVE,NOMY,T2D_FILES(T2DBI1)%LU,
     &                     T2D_FILES(T2DBI1)%FMT,W,OKY,NPTH,NP,ATH)
          IF(.NOT.OKX.OR..NOT.OKY) THEN
!           SECOND TRY (OLD VERSIONS OF ARTEMIS OR TOMAWAC)
            NOMX='FORCE_FX        '
            NOMY='FORCE_FY        '
            CALL FIND_IN_SEL(FXWAVE,NOMX,T2D_FILES(T2DBI1)%LU,
     &                       T2D_FILES(T2DBI1)%FMT,W,OKX,NPTH,NP,ATH)
            CALL FIND_IN_SEL(FYWAVE,NOMY,T2D_FILES(T2DBI1)%LU,
     &                       T2D_FILES(T2DBI1)%FMT,W,OKY,NPTH,NP,ATH)
          ENDIF
!         CLANDESTINE VARIABLES FROM TOMAWAC TO SISYPHE
          IF(NVARCL.GT.0) THEN
            DO I=1,NVARCL
              CALL FIND_IN_SEL(VARCL%ADR(I)%P,VARCLA(I)(1:16),
     &                         T2D_FILES(T2DBI1)%LU,
     &                         T2D_FILES(T2DBI1)%FMT,
     &                         W,OKC,NPTH,NP,ATH)
              IF(.NOT.OKC) THEN
                IF(LNG.EQ.1) WRITE(LU,7) VARCLA(I)(1:16)
                IF(LNG.EQ.2) WRITE(LU,8) VARCLA(I)(1:16)
7             FORMAT(1X,'PROSOU : VARIABLE CLANDESTINE :',/,1X,A16,/,1X,
     &                  '         NON TROUVEE',/,1X,
     &                  '         DANS LE FICHIER DE HOULE')
8             FORMAT(1X,'PROSOU : CLANDESTINE VARIABLE:',/,1X,A16,/,1X,
     &                  '         NOT FOUND',/,1X,
     &                  '         IN THE WAVE RESULTS FILE')
              CALL PLANTE(1)
              STOP
              ENDIF
            ENDDO
          ENDIF
!
          IF(.NOT.OKX.OR..NOT.OKY) THEN
            IF(LNG.EQ.1) WRITE(LU,5)
            IF(LNG.EQ.2) WRITE(LU,6)
5           FORMAT(1X,'PROSOU : FORCE FX OU FY NON TROUVES',/,1X,
     &                '         DANS LE FICHIER DE HOULE')
6           FORMAT(1X,'PROSOU: FORCE FX OR FY NOT FOUND',/,1X,
     &                '         IN THE WAVE RESULTS FILE')
            CALL PLANTE(1)
            STOP
          ENDIF
          IF(NP.NE.NPOIN) THEN
            IF(LNG.EQ.1) WRITE(LU,95)
            IF(LNG.EQ.2) WRITE(LU,96)
 95         FORMAT(1X,'PROSOU : SIMULATION DES COURANTS DE HOULE.',/,
     &             1X,'LES MAILLAGES HOULE ET COURANTS SONT ',/,
     &             1X,'DIFFERENTS : PAS POSSIBLE POUR LE MOMENT.')
 96         FORMAT(1X,'PROSOU: WAVE DRIVEN CURRENTS MODELLING.',/,
     &             1X,'WAVE AND CURRENT MODELS MESHES ARE ',/,
     &             1X,'DIFFERENT : NOT POSSIBLE AT THE MOMENT.')
!
            CALL PLANTE(1)
            STOP
          ENDIF
!         WRITES OUT TO THE LISTING
          IF(LNG.EQ.1) WRITE(LU,115) ATH
          IF(LNG.EQ.2) WRITE(LU,116) ATH
115       FORMAT(1X,/,1X,'PROSOU : COURANTS DE HOULE',/,
     &                1X,'         LECTURE AU TEMPS ',F10.3,/)
116       FORMAT(1X,/,1X,'PROSOU: WAVE DRIVEN CURRENTS MODELLING',/,
     &                1X,'         READING FILE AT TIME ',F10.3,/)
          IF(IELMU.NE.IELM1) THEN
            CALL CHGDIS(FXWAVE,IELM1,IELMU,MESH)
            CALL CHGDIS(FYWAVE,IELM1,IELMU,MESH)
          ENDIF
          DEJALU = .TRUE.
!
        ENDIF
!
!       ADDS INTO FU AND FV
!
        IF(INCLUS(COUPLING,'TOMAWAC')) THEN
          IF(IELMU.NE.IELM1) THEN
            CALL CHGDIS(FXWAVE,IELM1,IELMU,MESH)
            CALL CHGDIS(FYWAVE,IELM1,IELMU,MESH)
          ENDIF
        ENDIF
        CALL OS('X=X+Y   ',X=FU,Y=FXWAVE)
        CALL OS('X=X+Y   ',X=FV,Y=FYWAVE)
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!     TAKES SEEPAGE IN THE SOIL INTO ACCOUNT
!     COMMUNICATES WITH ESTEL-3D
!
!     GETS SOURCE TERM FROM ESTEL-3D TO ACCOUNT FOR SEEPAGE
!     CALLS THE INFILTRATION ROUTINE
!
      CALL INFILTRATION_GET(SMH%R,UNSV2D%R,YASMH)
!
!-----------------------------------------------------------------------
!
      RETURN
      END
