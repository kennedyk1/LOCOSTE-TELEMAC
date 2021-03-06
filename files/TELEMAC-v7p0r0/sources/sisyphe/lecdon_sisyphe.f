!                    *************************
                     SUBROUTINE LECDON_SISYPHE
!                    *************************
!
     &(MOTCAR,FILE_DESC,PATH,NCAR,CODE)
!
!***********************************************************************
! SISYPHE   V6P3                                   12/02/2013
!***********************************************************************
!
!brief    READS THE STEERING FILE BY CALL TO DAMOCLES.
!
!history  M. GONZALES DE LINARES
!+        2002
!+
!+
!
!history  C.VILLARET
!+        **/10/2003
!+
!+   * READS KFROT, HOULE
!
!history  F. HUVELIN
!+        **/12/2003
!+
!+   * INITIALISES F90 TO FDM IF NOT IN THE STEERING FILE
!
!history  CV
!+        **/03/06
!+
!+   ADDED NEW KEYWROD: TASS
!
!history  JMH
!+        11/04/2008
!+
!+   DEBUG IS A KEYWORD: DEBUGGER
!
!history  CV+JMH
!+        29/07/2008
!+
!+   READS CBOR_CLASSE
!
!history  JMH
!+        17/10/2008
!+
!+   CHECKS NCSIZE (FOR CONSISTENCY WITH TELEMAC-2D WHEN COUPLING)
!
!history  JMH
!+        23/12/2008
!+
!+   KEYWORDS FOR COUPLING WITH DREDGESIM
!
!history  BD+JMH
!+        09/04/2009
!+
!+   MED FORMAT
!
!history   J.-M. HERVOUET; C.VILLARET
!+        03/11/2009
!+        V6P0
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
!history  C.VILLARET; U. MERKEL, R. KOPMAN
!+        20/03/2011
!+        V6P1
!+
!
!history  C.VILLARET (EDF-LNHE), P.TASSI (EDF-LNHE)
!+        19/07/2011
!+        V6P1
!+  Name of variables   
!+   
!
!history  C.VILLARET + JMH (EDF-LNHE)
!+        02/05/2012
!+        V6P2
!+  File for liquid boundaries added  
!+   
!
!history  JWI
!+        31/05/2012
!+        V6P2
!+  added one increment to include wave orbital velocities
!+  (SORLEO(I+28+(NOMBLAY+4)*NSICLA+NOMBLAY).OR.
!
!history  PAT (LNHE)
!+        18/06/2012
!+        V6P2
!+   updated version with HRW's development 
!
!history  Pablo Tassi PAT (EDF-LNHE)
!+        12/02/2013
!+        V6P3
!+ Preparing for the use of a higher NSICLM value
!+ (by Rebekka Kopmann)
!
!history  Pablo Tassi PAT (EDF-LNHE)
!+        12/02/2013
!+        V6P3
!+ Settling lag: determines choice between Rouse and Miles concentration profile
!+ (by Michiel Knaapen HRW)
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_DESC      |<--| STORES STRINGS 'SUBMIT' OF DICTIONARY
!| MOTCAR         |<--| VALUES OF KEY-WORDS OF TYPE CHARACTER
!| NCAR           |-->| NUMBER OF LETTERS IN STRING PATH
!| PATH           |-->| FULL PATH TO CODE DICTIONARY
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_SISYPHE
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)               :: NCAR
      CHARACTER(LEN=24), INTENT(IN)     :: CODE
      CHARACTER(LEN=250), INTENT(IN)    :: PATH
!                                                 NMAX
      CHARACTER*144, INTENT(INOUT)      :: MOTCAR(300)
!                                                      NMAX
      CHARACTER(LEN=144), INTENT(INOUT) :: FILE_DESC(4,300)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, PARAMETER :: NMAX = 300
!
      INTEGER            :: I,K,ERR
      INTEGER            :: MOTINT(NMAX)
      INTEGER            :: TROUVE(4,NMAX)
      INTEGER            :: ADRESS(4,NMAX)
      INTEGER            :: DIMENS(4,NMAX)
      DOUBLE PRECISION   :: SUMAVAI
      DOUBLE PRECISION   :: MOTREA(NMAX)
      LOGICAL            :: DOC,EFFPEN
      LOGICAL            :: MOTLOG(NMAX)
      CHARACTER(LEN=250) :: NOM_CAS
      CHARACTER(LEN=250) :: NOM_DIC
      CHARACTER*72       :: MOTCLE(4,NMAX,2)

      CHARACTER(LEN=250) TEMPVAR
!
!-----------------------------------------------------------------------
!
!
!-----------------------------------------------------------------------
!
      SUMAVAI = 0

! INITIALISES THE VARIABLES FOR DAMOCLES CALL :
!
      DO K = 1, NMAX
!       A FILENAME NOT GIVEN BY DAMOCLES WILL BE RECOGNIZED AS A WHITE SPACE
!       (IT MAY BE THAT NOT ALL COMPILERS WILL INITIALISE LIKE THAT)
        MOTCAR(K)(1:1)=' '
!
        DIMENS(1,K) = 0
        DIMENS(2,K) = 0
        DIMENS(3,K) = 0
        DIMENS(4,K) = 0
      ENDDO
!
!     WRITES OUT INFO
      DOC = .FALSE.
!
!-----------------------------------------------------------------------
!     OPENS DICTIONNARY AND STEERING FILES
!-----------------------------------------------------------------------
!
      IF(NCAR.GT.0) THEN
!
        NOM_DIC=PATH(1:NCAR)//'SISDICO'
        NOM_CAS=PATH(1:NCAR)//'SISCAS'
!
      ELSE
!
        NOM_DIC='SISDICO'
        NOM_CAS='SISCAS'
!
      ENDIF
!
      OPEN(2,FILE=NOM_DIC,FORM='FORMATTED',ACTION='READ')
      OPEN(3,FILE=NOM_CAS,FORM='FORMATTED',ACTION='READ')
!
!-----------------------------------------------------------------------
!     CALLS DAMOCLES
!-----------------------------------------------------------------------
!
      CALL DAMOCLE( ADRESS , DIMENS  , NMAX   , DOC    , LNG , LU  ,
     &               MOTINT , MOTREA  , MOTLOG , MOTCAR ,
     &               MOTCLE , TROUVE , 2 , 3 ,.FALSE., FILE_DESC )
