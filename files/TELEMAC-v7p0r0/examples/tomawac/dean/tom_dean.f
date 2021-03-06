!                    *****************
                     SUBROUTINE TOM_CORFON
!                    *****************
!
!
!***********************************************************************
! TOMAWAC   V6P1                                   14/06/2011
!***********************************************************************
!
!brief    MODIFIES THE BOTTOM TOPOGRAPHY.
!
!warning  USER SUBROUTINE; MUST BE CODED BY THE USER
!
!history  F. MARCOS
!+
!+
!+
!
!history  OPTIMER (    )
!+        12/01/2001
!+
!+   TOMAWAC/COWADIS MERGE
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
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TOMAWAC
!
      IMPLICIT NONE
!
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!
!VB---------------------------------MODIF Dean, 1991
      INTEGER IP
!
      DO IP=1,NPOIN2
!        ZF(IP) = -5.D0
        ZF(IP) = - 0.25D0*(300.D0 - X(IP))**(2./3.)
      ENDDO
!VB---------------------------------MODIF fin
!
!
      RETURN
      END
!
!                    ***************
                     SUBROUTINE QVEG
!                    ***************
!
     &( TSTOT , TSDER , F , VARIAN , DEPTH, FMOY , 
     &  XKMOY , NF    , NPLAN  , NPOIN2   , BETA  )
!
!***********************************************************************
! TOMAWAC   V7P0                                 
!***********************************************************************
!
!brief    Takes into account the friction due to vegetation      
!
!history  VITO BACCHI (EDF - LNHE)
!+        12/09/2014
!+        V7P0
!+   First version, on birthday eve...
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| BETA           |<--| WORK TABLE
!| DEPTH          |-->| WATER DEPTH
!| F              |-->| DIRECTIONAL SPECTRUM
!| FMOY           |-->| MEAN SPECTRAL FRQUENCY FMOY (relative frequency)
!| NF             |-->| NUMBER OF FREQUENCIES
!| NPLAN          |-->| NUMBER OF DIRECTIONS
!| NPOIN2         |-->| NUMBER OF POINTS IN 2D MESH
!| TSDER          |<->| DERIVED PART OF THE SOURCE TERM CONTRIBUTION
!| TSTOT          |<->| TOTAL PART OF THE SOURCE TERM CONTRIBUTION
!| VARIAN         |-->| ENERGY SPECTRUM VARIANCE
!| XKMOY          |-->| AVERAGE WAVE NUMBER
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TOMAWAC, ONLY : DEUPI,GRAVIT,PI,X
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)             :: NF,NPLAN,NPOIN2
      DOUBLE PRECISION, INTENT(IN)    :: XKMOY(NPOIN2),VARIAN(NPOIN2) 
      DOUBLE PRECISION, INTENT(IN)    :: DEPTH(NPOIN2),FMOY(NPOIN2)
      DOUBLE PRECISION, INTENT(INOUT) :: BETA(NPOIN2)
      DOUBLE PRECISION, INTENT(INOUT) :: TSTOT(NPOIN2,NPLAN,NF)
      DOUBLE PRECISION, INTENT(INOUT) :: TSDER(NPOIN2,NPLAN,NF)
      DOUBLE PRECISION, INTENT(IN)    :: F(NPOIN2,NPLAN,NF)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER  JP    , JF    , IP
      DOUBLE PRECISION C1,CVEG,CD,NV,BV,ALFA,KH,AKH,DV
      DOUBLE PRECISION AUX,NUM,DENUM,SHAKH
!
      INTRINSIC SQRT
!
!-----------------------------------------------------------------------
!
!     NUMBER OF PLANTS*SQM 
      NV = 20.D0
!     PLANT AREA PER UNINT HEIGHT
      BV = 0.25D0
!     BULK DRAG COEFFICIENT
      CD = 0.2D0
!     VEGETATION HEIGHT
      DV = 1.D0
      ALFA = 0.1D0
      C1 = - SQRT(2.D0/PI)*GRAVIT**2
      CVEG = C1*CD*BV*NV/(DEUPI**3)
