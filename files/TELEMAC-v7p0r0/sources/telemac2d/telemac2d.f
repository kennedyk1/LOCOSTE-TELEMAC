!                    ********************
                     SUBROUTINE TELEMAC2D
!                    ********************
!
     &(PASS,ATDEP,NITER,CODE,DTDEP,NEWTIME,DOPRINT)
!
!***********************************************************************
! TELEMAC2D   V7P0                                  02/01/2014
!***********************************************************************
!
!brief    SOLVES THE SAINT-VENANT EQUATIONS FOR U,V,H.
!+
!+            ADJO = .TRUE.  : DIRECT MODE
!+
!+            ADJO = .FALSE. : ADJOINT MODE
!
!history
!+        06/06/2008
!+
!+   OPTIONAL ARGUMENT BOUNDARY_COLOUR ADDED TO LECLIM
!
!history
!+        16/06/2008
!+
!+   SECOND CALL TO PROPIN FOLLOWING CALL TO BORD
!
!history
!+        25/06/2008
!+
!+   DIFFIN2 RENAMED DIFFIN + ARGUMENT MESH
!
!history
!+        27/06/2008
!+
!+   ARGUMENTS OF PROPIN_TELEMAC2D : MESH ADDED TO THE END
!
!history
!+        29/07/2008
!+
!+   ADDED CALL TO FLUSEC BEFORE THE 1ST CALL PRERES
!
!history
!+        13/08/2008
!+
!+   CHANGED CALL AND CALL CONDITIONS TO CHARAC
!
!history
!+        20/08/2008
!+
!+   LIST_PTS MODIFIED IN PARALLEL
!
!history
!+        02/09/2008
!+
!+   CALL TO MODIFIED TEL4DEL (ADDED VELOCITY AND DIFFUSION)
!
!history
!+        25/09/2008
!+
!+   CALL TO MODIFIED TEL4DEL (FLUXES SENT THRU MESH%W%R)
!
!history
!+        21/10/2008
!+
!+   CALL TO MODIFIED MASKTO (PARALLEL VERSION OF MASKTO)
!
!history
!+        09/02/2009
!+
!+   IF H CLIPPED, USES HMIN INSTEAD OF 0.D0
!
!history
!+        16/02/2009
!+
!+   CALL TO POSITIVE_DEPTHS
!
!history
!+        19/02/2009
!+
!+   H CLIPPED IN CASE OF COMPUTATION CONTINUED
!
!history
!+        02/04/2009
!+
!+   NEW FILE STRUCTURE T2D_FILES AND MED FORMAT
!
!history
!+        09/07/2009
!+
!+   ARGUMENT NPTFR2 ADDED TO LECLIM
!
!history
!+        20/07/2009
!+
!+   1 OUT OF 3 CALLS TO TEL4DEL REMOVED (THANKS TO A
!
!history
!+        22/07/2009
!+
!+   3 NEW ARGUMENTS IN PROPAG
!
!history  J-M HERVOUET (LNHE)
!+        25/11/2009
!+        V6P0
!+   VERSION WITH MULTIPLE TRACERS
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
!+        19/04/2011
!+        V6P1
!+   SECOND CALL TO SISYPHE MOVED AT THE END OF THE TIME LOOP SO THAT
!+   A CORRECT CONTINUITY EQUATION CAN BE SENT EVEN AT THE FIRST TIME
!+   STEP (H, HN, USIS, VSIS, DM1, ZCONV COMPATIBLE)
!
!history  J-M HERVOUET (LNHE)
!+        19/05/2011
!+        V6P1
!+   NEW THOMPSON THEORY, THAT WORKS ALSO IN PARALLEL
!
!history  J-M HERVOUET (LNHE)
!+        09/08/2011
!+        V6P1
!+   Call to lecsng changed
!
!history  C.COULET (ARTELIA)
!+        23/05/2012
!+        V6P2
!+   Modification for adding "bridge" file and separation of weirs and
!+   culvert files.
!
!history  J-M HERVOUET (LNHE)
!+        16/07/2012
!+        V6P1
!+   Call to TEL4DEL modified.
!
!history  P. CHASSE (CETMEF) / C.COULET (ARTELIA)
!+        03/08/2012
!+        V6P2
!+   Modification for adding breaches management during simulation
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        12/02/2013
!+        V6P1
!+   Call to FLOT and DERIVE modified, call to SORFLO removed.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        11/03/2013
!+        V6P3
!+   Call to METEO modified.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        22/03/2013
!+        V6P3
!+   Call to WAC and SISYPHE modified.
!
!history  R. KOPMANN (EDF R&D, LNHE)
!+        16/04/2013
!+        V6P3
!+   Adding the file format in calls to FIND_IN_SEL.
!
!history  C.COULET / A.REBAI / E.DAVID (ARTELIA)
!+        12/06/2013
!+        V6P3
!+   Modification for new treatment of weirs
!
!history  A. JOLY (EDF R&D, LNHE)
!+        15/07/2013
!+        V6P3
!+   Allocating algae variables and initialising them for the next
!+   time step
!
!history R.ATA (EDF R&D, LNHE)
!+        10/10/2013
!+        V6P3
!+   FORCING LISTING AND GRAPHIC OUTPUTS FOR LAST TIME STEP, FOR FV
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        30/12/2013
!+        V7P0
!+   Initialisation of YAFLODEL added (overlooked bug?).
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        02/01/2014
!+        V7P0
!+   Removing a use of KNOGL. KNOGL suppressed in call to 
!+   flusec_telemac2d.
!
!history  J-M HERVOUET (EDF LAB, LNHE)
!+        31/03/2014
!+        V7P0
!+   1) Now written to enable different numbering of boundary points and
!+      boundary segments.
!+   2) Incident wave suppressed.
!+   3) Different advection schemes for different tracers allowed.
!
!history  J-M HERVOUET (EDF LAB, LNHE)
!+        30/04/2014
!+        V7P0
!+   Now 2 calls to charac
!+   one for strong and one for weak characteristics.
!+   Second call to DIFFIN: U and V replaced by UCONV and VCONV.
!
!history  J-M HERVOUET (EDF LAB, LNHE)
!+        11/06/2014
!+        V7P0
!+   LIMTRA replaced by a copy in the call to cvdftr (some schemes may
!+   change it and it may cause problems for the next tracers)
!
!history  J-M HERVOUET (EDF LAB, LNHE)
!+        05/08/2014
!+        V7P0
!+   Initialisation of PRIVE move before call to FONSTR (it could be
!+   used in FONSTR and wrongly cancelled by initialisation).
!
!history  C VILLARET (HRW+EDF) & J-M HERVOUET (EDF - LNHE)
!+        18/09/2014
!+        V7P0
!+   Calls to sisyphe and wac changed.
!
!history  D WANG & P TASSI (LNHE)
!+        10/07/2014
!+        V7P0
!+   Secondary flow correction:
!+   add the calculation of \Omega 
!
!history  R. ATA (EDF LAB, LNHE)
!+        05/11/2014
!+        V7P0
!+   add optional variables to meteo in a sake of harmonization
!+   with telemac-3d
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!param atdep     [in] starting time when called for coupling
!param code      [in] calling program (if coupling)
!param doprint   [in] for overwriting the keyword on listing
!param dtdep     [in] time step to use when coupling with estel-3d
!param newtime   [in] are we starting a new time step or just iterating?
!+                    this is for coupling with estel-3d
!param niter     [in] number of iterations when called for coupling
!param pass      [in] -1 : all steps
!+                     0 : only initialisation
!+                     1 : only time-steps steps
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_TELEMAC2D
      USE INTERFACE_TELEMAC2D, EX_TELEMAC2D => TELEMAC2D
      USE INTERFACE_SISYPHE, ONLY: SISYPHE
      USE INTERFACE_TOMAWAC, ONLY: WAC
      USE GRACESTOP
      USE FRICTION_DEF
!     MODULE SPECIFIC TO COUPLING WITH ESTEL-3D
      USE M_COUPLING_ESTEL3D
!     OIL SPILL MODEL
      USE OILSPILL
!     ALGAE MODEL
      USE ALGAE_TRANSP
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER,          INTENT(IN) :: PASS,NITER
      DOUBLE PRECISION, INTENT(IN) :: ATDEP
      CHARACTER(LEN=*), INTENT(IN) :: CODE
!     TIME STEP TO USE WHEN COUPLING WITH ESTEL-3D
      DOUBLE PRECISION, INTENT(IN), OPTIONAL :: DTDEP
!     ARE WE STARTING A NEW TIME STEP OR JUST ITERATING?
      LOGICAL,          INTENT(IN), OPTIONAL :: NEWTIME
!     DO WE WANT TELEMAC2D TO OUTPUT IN THE LISTING OR NOT?
      LOGICAL,          INTENT(IN), OPTIONAL :: DOPRINT
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
! INTEGERS
!
      INTEGER IELM,I,IELMX,ISOUSI,IBID,STOP2,LEOPRD_CHARR,DISCLIN
      INTEGER ALIRE(MAXVAR),TROUVE(MAXVAR+10)
!
! REAL SCALARS
!
      DOUBLE PRECISION KMIN,KMAX,KARMAN,FLUSOR,FLUENT,HIST(1),AT0
      DOUBLE PRECISION C,MASSES,RELAXS,RELAXB,CFLMAX,TETAHC,DTCAS,RELAX
      DOUBLE PRECISION EMAX,EMIN,SCHMIT,ESTAR,SIGMAE,SIGMAK,C2,C1,CMU
      DOUBLE PRECISION MASS_RAIN
!
! FOR TRACERS
!
!     MASSOU: MASS CREATED BY SOURCE TERM DURING THE TIME STEP
!     MASTR0: INITIAL MASS
!     MASTR2: CURRENT MASS
!     MASTEN: MASS ENTERED THROUGH BOUNDARIES
!     MASTOU: TOTAL MASS CREATED BY SOURCE TERM
!     MASTRAIN: TOTAL MASS BROUGHT BY RAIN OR EVAPORATION
      DOUBLE PRECISION MASSOU(MAXTRA),MASTR0(MAXTRA),MASTR2(MAXTRA)
      DOUBLE PRECISION MASTEN(MAXTRA),MASTOU(MAXTRA),MASTRAIN(MAXTRA)
!
! LOGICALS
!
      LOGICAL AKEP,INFOGS,INFOGT,ARRET1,ARRET2,YASMH,ARRET3,CORBOT
      LOGICAL CHARR,SUSP,CHARR_TEL,SUSP1,YAFLODEL,YAFLULIM
      LOGICAL YASMI(MAXTRA)
!
      CHARACTER(LEN=24), PARAMETER :: CODE1='TELEMAC2D               '
!
!-----------------------------------------------------------------------
!
      INTEGER IOPTAN,IMAX,ITRAC,NPTFR2
!
!-----------------------------------------------------------------------
!
! ADDED FOR KINETIC SCHEMES
!
      DOUBLE PRECISION FLUTSOR(MAXTRA),FLUTENT(MAXTRA),DTN
      DOUBLE PRECISION FLUSORTN,FLUENTN,TMAX,DTT
      INTEGER LTT
!
!-----------------------------------------------------------------------
!
!     FOR SISYPHE : GRAIN FEEDING AND CONSTANT FLOW DISCHARGE
      INTEGER :: ISIS_CFD, NSIS_CFD
      LOGICAL :: SISYPHE_CFD, CONSTFLOW_SIS
!     FRICTION DATA
      INTEGER :: KFROT_TP
!
      INTEGER  P_IMAX,P_IMIN
      DOUBLE PRECISION P_DMIN
      EXTERNAL P_IMAX,P_IMIN,P_DMIN
!
!-----------------------------------------------------------------------
!
      INTRINSIC MAX
!
!-----------------------------------------------------------------------
!
      DATA HIST /9999.D0/
!
!-----------------------------------------------------------------------
!
!  VARIABLES TO READ IN THE EVENT OF A CONTINUATION:
!  0 : DISCARD    1 : READ  (SEE SS-PG NOMVAR)
!
!                                 0: OLD PLACE FOR THE TRACER
      DATA ALIRE /1,1,0,1,1,1,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     &            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     &            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     &            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0/
!
!-----------------------------------------------------------------------
!
!     ADVECTION FIELD USED FOR SISYPHE CALL
!
      TYPE(BIEF_OBJ), POINTER :: USIS,VSIS
!
!-----------------------------------------------------------------------
!
      SAVE
!
!-----------------------------------------------------------------------
!
      CHARR_TEL=.FALSE.
      CHARR=.FALSE.
      SUSP=.FALSE.
      YAFLODEL=.FALSE.
      DISCLIN=11
      NFLOT=0
!
!-----------------------------------------------------------------------
!
!     FOR TAKING INTO ACCOUNT FLUX LIMITATION OF ARRAY FLULIM IN ADVECTION
!     SCHEMES (SO FAR ONLY FOR TRACERS IN CASE SOLSYS=2 AND OPT_HNEG=2).
!
      YAFLULIM=.FALSE.
!
!     FOR READING TRACERS IN SELAFIN FILES
!
      IF(NTRAC.GT.0) THEN
        DO ITRAC=1,NTRAC
!         SEE POINT_TELEMAC2D
          ALIRE(31+ITRAC) = 1
        ENDDO
      ENDIF
!
!     FOR AVOIDING READING K, EPSILON AND DIFFUSION WHEN NOT RELEVANT
!
      IF(ITURB.NE.3) ALIRE(10) = 0
      IF(ITURB.NE.3) ALIRE(11) = 0
      IF(ITURB.EQ.1) ALIRE(12) = 0
!
!-----------------------------------------------------------------------
!
!     USE DOPRINT TO LIMIT TELEMAC-2D OUTPUTS IN THE LISTING
!
      IF(PRESENT(DOPRINT)) THEN
        LISTIN =  DOPRINT
        ENTET  =  DOPRINT
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(PASS.EQ.0) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'INITIALISATION DE TELEMAC2D POUR ',CODE
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'INITIALISING TELEMAC2D FOR ',CODE
        ENDIF
      ELSEIF(PASS.EQ.1) THEN
        GO TO 700
      ELSEIF(PASS.NE.-1) THEN
        IF(LNG.EQ.1) WRITE(LU,*) 'MAUVAIS ARGUMENT PASS : ',PASS
        IF(LNG.EQ.2) WRITE(LU,*) 'WRONG ARGUMENT PASS: ',PASS
        CALL PLANTE(1)
        STOP
      ENDIF
!
!=======================================================================
!
! : 1          READS, PREPARES AND CONTROLS THE DATA
!
!=======================================================================
!
!  TYPES OF DISCRETISATION: P1 TRIANGLES FOR NOW
!
      IELM=IELM1
!     THE MOST COMPLEX ELEMENT
      IELMX = MAX(IELMH,IELMU,IELMT,IELMK,IELME)
!
!-----------------------------------------------------------------------
!
! READS THE BOUNDARY CONDITIONS AND INDICES OF THE BOUNDARY POINTS
!
      IF(IELMX.EQ.13) THEN
        NPTFR2=2*NPTFR
      ELSE
        NPTFR2=NPTFR
      ENDIF
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING LECLIM'
      CALL LECLIM (LIHBOR%I   , LIUBOR%I , LIVBOR%I , LITBOR%ADR(1)%P%I,
     &             HBOR%R     , UBOR%R   , VBOR%R   , TBOR%ADR(1)%P%R ,
     &             CHBORD%R    , ATBOR%ADR(1)%P%R   , BTBOR%ADR(1)%P%R ,
     &             MESH%NPTFR , 3        ,NTRAC.GT.0,
     &             T2D_FILES(T2DCLI)%LU,
     &             KENT       , KENTU    , KSORT ,  KADH , KLOG , KINC,
     &             NUMLIQ%I   ,MESH,BOUNDARY_COLOUR%I,NPTFR2)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM LECLIM'