!
!     DECODES 'SUBMIT' CHAINS
!
      CALL READ_SUBMIT(SIS_FILES,MAXLU_SIS,CODE,FILE_DESC,300)
!
!-----------------------------------------------------------------------
!
!     RETRIEVES FILES NUMBERS IN TELEMAC-2D FORTRAN PARAMETERS
!     AT THIS LEVEL LOGICAL UNITS ARE EQUAL TO THE FILE NUMBER
!
      DO I=1,MAXLU_SIS
        IF(SIS_FILES(I)%TELNAME.EQ.'SISHYD') THEN
          SISHYD=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISGEO') THEN
          SISGEO=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISCLI') THEN
          SISCLI=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISPRE') THEN
          SISPRE=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISRES') THEN
          SISRES=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISREF') THEN
          SISREF=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISCOU') THEN
          SISCOU=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISFON') THEN
          SISFON=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISMAF') THEN
          SISMAF=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISSEC') THEN
          SISSEC=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISSEO') THEN
          SISSEO=I
        ELSEIF(SIS_FILES(I)%TELNAME.EQ.'SISLIQ') THEN
          SISLIQ=I
        ENDIF
      ENDDO
!
!-----------------------------------------------------------------------
!
!   ASSIGNS THE STEERING FILE VALUES TO THE PARAMETER FORTRAN NAME
!
!-----------------------------------------------------------------------
!
! ################# !
! INTEGER KEYWORDS  !
! ################# !
! OPTION OF MATRIX ASSEMBLY IS HARD-CODED
! ---------------------------------------------
!
      OPTASS = 1
      PRODUC = 1

      ! DISCRETISES THE VARIABLES
      ! ----------------------------
      IELMT     = 11 ! SEDIMENTOLOGICAL VARIABLES
      IELMH_SIS = 11 ! VARIABLES ASSOCIATED WITH WATER DEPTH
      IELMU_SIS = 11 ! VARIABLES ASSOCIATED WITH VELOCITIES

      ! FOR NOW PRINTOUTS START AT ZERO
      ! -----------------------------------------------
      PTINIG = 0
      PTINIL = 0

      ! NON-EQUILIBIRUM BEDLOAD
      ! ------------------------
      LOADMETH = 0

!     ICM           = MOTINT( ADRESS(1,  1) )
      ICF           = MOTINT( ADRESS(1,  2) )
      NPAS          = MOTINT( ADRESS(1,  3) )
      NMAREE        = MOTINT( ADRESS(1,  4) )
!     N1            = MOTINT( ADRESS(1,  5) )

      LEOPR         = MOTINT( ADRESS(1,  6) )
      LISPR         = MOTINT( ADRESS(1,  7) )
!     STDGEO IS NOT USED, DELETE FROM DECLARATIONS
      STDGEO        = MOTINT( ADRESS(1,  8) )
!     LOGDES IS NOT USED, DELETE FROM DECLARATIONS
      LOGDES        = MOTINT( ADRESS(1,  9) )
!     LOGPRE IS NOT USED, DELETE FROM DECLARATIONS
      LOGPRE        = MOTINT( ADRESS(1, 10) )
      OPTBAN        = MOTINT( ADRESS(1, 11) )
      LVMAC         = MOTINT( ADRESS(1, 12) )
      HYDRO         = MOTINT( ADRESS(1, 13) )
      NSOUS         = MOTINT( ADRESS(1, 14) )
!
      MARDAT(1)     = MOTINT( ADRESS(1, 15) )
      MARDAT(2)     = MOTINT( ADRESS(1, 15) + 1 )
      MARDAT(3)     = MOTINT( ADRESS(1, 15) + 2 )
      MARTIM(1)     = MOTINT( ADRESS(1, 16) )
      MARTIM(2)     = MOTINT( ADRESS(1, 16) + 1 )
      MARTIM(3)     = MOTINT( ADRESS(1, 16) + 2 )
!
      SLVSED%SLV    = MOTINT( ADRESS(1, 17) )
      SLVSED%KRYLOV = MOTINT( ADRESS(1, 18) )
      SLVSED%PRECON = MOTINT( ADRESS(1, 19) )
      SLVSED%NITMAX = MOTINT( ADRESS(1, 20) )
      CHOIX         = MOTINT( ADRESS(1, 21) )
      DIRFLU        = MOTINT( ADRESS(1, 22) )
      NPRIV         = MOTINT( ADRESS(1, 23) )
!
!     NCSIZE        = MOTINT( ADRESS(1, 24) )
!     NUMBER OF PROCESSORS (ALREADY GIVEN IN INIT_FILES2;
!     MUST BE THE SAME, BUT WHEN USING COUPLED MODELS IT CAN
!     WRONGLY BE DIFFERENT)
      IF(NCSIZE.NE.MOTINT(ADRESS(1,24))) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'NOMBRE DE PROCESSEURS PARALLELES DIFFERENT :'
          WRITE(LU,*) 'DEJA DECLARE (CAS DE COUPLAGE ?) :',NCSIZE
          WRITE(LU,*) 'SISYPHE :',MOTINT(ADRESS(1,24))
          WRITE(LU,*) 'LA VALEUR ',NCSIZE,' EST GARDEE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'DIFFERENT NUMBER OF PARALLEL PROCESSORS:'
          WRITE(LU,*) 'DECLARED BEFORE (CASE OF COUPLING ?):',NCSIZE
          WRITE(LU,*) 'SISYPHE :',MOTINT(ADRESS(1,24))
          WRITE(LU,*) 'VALUE ',NCSIZE,' IS KEPT'
        ENDIF
      ENDIF
      RESOL         = MOTINT( ADRESS(1, 25) )
      SLVTRA%SLV    = MOTINT( ADRESS(1, 26) )
      SLVTRA%KRYLOV = MOTINT( ADRESS(1, 27) )
      SLVTRA%PRECON = MOTINT( ADRESS(1, 28) )
      SLVTRA%NITMAX = MOTINT( ADRESS(1, 29) )
      OPTDIF        = MOTINT( ADRESS(1, 31) )
      OPTSUP        = MOTINT( ADRESS(1, 32) )
      PRODUC        = MOTINT( ADRESS(1, 33) )
      OPTASS        = MOTINT( ADRESS(1, 34) )
      OPDTRA        = MOTINT( ADRESS(1, 35) )
      DEPER         = MOTINT( ADRESS(1, 36) )
      KFROT         = MOTINT( ADRESS(1, 37) )
      NCONDIS       = MOTINT( ADRESS(1, 38) )
      SLOPEFF       = MOTINT( ADRESS(1, 39) )
      DEVIA         = MOTINT( ADRESS(1, 40) )
      NOMBLAY       = MOTINT( ADRESS(1,251) )
      NSICLA        = MOTINT( ADRESS(1,252) )
      HIDFAC        = MOTINT( ADRESS(1,253) )
      ICQ           = MOTINT( ADRESS(1, 41) )
