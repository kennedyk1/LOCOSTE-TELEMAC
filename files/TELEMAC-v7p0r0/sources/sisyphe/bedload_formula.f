! CV :XKV not used - à supprimer
!                    **************************
                     SUBROUTINE BEDLOAD_FORMULA
!                    **************************
!
     &(U2D,V2D,UCMOY,HN,CF,MU,TOB,TOBW,UW,TW,THETAW,FW,
     & ACLADM, UNLADM,KSP,KSR,AVA,NPOIN,ICF,HIDFAC,XMVS,XMVE,
     & DM,GRAV,VCE,HMIN,XWC,D90,KARMAN,ZERO,
     & PI,SUSP, AC, HIDING, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10,
     & T11,TETAP, QSC, QSS,IELMT,SECCURRENT,SLOPEFF,
     & COEFPN,BIJK,HOULE)
!
!***********************************************************************
! SISYPHE   V6P2                                   21/07/2011
!***********************************************************************
!
!brief    COMPUTES THE BED-LOAD TRANSPORT.
!
!history  BUI MINH DUC
!+        **/01/2002
!+        V5P2
!+
!
!history  C. VILLARET
!+        **/10/2003
!+        V5P4
!+
!
!history  F. HUVELIN
!+        12/01/2005
!+        V5P6
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
!history  C.VILLARET (EDF-LNHE), P.TASSI (EDF-LNHE)
!+        19/07/2011
!+        V6P1
!+  Name of variables   
!+ 
!history  J-M HERVOUET (EDF-LNHE)
!+        27/02/2012
!+        V6P2
!+  ALPHA suppressed, was no longer used   
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| AC             |<->| SHIELDS PARAMETER
!| ACLADM         |-->| MEAN DIAMETER
!| AVA            |-->| PERCENT AVAILABLE
!| BIJK           |-->| EMPIRICAL COEFFICIENT
!| CF             |-->| QUADRATIC FRICTION COEFFICIENT
!| COEFPN         |-->| COEFFICIENT FOR SLOPING BED EFFECTS
!| D90            |-->| D90
!| DM             |-->| DIAMETER OF THE CLASS
!| FW             |-->| WAVE FRICTION COEFFICIENT
!| GRAV           |-->| GRAVITY
!| HIDFAC         |-->| HIDING FACTOR FORMULA
!| HIDING         |<->| HIDING FACTOR 
!| HMIN           |-->| MININMUM WATER DEPTH
!| HN             |-->| WATER DEPTH
!| HOULE          |-->| EFFECT OF WAVE 
!| ICF            |-->| CHOICE OF FORMULA
!| IELMT          |-->| NUMBER OF ELEMENTS
!| KARMAN         |-->| VON KARMAN COEFFICIENT
!| KSP            |-->| SKIN BED ROUGHNESS (M)
!| KSR            |-->| RIPPLE BED ROUGHNESS (M)
!| MU             |-->| CORRECTION FOR SKIN FRICTION
!| NPOIN          |-->| NUMBER OF POINTS
!| PI             |-->| PI
!| QSC            |<->| BED LOAD TRANSPORT RATE (m2/S)
!| QSS            |<->| SUSPENDED LOAD TRANSPORT RATE (M2/S)
!| SECCURRENT     |-->| EFFECT OF SECUNDARY CURRENTS 
!| SLOPEFF        |-->| FORMULA FOR SLOPING BED EFFECTS
!| SUSP           |-->| SUSPENSION TREATMENT 
!| T1             |<->| WORKING ARRAYS
!| T10            |<->| --
!| T11            |<->| --
!| T2             |<->| --
!| T3             |<->| --
!| T4             |<->| --
!| T5             |<->| --
!| T6             |<->| --
!| T7             |<->| --
!| T8             |<->| --
!| T9             |<->| --
!| TETAP          |<->| ADIMENSIONAL SKIN FRICTION 
!| THETAW         |-->| WAVE/CURRENT ANGLE 
!| TOB            |-->| TOTAL BED SHEAR STRESS (N/M2)
!| TOBW           |-->| WAVE INDUCED BED SHEAR STRESS (N/M2)
!| TW             |-->| WAVE PERIOD (S)
!| U2D            |-->| LONGITUDINAL VELOCITY (m/S)
!| UCMOY          |-->| CURRENT INTENSITY (M/S)
!| UNLADM         |-->| DIAMETER OF LAYER 2 (M)
!| UW             |-->| WAVE ORBITAL VELOCITY (M/S)
!| V2D            |-->| TRANSVERSAL VELOCITY (M/S)
!| VCE            |-->| FLUID KINEMATIC VISCOSITY (M2/S)
!| XMVE           |-->| FLUID DENSITY (KG/M3)
!| XMVS           |-->| SEDIMENT DENSITY (KG/M3)
!| XWC            |-->| SETTLING VELOCITY (M/S)
!| ZERO           |-->| ZERO
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE INTERFACE_SISYPHE,EX_BEDLOAD_FORMULA => BEDLOAD_FORMULA
      USE BIEF
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      TYPE(BIEF_OBJ),   INTENT(IN)    :: U2D, V2D, UCMOY,HN, CF, TOB
      TYPE(BIEF_OBJ),   INTENT(IN)    :: MU,TOBW, UW, TW, THETAW, FW
      TYPE(BIEF_OBJ),   INTENT(IN)    :: ACLADM,UNLADM,KSR,KSP
      INTEGER,          INTENT(IN)    :: NPOIN, ICF, HIDFAC,IELMT
      DOUBLE PRECISION, INTENT(IN)    :: XMVS, XMVE, DM, GRAV, VCE
      DOUBLE PRECISION, INTENT(IN)    :: HMIN, XWC, D90
      DOUBLE PRECISION, INTENT(IN)    :: KARMAN, ZERO, PI
      LOGICAL,          INTENT(IN)    :: SUSP,SECCURRENT,HOULE
      DOUBLE PRECISION, INTENT(INOUT) :: AC
      TYPE(BIEF_OBJ),   INTENT(INOUT) :: HIDING
      TYPE(BIEF_OBJ),   INTENT(INOUT) :: T1, T2, T3, T4, T5, T6, T7
      TYPE(BIEF_OBJ),   INTENT(INOUT) :: T8, T9, T10,T11
      TYPE(BIEF_OBJ),   INTENT(INOUT) :: TETAP ! WORK ARRAY T12
      TYPE(BIEF_OBJ),   INTENT(INOUT) :: QSC, QSS
      TYPE(BIEF_OBJ),   INTENT(INOUT) ::  COEFPN
      INTEGER,          INTENT(IN)    :: SLOPEFF