!
! DUPLICATES THE BOUNDARY CONDITIONS FOR THE TRACERS
!
      IF(NTRAC.GE.2) THEN
        DO ITRAC=2,NTRAC
          DO I=1,NPTFR
            LITBOR%ADR(ITRAC)%P%I(I)=LITBOR%ADR(1)%P%I(I)
              TBOR%ADR(ITRAC)%P%R(I)=  TBOR%ADR(1)%P%R(I)
             ATBOR%ADR(ITRAC)%P%R(I)= ATBOR%ADR(1)%P%R(I)
             BTBOR%ADR(ITRAC)%P%R(I)= BTBOR%ADR(1)%P%R(I)
          ENDDO
        ENDDO
      ENDIF
!
! COEFFICIENTS FOR SECONDARY CURRENTS SECURED TO 0.
!
      IF(SECCURRENTS) THEN
        DO I=1,NPTFR
          TBOR%ADR(NTRAC)%P%R(I)  = 0.D0
          ATBOR%ADR(NTRAC)%P%R(I) = 0.D0
          BTBOR%ADR(NTRAC)%P%R(I) = 0.D0
        ENDDO
      ENDIF
!
!-----------------------------------------------------------------------
!  COMPLEMENT OF THE DATA STRUCTURE FOR BIEF
!-----------------------------------------------------------------------
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING INBIEF'
      CALL INBIEF(LIHBOR%I,KLOG,IT1,IT2,IT3,LVMAC,IELMX,
     &            LAMBD0,SPHERI,MESH,T1,T2,OPTASS,PRODUC,EQUA)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM INBIEF'
!
      IF(IELMX.EQ.13) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING COMPLIM'
        CALL COMPLIM( LIUBOR%I , LIVBOR%I , LITBOR%ADR(1)%P%I,
     &                UBOR%R   , VBOR%R   , TBOR%ADR(1)%P%R ,
     &                CHBORD%R , ATBOR%ADR(1)%P%R , BTBOR%ADR(1)%P%R ,
     &                MESH%NBOR%I,MESH%NPTFR , MESH%NPOIN, NTRAC.GT.0,
     &                KENT , KENTU , KSORT ,KADH , KLOG , 
     &                IELMU,IELMU,IELMT,MESH,
     &                MESH%IKLBOR%I,MESH%NELEB,MESH%NELEBX)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM COMPLIM'
      ENDIF
!
!-----------------------------------------------------------------------
!  DEFINITION OF ZONES BY THE USER
!-----------------------------------------------------------------------
!
      IF(DEFZON) CALL DEF_ZONES
!
!-----------------------------------------------------------------------
!  CHANGES FROM GLOBAL TO LOCAL IN LIST OF POINTS IN PARALLEL
!-----------------------------------------------------------------------
!
      IF(NPTS.GT.0.AND.NCSIZE.GT.1) THEN
        DO I=1,NPTS
          LIST_PTS(I)=GLOBAL_TO_LOCAL_POINT(LIST_PTS(I),MESH)
        ENDDO
      ENDIF
!
!     INITIALISES SECONDARY CURRENTS VARIABLES
!
      IF(SECCURRENTS) THEN
        CALL OS('X=0     ',X=SEC_TAU)
        CALL OS('X=0     ',X=SEC_R)
      ENDIF
!
!-----------------------------------------------------------------------
!
!  INITIALISES PRIVE
!
      IF(NPRIV.GT.0) CALL OS('X=0     ',X=PRIVE)
!
!-----------------------------------------------------------------------
!  LOOKS FOR VARIABLES BOTTOM AND BOTTOM FRICTION IN THE GEOMETRY FILE:
!-----------------------------------------------------------------------
!
      IF(     .NOT.INCLU2(ESTIME,'FROTTEMENT')
     &   .AND..NOT.INCLU2(ESTIME,'FRICTION'  )  ) THEN
!       NO PARAMETER ESTIMATION
        CALL FONSTR(T1,ZF,T2,CHESTR,T2D_FILES(T2DGEO)%LU,
     &              T2D_FILES(T2DGEO)%FMT,
     &              T2D_FILES(T2DFON)%LU,T2D_FILES(T2DFON)%NAME,
     &              MESH,FFON,LISTIN)
        CORBOT=.TRUE.
      ELSEIF(NITERA.EQ.1.AND..NOT.ADJO) THEN
!       WITH PARAMETER ESTIMATION (HENCE NITERA DEFINED),
!       FONSTR CALLED ONCE TO GET
!       THE BOTTOM TOPOGRAPHY AND THE INITIAL FRICTION (CALL TO STRCHE)
        CALL FONSTR(T1,ZF,T2,CHESTR,T2D_FILES(T2DGEO)%LU,
     &              T2D_FILES(T2DGEO)%FMT,
     &              T2D_FILES(T2DFON)%LU,T2D_FILES(T2DFON)%NAME,
     &              MESH,FFON,LISTIN)
!       IF OPTID=0, VALUES OF SETSTR ARE GIVEN BY FILE, MUST NOT BE ERASED
        IF(OPTID.NE.0) CALL INITSTR(CHESTR,SETSTR,ZONE%I,NZONE,NPOIN,T1)
        CALL ASSIGNSTR(CHESTR,SETSTR,ZONE%I,NZONE,NPOIN)
        CORBOT=.TRUE.
      ELSE
!       IN PARAMETER ESTIMATION, FROM NITERA=2 ON, BOTTOM IS NOT READ
!       AGAIN, SO NO CALL TO CORFON
        CORBOT=.FALSE.
      ENDIF
!
!     INITIALISES FRICTION COEFFICIENT BY ZONE
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING FRICTION_CHOICE'
      CALL FRICTION_CHOICE(0,KARMAN)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM FRICTION_CHOICE'
!
!-----------------------------------------------------------------------
!
! PREPARES THE RESULTS FILE (OPTIONAL)
!
!      STANDARD SELAFIN
!
      IF(ADJO) THEN
!
        IF(T2D_FILES(T2DRBI)%NAME.NE.' '.AND.
     &    INCLU2(ESTIME,'DEBUG')) THEN
          CALL ECRGEO(MESH%X%R,MESH%Y%R,MESH%NPOIN,MESH%NBOR%I,
     &                T2D_FILES(T2DRBI)%LU,IBID,TEXTE,VARCLA,NVARCL,
     &                TITCAS,SORLEOA,MAXVAR,MESH%IKLE%I,
     &                MESH%NELEM,MESH%NPTFR,3,MARDAT,MARTIM,
     &                NCSIZE,NPTIR,MESH%KNOLG%I,I3=I_ORIG,I4=J_ORIG)
        ENDIF
!
      ELSE
!
!       CREATES THE DATA FILE USING A GIVEN FILE FORMAT:
!       T2D_FILES(T2DRES)%FMT
!       THE DATA ARE CREATED IN THE LOGICAL UNIT T2D_FILES(T2DRES)%LU
!       WITH A TITLE AND NAMES OF OUTPUT VARIABLES.
!
        CALL CREATE_DATASET(T2D_FILES(T2DRES)%FMT, ! RESULTS FILE FORMAT
     &                      T2D_FILES(T2DRES)%LU,  ! LU FOR RESULTS FILE
     &                      TITCAS,     ! TITLE
     &                      MAXVAR,     ! MAX NUMBER OF OUTPUT VARIABLES
     &                      TEXTE,      ! NAMES OF OUTPUT VARIABLES
     &                      SORLEO)     ! PRINT TO FILE OR NOT
!
!       WRITES THE MESH IN THE OUTPUT FILE :
!       IN PARALLEL, REQUIRES NCSIZE AND NPTIR.
!       THE REST OF THE INFORMATION IS IN MESH.
!       ALSO WRITES : START DATE/TIME AND COORDINATES OF THE
!       ORIGIN.
!
        CALL WRITE_MESH(T2D_FILES(T2DRES)%FMT, ! RESULTS FILE FORMAT
     &                  T2D_FILES(T2DRES)%LU,  ! LU FOR RESULTS FILE
     &                  MESH,          ! CHARACTERISES MESH
     &                  1,             ! NUMBER OF PLANES /NA/
     &                  MARDAT,        ! START DATE
     &                  MARTIM,        ! START TIME
     &                  I_ORIG,J_ORIG) ! COORDINATES OF THE ORIGIN.
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!  ENLARGES COSLAT AND SINLAT TO GIVE THEM THE DIMENSION OF U AND V
!  SAME THING FOR FRICTION
!
      IF(IELMU.NE.IELM1) THEN
        IF(SPHERI) CALL CHGDIS(MESH%COSLAT,IELM1,IELMU,MESH)
        IF(SPHERI) CALL CHGDIS(MESH%SINLAT,IELM1,IELMU,MESH)
        CALL CHGDIS(CHESTR,IELM1,IELMU,MESH)
      ENDIF
!
!=======================================================================
!
!  LOCATES THE BOUNDARIES
!
      IF(NCSIZE.GT.1) THEN
        NFRLIQ=0
        DO I=1,NPTFR
          NFRLIQ=MAX(NFRLIQ,NUMLIQ%I(I))
        ENDDO
        NFRLIQ=P_IMAX(NFRLIQ)
        WRITE(LU,*) ' '
        IF(LNG.EQ.1) WRITE(LU,*) 'NOMBRE DE FRONTIERES LIQUIDES :',
     &               NFRLIQ
        IF(LNG.EQ.2) WRITE(LU,*) 'NUMBER OF LIQUID BOUNDARIES:',NFRLIQ
      ELSE
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING FRONT2'
        CALL FRONT2(NFRLIQ,NFRSOL,DEBLIQ,FINLIQ,DEBSOL,FINSOL,
     &              LIHBOR%I,LIUBOR%I,
     &              MESH%X%R,MESH%Y%R,MESH%NBOR%I,MESH%KP1BOR%I,
     &              IT1%I,NPOIN,NPTFR,KLOG,LISTIN,NUMLIQ%I,MAXFRO)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM FRONT2'
      ENDIF
!
!=======================================================================
!
!  READS THE FILE WITH STAGE-DISCHARGE CURVES
!
      IF(T2D_FILES(T2DMAB)%NAME(1:1).NE.' ') THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING READ_FIC_CURVES'
        CALL READ_FIC_CURVES(T2D_FILES(T2DMAB)%LU,NFRLIQ,
     &                       STA_DIS_CURVES,PTS_CURVES)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM READ_FIC_CURVES'
      ENDIF
!
!=======================================================================
!
! CORRECTS THE NORMALS TO THE BOUNDARY NODES TO HAVE NORMALS TO
! ADJACENT LIQUID SEGMENT IN THE CASE OF A TRANSITION FROM LIQUID TO SOLID
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CORNOR'
      CALL CORNOR(MESH%XNEBOR%R,MESH%YNEBOR%R,
     &            MESH%XSGBOR%R,MESH%YSGBOR%R,NPTFR,KLOG,LIHBOR%I,
     &            T1,T2,MESH,MESH%IKLBOR%I,MESH%NELEB,MESH%NELEBX)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CORNOR'
!
!=======================================================================
!
! FILLS IN MASKEL BY DEFAULT
! (ALL THE ELEMENTS ARE TO BE CONSIDERED)
!
      IF(MSK) CALL OS ( 'X=C     ',X=MASKEL,C=1.D0)
!
!     USER CHOOSES TO HIDE SOME OF THE ELEMENTS
!     THIS SUBROUTINE IS ALSO CALLED AT EVERY TIME STEP
      IF(MSKUSE) THEN
        CALL MASKOB (MASKEL%R,MESH%X%R,MESH%Y%R,
     &               IKLE%I,NELEM,NELMAX,NPOIN,0.D0,0)
      ENDIF
!
!-----------------------------------------------------------------------
!  INTEGRAL OF TEST FUNCTIONS (ONCE FOR ALL AND WITHOUT MASKING)
!-----------------------------------------------------------------------
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING MASBAS2D'
      CALL MASBAS2D(VOLU2D,V2DPAR,UNSV2D,IELM1,MESH,.FALSE.,
     &              MASKEL,T2,T2)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM MASBAS2D'
!
!=======================================================================
!
! CORRECTS THE BOTTOM WITH USER-SUBROUTINE CORFON
! ZF IS TREATED AS LINEAR IN CORFON
! IF(CORBOT) : SEE CALL FONSTR ABOVE, IN PARAMETER ESTIMATION,
! ZF IS READ ONLY AT THE FIRST RUN
!
      IF(CORBOT) THEN
        IF(IELMH.NE.IELM1) CALL CHGDIS(ZF,IELMH,IELM1,MESH)
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CORFON'
        CALL CORFON
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CORFON'
        IF(IELMH.NE.IELM1) CALL CHGDIS(ZF,IELM1,IELMH,MESH)
      ENDIF
!
!=======================================================================
!
! IS POSSIBLE TO REDEFINE THE CHARACTERISTICS OF THE SOURCES
!
! STANDARD SUBROUTINE DOES NOT DO ANYTHING
!
      CALL SOURCE_TELEMAC2D
!
!=======================================================================
!
! CAREFULLY ANALYSES TOPOGRAPHY
!
      IF(OPTBAN.EQ.2) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING TOPOGR'
        CALL TOPOGR(ZF%R,T1%R,ZFE%R,IKLE%I,MESH%IFABOR%I,
     &              MESH%NBOR%I,MESH%NELBOR%I,MESH%NULONE%I,
     &              IT1%I,IT2%I,IT3%I,
     &              NELEM,NPTFR,NPOIN,MXPTVS)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM TOPOGR'
      ENDIF
!
!=======================================================================
!
! : 2                  INITIALISES
!
!=======================================================================
!
! K-EPSILON AND OTHER CONSTANTS (KARMAN IS USED EVEN WITHOUT K-E)
!
      CALL COSAKE(KARMAN,CMU,C1,C2,SIGMAK,SIGMAE,
     &            ESTAR,SCHMIT,KMIN,KMAX,EMIN,EMAX)
!
      IF(ITURB.EQ.3) THEN
!       WILL HAVE TO INITIALISE K AND EPSILON
        AKEP = .TRUE.
      ELSE
!       SHOULD NOT INITIALISE K AND EPSILON
        AKEP = .FALSE.
      ENDIF
!
! INITIALISES PHYSICAL PARAMETERS
!
!     CONDIN IS CALLED EVEN IN THE EVENT OF A CONTINUATION, SO THAT THE DEFINITION
!     OF C0 DOES NOT CHANGE (CASE OF INCIDENT WAVES)
!
      IF(ADJO) THEN
        CALL CONDIN_ADJ(ALIRE,T2D_FILES(T2DRES)%LU,TROUVE)
      ELSE
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CONDIN'
        CALL CONDIN
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CONDIN'
      ENDIF
!     
!     STARTING TIME (AT MAY BE INITIALISED BY USER IN CONDIN)
!
      AT0=AT
!
!     CORRECTS USER ERRORS IF H HAS BEEN USED
!     HERE THE NUMBER OF POINTS IS FORCED TO NPOIN.
      CALL CLIP(H,0.D0,.TRUE.,1.D6,.FALSE.,-NPOIN)