!     CONTROL SECTIONS
      NCP=DIMENS(1,42)
      ALLOCATE(CTRLSC(NCP),STAT=ERR)
      IF(ERR.NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,1039) ERR
        IF(LNG.EQ.2) WRITE(LU,2039) ERR
1039    FORMAT(1X,'LECDON_SISYPHE :',/,1X,
     &            'ERREUR A L''ALLOCATION DE CTRLSC : ',/,1X,
     &            'CODE D''ERREUR : ',1I6)
2039    FORMAT(1X,'LECDON_SISYPHE:',/,1X,
     &            'ERROR DURING ALLOCATION OF CTRLSC: ',/,1X,
     &            'ERROR CODE: ',1I6)
      ENDIF
      IF(NCP.GE.1) THEN
        DO K=1,NCP
          CTRLSC(K) = MOTINT( ADRESS(1,42) + K-1 )
        ENDDO
      ENDIF
!     COORDINATES OF THE ORIGIN
      I_ORIG = MOTINT( ADRESS(1,43)   )
      J_ORIG = MOTINT( ADRESS(1,43)+1 )
      DEBUG  = MOTINT( ADRESS(1,44)   )
!
      ICR  =   MOTINT(ADRESS(1,46)   )
!
      IKS  =   MOTINT(ADRESS(1,47)   )
!// UHM //
      PRO_MAX_MAX =   MAX(NSICLA*4+4,MOTINT(ADRESS(1,49) ))
      CVSMPPERIOD =   MOTINT(ADRESS(1,50)   )
      IF(CVSMPPERIOD.EQ.0) CVSMPPERIOD = LEOPR
      ALT_MODEL   =   MOTINT(ADRESS(1,52)   )
      VSMTYPE     =   MOTINT(ADRESS(1,53)   )
!// UHM //
! 
!     MAXIMUM NUMBER OF ITERATIONS FOR ADVECTION SCHEMES
!
      MAXADV = MOTINT(ADRESS(1,54)) 
!
!     SCHEME OPTION FOR ADVECTION
!
      OPTADV=1
      IF(RESOL.EQ.1) THEN
!       CHARACTERISTICS
!       OPTADV=OPTCHA (IN TELEMAC-2D, NOT IN SISYPHE YET)
      ELSEIF(RESOL.EQ.2) THEN
!       SUPG
        OPTADV=OPTSUP
      ELSEIF(RESOL.EQ.5) THEN
!       PSI SCHEME
!       OPTADV_VI=OPTPSI (IN TELEMAC-2D, NOT IN SISYPHE YET) 
      ENDIF
!     SCHEME OPTION FOR ADVECTION HAS PRIORITY WHEN PRESENT
      IF(TROUVE(1,55).EQ.2) THEN
        OPTADV = MOTINT(ADRESS(1,55))
      ENDIF
! 
!
! ############### !
! REAL KEYWORDS   !
! ############### !
!
      ! NON-EQUILIBRIRUM BEDLOAD
      ! ------------------------
      LS0         = 1.D0
!
      RC          = MOTREA( ADRESS(2,  1) )
      XMVE        = MOTREA( ADRESS(2,  2) )
      XMVS        = MOTREA( ADRESS(2,  3) )
      DO K=1,NSICLA
        FDM(K)   = MOTREA( ADRESS(2,  4) + K-1 )
      ENDDO
!     IF OLD NAME OF KEYWORD 28 HAS BEEN FOUND
      IF(TROUVE(2,28).EQ.2) THEN
        DO K=1,NSICLA
          FDM(K) = MOTREA( ADRESS(2,28) + K-1 )
        ENDDO
      ENDIF
      XKV         = MOTREA( ADRESS(2,  5) )
!     SHIELDS NUMBERS
      DO K=1,DIMENS(2,6)
        AC(K)   = MOTREA( ADRESS(2, 6) + K-1 )
      ENDDO
!     IF ALL SHIELDS NUMBERS ARE NOT GIVEN, THE LATEST
!     ONE IS TAKEN FOR THE FOLLOWING
!     FOR EXAMPLE IF ONLY ONE IS GIVEN, ALL WILL HAVE
!     THE SAME VALUE
      IF(DIMENS(2,6).LT.NSICLA) THEN
        DO K=DIMENS(2,6)+1,NSICLA
          AC(K) = MOTREA( ADRESS(2, 6)+DIMENS(2,6)-1 )
        ENDDO
      ENDIF
      SFON        = MOTREA( ADRESS(2,  7) )
      GRAV        = MOTREA( ADRESS(2,  8) )
      ZERO        = MOTREA( ADRESS(2,  9) )
      SLVSED%ZERO = ZERO
      VCE         = MOTREA( ADRESS(2, 10) )
      HMIN        = MOTREA( ADRESS(2, 11) )
      DELT        = MOTREA( ADRESS(2, 12) )
      TPREC       = MOTREA( ADRESS(2, 13) )
      PMAREE      = MOTREA( ADRESS(2, 14) )
      TETA        = MOTREA( ADRESS(2, 15) )
      BETA        = MOTREA( ADRESS(2, 16) )
      SLVSED%EPS  = MOTREA( ADRESS(2, 17) )
      TETA_SUSP   = MOTREA( ADRESS(2, 18) )
      XKX         = MOTREA( ADRESS(2, 19) )
      XKY         = MOTREA( ADRESS(2, 20) )
      SLVTRA%EPS  = MOTREA( ADRESS(2, 21) )