!
      DOUBLE PRECISION, INTENT (IN) :: BIJK,AVA(NPOIN)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER                     :: I
      DOUBLE PRECISION            :: DENS,DSTAR
      DOUBLE PRECISION, PARAMETER :: ZERO_LOCAL = 1.D-6
      DOUBLE PRECISION            :: C1
!
!======================================================================!
!======================================================================!
!                               PROGRAM                                !
!======================================================================!
!======================================================================!
!
      ! *************************** !
      ! I - ADIMENSIONAL PARAMETERS !
      ! *************************** !
      DENS  = (XMVS - XMVE )/ XMVE
      DSTAR = DM*(GRAV*DENS/VCE**2)**(1.D0/3.D0)
      ! ************************ !
      ! II -  SKIN FRICTION      !
      ! ************************ !
!
      C1 = 1.D0/(DENS*XMVE*GRAV*DM)
      CALL OS('X=CYZ   ', X=TETAP, Y=TOB,Z=MU,  C=C1)
      CALL OS('X=+(Y,C)', X= TETAP,Y=TETAP, C=ZERO_LOCAL)
!
      IF(SECCURRENT) CALL BEDLOAD_SECCURRENT(IELMT)
      ! ****************************************** !
      ! IV - COMPUTES 2 TRANSPORT TERMS            !
      !      QSS : SUSPENSION                      !
      !      QSC : BEDLOAD                         !
      ! ****************************************** !
      ! ===================================== !
      ! IV(1) - MEYER-PETER-MULLER FORMULATION!
      !         FOR BEDLOAD ONLY              !
      ! ===================================== !
      IF(ICF == 1) THEN
!
        CALL BEDLOAD_MEYER(TETAP,HIDING,HIDFAC,DENS,GRAV,DM,AC,
     &                     T1,QSC,SLOPEFF,COEFPN)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)
        ENDDO
!
      ! =========================== !
      ! IV(2) - EINSTEIN FORMULATION!
      !         FOR BEDLOAD ONLY    !
      ! =========================== !
      ELSEIF(ICF == 2) THEN
        CALL BEDLOAD_EINST(TETAP,NPOIN,DENS,GRAV,DM,DSTAR,QSC)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! =================================== !
      ! IV(30) - ENGELUND-HANSEN FORMULATION!
      !          FOR TOTAL TRANSPORT        !
      ! =================================== !
      ELSEIF(ICF == 30) THEN
! V6P0 MU IS USED INSTEAD OF CF
! BEWARE: DIFFERENCES
!         CALL BEDLOAD_ENGEL(TETAP,DENS,GRAV,DM,QSC)
! BACK TO EARLIER VERSION OF BEDLOAD_ENGEL
        CALL BEDLOAD_ENGEL(TOB,CF,DENS,GRAV,DM,XMVE,T1,QSC)
!       ARBITRARY DISTRIBUTION
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ======================================== !
      ! IV(3) - ENGELUND-HANSEN FORMULATION      !
      !         MODIFIED: CHOLLET ET CUNGE       !
      !         FOR TOTAL TRANSPORT              !
      ! ======================================== !
      ELSEIF(ICF == 3) THEN
!       KSP IS USED INSTEAD OF CFP
        CALL BEDLOAD_ENGEL_CC
     &       (TETAP,CF,NPOIN,GRAV,DM,DENS,T1,QSC)