!
!       VEGETATION OVER A CONSTANT DEPTH
!       COMPUTES THE BETA COEFFICIENT : QVEG1 = BETA * F
!    
        DO IP=1,NPOIN2
          IF(X(IP).LT.50.D0.OR.X(IP).GT.150.D0) THEN
            ALFA = 0.D0
          ELSE
            ALFA = DV/DEPTH(IP)
          ENDIF
          KH = XKMOY(IP)*DEPTH(IP)
          AKH = ALFA*KH
          SHAKH = SINH(AKH)
          NUM = SHAKH*(SHAKH**2 + 3.D0)
          DENUM = 3.D0*XKMOY(IP)*COSH(KH)**3
          AUX = (XKMOY(IP)/FMOY(IP))**3
          BETA(IP) = CVEG*AUX*(NUM/DENUM)*SQRT(VARIAN(IP))
        ENDDO
!
!
!       LOOP OVER THE DISCRETISED FREQUENCIES
!          
!         TAKES THE SOURCE TERM INTO ACCOUNT
!         
        DO JF=1,NF
          DO JP=1,NPLAN
            DO IP=1,NPOIN2
              TSTOT(IP,JP,JF) = TSTOT(IP,JP,JF)+BETA(IP)*F(IP,JP,JF)
              TSDER(IP,JP,JF) = TSDER(IP,JP,JF)+BETA(IP)
            ENDDO
          ENDDO
        ENDDO
!
!-----------------------------------------------------------------------
!
      RETURN
      END
!
!-----------------------------------------------------------------------
!
!                    *****************
                     SUBROUTINE LIMWAC
!                    *****************
!
     &(F     , FBOR  , LIFBOR, NPTFR , NPLAN , NF    ,  TETA , FREQ  ,
     & NPOIN2, NBOR  , AT    , LT    , DDC   , LIMSPE, FPMAXL, FETCHL,
     & SIGMAL, SIGMBL, GAMMAL, FPICL , HM0L  , APHILL, TETA1L, SPRE1L,
     & TETA2L, SPRE2L, XLAMDL, X ,Y  , KENT  , KSORT , NFO1  , NBI1  ,
     & BINBI1, UV    , VV    , SPEULI, VENT  , VENSTA, GRAVIT, DEUPI ,
     & PRIVE , NPRIV , SPEC  , FRA   , DEPTH , FRABL ,BOUNDARY_COLOUR)