!     SETTLING VELOCITIES (SAME TREATMENT THAN SHIELDS NUMBERS)
      DO K=1,DIMENS(2,22)
        XWC(K)   = MOTREA( ADRESS(2, 22) + K-1 )
      ENDDO
      IF(DIMENS(2,22).LT.NSICLA) THEN
        DO K=DIMENS(2,22)+1,NSICLA
          XWC(K) = MOTREA( ADRESS(2, 22)+DIMENS(2,22)-1 )
        ENDDO
      ENDIF
      CRIT_CFD    = MOTREA( ADRESS(2, 23) )
      KSPRATIO    = MOTREA( ADRESS(2, 24) )
      PHISED      = MOTREA( ADRESS(2, 25) )
      BETA2       = MOTREA( ADRESS(2, 26) )
      BIJK        = MOTREA( ADRESS(2, 27) )
!
!     INITIAL CONCENTRATIONS
!     ++++++++++++++++++++++
!     
      DO K=1,NSICLA
        CS0(K)=MOTREA( ADRESS(2,30) + K-1 )
      ENDDO
      DO K=1,10*MAXFRO
        CBOR_CLASSE(K)=0.D0
      ENDDO
      IF(DIMENS(2,31).GT.0) THEN
        DO K=1,DIMENS(2,31)
          CBOR_CLASSE(K)=MOTREA( ADRESS(2,31) + K-1 )
        ENDDO
      ENDIF
! 
!     COHESIVE SEDIMENT 
!     +++++++++++++++++
! 
      NCOUCH_TASS = MOTINT( ADRESS(1,45)   )
!
      IF(DIMENS(2,32).GT.0) THEN
        DO K=1,DIMENS(2,32)
          CONC_VASE(K)=MOTREA( ADRESS(2,32) + K-1 )
        ENDDO
      ENDIF
!
!     OBSOLETE KEY WORD : CSF_VASE = MOTREA( ADRESS(2, 29) )
!
!      CSF_VASE = CONC_VASE(1)/XMVS
! 
      IF(DIMENS(2,34).GT.0) THEN
        DO K=1,DIMENS(2,34)
          TOCE_VASE(K)=MOTREA( ADRESS(2,34) + K-1 )
        ENDDO
      ENDIF
!
!     KRONE AND PARTHENIADES EROSION AND DEPOSITION LAW
!
!     OBSOLETE KEY WORD : VITCE= MOTREA( ADRESS(2,35))
!     
      VITCE = SQRT(TOCE_VASE(1)/XMVE)
      VITCD= MOTREA( ADRESS(2,36))
!     PARTHENIADES WITH CONVERSION TO M/S
      PARTHENIADES = MOTREA( ADRESS(2,37))/XMVS
!
!     CONSOLIDATION MODEL
!
      TASS = MOTLOG(ADRESS(3,23))
      ITASS  =   MOTINT(ADRESS(1,48)   )
!
!     MULTILAYER MODEL (WALTHER, 2008)
!     ITASS = 1
      IF(DIMENS(2,33).GT.0) THEN
        DO K=1,DIMENS(2,33)
          TRANS_MASS(K)=MOTREA( ADRESS(2,33) + K-1 )
        ENDDO
      ENDIF
!
! V6P1
! THIEBOT MULTI LAYER MODEL 
! ITASS=2
!
      CONC_GEL=MOTREA( ADRESS(2,38))
      COEF_N= MOTREA( ADRESS(2,39))
      CONC_MAX=MOTREA( ADRESS(2,50))
!
!     PRESCRIBED SOLID DISCHARGES
!
      NSOLDIS=DIMENS(2,51)
      IF(NSOLDIS.GT.0) THEN
        DO K=1,NSOLDIS
          SOLDIS(K)=MOTREA(ADRESS(2,51)+K-1)
        ENDDO
      ENDIF
!
!     HIDING EXPOSURE MULTI GRAIN MODEL
! 
      DO K=1,NSICLA
        HIDI(K)  = MOTREA( ADRESS(2,253) + K-1 )
        IF (TROUVE(2,255).EQ.1) THEN
          FD90(K)= FDM(K)
        ELSE
          FD90(K)= MOTREA( ADRESS(2,255) + K-1 )
        ENDIF
        AVA0(K)  = MOTREA( ADRESS(2,258) + K-1 )
      ENDDO
      ELAY0       = MOTREA( ADRESS(2,259) )
!
! UM: MPM-Factor
      MPM         = MOTREA( ADRESS(2,260) )
! UM: ALPHA-Factor
      ALPHA       = MOTREA( ADRESS(2,261) )
! UM: MOFAC-Factor
      MOFAC       = MOTREA( ADRESS(2,262) )

      ! ################## !
      ! LOGICAL KEYWORDS !
      ! ################## !
! INDEX 99 IS ALREADY USED FOR KEYWORD 'LIST OF FILES'
! INDEX 54 IS ALREADY USED FOR KEYWORD 'DESCRIPTION OF LIBRARIES'
! INDEX 57 IS ALREADY USED FOR KEYWORD 'DEFAULT EXECUTABLE'
      ! SPHERICAL EQUATIONS HARD-CODED
      ! ----------------------------------
      SPHERI       = .FALSE.


      ! COMPUTATION OF FALL VELOCITIES
      ! ------------------------------------------
      CALWC = .FALSE.
      ! IF TROUVE: VELOCITIES ARE USER-DEFINED
      ! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      IF (TROUVE(2, 22).EQ.2) CALWC = .TRUE.
! CV
      ! SHIELDS PARAMETER
      ! ------------------------------------------
      CALAC = .FALSE.
      ! IF TROUVE
      ! ~~~~~~~~~~~~~
      IF (TROUVE(2, 6).EQ.2) CALAC = .TRUE.


      BILMA        = MOTLOG( ADRESS(3,  1) )
      PERMA        = MOTLOG( ADRESS(3,  2) )
      BANDEC       = MOTLOG( ADRESS(3,  3) )
      VALID        = MOTLOG( ADRESS(3,  4) )
