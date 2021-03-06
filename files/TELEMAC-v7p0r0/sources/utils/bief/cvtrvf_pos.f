!                    *********************
                     SUBROUTINE CVTRVF_POS
!                    *********************
!
     &(F,FN,FSCEXP,DIFT,CONV,H,HN,HPROP,UDEL,VDEL,DM1,ZCONV,SOLSYS,
     & VISC,VISC_S,SM,SMH,YASMH,SMI,YASMI,FBOR,MASKTR,MESH,
     & T1,T2,T3,T4,T5,T6,T7,T8,HNT,HT,AGGLOH,TE1,DT,ENTET,BILAN,
     & OPDTRA,MSK,MASKEL,S,MASSOU,OPTSOU,LIMTRA,KDIR,KDDL,NPTFR,FLBOR,
     & YAFLBOR,V2DPAR,UNSV2D,IOPT,FLBORTRA,MASKPT,GLOSEG1,GLOSEG2,NBOR,
     & OPTION,FLULIM,YAFLULIM,RAIN,PLUIE,TRAIN,GIVEN_FLUX,FLUX_GIVEN,
     & NITMAX)
!
!***********************************************************************
! BIEF   V7P0                                     13/06/2014
!***********************************************************************
!
!brief    FINITE VOLUMES, UPWIND, EXPLICIT AND MONOTONIC
!+                ADVECTOR EVEN WITH TIDAL FLATS.
!
!warning  AFBOR AND BFBOR MUST BE 0 FOR THE BOUNDARY ELEMENTS
!+            WITH NO FRICTION
!warning  DISCRETISATION OF VISC
!
!warning  SEE BELOW FOR DEFIITION OF IOPT1 AND IOPT2, RETRIEVED FROM IOPT  
!+        IOPT2=1 NOT TREATED HERE, MASS-CONSERVATION WILL BE DOWNGRADED
!+        IN THIS CASE (A CORRECT TREATMENT MAY RESULT IN INFINITE F)
!+        THE PROGRAM WILL NOT STOP IF IOPT2=1
!
!history  J-M HERVOUET   (LNHE)
!+        19/11/2010
!+        V6P0
!+   OPTIMIZATION (2 ABS SUPPRESSED)
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
!history  J-M HERVOUET   (LNHE)
!+        20/04/2011
!+        V6P1
!+   Option IOPT2=1 taken into account when there is an implicit source
!+   term. In other cases mass-conservation is not ensured (risk of 
!+   division by 0). The implicit source must be negative, like settling
!+   velocity in Sisyphe. It is impossible to have mass conservation and
!+   monotonicity when the advection field does not obey the continuity
!+   equation. The only known application so far is Sisyphe.
!+  
!+   Limitation of fluxes now programmed (see YAFLULIM and FLULIM)
!
!history  J-M HERVOUET (LNHE)
!+        24/02/2012
!+        V6P2
!+   Rain and evaporation added (after initiative by O. Boutron, from
!+   Tour du Valat, and O. Bertrand, Artelia group)
!
!history  J-M HERVOUET   (LNHE)
!+        17/07/2012
!+        V6P2
!+   T2 set to 0 to start with required in parallel
!+   Arguments flux_given and given_flux added.
!
!history  J-M HERVOUET   (LNHE)
!+        16/04/2013
!+        V6P2
!+   Intent of FLBOR changed and conditional building of FLBOR added
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        30/05/2013
!+        V6P2
!+   Argument NITMAX added.
!
!history  J-M HERVOUET (EDF LAB, LNHE)
!+        13/06/2014
!+        V7P0
!+   LIMTRA and FBOR corrected depending on the fluxes at boundaries,
!+   their intent modified accordingly.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| AGGLOH         |-->| MASS-LUMPING UTILISE DANS L'EQUATION DE CONTINUITE
!| BILAN          |-->| LOGICAL TRIGGERING A MASS BALANCE INFORMATION
!| CONV           |-->| LOGICAL, IF YES THERE IS ADVECTION OF F
!| DIFT           |-->| LOGICAL, IF YES THERE IS DIFFUSION OF F
!| DM1            |-->| THE PIECE-WISE CONSTANT PART OF ADVECTION FIELD
!|                |   | IS DM1*GRAD(ZCONV), SEE SOLSYS.
!| DT             |-->| TIME STEP
!| ENTET          |-->| LOGICAL, IF YES INFORMATION IS GIVEN ON MASS
!|                |   | CONSERVATION.
!| F              |<--| F AT TIME T(N+1)
!| FBOR           |-->| DIRICHLET CONDITIONS ON F.
!| FLBOR          |-->| FLUXES AT BOUNDARIES
!| FLBORTRA       |<->| TRACER FLUXES AT BOUNDARIES
!| FLUX_GIVEN     |-->| IF GIVEN_FLUX=YES, THE FLUX IS GIVEN IN
!|                |   | GIVEN_FLUX
!| FN             |-->| F AT TIME T(N)
!| FSCEXP         |-->| EXPLICIT PART OF THE SOURCE TERM
!|                |   | EQUAL TO ZERO EVERYWHERE BUT ON SOURCES
!|                |   | WHERE THERE IS FSCE - (1-TETAT) FN
!|                |   | SEE DIFSOU
!| GIVEN_FLUX     |-->| IF GIVEN_FLUX=YES, THE FLUX IS GIVEN IN
!|                |   | GIVEN_FLUX AND WILL NOT BE COMPUTED HERE
!| GLOSEG1        |-->| FIRST POINT OF SEGMENTS
!| GLOSEG2        |-->| SECOND POINT OF SEGMENTS
!| HNT,HT         |<--| WORK ARRAYS (MODIFIED DEPTHS TO TAKE MASS-LUMPING
!|                |   | INTO ACCOUNT)
!| HPROP          |-->| PROPAGATION DEPTH (DONE IN CVDFTR).
!| IOPT           |-->| OPTIONS FOR COMPUTATION (NUMBER BETWEEN 0 AND 13)
!|                |   | THE TENS (IOPT2, I.E. 0 OR 1):
!|                |   | 0: UCONV OBEYS THE CONTINUITY EQUATION
!|                |   | 1: UCONV DOES NOT OBEY THE CONTINUITY EQUATION
!|                |   | THE UNITS (IOPT1, I.E. 0 TO 3): VARIANT FOR FLUXES
!|                |   | 0: CONSTANT PER ELEMENT = 0
!|                |   | 1: CHI-TUAN PHAM'S CONSTANT
!|                |   | 2: N SCHEME
!|                |   | 3: PSI SCHEME
!| KDDL           |-->| CONVENTION FOR DEGREE OF FREEDOM
!| KDIR           |-->| CONVENTION FOR DIRICHLET POINT
!| LIMTRA         |-->| BOUNDARY CONDITIONS ON BOOUNDARY POINTS
!| MASKEL         |-->| MASKING OF ELEMENTS
!|                |   | =1. : NORMAL   =0. : MASKED ELEMENT
!| MASKPT         |-->| MASKING PER POINT.
!| MASSOU         |-->| MASS OF TRACER ADDED BY SOURCE TERM
!|                |   | SEE DIFSOU
!| MESH           |-->| MESH STRUCTURE
!| MSK            |-->| IF YES, THERE IS MASKED ELEMENTS.
!| NBOR           |-->| GLOBAL NUMBERS OF BOUNDARY POINTS
!| NITMAX         |-->| MAXIMUM NUMBER OF ITERATIONS
!| NPTFR          |-->| NUMBER OF BOUNDARY POINTS
!| OPDTRA         |-->| OPTION FOR THE DIFFUSION OF TRACERS
!| OPTION         |-->| OPTION OF ALGORITHM FOR EDGE-BASED ADVECTION
!|                |   | 1: FAST BUT SENSITIVE TO SEGMENT NUMBERING
!|                |   | 2: INDEPENDENT OF SEGMENT NUMBERING
!| OPTSOU         |-->| TYPE OF SOURCES
!|                |   | 1: NORMAL
!|                |   | 2: DIRAC
!| PLUIE          |-->| RAIN OR EVAPORATION, IN M/S
!| RAIN           |-->| IF YES: RAIN OR EVAPORATION
!| S              |-->| VOID STRUCTURE
!| SM             |-->| SOURCE TERMS.
!| SMH            |-->| SOURCE TERM IN CONTINUITY EQUATION
!| SMI            |-->| IMPLICIT SOURCE TERM
!| SOLSYS         |-->| 1 OR 2. IF 2 ADVECTION FIELD IS UCONV + DM1*GRAD(ZCONV)
!| T1             |<->| WORK BIEF_OBJ STRUCTURE
!| T2             |<->| WORK BIEF_OBJ STRUCTURE
!| T3             |<->| WORK BIEF_OBJ STRUCTURE
!| T4             |<->| WORK BIEF_OBJ STRUCTURE
!| T5             |<->| WORK BIEF_OBJ STRUCTURE
!| T6             |<->| WORK BIEF_OBJ STRUCTURE
!| T7             |<->| WORK BIEF_OBJ STRUCTURE
!| T8             |<->| WORK BIEF_OBJ STRUCTURE
!| TE1            |<->| WORK BIEF_OBJ STRUCTURE FOR ELEMENTS
!| TRAIN          |-->| VALUE OF TRACER IN THE RAIN
!| UDEL           |-->| X-COMPONENT OF ADVECTION VELOCITY
!| UNSV2D         |-->| INVERSE OF V2DPAR
!| V2DPAR         |-->| INTEGRAL OF 2D TEST FUNCTIONS, ASSEMBLED
!|                |   | IN PARALLEL.
!| VDEL           |-->| X-COMPONENT OF ADVECTION VELOCITY
!| VISC           |-->| VISCOSITY COEFFICIENTS ALONG X,Y AND Z .
!|                |   | IF P0 : PER ELEMENT
!|                |   | IF P1 : PERR POINT
!| VISC_S         |<->| WORK ARRAY FOR SAVING VISC
!| YAFLBOR        |-->| IF YES FLBOR IS GIVEN
!| YASMH          |-->| IF YES, SMH MUST BE TAKEN INTO ACCOUNT
!| YASMI          |-->| IF YES, SMI MUST BE TAKEN INTO ACCOUNT
!| ZCONV          |-->| THE PIECE-WISE CONSTANT PART OF ADVECTION FIELD
!|                |   | IS DM1*GRAD(ZCONV), SEE SOLSYS.
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF, EX_CVTRVF_POS => CVTRVF_POS
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)             :: OPDTRA,OPTSOU,KDIR,NPTFR,SOLSYS
      INTEGER, INTENT(IN)             :: KDDL,IOPT,OPTION,NITMAX
      INTEGER, INTENT(IN)             :: GLOSEG1(*),GLOSEG2(*)
      INTEGER, INTENT(IN)             :: NBOR(NPTFR)
      INTEGER, INTENT(INOUT)          :: LIMTRA(NPTFR)