!
! COMPUTES REFERENCE HEIGHT FOR BOUSSINESQ EQUATIONS
!
      IF(EQUA(1:10).EQ.'BOUSSINESQ') THEN
        CALL HREF
      ENDIF
!
      IF(.NOT.DEBU.AND..NOT.ADJO) THEN
!
!       BEWARE : BIEF_SUITE WILL TAKE THE BOTTOM IN THE FILE
!                IF IT IS THERE.
!
!       FRICTION COEFFICIENT ALSO READ IN CASE IT HAS BEEN DONE
!       BY THE USER INTERFACE (JMH 27/11/2006)
        ALIRE(19)=1
        CALL BIEF_SUITE(VARSOR,VARCL,START_RECORD,
     &                  T2D_FILES(T2DPRE)%LU,
     &                  T2D_FILES(T2DPRE)%FMT,
     &                  HIST,0,NPOIN,AT,TEXTPR,VARCLA,
     &                  NVARCL,TROUVE,ALIRE,LISTIN,
     &                  START_RECORD.EQ.0,MAXVAR)
        ALIRE(19)=0
        IF(INCLUS(COUPLING,'SISYPHE').AND.TROUVE(6).NE.1) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'SUITE DE CALCUL ET COUPLAGE AVEC SISYPHE :'
            WRITE(LU,*) 'LE FOND DOIT ETRE DANS LE FICHIER DU CALCUL'
            WRITE(LU,*) 'PRECEDENT'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'COMPUTATION CONTINUED, COUPLING WITH SISYPHE :'
            WRITE(LU,*) 'THE BOTTOM MUST BE IN THE PREVIOUS COMPUTATION'
            WRITE(LU,*) 'FILE'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(RAZTIM) THEN
          AT=0.D0
          IF(LNG.EQ.1) WRITE(LU,*) 'TEMPS ECOULE REMIS A ZERO'
          IF(LNG.EQ.2) WRITE(LU,*) 'ELAPSED TIME RESET TO ZERO'
        ENDIF
        AT0=AT
        CALL RESCUE(U%R,V%R,H%R,FV%R,ZF%R,T,TRAC0,NTRAC,
     &              ITURB,NPOIN,AKEP,TROUVE)
!       CASE WHERE POSITIVE DEPTHS ARE NECESSARY
        IF(OPTBAN.EQ.1.AND.OPT_HNEG.EQ.2) THEN
          CALL CLIP(H,0.D0,.TRUE.,1.D6,.FALSE.,-NPOIN)
        ENDIF
      ENDIF
!
      TMAX=DUREE+AT0
!
!-----------------------------------------------------------------------
!
!  INITIALISES PARAMETERS SPECIFIC TO FINITE VOLUMES
!
!-----------------------------------------------------------------------
!   
      IF(EQUA(1:15).EQ.'SAINT-VENANT VF') THEN
!
        CALL OS( 'X=YZ    ' , QU , U , H , C )
        CALL OS( 'X=YZ    ' , QV , V , H , C )
!       PREPARES SIMULATION TIME WHEN DURATION =0
        IF(DUREE.EQ.0.D0) THEN
          IF(DT.GT.0.D0.AND.NIT.GE.1) THEN
            DUREE = NIT*DT
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'DUREE DE SIMULATION DEMANDEE :',DUREE 
            ELSEIF(LNG.EQ.2) THEN
              WRITE(LU,*) 'SIMULATION DURATION:',DUREE 
            ENDIF
          ELSE
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'FOURNIR DUREE DE SIMULATION' 
              WRITE(LU,*) 'OU NOMBRE D''ITERATIONS '
            ELSEIF(LNG.EQ.2) THEN
              WRITE(LU,*) 'PLEASE GIVE AT LEAST A DURATION' 
              WRITE(LU,*) 'OR A NUMBER OF ITERATIONS'
            ENDIF
            CALL PLANTE(1)
            STOP
          ENDIF
        ENDIF
! 
      ENDIF
!
!-----------------------------------------------------------------------
!
      LT=0
      LTT=0
!
!=======================================================================
! EXTENDS THE VARIABLES WHICH ARE NOT LINEAR P1
!=======================================================================
!
      IF(NTRAC.GT.0.AND.IELMT.NE.IELM1) THEN
        DO ITRAC=1,NTRAC
          CALL CHGDIS( T%ADR(ITRAC)%P ,IELM1 , IELMT , MESH )
        ENDDO
      ENDIF
      IF(IELMH.NE.IELM1) THEN
        CALL CHGDIS( H  , IELM1 , IELMH , MESH )
        CALL CHGDIS( ZF , IELM1 , IELMH , MESH )
      ENDIF
      IF(IELMU.NE.IELM1) THEN
        CALL CHGDIS( U , IELM1 , IELMU , MESH )
        CALL CHGDIS( V , IELM1 , IELMU , MESH )
      ENDIF
!
!=======================================================================
! INITIAL CONDITIONS NOT IN CONTINUATION FILE NOR IN CONDIN
!=======================================================================
!
!  CLIPPING (CONDITIONAL) OF H
!
      IF(CLIPH) CALL CLIP( H , HMIN , .TRUE. , 1.D6 , .FALSE. , 0 )
!
!-----------------------------------------------------------------------
! INITIAL WEATHER CONDITIONS
!
      IF (VENT.OR.ATMOS) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING METEO'
        CALL METEO(PATMOS%R,WINDX%R,WINDY%R,
     &             FUAIR,FVAIR,MESH%X%R,MESH%Y%R,AT,LT,NPOIN,VENT,ATMOS,
     &             H%R,T1%R,GRAV,ROEAU,NORD,PRIVE,
     &             T2DFO1,T2D_FILES,LISTIN,WATQUA,PLUIE)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM METEO'
      ENDIF
!
!-----------------------------------------------------------------------
! INITIAL BREACHES CONDITIONS
!
      IF (BRECHE) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BREACH'
        CALL BREACH
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BREACH'
      ENDIF
!
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
!
! READS THE GEOMETRY OF SINGULARITIES
!
      IF(NWEIRS.GT.0) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING LECSNG'
        CALL LECSNG(IOPTAN,T2D_FILES(T2DSEU)%LU)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM LECSNG'
      ENDIF
      IF(NSIPH.GT.0) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING LECSIP'
        CALL LECSIP(RELAXS,NSIPH,ENTSIP%I,SORSIP%I,SECSIP%R,
     &              ALTSIP%R,CSSIP%R,CESIP%R,DELSIP%R,
     &              ANGSIP%R,LSIP%R,T2D_FILES(T2DSIP)%LU,MESH)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM LECSIP'
      ENDIF
      IF(NBUSE.GT.0) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING LECBUS'
        CALL LECBUS(RELAXB,NBUSE,ENTBUS%I,SORBUS%I,LRGBUS%R,
     &              HAUBUS%R,CLPBUS%I,ALTBUS%R,CSBUS%R,CEBUS%R,
     &              ANGBUS%R,LBUS%R,T2D_FILES(T2DBUS)%LU,MESH)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM LECBUS'
      ENDIF
!
!-----------------------------------------------------------------------
!
! INITIAL CONDITIONS FOR K-EPSILON MODEL AND DIFFUSION
!
!   K-EPSILON
!
!     IF AKEP = .FALSE. K AND EPSILON COME FROM SUITE OR CONDIN
      IF(AKEP) THEN
!
        CALL FRICTION_CHOICE(1, KARMAN)
        IF(FRICTB) THEN
          KFROT_TP = 0
          IF(KFROT.EQ.NZONES) KFROT_TP = 1 ! NEED A NON ZERO VALUE
        ELSE
          KFROT_TP = KFROT
        ENDIF
!
        CALL AKEPIN(AK%R,EP%R,U%R,V%R,H%R,NPOIN,KFROT_TP,CMU,C2,
     &              ESTAR,SCHMIT,KMIN,EMIN,CF%R)
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!     PREPARES BOUNDARY CONDITIONS FOR WEIRS.
!
      IF(NWEIRS.GT.0) THEN
!
        IF(TYPSEUIL.EQ.1) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CLSING'
          CALL CLSING(NWEIRS,NPSING,NDGA1,NDGB1,
     &                MESH%X%R,MESH%Y%R,ZF%R,CHESTR%R,NKFROT%I,
     &                KARMAN,ZDIG,PHIDIG,MESH%NBOR%I,
     &                H%R,T,NTRAC,IOPTAN,T1%R,UBOR%R,VBOR%R,TBOR,
     &                LIHBOR%I,LIUBOR%I,LIVBOR%I,LITBOR,GRAV)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CLSING'
        ELSEIF(TYPSEUIL.EQ.2) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CALCUL_Q_WEIR'
          CALL CALCUL_Q_WEIR(NWEIRS,MESH%X%R,MESH%Y%R,ZF%R,H%R,CHESTR%R,
     &                       NKFROT%I,KARMAN,IOPTAN,NTRAC,T)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CALCUL_Q_WEIR'
        ELSE
          IF(LNG.EQ.1) THEN
            WRITE(LU,*)'LECSNG : TYPE DE SEUIL NON PROGRAMME '
          ELSEIF(LNG.EQ.2) THEN
            WRITE(LU,*)'LECSNG : TYPE OF WEIRS NOT IMPLEMENTED'
          ENDIF
        ENDIF
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!     TYPES OF CONDITIONS FOR TRACER:
!
      IF(NTRAC.GT.0) THEN
        IF(NWEIRS.GT.0.AND.TYPSEUIL.EQ.1)
     &    CALL CLTRAC(NWEIRS,NPSING,NDGA1,NDGB1,ZF%R,ZDIG,H%R,T,
     &                MESH%NBOR%I,LITBOR,TBOR,NTRAC)
        DO ITRAC=1,NTRAC
          CALL DIFFIN(MASKTR,LIMTRA%I,LITBOR%ADR(ITRAC)%P%I,
     &                IT1%I,U%R,V%R,MESH%XNEBOR%R,MESH%YNEBOR%R,
     &                MESH%NBOR%I,NPTFR,
     &                KENT,KSORT,KLOG,KNEU,KDIR,KDDL,
     &                ICONVFT(ITRAC),
     &                MESH%NELBOR%I,NPOIN,NELMAX,MSK,MASKEL%R,
     &                NFRLIQ,THOMFR,FRTYPE,
     &                TN%ADR(ITRAC)%P,TBOR%ADR(ITRAC)%P,MESH,NUMLIQ%I,
     &                MESH%IKLBOR%I,MESH%NELEB,MESH%NELEBX)
        ENDDO
      ENDIF
!
!     TYPES OF CONDITIONS FOR PROPAGATION:
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PROPIN'
      CALL PROPIN_TELEMAC2D
     &            (LIMPRO%I,LIMPRO%DIM1,MASK,LIUBOR%I,LIVBOR%I,
     &             LIHBOR%I,MESH%NBOR%I,NPTFR,
     &             KENT,KENTU,KSORT,KADH,KLOG,
     &             KNEU,KDIR,KDDL,CLH%I,CLU%I,CLV%I,
     &             U%ELM,U%R,V%R,GRAV,H%R,LT,NPOIN,
     &             MESH%NELBOR%I,NELMAX,MSK,MASKEL%R,
     &             NFRLIQ,THOMFR,NUMLIQ%I,FRTYPE,
     &             MESH%XNEBOR%R,MESH%YNEBOR%R,MESH%IKLBOR%I,ENTET,
     &             MESH%NELEBX,MESH%NELEB)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PROPIN'
!
!     PROPIN WILL BE CALLED IN THE TIME LOOP AFTER EACH CALL
!     TO BORD
!
!-----------------------------------------------------------------------
!
!     FRICTION COEFFICIENT:
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING FRICTION_CHOICE'
      CALL FRICTION_CHOICE(1,KARMAN)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM FRICTION_CHOICE'
!
!  DIFFUSION OF SPEED (CALLED HERE TO INITIALISE VISC IN CASE
!                           IT IS ONE OF THE OUTPUT VARIABLES)
      IF(ITURB.EQ.1) THEN
!
        CALL OS('X=C     ', X=VISC , C=PROPNU )
!
      ELSEIF(ITURB.EQ.2) THEN
!
        CALL DISPER( VISC , U%R , V%R , H%R , CF%R , ELDER , PROPNU )
!
      ELSEIF(ITURB.EQ.3) THEN
!
        CALL VISTUR(VISC,AK,EP,NPOIN,CMU,PROPNU)
!
      ELSEIF(ITURB.EQ.4) THEN
!
        CALL SMAGOR(VISC,CF,U,V,MESH,T1,T2,T3,T4,MSK,MASKEL,PROPNU)
!
      ELSE
        IF(LISTIN) THEN
          IF(LNG.EQ.1) WRITE(LU,15) ITURB
          IF(LNG.EQ.2) WRITE(LU,16) ITURB
        ENDIF
15      FORMAT(1X,'ITURB=',1I6,'MODELE DE TURBULENCE NON PREVU')
16      FORMAT(1X,'ITURB=',1I6,'UNKNOWN TURBULENCE MODEL')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!  LAGRANGIAN DRIFT(S)
!
      IF(NLAG.NE.0) CALL LAGRAN(NLAG,DEBLAG%I,FINLAG%I)
!
!-----------------------------------------------------------------------
!  LOCATION OF THE OUTLETS
!
      IF(NREJET.NE.0.OR.NREJTR.NE.0) THEN
        CALL PROXIM(ISCE,XSCE,YSCE,
     &              MESH%X%R,MESH%Y%R,
     &              NREJET,NPOIN,
     &              MESH%IKLE%I,NELEM,NELMAX)
      ENDIF
!
!-----------------------------------------------------------------------
!  INITIALISING THE ALGAE VARIABLES
!
      IF(ALGAE) THEN
!       ALLOCATE THE ALGAE VARIABLES IF NEEDED
        CALL ALLOC_ALGAE(NFLOT_MAX,MESH,DT)
        CALL OS('X=Y     ',X=U_X_AV_0,Y=U_X_AV)
        CALL OS('X=Y     ',X=U_Y_AV_0,Y=U_Y_AV)
        CALL OS('X=Y     ',X=U_Z_AV_0,Y=U_Z_AV)
        CALL OS('X=Y     ',X=K_AV_0  ,Y=K_AV)
        CALL OS('X=Y     ',X=EPS_AV_0,Y=EPS_AV)
        CALL OS('X=Y     ',X=U_X_0   ,Y=U_X)
        CALL OS('X=Y     ',X=U_Y_0   ,Y=U_Y)
        CALL OS('X=Y     ',X=U_Z_0   ,Y=U_Z)
        CALL OS('X=Y     ',X=V_X_0   ,Y=V_X)
        CALL OS('X=Y     ',X=V_Y_0   ,Y=V_Y)
        CALL OS('X=Y     ',X=V_Z_0   ,Y=V_Z)
      ENDIF
!
!=======================================================================
! END OF INITIAL CONDITIONS
!=======================================================================
!
! INITIALISES ADVECTION
! FTILD COMPRISES UTILD,VTILD,HTILD,(TTILD),(AKTILD AND EPTILD)
!
      CALL OS( 'X=0     ' , X=FTILD )
!
!***********************************************************************
!
! LISTING AND OUTPUT FOR THE INITIAL CONDITIONS.
!
      IF(LISTIN) CALL ENTETE(1,AT,LT)