!
!***********************************************************************
! TOMAWAC   V6P3                                   21/06/2011
!***********************************************************************
!
!brief    BOUNDARY CONDITIONS.
!
!warning  BY DEFAULT, THE BOUNDARY CONDITIONS SPECIFIED IN THE FILE
!+            DYNAM ARE DUPLICATED ON ALL THE DIRECTIONS AND FREQUENCIES
!
!history  F. MARCOS (LNH)
!+        01/02/95
!+        V1P0
!+
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
!history  G.MATTAROLO (EDF - LNHE)
!+        20/06/2011
!+        V6P1
!+   Translation of French names of the variables in argument
!
!history  E. GAGNAIRE-RENOU & J.-M. HERVOUET (EDF R&D, LNHE)
!+        12/03/2013
!+        V6P3
!+   A line IF(LIMSPE.EQ.0...) RETURN removed.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| APHILL         |-->| BOUNDARY PHILLIPS CONSTANT
!| AT             |-->| COMPUTATION TIME
!| BINBI1         |-->| BINARY FILE 1 BINARY
!| BOUNDARY_COLOUR|-->| COLOUR OF BOUNDARY POINT (DEFAULT: ITS RANK)
!| DDC            |-->| DATE OF COMPUTATION BEGINNING
!| DEPTH          |-->| WATER DEPTH
!| DEUPI          |-->| 2.PI
!| F              |-->| VARIANCE DENSITY DIRECTIONAL SPECTRUM
!| FBOR           |<->| SPECTRAL VARIANCE DENSITY AT THE BOUNDARIES
!| FETCHL         |-->| BOUNDARY MEAN FETCH VALUE
!| FPICL          |-->| BOUNDARY PEAK FREQUENCY
!| FPMAXL         |-->| BOUNDARY MAXIMUM PEAK FREQUENCY
!| FRA            |<--| DIRECTIONAL SPREADING FUNCTION VALUES
!| FRABL          |-->| BOUNDARY ANGULAR DISTRIBUTION FUNCTION
!| FREQ           |-->| DISCRETIZED FREQUENCIES
!| GAMMAL         |-->| BOUNDARY PEAK FACTOR
!| GRAVIT         |-->| GRAVITY ACCELERATION
!| HM0L           |-->| BOUNDARY SIGNIFICANT WAVE HEIGHT
!| KENT           |-->| B.C.: A SPECTRUM IS PRESCRIBED AT THE BOUNDARY
!| KSORT          |-->| B.C.: FREE BOUNDARY: NO ENERGY ENTERING THE DOMAIN
!| LIFBOR         |-->| TYPE OF BOUNDARY CONDITION ON F
!| LIMSPE         |-->| TYPE OF BOUNDARY DIRECTIONAL SPECTRUM
!| LT             |-->| NUMBER OF THE TIME STEP CURRENTLY SOLVED
!| NBI1           |-->| LOGICAL UNIT NUMBER OF THE USER BINARY FILE
!| NBOR           |-->| GLOBAL NUMBER OF BOUNDARY POINTS
!| NF             |-->| NUMBER OF FREQUENCIES
!| NFO1           |-->| LOGICAL UNIT NUMBER OF THE USER FORMATTED FILE
!| NPLAN          |-->| NUMBER OF DIRECTIONS
!| NPOIN2         |-->| NUMBER OF POINTS IN 2D MESH
!| NPRIV          |-->| NUMBER OF PRIVATE ARRAYS
!| NPTFR          |-->| NUMBER OF BOUNDARY POINTS
!| PRIVE          |-->| USER WORK TABLE
!| SIGMAL         |-->| BOUNDARY SPECTRUM VALUE OF SIGMA-A
!| SIGMBL         |-->| BOUNDARY SPECTRUM VALUE OF SIGMA-B
!| SPEC           |<--| VARIANCE DENSITY FREQUENCY SPECTRUM
!| SPEULI         |-->| INDICATES IF B.C. SPECTRUM IS MODIFIED BY USER
!| SPRE1L         |-->| BOUNDARY DIRECTIONAL SPREAD 1
!| SPRE2L         |-->| BOUNDARY DIRECTIONAL SPREAD 2
!| TETA           |-->| DISCRETIZED DIRECTIONS
!| TETA1L         |-->| BOUNDARY MAIN DIRECTION 1
!| TETA2L         |-->| BOUNDARY MAIN DIRECTION 2
!| UV, VV         |-->| WIND VELOCITIES AT THE MESH POINTS
!| VENSTA         |-->| INDICATES IF THE WIND IS STATIONARY
!| VENT           |-->| INDICATES IF WIND IS TAKEN INTO ACCOUNT
!| X              |-->| ABSCISSAE OF POINTS IN THE MESH
!| XLAMDL         |-->| BOUNDARY WEIGHTING FACTOR FOR ANGULAR
!|                |   | DISTRIBUTION FUNCTION
!| Y              |-->| ORDINATES OF POINTS IN THE MESH
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE INTERFACE_TOMAWAC, EX_LIMWAC => LIMWAC
      IMPLICIT NONE
!
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
      INTEGER NPLAN,NF,NPOIN2,NPTFR,LT,NPRIV
      INTEGER, INTENT(IN) :: BOUNDARY_COLOUR(NPTFR)
!
      DOUBLE PRECISION F(NPOIN2,NPLAN,NF),X(NPOIN2),Y(NPOIN2)
      DOUBLE PRECISION FBOR(NPTFR,NPLAN,NF),TETA(NPLAN),FREQ(NF)
      DOUBLE PRECISION UV(NPOIN2),VV(NPOIN2), SPEC(NF), FRA(NPLAN)
      DOUBLE PRECISION PRIVE(NPOIN2,NPRIV),DDC, DEPTH(NPOIN2)
      DOUBLE PRECISION HM0L,FPICL,GAMMAL,SIGMAL,SIGMBL,APHILL,FETCHL
      DOUBLE PRECISION FPMAXL,TETA1L,SPRE1L,TETA2L,SPRE2L,XLAMDL
      DOUBLE PRECISION GRAVIT,DEUPI,E2FMIN
!
      DOUBLE PRECISION AT, DTETAR, DF3, AUX
!
      LOGICAL SPEULI, VENT, VENSTA
!
      INTEGER NBOR(NPTFR),LIFBOR(NPTFR),NFO1,NBI1,NPB
      INTEGER KENT,KSORT,IFF,IPLAN,IPTFR,LIMSPE,FRABL