!                                                               NSEG
      DOUBLE PRECISION, INTENT(IN)    :: DT,AGGLOH,TRAIN,FLULIM(*)
      DOUBLE PRECISION, INTENT(INOUT) :: MASSOU
      LOGICAL, INTENT(IN)             :: BILAN,CONV,YASMH,YAFLBOR,RAIN
      LOGICAL, INTENT(IN)             :: DIFT,MSK,ENTET,YASMI,YAFLULIM
      LOGICAL, INTENT(IN)             :: FLUX_GIVEN
      TYPE(BIEF_OBJ), INTENT(IN)      :: MASKEL,H,HN,DM1,ZCONV,MASKPT
      TYPE(BIEF_OBJ), INTENT(IN)      :: V2DPAR,UNSV2D,HPROP
      TYPE(BIEF_OBJ), INTENT(INOUT)   :: F,SM,HNT,HT
      TYPE(BIEF_OBJ), INTENT(IN)      :: UDEL,VDEL,FN,SMI,SMH
      TYPE(BIEF_OBJ), INTENT(INOUT)   :: TE1,FLBORTRA,FBOR
      TYPE(BIEF_OBJ), INTENT(INOUT)   :: T1,T2,T3,T4,T5,T6,T7,T8
      TYPE(BIEF_OBJ), INTENT(IN)      :: FSCEXP,S,MASKTR
      TYPE(BIEF_OBJ), INTENT(INOUT)   :: FLBOR
      TYPE(BIEF_OBJ), INTENT(IN)      :: VISC_S,VISC,PLUIE,GIVEN_FLUX
      TYPE(BIEF_MESH)                 :: MESH
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      DOUBLE PRECISION P_DSUM,P_DMIN,P_DMAX
      EXTERNAL         P_DSUM,P_DMIN,P_DMAX