!       ARBITRARY DISTRIBUTION
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ============================== !
      ! IV(4) - BIJKER FORMULATION     !
      !         FOR BEDLOAD + SUSPENSION !
      ! ============================== !
      ELSEIF (ICF == 4) THEN
        CALL BEDLOAD_BIJKER
     &   (TOBW,TOB,MU,KSP,KSR,HN,NPOIN,DM,DENS,XMVE,GRAV,
     &    XWC,KARMAN,ZERO,T4,T7,T8,T9,QSC,QSS,BIJK,HOULE)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
          QSS%R(I)=QSS%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ============================== !
      ! IV(5) - SOULSBY FORMULATION    !
      !         FOR BEDLOAD + SUSPENSION !
      ! ============================== !
      ELSEIF (ICF == 5) THEN
        CALL BEDLOAD_SOULSBY
     &       (UCMOY,HN,UW,NPOIN,DENS,GRAV,DM,DSTAR,HMIN,
     &        D90,QSC,QSS)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
          QSS%R(I)=QSS%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ================================================== !
      ! IV(6) - HUNZIKER / MEYER-PETER & MULLER FORMULATION!
      !         FOR BEDLOAD ONLY                           !
      ! ================================================== !
      ELSEIF (ICF == 6) THEN
        CALL BEDLOAD_HUNZ_MEYER
     &       (TOB, MU, ACLADM, UNLADM, NPOIN, DENS, XMVE, GRAV,
     &        DM, AC, T1, T2, T3, HIDING, QSC)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)
        ENDDO
!
      ! =========================== !
      ! IV(7) - VAN RIJN FORMULATION!
      !         FOR BEDLOAD ONLY    !
      ! =========================== !
      ELSEIF (ICF == 7) THEN
!
        CALL BEDLOAD_VANRIJN
!     &       (TOB,MU,NPOIN,DM,DENS,GRAV,DSTAR,AC,QSC)
     &       (TETAP,MU,NPOIN,DM,DENS,GRAV,DSTAR,AC,QSC)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ============================== !
      ! IV(8) - BAILARD FORMULATION    !
      !         FOR BEDLOAD + SUSPENSION !
      ! ============================== !
      ELSEIF (ICF == 8) THEN
!
        CALL BEDLOAD_BAILARD
     &       (U2D,V2D,UCMOY,TOB,TOBW,THETAW,UW,FW,CF,NPOIN,
     &        PI,XMVE,GRAV,DENS,XWC,T1,T2,T3,T4,T5,T6,T7,
     &        T8,T9,T10,T11,QSC,QSS,HOULE)
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
          QSS%R(I)=QSS%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ======================================= !
      ! IV(9) - DIBAJNIA AND WATANABE FORMULATION!
      !         FOR TOTAL TRANSPORT             !
      ! ======================================= !
      ELSEIF(ICF == 9) THEN
!
        CALL BEDLOAD_DIBWAT
     &       (U2D,V2D,UCMOY, CF, TOB, TOBW, UW, TW, FW, THETAW,
     &        NPOIN, XMVE, DENS, GRAV, DM, XWC, PI, T1, T2, T3, T4,
     &        T5, T6, T7, T8, T9, T10, T11, QSC,HOULE)
!       ARBITRARY DISTRIBUTION
        DO I=1,NPOIN
          QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
!
      ! ============================================ !
      ! IV(0) - USER-DEFINED FORMULATION             !
      ! ============================================ !
      ELSEIF (ICF == 0) THEN
        CALL QSFORM
     &       (U2D, V2D, TOB, HN, XMVE, TETAP, MU, NPOIN, DM, 
     &       DENS, GRAV, DSTAR, AC, QSC, QSS)
        DO I=1,NPOIN
           QSC%R(I)=QSC%R(I)*AVA(I)*HIDING%R(I)
           QSS%R(I)=QSS%R(I)*AVA(I)*HIDING%R(I)
        ENDDO
      ! ================= !
      ! IV(ELSE) - ERROR  !
      ! ================= !
      ELSE
        IF(LNG == 1) WRITE(LU,200) ICF
        IF(LNG == 2) WRITE(LU,201) ICF
200     FORMAT(1X,'TRANSP : FORMULE DE TRANSPORT INCONNUE :',1I6)
201     FORMAT(1X,'TRANSP : TRANSPORT FORMULA UNKNOWN:',1I6)
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!     WHEN SUSPENSION IS NOT ASKED SPECIFICALLY, SOME BEDLOAD TRANSPORT
!     FORMULAS GIVE A VALUE
!
      IF(.NOT.SUSP) THEN
        IF(ICF.EQ.4.OR.ICF.EQ.5.OR.ICF.EQ.8.OR.ICF.EQ.0) THEN
          DO I = 1,NPOIN
            QSC%R(I) = QSC%R(I) + QSS%R(I)
          ENDDO
        ELSE
!         NOTE JMH: IS THIS REALLY USEFUL ???
          DO I = 1,NPOIN
            QSS%R(I) = 0.D0
          ENDDO
        ENDIF
      ENDIF
!
!=======================================================================
!=======================================================================
!
      RETURN
      END