!
!     OUTINI IS KEY-WORD "OUTPUT OF INITIAL CONDITONS"
!     IT HAS PRIORITY OVER FIRST TIME-STEP FOR GRAPHIC PRINTOUTS.
!
!     NOTE THAT OUTPUTS ARE DONE WITHIN ESTEL3D IN COUPLED MODE)
!
      IF(OUTINI .AND. (.NOT.ADJO)
     &          .AND. (CODE(1:7).NE.'ESTEL3D') ) THEN
!
! CONTROL SECTIONS (0. IN PLACE OF DT)
!
        IF(NCP.NE.0.AND.(ENTET.OR.CUMFLO)) THEN
          CALL FLUSEC_TELEMAC2D(U,V,H,MESH%IKLE%I,MESH%XEL%R,MESH%YEL%R,
     &                          MESH%NELMAX,MESH%NELEM,
     &                          MESH%X%R,MESH%Y%R,
     &                          0.D0,NCP,CTRLSC,ENTET,AT,
     &                          MSKSEC,BM1,BM2,T1,H,MESH,S,CV1,
     &                          MESH%IFABOR%I,COMFLU,CUMFLO)
        ENDIF
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PRERES_TELEMAC2D'
        CALL PRERES_TELEMAC2D
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PRERES_TELEMAC2D'
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING DESIMP'
        CALL BIEF_DESIMP(T2D_FILES(T2DRES)%FMT,VARSOR,
     &                  HIST,0,NPOIN,T2D_FILES(T2DRES)%LU,'STD',AT,LT,
     &                  LISPRD,LEOPRD,
     &                  SORLEO,SORIMP,MAXVAR,TEXTE,0,     0)
!                                                  PTINIG,PTINIL
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM DESIMP'
!
      ENDIF
!
!=======================================================================
!
!     COUPLING WITH DELWAQ
!
      IF(INCLUS(COUPLING,'DELWAQ')) THEN
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING TEL4DEL'
!
!     T3 : MODIFIED DEPTH TO TAKE INTO ACCOUNT MASS-LUMPING
!          IN THE CONTINUITY EQUATION
      IF(ABS(1.D0-AGGLOC).GT.1.D-8) THEN
        CALL VECTOR(T3 ,'=','MASVEC          ',IELMH,
     &              1.D0-AGGLOC,H ,S,S,S,S,S,MESH,MSK,MASKEL)
        IF(NCSIZE.GT.1) CALL PARCOM(T3,2,MESH)
        CALL OS('X=XY    ',X=T3 ,Y=UNSV2D)
        CALL OS('X=X+CY  ',X=T3 ,Y=H ,C=AGGLOC)
      ELSE
        CALL OS('X=Y     ',X=T3 ,Y=H )
      ENDIF
!
!     FIRST CALL FOR INITIALISATION, HENCE MESH%W%R IS NOT INITIALISED
!     WITH A CALL TO VECTOR, AS IN THE SECOND CALL
!
      CALL TEL4DEL(MESH%NPOIN,
     &        MESH%NPOIN,MESH%NELEM,MESH%NSEG,MESH%IKLE%I,MESH%ELTSEG%I,
     &        MESH%GLOSEG%I,MESH%ORISEG%I,MESH%GLOSEG%DIM1,
     &        MESH%X%R,MESH%Y%R,MESH%NPTFR,LIHBOR%I,
     &        MESH%NBOR%I,1,AT,DT,LT,NIT,T3%R,H%R,T3%R,U%R,V%R,
     &        T%ADR(MAX(IND_S,1))%P%R,
     &        T%ADR(MAX(IND_T,1))%P%R,VISC%R,TITCAS,
     &        T2D_FILES(T2DGEO)%NAME,T2D_FILES(T2DCLI)%NAME,WAQPRD,
     & T2DDL1,T2D_FILES(T2DDL1)%NAME,T2DDL2,T2D_FILES(T2DDL2)%NAME,
     & T2DDL3,T2D_FILES(T2DDL3)%NAME,T2DDL5,T2D_FILES(T2DDL5)%NAME,
     & T2DDL6,T2D_FILES(T2DDL6)%NAME,T2DDL7,T2D_FILES(T2DDL7)%NAME,
     & T2DL11,T2D_FILES(T2DL11)%NAME,T2DDL4,T2D_FILES(T2DDL4)%NAME,
     & T2DDL8,T2D_FILES(T2DDL8)%NAME,T2DDL9,T2D_FILES(T2DDL9)%NAME,
     & T2DL10,T2D_FILES(T2DL10)%NAME,INFOGR,NELEM,SALI_DEL,TEMP_DEL,
     & VELO_DEL,DIFF_DEL,MARDAT,MARTIM,FLODEL%R,V2DPAR%R,MESH%KNOLG%I)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM TEL4DEL'
!
      ENDIF
!
!=======================================================================
!
!     OPTIONAL USER OUTPUT (COURTESY JACEK JANKOWSKI, BAW)
      CALL UTIMP_TELEMAC2D(LT,AT,PTINIG,LEOPRD,PTINIL,LISPRD)
!
!=======================================================================
!
!  INITIALISES THE ADVECTION AND PROPAGATION FIELDS
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING HPROPA'
      CALL HPROPA(HPROP,H,H,PROLIN,HAULIN,TETAC,NSOUSI)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM HPROPA'
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING DE CHPCON'
      CALL CHPCON(UCONV,VCONV,U,V,U,V,TETAU)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CHPCON'
      IF(SOLSYS.EQ.2) THEN
        USIS=>UDEL
        VSIS=>VDEL
      ELSE
        USIS=>UCONV
        VSIS=>VCONV
      ENDIF
!
!=======================================================================
!
!     TETAHC: SEMI-IMPLICITATION OF H IN THE CONTINUITY EQUATION
!             IS ALSO USED FOR FLUXES IN THE MASS BALANCE
      TETAHC = TETAC
      IF(ICONVF(2).EQ.5) TETAHC = 0.D0
!
!     FIRST COMPUTATION OF POROSITY
!
      IF(OPTBAN.EQ.3) THEN
        CALL POROS(TE5,ZF,H,MESH)
        IF(MSK) CALL OS('X=XY    ',X=TE5,Y=MASKEL)
      ENDIF
!
! FIRST COMPUTATIONS FOR BALANCE
!
      IF(BILMAS) THEN
!
        MASSES = 0.D0
        FLUSOR = 0.D0
        FLUENT = 0.D0
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BILAN'
        CALL BILAN(MESH,H,T1,MASK,AT,DT,LT,NIT,ENTET,
     &             MASSES,MSK,MASKEL,EQUA,TE5,OPTBAN,
     &             MESH%NPTFR,FLBOR,
     &             FLUX_BOUNDARIES,NUMLIQ%I,NFRLIQ,GAMMA)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BILAN'
!
        IF(NTRAC.GT.0) THEN
!
          IF(EQUA(1:15).NE.'SAINT-VENANT VF') THEN
            IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BILANT'
            DO ITRAC=1,NTRAC
            MASSOU(ITRAC) = 0.D0
            CALL BILANT(H,T2,T3,DT,LT,NIT,LISTIN,
     &                  T%ADR(ITRAC)%P,
     &                  AGGLOT,MASSOU(ITRAC),MASTR0(ITRAC),
     &                  MASTR2(ITRAC),MASTEN(ITRAC),
     &                  MASTOU(ITRAC),MSK,MASKEL,MESH,FLBOR,
     &                  NUMLIQ%I,NFRLIQ,NPTFR,NAMETRAC(ITRAC),
     &                  FLBORTRA,MASS_RAIN,TRAIN(ITRAC),
     &                  MASTRAIN(ITRAC))
            ENDDO
            IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BILANT'
!
          ELSE
            FLUTSOR = 0.D0
            FLUTENT = 0.D0
            IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BILANT1'
            DO ITRAC=1,NTRAC
            CALL BILANT1(H,UCONV,VCONV,HPROP,T2,T3,T4,T5,T6,
     &                   DT,LT,NIT,ENTET,MASKTR,
     &                   T%ADR(1)%P,TN%ADR(1)%P,TETAT,
     &                   MASSOU(ITRAC),MSK,MASKEL,MESH,
     &                   FLUTSOR(ITRAC),FLUTENT(ITRAC),EQUA,LTT,ITRAC)
            ENDDO
            IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BILANT1'
          ENDIF
!
        ENDIF
!
      ENDIF
!
!=======================================================================
!
      IF(NIT.EQ.0) THEN
        IF(LISTIN) THEN
          IF(LNG.EQ.1) WRITE(LU,9)
          IF(LNG.EQ.2) WRITE(LU,10)
        ENDIF
9     FORMAT(1X,'ARRET DANS TELEMAC, NOMBRE D''ITERATIONS DEMANDE NUL')
10    FORMAT(1X,'STOP IN TELEMAC, NUMBER OF TIME STEP ASKED EQUALS 0')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!=======================================================================
!
!     COUPLING
!
      IF(COUPLING.NE.' ') THEN
        IF(LNG.EQ.1) WRITE(LU,*) 'TELEMAC2D COUPLE AVEC : ',COUPLING
        IF(LNG.EQ.2) WRITE(LU,*) 'TELEMAC2D COUPLED WITH: ',COUPLING
      ENDIF
!
      IF(INCLUS(COUPLING,'TOMAWAC')) THEN
!
        IF(LNG.EQ.1) THEN
          WRITE (LU,*) 'TELEMAC-2D : COUPLAGE INTERNE AVEC TOMAWAC'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE (LU,*) 'TELEMAC-2D: INTERNAL COUPLING WITH TOMAWAC'
        ENDIF
        CALL CONFIG_CODE(3)
        IF(DEBUG.GT.0) WRITE(LU,*) 'PREMIER APPEL DE TOMAWAC'
!       CALL WAC(0,U,V,H,FXWAVE,FYWAVE,WINDX,WINDY,CODE1,AT,DT,NIT,
!                PERCOU_WAC,DIRMOY,HM0,TPR5)
        CALL WAC(0,U,V,H,FXWAVE,FYWAVE,T1   ,T2   ,CODE1,AT,DT,NIT,
     &           PERCOU_WAC,DIRMOY,HM0,TPR5,ORBVEL)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM TOMAWAC'
        CALL CONFIG_CODE(1)
!
      ENDIF
!
!     INITIALISES CONSTANT FLOW DISCHARGE (SEE SISYPHE)
!     ------------------------------------------------------------------
!
      SISYPHE_CFD   = .FALSE.
      CONSTFLOW_SIS = .FALSE.
      NSIS_CFD      = 1
!
      IF(INCLUS(COUPLING,'SISYPHE')) THEN
!
        IF(INCLUS(COUPLING,'FILE-SISYPHE')) THEN
!
          WRITE (LU,*) 'TELEMAC-2D: FILE-COUPLING HAS NOW BEEN'
          WRITE (LU,*) '            SUPPRESSED'
          WRITE (LU,*) '            USE INTER-SISYPHE OR SISYPHE'
          WRITE (LU,*) '            INSTEAD OF FILE-SISYPHE'
          CALL PLANTE(1)
          STOP
!
        ELSEIF(INCLUS(COUPLING,'SISYPHE')) THEN
!
          IF(LNG.EQ.1) THEN
            WRITE (LU,*) 'TELEMAC-2D : COUPLAGE INTERNE AVEC SISYPHE'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE (LU,*) 'TELEMAC-2D: INTERNAL COUPLING WITH SISYPHE'
          ENDIF
          CALL CONFIG_CODE(2)
          IF(DEBUG.GT.0) WRITE(LU,*) 'PREMIER APPEL DE SISYPHE'
          CALL SISYPHE(0,LT,LEOPRD,LISPRD,NIT,U,V,H,H,ZF,CF,CF,CHESTR,
     &                 CONSTFLOW_SIS,NSIS_CFD,SISYPHE_CFD,CODE1,PERCOU,
     &                 U,V,AT,VISC,DT,CHARR,SUSP,
!                                     CHARR,SUSP : RETURNED BY SISYPHE
!                                                  BUT THEN GIVEN TO IT
     &                 FLBOR,SOLSYS,DM1,USIS,VSIS,ZCONV,
     &                 DIRMOY,HM0,TPR5,ORBVEL)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM SISYPHE'
          CALL CONFIG_CODE(1)
!         AVOIDS TWO OUTPUTS WHEN SISYPHE IS CALLED TWICE
          IF(SUSP.AND.CHARR.AND.PERCOU.NE.1) THEN
            LEOPRD_CHARR=NIT+PERCOU
          ELSE
            LEOPRD_CHARR=LEOPRD
          ENDIF
!
        ENDIF
!
      ENDIF
!
!=======================================================================
! INITIALISES INFILTRATION STRUCTURES FOR COUPLING WITH ESTEL3D
!
      CALL INFILTRATION_INIT(NPOIN,(CODE(1:7).EQ.'ESTEL3D'))
!
!     SAVES THE DEPTH CALCULATED BY TELEMAC2D FOR ESTEL3D
!
      IF(CODE(1:7).EQ.'ESTEL3D') CALL DEPTH_FILL(H%R)
!
!=======================================================================
!
! : 3                    /* TIME LOOP */
!
!=======================================================================
!
!     STORES DT FOR CASE WITH VARIABLE TIME-STEP
!
      DTCAS = DT
!
!     CALLED BY ANOTHER PROGRAM, ONLY INITIALISATION REQUIRED
      IF(PASS.EQ.0) THEN
        IF(LNG.EQ.1) WRITE(LU,*) 'FIN D''INITIALISATION DE TELEMAC2D'
        IF(LNG.EQ.2) WRITE(LU,*) 'TELEMAC2D INITIALISED'
        RETURN
      ENDIF
!
700   CONTINUE
!
      IF(PASS.EQ.1) THEN
        IF(CODE(1:7).EQ.'ESTEL3D') THEN
          AT=ATDEP
          NIT=NITER
! --- JP RENAUD START ---
!         USE THE TIME STEP SPECIFIED BY ESTEL-3D
          IF(PRESENT(DTDEP)) THEN
            DT = DTDEP
            DTCAS = DTDEP
          ! TO DO: CHECK WHAT HAPPENS WITH ADAPTIVE TIME STEP
          ENDIF
! --- JP RENAUD END ---
        ELSE
          IF(LNG.EQ.1) WRITE(LU,*) 'PROGRAM APPELANT INCONNU'
          IF(LNG.EQ.2) WRITE(LU,*) 'UNKNOWN CALLING PROGRAM'
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
      LT = LT + 1
!
      IF(BRECHE) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BREACH'
        CALL BREACH
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BREACH'
      ENDIF
!
      IF(DTVARI.AND.EQUA(1:15).NE.'SAINT-VENANT VF') THEN
!       COURANT NUMBER FOR PSI SCHEME IN P1
        CALL CFLPSI(T1,U,V,DT,IELM,MESH,MSK,MASKEL)
        CALL MAXI(CFLMAX,IMAX,T1%R,NPOIN)
!       LIMITS VARIATIONS IN THE RANGE (1/2, 2)
        DT = DT * MAX(MIN(CFLWTD/MAX(CFLMAX,1.D-6),2.D0),0.5D0)
!       LIMITS DT TO THAT OF THE STEERING FILE
        DT=MIN(DT,DTCAS)
        IF(NCSIZE.GT.1) DT=P_DMIN(DT)
        IF(ENTET) THEN
          IF (LNG.EQ.1) WRITE(LU,78) CFLMAX,DT
          IF (LNG.EQ.2) WRITE(LU,79) CFLMAX,DT