!
      INTEGER I,IOPT1,IOPT2,NPOIN,IPTFR,I1,I2,NITER,REMAIN_SEG,NEWREMAIN
      INTEGER IR,N
!
!-----------------------------------------------------------------------
!
      DOUBLE PRECISION C,CPREV,CINIT,HFL1,HFL2,TET,H1N,H2N,HSEG1,HSEG2
      CHARACTER(LEN=16) FORMUL
      DOUBLE PRECISION, POINTER, DIMENSION(:) :: FXMAT
      LOGICAL TESTING
      DATA TESTING/.FALSE./
      DOUBLE PRECISION EPS_FLUX
      DATA             EPS_FLUX/1.D-15/
!
!-----------------------------------------------------------------------
!
!     INDIC WILL BE A LIST OF SEGMENTS WITH NON ZERO FLUXES
!
      LOGICAL DEJA
      DATA DEJA/.FALSE./
      INTEGER, ALLOCATABLE          :: INDIC(:)
      SAVE
      IF(.NOT.DEJA) THEN
        ALLOCATE(INDIC(MESH%NSEG))
        DEJA=.TRUE.
      ENDIF
!
!-----------------------------------------------------------------------
!
      FXMAT=>MESH%MSEG%X%R(1:MESH%NSEG)
!
!-----------------------------------------------------------------------
!
      NPOIN=H%DIM1
!
!     EXTRACTING OPTIONS, AND CONTROL
!
      IOPT2=IOPT/10
      IOPT1=IOPT-10*IOPT2
      IF(IOPT1.LT.0.OR.IOPT1.GT.3) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'CVTRVF_POS : OPTION IOPT1 INCONNUE : ',IOPT1
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'CVTRVF_POS: OPTION IOPT1 UNKNOWN: ',IOPT1
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
      IF(IOPT2.NE.0.AND.IOPT2.NE.1) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'CVTRVF_POS : OPTION IOPT2 INCONNUE : ',IOPT2
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'CVTRVF_POS: OPTION IOPT2 UNKNOWN: ',IOPT2
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!     STARTING AGAIN FROM NON CORRECTED DEPTH
!
      IF(TESTING) THEN
        C=1.D99
        CINIT=1.D99
        DO I=1,NPOIN
          C    =MIN(C    ,H%R(I))
          CINIT=MIN(CINIT,HN%R(I))
        ENDDO
        IF(NCSIZE.GT.1) THEN
          C=P_DMIN(C)
          CINIT=P_DMIN(CINIT)
        ENDIF
        WRITE(LU,*) 'AVANT TRAITEMENT HAUTEURS NEGATIVES, H MIN=',C
        WRITE(LU,*) 'AVANT TRAITEMENT HAUTEURS NEGATIVES, HN MIN=',CINIT
      ENDIF
!
!     CALCUL DES FLUX PAR NOEUDS
!
      IF(.NOT.FLUX_GIVEN) THEN
!
      FORMUL='HUGRADP         '
      IF(SOLSYS.EQ.2) FORMUL(8:8)='2'
      CALL VECTOR(T1,'=',FORMUL,H%ELM,-1.D0,
     &            HPROP,DM1,ZCONV,UDEL,VDEL,VDEL,MESH,MSK,MASKEL)