!
!     DOUBLE PRECISION, ALLOCATABLE :: TRAV(:)
      DOUBLE PRECISION, ALLOCATABLE :: UV2D(:),VV2D(:),PROF(:)
      DOUBLE PRECISION, ALLOCATABLE :: FB_CTE(:,:)
      LOGICAL FLAG
!
      CHARACTER(LEN=3) BINBI1
!
      SAVE NPB,UV2D,VV2D,PROF,FB_CTE
!
!***********************************************************************
!
!     MODIFIES THE TYPE OF BOUNDARY CONDITION (OPTIONAL)
!
!     CAN BE CODED BY THE USER (SPEULI=.TRUE.)
!
!     LIFBOR(IPTFR)=KENT OR KSORT
!
      FLAG=.FALSE.
      IF (VENT .AND. (LIMSPE.EQ.1 .OR. LIMSPE.EQ.2 .OR. LIMSPE.EQ.3
     & .OR. LIMSPE.EQ.5)) FLAG=.TRUE.
!
!     THE FIRST TIME, ALLOCATES MEMORY FOR THE USEFUL ARRAYS
!     ---------------------------------------------------------------
!
      IF(LT.LT.1) THEN
        NPB=1
        IF(FLAG) THEN
          ALLOCATE(UV2D(1:NPTFR),VV2D(1:NPTFR))
          NPB=NPTFR
        ENDIF
        IF(LIMSPE.EQ.7 .OR. SPEULI) THEN
          ALLOCATE(PROF(1:NPTFR))
          NPB=NPTFR
        ENDIF
        IF(NPB.EQ.1) THEN
          ALLOCATE(FB_CTE(1:NPLAN,1:NF))
        ENDIF
      ENDIF
      IF (.NOT.ALLOCATED(UV2D)) ALLOCATE(UV2D(NPTFR))
      IF (.NOT.ALLOCATED(VV2D)) ALLOCATE(VV2D(NPTFR))
      IF (.NOT.ALLOCATED(PROF)) ALLOCATE(PROF(NPTFR))
      IF (.NOT.ALLOCATED(FB_CTE)) ALLOCATE(FB_CTE(1:NPLAN,1:NF))
!
!     THE FIRST TIME (AND POSSIBLY SUBSEQUENTLY IF THE WIND IS NOT
!     STATIONARY AND IF THE BOUNDARY SPECTRUM DEPENDS ON IT),
!     COMPUTES THE BOUNDARY SPECTRUM
!    
      IF(LT.LT.1 .OR. (.NOT.VENSTA.AND.FLAG) .OR. SPEULI) THEN
        IF(FLAG) THEN
          DO IPTFR=1,NPTFR
            UV2D(IPTFR)=UV(NBOR(IPTFR))
            VV2D(IPTFR)=VV(NBOR(IPTFR))
          ENDDO     
        ENDIF
        IF(LIMSPE.EQ.7 .OR. SPEULI) THEN
          DO IPTFR=1,NPTFR
            PROF(IPTFR)=DEPTH(NBOR(IPTFR))
          ENDDO
        ENDIF
!   
        E2FMIN = 1.D-30
!
!       WHEN NPB=1 FBOR ONLY FILLED FOR FIRST POINT
!
!       SPECTRUM ON BOUNDARIES
!
        IF(NPB.EQ.NPTFR) THEN
          CALL SPEINI
     &(   FBOR  ,SPEC  ,FRA   ,UV2D  ,VV2D  ,FREQ ,
     &    TETA  ,GRAVIT,FPMAXL,FETCHL,SIGMAL,SIGMBL,GAMMAL,FPICL,
     &    HM0L  ,APHILL,TETA1L,SPRE1L,TETA2L,SPRE2L,XLAMDL,
     &    NPB   ,NPLAN ,NF    ,LIMSPE,E2FMIN,PROF  ,FRABL )
        ELSE
          CALL SPEINI
     &(   FB_CTE,SPEC  ,FRA   ,UV2D  ,VV2D  ,FREQ ,
     &    TETA  ,GRAVIT,FPMAXL,FETCHL,SIGMAL,SIGMBL,GAMMAL,FPICL,
     &    HM0L  ,APHILL,TETA1L,SPRE1L,TETA2L,SPRE2L,XLAMDL,
     &    NPB   ,NPLAN ,NF    ,LIMSPE,E2FMIN,PROF  ,FRABL )
        ENDIF