78        FORMAT(1X,'    NOMBRE DE COURANT MAXIMUM :',G16.7,/,1X,
     &              '    PAS DE TEMPS              :',G16.7)
79        FORMAT(1X,'    MAXIMUM COURANT NUMBER: ',G16.7,/,1X,
     &              '    TIME-STEP                 :',G16.7)
        ENDIF
      ENDIF
!
!=======================================================================
!
!     COUPLING WITH TOMAWAC
!
      IF(INCLUS(COUPLING,'TOMAWAC').AND.
     &   PERCOU_WAC*((LT-1)/PERCOU_WAC).EQ.LT-1) THEN
!
        CALL CONFIG_CODE(3)
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING TOMAWAC'
!       CALL WAC(1,U,V,H,FXWAVE,FYWAVE,WINDX,WINDY,CODE1,AT,
!    &           DT,NIT,PERCOU_WAC,DIRMOY,HM0,TPR5)
        CALL WAC(1,U,V,H,FXWAVE,FYWAVE,T1   ,T2   ,CODE1,AT,
     &           DT,NIT,PERCOU_WAC,DIRMOY,HM0,TPR5,ORBVEL)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM TOMAWAC'
        CALL CONFIG_CODE(1)
!
      ENDIF
!
!=======================================================================
!
      IF(ADJO) THEN
        AT = AT - DT
      ELSE
!       DT IS NOT YET KNOWN IN FINITE VOLUMES
        IF(EQUA(1:15).NE.'SAINT-VENANT VF') AT = AT + DT
      ENDIF
!
      IF(DTVARI) THEN
        IF(AT.GT.DUREE+AT0) THEN
!         LAST TIME STEP
          NIT = LT
        ELSE
!         DUMMY VALUE GREATER THAN LT
          NIT = LT + 10
        ENDIF
      ENDIF
!
      IF((LISPRD*(LT/LISPRD).EQ.LT.AND.LT.GE.PTINIL).OR.LT.EQ.NIT) THEN
        ENTET=LISTIN
      ELSE
        ENTET=.FALSE.
      ENDIF
! 
!     CONSTRAINS TELEMAC-2D OUTPUT IN THE LISTING
!
      IF (PRESENT(DOPRINT)) ENTET = ENTET .AND. DOPRINT
! 
      IF(ENTET) CALL ENTETE(2,AT,LT)
!
!=======================================================================
!
! BACKUP OF UN, VN, HN, TN, AKN AND EPN (THEY ARE IN FN)
!
! THIS IS NOT DONE WHEN ITERATING FOR THE COUPLING WITH ESTEL-3D
      IF(CODE(1:7).EQ.'ESTEL3D'.AND.PRESENT(NEWTIME)) THEN
        IF(NEWTIME) CALL OS('X=Y     ',X=FN,Y=F)
      ELSE
        CALL OS('X=Y     ',X=FN,Y=F)
      ENDIF
!     CALL OS( 'X=Y     ' , FN , F , F , C )
!
!=======================================================================
!
! NEW COUPLING WITH SISYPHE FOR CONSTANT FLOW DISCHARGE
!
      IF(SISYPHE_CFD.AND.CONSTFLOW_SIS) GOTO 999
!
      DO ISIS_CFD=1,NSIS_CFD
!
!=======================================================================
!
!  MASKING OF THE WETTING/DRYING ELEMENTS
!
      IF(MSK) CALL OS( 'X=C     ' , MASKEL , S , S , 1.D0 )
      IF (OPTBAN.EQ.2) THEN
        CALL MASKBD(MASKEL%R,ZFE%R,ZF%R,H%R,
     &              HMIN,MESH%IKLE%I,MESH%IFABOR%I,IT1%I,NELEM,NPOIN)
      ENDIF
!
!  MASKING SPECIFIED BY USER
!
      IF(MSKUSE) THEN
        CALL MASKOB(MASKEL%R,MESH%X%R,MESH%Y%R,
     &              MESH%IKLE%I,NELEM,NELMAX,NPOIN,AT,LT)
      ENDIF
!
! CREATES THE MASK OF THE POINTS FROM THE MASK OF THE ELEMENTS
! AND CHANGES OF IFAMAS (IFABOR WITH MASKING)
!
      IF(MSK) THEN
        CALL MASKTO(MASKEL%R,MASKPT,IFAMAS%I,MESH%IKLE%I,
     &              MESH%IFABOR%I,MESH%ELTSEG%I,MESH%NSEG,
     &              NELEM,NPOIN,IELMT,MESH)
        IF(IELMX.NE.IELM1) CALL CHGDIS(MASKPT,IELM1,IELMX,MESH)
      ENDIF
!
!-----------------------------------------------------------------------
!  COMPUTATION OF THE INTEGRAL OF THE BASES
!-----------------------------------------------------------------------
!
!     IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING MASBAS2D'
!     IF(MSK) THEN
!       CALL MASBAS2D(VOLU2D,V2DPAR,UNSV2D,IELM1,MESH,MSK,MASKEL,T2,T2)
!     ENDIF
!     IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM MASBAS2D'
!
!-----------------------------------------------------------------------
!
! UPDATES POROSITY : NEW VALUE IN TE5
!                    OLD - NEW IN TE4
!
      IF(OPTBAN.EQ.3) THEN
!
        CALL OS('X=Y     ',TE4,TE5,TE5,0.D0)
        CALL POROS(TE5,ZF,HN,MESH)
        IF(MSK) CALL OS('X=XY    ',X=TE5,Y=MASKEL)
!       TEST OF UNDER-RELAXATION
        RELAX = 0.05D0
        CALL OS('X=CX    ',X=TE5,C=RELAX)
        CALL OS('X=X+CY  ',X=TE5,Y=TE4,C=1.D0-RELAX)
!       TE4 = OLD POROS - NEW POROS
        CALL OS('X=X-Y   ',X=TE4,Y=TE5)
!
      ENDIF
!
!=======================================================================
!
! NEW ADVECTION AND PROPAGATION FIELDS
! NOTE THAT U = UN, V = VN AND H = HN AT THIS STAGE
!
      IF(CONV) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CHPCON'
        CALL CHPCON(UCONV,VCONV,U,V,UN,VN,TETAU)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CHPCON'
      ENDIF
!
!     COMPUTATION OF THE NEW PROPAGATION TERM
!
      IF(PROPA) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING HPROPA'
        CALL HPROPA(HPROP ,HN,H,PROLIN,HAULIN,TETAHC,NSOUSI)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM HPROPA'
      ENDIF
!
!=======================================================================
!
! PREPARES BOUNDARY CONDITIONS FOR WEIRS.
!
      IF(NWEIRS.GT.0) THEN
!
        IF(TYPSEUIL.EQ.1) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CLSING'
          CALL CLSING(NWEIRS,NPSING,NDGA1,NDGB1,
     &                MESH%X%R,MESH%Y%R,ZF%R,CHESTR%R,NKFROT%I,
     &                KARMAN,ZDIG,PHIDIG,MESH%NBOR%I,
     &                H%R,T,NTRAC,IOPTAN,T1%R,UBOR%R,VBOR%R,TBOR,
     &                LIHBOR%I,LIUBOR%I,LIVBOR%I,LITBOR,GRAV)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CLSING'
        ELSEIF(TYPSEUIL.EQ.2) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CALCUL_Q_WEIR'
          CALL CALCUL_Q_WEIR(NWEIRS,MESH%X%R,MESH%Y%R,ZF%R,H%R,
     &                       CHESTR%R,NKFROT%I,KARMAN,IOPTAN,NTRAC,T)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CALCUL_Q_WEIR'
        ELSE
          IF(LNG.EQ.1) THEN
            WRITE(LU,*)'LECSNG : TYPE DE SEUIL NON PROGRAMME '
          ELSEIF(LNG.EQ.2) THEN
            WRITE(LU,*)'LECSNG : TYPE OF WEIRS NOT IMPLEMENTED'
          ENDIF
        ENDIF
!
      ENDIF
!
! IT IS ASSUMED THAT THE TYPES OF BOUNDARY CONDITIONS DO NOT CHANGE
! DURING THE SUB-ITERATIONS. IF NOT IT IS NECESSARY TO MOVE THE CALLS
! TO KEPSIN, DIFFIN, PROPIN
!
! TYPES OF CONDITIONS FOR THE K-EPSILON MODEL
!
      IF(ITURB.EQ.3) CALL KEPSIN(LIMKEP%I,LIUBOR%I,NPTFR,
     &                           KENT,KENTU,KSORT,KADH,KLOG,
     &                           KINC,KNEU,KDIR)
!
! TYPES OF CONDITIONS FOR THE DIFFUSION OF THE TRACER:
!
      IF(NTRAC.GT.0) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING DIFFIN'
        DO ITRAC=1,NTRAC
        CALL DIFFIN(MASKTR,LIMTRA%I,LITBOR%ADR(ITRAC)%P%I,
     &              IT1%I,UCONV%R,VCONV%R,
     &              MESH%XNEBOR%R,MESH%YNEBOR%R,
     &              MESH%NBOR%I,NPTFR,
     &              KENT,KSORT,KLOG,KNEU,KDIR,KDDL,
     &              ICONVFT(ITRAC),
     &              MESH%NELBOR%I,NPOIN,NELMAX,MSK,MASKEL%R,
     &              NFRLIQ,THOMFR,FRTYPE,
     &              TN%ADR(ITRAC)%P,TBOR%ADR(ITRAC)%P,MESH,NUMLIQ%I,
     &              MESH%IKLBOR%I,MESH%NELEB,MESH%NELEBX)
        ENDDO
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM DIFFIN'
      ENDIF
!
! TYPES OF CONDITIONS FOR THE PROPAGATION:
! REQUIRED FOR THOMFR ?? (OTHERWISE DONE AFTER BORD !)
!
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PROPIN'
      CALL PROPIN_TELEMAC2D
     &            (LIMPRO%I,LIMPRO%DIM1,MASK,LIUBOR%I,LIVBOR%I,
     &             LIHBOR%I,MESH%NBOR%I,NPTFR,
     &             KENT,KENTU,KSORT,KADH,KLOG,
     &             KNEU,KDIR,KDDL,CLH%I,CLU%I,CLV%I,
     &             U%ELM,U%R,V%R,GRAV,H%R,LT,NPOIN,
     &             MESH%NELBOR%I,NELMAX,MSK,MASKEL%R,
     &             NFRLIQ,THOMFR,NUMLIQ%I,FRTYPE,
     &             MESH%XNEBOR%R,MESH%YNEBOR%R,MESH%IKLBOR%I,.FALSE.,
     &             MESH%NELEBX,MESH%NELEB)
!    *             MESH%XNEBOR%R,MESH%YNEBOR%R,MESH%IKLBOR%I,ENTET )
!       WARNINGS WILL BE GIVEN AT THE SECOND CALL AFTER BORD
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PROPIN'
!
!=======================================================================
!                 COMPUTES THE FRICTION COEFFICIENTS
!                         VARIABLE IN TIME
!=======================================================================
! CORSTR DOES NOT DO ANYTHING UNLESS MODIFIED BY THE USER.
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CORSTR'
      CALL CORSTR
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CORSTR'
!
      IF(IELMU.EQ.12.OR.IELMU.EQ.13) THEN
        CALL CHGDIS(CHESTR,DISCLIN,IELMU,MESH)
      ENDIF
!
      CALL FRICTION_CHOICE(1,KARMAN)
!
!=======================================================================
!                 COMPUTES VISCOSITY COEFFICIENTS
!=======================================================================
!
!  COMPUTES DYNAMIC VISCOSITY VISC
!
      IF(ITURB.EQ.1) THEN
!
        CALL OS( 'X=C     ' , VISC , VISC , VISC , PROPNU )
!
      ELSEIF(ITURB.EQ.2) THEN
!
        CALL DISPER( VISC , U%R , V%R , H%R , CF%R , ELDER , PROPNU )
!
      ELSEIF(ITURB.EQ.3) THEN
!
        CALL VISTUR(VISC,AK,EP,NPOIN,CMU,PROPNU)
!
      ELSEIF(ITURB.EQ.4) THEN
!
        CALL SMAGOR(VISC,CF,U,V,MESH,T1,T2,T3,T4,MSK,MASKEL,PROPNU)
!
      ELSE
!
        IF(LISTIN) THEN
          IF(LNG.EQ.1) WRITE(LU,15) ITURB
          IF(LNG.EQ.2) WRITE(LU,16) ITURB
        ENDIF
        CALL PLANTE(1)
        STOP
!
      ENDIF
!
!  COEFFICIENT FOR THERMAL DIFFUSION (PRANDTL = 1 FOR NOW)
!  AND THE SAME FOR ALL THE TRACERS
!
      IF(NTRAC.GT.0.AND.DIFT) THEN
        DO ITRAC=1,NTRAC
          CALL OS( 'X=Y     ' , X=VISCT%ADR(ITRAC)%P , Y=VISC )
          CALL OS( 'X=X+C   ' , X=VISCT%ADR(ITRAC)%P , C=DIFNU-PROPNU )
        ENDDO
      ENDIF
!
!  IT IS POSSIBLE TO CORRECT THE VISCOSITY COEFFICIENTS.
!
      CALL CORVIS
!
!=======================================================================
!  SOURCES : COMPUTATION OF INPUTS WHEN VARYING IN TIME
!            IF NO VARIATION IN TIME DSCE2=DSCE AND TSCE2=TSCE
!=======================================================================
!
      IF(NREJET.GT.0) THEN
        DO I=1,NREJET
          DSCE2(I)=DEBSCE(AT,I,DSCE)
        ENDDO
        IF(NTRAC.GT.0) THEN
          DO I=1,NREJET
            DO ITRAC=1,NTRAC
              TSCE2(I,ITRAC)=TRSCE(AT,I,ITRAC)
            ENDDO
          ENDDO
        ENDIF
      ENDIF
!
!=======================================================================
! BOUNDARY CONDITIONS
!=======================================================================
!
      IF(THOMFR) THEN
!
      CALL CPSTVC(H,T9)
      CALL PREBOR(HBOR%R,UBOR%R,VBOR%R,TBOR,U%R,V%R,H%R,
     &            T9%R,T,MESH%NBOR%I,
     &            NPOIN,NPTFR,NTRAC,NFRLIQ,FRTYPE,NUMLIQ%I)
!
      ENDIF
!
! CALLS THE USER-SUBROUTINE DETERMINING THE BOUNDARY CONDITIONS.
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BORD'
      CALL BORD(HBOR%R,UBOR%R,VBOR%R,TBOR,
     &          U,V,H,ZF%R,MESH%NBOR%I,W1,T8,
     &          LIHBOR%I,LIUBOR%I,LITBOR,
     &          MESH%XNEBOR%R,MESH%YNEBOR%R,NPOIN,NPTFR,
     &          NPTFR2,AT,
     &          NDEBIT,NCOTE,NVITES,NTRAC,NTRACE,NFRLIQ,NUMLIQ%I,
     &          KENT,KENTU,PROVEL,MASK,MESH,EQUA,T2D_FILES(T2DIMP)%NAME)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BORD'