!                 T1 AS HUGRADP IS NOT USED AS AN ASSEMBLED VECTOR
!                 BUT TO GET THE NON ASSEMBLED FORM MESH%W
!     CALCUL DES FLUX PAR SEGMENT (TE1 SUIVI DE FALSE NON UTILISE)
!     FXMAT IS NOT ASSEMBLED IN //
!
!----------------------------------------
! DIFFERENT OPTIONS TO COMPUTE THE FLUXES
!----------------------------------------
!
      CALL FLUX_EF_VF(FXMAT,MESH%W%R,MESH%NSEG,MESH%NELEM,
     &                MESH%ELTSEG%I,MESH%ORISEG%I,
     &                MESH%IKLE%I,.TRUE.,IOPT1)
!
!-----------------------------------------------------
! LIMITATION OF FLUXES (IF REQUESTED, USED BY SISYPHE)
!-----------------------------------------------------
!
      IF(YAFLULIM) THEN
        DO I=1,MESH%NSEG
          FXMAT(I)=FXMAT(I)*FLULIM(I)
        ENDDO  
      ENDIF
!
      ELSE
        DO I=1,MESH%NSEG
          FXMAT(I)=GIVEN_FLUX%R(I)
        ENDDO  
      ENDIF
!
!----------------------------------------
!
!     AVERAGING FLUXES ON INTERFACE SEGMENTS BY ASSEMBLING AND
!     DIVIDING BY 2. THIS WILL GIVE THE UPWINDING INFORMATION
!
      IF(NCSIZE.GT.1) THEN
        CALL PARCOM2_SEG(FXMAT,FXMAT,FXMAT,MESH%NSEG,1,2,1,MESH,
     &                   1,11)
        CALL MULT_INTERFACE_SEG(FXMAT,MESH%NH_COM_SEG%I,
     &                          MESH%NH_COM_SEG%DIM1,
     &                          MESH%NB_NEIGHB_SEG,
     &                          MESH%NB_NEIGHB_PT_SEG%I,
     &                          0.5D0,MESH%NSEG)
      ENDIF
!
!----------------------------------------
! END OF THE OPTIONS
!----------------------------------------
!
      CALL CPSTVC(H,T2)
!     T2 WILL BE THE ASSEMBLED FLBOR, INITIALISATION HERE
!     IS USELESS EXCEPT THAT PARCOM MAY ADD UNDEFINED
!     NUMBERS (THAT WILL NOT BE USED BUT THAT WILL STOP
!     A COMPILER... TOO BAD!)
      IF(NCSIZE.GT.1) CALL OS('X=0     ',X=T2)
!
!     INITIALIZING F AT THE OLD VALUE
!
      CALL OS('X=Y     ',X=F,Y=FN)
!
      CPREV=0.D0
      DO I=1,MESH%NSEG
        CPREV=CPREV+ABS(FXMAT(I))
      ENDDO
      IF(NCSIZE.GT.1) CPREV=P_DSUM(CPREV)
      CINIT=CPREV
      IF(TESTING) WRITE(LU,*) 'SOMME INITIALE DES FLUX=',CPREV