!
!     ===========================================================
!     TO BE MODIFIED BY USER - RESU CAN BE CHANGED
!     ===========================================================
!
        IF(SPEULI) THEN
!
!======================================================================
!MJTS MODIF POUR CAS MONOCHROMATIQUE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!======================================================================
!         Permet d'avoir Hm0 = 3.54 m qui est le Hm0 cible; freq=1 Hz
          DTETAR=DEUPI/DBLE(NPLAN)
          DF3=0.5D0*(FREQ(4)/FREQ(3)-1.0D0)*(FREQ(4)+FREQ(3))
          AUX=(3.54D0)**2/(16.0D0*DTETAR*DF3)
!
          DO IFF=1,NF
            DO IPLAN=1,NPLAN
              FB_CTE(IPLAN,IFF)=0.0D0
            ENDDO
          ENDDO
!.........Put energy on a single bin : 10th direction (=90 deg for NPLAN=36
!         and 4rd frequency
          FB_CTE(10,4)=AUX
        ENDIF
!
!     ===========================================================
!     END OF USER MODIFICATIONS
!     ===========================================================
      ENDIF
!
!
!     -----------------------------------------------------------------
!     DUPLICATES THE BOUNDARY CONDITION FROM DYNAM ON ALL THE
!     DIRECTIONS AND FREQUENCIES, IF LIQUID BOUNDARY
!     -----------------------------------------------------------------
!       IF (FLAG .OR. LIMSPE.EQ.7 .OR. SPEULI) THEN
!         DO IPTFR=1,NPTFR
!           IF (LIFBOR(IPTFR).EQ.KENT) THEN
!             DO IFF=1,NF
!               DO IPLAN=1,NPLAN
!                 F(NBOR(IPTFR),IPLAN,IFF)=FBOR(IPTFR,IPLAN,IFF)
!               ENDDO
!             ENDDO
!           ENDIF
!         ENDDO
!       ELSE
          DO IPTFR=1,NPTFR
            IF (LIFBOR(IPTFR).EQ.KENT) THEN
              DO IFF=1,NF
                DO IPLAN=1,NPLAN
                  F(NBOR(IPTFR),IPLAN,IFF)=FB_CTE(IPLAN,IFF)
                ENDDO
              ENDDO
            ENDIF
          ENDDO
!       ENDIF
!
      RETURN
      END

!======================================================================
!MJTS - sous-programme ajoute pour mettre a zero toutes les valeurs du
!       spectre, sauf celle du bin (IFREQ, JDIR)
!======================================================================
      SUBROUTINE MONOCRO
     &(F, NPOIN2, NF, NPLAN, IFREQ, JDIR)
!
      IMPLICIT NONE
!
!.....Variables transmises
!     """"""""""""""""""""
      INTEGER NPOIN2, NF, NPLAN, IFREQ, JDIR
      DOUBLE PRECISION F(NPOIN2,NPLAN,NF)
!
!.....Variables locales
!     """"""""""""""""""""
      INTEGER IP, JF, JD
      DOUBLE PRECISION AUX
!
!
      DO IP=1,NPOIN2
        AUX=F(IP,JDIR,IFREQ)
        DO JF=1,NF
          DO JD=1,NPLAN
             F(IP,JD,JF)=0.0D0
          END DO
        END DO
        F(IP,JDIR,IFREQ)=AUX
      END DO
!
      RETURN
      END
!                    *****************
                     SUBROUTINE DUMP2D
!                    *****************
!
     &( LT , XF1 , NP1 )
!
!***********************************************************************
! TOMAWAC   V6P3                                   15/06/2011
!***********************************************************************
!
!brief    WRITES OUT WAVE, WIND, CURRENT, BATHYMETRY, ...
!+                VARIABLES AT EACH NODE OF THE MESH.
!+                VARIES SPATIALLY IN 2D (BINARY SELAFIN FORMAT).
!
!warning  STSDER used as work array here.
!
!
!history  F. MARCOS
!+        01/02/95
!+        V1P0
!+   CREATED
!
!history  M. BENOIT
!+        04/07/96
!+        V1P2
!+   MODIFIED
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
!history  G.MATTAROLO (EDF - LNHE)
!+        15/06/2011
!+        V6P1
!+   Translation of French names of the variables in argument
!
!history  J-M HERVOUETO (EDF R&D, LNHE)
!+        26/02/2013
!+        V6P3
!+   Use of work arrays optimised.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| LT             |-->| NUMBER OF THE TIME STEP CURRENTLY SOLVED
!| NP1            |-->| NPOIN2.NPLAN.NF
!| XF1            |-->| VARIANCE DENSITY DIRECTIONAL SPECTRUM
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_TOMAWAC
      USE INTERFACE_TOMAWAC, EX_DUMP2D => DUMP2D
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)          :: LT,NP1
      DOUBLE PRECISION, INTENT(IN) :: XF1(NP1)