!
! COMPUTES LIMPRO, CLU,CLV, CLH AND MASK
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PROPIN'
      CALL PROPIN_TELEMAC2D
     &            (LIMPRO%I,LIMPRO%DIM1,MASK,LIUBOR%I,LIVBOR%I,
     &             LIHBOR%I,MESH%NBOR%I,NPTFR,
     &             KENT,KENTU,KSORT,KADH,KLOG,
     &             KNEU,KDIR,KDDL,CLH%I,CLU%I,CLV%I,
     &             U%ELM,U%R,V%R,GRAV,H%R,LT,NPOIN,
     &             MESH%NELBOR%I,NELMAX,MSK,MASKEL%R,
     &             NFRLIQ,THOMFR,NUMLIQ%I,FRTYPE,
     &             MESH%XNEBOR%R,MESH%YNEBOR%R,MESH%IKLBOR%I,ENTET,
     &             MESH%NELEBX,MESH%NELEB)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PROPIN'
!
! PREPARING THE FRICTION ON THE LATERAL BOUNDARIES
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING WALL_FRICTION'
      CALL WALL_FRICTION(UETUTA%R,AUBOR%R,CFBOR%R,
     &                   MESH%DISBOR%R,UN%R,VN%R,LIMPRO%I,
     &                   MESH%NBOR%I,NPTFR,KARMAN,PROPNU,
     &                   LISRUG,KNEU,KDIR,KENT,KENTU,KADH,KLOG,
     &                   IELMU,MESH%IKLBOR%I,MESH%NELEB,MESH%NELEBX)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM WALL_FRICTION'
!
! K-EPSILON BOUNDARY CONDITIONS: KBOR,EBOR AND AUBOR
!
      IF(ITURB.EQ.3) THEN
        CALL KEPSCL(KBOR%R,EBOR%R,AUBOR%R,CF%R,CFBOR%R,
     &              MESH%DISBOR%R,
     &              UN%R,VN%R,HN%R,LIMKEP%I,LIUBOR%I,LIMPRO%I,
     &              MESH%NBOR%I,NPTFR,KARMAN,CMU,C2,ESTAR,
     &              SCHMIT,LISRUG,PROPNU,KMIN,EMIN,KNEU,KDIR,
     &              KENT,KENTU,KADH,KLOG,UETUTA%R)
      ENDIF
!
! CALLS THE SYSTEM OF RESOLUTION FOR BOUNDARIES BY THE CHARACTERISTICS
! METHOD (THOMPSON)
!
      IF(THOMFR) THEN
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING THOMPS'
      CALL THOMPS(HBOR%R,UBOR%R,VBOR%R,TBOR,U,V,T9,
     &            T,ZF,MESH%X%R,MESH%Y%R,MESH%NBOR%I,
     &            FRTYPE,T2,T3,T4,T7,T10,T11,
     &            LIHBOR%I,LIUBOR%I,LIVBOR%I,LITBOR,IT1%I,
     &            IT2%I,CV2%R,CV3%R,TE1%R,HTILD,UTILD,VTILD,
     &            TTILD,T15,MESH%SURDET%R,MESH%IKLE%I,
     &            MESH%IFABOR%I,NELEM,MESH,
     &            MESH%XNEBOR%R,MESH%YNEBOR%R,
     &            NPOIN,NPTFR,DT,GRAV,NTRAC,
     &            NFRLIQ,KSORT,KINC,KENT,KENTU,MESH%LV,MSK,MASKEL,
     &            NELMAX,IELM,T5%R,NUMLIQ%I,BM1%X%R,
     &            T12%R,T13%R,T14%R,IT3,IT4,
     &            T17,T18,T19,T20,T21,T22,W1)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM THOMPS'
!
      ENDIF
!
!     CHECKS HBOR BECAUSE THE USER CAN MODIFY BORD AND MAKE A MISTAKE
      CALL CLIP(HBOR,0.D0,.TRUE.,1.D6,.FALSE.,0)
!
!=======================================================================
!
! LOOP OVER THE SUB-ITERATIONS WHERE ADVECTION AND PROPAGATION ARE UPDATED
!
!=======================================================================
!
      DO ISOUSI = 1 , NSOUSI
      IF(DEBUG.GT.0) WRITE(LU,*) 'BOUCLE 701 ISOUSI=',ISOUSI
!
!=======================================================================
!
! : 4                     ADVECTION
!
!=======================================================================
!
      IF(CONV.AND.(FTILD%N.GT.0.OR.FTILD2%N.GT.0)) THEN
!
        IF(ENTET) CALL ENTETE(3,AT,LT)
!
        IF(SPHERI) THEN
          CALL OS('X=Y/Z   ',UCONV,UCONV,MESH%COSLAT,C)
          CALL OS('X=Y/Z   ',VCONV,VCONV,MESH%COSLAT,C)
        ENDIF
!
!       COMPUTATION OF STRONG CHARACTERISTICS AND INTERPOLATION
!
        IF(FTILD%N.GT.0) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CHARAC OPTION STRONG'
          CALL CHARAC(FNCAR , FTILD  , FTILD%N  , UCONV , VCONV,S,S,S,S,
     &                DT    , IFAMAS , IELM     , NPOIN , 1,1,1,
     &                MSK   , MASKEL , BM1%X    , BM1%D , BM1%D , TB   ,
     &                IT1%I , IT2%I  , IT2%I    ,IT3%I  , IT4%I , IT2%I,
     &                MESH  , MESH%NELEM        ,MESH%NELMAX    ,
     &                MESH%IKLE,MESH%SURDET,
!                     FOR WEAK FORM OF ADVECTION                OPTCHA
     &                AM1,CV1,SLVPRO,AGGLOW,ENTET,NGAUSS,UNSV2D,1)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CHARAC OPTION STRONG'
        ENDIF
!
!       COMPUTATION OF WEAK CHARACTERISTICS AND INTERPOLATION
!
        IF(FTILD2%N.GT.0) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CHARAC OPTION STRONG'
          CALL CHARAC(FNCAR2, FTILD2 , FTILD2%N , UCONV , VCONV,S,S,S,S,
     &                DT    , IFAMAS , IELM     , NPOIN , 1,1,1,
     &                MSK   , MASKEL , BM1%X    , BM1%D , BM1%D , TB   ,
     &                IT1%I , IT2%I  , IT2%I    ,IT3%I  , IT4%I , IT2%I,
     &                MESH  , MESH%NELEM        ,MESH%NELMAX    ,
     &                MESH%IKLE,MESH%SURDET,
!                     FOR WEAK FORM OF ADVECTION                OPTCHA
     &                AM1,CV1,SLVPRO,AGGLOW,ENTET,NGAUSS,UNSV2D,2)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CHARAC OPTION STRONG'
        ENDIF
!
        IF(SPHERI) THEN
          CALL OS('X=XY    ',UCONV,MESH%COSLAT,S,C)
          CALL OS('X=XY    ',VCONV,MESH%COSLAT,S,C)
        ENDIF
!
      ENDIF
!
! MANAGEMENT OF THE ARRAYS.
!
      CALL GESTIO(UN   ,VN   ,HN   ,TN   ,AKN   ,EPN   ,
     &            UTILD,VTILD,HTILD,TTILD,AKTILD,EPTILD,
     &            NTRAC.GT.0,PROPA,CONVV,ITURB,3)
!
!=======================================================================
!                       END OF ADVECTION
!=======================================================================
!=======================================================================
!
! : 6                DIFFUSION - PROPAGATION
!
!=======================================================================
!
      IF(PROPA) THEN
      IF(ENTET) CALL ENTETE(6,AT,LT)
!     INFORMATION ON THE METHOD OF RESOLUTION IS GIVEN ONLY
!     IF LISTING IS REQUESTED
      INFOGS=.FALSE.
      IF(INFOGR.AND.ENTET) INFOGS=.TRUE.
!
!  WEATHER CONDITIONS.
!
      IF(VENT.OR.ATMOS) THEN
        CALL METEO(PATMOS%R,WINDX%R,WINDY%R,
     &             FUAIR,FVAIR,MESH%X%R,MESH%Y%R,AT,LT,NPOIN,VENT,ATMOS,
     &             H%R,T1%R,GRAV,ROEAU,NORD,PRIVE,
     &             T2DFO1,T2D_FILES,LISTIN,WATQUA,PLUIE)
      ENDIF
!
!  COMPUTES THE DENSITY WHEN IT IS VARIABLE
!
      IF(ROVAR) THEN
!       BEWARE, SALINITY MUST BE HERE THE FIRST TRACER
        CALL VALRO(RO,T,ROEAU)
      ENDIF
!
!  SOURCE TERMS DUE TO NOZZLES AND SIPHONS.
!
      IF(NSIPH.GT.0) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING SIPHON'
        CALL SIPHON(RELAXS,NSIPH,ENTSIP%I,SORSIP%I,GRAV,
     &              H%R,ZF%R,DSIP%R,SECSIP%R,ALTSIP%R,CSSIP%R,CESIP%R,
     &              DELSIP%R,ANGSIP%R,LSIP%R,
     &              NTRAC,T,TSIP,USIP%R,VSIP%R,U%R,V%R,ENTET)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM SIPHON'
      ENDIF
!
!  SOURCE TERMS DUE TO TUBES OR BRIDGES.
!
      IF(NBUSE.GT.0) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BUSE'
        CALL BUSE(RELAXB,NBUSE,ENTBUS%I,SORBUS%I,GRAV,
     &            H%R,ZF%R,DBUS%R,LRGBUS%R,HAUBUS%R,CLPBUS%I,
     &            ALTBUS%R,CSBUS%R,CEBUS%R,ANGBUS%R,LBUS%R,
     &            NTRAC,T,TBUS,UBUS%R,VBUS%R,U%R,V%R,ENTET)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BUSE'
      ENDIF
!
!  SOURCE TERMS FOR PROPAGATION.
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PROSOU'
      CALL PROSOU(FU,FV,SMH,UN,VN,HN,GRAV,NORD,
     &            FAIR,WINDX,WINDY,VENT,HWIND,
     &            CORIOL,FCOR,SPHERI,YASMH,
     &            MESH%COSLAT,MESH%SINLAT,AT,LT,DT,
     &            NREJET,NREJEU,DSCE2,ISCE,T1,MESH,MSK,MASKEL,
     &            MAREE,MARDAT,MARTIM,PHI0,OPTSOU,COUROU,NPTH,
     &            VARCL,NVARCL,VARCLA,UNSV2D,FXWAVE,FYWAVE,
     &            RAIN,RAIN_MMPD,PLUIE,T2D_FILES,T2DBI1,
     &            BANDEC,OPTBAN,
     &            NSIPH,ENTSIP%I,SORSIP%I,DSIP%R,USIP%R,VSIP%R,
     &            NBUSE,ENTBUS%I,SORBUS%I,DBUS%R,UBUS%R,VBUS%R,
     &            TYPSEUIL,NWEIRS,
     &            NPSING,NDGA1,NDGB1,MESH%NBOR)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PROSOU'
!
!  PROPAGATION.
!
      IF(EQUA(1:15).EQ.'SAINT-VENANT EF'.OR.
     &   EQUA(1:10).EQ.'BOUSSINESQ') THEN
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PROPAG'
      CALL PROPAG
     &(U,V,H,UCONV,VCONV,CONVV,H0,PATMOS,ATMOS,
     & HPROP,UN,VN,HN,UTILD,VTILD,HTILD,DH,DU,DV,DHN,VISC,VISC_S,
     & FU,FV,
     & SMH,MESH,ZF,AM1,AM2,AM3,BM1,BM2,CM1,CM2,TM1,A23,A32,MBOR,
     & CV1,CV2,CV3,W1,UBOR,VBOR,AUBOR,HBOR,DIRBOR,
     & TE1,TE2,TE3,TE4,TE5,T1,T2,T3,T4,T5,T6,T7,T8,
     & LIMPRO,MASK,GRAV,ROEAU,CF,DIFVIT,IORDRH,IORDRU,LT,AT,DT,
     & TETAC,TETAHC,TETAU,TETAD,
     & AGGLOC,AGGLOU,KDIR,INFOGS,KFROT,ICONVF,
     & PRIVE,ISOUSI,BILMAS,MASSES,MASS_RAIN,YASMH,OPTBAN,CORCON,
     & OPTSUP,MSK,MASKEL,MASKPT,RO,ROVAR,
     & MAT,RHS,UNK,TB,S,TB,PRECCU,SOLSYS,CFLMAX,OPDVIT,
!                       TB HERE TO REPLACE BD SUPPRESSED, NOT USED
     & OPTSOU,NFRLIQ,SLVPRO,EQUA,VERTIC,ADJO,ZFLATS,TETAZCOMP,
     & UDEL,VDEL,DM1,ZCONV,COUPLING,FLBOR,BM1S,BM2S,CV1S,
     & VOLU2D,V2DPAR,UNSV2D,NDGA1,NDGB1,NWEIRS,NPSING,HFROT,
     & FLULIM,YAFLULIM,RAIN,PLUIE,MAXADV,OPTADV_VI)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PROPAG'
!
      IF(ADJO) THEN
!
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING PROPAG_ADJ'
        CALL PROPAG_ADJ
     &( UCONV,VCONV,CONVV,H0,PATMOS,ATMOS,
     &  HPROP,UN,VN,HN,UTILD,VTILD,HTILD,DH,DU,DV,DHN,VISC,VISC_S,
     &  FU,FV,SMH,MESH,ZF,AM1,AM2,AM3,BM1,BM2,CM1,CM2,TM1,A23,A32,
     &  MBOR,CV1,CV2,CV3,W1,UBOR,VBOR,AUBOR,HBOR,DIRBOR,
     &  TE1,TE2,TE3,TE4,TE5,T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,
     &  LIMPRO,MASK,GRAV,ROEAU,CF,DIFVIT,IORDRH,IORDRU,LT,AT,DT,
     &  TETAC,TETAHC,TETAU,TETAD,
     &  AGGLOC,AGGLOU,KDIR,INFOGS,KFROT,ICONVF,
     &  PRIVE,ISOUSI,BILMAS,MASSES,YASMH,OPTBAN,CORCON,
     &  OPTSUP,MSK,MASKEL,MASKPT,RO,ROVAR,
     &  MAT,RHS,UNK,TB,S,TB,PRECCU,SOLSYS,CFLMAX,OPDVIT,
     &  OPTSOU,NFRLIQ,SLVPRO,EQUA,VERTIC,
     &  ADJO,UD,VD,HD,U,V,H,UU,VV,HH,UIT1,VIT1,HIT1,PP,QQ,RR,
     &  TAM1,TAM2,TAM3,TBM1,TBM2,TCM1,TCM2,MATADJ,UNKADJ,
     &  ALPHA1,ALPHA2,ALPHA3,ADJDIR,ESTIME,OPTCOST,NIT,NVARRES,
     &  VARSOR,T2D_FILES(T2DRES)%LU,T2D_FILES(T2DREF)%LU,
     &  ALIRE,TROUVE,MAXVAR,VARCL,VARCLA,TEXTE,
     &  TEXREF,TEXRES,W,OUTINI,CHESTR,KARMAN,NDEF,ITURB,LISRUG,
     &  LINDNER,SB,DP,SP,CHBORD,CFBOR,HFROT,UNSV2D)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM PROPAG_ADJ'
!
      ENDIF
!
      ELSEIF(EQUA(1:15).EQ.'SAINT-VENANT VF') THEN