!     DTVAR        = MOTLOG( ADRESS(3,  5) )
      LUMPI        = MOTLOG( ADRESS(3,  6) )
      SUSP         = MOTLOG( ADRESS(3,  7) )
      CHARR        = MOTLOG( ADRESS(3,  8) )
      HOULE        = MOTLOG( ADRESS(3, 10) )
      CONST_ALAYER = MOTLOG( ADRESS(3, 11) )
      LCONDIS      = MOTLOG( ADRESS(3, 12) )
      LGRAFED      = MOTLOG( ADRESS(3, 13) )
!     USED TO CHECK SIS_FILES(SISPRE)%NAME
      DEBU         = MOTLOG( ADRESS(3, 14) )
      IMP_INFLOW_C = MOTLOG( ADRESS(3, 15) )
      SECCURRENT   = MOTLOG( ADRESS(3, 16) )
      IF(CODE(1:9).EQ.'TELEMAC3D') SECCURRENT = .FALSE.
      UNIT         = MOTLOG( ADRESS(3, 17) )
      VF           = MOTLOG( ADRESS(3,253) )
      CORR_CONV    = MOTLOG( ADRESS(3, 18) )
      DO K=1,NSICLA
        SEDCO(K)   = .FALSE.
      ENDDO
      IF(DIMENS(3,19).GT.0) THEN
        DO K=1,DIMENS(3,19)
          SEDCO(K) = MOTLOG( ADRESS(3,19) + K-1 )
        ENDDO
      ENDIF
      SLIDE    = MOTLOG( ADRESS(3, 20) )
      DIFT     = MOTLOG( ADRESS(3, 21) )
      EFFPEN   = MOTLOG( ADRESS(3, 22) )
      IF(.NOT.EFFPEN) THEN
        SLOPEFF=0
        DEVIA=0
      ENDIF
!
      MIXTE=MOTLOG(ADRESS(3,24))
!     COUPLING WITH DREDGESIM
      DREDGESIM=MOTLOG(ADRESS(3,25))
!     V6P1
      KSPRED   =MOTLOG(ADRESS(3,26))
!
! MAK
!     Settling lag: determines choice between Rouse and Miles concentration profile
!     SET_LAG = TRUE : Miles
!             = FALSE: Rouse
!
      SET_LAG  = MOTLOG(ADRESS(3,27) )
!     STATIONARY MODE: calculate sediment transport without updating the bed.
      STAT_MODE  = MOTLOG(ADRESS(3,28) )
! 
!
! ################################### !
! CHARACTER STRING KEYWORDS           !
! ################################### !
!
      TITCA            = MOTCAR( ADRESS(4, 1) )(1:72)
      SORTIS           = MOTCAR( ADRESS(4, 2) )(1:72)
      VARIM            = MOTCAR( ADRESS(4, 3) )(1:72)
      SIS_FILES(SISGEO)%NAME=MOTCAR( ADRESS(4,6) )
      SIS_FILES(SISCLI)%NAME=MOTCAR( ADRESS(4,9) )
      SIS_FILES(SISHYD)%NAME=MOTCAR( ADRESS(4,29) )
      SIS_FILES(SISPRE)%NAME=MOTCAR( ADRESS(4,11) )
      SIS_FILES(SISRES)%NAME=MOTCAR( ADRESS(4,12) )
      SIS_FILES(SISFON)%NAME=MOTCAR( ADRESS(4,16) )
      SIS_FILES(SISRES)%FMT = MOTCAR( ADRESS(4,31) )(1:8)
      CALL MAJUS(SIS_FILES(SISRES)%FMT)
!     RESULT FILE FORMAT FOR PREVIOUS SEDIMENTOLOGICAL
!     COMPUTATION...
      SIS_FILES(SISPRE)%FMT = MOTCAR( ADRESS(4,34) )(1:8)
      CALL MAJUS(SIS_FILES(SISPRE)%FMT)
!     REFERENCE FILE FORMAT
      SIS_FILES(SISREF)%FMT = MOTCAR( ADRESS(4,33) )(1:8)
      CALL MAJUS(SIS_FILES(22)%FMT)
!     HYDRODYNAMIC FILE FORMAT
      SIS_FILES(SISHYD)%FMT = MOTCAR( ADRESS(4,32) )(1:8)
      CALL MAJUS(SIS_FILES(SISHYD)%FMT)
!     WAVE FILE FORMAT (COUPLING WITH TOMAWAC)
      SIS_FILES(SISCOU)%FMT = MOTCAR( ADRESS(4,35) )(1:8)
      CALL MAJUS(SIS_FILES(SISCOU)%FMT)
      BINGEOSIS        = MOTCAR( ADRESS(4,18) )(1:3)
      BINHYDSIS        = MOTCAR( ADRESS(4,19) )(1:3)
      BINPRESIS        = MOTCAR( ADRESS(4,20) )(1:3)
      BINRESSIS        = MOTCAR( ADRESS(4,21) )(1:3)
      SIS_FILES(SISREF)%NAME=MOTCAR( ADRESS(4,22) )
      BINREFSIS        = MOTCAR( ADRESS(4,23) )(1:3)
!     DREDGESIM STEERING FILE
      SIS_FILES(SISMAF)%NAME = MOTCAR( ADRESS(4,27) )
!     ******           = MOTCAR( ADRESS(4,28) )
!     WAVE FILE
      SIS_FILES(SISCOU)%NAME=MOTCAR( ADRESS(4,30) )
!     SECTIONS
      SIS_FILES(SISSEC)%NAME=MOTCAR( ADRESS(4,36) )
      SIS_FILES(SISSEO)%NAME=MOTCAR( ADRESS(4,37) )
!     FILE FOR LIQUID BOUNDARIES
      SIS_FILES(SISLIQ)%NAME=MOTCAR( ADRESS(4,38) )
! PAT 090812
!     GEOMETRY FILE FORMAT
      SIS_FILES(SISGEO)%FMT = MOTCAR( ADRESS(4,39) )(1:8)
      CALL MAJUS(SIS_FILES(SISGEO)%FMT)

      !UHM FOR CVSP, But its not Beautiful
      TEMPVAR  =   MOTCAR(ADRESS(4,51)   )
      CALL LECDON_SPLIT_OUTPUTPOINTS(TEMPVAR,CVSMOUTPUT,CVSM_OUT_FULL)
      !UHM

      IF(LNG.EQ.1) WRITE(LU,101)
      IF(LNG.EQ.2) WRITE(LU,102)