!
!     BOUCLE SUR LES SEGMENTS, POUR PRENDRE EN COMPTE LES FLUX
!     ADMISSIBLES
!
!     ADDING THE SOURCES (SMH IS NATURALLY ASSEMBLED IN //)
      IF(YASMH) THEN
        IF(OPTSOU.EQ.1) THEN
          DO I=1,NPOIN
            HT%R(I)=HN%R(I)+DT*SMH%R(I)
            F%R(I)=FN%R(I)+DT/MAX(HT%R(I),1.D-4)*SMH%R(I)*FSCEXP%R(I)
          ENDDO
        ELSEIF(OPTSOU.EQ.2) THEN
          DO I=1,NPOIN
            HT%R(I)=HN%R(I)+DT*SMH%R(I)*UNSV2D%R(I)
            F%R(I)=FN%R(I)+DT/MAX(HT%R(I),1.D-4)*
     &                       UNSV2D%R(I)*SMH%R(I)*FSCEXP%R(I)
          ENDDO
        ENDIF
      ELSE
        DO I=1,NPOIN
          HT%R(I)=HN%R(I)
        ENDDO
      ENDIF
!
!     RAIN-EVAPORATION: RAIN FIRST, EVAPORATION IN THE END
!
      IF(RAIN) THEN
        DO I=1,NPOIN
          C=MAX(PLUIE%R(I),0.D0)
          HT%R(I)=HT%R(I)+DT*C
!                                                VALUE IN RAIN
          F%R(I)=F%R(I)+DT/MAX(HT%R(I),1.D-4)*C*(TRAIN-F%R(I))
        ENDDO       
      ENDIF
!
      IF(.NOT.YAFLBOR) THEN
!       MASK=8 FOR LIQUID BOUNDARIES
        CALL VECTOR(FLBOR,'=','FLUBDF          ',1,1.D0,
     &              HPROP,HPROP,HPROP,
     &              UDEL , VDEL, VDEL,MESH,.TRUE.,MASKTR%ADR(8)%P)
      ENDIF
!
!     BOUNDARY FLUXES : ADDING THE ENTERING (NEGATIVE) FLUXES
!     FIRST PUTTING FLBOR (BOUNDARY) IN T2 (DOMAIN)
      CALL OSDB( 'X=Y     ' ,T2,FLBOR,FLBOR,0.D0,MESH)
!     ASSEMBLING T2 (FLBOR IS NOT ASSEMBLED)
      IF(NCSIZE.GT.1) CALL PARCOM(T2,2,MESH)
!     POSSIBLE CORRECTION OF LIMTRA AND FBOR (LIMTRA HAS BEEN DONE BY
!     DIFFIN WITH U.N)
      DO I=1,MESH%NPTFR
        N=MESH%NBOR%I(I)
        IF(LIMTRA(I).EQ.KDIR.AND.T2%R(N).GT.0.D0) THEN
          LIMTRA(I)=KDDL
        ELSEIF(LIMTRA(I).EQ.KDDL.AND.T2%R(N).LT.0.D0) THEN
          LIMTRA(I)=KDIR
          FBOR%R(I)=FN%R(N)
        ENDIF
      ENDDO
!
      DO IPTFR=1,NPTFR
        I=NBOR(IPTFR)
        HT%R(I)=HT%R(I)-DT*UNSV2D%R(I)*MIN(T2%R(I),0.D0)
!       ENTERING FLUXES OF TRACERS
!       THE FINAL DEPTH IS TAKEN
        IF(LIMTRA(IPTFR).EQ.KDIR) THEN
          F%R(I)=FN%R(I)-DT/MAX(HT%R(I),1.D-4)*
     &       UNSV2D%R(I)*T2%R(I)*(FBOR%R(IPTFR)-FN%R(I))
        ELSEIF(LIMTRA(IPTFR).EQ.KDDL) THEN
!         FLBORTRA IS NOT ASSEMBLED
          FLBORTRA%R(IPTFR)=FLBOR%R(IPTFR)*FN%R(I)
        ENDIF
      ENDDO
!
!     FOR OPTIMIZING THE LOOP ON SEGMENTS, ONLY SEGMENTS
!     WITH NON ZERO FLUXES WILL BE CONSIDERED, THIS LIST
!     WILL BE UPDATED. TO START WITH, ALL FLUXES ASSUMED NON ZERO
!
      REMAIN_SEG=MESH%NSEG
      DO I=1,REMAIN_SEG
        INDIC(I)=I
      ENDDO
!
      NITER = 0
777   CONTINUE
      NITER = NITER + 1
!
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!     FOR DISTRIBUTING THE DEPTHS BETWEEN SEGMENTS
!
      IF(OPTION.EQ.2) THEN
!
!       T1 : TOTAL FLUX REMOVED OF EACH POINT
!       T4 : DEPTH H SAVED
!       T6 : F SAVED
!
        CALL CPSTVC(H,T1)
        IF(NITER.EQ.1) THEN
          DO I=1,NPOIN
            T1%R(I)=0.D0
            T4%R(I)=HT%R(I)
            T6%R(I)=F%R(I)
            T5%R(I)=HT%R(I)*F%R(I)
          ENDDO
          IF(NCSIZE.GT.1) THEN
            DO IPTFR=1,NPTIR
              I=MESH%NACHB%I(NBMAXNSHARE*(IPTFR-1)+1)
!             AVAILABLE DEPTH IS SHARED BETWEEN PROCESSORS
              HT%R(I)=HT%R(I)*MESH%FAC%R(I)
              T5%R(I)=T5%R(I)*MESH%FAC%R(I)
            ENDDO
          ENDIF
        ELSE
!         NOT ALL THE POINTS NEED TO BE INITIALISED NOW
          DO IR=1,REMAIN_SEG
            I=INDIC(IR)
            I1=GLOSEG1(I)
            I2=GLOSEG2(I)
            T1%R(I1)=0.D0
            T1%R(I2)=0.D0
!           SAVING THE DEPTH AND TRACER
            T4%R(I1)=HT%R(I1)
            T4%R(I2)=HT%R(I2)
            T6%R(I1)=F%R(I1)
            T6%R(I2)=F%R(I2)
            T5%R(I1)=HT%R(I1)*F%R(I1)
            T5%R(I2)=HT%R(I2)*F%R(I2)
          ENDDO
!         CANCELLING INTERFACE POINTS (SOME MAY BE ISOLATED IN A SUBDOMAIN
!         AT THE TIP OF AN ACTIVE SEGMENT WHICH IS ELSEWHERE)
          IF(NCSIZE.GT.1) THEN
            DO IPTFR=1,NPTIR
              I=MESH%NACHB%I(NBMAXNSHARE*(IPTFR-1)+1)
              T1%R(I)=0.D0
!             SAVING THE DEPTH AND TRACER
              T4%R(I)=HT%R(I)
              T6%R(I)=F%R(I)
!             AVAILABLE DEPTH IS SHARED BETWEEN PROCESSORS
              HT%R(I)=HT%R(I)*MESH%FAC%R(I)
              T5%R(I)=T5%R(I)*MESH%FAC%R(I)
            ENDDO
          ENDIF
        ENDIF
        DO IR=1,REMAIN_SEG
          I=INDIC(IR)
          I1=GLOSEG1(I)
          I2=GLOSEG2(I)
          IF(FXMAT(I).GT.EPS_FLUX) THEN
            T1%R(I1)=T1%R(I1)+FXMAT(I)
            HT%R(I1)=0.D0
            T5%R(I1)=0.D0
          ELSEIF(FXMAT(I).LT.-EPS_FLUX) THEN
            T1%R(I2)=T1%R(I2)-FXMAT(I)
            HT%R(I2)=0.D0
            T5%R(I2)=0.D0
          ENDIF
        ENDDO
!
        IF(NCSIZE.GT.1) CALL PARCOM(T1,2,MESH)
!
!       FOR ISOLATED POINTS CONNECTED TO AN ACTIVE SEGMENT
!       THAT IS IN ANOTHER SUBDOMAIN
        IF(NCSIZE.GT.1) THEN
          DO IPTFR=1,NPTIR
            I=MESH%NACHB%I(NBMAXNSHARE*(IPTFR-1)+1)
            IF(T1%R(I).GT.EPS_FLUX) THEN
              HT%R(I)=0.D0
              T5%R(I)=0.D0
            ENDIF
          ENDDO
        ENDIF
!
      ELSEIF(OPTION.EQ.1) THEN
!
!       AT THIS LEVEL H THE SAME AT INTERFACE POINTS
!       THIS IS DONE EVEN FOR OPTION 2, TO ANTICIPATE THE FINAL PARCOM
        IF(NCSIZE.GT.1) THEN
          DO IPTFR=1,NPTIR
!           AVAILABLE DEPTH IS SHARED BETWEEN PROCESSORS
!           NACHB(1,IPTFR) WITH DIMENSION NACHB(NBMAXNSHARE,NPTIR)
            I=MESH%NACHB%I(NBMAXNSHARE*(IPTFR-1)+1)
            HT%R(I)=HT%R(I)*MESH%FAC%R(I)
          ENDDO
        ENDIF
!
      ENDIF
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
      C=0.D0
      NEWREMAIN=0
!
      IF(OPTION.EQ.1) THEN
!
      DO IR=1,REMAIN_SEG
        I=INDIC(IR)
        IF(FXMAT(I).GT.EPS_FLUX) THEN
          I1=GLOSEG1(I)
          I2=GLOSEG2(I)
          HFL1= DT*UNSV2D%R(I1)*FXMAT(I)
          HFL2=-DT*UNSV2D%R(I2)*FXMAT(I)
!         POUR TRACEURS
          H1N=HT%R(I1)
          H2N=HT%R(I2)
!         FIN POUR TRACEURS
          IF(HFL1.GT.HT%R(I1)) THEN
            TET=HT%R(I1)/HFL1
            HT%R(I1)=0.D0
            HT%R(I2)=HT%R(I2)-HFL2*TET
            FXMAT(I)=FXMAT(I)*(1.D0-TET)
            C=C+FXMAT(I)
            NEWREMAIN=NEWREMAIN+1
            INDIC(NEWREMAIN)=I
          ELSE
            HT%R(I1)=HT%R(I1)-HFL1
            HT%R(I2)=HT%R(I2)-HFL2
          ENDIF
!         TRACER (WITH TEST HT%R(I2) CANNOT BE 0.D0)
          IF(H2N.LT.HT%R(I2)) THEN
            F%R(I2)=F%R(I2)+(1.D0-H2N/HT%R(I2))*(F%R(I1)-F%R(I2))
          ENDIF
!         END TRACER
        ELSEIF(FXMAT(I).LT.-EPS_FLUX) THEN
          I1=GLOSEG1(I)
          I2=GLOSEG2(I)
          HFL1= DT*UNSV2D%R(I1)*FXMAT(I)
          HFL2=-DT*UNSV2D%R(I2)*FXMAT(I)
!         POUR TRACEURS
          H1N=HT%R(I1)
          H2N=HT%R(I2)
!         FIN POUR TRACEURS
          IF(HFL2.GT.HT%R(I2)) THEN
            TET=HT%R(I2)/HFL2
            HT%R(I1)=HT%R(I1)-HFL1*TET
            HT%R(I2)=0.D0
            FXMAT(I)=FXMAT(I)*(1.D0-TET)
            C=C-FXMAT(I)
            NEWREMAIN=NEWREMAIN+1
            INDIC(NEWREMAIN)=I
          ELSE
            HT%R(I1)=HT%R(I1)-HFL1
            HT%R(I2)=HT%R(I2)-HFL2
          ENDIF
!         TRACER (WITH TEST HT%R(I1) CANNOT BE 0.D0)
          IF(H1N.LT.HT%R(I1)) THEN
            F%R(I1)=F%R(I1)+(1.D0-H1N/HT%R(I1))*(F%R(I2)-F%R(I1))
          ENDIF
!         FIN TRACEUR
        ENDIF
      ENDDO
!
      ELSEIF(OPTION.EQ.2) THEN
!
      DO IR=1,REMAIN_SEG
        I=INDIC(IR)
        I1=GLOSEG1(I)
        I2=GLOSEG2(I)
        IF(FXMAT(I).GT.EPS_FLUX) THEN
!         SHARING ON DEMAND: FRACTION OF DEPTH TAKEN
!         T4 IS THE STORED DEPTH
!         1.D-20 ADDED HERE OTHERWISE IT OCCURED THAT THE PRODUCT OF 2
!         STRICTLY POSITIVE NUMBERS GAVE 0.D0
          IF(T4%R(I1).GT.1.D-20) THEN
            HSEG1=T4%R(I1)*FXMAT(I)/T1%R(I1)
!           END OF SHARING ON DEMAND
            HFL1= DT*UNSV2D%R(I1)*FXMAT(I)
            IF(HFL1.GT.HSEG1) THEN
              TET=HSEG1/HFL1
!             HSEG2 AND THUS HT WILL BE STRICTLY POSITIVE
              HSEG2=DT*UNSV2D%R(I2)*FXMAT(I)*TET
              HT%R(I2)=HT%R(I2)+HSEG2
!             GROUPING H*F
              T5%R(I2)=T5%R(I2)+HSEG2*T6%R(I1)
!             RECOMPUTING F (AS WEIGHTED AVERAGE)
!             THIS MAY BE DONE SEVERAL TIMES FOR THE SAME POINT
!             BUT THE LAST ONE WILL BE THE GOOD ONE
              F%R(I2)=T5%R(I2)/HT%R(I2)
              FXMAT(I)=FXMAT(I)*(1.D0-TET)
              C=C+FXMAT(I)
              NEWREMAIN=NEWREMAIN+1
              INDIC(NEWREMAIN)=I
            ELSE
              HSEG1=HSEG1-HFL1
              HSEG2=DT*UNSV2D%R(I2)*FXMAT(I)
              HT%R(I2)=HT%R(I2)+HSEG2
              T5%R(I2)=T5%R(I2)+HSEG2*T6%R(I1)
!             THE LAST ONE WILL BE THE GOOD ONE
              F%R(I2)=T5%R(I2)/HT%R(I2)
              IF(HSEG1.GT.0.D0) THEN
                HT%R(I1)=HT%R(I1)+HSEG1
                T5%R(I1)=T5%R(I1)+HSEG1*T6%R(I1)
!               THE LAST ONE WILL BE THE GOOD ONE
                F%R(I1)=T5%R(I1)/HT%R(I1)
              ENDIF
            ENDIF
          ELSE
!           NO WATER NO FLUX TRANSMITTED, NOTHING CHANGED
            C=C+FXMAT(I)
            NEWREMAIN=NEWREMAIN+1
            INDIC(NEWREMAIN)=I
          ENDIF
        ELSEIF(FXMAT(I).LT.-EPS_FLUX) THEN
!         SHARING ON DEMAND
          IF(T4%R(I2).GT.1.D-20) THEN
!         1.D-20 ADDED HERE OTHERWISE IT OCCURED THAT THE PRODUCT OF 2
!         STRICTLY POSITIVE NUMBERS GAVE 0.D0
            HSEG2=-T4%R(I2)*FXMAT(I)/T1%R(I2)
!           END OF SHARING ON DEMAND
            HFL2=-DT*UNSV2D%R(I2)*FXMAT(I)
            IF(HFL2.GT.HSEG2) THEN
              TET=HSEG2/HFL2
!             HSEG1 AND THUS HT WILL BE STRICTLY POSITIVE
              HSEG1=-DT*UNSV2D%R(I1)*FXMAT(I)*TET
              HT%R(I1)=HT%R(I1)+HSEG1
              T5%R(I1)=T5%R(I1)+HSEG1*T6%R(I2)
!             THE LAST ONE WILL BE THE GOOD ONE
              F%R(I1)=T5%R(I1)/HT%R(I1)
              FXMAT(I)=FXMAT(I)*(1.D0-TET)
              C=C-FXMAT(I)
              NEWREMAIN=NEWREMAIN+1
              INDIC(NEWREMAIN)=I
            ELSE
              HSEG1=-DT*UNSV2D%R(I1)*FXMAT(I)
              HSEG2=HSEG2-HFL2
              HT%R(I1)=HT%R(I1)+HSEG1
              T5%R(I1)=T5%R(I1)+HSEG1*T6%R(I2)
              F%R(I1)=T5%R(I1)/HT%R(I1)
              IF(HSEG2.GT.0.D0) THEN
                HT%R(I2)=HT%R(I2)+HSEG2
                T5%R(I2)=T5%R(I2)+HSEG2*T6%R(I2)
!               THE LAST ONE WILL BE THE GOOD ONE
                F%R(I2)=T5%R(I2)/HT%R(I2)
              ENDIF
            ENDIF
          ELSE
!           NO WATER NO FLUX TRANSMITTED, NOTHING CHANGED
            C=C-FXMAT(I)
            NEWREMAIN=NEWREMAIN+1
            INDIC(NEWREMAIN)=I
          ENDIF
        ENDIF
      ENDDO
!
!     ELSE
!       UNKNOWN OPTION
      ENDIF
!
      REMAIN_SEG=NEWREMAIN
!
!     MERGING DEPTHS AND F AT INTERFACE POINTS
!
      IF(NCSIZE.GT.1) THEN
        DO IPTFR=1,NPTIR
!         ARRAY WITH HT*F AT INTERFACE POINTS
          I=MESH%NACHB%I(NBMAXNSHARE*(IPTFR-1)+1)
          T1%R(I)=HT%R(I)*F%R(I)
        ENDDO
!       SUMMING HT*F AT INTERFACE POINTS
        CALL PARCOM(T1,2,MESH)
!       SUMMING THE NEW POSITIVE PARTIAL DEPTHS OF INTERFACE POINTS
        CALL PARCOM(HT,2,MESH)
!       AVERAGE F AT INTERFACE POINTS
        DO IPTFR=1,NPTIR
          I=MESH%NACHB%I(NBMAXNSHARE*(IPTFR-1)+1)
          IF(HT%R(I).GT.0.D0) F%R(I)=T1%R(I)/HT%R(I)
        ENDDO
      ENDIF
!
      IF(NCSIZE.GT.1) C=P_DSUM(C)
      IF(TESTING) WRITE(LU,*) 'FLUX NON PRIS EN COMPTE=',C
      IF(C.NE.CPREV.AND.ABS(C-CPREV).GT.CINIT*1.D-9
     &             .AND.C.NE.0.D0) THEN
        CPREV=C
        IF(NITER.LT.NITMAX) GO TO 777
      ENDIF
!
!     RAIN-EVAPORATION: RAIN DONE ABOVE, NOW EVAPORATION
!
      IF(RAIN) THEN
        DO I=1,NPOIN
          C=MIN(PLUIE%R(I),0.D0)
!         POSITIVITY NOT TESTED HERE, WOULD REQUIRE C=MAX(C,-HT%R(I)/DT)
!         BUT THEN MASS-BALANCE WOULD NOT BE CORRECT, 
          HT%R(I)=HT%R(I)+DT*C
!                                                VALUE IN VAPOR
!         F%R(I)=F%R(I)+DT/MAX(HT%R(I),1.D-4)*C*(0.D0-F%R(I))
          F%R(I)=F%R(I)-DT/MAX(HT%R(I),1.D-4)*C*F%R(I)
        ENDDO       
      ENDIF
!
!     BOUNDARY FLUXES : ADDING THE EXITING (POSITIVE) FLUXES
!                       WITH A POSSIBLE LIMITATION
!
      DO IPTFR=1,NPTFR
        I=NBOR(IPTFR)
!                               T2 = // ASSEMBLED FLBOR
        HFL1=DT*UNSV2D%R(I)*MAX(T2%R(I),0.D0)
        TET=1.D0
!       NEXT LINE SHOULD NEVER HAPPEN (DONE IN POSITIVE_DEPTHS)
        IF(HFL1.GT.HT%R(I)) TET=HT%R(I)/HFL1
!       MAX IS ONLY TO PREVENT TRUNCATION ERROR
        HT%R(I)=MAX(HT%R(I)-HFL1*TET,0.D0)
!       LIMITATION OF FLBOR (MUST HAVE BEEN DONE ALREADY
!                            IN POSITIVE_DEPTHS)
!       FLBOR%R(IPTFR)=FLBOR%R(IPTFR)*TET
        IF(LIMTRA(IPTFR).EQ.KDIR) THEN
          F%R(I)=F%R(I)-HFL1*TET/MAX(HT%R(I),1.D-4)*
     &           (FBOR%R(IPTFR)-F%R(I))
          FLBORTRA%R(IPTFR)=FLBOR%R(IPTFR)*FBOR%R(IPTFR)
        ELSEIF(LIMTRA(IPTFR).EQ.KDDL) THEN
          FLBORTRA%R(IPTFR)=FLBOR%R(IPTFR)*F%R(I)
        ELSE
          FLBORTRA%R(IPTFR)=0.D0
        ENDIF
      ENDDO
!
      IF(TESTING) THEN
        C=0.D0
        DO I=1,NPOIN
          C=C+(HT%R(I)-H%R(I))**2
        ENDDO
!                       FAUX MAIS PAS GRAVE SI 0.
        IF(NCSIZE.GT.1) C=P_DSUM(C)
        WRITE(LU,*) 'DIFFERENCE ENTRE H ET HT =',C
!
        C=1.D99
        DO I=1,NPOIN
          C=MIN(C,F%R(I))
        ENDDO
        IF(NCSIZE.GT.1) C=P_DMIN(C)
        WRITE(LU,*) 'APRES TRAITEMENT TRACEUR MIN=',C
        C=-1.D99
        DO I=1,NPOIN
          C=MAX(C,F%R(I))
        ENDDO
        IF(NCSIZE.GT.1) C=P_DMAX(C)
        WRITE(LU,*) 'APRES TRAITEMENT TRACEUR MAX=',C
      ENDIF
!
!-----------------------------------------------------------------------
!
!     SOURCE TERMS
!
      IF(YASMI) THEN
!
!       IMPLICIT AND EXPLICIT SOURCE TERM
!
        IF(IOPT2.EQ.0) THEN
          DO I = 1,MESH%NPOIN
            F%R(I)=(F%R(I)+DT*SM%R(I))/
     &           (1.D0-DT*SMI%R(I)/MAX(H%R(I),1.D-15))
!           COULD BE DONE LIKE THIS...
!           F%R(I)=H%R(I)*(F%R(I)+DT*SM%R(I))/(H%R(I)-DT*SMI%R(I))
          ENDDO
        ELSEIF(IOPT2.EQ.1) THEN
!         HERE WE ASSUME THAT SMI WILL PREVENT A DIVISION BY ZERO
!         THIS IS THE CASE WITH SETTLING VELOCITY IN SISYPHE
          DO I = 1,MESH%NPOIN
          F%R(I)=(F%R(I)*HT%R(I)+DT*SM%R(I)*H%R(I))/(H%R(I)-DT*SMI%R(I))
          ENDDO
        ENDIF            
!
      ELSE
!
!       EXPLICIT SOURCE TERM ONLY (AND IOPT2=1 NOT TREATED !!!)
!
        DO I = 1,MESH%NPOIN
          F%R(I) = F%R(I)+DT*SM%R(I)
        ENDDO
!      
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(ENTET) THEN
        IF(LNG.EQ.1) WRITE(LU,101) NITER
        IF(LNG.EQ.2) WRITE(LU,102) NITER
      ENDIF
!
101   FORMAT(' CVTRVF_POS (SCHEMA 13 OU 14) : ',1I3,' ITERATIONS')
102   FORMAT(' CVTRVF_POS (SCHEME 13 OR 14): ',1I3,' ITERATIONS')
!
!-----------------------------------------------------------------------
!
      RETURN
      END