!
!       VOLFIN MAY CHANGE DT
!
!       CM1%D%R : HT
!       
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING VOLFIN'
        CALL VOLFIN(W1%R,AT,DT,LT,NELEM,NPTFR,MESH%NSEG,
     &       TB,ZF%R,CHESTR%R,NPOIN,HN%R,H%R,U%R,V%R,QU%R,QV%R,
     &       GRAV,ENTET,MESH,LIMPRO%I,
     &       MESH%NBOR%I,KDIR,KNEU,KDDL,HBOR%R,UBOR%R,VBOR%R,
     &       MASSES,FLUENT,FLUSOR,CFLWTD,DTVARI,KFROT,
     &       NREJET,ISCE,TSCE2,MAXSCE,MAXTRA,YASMH,SMH%R,
     &       NTRAC,T%ADR(1)%P%DIM1,T,HT,TN,
     &       TBOR,MASSOU,FLUTENT,FLUTSOR,MESH%DTHAUT%R,
     &       MESH%DPX%R,MESH%DPY%R,CM1%X%R,CM2%X%R,
     &       MESH%CMI%R,MESH%JMI%I,TE1%R,TE2%R,
     &       DIFVIT,ITURB,PROPNU,DIFT,DIFNU,
     &       BM1%X%R,BM2%X%R,OPTVF,
     &       HSTOK%R,HCSTOK%R,LOGFR%I,DSZ%R,FLUXT,FLUHBOR,
     &       FLBOR,DTN,FLUSORTN,FLUENTN,
     &       LTT,FLUXTEMP,FLUHBTEMP,HC%R,SMTR,MESH%AIRST%R,
     &       TMAX,DTT,GAMMA,FLUX_OLD,MXPTVS,NEISEG%I,V2DPAR)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM VOLFIN'
!       
        AT = AT + DT
        IF (LT.GE.NIT.OR.AT.GE.TMAX) THEN !LAST TIME STEP
           NIT = LT         
           LEOPRD = LT ! TO GET OUTPUT OF LAST TIME STEP IN RESULT FILE
           ENTET = .TRUE.
           CALL ENTETE(1,AT,LT)
        ENDIF
!
      ELSE
!
        IF(LNG.EQ.1) WRITE(LU,*) 'EQUATIONS INCONNUES : ',EQUA
        IF(LNG.EQ.2) WRITE(LU,*) 'UNKNOWN EQUATIONS: ',EQUA
        CALL PLANTE(1)
        STOP
!
      ENDIF
!
! IF NO PROPAGATION :
!
      ELSE
!
! MANAGEMENT OF THE ARRAYS .
!
        CALL GESTIO(U    ,V    ,H    ,T,AK  ,EP ,
     &              UTILD,VTILD,HTILD,T,AK  ,EP ,
     &              NTRAC.GT.0,PROPA,CONVV,ITURB ,6)
!
!       SMH USED BY THE TRACER
!       TO SIMULATE SUBIEF TAKING OFF PROPAGATION
!       AND ADVECTION, PROSOU IS NOT CALLED AND DISCRETE
!       SOURCES ARE NOT TAKEN INTO ACCOUNT.
!       STRICTLY 'CALL PROSOU' SHOULD BE HERE.
        IF(NTRAC.GT.0) CALL OS('X=0     ',X=SMH)
!
      ENDIF
!
!     TREATMENT OF NEGATIVE DEPTHS
!
      CALL CORRECTION_DEPTH_2D(MESH%GLOSEG%I,MESH%GLOSEG%DIM1,
     &                         YAFLODEL,YASMH,YAFLULIM)
!                              A ENLEVER
!
!=======================================================================
!                          END OF PROPAGATION
!=======================================================================
!
!  COMPUTES THE NEW ADVECTION FIELDS IF THERE REMAIN
!  SUB-ITERATIONS.
!
!  THE TEST ON ISOUSI IS MADE ONLY FOR HPROP AND NOT FOR UCONV
!  FOR REASONS OF TRACER MASS CONSERVATION (IT IS NECESSARY TO KEEP
!  THE SAME HPROP FOR THE TRACER AS THAT FOR H AND U)
!
      IF(ISOUSI.NE.NSOUSI) THEN
!       COMPUTES THE NEW PROPAGATION FIELD IF PROPAGATION
        IF(PROPA) THEN
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING HPROPA'
          CALL HPROPA(HPROP ,HN,H,PROLIN,HAULIN,TETAHC,NSOUSI)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM HPROPA'
        ENDIF
      ENDIF
!
!     COMPUTES THE NEW ADVECTION FIELD (IF ADVECTION)
      IF(CONV) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CHPCON'
        CALL CHPCON(UCONV,VCONV,U,V,UN,VN,TETAU)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CHPCON'
      ENDIF
!
!=======================================================================
! END OF THE LOOP OF THE SUB-ITERATIONS
!
      ENDDO ! ISOUSI 
!
!=======================================================================
!
! : 5                 DIFFUSION OF THE TRACER
!
!=======================================================================
!
      IF(NTRAC.GT.0.AND.EQUA(1:15).NE.'SAINT-VENANT VF') THEN
!
      IF(ENTET) CALL ENTETE(5,AT,LT)
!
      DO ITRAC=1,NTRAC
!
!  BOUNDARY CONDITIONS FOR THE DIFFUSION OF THE TRACER.
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING DIFFCL POUR ITRAC=',ITRAC
      CALL DIFFCL(LITBOR%ADR(ITRAC)%P%I,
     &            TTILD%ADR(ITRAC)%P%R,TBOR%ADR(ITRAC)%P%R,
     &            MESH%NBOR%I,ICONVFT(ITRAC),NPOIN,NPTFR)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM DIFFCL'
!
      ENDDO
!
!  SOURCE TERMS FOR DIFFUSION - SOURCE TERMS OF THE TRACER
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING DIFSOU'
      CALL DIFSOU(TEXP,TIMP,YASMI,TSCEXP,HPROP,TN,TETAT,NREJTR,
     &            ISCE,DSCE2,TSCE2,MAXSCE,MAXTRA,AT,DT,MASSOU,NTRAC,
     &            MESH%FAC%R,NSIPH,ENTSIP%I,SORSIP%I,DSIP%R,TSIP,
     &            NBUSE,ENTBUS%I,SORBUS%I,DBUS%R,TBUS,NWEIRS,TYPSEUIL,
     &            NPSING,NDGA1,NDGB1,TWEIRA,TWEIRB)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM DIFSOU'
!
!=======================================================================
!     OIL SPILL MODEL (UNDER DEVELOPMENT IN MYGRHYCAR PROJECT)
!=======================================================================
!
      IF(SPILL_MODEL) THEN
!
        CALL OIL_SPILL_2D(YASMI)
!
      ENDIF
!
!=======================================================================
!     ADVECTION-DIFFUSION OF TRACERS
!=======================================================================
!
      DO ITRAC=1,NTRAC
!
!  CALLS THE STANDARD DIFFUSER. (CV1 IS THE SECOND MEMBER)
!
      INFOGT=INFOGR.AND.ENTET
!     HTILD: WORKING ARRAY WHERE HPROP IS RE-COMPUTED
!             (SAME ARRAY STRUCTURE)
!
!     LIMTRA REPLACED BY A COPY (IT MAY BE CHANGED BY THE ADVECTION SCHEME)
!
      DO I=1,NPTFR
        IT1%I(I)=LIMTRA%I(I)
      ENDDO
!
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING CVDFTR SOLSYS=',SOLSYS
      IF(SOLSYS.EQ.1) THEN
      CALL CVDFTR(T%ADR(ITRAC)%P,TTILD%ADR(ITRAC)%P,TN%ADR(ITRAC)%P,
     &            TSCEXP%ADR(ITRAC)%P,
     &            DIFT,ICONVFT(ITRAC),CONVV(3),H,HN,HTILD,TETAHC,
     &            UCONV,VCONV,DM1,ZCONV,SOLSYS,
     &            VISCT%ADR(ITRAC)%P,VISC_S,TEXP%ADR(ITRAC)%P,SMH,YASMH,
     &            TIMP%ADR(ITRAC)%P,YASMI(ITRAC),AM1,AM2,ZF,
     &            TBOR%ADR(ITRAC)%P,ATBOR%ADR(ITRAC)%P,
     &            BTBOR%ADR(ITRAC)%P,IT1,MASKTR,MESH,W1,TB,
     &            T1,T2,T3,T4,T5,T6,T7,T10,TE1,TE2,TE3,
     &            KDIR,KDDL,KENT,
     &            DT,ENTET,TETAT,AGGLOT,INFOGT,BILMAS,OPTADV_TR(ITRAC),
     &            ISOUSI,LT,NIT,OPDTRA,OPTBAN,
     &            MSK,MASKEL,MASKPT,MBOR,S,MASSOU(ITRAC),
     &            OPTSOU,SLVTRA(ITRAC),FLBOR,VOLU2D,V2DPAR,UNSV2D,
     &            2,FLBORTRA,
     &            FLULIM,YAFLULIM,DIRFLU,RAIN,PLUIE,TRAIN(ITRAC),
     &            FLODEL,.FALSE.,MAXADV)
!
      ELSE
      CALL CVDFTR(T%ADR(ITRAC)%P,TTILD%ADR(ITRAC)%P,TN%ADR(ITRAC)%P,
     &            TSCEXP%ADR(ITRAC)%P,
     &            DIFT,ICONVFT(ITRAC),CONVV(3),H,HN,HTILD,TETAHC,
     &            UDEL,VDEL,DM1,ZCONV,SOLSYS,
     &            VISCT%ADR(ITRAC)%P,VISC_S,TEXP%ADR(ITRAC)%P,SMH,YASMH,
     &            TIMP%ADR(ITRAC)%P,YASMI(ITRAC),AM1,AM2,ZF,
     &            TBOR%ADR(ITRAC)%P,ATBOR%ADR(ITRAC)%P,
     &            BTBOR%ADR(ITRAC)%P,IT1,MASKTR,MESH,W1,TB,
     &            T1,T2,T3,T4,T5,T6,T7,T10,TE1,TE2,TE3,
     &            KDIR,KDDL,KENT,
     &            DT,ENTET,TETAT,AGGLOT,INFOGT,BILMAS,OPTADV_TR(ITRAC),
     &            ISOUSI,LT,NIT,OPDTRA,OPTBAN,
     &            MSK,MASKEL,MASKPT,MBOR,S,MASSOU(ITRAC),
     &            OPTSOU,SLVTRA(ITRAC),FLBOR,VOLU2D,V2DPAR,UNSV2D,
     &            2,FLBORTRA,
     &            FLULIM,YAFLULIM,DIRFLU,RAIN,PLUIE,TRAIN(ITRAC),
     &            FLODEL,YAFLODEL,MAXADV)
      ENDIF
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM CVDFTR'
!
      IF(BILMAS) THEN
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BILANT'
      CALL BILANT(H,T2,T3,DT,LT,NIT,ENTET,
     &            T%ADR(ITRAC)%P,AGGLOT,MASSOU(ITRAC),MASTR0(ITRAC),
     &            MASTR2(ITRAC),MASTEN(ITRAC),
     &            MASTOU(ITRAC),MSK,MASKEL,MESH,FLBOR,NUMLIQ%I,
     &            NFRLIQ,NPTFR,NAMETRAC(ITRAC),FLBORTRA,MASS_RAIN,
     &            TRAIN(ITRAC),MASTRAIN(ITRAC))
      ENDIF
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BILANT'
!
      ENDDO
!
      ENDIF
!
!=======================================================================
!                    END OF DIFFUSION OF THE TRACER
!=======================================================================
!
!
!
!
!=======================================================================
!           DIFFUSION AND SOURCE TERMS FOR K-EPSILON MODEL
!=======================================================================
!
      IF(ITURB.EQ.3.AND..NOT.ADJO) THEN
!
        IF (ENTET) CALL ENTETE(4,AT,LT)
!
! BEWARE THE MATRIX STRUCTURE (SYMMETRICAL OR NOT)
! WHEN CONSIDERING THE COUPLED SYSTEM K-E
!
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING KEPSIL'
        CALL KEPSIL(AK,EP,AKTILD,EPTILD,AKN,EPN,VISC,CF,U,V,H,
     &              UCONV,VCONV,KBOR,EBOR,LIMKEP%I,IELMK,IELME,
     &              CV1,CV2,TM1,BM1,BM2,CM2,TE1,TE2,NPTFR,DT,
     &              MESH,T1,T2,T3,TB,
     &              CMU,C1,C2,SIGMAK,SIGMAE,ESTAR,SCHMIT,
     &              KMIN,KMAX,EMIN,EMAX,INFOKE.AND.ENTET,
     &              KDIR,MSK,MASKEL,MASKPT,S,SLVK,SLVEP,
     &              ICONVF(4),OPTADV_KE)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM KEPSIL'
!
      ENDIF
!
!=======================================================================
!  1)                 CHECKS MASS BALANCE
!=======================================================================
!
! CONTROL SECTIONS
!
      IF(NCP.NE.0.AND.(ENTET.OR.CUMFLO)) THEN
        CALL FLUSEC_TELEMAC2D(U,V,H,MESH%IKLE%I,MESH%XEL%R,MESH%YEL%R,
     &                        MESH%NELMAX,MESH%NELEM,
     &                        MESH%X%R,MESH%Y%R,DT,NCP,
     &                        CTRLSC,ENTET,AT,
     &                        MSKSEC,BM1,BM2,T1,HPROP,MESH,S,CV1,
     &                        MESH%IFABOR%I,COMFLU,CUMFLO)
      ENDIF
!
! MASS BALANCE
!
      IF(BILMAS) THEN
!
        CALL BILAN(MESH,H,T1,MASK,AT,DT,LT,NIT,ENTET,
     &             MASSES,MSK,MASKEL,EQUA,TE5,OPTBAN,
     &             MESH%NPTFR,FLBOR,
     &             FLUX_BOUNDARIES,NUMLIQ%I,NFRLIQ,GAMMA)
!
!       ADDED FOR THE KINETIC SCHEMES (TO BE CHECKED)
!
        IF(NTRAC.GT.0) THEN
          IF(EQUA(1:15).EQ.'SAINT-VENANT VF') THEN
!
            DO ITRAC=1,NTRAC
            CALL BILANT1(HSTOK,UCONV,VCONV,HPROP,T2,T3,T4,T5,T6,
     &                   DT,LT,NIT,ENTET,MASKTR,
     &                   T%ADR(1)%P,TN%ADR(1)%P,TETAT,
     &                   MASSOU(ITRAC),MSK,MASKEL,MESH,
     &                   FLUTSOR(ITRAC),FLUTENT(ITRAC),EQUA,LTT,ITRAC)
            ENDDO
!
          ENDIF
        ENDIF
!
      ENDIF
!
!=======================================================================
!                           DROGUE(S)
!=======================================================================
!
      IF(NFLOT_MAX.NE.0.AND..NOT.SPILL_MODEL) THEN
!
        IF(ENTET) CALL ENTETE(12,AT,LT)
!
        IF(SPHERI) THEN
          CALL OS('X=Y/Z   ',UCONV,UCONV,MESH%COSLAT,C)
          CALL OS('X=Y/Z   ',VCONV,VCONV,MESH%COSLAT,C)
        ENDIF
!
!       ADDING AND REMOVING DROGUES
!
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING FLOT'
        CALL FLOT(XFLOT%R,YFLOT%R,NFLOT,NFLOT_MAX,MESH%X%R,MESH%Y%R,
     &            MESH%IKLE%I,NELEM,NELMAX,NPOIN,TAGFLO%I,
     &            SHPFLO%R,ELTFLO%I,MESH,LT,NIT,AT)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM FLOT'