101   FORMAT(1X,/,19X, '********************************************',/,
     &            19X, '*               LECDON:                    *',/,
     &            19X, '*        APRES APPEL DE DAMOCLES           *',/,
     &            19X, '*     VERIFICATION DES DONNEES LUES        *',/,
     &            19X, '*     SUR LE FICHIER DES PARAMETRES        *',/,
     &            19X, '********************************************',/)
102   FORMAT(1X,/,19X, '********************************************',/,
     &            19X, '*               LECDON:                    *',/,
     &            19X, '*        AFTER CALLING DAMOCLES            *',/,
     &            19X, '*        CHECKING OF DATA  READ            *',/,
     &            19X, '*         IN THE STEERING FILE             *',/,
     &            19X, '********************************************',/)
!
!-----------------------------------------------------------------------
!
! LOGICALS FOR OUTPUT VARIABLES
!-----------------------------------------------------------------------
!
      NOMBLAY=MAX(NOMBLAY,NCOUCH_TASS)
      NCOUCH_TASS=NOMBLAY
!
      CALL NOMVAR_SISYPHE(TEXTE,TEXTPR,MNEMO,NSICLA,UNIT,MAXVAR,
     &                    NPRIV,NOMBLAY)
      CALL SORTIE(SORTIS , MNEMO , MAXVAR , SORLEO )
      CALL SORTIE(VARIM  , MNEMO , MAXVAR , SORIMP )
!
      DO I = 1, 4
        IF ((NPRIV.LT.I).AND.
            ! JWI 31/05/2012 - added 1 to include wave orbital velocities
     &      (SORLEO(I+28+(NOMBLAY+4)*NSICLA+NOMBLAY).OR.
     &       SORIMP(I+28+(NOMBLAY+4)*NSICLA+NOMBLAY))) THEN
          NPRIV=MAX(NPRIV,I)
        ENDIF
      ENDDO
!
!-----------------------------------------------------------------------
!
!     CANCELS OUTPUT OF VARIABLES WHICH ARE NOT BUILT IN THIS CASE
!
      IF(.NOT.SUSP) THEN
!V 7/09/2006 MIGHT WANT TO OUTPUT THE SUSPENDED COMPONENT IN BIJKER
!        SORIMP(24+4*NSICLA)=.FALSE.
!        SORIMP(25+4*NSICLA)=.FALSE.
!        SORIMP(26+4*NSICLA)=.FALSE.
      ENDIF
!   
! JWI 31/05/2012 - added 1 to include wave orbital velocities
      IF(.NOT.CHARR) THEN
        SORLEO(23+(NOMBLAY+2)*NSICLA)=.FALSE.
        SORLEO(24+(NOMBLAY+2)*NSICLA)=.FALSE.
        SORLEO(25+(NOMBLAY+2)*NSICLA)=.FALSE.
        SORIMP(23+(NOMBLAY+2)*NSICLA)=.FALSE.
        SORIMP(24+(NOMBLAY+2)*NSICLA)=.FALSE.
        SORIMP(25+(NOMBLAY+2)*NSICLA)=.FALSE.
      ENDIF
! JWI END
!
!-----------------------------------------------------------------------
!
! CHECKS TETA VALUE
!
      IF( TETA.LT.0.D0.OR.TETA.GT.1.D0) THEN
          IF (LNG.EQ.1) WRITE(LU,50)
          IF (LNG.EQ.2) WRITE(LU,51)
50      FORMAT(/,1X,'VALEUR DE TETA INCORRECTE !            ',/
     &          ,1X,'TETA DOIT ETRE COMPRIS ENTRE 0 ET 1    ')
51      FORMAT(/,1X,'BAD VALUE FOR TETA !                   ',/
     &          ,1X,'TETA MUST BE WITHIN 0 AND 1            ')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!     INITIALISES MSK (MASKING VARIABLE)
!     FOR NOW MASKING IS ONLY DONE FOR ONE 'OPTION FOR THE TREATMENT
!     OF TIDAL FLATS'. SHOULD BE OFFERED AS AN OPTION FOR THE USER TO
!     CREATE ISLANDS IN THE FUTURE
      MSK = .FALSE.
      IF (.NOT.BANDEC) OPTBAN=0
      IF (OPTBAN.EQ.2) MSK = .TRUE.
!
!-----------------------------------------------------------------------
!
!     CHECKS WHETHER THERE IS A VALIDATION FILE
!
      IF (VALID.AND.SIS_FILES(SISREF)%NAME.EQ.' ') THEN
          VALID=.FALSE.
        IF (LNG.EQ.1) WRITE(LU,70)
        IF (LNG.EQ.2) WRITE(LU,71)
        WRITE(LU,*)
70      FORMAT(/,1X,'VALIDATION IMPOSSIBLE  :      ',/
     &          ,1X,'PAS DE FICHIER DE VALIDATION !        ')
71      FORMAT(/,1X,'VALIDATION IS NOT POSSIBLE :  ',/
     &          ,1X,'NO VALIDATION FILE  !                 ')
      ENDIF
!
!MGDL
!     CHECKS THE NUMBER OF NSICLA
!      IF(NSICLA.GT.10) THEN
      IF(NSICLA.GT.NSICLM) THEN
      IF (LNG.EQ.1) WRITE(LU,80) NSICLM
        IF (LNG.EQ.2) WRITE(LU,81) NSICLM
        WRITE(LU,*)
80      FORMAT(/,1X,'LE NOMBRE MAXIMUM DE CLASSES DE SEDIMENTS EST 10'
     &         , I2)
81      FORMAT(/,1X,'THE MAXIMUM NUMBER OF SEDIMENT CLASSES IS', I2)
        CALL PLANTE(1)
        STOP
      ENDIF
!     CHECKS THE SUM OF INITIAL AVAI
      DO I=1,NSICLA
      SUMAVAI = SUMAVAI + AVA0(I)
      ENDDO
      IF(ABS(SUMAVAI-1).GE.1.D-8) THEN
      IF (LNG.EQ.1) WRITE(LU,90)
        IF (LNG.EQ.2) WRITE(LU,91)
        WRITE(LU,*)