!VB_modif
      DOUBLE PRECISION AUX1(NPOIN2),AUX2(NPOIN2)
      DOUBLE PRECISION AUX3(NPOIN2)
!      DOUBLE PRECISION TAUX1(NPOIN2)
!VB_modif
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER          IP
      DOUBLE PRECISION U10   , FMIN  , FMAX
!
      FMIN=FREQ(1)
      FMAX=FREQ(NF)
!
!=====C====================================
!     C COMPUTES THE SELECTED VARIABLES
!=====C====================================
! THE ORDER IN WHICH THE VARIABLES ARE COMPUTED DOES NOT CORRESPOND TO THAT OF
! THE GRAPHICAL OUTPUT IN AN EFFORT TO LIMIT THE NUMBER OF WORKING ARRAYS.
!
!     ------------------------------- RADIATION STRESSES
!
      IF(.NOT.PROINF) THEN
        IF(SORLEO(11).OR.SORLEO(12).OR.SORLEO(13).OR.
     &     SORLEO(14).OR.SORLEO(15) ) CALL RADIAT
     &( STRA51%R, STRA52%R, STRA53%R, STRA54%R, STRA55%R,
     &  SXK%R   , XF1     , SCG%R   , SDEPTH%R,
!       WORK TABLE HERE
     &  STSDER%R,STRA36%R, STRA37%R, STRA38%R, STRA39%R)
      ENDIF
!
!     ------------------------------- DIRECTIONAL SPREADING
!
      IF(SORLEO(4)) THEN
        CALL SPREAD
     &( STRA31%R,XF1,SCOSTE%R,SSINTE%R,NPLAN ,
     &  SFR%R,SDFR%R,NF,NPOIN2,TAILF,
     &  STRA34%R,STRA35%R,STRA36%R,STRA37%R,STRA38%R,
     &  STRA39%R)
      ENDIF