!
!       MOVING THEM
!
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING DERIVE'
        CALL DERIVE(UCONV%R,VCONV%R,VCONV%R,DT,AT,
     &              MESH%X%R,MESH%Y%R,MESH%Y%R,
     &              MESH%IKLE%I,MESH%IFABOR%I,LT,IELM,UCONV%ELM,3,NPOIN,
     &              NPOIN,
     &              NELEM,NELMAX,MESH%SURDET%R,XFLOT%R,YFLOT%R,YFLOT%R,
     &              SHPFLO%R,SHPFLO%R,TAGFLO%I,ELTFLO%I,ELTFLO%I,
     &              NFLOT,NFLOT_MAX,FLOPRD,MESH,T2D_FILES(T2DFLO)%LU,
     &              IT1%I,T1%R,T2%R,T2%R,IT2%I,W1%R,W1%R,NPOIN,STOCHA,
     &              VISC,
     &              AALGAE=ALGAE,DALGAE=DALGAE,RALGAE=RALGAE,
     &              EALGAE=EALGAE,ALGTYP=ALGTYP,AK=AK%R,EP=EP%R,H=H%R)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM DERIVE'
!
        IF(SPHERI) THEN
          CALL OS('X=XY    ',UCONV,MESH%COSLAT,S,C)
          CALL OS('X=XY    ',VCONV,MESH%COSLAT,S,C)
        ENDIF
!
      ENDIF
!
!=======================================================================
!                        LAGRANGIAN DRIFT(S)
!=======================================================================
!
      IF(NLAG.NE.0) THEN
!
        IF (ENTET) CALL ENTETE(13,AT,LT)
!
          CALL DERLAG(UCONV%R,VCONV%R,DT,MESH%X%R,MESH%Y%R,
     &                LT,IELM,UCONV%ELM,3,NPOIN,NELEM,NELMAX,
     &                XLAG%R,YLAG%R,T1%R,T2%R,IT1%I,SHPLAG%R,
     &                DEBLAG%I,FINLAG%I,ELTLAG%I,NLAG,
     &                T7%R,T8%R,IT2%I,MESH)
!
      ENDIF
!
!=======================================================================
!                     CREDIBILITY CHECKS
!                   LOOKS FOR A STEADY STATE
!=======================================================================
!
      ARRET1=.FALSE.
      IF(VERLIM) THEN
        CALL ISITOK(H%R,H%DIM1,U%R,U%DIM1,V%R,V%DIM1,NTRAC,
     &              T,T%ADR(1)%P%DIM1,
     &              MESH%X%R,MESH%Y%R,BORNES,ARRET1)
!       CORRECTION SUGGESTED BY NOEMIE DURAND (CHC-NRC) 04/01/2006
        IF(NCSIZE.GT.1) THEN
          STOP2=0
          IF(ARRET1) STOP2=1
          STOP2=P_IMAX(STOP2)
          IF(STOP2.EQ.1) ARRET1=.TRUE.
        ENDIF
      ENDIF
      ARRET2=.FALSE.
      IF(STOPER) THEN
        CALL STEADY(H%R,HN%R,H%DIM1,U%R,UN%R,U%DIM1,V%R,VN%R,
     &              V%DIM1,NTRAC,T,TN,T%ADR(1)%P%DIM1,
     &              CRIPER,ARRET2)
!       CORRECTION BY NOEMIE DURAND (CHC-NRC) 04/01/2006
        IF(NCSIZE.GT.1) THEN
          STOP2=0
          IF(ARRET2) STOP2=1
          STOP2=P_IMIN(STOP2)
          ARRET2=.NOT.(STOP2.EQ.0)
        ENDIF
      ENDIF
      IF(ARRET1.OR.ARRET2) THEN
        LEOPRD=1
        LISPRD=1
      ENDIF
!
      ARRET3=.FALSE.
      CALL TRAPSIG()
      IF(BREAKER) ARRET3=.TRUE.
!
      IF(ARRET1.OR.ARRET2.OR.ARRET3) THEN
        LEOPRD=1
        LISPRD=1
      ENDIF
!
! FH-BMD
!=============================================
!     FOR NEW COUPLING
      ENDDO ! ISIS_CFD
      IF (SISYPHE_CFD) CONSTFLOW_SIS = .TRUE.
999   CONTINUE
!
!=======================================================================
!
!     COUPLING WITH SISYPHE
!
      IF(INCLUS(COUPLING,'SISYPHE')) THEN
!
        CALL CONFIG_CODE(2)
!
        SUSP1=SUSP.AND.PERCOU.EQ.1
        IF(SUSP1.OR.(CHARR.AND.(PERCOU*(LT/PERCOU).EQ.LT))) THEN
!
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING SISYPHE, CHARRIAGE'
          CALL SISYPHE(1,LT,LEOPRD_CHARR,LISPRD,NIT,U,V,H,HN,ZF,
     &                 CF,CF,CHESTR,CONSTFLOW_SIS,NSIS_CFD,SISYPHE_CFD,
     &                 CODE1,PERCOU,U,V,AT,VISC,DT*PERCOU,CHARR,SUSP1,
     &                 FLBOR,SOLSYS,DM1,USIS,VSIS,ZCONV,
     &                 DIRMOY,HM0,TPR5,ORBVEL)
          IF(DEBUG.GT.0) WRITE(LU,*) 'FIN APPEL SISYPHE, CHARRIAGE'
!
        ENDIF
!
        IF(SUSP.AND.PERCOU.NE.1) THEN
!
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING SISYPHE, SUSPENSION'
          CALL SISYPHE(1,LT,LEOPRD,LISPRD,NIT,U,V,H,HN,ZF,
     &                 CF,CF,CHESTR,CONSTFLOW_SIS,NSIS_CFD,SISYPHE_CFD,
     &                 CODE1,1,U,V,AT,VISC,DT,CHARR_TEL,SUSP,
     &                 FLBOR,SOLSYS,DM1,USIS,VSIS,ZCONV,
     &                 DIRMOY,HM0,TPR5,ORBVEL)
          IF(DEBUG.GT.0) WRITE(LU,*) 'FIN APPEL DE SISYPHE, SUSPENSION'
!
        ENDIF
!
        CALL CONFIG_CODE(1)
!
      ENDIF
!
!=======================================================================
!                      WRITES OUT THE RESULTS
!=======================================================================
!
      IF(ADJO) THEN
!
        IF(T2D_FILES(T2DRBI)%NAME.NE.' '.AND.
     &     INCLU2(ESTIME,'DEBUG')) THEN
          CALL BIEF_DESIMP('SERAFIN ',VARSORA,
     &                     HIST,0,NPOIN,T2D_FILES(T2DRBI)%LU,
     &                     'STD',-AT,LT,LISPRD,1,
     &                     SORLEOA,SORIMPA,MAXVAR,TEXTE,PTINIG,PTINIL)
        ENDIF
!
      ELSE
!
        IF(CODE(1:7).EQ.'ESTEL3D') THEN
!
!         SAVES THE DEPTH FOR ESTEL3D
          CALL DEPTH_FILL(H%R)
!
! (NOTE THAT OUTPUTS ARE DONE WITHIN ESTEL3D IN COUPLED MODE)
!
        ELSE
          CALL PRERES_TELEMAC2D
          CALL BIEF_DESIMP(T2D_FILES(T2DRES)%FMT,VARSOR,
     &            HIST,0,NPOIN,T2D_FILES(T2DRES)%LU,'STD',AT,LT,
     &            LISPRD,LEOPRD,
     &            SORLEO,SORIMP,MAXVAR,TEXTE,PTINIG,PTINIL)
        ENDIF
!
!
        IF(INCLUS(COUPLING,'DELWAQ')) THEN
!
!         T3 : MODIFIED DEPTH TO TAKE INTO ACCOUNT MASS-LUMPING
!              IN THE CONTINUITY EQUATION
          IF(ABS(1.D0-AGGLOC).GT.1.D-8) THEN
            CALL VECTOR(T3,'=','MASVEC          ',IELMH,
     &                  1.D0-AGGLOC,H ,S,S,S,S,S,MESH,MSK,MASKEL)
            IF(NCSIZE.GT.1) CALL PARCOM(T3,2,MESH)
            CALL OS('X=XY    ',X=T3 ,Y=UNSV2D)
            CALL OS('X=X+CY  ',X=T3 ,Y=H ,C=AGGLOC)
          ELSE
            CALL OS('X=Y     ',X=T3 ,Y=H )
          ENDIF
!
!         NOTE: FLODEL IS DONE IN CORRECTION_DEPTH_2D
!
          IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING TEL4DEL'
          CALL TEL4DEL(MESH%NPOIN,
     &    MESH%NPOIN,MESH%NELEM,MESH%NSEG,MESH%IKLE%I,MESH%ELTSEG%I,
     &    MESH%GLOSEG%I,MESH%ORISEG%I,MESH%GLOSEG%DIM1,
     &    MESH%X%R,MESH%Y%R,MESH%NPTFR,LIHBOR%I,MESH%NBOR%I,1,
     &    AT,DT,LT,NIT,T3%R,HPROP%R,T3%R,UDEL%R,VDEL%R,
     &    T%ADR(MAX(IND_S,1))%P%R,T%ADR(MAX(IND_T,1))%P%R,
     &    VISC%R,TITCAS,T2D_FILES(T2DGEO)%NAME,
     &    T2D_FILES(T2DCLI)%NAME,WAQPRD,
     &    T2DDL1,T2D_FILES(T2DDL1)%NAME,T2DDL2,T2D_FILES(T2DDL2)%NAME,
     &    T2DDL3,T2D_FILES(T2DDL3)%NAME,T2DDL5,T2D_FILES(T2DDL5)%NAME,
     &    T2DDL6,T2D_FILES(T2DDL6)%NAME,T2DDL7,T2D_FILES(T2DDL7)%NAME,
     &    T2DL11,T2D_FILES(T2DL11)%NAME,T2DDL4,T2D_FILES(T2DDL4)%NAME,
     &    T2DDL8,T2D_FILES(T2DDL8)%NAME,T2DDL9,T2D_FILES(T2DDL9)%NAME,
     &    T2DL10,T2D_FILES(T2DL10)%NAME,ENTET,NELEM,SALI_DEL,
     &    TEMP_DEL,VELO_DEL,DIFF_DEL,MARDAT,MARTIM,FLODEL%R,
     &    V2DPAR%R,MESH%KNOLG%I)
          IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM TEL4DEL'
!
        ENDIF
!
      ENDIF  !(ADJO)
!
!     OPTIONAL USER OUTPUT (COURTESY JACEK JANKOWSKI, BAW)
      IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING UTIMP_TELEMAC2D'
      CALL UTIMP_TELEMAC2D(LT,AT,PTINIG,LEOPRD,PTINIL,LISPRD)
      IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM UTIMP_TELEMAC2D'
!
!=======================================================================
!              COMPARISON AGAINST A REFERENCE FILE
!=======================================================================
!
!     THE VALIDA SUBROUTINE FROM THE BIEF LIBRARY IS STANDARD.
!     IT CAN BE MODIFIED BY THE USER FOR THEIR PARTICULAR CASE.
!     BUT THE CALL TO THE SUBROUTINE MUST STAY IN THE TIME LOOP.
!
      IF(VALID) THEN
        IF(DEBUG.GT.0) WRITE(LU,*) 'CALLING BIEF_VALIDA'
        CALL BIEF_VALIDA(TB,TEXTPR,
     &                   T2D_FILES(T2DREF)%LU,T2D_FILES(T2DREF)%FMT,
     &                   VARSOR,TEXTE,
     &                   T2D_FILES(T2DRES)%LU,T2D_FILES(T2DRES)%FMT,
     &                   MAXVAR,NPOIN,LT,NIT,ALIRE)
        IF(DEBUG.GT.0) WRITE(LU,*) 'BACK FROM BIEF_VALIDA'
      ENDIF


!=======================================================================
!              REDEFINING THE ALGAE VARIABLES FOR THE NEXT 
!                            TIME STEP
!=======================================================================
!
! DAJ
! UPDATE THE ALGAE VARIABLES AT T_0 FOR THE CALCULATIONS OF THE NEXT TIME STEP
      IF(ALGAE) THEN
        CALL OS('X=Y     ',X=U_X_AV_0,Y=U_X_AV)
        CALL OS('X=Y     ',X=U_Y_AV_0,Y=U_Y_AV)
        CALL OS('X=Y     ',X=U_Z_AV_0,Y=U_Z_AV)
        CALL OS('X=Y     ',X=K_AV_0,Y=K_AV)
        CALL OS('X=Y     ',X=EPS_AV_0,Y=EPS_AV)
        CALL OS('X=Y     ',X=U_X_0,Y=U_X)
        CALL OS('X=Y     ',X=U_Y_0,Y=U_Y)
        CALL OS('X=Y     ',X=U_Z_0,Y=U_Z)
        CALL OS('X=Y     ',X=V_X_0,Y=V_X)
        CALL OS('X=Y     ',X=V_Y_0,Y=V_Y)
        CALL OS('X=Y     ',X=V_Z_0,Y=V_Z)
      ENDIF
! FAJ
!
!=======================================================================
!
!  NEAT (PROGRAMMED) STOP OF THE MODEL:
!
      IF(ARRET1) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*)
          WRITE(LU,*) 'VALEURS LIMITES DEPASSEES, ARRET DE TELEMAC-2D'
          WRITE(LU,*)
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*)
          WRITE(LU,*) 'LIMIT VALUES TRESPASSED, TELEMAC-2D IS STOPPED'
          WRITE(LU,*)
        ENDIF
        RETURN
      ENDIF
      IF(ARRET2) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*)
          WRITE(LU,*) 'ETAT PERMANENT ATTEINT, ARRET DE TELEMAC-2D'
          WRITE(LU,*)
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*)
          WRITE(LU,*) 'STEADY STATE REACHED, TELEMAC-2D IS STOPPED'
          WRITE(LU,*)
        ENDIF
        RETURN
      ENDIF
      IF(ARRET3) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*)
          CALL ENTETE(1,AT,LT)
          WRITE(LU,*) 'TELEMAC-2D ARRETE PAR L''UTILISATEUR'
          WRITE(LU,*) 'AVEC SIGNAL ',SIGUSR1
          WRITE(LU,*)
        ENDIF
        IF(LNG.EQ.2) THEN
          CALL ENTETE(1,AT,LT)
          WRITE(LU,*)
          WRITE(LU,*) 'TELEMAC-2D CHECKPOINTED BY THE USER'
          WRITE(LU,*) 'USING SIGNAL ',SIGUSR1
          WRITE(LU,*)
        ENDIF
        RETURN
      ENDIF
!
!     NOW ADVECTION SCHEME WILL BE CHANGED AND FLULIM
!     WILL NOT CORRESPOND TO IT.
!
      YAFLULIM=.FALSE.
!
!
! 700: TIME LOOP
!
      IF(LT.LT.NIT) GO TO 700
!
!=======================================================================
!
! :                 /* END OF THE LOOP IN TIME */
!
!=======================================================================
!
      IF(LNG.EQ.1.AND.LISTIN) WRITE(LU,18)
      IF(LNG.EQ.2.AND.LISTIN) WRITE(LU,19)
18    FORMAT(/,1X,'FIN DE LA BOUCLE EN TEMPS',////)
19    FORMAT(/,1X,'END OF TIME LOOP',////)
!
!-----------------------------------------------------------------------
!
      RETURN
      END SUBROUTINE TELEMAC2D