90      FORMAT(/,1X,'LA SOMME DES FRACTIONS DE SEDIMENTS ',/
     &          ,1X,'EST DIFFERENTE DE 1 !        ')
91      FORMAT(/,1X,'SUM OF SEDIMENT FRACTIONS IS NOT 1  ')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!     WARNING FOR THE CHOICE OF RIGID BED METHOD
!
      IF(CHOIX.GT.0.AND.CHOIX.LT.4.AND.VF) THEN
      IF(LNG.EQ.1) WRITE(LU,200)
        IF (LNG.EQ.2) WRITE(LU,201)
        WRITE(LU,*)
200     FORMAT(/,1X,'CALCUL EN VOLUMES FINIS : ',/
     &          ,1X,'LA METHODE 4 POUR LES FONDS NON ERODABLES SERA UTIL
     &ISEE ')
201     FORMAT(/,1X,'FINITE VOLUMES CHOSEN: ',/
     &          ,1X,'METHOD 4 FOR RIGID BED WILL BE USED ')
!       ADDED BY JMH 12/07/2007
        CHOIX=4
      ENDIF
      IF (CHOIX.EQ.4.AND..NOT.VF) THEN
        IF(LNG.EQ.1) WRITE(LU,300)
        IF(LNG.EQ.2) WRITE(LU,301)
        WRITE(LU,*)
300     FORMAT(/,1X,'CALCUL EN ELEMENTS FINIS : ',/
     &          ,1X,'LA METHODE 4 NE PEUT ETRE UTILISEE, METHODE 3 UTILI
     &SEE A LA PLACE')
301     FORMAT(/,1X,'FINITE ELEMENTS CHOSEN: ',/
     &          ,1X,'METHOD 4 FOR RIGID BED CAN NOT BE USED, METHOD 3 US
     &ED INSTEAD')
!       ADDED BY JMH 12/07/2007
        CHOIX=3
      ENDIF
!
!     CHECKS THAT THE BEDLOAD TRANSPORT FORMULATION AND THE HIDING
!     FACTOR FORMULATION CAN GO TOGETHER
!
      IF ((HIDFAC.EQ.3.AND.ICF.NE.6).OR.
     &    (HIDFAC.EQ.1.AND.ICF.NE.1).OR.
     &    (HIDFAC.EQ.2.AND.ICF.NE.1)) THEN
      IF (LNG.EQ.1) WRITE(LU,110)
        IF (LNG.EQ.2) WRITE(LU,111)
        WRITE(LU,*)
110     FORMAT(/,1X,'MAUVAIS ASSOCIATION ENTRE LA FORMULE DE TRANSPORT E
     &T LE HIDING FACTOR ')
111     FORMAT(/,1X,'CHOICE OF TRANSPORT FORMULA AND HIDING FACTOR FORMU
     &LATION NOT ALLOWED ')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!     WITHOUT AND WITH COUPLING, SOME CORRECTIONS
!
      IF(CODE(1:7).EQ.'TELEMAC'.AND.
     &   SIS_FILES(SISHYD)%NAME(1:1).NE.' ') THEN
        SIS_FILES(SISHYD)%NAME(1:1)=' '
        IF(LNG.EQ.1) WRITE(LU,112)
112     FORMAT(/,1X,'COUPLAGE : FICHIER HYDRODYNAMIQUE IGNORE')
        IF(LNG.EQ.1) WRITE(LU,113)
113     FORMAT(/,1X,'COUPLING: HYDRODYNAMIC FILE IGNORED')
      ENDIF
!
!     COMPUTATION CONTINUED
!
      IF(DEBU) THEN
        IF(SIS_FILES(SISPRE)%NAME(1:1).EQ.' ') THEN
          IF(LNG.EQ.1) WRITE(LU,312)
312       FORMAT(/,1X,'SUITE DE CALCUL :',/,
     &    1X,'FICHIER PRECEDENT SEDIMENTOLOGIQUE ABSENT')
          IF(LNG.EQ.2) WRITE(LU,313)
313       FORMAT(/,1X,'COMPUTATION CONTINUED:',/,
     &             1X,'PREVIOUS SEDIMENTOLOGICAL FILE MISSING')
          CALL PLANTE(1)
          STOP
        ENDIF
      ELSE
        IF(SIS_FILES(SISPRE)%NAME(1:1).NE.' ') THEN
          SIS_FILES(SISPRE)%NAME(1:1)=' '
          IF(LNG.EQ.1) WRITE(LU,212)
212       FORMAT(/,1X,'PAS DE SUITE DE CALCUL :',/,
     &             1X,'FICHIER PRECEDENT SEDIMENTOLOGIQUE IGNORE')
          IF(LNG.EQ.2) WRITE(LU,213)
213       FORMAT(/,1X,'NO COMPUTATION CONTINUED:',/,
     &             1X,'PREVIOUS SEDIMENTOLOGICAL FILE IGNORED')
        ENDIF
      ENDIF
!
! METHODS NOT CODED UP FOR SUSPENSION
! -------------------------------------------
!
!     JMH ON 09/10/2009 : NEW PARAMETERISATION AND NEW SCHEMES
!
      IF(SUSP) THEN
        IF(RESOL.NE.ADV_CAR   .AND.RESOL.NE.ADV_SUP   .AND.
     &     RESOL.NE.ADV_PSI_NC.AND.RESOL.NE.ADV_NSC_NC.AND.
     &     RESOL.NE.ADV_LPO   .AND.RESOL.NE.ADV_NSC   .AND.
     &     RESOL.NE.ADV_PSI   .AND.RESOL.NE.ADV_LPO_TF.AND.
     &     RESOL.NE.ADV_NSC_TF                              ) THEN
          IF (LNG.EQ.1) WRITE(LU,302) RESOL
          IF (LNG.EQ.2) WRITE(LU,303) RESOL
302       FORMAT(1X,'METHODE DE RESOLUTION NON PROGRAMMEE : ',1I6)
303       FORMAT(1X,'RESOLVING METHOD NOT IMPLEMENTED : ',1I6)
          IF(RESOL.EQ.8) THEN
            IF(LNG.EQ.1) WRITE(LU,*) 
     &                'LE SCHEMA 8 AVANT VERSION 6.0 EST DEVENU LE 4'
            IF(LNG.EQ.2) WRITE(LU,*) 
     &                'NUMBER 8 PRIOR TO VERSION 6.0 IS NOW NUMBER 4'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!C
! CV 27/01/2005
!
      IF(.NOT.HOULE) SIS_FILES(SISCOU)%NAME(1:1)=' '
      IF(HOULE) THEN
        IF(ICF.NE.4.AND.ICF.NE.5.AND.ICF.NE.8.AND.ICF.NE.9) THEN
          IF(LNG.EQ.1) WRITE(LU,1303) ICF
          IF(LNG.EQ.2) WRITE(LU,1304) ICF
1303      FORMAT(' LA FORMULE DE TRANSPORT',1I3,1X,
     &       'NE PREND PAS EN COMPTE LA HOULE,',/,1X,
     &       'ESSAYER 4, 5, 8 OU 9')
1304      FORMAT(' TRANSPORT FORMULA',1I3,1X,
     &       'DOES NOT TAKE WAVES INTO ACCOUNT,',/,1X,
     &       'TRY 4, 5, 8 OR 9')
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
! BEDLOAD AND SUSPENDED TRANSPORT COUPLING
! ---------------------------------
!
      IF((ICF==30.OR.ICF==3.OR.ICF==9).AND.SUSP.AND.CHARR) THEN
        IF(LNG.EQ.1) WRITE(LU,1301) ICF
        IF(LNG.EQ.2) WRITE(LU,1302) ICF
        CALL PLANTE(1)
        STOP
      ENDIF
1301  FORMAT('POUR LA FORMULE :',1I3,/,1X,
     &       'LE TERME DE TRANSPORT EN SUSPENSION EST CALCULE'
     &      ,' LORS DU CHARRIAGE ET LORS DE LA SUSPENSION')
1302  FORMAT('FOR THE FORMULA',1I3,/,1X,
     &       'THE SUSPENSION TERM IS CALCULATED TWICE,'
     &      ,' WITH TOTAL LOAD FORMULA AND SUSPENSION ')
!
! REFERENCE CONCENTRATION
!
! MODIFICATION CV 31/12      IF(ICQ.EQ.2.AND.(PERCOU.NE.1.OR..NOT.CHARR)) THEN
!
      IF(ICQ.EQ.2.AND.(PERCOU.GT.1.OR..NOT.CHARR)) THEN
        IF(LNG == 1) WRITE(LU,1401) ICQ
        IF(LNG == 2) WRITE(LU,1402) ICQ
1401  FORMAT('POUR LA METHODE DE BIJKER: ICQ=',1I3,/,1X,
     &       'LE CHARRIAGE DOIT ETRE CALCULE A CHAQUE PAS DE TEMPS
     &       , CHOISIR  : PERCOU = 1 ET',/,1X,
     &       'CHARRIAGE=OUI')
1402  FORMAT('FOR THE BIJKER REFERENCE CONCENTRATION',1I3,/,1X,
     &       'BEDLOAD MUST BE COMPUTED, CHOOSE:',/,1X,
     &       'BEDLOAD = YES')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!     CHECKS CONSISTENCY OF BEDLOAD LAWS
!
!     SOULSBY SLOPE EFFECT : REQUIRES A THRESHOLD FORMULA
!
      IF(SLOPEFF.EQ.2) THEN
!       CHECK FOR ICF=6
!       IF(ICF.NE.1.AND.ICF.NE.6) THEN
        IF(ICF.NE.1) THEN
        IF(LNG == 1) WRITE(LU,1403) ICF
        IF(LNG == 2) WRITE(LU,1404) ICF
1403    FORMAT('LA LOI DE TRANSPORT SOLIDE, ICI ICF=',1I3,/,1X,
     &         'DOIT ETRE UNE FORMULE A SEUIL',/,1X,
     &         'SI FORMULE POUR EFFET DE PENTE=2 (SOULSBY)')
1404    FORMAT('BED-LOAD TRANSPORT FORMULA, HERE ICF=',1I3,/,1X,
     &         'MUST HAVE A THRESHOLD',/,1X,
     &         'IF FORMULA FOR SLOPE EFFECT=2 (SOULSBY)')
        ENDIF
      ENDIF
!
! V6P0 : COHERENCE IF CONSOLIDATION MODEL IS USED
! VITCE AND CSF_VASE STEM FROM THE FIRST LAYER OF THE MULTI-LAYER MODEL
! +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
! Mots cl??s supprim??s vitesse critique d'erosion et concentration du lit
! CV : si premi??re couche est  vide cela n'est pas correct

!
      IF(MIXTE) THEN
!
!       FILLS VOIDS WITH MUD:
! CV: v??rifier que la concentration en coh??sif est non nulle
!
        CSF_SABLE= 1.D0
!V: verrouiller les options
        NSICLA=2
        SEDCO(1)=.FALSE.
        SEDCO(2)=.TRUE.
        CHARR=.FALSE.
        SUSP=.TRUE.
!V
      ELSE
        CSF_SABLE= (1.D0-XKV)
      ENDIF
!
      IF((.NOT.MIXTE).AND.SEDCO(1)) THEN
        CHARR=.FALSE.
        !SUSP=.TRUE. (In general, but not necessary)
      ENDIF
!
      IF(NOMBLAY.GT.NLAYMAX) THEN
        WRITE (LU,*) 'NUMBER OF BED LOAD MODEL LAYERS LARGER THAN '
        WRITE (LU,*) 'THE MAXIMUM PROGRAMMED VALUE OF ', NLAYMAX
        CALL PLANTE(1)
        STOP
      ENDIF
!      IF(NOMBLAY.LT.2) THEN
!        WRITE (LU,*) 'BEWARE: NUMBER OF BED LOAD MODEL LAYERS'
!        WRITE (LU,*) '======= LOWER THAN THE DEFAULT VALUE OF 2'
!      ENDIF
!
!----------------------------------------------------------------
!
!  V6P1: FOR THE BED FRICTION PREDICTOR USE LAW OF FRICTION 5 (NIKURADSE)
!
      IF(KSPRED) KFROT=5
!
!----------------------------------------------------------------
!
      RETURN
      END