!
!     ------------------------------- MEAN DIRECTION
!
      IF(SORLEO(3)) THEN
        CALL TETMOY
     &( STRA32%R, XF1 , SCOSTE%R, SSINTE%R, NPLAN , FREQ ,
     &  SDFR%R  , NF  , NPOIN2  , TAILF, STRA36%R ,
     &  STRA37%R, STRA38%R, STRA39%R )
        IF(TRIGO) THEN
          DO IP=1,NPOIN2
            TRA32(IP)=(PISUR2-TRA32(IP))*GRADEG
          ENDDO
        ELSE
          DO IP=1,NPOIN2
            TRA32(IP)=TRA32(IP)*GRADEG
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- MEAN FREQUENCY FMOY
!
      IF(SORLEO(18).OR.SORLEO(28)) THEN
        CALL FREMOY
     &( STRA33%R, XF1   , SFR%R   , SDFR%R  , TAILF , NF  ,
     &  NPLAN      , NPOIN2, STRA38%R, STRA39%R)
        IF(SORLEO(28)) THEN
          DO IP=1,NPOIN2
            TRA61(IP)=1.D0/MIN(MAX(TRA33(IP),FMIN),FMAX)
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- MEAN FREQUENCY FM01
!
      IF(SORLEO(19).OR.SORLEO(29)) THEN
        CALL FREM01
     &( STRA34%R, XF1   , SFR%R   , SDFR%R  , TAILF , NF  ,
     &  NPLAN      , NPOIN2, STRA38%R, STRA39%R)
        IF (SORLEO(29)) THEN
          DO IP=1,NPOIN2
            TRA62(IP)=1.D0/MIN(MAX(TRA34(IP),FMIN),FMAX)
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- MEAN FREQUENCY FM02
!
      IF (SORLEO(20).OR.SORLEO(30)) THEN
        CALL FREM02
     &( STRA35%R, XF1   , SFR%R   , SDFR%R  , TAILF , NF  ,
     &  NPLAN      , NPOIN2, STRA38%R, STRA39%R)
        IF (SORLEO(30)) THEN
          DO IP=1,NPOIN2
            TRA63(IP)=1.D0/MIN(MAX(TRA35(IP),FMIN),FMAX)
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- DISCRETE PEAK FREQUENCY
!
      IF (SORLEO(21).OR.SORLEO(31)) THEN
        CALL FREPIC
     &( STRA36%R, XF1   , SFR%R , NF   , NPLAN , NPOIN2,
     &  STRA38%R, STRA39%R      )
        IF (SORLEO(31)) THEN
          DO IP=1,NPOIN2
            TRA64(IP)=1.D0/MIN(MAX(TRA36(IP),FMIN),FMAX)
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- PEAK FREQUENCY (READ 5TH ORDER)
!
      IF (SORLEO(22).OR.SORLEO(32)) THEN
        CALL FPREAD
     &( STRA56%R, XF1   , SFR%R, SDFR%R  , NF   , NPLAN ,
     &  NPOIN2     , 5.D0  , TAILF   , STRA38%R, STRA39%R  )
        IF (SORLEO(32)) THEN
          DO IP=1,NPOIN2
            TRA65(IP)=1.D0/MIN(MAX(TRA56(IP),FMIN),FMAX)
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- PEAK FREQUENCY (READ 8TH ORDER)
!
      IF (SORLEO(23).OR.SORLEO(33)) THEN
        CALL FPREAD
     &( STRA57%R, XF1   , SFR%R , SDFR%R  , NF   , NPLAN ,
     &  NPOIN2     , 8.D0  , TAILF    , STRA38%R, STRA39%R  )
        IF (SORLEO(33)) THEN
          DO IP=1,NPOIN2
            TRA66(IP)=1.D0/MIN(MAX(TRA57(IP),FMIN),FMAX)
          ENDDO
        ENDIF
      ENDIF
!
      IF(VENT) THEN
!
!       ------------------------------- DRAG COEFFICIENT
!
        IF(SORLEO(25)) THEN
          DO IP=1,NPOIN2
            U10=UV(IP)**2+VV(IP)**2
            IF (U10.GT.1.D-6) THEN
              TRA58(IP)=TRA42(IP)**2/U10
            ELSE
              TRA58(IP)=0.D0
            ENDIF
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- BOTTOM SPEED
!
      IF(.NOT.PROINF) THEN
        IF(SORLEO(16)) THEN
          CALL VITFON(STRA59%R,XF1,SXK%R,SDEPTH%R,SDFR%R,NF,
     &                NPOIN2,NPLAN,STRA39%R)
        ENDIF
      ENDIF
!
!     ------------------------------- VARIANCE
!
      IF(SORLEO(1).OR.SORLEO(2)) THEN
        CALL TOTNRJ
     &( STRA37%R , XF1   , SFR%R  , SDFR%R , TAILF ,
     &  NF  , NPLAN , NPOIN2)
!
!     ------------------------------- SIGNIFICANT WAVE HEIGHT
!
        IF(SORLEO(2)) THEN
          DO IP=1,NPOIN2
            TRA38(IP)=4.D0*SQRT(TRA37(IP))
          ENDDO
        ENDIF
      ENDIF
!
!     ------------------------------- POWER PER UNIT LENGTH
!
      IF(SORLEO(34)) THEN
        CALL WPOWER(STRA60%R,XF1,SFR%R,SDFR%R,SCG%R,TAILF,NF,
     &              NPLAN,NPOIN2,ROEAU)
      ENDIF
!     ------------------------------- KMOYEN AND QMOUT1
!
      IF(SORLEO(17)) THEN
        CALL KMOYEN(SPRIVE%R,SXK%R,SF%R,SFR%R,SDFR%R,TAILF,NF,NPLAN,
     &              NPOIN2,AUX1,AUX2,AUX3)
!        CALL QMOUT1(SPRIVE2%R,TSDER,SF%R,SXK%R,STRA37%R,SFR%R,
!     &              STRA33%R,SPRIVE1%R,PROINF,CMOUT1,CMOUT2,NF,NPLAN,
!     &              NPOIN2,TAUX1,BETA,SDEPTH%R)
      ENDIF

!
!-----------------------------------------------------------------------
!
      RETURN
      END
