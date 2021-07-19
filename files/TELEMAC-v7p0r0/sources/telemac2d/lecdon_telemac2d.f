!                    ***************************
                     SUBROUTINE LECDON_TELEMAC2D
!                    ***************************
!
     &(MOTCAR,WMOTCAR,FILE_DESC,WFILE_DESC,PATH,NCAR)
!
!***********************************************************************
! TELEMAC2D   V7P0                                   21/08/2010
!***********************************************************************
!
!brief    READS THE STEERING FILE THROUGH A DAMOCLES CALL.
!
!history  J-M HERVOUET (LNHE)
!+        20/04/2010
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
!history  C.COULET (ARTELIA)
!+        30/03/2012
!+        V6P2
!+   Modification for adding "bridge" file and separation of weirs and
!+   culvert file
!
!history  C.COULET / A.MASSON (ARTELIA) / P. CHASSE (CETMEF)
!+        19/07/2012
!+        V6P2
!+   Modification for adding breaches management during simulation
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        12/02/2013
!+        V6P3
!+   Treatment of drogues (floats) modified.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        14/03/2013
!+        V6P3
!+   Treatment of spatial projection type.
!
!history  C.COULET / A.REBAI / E.DAVID (ARTELIA)
!+        30/04/2013
!+        V6P3
!+   Modification for new treatment of weirs
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        24/12/2013
!+        V6P3
!+   Now wave driven currents may be discarded in coupling with Tomawac.
!+   Actually the user may want a one way coupling.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        31/03/2014
!+        V7P0
!+   Different advection schemes for different solvers allowed.
!
!history  D WANG & P TASSI (LNHE)
!+        10/07/2014
!+        V7P0
!+   Secondary flow correction: set the conditions for \Omega.
!
!history  C. VILLARET (HRW)
!+        03/10/2014
!+        V7P0
!+   Friction enhancement
!
!history R. ATA
!+        10/11/2014
!+        V7P0
!+   introduction of water quality 
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| FILE_DESC      |<--| STORES STRINGS 'SUBMIT' OF DICTIONARY
!| MOTCAR         |<--| VALUES OF KEY-WORDS OF TYPE CHARACTER
!| NCAR           |-->| NUMBER OF LETTERS IN STRING PATH
!| PATH           |-->| FULL PATH TO CODE DICTIONARY
!| WFILE_DESC     |<--| STORES STRINGS 'SUBMIT' OF DICTIONARY FOR WAQ
!| WMOTCAR        |<--| VALUES OF KEY-WORDS OF TYPE CHARACTER FOR WAQ
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_TELEMAC2D
      USE DECLARATIONS_WAQTEL
!
      USE INTERFACE_TELEMAC2D, EX_LECDON_TELEMAC2D => LECDON_TELEMAC2D
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)               :: NCAR
      CHARACTER(LEN=250), INTENT(IN)    :: PATH
      CHARACTER(LEN=144), INTENT(INOUT) :: FILE_DESC(4,MAXKEY)
      CHARACTER(LEN=144), INTENT(INOUT) :: MOTCAR(MAXKEY)
!     WAQ
      CHARACTER(LEN=144), INTENT(INOUT) :: WFILE_DESC(4,MAXKEY)
      CHARACTER(LEN=144), INTENT(INOUT) :: WMOTCAR(MAXKEY)
!                                                 
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER I,K,ERR,ITRAC,NTRTOT
      INTEGER NREJEX,NREJEY,NCOSUP,NREJEV,NCRITE
!
      CHARACTER*8 MNEMO(MAXVAR)
      CHARACTER(LEN=250) NOM_CAS,NOM_DIC
      CHARACTER(LEN=250) NOM_CAS_WAQ,NOM_DIC_WAQ
!
!-----------------------------------------------------------------------
!
      CHARACTER(LEN=2) I_IN_2_LETTERS(34)
      DATA I_IN_2_LETTERS /'1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ',
     &                     '10','11','12','13','14','15','16','17','18',
     &                     '19','20','21','22','23','24','25','26','27',
     &                     '28','29','30','31','32','33','34'/
!
      CHARACTER(LEN=24), PARAMETER :: CODE1='TELEMAC2D               '
!      CHARACTER(LEN=24), PARAMETER :: CODE2='WAQTEL                  '
!
!-----------------------------------------------------------------------
!
!     ARRAYS USED IN THE DAMOCLES CALL
!
      INTEGER              ADRESS(4,MAXKEY),DIMEN(4,MAXKEY)
      DOUBLE PRECISION     MOTREA(MAXKEY)
      INTEGER              MOTINT(MAXKEY)
      LOGICAL              MOTLOG(MAXKEY)
      CHARACTER*72         MOTCLE(4,MAXKEY,2)
      INTEGER              TROUVE(4,MAXKEY)
      LOGICAL DOC
!     ARRAYS USED IN THE DAMOCLES CALL FOR WAQ
!
      INTEGER              WADRESS(4,MAXKEY),WDIMEN(4,MAXKEY)
      DOUBLE PRECISION     WMOTREA(MAXKEY)
      INTEGER              WMOTINT(MAXKEY)
      LOGICAL              WMOTLOG(MAXKEY)
      CHARACTER*72         WMOTCLE(4,MAXKEY,2)
      INTEGER              WTROUVE(4,MAXKEY)
!
!     END OF DECLARATIONS FOR DAMOCLES CALL :
!
!-----------------------------------------------------------------------
!
      INTRINSIC MAX,INT,MOD
!
!-----------------------------------------------------------------------
!
! INITIALISES THE ARRAYS TO DEFAULT VALUES (NOT DONE IN DAMOCLES)
!
      ICONVF(1) = ADV_CAR
!     NO ADVECTION IS CONSIDERED ON H
      ICONVF(2) = 5
      ICONVF(3) = ADV_CAR
      ICONVF(4) = ADV_CAR
!
      DISCRE(1) = 11
      DISCRE(2) = 11
      DISCRE(3) = 11
      DISCRE(4) = 11
!
      COSUPG(1) = 1.D0
      COSUPG(2) = 1.D0
      COSUPG(3) = 1.D0
      COSUPG(4) = 1.D0
!
      OPTSUP(1) = 2
      OPTSUP(2) = 2
      OPTSUP(3) = 2
      OPTSUP(4) = 2
!
      BORNES(1) = -1000.D0
      BORNES(2) = +9000.D0
      BORNES(3) = -1000.D0
      BORNES(4) = +1000.D0
      BORNES(5) = -1000.D0
      BORNES(6) = +1000.D0
      BORNES(7) = -1000.D0
      BORNES(8) = +1000.D0
!
      CRIPER(1) = 1.D-4
      CRIPER(2) = 1.D-4
      CRIPER(3) = 1.D-4
!
      DO K=1,MAXFRO
        FRTYPE(K)=1
        PROVEL(K)=1
        STA_DIS_CURVES(K)=0
      ENDDO ! K
!
!-----------------------------------------------------------------------
!
! INITIALISES THE VARIABLES FOR DAMOCLES CALL :
!
      DO K=1,MAXKEY
!       A FILENAME NOT GIVEN BY DAMOCLES WILL BE RECOGNIZED AS A WHITE SPACE
!       (IT MAY BE THAT NOT ALL COMPILERS WILL INITIALISE LIKE THAT)
        MOTCAR(K)(1:1)=' '
!
        DIMEN(1,K) = 0
        DIMEN(2,K) = 0
        DIMEN(3,K) = 0
        DIMEN(4,K) = 0
!
        WMOTCAR(K)(1:1)=' '
!
        WDIMEN(1,K) = 0
        WDIMEN(2,K) = 0
        WDIMEN(3,K) = 0
        WDIMEN(4,K) = 0
      ENDDO ! K
!     WRITES OUT INFO
      DOC = .FALSE.
      ADDTR = 0
!
!-----------------------------------------------------------------------
!     OPENS DICTIONNARY AND STEERING FILES
!-----------------------------------------------------------------------
!
      IF(NCAR.GT.0) THEN
!
        NOM_DIC=PATH(1:NCAR)//'T2DDICO'
        NOM_CAS=PATH(1:NCAR)//'T2DCAS'
!       WAQTEL
        NOM_DIC_WAQ=PATH(1:NCAR)//'T2DWQD'
        NOM_CAS_WAQ=PATH(1:NCAR)//'T2DWAQ'
!
      ELSE
!
        NOM_DIC='T2DDICO'
        NOM_CAS='T2DCAS'
!       WAQTEL
        NOM_DIC_WAQ='T2DWQD'
        NOM_CAS_WAQ='T2DWAQ'
!
      ENDIF
!
      OPEN(2,FILE=NOM_DIC,FORM='FORMATTED',ACTION='READ')
      OPEN(3,FILE=NOM_CAS,FORM='FORMATTED',ACTION='READ')
!
!-----------------------------------------------------------------------
!
      CALL DAMOCLE( ADRESS , DIMEN  , MAXKEY , DOC     , LNG    , LU ,
     &              MOTINT , MOTREA , MOTLOG , MOTCAR  , MOTCLE ,
     &              TROUVE , 2      , 3      , .FALSE. , FILE_DESC )
!
!-----------------------------------------------------------------------
!     CLOSES DICTIONNARY AND STEERING FILES
!-----------------------------------------------------------------------
      CLOSE(2)
      CLOSE(3)  
!
!     FIRST VERIFY IF WE CALL WAQ OR NOT
!
      WATQUA    = MOTLOG( ADRESS(3, 48) ) 
!     SECONDARY CURRENT ALSO
      SECCURRENTS = MOTLOG(ADRESS(3,49))
      IF(WATQUA)THEN  
!
        OPEN(2,FILE=NOM_DIC_WAQ,FORM='FORMATTED',ACTION='READ',ERR=9000)
        OPEN(3,FILE=NOM_CAS_WAQ,FORM='FORMATTED',ACTION='READ',ERR=9000)
!
!       CALLING DAMCOCLE FOR WAQTEL
!
        CALL DAMOCLE( WADRESS, WDIMEN, MAXKEY , DOC     , LNG    , LU ,
     &                WMOTINT , WMOTREA , WMOTLOG , WMOTCAR  , WMOTCLE,
     &                WTROUVE , 2       , 3    , .FALSE. , WFILE_DESC )
!
!-----------------------------------------------------------------------
!     CLOSES DICTIONNARY AND STEERING FILES
!-----------------------------------------------------------------------
!
        CLOSE(2)
        CLOSE(3)
      ENDIF
!
!     ANALYSIS OF 'SUBMIT' CHAINS
!
      CALL READ_SUBMIT(T2D_FILES,   MAXLU_T2D,   CODE1,FILE_DESC, 300)
!
!      NOT NECESSAY SO FAR, TO ACTIVATE WHEN WORKING IN STANDALONE  
!      IF(WATQUA) CALL 
!     &     READ_SUBMIT(WAQTEL_FILES,MAXLU_WAQTEL,CODE1,WFILE_DESC,300)

!-----------------------------------------------------------------------
!
!     RETRIEVES FILES NUMBERS IN TELEMAC-2D FORTRAN PARAMETERS
!     HERE LOGICAL UNITS EQUAL TO THE FILE NUMBER
!
      DO I=1,MAXLU_T2D
        IF(T2D_FILES(I)%TELNAME.EQ.'T2DGEO') THEN
!         T2DGEO=T2D_FILES(I)%LU  (IS EQUIVALENT)
          T2DGEO=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DCLI') THEN
          T2DCLI=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DPRE') THEN
          T2DPRE=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DRES') THEN
          T2DRES=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DFON') THEN
          T2DFON=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBI1') THEN
          T2DBI1=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBI2') THEN
          T2DBI2=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DFO1') THEN
          T2DFO1=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DFO2') THEN
          T2DFO2=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DRBI') THEN
          T2DRBI=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DRFO') THEN
          T2DRFO=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DREF') THEN
          T2DREF=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DIMP') THEN
          T2DIMP=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DCOF') THEN
          T2DCOF=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL1') THEN
          T2DDL1=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL2') THEN
          T2DDL2=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL3') THEN
          T2DDL3=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL4') THEN
          T2DDL4=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL5') THEN
          T2DDL5=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL6') THEN
          T2DDL6=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL7') THEN
          T2DDL7=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL8') THEN
          T2DDL8=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DDL9') THEN
          T2DDL9=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DL10') THEN
          T2DL10=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DL11') THEN
          T2DL11=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DMAB') THEN
          T2DMAB=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DVEF') THEN
          T2DVEF=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DSEC') THEN 
          T2DSEC=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DSEO') THEN 
          T2DSEO=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DMIG') THEN
          T2DMIG=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DHAR') THEN
          T2DHAR=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DTID') THEN
          T2DTID=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBDD') THEN
          T2DBDD=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBB1') THEN
          T2DBB1=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBB2') THEN
          T2DBB2=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DSEU') THEN
          T2DSEU=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DSIP') THEN
          T2DSIP=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBUS') THEN
          T2DBUS=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DBRC') THEN
          T2DBRC=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DFLO') THEN
          T2DFLO=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DZFI') THEN
          T2DZFI=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DWAQ') THEN
          T2DWAQ=I
        ELSEIF(T2D_FILES(I)%TELNAME.EQ.'T2DWQD') THEN
          T2DWQD=I
        ELSEIF(I.NE.02.AND.I.NE.03.AND.I.NE.05.AND.I.NE.06)THEN
!         ONE FILE THAT SHOULD HAVE A STRING 'SUBMIT' IN DICTIONARY
!         HAS RECEIVED NO NAME
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'LECDON_TELEMAC2D: ERREUR POUR LE FICHIER' 
            WRITE(LU,*) 'I=',I,' NOM=',T2D_FILES(I)%TELNAME
            WRITE(LU,*) 'IL MANQUE UNE CHAINE SUBMIT DANS LE'
            WRITE(LU,*) 'DICTIONNAIRE'
            WRITE(LU,*) 'OU INSTALLATION DEFECTUEUSE.'
          ELSEIF(LNG.EQ.2) THEN
            WRITE(LU,*) 'LECDON_TELEMAC2D: ERROR FOR FILE NUMBER' 
            WRITE(LU,*) 'I=',I,' NAME=',T2D_FILES(I)%TELNAME
            WRITE(LU,*) 'THIS FILE SHOULD HAVE A STRING SUBMIT'
            WRITE(LU,*) 'IN DICTIONARY'
            WRITE(LU,*) 'OR INSTALLATION PROBLEM.'
          ENDIF 
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDDO
!
      IF(WATQUA)THEN
!
!     RETRIEVES FILES NUMBERS IN WAQTEL PARAMETERS
!  
        DO I=1,MAXLU_WAQTEL
          IF    (WAQTEL_FILES(I)%TELNAME.EQ.'WAQCAS') THEN
            WAQCAS=I
          ELSEIF(WAQTEL_FILES(I)%TELNAME.EQ.'WAQGEO') THEN
            WAQGEO=I
          ELSEIF(WAQTEL_FILES(I)%TELNAME.EQ.'WAQRES') THEN
            WAQRES=I
          ELSEIF(WAQTEL_FILES(I)%TELNAME.EQ.'WAQREF') THEN
            WAQREF=I
          ENDIF
        ENDDO
!     
!     ASSIGNS THE WAQ STEERING FILE VALUES TO THE PARAMETER FORTRAN NAME
!
!-----------------------------------------------------------------------
!*******************************
!   WAQ  INTEGER KEYWORDS      *
!*******************************
!
!       PRINTOUT WAQ PERIOD
!       WLEOPRD    = WMOTINT( ADRESS(1,  1) )
!       WAQ PROCESS
        WAQPROCESS = WMOTINT( WADRESS(1,  2) )
!       K2 FORMULA
        FORMK2     = WMOTINT( WADRESS(1,  3) )
!       CS FORMULA
        FORMCS     = WMOTINT( WADRESS(1,  5) )
!       DEBUG KEYWORD
        DEBUG      = WMOTINT( WADRESS(1, 11) )
!
!*******************************
!       WAQ REAL KEYWORDS        *                   
!*******************************
!
        ROO    = WMOTREA( WADRESS(2,  2) )
        GRAV   = WMOTREA( WADRESS(2,  5) )
        VCE    = WMOTREA( WADRESS(2,  8) )
        LDISP  = WMOTREA( WADRESS(2, 11) )
        TDISP  = WMOTREA( WADRESS(2, 12) )
        K120   = WMOTREA( WADRESS(2, 21) )
        K520   = WMOTREA( WADRESS(2, 22) )
        O2PHOTO= WMOTREA( WADRESS(2, 25) )
        O2NITRI= WMOTREA( WADRESS(2, 26) )
        DEMBEN = WMOTREA( WADRESS(2, 29) )
        K22    = WMOTREA( WADRESS(2, 31) )
        O2SATU = WMOTREA( WADRESS(2, 33) )
        WPOR   = WMOTREA( WADRESS(2, 36) )
        WNOR   = WMOTREA( WADRESS(2, 39) )
        CMAX   = WMOTREA( WADRESS(2, 42) )
        PS     = WMOTREA( WADRESS(2, 45) )
        KPE    = WMOTREA( WADRESS(2, 48) )
        BETA   = WMOTREA( WADRESS(2, 51) )
        IK     = WMOTREA( WADRESS(2, 54) )
        KP     = WMOTREA( WADRESS(2, 57) )
        KN     = WMOTREA( WADRESS(2, 60) )
        CTOXIC = WMOTREA( WADRESS(2, 63) )
        TRESPIR= WMOTREA( WADRESS(2, 66) )
        PROPHOC= WMOTREA( WADRESS(2, 69) )
        DTP    = WMOTREA( WADRESS(2, 71) )
        K320   = WMOTREA( WADRESS(2, 73) )
        PRONITC= WMOTREA( WADRESS(2, 75) )
        PERNITS= WMOTREA( WADRESS(2, 77) )
        K360   = WMOTREA( WADRESS(2, 79) )
        CMORALG(1)= WMOTREA(WADRESS(2,81))
        CMORALG(2)= WMOTREA(WADRESS(2,81)+1)
        WLOR   = WMOTREA( WADRESS(2, 85) )
        K1     = WMOTREA( WADRESS(2, 90) )
        K44    = WMOTREA( WADRESS(2, 93) )
        PHOTO  = WMOTREA( WADRESS(2, 95) )
        RESP   = WMOTREA( WADRESS(2, 97) )
        WATTEMP= WMOTREA( WADRESS(2, 99) )
        ERO    = WMOTREA( WADRESS(2,104) )
        TAUR   = WMOTREA( WADRESS(2,106) )
        TAUS   = WMOTREA( WADRESS(2,109) )
        VITCHU = WMOTREA( WADRESS(2,111) )
        CCSEDIM= WMOTREA( WADRESS(2,113) )
        CDISTRIB= WMOTREA(WADRESS(2,115) )
        KDESORP= WMOTREA (WADRESS(2,117) )
        CP_EAU = WMOTREA( WADRESS(2,119) )
        CP_AIR = WMOTREA( WADRESS(2,121) )
        CFAER(1)=WMOTREA( WADRESS(2,125) )
        CFAER(2)=WMOTREA( WADRESS(2,125)+1) 
        COEF_K = WMOTREA( WADRESS(2,127) )
        EMA    = WMOTREA( WADRESS(2,129) )
        EMI_EAU= WMOTREA( WADRESS(2,131) )
!       INITIALIZE K2 DONE IN CALCS_O2
!        IF(WAQPROCESS.EQ.1.AND.FORMK2.EQ.0)THEN
!          CALL OS('X=C     ',K2,K2,K2,K22)
!        ENDIF      
!
!*******************************
!       LOGICAL KEYWORDS         *
!*******************************
!
        WQBILMAS= WMOTLOG( WADRESS(3,  1) )
        WQVALID = WMOTLOG( WADRESS(3,  3) )
!
!*******************************
!       STRING KEYWORDS          *
!*******************************
!
        TITWAQCAS = WMOTCAR( WADRESS(4, 2) ) (1:72)
!       SORTWAQ   = WMOTCAR( WADRESS(4, 3) ) (1:72)
!
!       FILES IN THE STEERING FILE (TO ACTIVATE FOR STANALONE RUN)
!
!       WAQTEL_FILES(WAQRES)%NAME=WMOTCAR( WADRESS(4,6 ) )
!       WAQTEL_FILES(WAQGEO)%NAME=WMOTCAR( WADRESS(4,8 ) )
!       WAQTEL_FILES(WAQREF)%NAME=WMOTCAR( WADRESS(4,12) )
!       WAQTEL_FILES(WAQHYD)%NAME=WMOTCAR( WADRESS(4,14) )
!
      ENDIF
!     JUMP HERE IF NO WAQ 
!
!     LOOKS FOR THE NUMBER OF TRACERS TO BE INCREASED 
!     DEPENDING ON THE WAQ PROCESS
!   
      IF(WATQUA.OR.SECCURRENTS)THEN  
!                                              
        CALL INCREASE_NTRAC(ADDTR,WATQUA,WAQPROCESS,SECCURRENTS,
     &                      MOTCAR,                    ! HERE ARE NAMETRAC
     &                      DIMEN(4,74),       
     &                      MOTINT( ADRESS(1,67)   ))  ! HERE IS NTRAC 
      ENDIF
!
!
!-----------------------------------------------------------------------
!
! ASSIGNS THE STEERING FILE VALUES TO THE PARAMETER FORTRAN NAME :
!
!-----------------------------------------------------------------------
!
! INTEGER KEYWORDS:
!
      LEOPRD           = MOTINT( ADRESS(1, 1) )
!
!     LISTING PRINTOUT PERIOD
!
      LISPRD           = MOTINT( ADRESS(1, 2) )
      IF(TROUVE(1,64).EQ.2) THEN
        LISPRD = MOTINT( ADRESS(1,64) )
      ENDIF
!
      NIT              = MOTINT( ADRESS(1, 3) )
!     PSI SCHEME OPTION
      OPTPSI           = MOTINT( ADRESS(1, 4) )
!     TYPE OF ADVECTION (TO BE REMOVED IN FUTURE VERSIONS)
      IF(DIMEN(1,5).NE.0) THEN
        DO K=1,DIMEN(1,5)
          ICONVF(K)     = MOTINT( ADRESS(1,5) + K-1 )
        ENDDO
      ENDIF
!     INDEX 6, SEE AFTER 46 (NBUSE)
      ITURB            = MOTINT( ADRESS(1, 7) )
      KFROT            = MOTINT( ADRESS(1, 8) )
      SLVPRO%NITMAX    = MOTINT( ADRESS(1,10) )
      OPTPRO           = MOTINT( ADRESS(1,12) )
      SLVK%NITMAX      = MOTINT( ADRESS(1,13) )
      SLVEP%NITMAX     = SLVK%NITMAX
      SLVPRO%PRECON    = MOTINT( ADRESS(1,14) )
      IORDRH    = MOTINT( ADRESS(1,15) )
      IF(DIMEN(1,16).NE.0) THEN
        DO K=1,DIMEN(1,16)
          DISCRE(K) = MOTINT( ADRESS(1,16) + K-1 )
        ENDDO ! K
      ENDIF
!     STDGEO    = MOTINT( ADRESS(1,17) )
!     STDRES    = MOTINT( ADRESS(1,18) )
      SLVPRO%SLV = MOTINT( ADRESS(1,19) )
!     STDPRE    = MOTINT( ADRESS(1,20) )
      NSOUSI    = MOTINT( ADRESS(1,21) )
      PTINIG    = MOTINT( ADRESS(1,22) )
      PTINIL    = MOTINT( ADRESS(1,23) )
      SLVK%SLV = MOTINT( ADRESS(1,25) )
      SLVEP%SLV = SLVK%SLV
      SLVK%PRECON    = MOTINT( ADRESS(1,26) )
      SLVEP%PRECON = SLVK%PRECON
      LISRUG    = MOTINT( ADRESS(1,27) )
      NFLOT_MAX = MOTINT( ADRESS(1,28) )
      FLOPRD    = MOTINT( ADRESS(1,29) )
      NLAG      = MOTINT( ADRESS(1,30) )
      LISFON    = MOTINT( ADRESS(1,31) )
      SLVPRO%KRYLOV = MOTINT( ADRESS(1,33) )
      SLVK%KRYLOV = MOTINT( ADRESS(1,34) )
      SLVEP%KRYLOV = SLVK%KRYLOV
      OPTBAN    = MOTINT( ADRESS(1,35) )
      LVMAC     = MOTINT( ADRESS(1,36) )
      IF(DIMEN(1,37).NE.0) THEN
        DO K=1,DIMEN(1,37)
          OPTSUP(K) = MOTINT( ADRESS(1,37) + K-1 )
        ENDDO ! K
      ENDIF
      IORDRU       = MOTINT( ADRESS(1,38) )
      START_RECORD = MOTINT( ADRESS(1,39) )
      OPTASS       = MOTINT( ADRESS(1,40) )
      MARDAT(1)    = MOTINT( ADRESS(1,41) )
      MARDAT(2)    = MOTINT( ADRESS(1,41) + 1 )
      MARDAT(3)    = MOTINT( ADRESS(1,41) + 2 )
      MARTIM(1)    = MOTINT( ADRESS(1,42) )
      MARTIM(2)    = MOTINT( ADRESS(1,42) + 1 )
      MARTIM(3)    = MOTINT( ADRESS(1,42) + 2 )
      PRODUC       = MOTINT( ADRESS(1,43) )
      NCP=DIMEN(1,44)
      ALLOCATE(CTRLSC(NCP),STAT=ERR)
!
      IF(ERR.NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,1039) ERR
        IF(LNG.EQ.2) WRITE(LU,2039) ERR
1039    FORMAT(1X,'LECDON : ERREUR A L''ALLOCATION DE CTRLSC : ',/,1X,
     &            'CODE D''ERREUR : ',1I6)
2039    FORMAT(1X,'LECDON: ERROR DURING ALLOCATION OF CTRLSC: ',/,1X,
     &            'ERROR CODE: ',1I6)
      ENDIF
      IF(NCP.NE.0) THEN
        DO K=1,NCP
          CTRLSC(K) = MOTINT( ADRESS(1,44) + K-1 )
        ENDDO
      ENDIF
      NWEIRS    = MOTINT( ADRESS(1,45) )
      NSIPH     = MOTINT( ADRESS(1,46) )
      NBUSE     = MOTINT( ADRESS(1, 6) )
      NTYPFR = DIMEN(1,47)
      THOMFR=.FALSE.
      IF(NTYPFR.NE.0) THEN
        DO K=1,NTYPFR
          FRTYPE(K) = MOTINT( ADRESS(1,47) + K-1 )
          IF(FRTYPE(K).EQ.2) THOMFR=.TRUE.
        ENDDO
      ENDIF
      SOLSYS    = MOTINT( ADRESS(1,48) )
!
!     NUMBER OF PROCESSORS (ALREADY IN INIT_FILES2; MUST BE THE
!     SAME, BUT IT CAN (ERRONEOUSLY) BE DIFFERENT WHEN COUPLING).
      IF(NCSIZE.NE.MOTINT(ADRESS(1,49))) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'NOMBRE DE PROCESSEURS PARALLELES DIFFERENT :'
          WRITE(LU,*) 'DEJA DECLARE (CAS DE COUPLAGE ?) :',NCSIZE
          WRITE(LU,*) 'TELEMAC-2D :',MOTINT(ADRESS(1,49))
          WRITE(LU,*) 'LA VALEUR ',NCSIZE,' EST GARDEE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'DIFFERENT NUMBER OF PARALLEL PROCESSORS:'
          WRITE(LU,*) 'DECLARED BEFORE (CASE OF COUPLING ?):',NCSIZE
          WRITE(LU,*) 'TELEMAC-2D :',MOTINT(ADRESS(1,49))
          WRITE(LU,*) 'VALUE ',NCSIZE,' IS KEPT'
        ENDIF
      ENDIF
      IF(DIMEN(1,50).NE.0) THEN
        DO K=1,DIMEN(1,50)
          PROVEL(K) = MOTINT( ADRESS(1,50) + K-1 )
        ENDDO
      ENDIF
      OPDTRA    = MOTINT( ADRESS(1,51) )
      OPDVIT    = MOTINT( ADRESS(1,52) )
      OPTSOU    = MOTINT( ADRESS(1,53) )
      NPRIV     = MOTINT( ADRESS(1,54) )
!     CHANGE OF LANGUAGE: DOES NOT WORK IN THE EVENT OF CONTINUATION, INVESTIGATE
!     LNG       = MOTINT (ADRESS (1,55))
      NPTH      = MOTINT( ADRESS(1,56) )
!     OPTION FOR THE IDENTIFICATION OF PARAMETERS
      OPTID     = MOTINT( ADRESS(1,57) )
      NPTS      = DIMEN(1,58)
      IF(NPTS.GT.0) THEN
        DO K=1,NPTS
          LIST_PTS(K) = MOTINT( ADRESS(1,58) + K-1 )
          NAME_PTS(K)=' '
        ENDDO
      ENDIF
      OPTCOST= MOTINT( ADRESS(1,59) )
      MAXEST = MOTINT( ADRESS(1,60) )
!     COUPLING PERIOD
      PERCOU = MOTINT( ADRESS(1,61) )
!     FINITE VOLUME SCHEME
      OPTVF  = MOTINT( ADRESS(1,62) )
!     MAX NUMBER OF ZONES TO DEFINE FRICTION COEFF.
      NZONMX = MOTINT( ADRESS(1,63) )
!     COORDINATES OF THE ORIGIN
      I_ORIG = MOTINT( ADRESS(1,65)   )
      J_ORIG = MOTINT( ADRESS(1,65)+1 )
!     DELWAQ PRINTOUT PERIOD
      WAQPRD = MOTINT( ADRESS(1,66)   )
!     NUMBER OF TRACERS
      NTRAC  = MOTINT( ADRESS(1,67)   )
!     ADD THE TRACERS OF WAQ  AND SECONDARY CURRENT
      NTRAC = NTRAC + ADDTR
!
!     PREVIOUS KEYWORDS DEPENDING ON NTRAC
!
      IF(NTRAC.GT.0) THEN
!       FIRST ASSUMING A SINGLE VALUE
        DO ITRAC=1,NTRAC
          SLVTRA(ITRAC)%NITMAX = MOTINT( ADRESS(1, 9) )
          SLVTRA(ITRAC)%SLV    = MOTINT( ADRESS(1,11) )
          SLVTRA(ITRAC)%PRECON = MOTINT( ADRESS(1,24) )
          SLVTRA(ITRAC)%KRYLOV = MOTINT( ADRESS(1,32) )
        ENDDO
!       MULTIPLE VALUES MAY BE GIVEN (AND A FEW LAST MAY BE FORGOTTEN)
        DO ITRAC=1,DIMEN(1,9)
          SLVTRA(ITRAC)%NITMAX = MOTINT( ADRESS(1,9)+ITRAC-1 )
        ENDDO
        DO ITRAC=1,DIMEN(1,11)
          SLVTRA(ITRAC)%SLV    = MOTINT( ADRESS(1,11)+ITRAC-1 )
        ENDDO
        DO ITRAC=1,DIMEN(1,24)
          SLVTRA(ITRAC)%PRECON = MOTINT( ADRESS(1,24)+ITRAC-1 )
        ENDDO
        DO ITRAC=1,DIMEN(1,32)
          SLVTRA(ITRAC)%KRYLOV = MOTINT( ADRESS(1,32)+ITRAC-1 )
        ENDDO
      ENDIF
!
!     END OF PREVIOUS KEYWORDS DEPENDING ON NTRAC
!
!     STAGE-DISCHARGE CURVES
      IF(DIMEN(1,68).NE.0) THEN
        DO K=1,DIMEN(1,68)
          STA_DIS_CURVES(K) = MOTINT( ADRESS(1,68) + K-1 )
        ENDDO
      ENDIF
!     DEBUGGER KEYWORD
      DEBUG  = MOTINT(ADRESS(1,69))
!     NEGATIVE DEPTHS OPTION
      OPT_HNEG = MOTINT(ADRESS(1,70))
!     DEPTH IN FRICTION TERMS
      HFROT = MOTINT(ADRESS(1,71))
!     LAW OF FRICTION ON LATERAL BOUNDARIES
      KFROTL     = MOTINT(ADRESS(1,72))
!     COUPLING PERIOD FOR TOMAWAC
      PERCOU_WAC = MOTINT(ADRESS(1,73))
!     TREATMENT OF FLUXES AT THE BOUNDARIES
      DIRFLU     = MOTINT(ADRESS(1,74))
!     OPTION FOR TIDAL BOUNDARY CONDITIONS
      TIDALTYPE  = MOTINT(ADRESS(1,75))
!     OPTION FOR TSUNAMI GENERATION
      OPTTSUNAMI = MOTINT(ADRESS(1,76))
!     INPUT TIDAL DATA BASE
      TIDALDB = MOTINT(ADRESS(1,77))
!     GEOGRAPHIC SYSTEM IN WHICH THE NUMERICAL MODEL IS BUILT (TIDAL MODEL)
      GEOSYST = MOTINT(ADRESS(1,78))
!     ZONE NUMBER WHEN USING A PLANE PROJECTION,
!     ASSOCIATED TO GEOGRAPHIC SYSTEM (TIDAL MODEL)
      NUMZONE = MOTINT(ADRESS(1,79))
!     LAW OF TRACERS DEGRADATION
      IF(NTRAC.GT.0) THEN
        DO I=1,NTRAC
          LOITRAC(I) = 0
        ENDDO
        IF(TROUVE(1,80).EQ.2) THEN
          DO I=1,DIMEN(1,80)
            LOITRAC(I) = MOTINT(ADRESS(1,80)+I-1)
          ENDDO
        ENDIF
      ENDIF
!     SPATIAL PROJECTION TYPE
      PROTYP = MOTINT(ADRESS(1,81))
!     ALGAE TYPE
      ALGTYP = MOTINT(ADRESS(1,82))
!     OPTION FOR CHARACTERISTICS
      OPTCHA = MOTINT(ADRESS(1,83))
!     MAXIMUM NUMBER OF ITERATIONS FOR ADVECTION SCHEMES
      MAXADV = MOTINT(ADRESS(1,84))
!     STOCHASTIC DIFFUSION MODEL
      STOCHA = MOTINT(ADRESS(1,85))
!     NUMBER OF GAUSS POINTS FOR CHARACTERISTICS
      NGAUSS = MOTINT(ADRESS(1,86))
!
!     OPTION FOR WEIR TREATMENT
      TYPSEUIL = MOTINT(ADRESS(1,87))
!
!     NEW KEYWORDS REPLACING TYPE OF ADVECTION
!
      IF(TROUVE(1,88).EQ.2) THEN
        ICONVF(1) = MOTINT(ADRESS(1,88))
      ENDIF
      IF(NTRAC.GT.0) THEN
        DO ITRAC=1,NTRAC
          ICONVFT(ITRAC)=ICONVF(3)
        ENDDO
        IF(TROUVE(1,89).EQ.2) THEN
          DO ITRAC=1,DIMEN(1,89)
            ICONVFT(ITRAC)=MOTINT(ADRESS(1,89)+ITRAC-1)
          ENDDO
        ENDIF
      ENDIF
      IF(TROUVE(1,90).EQ.2) THEN
        ICONVF(4) = MOTINT(ADRESS(1,90))
      ENDIF
!
!     OPTION FOR WIND MANAGEMENT
      OPTWIND = MOTINT(ADRESS(1,94))
!     AVOID NON LOGICAL CASE (WIND=YES AND OPTWIND=0)
      IF(VENT.AND.OPTWIND.EQ.0)THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) ' INCONSISTANCE DANS LA GESTION DU VENT'
          WRITE(LU,*) ' VENT ACTIVE ET OPTION DU VENT = 0'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) ' UNCOHERENT CHOICES FOR WIND MANAGEMENT'
          WRITE(LU,*) ' WIND ACTIVATED AND OPTION FOR WIND = 0'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF     
!
! REAL KEYWORDS:
!
      DT           = MOTREA( ADRESS(2, 1) )
      GRAV         = MOTREA( ADRESS(2, 2) )
      SLVPRO%ZERO  = MOTREA( ADRESS(2, 3) )
      SLVK%ZERO    = SLVPRO%ZERO
      SLVEP%ZERO   = SLVPRO%ZERO
      FFON      = MOTREA( ADRESS(2, 4) )
      FCOR      = MOTREA( ADRESS(2, 5) )
      FAIR      = MOTREA( ADRESS(2, 6) )
      FUAIR     = MOTREA( ADRESS(2, 7) )
      FVAIR     = MOTREA( ADRESS(2, 8) )
      IF(NTRAC.GT.0) THEN
        DO K=1,NTRAC
          TRAC0(K)=0.D0
          IF(DIMEN(2,9).GE.K) THEN
            TRAC0(K) = MOTREA( ADRESS(2, 9) +K-1)
          ELSE
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'LA VALEUR INITIALE DU TRACEUR ',K
              WRITE(LU,*) 'N''EST PAS DONNEE, ELLE EST MISE A 0.D0'
            ENDIF
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'THE INITIAL VALUE OF TRACER ',K
              WRITE(LU,*) 'IS NOT GIVEN, IT IS SET TO 0.D0'
            ENDIF
          ENDIF
        ENDDO
      ENDIF
      DIFNU     = MOTREA( ADRESS(2,10) )         
      IF(NTRAC.GT.0) THEN
        DO ITRAC=1,NTRAC
          SLVTRA(ITRAC)%ZERO = SLVPRO%ZERO
          SLVTRA(ITRAC)%EPS  = MOTREA( ADRESS(2,11) )
        ENDDO
      ENDIF
      TETAT     = MOTREA( ADRESS(2,12) )
      PROPNU    = MOTREA( ADRESS(2,13) )
      SLVPRO%EPS= MOTREA( ADRESS(2,14) )
      IF(DIMEN(2,15).NE.0) THEN
        DO K=1,DIMEN(2,15)
          BORNES(K) = MOTREA( ADRESS(2,15) + K-1 )
        ENDDO
      ENDIF
      HREC      = MOTREA( ADRESS(2,16) )
      TETAC     = MOTREA( ADRESS(2,17) )
      TETAU     = MOTREA( ADRESS(2,18) )
      TETAD     = MOTREA( ADRESS(2,19) )
      AGGLOC    = MOTREA( ADRESS(2,20) )
      AGGLOU    = MOTREA( ADRESS(2,21) )
      HMIN      = MOTREA( ADRESS(2,22) )
      REDUC     = MOTREA( ADRESS(2,23) )
      SLVK%EPS  = MOTREA( ADRESS(2,24) )
      SLVEP%EPS = MOTREA( ADRESS(2,25) )
      HAULIN    = MOTREA( ADRESS(2,26) )
      ROEAU     = MOTREA( ADRESS(2,27) )
      LAMBD0    = MOTREA( ADRESS(2,28) )
      SB        = MOTREA( ADRESS(2,29) )
      COTINI    = MOTREA( ADRESS(2,33) )
      HAUTIN    = MOTREA( ADRESS(2,34) )
!
!  ARRAYS OF REALS
!
      NDEBIT = DIMEN(2,30)
      IF(NDEBIT.NE.0) THEN
        DO K=1,NDEBIT
          DEBIT(K) = MOTREA( ADRESS(2,30) + K-1 )
        ENDDO
      ENDIF
      NCOTE  = DIMEN(2,31)
      IF(NCOTE.NE.0) THEN
        DO K=1,NCOTE
          COTE(K) = MOTREA( ADRESS(2,31) + K-1 )
        ENDDO
      ENDIF
      NVITES = DIMEN(2,32)
      IF(NVITES.NE.0) THEN
        DO K=1,NVITES
          VITES(K) = MOTREA( ADRESS(2,32) + K-1 )
        ENDDO
      ENDIF
      NTRACE = DIMEN(2,35)
      IF(NTRACE.NE.0) THEN
        DO K=1,NTRACE
          TRACER(K)=MOTREA(ADRESS(2,35)+K-1)
        ENDDO
      ENDIF
      NREJET = DIMEN(2,38)
      IF(NREJET.NE.0) THEN
        DO K=1,NREJET
          DSCE(K) = MOTREA( ADRESS(2,38) + K-1 )
        ENDDO
      ENDIF
      NREJEX = DIMEN(2,36)
      IF(NREJEX.EQ.NREJET) THEN
        DO K=1,NREJEX
          XSCE(K) = MOTREA( ADRESS(2,36) + K-1 )
        ENDDO
      ELSE
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) NREJET,' ABSCISSES DES SOURCES ATTENDUES'
          WRITE(LU,*) NREJEX,' TROUVEES'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) NREJET,' ABSCISSAE OF SOURCES EXPECTED'
          WRITE(LU,*) NREJEX,' FOUND'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
      NREJEY = DIMEN(2,37)
      IF(NREJEY.EQ.NREJET) THEN
        DO K=1,NREJEY
          YSCE(K) = MOTREA( ADRESS(2,37) + K-1 )
        ENDDO
      ELSE
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) NREJET,' ABSCISSES DES SOURCES ATTENDUES'
          WRITE(LU,*) NREJEY,' TROUVEES'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) NREJET,' ABSCISSAE OF SOURCES EXPECTED'
          WRITE(LU,*) NREJEY,' FOUND'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
      NREJTR = DIMEN(2,39)
      IF(NREJTR.EQ.NTRAC*NREJET) THEN
        IF(NTRAC.GT.0) THEN
          DO ITRAC=1,NTRAC
          DO K=1,NREJET
            TSCE(K,ITRAC)=MOTREA(ADRESS(2,39)+(K-1)*NTRAC+ITRAC-1)
          ENDDO
          ENDDO
        ENDIF
      ELSE
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) NREJET*NTRAC,
     &    ' VALEURS DES TRACEURS DES SOURCES ATTENDUES'
          WRITE(LU,*) NREJTR,' TROUVEES'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) NREJET*NTRAC,
     &    ' VALUES OF THE TRACERS AT THE SOURCES EXPECTED'
          WRITE(LU,*) NREJTR,' FOUND'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
      NCOSUP = DIMEN(2,40)
      IF(NCOSUP.NE.0) THEN
        DO K=1,NCOSUP
          COSUPG(K) = MOTREA( ADRESS(2,40) + K-1 )
        ENDDO
      ENDIF
      NCRITE = DIMEN(2,41)
      IF(NCRITE.NE.0) THEN
        DO K=1,NCRITE
          CRIPER(K) = MOTREA( ADRESS(2,41) + K-1 )
        ENDDO
      ENDIF
      TMOY = MOTREA( ADRESS(2,42) )
      NREJEU = DIMEN(2,43)
      IF(NREJEU.NE.0) THEN
        DO K=1,NREJEU
          USCE(K) = MOTREA( ADRESS(2,43) + K-1 )
        ENDDO
      ENDIF
      NREJEV = DIMEN(2,44)
      IF(NREJEV.NE.0) THEN
        DO K=1,NREJEV
          VSCE(K) = MOTREA( ADRESS(2,44) + K-1 )
        ENDDO
      ENDIF
      DUREE = MOTREA( ADRESS(2,45) )
      NORD  = MOTREA( ADRESS(2,46) )
      ELDER(1) = MOTREA( ADRESS(2,47)     )
      ELDER(2) = MOTREA( ADRESS(2,47) + 1 )
      PHI0     = MOTREA( ADRESS(2,48) )
!     TRACER MASS CONSERVATION WANTS AGGLOT=AGGLOC
!     AGGLOT   = MOTREA( ADRESS(2,49) )
      AGGLOT   = AGGLOC
      CFLWTD   = MOTREA( ADRESS(2,50) )
      NPERIAF   = DIMEN(2,51)
      IF(NPERIAF.GT.0) THEN
        DO K=1,MAX(NPERIAF,50)
          PERIAF(K) = MOTREA( ADRESS(2,51) + K-1 )
        ENDDO
      ENDIF
      DO K=1,4
        TOLEST(K) = MOTREA( ADRESS(2,52) + K-1 )
      ENDDO
      NDEF     = MOTREA( ADRESS(2,53) )
      DP       = MOTREA( ADRESS(2,54) )
      SP       = MOTREA( ADRESS(2,55) )
      HWIND    = MOTREA( ADRESS(2,56) )
      HNEG     = MOTREA( ADRESS(2,57) )
      TETAZCOMP= MOTREA( ADRESS(2,58) )
      TAFBGN   = MOTREA( ADRESS(2,59) )
      TAFEND   = MOTREA( ADRESS(2,59)+1 )
      GAMMA    = MOTREA( ADRESS(2,60) )
      RAIN_MMPD= MOTREA( ADRESS(2,61) )
!     PHYSICAL CHARACTERISTICS OF THE TSUNAMI
      DO K = 1,10
        COETSUNAMI(K) = MOTREA( ADRESS(2,62) + K-1 )
      ENDDO
!
!     VALUES OF TRACERS IN THE RAIN
!
      IF(NTRAC.GT.0) THEN
        DO I=1,NTRAC
          TRAIN(I) = 0.D0
        ENDDO
        IF(TROUVE(2,63).EQ.2) THEN
          DO I=1,DIMEN(2,63)
            TRAIN(I) = MOTREA(ADRESS(2,63)+I-1)
          ENDDO
        ENDIF
      ENDIF
!     COEFFICIENT TO CALIBRATE TIDAL RANGE
      CTIDE    = MOTREA( ADRESS(2,64) )
!     COEFFICIENT TO CALIBRATE TIDAL VELOCITIES
      CTIDEV   = MOTREA( ADRESS(2,65) )
!     COEFFICIENT TO CALIBRATE SEA LEVEL (TIDAL MODEL)
      MSL      = MOTREA( ADRESS(2,66) )
!     COEFFICIENT 1 FOR LAW OF TRACERS DEGRADATION
      IF(NTRAC.GT.0) THEN
        DO I=1,NTRAC
          COEF1TRAC(I) = 0.D0
        ENDDO
        IF(TROUVE(2,67).EQ.2) THEN
          DO I=1,DIMEN(2,67)
            COEF1TRAC(I) = MOTREA(ADRESS(2,67)+I-1)
          ENDDO
        ENDIF
      ENDIF
!     DIAMETRE OF ALGAE
      DALGAE   = MOTREA( ADRESS(2,68) )
!     DENSITY OF ALGAE
      RALGAE   = MOTREA( ADRESS(2,69) )
!     THICKNESS OF ALGAE
      EALGAE   = MOTREA( ADRESS(2,70) )
!     MASS-LUMPING FOR WEAK CHARACTERISTICS
      AGGLOW   = MOTREA( ADRESS(2,71) )
!     SPEED AND DIRECTION OF WIND
      WIND_SPD(1)   = MOTREA( ADRESS(2,72)   )
      WIND_SPD(2)   = MOTREA( ADRESS(2,72)+1 )
!
!     VALUE OF THE ATMOSPHERIC PRESSURE
      PATMOS_VALUE  = MOTREA( ADRESS(2,73)   )
!     FOR SECONDARY CURRENTS
      SEC_AS     = MOTREA( ADRESS(2, 74) )
      SEC_DS     = MOTREA( ADRESS(2, 75) )
!
! LOGICAL KEYWORDS:
!
      IF(MOTLOG( ADRESS(3,1) )) THEN
        DEBU = .FALSE.
      ELSE
        DEBU = .TRUE.
      ENDIF
!     BREACHES
      BRECHE    = MOTLOG( ADRESS(3, 2) )
      LISTIN    = MOTLOG( ADRESS(3, 3) )
      DIFVIT    = MOTLOG( ADRESS(3, 4) )
      ATMOS     = MOTLOG( ADRESS(3, 5) )
      CONV      = MOTLOG( ADRESS(3, 6) )
      CONVV(1)  = MOTLOG( ADRESS(3, 7) )
      CONVV(2)  = MOTLOG( ADRESS(3, 8) )
      CONVV(3)  = MOTLOG( ADRESS(3, 9) )
      CONVV(4)  = MOTLOG( ADRESS(3,10) )
      DIFT      = MOTLOG( ADRESS(3,11) )
      PROPA     = MOTLOG( ADRESS(3,12) )
      CORIOL    = MOTLOG( ADRESS(3,13) )
      VENT      = MOTLOG( ADRESS(3,14) )
      INFOGR    = MOTLOG( ADRESS(3,15) )
      BILMAS    = MOTLOG( ADRESS(3,16) )
      CLIPH     = MOTLOG( ADRESS(3,17) )
      SPHERI    = MOTLOG( ADRESS(3,18) )
      RAIN      = MOTLOG( ADRESS(3,19) )
      PROLIN    = MOTLOG( ADRESS(3,20) )
      VALID     = MOTLOG( ADRESS(3,21) )
      INFOKE    = MOTLOG( ADRESS(3,22) )
      VERLIM    = MOTLOG( ADRESS(3,23) )
      BANDEC    = MOTLOG( ADRESS(3,24) )
      STOPER    = MOTLOG( ADRESS(3,25) )
      MSKUSE    = MOTLOG( ADRESS(3,26) )
      ROVAR     = MOTLOG( ADRESS(3,27) )
      MAREE     = MOTLOG( ADRESS(3,28) )
      CORCON    = MOTLOG( ADRESS(3,29) )
      RAZTIM    = MOTLOG( ADRESS(3,30) )
      PRECCU    = MOTLOG( ADRESS(3,31) )
      DTVARI    = MOTLOG( ADRESS(3,32) )
      COUROU    = MOTLOG( ADRESS(3,33) )
      VERTIC    = MOTLOG( ADRESS(3,34) )
      OUTINI    = MOTLOG( ADRESS(3,35) )
      DEFZON    = MOTLOG( ADRESS(3,36) )
      FRICTB    = MOTLOG( ADRESS(3,37) )
      LINDNER   = MOTLOG( ADRESS(3,38) )
      CUMFLO    = MOTLOG( ADRESS(3,39) )
      COMFLU    = MOTLOG( ADRESS(3,40) )
!     SALINITY AND TEMPERATURE OUTPUT FOR DELWAQ
      SALI_DEL  = MOTLOG( ADRESS(3,41) )
      TEMP_DEL  = MOTLOG( ADRESS(3,42) )
      VELO_DEL  = MOTLOG( ADRESS(3,43) )
      DIFF_DEL  = MOTLOG( ADRESS(3,44) )
!     OIL SPILL MODEL
      SPILL_MODEL  = MOTLOG( ADRESS(3,45) )
!     INFERENCE OF MINOR CONSTITUENTS OF TPXO TIDAL DATABASE
      INTMICON  = MOTLOG( ADRESS(3,46) )
!     ALGAE TRANSPORT MODEL
      ALGAE     = MOTLOG( ADRESS(3,47) )
!     SECONDARY CURRENTS (DONE IN THE UPPER PART OR LECDON)
!     SECCURRENTS = MOTLOG(ADRESS(3,49))
!     WAVE ENHANCED FRICTION
      FRICOU    = MOTLOG( ADRESS(3,50) )
!
      IF(.NOT.DEFZON) NZONE=0
!
!     CHARACTER STRING KEYWORDS : SOME ARE USED BY THE LAUNCHING
!                             PROCEDURE
!
      TITCAS    = MOTCAR( ADRESS(4, 1) )(1:72)
      VARDES    = MOTCAR( ADRESS(4, 2) )(1:72)
      CALL MAJUS(VARDES)
      VARIMP    = MOTCAR( ADRESS(4, 3) )(1:72)
      CALL MAJUS(VARIMP)
!     FROM 4 TO 5 : READ AND USED BY THE LAUNCHING PROCEDURE
!     NOMGEO    = MOTCAR( ADRESS(4, 6) )
      T2D_FILES(T2DGEO)%NAME=MOTCAR( ADRESS(4, 6) )
!     NOMFOR    = MOTCAR( ADRESS(4, 7) )
!     NOMCAS    = MOTCAR( ADRESS(4, 8) )
      T2D_FILES(T2DCLI)%NAME=MOTCAR( ADRESS(4, 9) )
      T2D_FILES(T2DPRE)%NAME=MOTCAR( ADRESS(4,10) )
      T2D_FILES(T2DRES)%NAME=MOTCAR( ADRESS(4,11) )
!     FROM 12 TO 14 : READ AND USED BY THE LAUNCHING PROCEDURE
      T2D_FILES(T2DFON)%NAME=MOTCAR( ADRESS(4,15) )
!     16 : ACCOUNT NUMBER (NOT KEPT)
      T2D_FILES(T2DBI1)%NAME=MOTCAR( ADRESS(4,17) )
      T2D_FILES(T2DBI2)%NAME=MOTCAR( ADRESS(4,18) )
      T2D_FILES(T2DFO1)%NAME=MOTCAR( ADRESS(4,19) )
      T2D_FILES(T2DFO2)%NAME=MOTCAR( ADRESS(4,20) )
!     FROM 21 TO 22 : READ AND USED BY THE LAUNCHING PROCEDURE
      NVARCL = DIMEN(4,23)
      IF(NVARCL.NE.0) THEN
        DO K=1,NVARCL
          VARCLA(K) = MOTCAR( ADRESS(4,23) + K-1 )(1:32)
          CALL MAJUS(VARCLA(K))
        ENDDO
      ENDIF
!     NOMRBI    = MOTCAR( ADRESS(4,24) )
      T2D_FILES(T2DRBI)%NAME=MOTCAR( ADRESS(4,24) )
!     NOMRFO    = MOTCAR( ADRESS(4,25) )
      T2D_FILES(T2DRFO)%NAME=MOTCAR( ADRESS(4,25) )
      CDTINI    = MOTCAR( ADRESS(4,26) )(1:72)
      CALL MAJUS(CDTINI)
!     GEOMETRY FILE FORMAT
      T2D_FILES(T2DGEO)%FMT = MOTCAR( ADRESS(4,27) )(1:8)
      CALL MAJUS(T2D_FILES(T2DGEO)%FMT)
!     RESULTS FILE FORMAT
      T2D_FILES(T2DRES)%FMT = MOTCAR( ADRESS(4,28) )(1:8)
      CALL MAJUS(T2D_FILES(T2DRES)%FMT)
!     PREVIOUS COMPUTATION FILE FORMAT
      T2D_FILES(T2DPRE)%FMT = MOTCAR( ADRESS(4,29) )(1:8)
      CALL MAJUS(T2D_FILES(T2DPRE)%FMT)
!     FROM 30 TO 33 : READ AND USED BY THE LAUNCHING PROCEDURE
!                30 : LIBRARIES
!                31 : PRIORITY
!                32 : PVM LIBRARY
!                33 : CALCIUM 1 LIBRARY
!                34 : CALCIUM 2 LIBRARY
!                35 : CRAY NAME
      EQUA      = MOTCAR( ADRESS(4,36) )(1:20)
      CALL MAJUS(EQUA)
!     NOMREF    = MOTCAR( ADRESS(4,37) )
      T2D_FILES(T2DREF)%NAME=MOTCAR( ADRESS(4,37) )
!     NOMIMP    = MOTCAR( ADRESS(4,38) )
      T2D_FILES(T2DIMP)%NAME=MOTCAR( ADRESS(4,38) )
!     DOSSIER_COUPLAGE = MOTCAR( ADRESS(4,39) )
      COUPLING  = MOTCAR( ADRESS(4,40) )
      CALL MAJUS(COUPLING)
!
!     FROM 41 TO 58 : "DESCRIPTION OF" KEYWORDS
!
!     ZONES FILE
      T2D_FILES(T2DZFI)%NAME=MOTCAR( ADRESS(4,59) )
!
      ESTIME  = MOTCAR( ADRESS(4,60) )(1:72)
      CALL MAJUS(ESTIME)
      IF(ESTIME.EQ.' ') ADJO=.FALSE.
      I         = DIMEN(4,61)
      IF(I.GT.0) THEN
        DO K=1,I
          NAME_PTS(K)=MOTCAR(ADRESS(4,61)+K-1)(1:32)
        ENDDO
      ENDIF
!     62 : SISYPHE STEERING FILE (READ BY PERL SCRIPTS)
!
!     63 : FRICTION DATA FILE
!     NOMCOF=MOTCAR( ADRESS(4,63))
      T2D_FILES(T2DCOF)%NAME=MOTCAR( ADRESS(4,63) )
!     64-72 : DELWAQ FILES
!     NOMSOU=MOTCAR( ADRESS(4,64) )
      T2D_FILES(T2DDL1)%NAME=MOTCAR( ADRESS(4,64) )
!     NOSUIS=MOTCAR( ADRESS(4,65) )
      T2D_FILES(T2DDL2)%NAME=MOTCAR( ADRESS(4,65) )
!     NOMCOU=MOTCAR( ADRESS(4,66) )
      T2D_FILES(T2DDL3)%NAME=MOTCAR( ADRESS(4,66) )
!     NOMFRC=MOTCAR( ADRESS(4,67) )
      T2D_FILES(T2DDL4)%NAME=MOTCAR( ADRESS(4,67) )
!     NOMINI=MOTCAR( ADRESS(4,68) )
      T2D_FILES(T2DDL5)%NAME=MOTCAR( ADRESS(4,68) )
!     NOMVEB=MOTCAR( ADRESS(4,69) )
      T2D_FILES(T2DDL6)%NAME=MOTCAR( ADRESS(4,69) )
!     NORSED=MOTCAR( ADRESS(4,70) )
      T2D_FILES(T2DDL7)%NAME=MOTCAR( ADRESS(4,70) )
!     NOMCOB=MOTCAR( ADRESS(4,71) )
      T2D_FILES(T2DL11)%NAME=MOTCAR( ADRESS(4,71) )
!     NOMSCO=MOTCAR( ADRESS(4,72) )
      T2D_FILES(T2DDL8)%NAME=MOTCAR( ADRESS(4,72) )
!     NOMPAR=MOTCAR( ADRESS(4,76) )
      T2D_FILES(T2DDL9)%NAME=MOTCAR( ADRESS(4,76) )
!     NOMPRI=MOTCAR( ADRESS(4,77) )
      T2D_FILES(T2DL10)%NAME=MOTCAR( ADRESS(4,77) )
!     STAGE-DISCHARGE CURVES FILE
!     NOMMAB=MOTCAR( ADRESS(4,73) )
      T2D_FILES(T2DMAB)%NAME=MOTCAR( ADRESS(4,73) )
!     INITIALISES AND READS THE NAMES OF TRACERS
      IF(NTRAC.GT.0) THEN
        DO I=1,NTRAC
          IF(LNG.EQ.1) THEN
           NAMETRAC(I) =  'TRACEUR '//I_IN_2_LETTERS(I)//'      '
     &                   // '??              '
          ELSEIF(LNG.EQ.2) THEN
           NAMETRAC(I) =  'TRACER '//I_IN_2_LETTERS(I)//'       '
     &                   // '??              '
          ENDIF
        ENDDO
      ENDIF
      NTRTOT=DIMEN(4,74)
      IF(NTRTOT.GT.0.AND.NTRAC.GT.0) THEN
        DO I=1,NTRTOT
          NAMETRAC(I) = MOTCAR(ADRESS(4,74)+I-1)(1:32)
        ENDDO
      ENDIF
!     CHANES DUE TO WAQ
      IF(WATQUA.OR.SECCURRENTS)THEN
!       GIVE THEM THEIR NAMES
        CALL NAMETRAC_WAQ(NAMETRAC,WATQUA,SECCURRENTS,
     &                    WAQPROCESS,NTRAC-ADDTR,IND_SEC)
      ENDIF   
!     SOURCES FILE
      T2D_FILES(T2DVEF)%NAME=MOTCAR( ADRESS(4,75) )
!     76 AND 77 IN DELWAQ FILES ABOVE
!     REFERENCE FILE FORMAT
      T2D_FILES(T2DREF)%FMT = MOTCAR( ADRESS(4,78) )(1:8)
      CALL MAJUS(T2D_FILES(T2DREF)%FMT)
!     SECTIONS INPUT FILE
      T2D_FILES(T2DSEC)%NAME=MOTCAR( ADRESS(4,79) )
!     SECTIONS OUTPUT FILE
      T2D_FILES(T2DSEO)%NAME=MOTCAR( ADRESS(4,80) )
!     MIGRHYCAR STEERING FILE
      T2D_FILES(T2DMIG)%NAME=MOTCAR( ADRESS(4,81) )
!     82 : TOMAWAC STEERING FILE (READ BY PERL SCRIPTS)
!
!     HARMONIC CONSTANTS FILE
      T2D_FILES(T2DHAR)%NAME=MOTCAR( ADRESS(4,83) )
!     TIDAL MODEL FILE
      T2D_FILES(T2DTID)%NAME=MOTCAR( ADRESS(4,84) )
!     TIDE DATA BASE FILE
      T2D_FILES(T2DBDD)%NAME=MOTCAR( ADRESS(4,85) )
!     BINARY TIDE DATABASE FILE 1 (FOR SATELLITE ALTIMETRY)
      T2D_FILES(T2DBB1)%NAME=MOTCAR( ADRESS(4,86) )
!     BINARY TIDE DATABASE FILE 2 (FOR SATELLITE ALTIMETRY)
      T2D_FILES(T2DBB2)%NAME=MOTCAR( ADRESS(4,87) )
!     WEIRS DATA FILE
      T2D_FILES(T2DSEU)%NAME=MOTCAR( ADRESS(4,88) )
!     CULVERT DATA FILE
      T2D_FILES(T2DSIP)%NAME=MOTCAR( ADRESS(4,89) )
!     BUSES/BRIDGES DATA FILE
      T2D_FILES(T2DBUS)%NAME=MOTCAR( ADRESS(4,90) )
!     BREACHES DATA FILE
      T2D_FILES(T2DBRC)%NAME=MOTCAR( ADRESS(4,91) )
!     DROGUES FILE
      T2D_FILES(T2DFLO)%NAME=MOTCAR( ADRESS(4,92) )
!     WATER QUALITY
!
!     WAQ STEERING FILE
      T2D_FILES(T2DWAQ)%NAME=MOTCAR( ADRESS(4,93) )
!     WAQ DICTIONARY
      T2D_FILES(T2DWQD)%NAME=MOTCAR( ADRESS(4,94) )

      IF(LISTIN) THEN
        IF(LNG.EQ.1) WRITE(LU,1000)
        IF(LNG.EQ.2) WRITE(LU,1001)
      ENDIF
1000  FORMAT(1X,/,19X, '********************************************',/,
     &            19X, '*               LECDON:                    *',/,
     &            19X, '*        APRES APPEL DE DAMOCLES           *',/,
     &            19X, '*     VERIFICATION DES DONNEES LUES        *',/,
     &            19X, '*     SUR LE FICHIER DES PARAMETRES        *',/,
     &            19X, '********************************************',/)
1001  FORMAT(1X,/,19X, '********************************************',/,
     &            19X, '*               LECDON:                    *',/,
     &            19X, '*        AFTER CALLING DAMOCLES            *',/,
     &            19X, '*        CHECKING OF DATA  READ            *',/,
     &            19X, '*         IN THE STEERING FILE             *',/,
     &            19X, '********************************************',/)
!
!-----------------------------------------------------------------------
!  CORRECTS AND COMPUTES OTHER VARIABLES THAT CAN BE DEDUCTED
!  FROM THE ONES JUST READ
!-----------------------------------------------------------------------
!
!  ADVECTION VARIABLES :
!
      IF (.NOT.CONV) THEN
        CONVV(1)  =  .FALSE.
        CONVV(2)  =  .FALSE.
        CONVV(3)  =  .FALSE.
        CONVV(4)  =  .FALSE.
      ENDIF
!
!-----------------------------------------------------------------------
!  IF NO TRACER, THERE SHOULD BE NO TRACER DIFFUSION:
!-----------------------------------------------------------------------
!
      IF(NTRAC.EQ.0) THEN
        DIFT = .FALSE.
      ENDIF
!
!-----------------------------------------------------------------------
!  POSSIBLE ERROR OF ENGLISH USERS
!-----------------------------------------------------------------------
!
      IF (EQUA(1:15).EQ.'SAINT-VENANT FE') EQUA(14:15)='EF'
      IF (EQUA(1:15).EQ.'SAINT-VENANT FV') EQUA(14:15)='VF'
!
!-----------------------------------------------------------------------
!  NO PARALLELISME YET FOR FV
!-----------------------------------------------------------------------
!
      IF(EQUA(1:15).EQ.'SAINT-VENANT VF'.AND.NCSIZE.GT.1) THEN
        IF(OPTVF.EQ.6) THEN
          WRITE(LU,*) REPEAT('+',50)
          IF(LNG.EQ.1) WRITE(LU,1) 
          IF(LNG.EQ.2) WRITE(LU,2) 
1         FORMAT(1X,'PARALLELISME NON DISPONIBLE POUR LE SCHEMA WAF')
2         FORMAT(1X,'PARALLEL OPTION NOT AVAILABLE FOR WAF SCHEME')
          WRITE(LU,*) REPEAT('+',50)
          CALL PLANTE(1)
          STOP
        ENDIF       
      ENDIF
!
!-----------------------------------------------------------------------
!  NAME OF THE VARIABLES FOR THE RESULTS AND GEOMETRY FILES:
!-----------------------------------------------------------------------
!
! ARRAY OF LOGICALS FOR OUTPUT
!
      CALL NOMVAR_TELEMAC2D(TEXTE,TEXTPR,MNEMO,NPERIAF,NTRAC,NAMETRAC)
      CALL SORTIE(VARDES , MNEMO , MAXVAR , SORLEO )
      CALL SORTIE(VARIMP , MNEMO , MAXVAR , SORIMP )
!
!     OVERWRITES FOR PARAMETER ESTIMATION DEVELOPPERS
!     CHECKS FILES
!
      IF(ESTIME.NE.' ') THEN
        TEXTE (20) = 'CV1                             '
        TEXTE (21) = 'CV2                             '
        TEXTE (22) = 'CV3                             '
        TEXTE (23) = 'ADJOINT H                       '
        TEXTE (24) = 'ADJOINT U                       '
        TEXTE (25) = 'ADJOINT V                       '
        IF(T2D_FILES(T2DRBI)%NAME.EQ.' ') THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'FICHIER DE RESULTATS BINAIRE NECESSAIRE'
            WRITE(LU,*) 'POUR L''ESTIMATION DE PARAMETRES'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'BINARY RESULTS FILE NECESSARY'
            WRITE(LU,*) 'FOR PARAMETER ESTIMATION'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
! CORRECTS A POTENTIAL ERROR IN THE DATA (THERE SHOULD BE NO TRACER
! WIND, ETC OUTPUT IF THE COMPUTATION WAS WITHOUT TRACER, WIND, ETC).
!
      IF(.NOT.ATMOS) THEN
        SORLEO(18)  = .FALSE.
        SORIMP(18)  = .FALSE.
      ENDIF
      IF(.NOT.VENT) THEN
        SORLEO(16)  = .FALSE.
        SORIMP(16)  = .FALSE.
        SORLEO(17)  = .FALSE.
        SORIMP(17)  = .FALSE.
      ENDIF
      IF(NTRAC.EQ.0) THEN
        SORLEO(9)  = .FALSE.
        SORIMP(9)  = .FALSE.
      ENDIF
      IF(ITURB.NE.3) THEN
        SORLEO(10) = .FALSE.
        SORIMP(10) = .FALSE.
        SORLEO(11) = .FALSE.
        SORIMP(11) = .FALSE.
      ENDIF
!
!-----------------------------------------------------------------------
!
! IN CASE OF A CONTINUATION RUN, A PREVIOUS COMPUTATION FILE NEEDS TO BE GIVEN
!
      IF(.NOT.DEBU.AND.T2D_FILES(T2DPRE)%NAME(1:1).EQ.' ') THEN
        IF(LISTIN) THEN
          IF(LNG.EQ.1) WRITE(LU,1002)
          IF(LNG.EQ.2) WRITE(LU,1003)
        ENDIF
1002    FORMAT(1X,'LECDON : UNE SUITE DE CALCUL EST DEMANDEE',/,10X,
     &  'IL FAUT DONNER UN FICHIER DE RESULTATS DU CALCUL PRECEDENT',/)
1003    FORMAT(1X,'LECDON : COMPUTATION CONTINUED, SO A PREVIOUS',/,
     &         1X,'         RESULTS FILE IS NECESSARY',/)
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
! IN CASE OF A VALIDATION, A REFERENCE FILE SHOULD BE GIVEN
!
      IF(VALID.AND.T2D_FILES(T2DREF)%NAME(1:1).EQ.' ') THEN
        IF(LISTIN) THEN
          IF(LNG.EQ.1) WRITE(LU,1004)
          IF(LNG.EQ.2) WRITE(LU,1005)
        ENDIF
1004    FORMAT(1X,'LECDON : UNE VALIDATION EST DEMANDEE',/,10X,
     &  'IL FAUT DONNER UN FICHIER DE REFERENCE',/,10X,
     &  '(MOT-CLE : FICHIER DE REFERENCE)',/,10X,
     &  'QUI SERVIRA POUR LA COMPARAISON. ARRET DU PROGRAMME',
     &  ////)
1005    FORMAT(1X,'LECDON: A VALIDATION IS ASKED, SO A',/,
     &         9X,'REFERENCE FILE IS NECESSARY',/,
     &         9X,'(KEY-WORD: REFERENCE FILE)',/,
     &         9X,'FOR COMPARISON. INTERRUPTION OF PROGRAM',
     &  ////)
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!  COHERENCE OF THE DISCHARGE POINTS
!
      IF(NREJEU.NE.NREJEV) THEN
        IF(LNG.EQ.1) WRITE(LU,1016) NREJEU,NREJEV
        IF(LNG.EQ.2) WRITE(LU,1017) NREJEU,NREJEV
1016    FORMAT(1X,
     &  'VITESSES DES SOURCES SELON X ET SELON Y EN NOMBRE DIFFERENT :',
     &  I6,1X,I6)
1017    FORMAT(1X,'DIFFERENT NUMBERS OF VELOCITIES OF SOURCES ',/,1X,
     &  'ALONG X AND ALONG Y: ',I6,1X,I6)
      ENDIF
!
!-----------------------------------------------------------------------
!
!  OPTBAN REPLACES BANDEC
!  FOR REASONS OF COMPATIBILITY, BANDEC IS KEPT
!  OPTBAN IS HERE MODIFIED ACCORDING TO BANDEC
!
      IF(.NOT.BANDEC) OPTBAN =0
      MSK = .FALSE.
      IF(OPTBAN.EQ.2.OR.MSKUSE) MSK = .TRUE.
      IF(EQUA(1:15).EQ.'SAINT-VENANT VF') THEN
        IF(BANDEC.OR.OPTBAN.NE.0) THEN
          BANDEC = .FALSE.
          OPTBAN = 0
          IF(LNG.EQ.1) WRITE(LU,1020)
          IF(LNG.EQ.2) WRITE(LU,1021)
1020      FORMAT(1X,'PAS DE TRAITEMENT DES BANCS DECOUVRANTS',/,1X,
     &              ' EN VOLUMES FINIS')
1021      FORMAT(1X,'NO SPECIFIC TREATMENT OF DRY ZONES',/,1X,
     &              ' IN FINITE VOLUMES')
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!  PRECONDITIONING OF TYPE CROUT WITH GMRES: NOT FOR VECTOR COMPUTERS
!
      IF(LVMAC.NE.1) THEN
        IF((SLVPRO%SLV.EQ.7.AND.
     &      MOD(SLVPRO%PRECON, 7).EQ.0).OR.
     &     (SLVPRO%SLV.EQ.7.AND.
     &      MOD(SLVPRO%PRECON,11).EQ.0).OR.
     &     (SLVPRO%SLV.EQ.7.AND.
     &      MOD(SLVPRO%PRECON,13).EQ.0).OR.
     &     (SLVK%SLV.EQ.7.AND.
     &      MOD(SLVK%PRECON, 7).EQ.0).OR.
     &     (SLVK%SLV.EQ.7.AND.
     &      MOD(SLVK%PRECON,11).EQ.0).OR.
     &     (SLVK%SLV.EQ.7.AND.
     &      MOD(SLVK%PRECON,13).EQ.0)) THEN
          IF(LNG.EQ.1) WRITE(LU,2000)
          IF(LNG.EQ.2) WRITE(LU,2001)
2000      FORMAT(1X,'MOT-CLES SOLVEURS ET PRECONDITIONNEMENTS :',/,1X,
     &              'SUR MACHINE VECTORIELLE,',/,1X,
     &              'NE PAS UTILISER GMRES + CROUT',///)
2001      FORMAT(1X,'KEY-WORDS SOLVERS AND PRECONDITONING:',/,1X,
     &              'ON VECTOR MACHINES,',/,1X,
     &              'DO NOT USE GMRES + CROUT',///)
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(NTRAC.GT.0) THEN
          DO ITRAC=1,NTRAC
            IF((SLVTRA(ITRAC)%SLV.EQ.7.AND.
     &          MOD(SLVTRA(ITRAC)%PRECON, 7).EQ.0).OR.
     &         (SLVTRA(ITRAC)%SLV.EQ.7.AND.
     &          MOD(SLVTRA(ITRAC)%PRECON,11).EQ.0).OR.
     &         (SLVTRA(ITRAC)%SLV.EQ.7.AND.
     &          MOD(SLVTRA(ITRAC)%PRECON,13).EQ.0)) THEN
              IF(LNG.EQ.1) WRITE(LU,2000)
              IF(LNG.EQ.2) WRITE(LU,2001)
              CALL PLANTE(1)
              STOP
            ENDIF
          ENDDO
        ENDIF
      ENDIF
!
!  PRECONDITIONING OF TYPE CROUT WITH PARALLELISM IMPOSSIBLE
!  DIRECT SOLVER WITH IMPOSSIBLE PARALLELISM
!
      IF(NCSIZE.GT.1) THEN
        IF((MOD(SLVPRO%PRECON, 7).EQ.0.AND.
     &      SLVPRO%PRECON.NE.0).OR.
     &     (MOD(SLVPRO%PRECON,11).EQ.0.AND.
     &      SLVPRO%PRECON.NE.0).OR.
     &     (MOD(SLVPRO%PRECON,13).EQ.0.AND.
     &      SLVPRO%PRECON.NE.0).OR.
     &     (MOD(SLVTRA(1)%PRECON, 7).EQ.0.AND.
     &      SLVTRA(1)%PRECON.NE.0).OR.
     &     (MOD(SLVTRA(1)%PRECON,11).EQ.0.AND.
     &      SLVTRA(1)%PRECON.NE.0).OR.
     &     (MOD(SLVTRA(1)%PRECON,13).EQ.0.AND.
     &      SLVTRA(1)%PRECON.NE.0).OR.
     &     (MOD(SLVK%PRECON, 7).EQ.0.AND.
     &      SLVK%PRECON.NE.0).OR.
     &     (MOD(SLVK%PRECON,11).EQ.0.AND.
     &      SLVK%PRECON.NE.0).OR.
     &     (MOD(SLVK%PRECON,13).EQ.0.AND.
     &      SLVK%PRECON.NE.0) ) THEN
          IF(LNG.EQ.1) WRITE(LU,2014)
          IF(LNG.EQ.2) WRITE(LU,2015)
2014      FORMAT(1X,'AVEC PARALLELISME,',/,1X,
     &           'PAS DE PRECONDITIONNEMENT DE TYPE CROUT',///)
2015      FORMAT(1X,'WITH PARALLELISM,',/,1X,
     &           'NO CROUT-TYPE PRECONDITIONNING',///)
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(SLVPRO%SLV.EQ.8.OR.SLVK%SLV.EQ.8) THEN
          IF(LNG.EQ.1) WRITE(LU,2018)
          IF(LNG.EQ.2) WRITE(LU,2019)
2018      FORMAT(1X,'AVEC PARALLELISME,',/,1X,
     &             'PAS DE SOLVEUR DIRECT',///)
2019      FORMAT(1X,'WITH PARALLELISM,',/,1X,
     &             'NO DIRECT SYSTEM SOLVER',///)
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(NTRAC.GT.0) THEN
          DO ITRAC=1,NTRAC
            IF(SLVTRA(ITRAC)%SLV.EQ.8) THEN
              IF(LNG.EQ.1) WRITE(LU,2018)
              IF(LNG.EQ.2) WRITE(LU,2019)
              CALL PLANTE(1)
              STOP
            ENDIF
          ENDDO
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(OPTASS.NE.3) THEN
        IF(SLVPRO%SLV.EQ.8.OR.SLVK%SLV.EQ.8) THEN
          IF(LNG.EQ.1) WRITE(LU,2022)
          IF(LNG.EQ.2) WRITE(LU,2023)
2022      FORMAT(1X,'AVEC SOLVEUR DIRECT, STOCKAGE PAR SEGMENT',/,1X,
     &             'OBLIGATOIRE',///)
2023      FORMAT(1X,'WITH DIRECT SYSTEM SOLVER, EDGE-BASED STORAGE',/,
     &           1X,'IS MANDATORY',///)
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(NTRAC.GT.0) THEN
          DO ITRAC=1,NTRAC
            IF(SLVTRA(ITRAC)%SLV.EQ.8) THEN
              IF(LNG.EQ.1) WRITE(LU,2022)
              IF(LNG.EQ.2) WRITE(LU,2023)
              CALL PLANTE(1)
              STOP
            ENDIF
          ENDDO
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(INCLUS(COUPLING,'DELWAQ').AND.OPTASS.NE.3) THEN
        IF(LNG.EQ.1) WRITE(LU,2024)
        IF(LNG.EQ.2) WRITE(LU,2025)
2024    FORMAT(1X,'AVEC COUPLAGE DELWAQ, STOCKAGE PAR SEGMENT',/,1X,
     &            'OBLIGATOIRE',///)
2025    FORMAT(1X,'WITH COUPLING WITH DELWAQ, EDGE-BASED STORAGE',/,1X,
     &            'IS MANDATORY',///)
        CALL PLANTE(1)
        STOP
      ENDIF
      IF(INCLUS(COUPLING,'DELWAQ').AND.DISCRE(1).EQ.12) THEN
        IF(LNG.EQ.1) WRITE(LU,2026)
        IF(LNG.EQ.2) WRITE(LU,2027)
2026    FORMAT(1X,'AVEC COUPLAGE DELWAQ, VITESSE QUASI-BULLE',/,1X,
     &            'INTERDITE',///)
2027    FORMAT(1X,'WITH COUPLING WITH DELWAQ, QUASI-BUBBLE VELOCITIES',
     &       /,1X,'IS NOT ALLOWED',///)
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(INCLUS(COUPLING,'DELWAQ').AND.OPTSUP(2).NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,2028)
        IF(LNG.EQ.2) WRITE(LU,2029)
2028    FORMAT(1X,'AVEC COUPLAGE DELWAQ, DECENTREMENT SUPG SUR H',/,1X,
     &            'IMPOSSIBLE, MODIFIER LE MOT-CLE : OPTION DE SUPG',//)
2029    FORMAT(1X,'WITH COUPLING WITH DELWAQ, SUPG UPWINDING ON H',/,1X,
     &            'IS FORBIDDEN, CHECK KEY-WORD: SUPG OPTION',//)
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!     CHECKS ADVECTION SOLVERS ON VELOCITY
!
      IF(ICONVF(1).NE.ADV_CAR.AND.ICONVF(1).NE.ADV_SUP.AND.
     &   ICONVF(1).NE.ADV_LPO.AND.ICONVF(1).NE.ADV_NSC.AND.
     &   ICONVF(1).NE.ADV_PSI.AND.ICONVF(1).NE.ADV_NSC_NC.AND.
     &   ICONVF(1).NE.ADV_PSI_NC.AND.
     &   ICONVF(1).NE.ADV_LPO_TF.AND.ICONVF(1).NE.ADV_NSC_TF) THEN
        IF(LNG.EQ.1) WRITE(LU,72) ICONVF(1)
        IF(LNG.EQ.2) WRITE(LU,73) ICONVF(1)
72      FORMAT(1X,'FORME DE LA CONVECTION POUR LA VITESSE : ',I3,/,1X,
     &            'INCONNUE OU NON PROGRAMMEE')
73      FORMAT(1X,'TYPE OF AVECTION FOR VELOCITY: ',I3,/,1X,
     &            'UNKNOWN OR NOT IMPLEMENTED')
        IF(ICONVF(1).EQ.8.AND.LNG.EQ.1) THEN
          WRITE(LU,*) 'LE SCHEMA VOLUMES FINIS 8 EST MAINTENANT'
          WRITE(LU,*) 'LE SCHEMA N CONSERVATIF, AVEC LE NUMERO ',
     &                                                          ADV_NSC
        ENDIF
        IF(ICONVF(1).EQ.8.AND.LNG.EQ.2) THEN
          WRITE(LU,*) 'THE FINITE VOLUMES SCHEME 8 IS NOW'
          WRITE(LU,*) 'THE CONSERVATIVE N-SCHEME, WITH NUMBER ',ADV_NSC
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!     CHECKS ADVECTION SOLVERS ON TRACERS
!
      IF(NTRAC.GT.0) THEN
        DO ITRAC=1,NTRAC
          IF(ICONVFT(ITRAC).NE.ADV_CAR.AND.
     &       ICONVFT(ITRAC).NE.ADV_SUP.AND.
     &       ICONVFT(ITRAC).NE.ADV_LPO.AND.
     &       ICONVFT(ITRAC).NE.ADV_NSC.AND.
     &       ICONVFT(ITRAC).NE.ADV_PSI.AND.
     &       ICONVFT(ITRAC).NE.ADV_NSC_NC.AND.
     &       ICONVFT(ITRAC).NE.ADV_PSI_NC.AND.
     &       ICONVFT(ITRAC).NE.ADV_LPO_TF.AND.
     &       ICONVFT(ITRAC).NE.ADV_NSC_TF) THEN
            IF(LNG.EQ.1) WRITE(LU,74) ICONVFT(ITRAC)
            IF(LNG.EQ.2) WRITE(LU,75) ICONVFT(ITRAC)
74          FORMAT(1X,'FORME DE LA CONVECTION DES TRACEURS : ',I3,/,1X,
     &                'INCONNUE OU NON PROGRAMMEE')
75          FORMAT(1X,'TYPE OF AVECTION FOR TRACERS: ',I3,/,1X,
     &                'UNKNOWN OR NOT IMPLEMENTED')
            IF(ICONVFT(ITRAC).EQ.8.AND.LNG.EQ.1) THEN
              WRITE(LU,*) 'LE SCHEMA VOLUMES FINIS 8 EST MAINTENANT'
              WRITE(LU,*) 'LE SCHEMA N CONSERVATIF, AVEC LE NUMERO ',
     &                                                    ADV_NSC
            ENDIF
            IF(ICONVFT(ITRAC).EQ.8.AND.LNG.EQ.2) THEN
              WRITE(LU,*) 'THE FINITE VOLUMES SCHEME 8 IS NOW'
              WRITE(LU,*) 'THE CONSERVATIVE N-SCHEME, WITH NUMBER ',
     &                                                    ADV_NSC
            ENDIF
            CALL PLANTE(1)
            STOP
          ENDIF
          IF(ICONVFT(ITRAC).EQ.ADV_LPO.OR.
     &       ICONVFT(ITRAC).EQ.ADV_LPO_TF.OR.
     &       ICONVFT(ITRAC).EQ.ADV_NSC.OR.
     &       ICONVFT(ITRAC).EQ.ADV_NSC_TF.OR.
     &       ICONVFT(ITRAC).EQ.ADV_PSI.OR.
     &       ICONVFT(ITRAC).EQ.ADV_PSI_TF     ) THEN
            TETAT = 0.D0
            IF(LNG.EQ.1) WRITE(LU,6000) ITRAC
            IF(LNG.EQ.2) WRITE(LU,6001) ITRAC
6000        FORMAT(1X,'LECDON : SCHEMA VOLUMES FINIS SUR LE TRACEUR ',
     &      1I6,/,1X,'VALEUR FORCEE : IMPLICITATION = 0.')
6001        FORMAT(1X,'LECDON: FINITE VOLUME SCHEME ON THE TRACER ',
     &      1I6,/,1X,'IMPOSED VALUE: IMPLICITATION = 0.')
            OPTSUP(2)=0
            IF(LNG.EQ.1) WRITE(LU,8000)
            IF(LNG.EQ.2) WRITE(LU,8001)
8000        FORMAT(1X,'LECDON : SCHEMA VOLUMES FINIS SUR LE TRACEUR ',
     &      1I6,/,1X,
     &      'VALEUR FORCEE : OPTION DE SUPG = 0 POUR H')
8001        FORMAT(1X,'LECDON : FINITE VOLUME SCHEME ON THE TRACER ',
     &      1I6,/,1X,
     &      'IMPOSED VALUE: SUPG OPTION = 0 FOR DEPTH')
            IF(OPTASS.NE.3) THEN
              IF(LNG.EQ.1) WRITE(LU,2216)
              IF(LNG.EQ.2) WRITE(LU,2217)
2216          FORMAT(1X,'STOCKAGE DES MATRICES = 3',/,1X,
     &                  'IMPOSE AVEC CONVECTEUR VOLUME FINIS')
2217          FORMAT(1X,'MATRIX STORAGE = 3',/,1X,
     &                  'MANDATORY WITH FINITE VOLUME ADVECTION')
              CALL PLANTE(1)
              STOP
            ENDIF
          ENDIF
        ENDDO
      ENDIF
!
!-----------------------------------------------------------------------
!
!     CASE WHERE ADVECTION IS DONE IN FINITE VOLUME
!
      IF(ICONVF(1).EQ.ADV_LPO.OR.ICONVF(1).EQ.ADV_LPO_TF.OR.
     &   ICONVF(1).EQ.ADV_NSC.OR.ICONVF(1).EQ.ADV_NSC_TF.OR.
     &   ICONVF(1).EQ.ADV_PSI.OR.ICONVF(1).EQ.ADV_PSI_TF     ) THEN
        IF(OPTASS.NE.3) THEN
          IF(LNG.EQ.1) WRITE(LU,2216)
          IF(LNG.EQ.2) WRITE(LU,2217)
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
      IF(ITURB.EQ.3) THEN
      IF(ICONVF(4).NE.ADV_CAR.AND.ICONVF(4).NE.ADV_SUP.AND.
     &   ICONVF(4).NE.ADV_LPO.AND.ICONVF(4).NE.ADV_NSC.AND.
     &   ICONVF(4).NE.ADV_PSI.AND.ICONVF(4).NE.ADV_NSC_NC.AND.
     &   ICONVF(4).NE.ADV_PSI_NC.AND.
     &   ICONVF(4).NE.ADV_LPO_TF.AND.ICONVF(4).NE.ADV_NSC_TF) THEN
        IF(LNG.EQ.1) WRITE(LU,76) ICONVF(4)
        IF(LNG.EQ.2) WRITE(LU,77) ICONVF(4)
76      FORMAT(1X,'FORME DE LA CONVECTION DE K ET EPSILON : ',I3,/,1X,
     &            'INCONNUE OU NON PROGRAMMEE')
77      FORMAT(1X,'TYPE OF AVECTION FOR K AND EPSILON: ',I3,/,1X,
     &            'UNKNOWN OR NOT IMPLEMENTED')
        IF(ICONVF(4).EQ.8.AND.LNG.EQ.1) THEN
          WRITE(LU,*) 'LE SCHEMA VOLUMES FINIS 8 EST MAINTENANT'
          WRITE(LU,*) 'LE SCHEMA N CONSERVATIF, AVEC LE NUMERO ',
     &                                                          ADV_NSC
        ENDIF
        IF(ICONVF(4).EQ.8.AND.LNG.EQ.2) THEN
          WRITE(LU,*) 'THE FINITE VOLUMES SCHEME 8 IS NOW'
          WRITE(LU,*) 'THE CONSERVATIVE N-SCHEME, WITH NUMBER ',ADV_NSC
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
      IF(ICONVF(4).EQ.ADV_LPO.OR.ICONVF(4).EQ.ADV_LPO_TF.OR.
     &   ICONVF(4).EQ.ADV_NSC.OR.ICONVF(4).EQ.ADV_NSC_TF.OR.
     &   ICONVF(4).EQ.ADV_PSI.OR.ICONVF(4).EQ.ADV_PSI_TF     ) THEN
        IF(OPTASS.NE.3) THEN
          IF(LNG.EQ.1) WRITE(LU,2216)
          IF(LNG.EQ.2) WRITE(LU,2217)
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!  CROUT PRECONDITIONING WITH DIFFERENT DISCRETISATION FOR H AND U
!  NOT PROGRAMMED FOR THE TIME BEING
!
      IF(DISCRE(1).NE.DISCRE(2).AND.SLVPRO%PRECON.NE.0) THEN
        IF((MOD(SLVPRO%PRECON, 7).EQ.0).OR.
     &     (MOD(SLVPRO%PRECON,11).EQ.0).OR.
     &     (MOD(SLVPRO%PRECON,13).EQ.0)     ) THEN
           IF(LNG.EQ.1) WRITE(LU,5002)
           IF(LNG.EQ.2) WRITE(LU,5003)
5002       FORMAT(1X,'AVEC DISCRETISATION DIFFERENTE DE H ET DE U',/,1X,
     &               'PAS DE PRECONDITIONNEMENT DE TYPE CROUT',///)
5003       FORMAT(1X,'WITH A DIFFERENT DISCRETIZATION OF H AND U',/,1X,
     &               'NO CROUT-TYPE PRECONDITIONNING',///)
           CALL PLANTE(1)
           STOP
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!  COHERENCE FOR THE EFFECTS OF DENSITY
!
      IF(ROVAR) THEN
!
        IF(NTRAC.EQ.0) THEN
          IF(LNG.EQ.1) WRITE(LU,2004)
          IF(LNG.EQ.2) WRITE(LU,2005)
2004      FORMAT(1X,'AVEC DES EFFETS DE DENSITE, IL FAUT UN ',/,1X,
     &              'TRACEUR EGAL A LA SALINITE')
2005      FORMAT(1X,'WITH DENSITY EFFECTS, A TRACER EQUAL TO',/,1X,
     &              'THE SALINITY IS NEEDED')
          CALL PLANTE(1)
          STOP
        ENDIF
!
        ROEAU = 999.972D0 * ( 1.D0 -7.D-6 *(TMOY-4.D0)**2 )
!
      ENDIF
!
!-----------------------------------------------------------------------
!
! COHERENCE FOR THE GENERATING FORCE OF THE TIDE
!
      IF (MAREE) THEN
!
        IF (SPHERI) THEN
          CORIOL = .TRUE.
          IF(LNG.EQ.1) WRITE(LU,5000)
          IF(LNG.EQ.2) WRITE(LU,5001)
5000      FORMAT(1X,'LECDON : PRISE EN COMPTE DE LA FORCE ',
     &    'GENERATRICE DE LA MAREE ET DE LA FORCE DE CORIOLIS')
5001      FORMAT(1X,'LECDON : COMPUTATION WITH THE TIDE-GENERATING FORCE
     & AND THE CORIOLIS FORCE')
        ELSE
          IF(LNG.EQ.1) WRITE(LU,4002)
          IF(LNG.EQ.2) WRITE(LU,4003)
4002      FORMAT(1X,'LECDON : LA PRISE EN COMPTE DE LA FORCE ',
     &            'GENERATRICE DE LA MAREE',/,10X,'N''EST PAS POSSIBLE',
     &            ' EN COORDONNEES CARTESIENNES')
4003      FORMAT(1X,'LECDON : COMPUTATION WITH TIDE-GENERATING FORCE',/,
     &      10X,'IMPOSSIBLE IN CARTESIAN COORDINATES')
          CALL PLANTE(1)
          STOP
        ENDIF
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!     DISCRETISES THE VARIABLES
!
      IELMU = DISCRE(1)
      IELMH = DISCRE(2)
      IELMT = DISCRE(3)
      IELMK = DISCRE(4)
      IELME = DISCRE(4)
      IELM0 = 10*(IELMH/10)
      IELM1 = IELM0 + 1
!
      IF(IELMH.EQ.12) THEN
        IF(LNG.EQ.1) WRITE(LU,4102)
        IF(LNG.EQ.2) WRITE(LU,4103)
4102    FORMAT(/,1X,'PAS DE DISCRETISATION QUASI-BULLE SUR LA HAUTEUR')
4103    FORMAT(/,1X,'NO QUASI-BUBBLE DISCRETISATION FOR DEPTH')
        CALL PLANTE(1)
        STOP
      ENDIF
!
      IF((IELMU.EQ.12.OR.IELMT.EQ.12).AND.PRODUC.EQ.2)
     & THEN
        IF(LNG.EQ.1) WRITE(LU,4000)
        IF(LNG.EQ.2) WRITE(LU,4001)
4000    FORMAT(/1X,'PRODUIT FRONTAL NON PROGRAMME AVEC QUASI-BULLE')
4001    FORMAT(/1X,'FRONTAL PRODUCT NOT IMPLEMENTED FOR QUASI-BUBBLE')
        CALL PLANTE(1)
        STOP
      ENDIF
!
      IF(EQUA(1:15).EQ.'SAINT-VENANT VF') THEN
        IF(IELMU.EQ.12.OR.IELMH.EQ.12) THEN
          IELMU = 11
          IELMH = 11
          IF(LNG.EQ.1) WRITE(LU,2020)
          IF(LNG.EQ.2) WRITE(LU,2021)
2020      FORMAT(1X,'PAS DE QUASI-BULLE EN VOLUMES FINIS')
2021      FORMAT(1X,'NO QUASI-BUBBLE IN FINITE VOLUMES')
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!  NUMBER OF TIMESTEPS ACCORDING TO THE PARAMETER CHOSEN BY THE USER
!
      NIT = MAX(NIT,INT(DUREE/DT +0.5D0))
!
!-----------------------------------------------------------------------
!
!  NPRIV MOFIFIED FOR OUTPUT OF USER-BUILT VARIABLES
!
      DO I=1,4
        IF ((SORLEO(22+I).OR.SORIMP(22+I)).AND.(NPRIV.LT.I)) THEN
          NPRIV=MAX(NPRIV,I)
        ENDIF
      ENDDO
!
!-----------------------------------------------------------------------
!
!  STORAGE 2 OPTION HAS BEEN REMOVED FROM RELEASE 5.1
!
      IF(OPTASS.EQ.2) THEN
        IF(LNG.EQ.1) WRITE(LU,2016)
        IF(LNG.EQ.2) WRITE(LU,2017)
2016    FORMAT(1X,'STOCKAGE DES MATRICES = 2',/,1X,
     &            'SUPPRIME DEPUIS LA VERSION 5.1',/,1X,
     &            'ESSAYER LE STOCKAGE PAR SEGMENTS (3) A LA PLACE')
2017    FORMAT(1X,'MATRIX STORAGE = 2',/,1X,
     &            'SUPPRESSED SINCE VERSION 5.1',/,1X,
     &            'TRY EDGE-BASED STORAGE (3) INSTEAD')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!  CHECKS NON-PROGRAMMED OPTIONS IN PARALLEL MODE
!
      IF(NCSIZE.GT.1) THEN
        IF(PRODUC.EQ.2) THEN
          IF(LNG.EQ.1) WRITE(LU,2714)
          IF(LNG.EQ.2) WRITE(LU,2715)
2714      FORMAT(1X,'PRODUIT FRONTAL',/,1X,
     &           'NON PROGRAMME EN PARALLELISME',/,1X,
     &           'L''OPTION 1 EST CHOISIE A LA PLACE')
2715      FORMAT(1X,'FRONTAL PRODUCT',/,1X,
     &           'NOT IMPLEMENTED WITH PARALLELISM',/,1X,
     &           'OPTION 1 IS TAKEN INSTEAD')
          PRODUC = 1
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!     CHECKS FRICTION COEFFICIENT
! 
      IF(FRICTB.AND.ESTIME.NE.' ') THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'LES MOTS CLES :'
          WRITE(LU,*) 'DONNEES POUR LE FROTTEMENT ET '
          WRITE(LU,*) 'ESTIMATION DE PARAMETRE'
          WRITE(LU,*) 'NE PEUVENT ETRE UTILISES SIMULTANEMENT'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'THE KEYWORDS :'
          WRITE(LU,*) 'FRICTION DATA FILE AND PARAMETER ESTIMATION'
          WRITE(LU,*) 'CANNOT BE USED TOGETHER'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
      IF(FRICTB) KFROT = 0 !ELSE THE NEXT TEST CAN BE FALSE
      IF(KFROT.NE.0.AND.TROUVE(2,4).NE.2) THEN
        IF(LNG.EQ.1) WRITE(LU,2716) KFROT
        IF(LNG.EQ.2) WRITE(LU,2717) KFROT
2716    FORMAT(1X,'LA LOI DE FROTTEMENT ',1I2,' EST DEMANDEE',/,1X,
     &            'DONNER LE COEFFICIENT DE FROTTEMENT CORRESPONDANT')
2717    FORMAT(1X,'THE LAW OF BOTTOM FRICTION ',1I2,' IS ASKED',/,1X,
     &            'GIVE THE CORRESPONDING FRICTION COEFICIENT')
        CALL PLANTE(1)
        STOP
      ELSEIF(TROUVE(1,8).NE.2) THEN
        IF(LNG.EQ.1) WRITE(LU,2718) 
        IF(LNG.EQ.2) WRITE(LU,2719) 
2718    FORMAT(1X,'AUCUNE LOI DE FROTTEMENT N''EST DONNEE !')
2719    FORMAT(1X,'NO FRICTION LAW IS PRESCRIBED!') 
        CALL PLANTE(1)
        STOP    
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(SOLSYS.EQ.2.AND.ESTIME.NE.' ') THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'TRAITEMENT DU SYSTEME LINEAIRE OBLIGATOIREMENT 1'
          WRITE(LU,*) 'EN MODE ESTIMATION DE PARAMETRES                '
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'TREATMENT OF THE LINEAR SYSTEM MUST BE 1'
          WRITE(LU,*) 'IN PARAMETER ESTIMATION MODE            '
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(SOLSYS.EQ.2.AND.EQUA(1:10).EQ.'BOUSSINESQ') THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'TRAITEMENT DU SYSTEME LINEAIRE 2'
          WRITE(LU,*) 'ET BOUSSINESQ SONT INCOMPATIBLES'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'TREATMENT OF THE LINEAR SYSTEM 2'
          WRITE(LU,*) 'AND BOUSSINESQ ARE NOT COMPATIBLE'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
      IF(ESTIME.NE.' '.AND.BANDEC) THEN
        IF(OPTCOST.EQ.2.AND.LNG.EQ.1) THEN
          WRITE(LU,*) 'MOT-CLE FONCTION COUT OBLIGATOIREMENT EGAL A 1'
          WRITE(LU,*) 'AVEC DES BANCS DECOUVRANTS'
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(OPTCOST.EQ.2.AND.LNG.EQ.2) THEN
          WRITE(LU,*) 'KEY-WORD COST FUNCTION MUST BE 1'
          WRITE(LU,*) 'WITH TIDAL FLATS'
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!     REQUIRED OPTIONS OR BETTER OPTIONS FOR THE WAVE EQUATION
!
      IF(SOLSYS.EQ.2) THEN
!
!       DIAGONAL PRECONDITIONING WITH ABSOLUTE VALUES
        IF(2*(SLVPRO%PRECON/2).EQ.SLVPRO%PRECON) THEN
          SLVPRO%PRECON=SLVPRO%PRECON/2
          SLVPRO%PRECON=SLVPRO%PRECON*5
        ENDIF
!       NO C-U PRECONDITIONING
        PRECCU = .FALSE.
!       EXPLICIT DIFFUSION
!       TETAD  = 0.D0
!       IMPLICIT VELOCITY AND DEPTH (NOT COMPULSORY BUT MORE STABLE)
!       FOLLOWING LINE COMMENTED OUT AFTER USER CLUB 2010 (REMARK BY ALAN COOPER)
!       TETAU = 1.D0
!       FOLLOWING LINE COMMENTED OUT ON 16/09/2011 (NOT MANDATORY)
!       TETAC = 1.D0
!       MASS-LUMPING COMPLETE ON U
        AGGLOU = 1.D0
        IF(ICONVF(1).NE.ADV_CAR.AND.ICONVF(1).NE.ADV_PSI_NC.AND.
     &     ICONVF(1).NE.ADV_LPO.AND.ICONVF(1).NE.ADV_LPO_TF.AND.
     &     ICONVF(1).NE.ADV_NSC.AND.ICONVF(1).NE.ADV_NSC_TF.AND.
     &     ICONVF(1).NE.ADV_PSI.AND.ICONVF(1).NE.ADV_PSI_TF     ) THEN
          IF(LNG.EQ.1) WRITE(LU,3002)
          IF(LNG.EQ.2) WRITE(LU,3003)
3002      FORMAT(/1X,'AVEC LE TRAITEMENT DU SYSTEME LINEAIRE 2',/,
     &            1X,'LA FORME DE LA CONVECTION DOIT ETRE EXPLICITE',/,
     &            1X,'POUR LA VITESSE')
3003      FORMAT(/1X,'WITH THE TREATMENT OF THE LINEAR SYSTEM NUMBER 2',
     &            1X,'THE ADVECTION TYPE MUST BE EXPLICIT',/,
     &            1X,'FOR THE VELOCITY')
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(IELMU.EQ.13) THEN
          IF(LNG.EQ.1) WRITE(LU,3006)
          IF(LNG.EQ.2) WRITE(LU,3007)
3006      FORMAT(/1X,'AVEC L''EQUATION D''ONDE',/,
     &            1X,'VITESSE QUADRATIQUE NON PROGRAMMEE')
3007      FORMAT(/1X,'WITH THE WAVE EQUATION',
     &            1X,'QUADRATIC VELOCITY IS NOT IMPLEMENTED')
          CALL PLANTE(1)
          STOP
        ENDIF
      ELSEIF(SOLSYS.NE.1) THEN
        IF(LNG.EQ.1) WRITE(LU,3004) SOLSYS
        IF(LNG.EQ.2) WRITE(LU,3005) SOLSYS
3004    FORMAT(/,1X,'LE TRAITEMENT DU SYSTEME LINEAIRE :',1I6,1X,/,
     &             'DOIT ETRE EGAL A 1 OU 2')
3005    FORMAT(/,1X,'THE TREATMENT OF THE LINEAR SYSTEM:',1I6,1X,/,
     &             'MUST BE EQUAL TO 1 OR 2')
        CALL PLANTE(1)
        STOP
      ENDIF
!
      IF(TETAC.LT.0.5D0) THEN
        IF(LNG.EQ.1) WRITE(LU,3008) TETAC
        IF(LNG.EQ.2) WRITE(LU,3009) TETAC
3008    FORMAT(/,1X,'L''IMPLICITATION POUR LA HAUTEUR :',G16.7,1X,/,
     &             'DOIT ETRE SUPERIEURE A 0.5')
3009    FORMAT(/,1X,'IMPLICITATION FOR DEPTH:',1I6,1X,/,
     &             'MUST BE GREATER THAN 0.5')
        CALL PLANTE(1)
        STOP
      ENDIF
      IF(TETAU.LT.0.5D0) THEN
        IF(LNG.EQ.1) WRITE(LU,3010) TETAU
        IF(LNG.EQ.2) WRITE(LU,3011) TETAU
3010    FORMAT(/,1X,'L''IMPLICITATION POUR LA VITESSE :',G16.7,1X,/,
     &             'DOIT ETRE SUPERIEURE A 0.5')
3011    FORMAT(/,1X,'IMPLICITATION FOR VELOCITY:',1I6,1X,/,
     &             'MUST BE GREATER THAN 0.5')
        CALL PLANTE(1)
        STOP
      ENDIF
!
!  LOOKS FOR TEMPERATURE AND SALINITY IN THE TRACERS 
!
      IF(.NOT.WATQUA)IND_T=0
!     IF WATQUA, IND_T IS OBTAINED IN SUBROUTINE INCREASE_NTRAC 
      IND_S=0
      IF(NTRAC.GE.1) THEN
        DO I=1,NTRAC
          IF(NAMETRAC(I)(1:11).EQ.'TEMPERATURE') IND_T = I
          IF(NAMETRAC(I)(1: 7).EQ.'SALINIT')     IND_S = I
        ENDDO
      ENDIF
!
!  CHECKS THE EXISTENCE OF RELEVANT TRACERS FOR DELWAQ
!
      IF(IND_T.EQ.0.AND.TEMP_DEL) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'POUR DELWAQ IL MANQUE LA TEMPERATURE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'TEMPERATURE MISSING FOR DELWAQ'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
      IF(IND_S.EQ.0.AND.SALI_DEL) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'POUR DELWAQ IL MANQUE LA SALINITE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'SALINITY MISSING FOR DELWAQ'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
      IF(OPTBAN.EQ.1.AND.OPT_HNEG.EQ.2) THEN
        IF(ABS(AGGLOC-1.D0).GT.0.01D0) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'TRAITEMENT DES HAUTEURS NEGATIVES=2'
            WRITE(LU,*) 'MASS-LUMPING SUR H DOIT ETRE EGAL A 1.'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'TREATMENT OF NEGATIVE DEPTHS=2'
            WRITE(LU,*) 'MASS-LUMPING ON H MUST BE EQUAL TO 1.'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(.NOT.CORCON) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'TRAITEMENT DES HAUTEURS NEGATIVES=2'
            WRITE(LU,*) 'CORRECTION DE CONTINUITE=OUI OBLIGATOIRE'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'TREATMENT OF NEGATIVE DEPTHS=2'
            WRITE(LU,*) 'CONTINUITY CORRECTION=YES MANDATORY'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
        IF(OPTSUP(2).NE.0) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'TRAITEMENT DES HAUTEURS NEGATIVES=2'
            WRITE(LU,*) 'PAS DE DECENTREMENT SUPG SUR LA HAUTEUR'
            WRITE(LU,*) 'METTRE OPTION DE SUPG=..;0;...'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'TREATMENT OF NEGATIVE DEPTHS=2'
            WRITE(LU,*) 'NO SUPG UPWINDING ON DEPTH'
            WRITE(LU,*) 'CHOOSE SUPG OPTION=...;0;...'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
!     TIDAL FLATS VERSIONS OF FINITE VOLUME ADVECTION SCHEMES
!     REQUEST POSITIVE DEPTHS
!
      IF(BANDEC.AND.OPTBAN.EQ.1.AND.OPT_HNEG.NE.2) THEN
        IF(ICONVF(1).EQ.ADV_NSC_TF.OR.ICONVF(4).EQ.ADV_NSC_TF
     & .OR.ICONVF(1).EQ.ADV_LPO_TF.OR.ICONVF(4).EQ.ADV_LPO_TF
     & .OR.ICONVF(1).EQ.ADV_PSI_TF.OR.ICONVF(4).EQ.ADV_PSI_TF) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'AVEC LES SCHEMAS DE CONVECTION'
            WRITE(LU,*) ADV_LPO_TF,ADV_NSC_TF,' OU ',ADV_PSI_TF
            WRITE(LU,*) 'TRAITEMENT DES HAUTEURS NEGATIVES'
            WRITE(LU,*) 'DOIT ETRE EGAL A 2'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'WITH ADVECTION SCHEMES'
            WRITE(LU,*) ADV_LPO_TF,ADV_NSC_TF,' OR ',ADV_PSI_TF
            WRITE(LU,*) 'TREATMENT OF NEGATIVE DEPTHS'
            WRITE(LU,*) 'MUST BE EQUAL TO 2'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
      IF(NTRAC.GT.0.AND.BANDEC.AND.OPTBAN.EQ.1.AND.OPT_HNEG.NE.2) THEN
        DO ITRAC=1,NTRAC
          IF(    ICONVFT(ITRAC).EQ.ADV_NSC_TF
     &       .OR.ICONVFT(ITRAC).EQ.ADV_LPO_TF
     &       .OR.ICONVFT(ITRAC).EQ.ADV_PSI_TF ) THEN
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'AVEC LES SCHEMAS DE CONVECTION'
              WRITE(LU,*) ADV_LPO_TF,ADV_NSC_TF,' OU ',ADV_PSI_TF
              WRITE(LU,*) 'TRAITEMENT DES HAUTEURS NEGATIVES'
              WRITE(LU,*) 'DOIT ETRE EGAL A 2'
            ENDIF
            IF(LNG.EQ.2) THEN
              WRITE(LU,*) 'WITH ADVECTION SCHEMES'
              WRITE(LU,*) ADV_LPO_TF,ADV_NSC_TF,' OR ',ADV_PSI_TF
              WRITE(LU,*) 'TREATMENT OF NEGATIVE DEPTHS'
              WRITE(LU,*) 'MUST BE EQUAL TO 2'
            ENDIF
            CALL PLANTE(1)
            STOP
          ENDIF
        ENDDO
      ENDIF
!
!-----------------------------------------------------------------------
!
!  CHECKS THE EXISTENCE OF A MIGRHYCAR STEERING FILE
!
      IF(SPILL_MODEL.AND.T2D_FILES(T2DMIG)%NAME(1:1).EQ.' ') THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) ' '
          WRITE(LU,*) 'POUR LE MODELE DE DERIVES DE NAPPES'
          WRITE(LU,*) 'DONNER UN FICHIER DE COMMANDES MIGRHYCAR'
          WRITE(LU,*) ' '
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) ' '
          WRITE(LU,*) 'FOR THE OIL SPILL MODEL'
          WRITE(LU,*) 'PLEASE GIVE A MIGRHYCAR STEERING FILE'
          WRITE(LU,*) ' '
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!     WAVE DRIVEN CURRENTS MANDATORY IF COUPLING TO TOMAWAC
!
!     COMMENTED ON 24/12/2013
!     IF(INCLUS(COUPLING,'TOMAWAC')) COUROU=.TRUE.
!
!-----------------------------------------------------------------------
!
!  CHOICE FOR TIDAL DATA BASE TO DO BY THE USER
!
      IF(TIDALTYPE.NE.0.AND.TIDALDB.EQ.-1) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'CHOISIR LA BASE DE DONNEES DE MAREE'
          WRITE(LU,*) 'PARMI LES CHOIX POSSIBLES :'
          WRITE(LU,*) '  -1 : JMJ ;'
          WRITE(LU,*) '  -2 : TPXO ;'
          WRITE(LU,*) '  -3 : LEGOS-NEA.'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'CHOOSE THE TIDAL DATA BASE'
          WRITE(LU,*) 'AMONG THE POSSIBLE CHOICES:'
          WRITE(LU,*) '  -1: JMJ,'
          WRITE(LU,*) '  -2: TPXO,'
          WRITE(LU,*) '  -3: LEGOS-NEA.'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!  CHECKS THE EXISTENCE OF TIDAL DATA BASE FILES WHEN USING TPXO
!
      IF(TIDALTYPE.NE.0.AND.TIDALDB.EQ.2
     &   .AND.T2D_FILES(T2DBB1)%NAME(1:1).EQ.' ') THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'POUR UTILISER LA BASE DE DONNEES DE MAREE TPXO'
          WRITE(LU,*) 'DONNER LE FICHIER'
          WRITE(LU,*) 'BASE BINAIRE 1 DE DONNEES DE MAREE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'TO USE TPXO TIDAL DATA BASE'
          WRITE(LU,*) 'PLEASE GIVE A BINARY DATABASE 1 FOR TIDE FILE'
        ENDIF
        CALL PLANTE(1)
        STOP
      ELSEIF(TIDALTYPE.NE.0.AND.TIDALDB.EQ.2
     &       .AND.T2D_FILES(T2DBB2)%NAME(1:1).EQ.' ') THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'POUR UTILISER LA BASE DE DONNEES DE MAREE TPXO'
          WRITE(LU,*) 'DONNER LE FICHIER'
          WRITE(LU,*) 'BASE BINAIRE 2 DE DONNEES DE MAREE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'TO USE TPXO TIDAL DATA BASE'
          WRITE(LU,*) 'PLEASE GIVE A BINARY DATABASE 2 FOR TIDE FILE'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!  POSITIVE COEFFICIENT TO CALIBRATE TIDAL RANGE EXPECTED
!
      IF(CTIDE.LT.0) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'LE COEFFICIENT DE CALAGE DU MARNAGE'
          WRITE(LU,*) 'DOIT ETRE POSITIF OU NUL'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'COEFFICIENT TO CALIBRATE TIDAL RANGE'
          WRITE(LU,*) 'HAVE TO BE GREATER OR EQUAL 0'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!  POSITIVE COEFFICIENT TO CALIBRATE TIDAL VELOCITIES EXPECTED
!
      IF(CTIDEV.LT.0) THEN
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'LE COEFFICIENT DE CALAGE DES VITESSES DE COURANT'
          WRITE(LU,*) 'DOIT ETRE POSITIF OU NUL'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'COEFFICIENT TO CALIBRATE TIDAL VELOCITIES'
          WRITE(LU,*) 'HAVE TO BE GREATER OR EQUAL 0'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
!  SPATIAL PROJECTION TYPE CHECKED IF SPHERICAL COORDINATES ASKED
!
      IF(SPHERI) THEN
        IF(PROTYP.NE.2.AND.PROTYP.NE.3) THEN
          IF(LNG.EQ.1) THEN
            WRITE(LU,*) 'TYPE DE PROJECTION SPATIALE : ',PROTYP
            WRITE(LU,*) 'IMPOSSIBLE AVEC DES COORDONNEES SPHERIQUES'
          ENDIF
          IF(LNG.EQ.2) THEN
            WRITE(LU,*) 'SPATIAL PROJECTION TYPE: ',PROTYP
            WRITE(LU,*) 'IMPOSSIBLE WITH SPHERICAL COORDINATES'
          ENDIF
          CALL PLANTE(1)
          STOP
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!     BUIDING THE OPTIONS OF THE ADVECTION SCHEMES
!
!     VELOCITY
!
      OPTADV_VI=1
      IF(ICONVF(1).EQ.1) THEN
!       CHARACTERISTICS
        OPTADV_VI=OPTCHA
      ELSEIF(ICONVF(1).EQ.2) THEN
!       SUPG
        OPTADV_VI=OPTSUP(1)
      ELSEIF(ICONVF(1).EQ.5) THEN
!       PSI SCHEME
        OPTADV_VI=OPTPSI
      ENDIF
!     SCHEME OPTION FOR ADVECTION OF VELOCITIES
!     HAS PRIORITY WHEN PRESENT
      IF(TROUVE(1,92).EQ.2) THEN
        OPTADV_VI = MOTINT(ADRESS(1,92))
!       WEAK CHARACTERISTICS MEMORY ALLOCATIONS ARE TRIGGERED BY OPTCHA
        IF(ICONVF(1).EQ.1.AND.OPTADV_VI.EQ.2) OPTCHA=2
      ENDIF
!
!     K-EPSILON
!
      OPTADV_KE=1
      IF(ICONVF(4).EQ.1) THEN
!       CHARACTERISTICS
        OPTADV_KE=OPTCHA
      ELSEIF(ICONVF(4).EQ.2) THEN
!       SUPG
        OPTADV_KE=OPTSUP(4)
      ELSEIF(ICONVF(4).EQ.5) THEN
!       PSI SCHEME
        OPTADV_KE=OPTPSI
      ENDIF
!     SCHEME OPTION FOR ADVECTION OF K-EPSILON
!     HAS PRIORITY WHEN PRESENT
      IF(TROUVE(1,93).EQ.2) THEN
        OPTADV_KE = MOTINT(ADRESS(1,93))
!       WEAK CHARACTERISTICS MEMORY ALLOCATIONS ARE TRIGGERED BY OPTCHA
        IF(ICONVF(4).EQ.1.AND.OPTADV_KE.EQ.2) OPTCHA=2
      ENDIF
!
!     TRACERS
!
      IF(NTRAC.GT.0) THEN
        DO ITRAC=1,NTRAC
          OPTADV_TR(ITRAC)=1
          IF(ICONVFT(ITRAC).EQ.1) THEN
!           CHARACTERISTICS
            OPTADV_TR(ITRAC)=OPTCHA
          ELSEIF(ICONVFT(ITRAC).EQ.2) THEN
!           SUPG
            OPTADV_TR(ITRAC)=OPTSUP(3)
          ELSEIF(ICONVFT(ITRAC).EQ.5) THEN
!           PSI SCHEME
            OPTADV_TR(ITRAC)=OPTPSI
          ENDIF
        ENDDO
!       SCHEME OPTION FOR ADVECTION OF TRACERS
!       HAS PRIORITY WHEN PRESENT
        IF(TROUVE(1,91).EQ.2) THEN
          DO ITRAC=1,MIN(NTRAC,DIMEN(1,91))
            OPTADV_TR(ITRAC) = MOTINT(ADRESS(1,91)+ITRAC-1)
!           WEAK CHARACTERISTICS MEMORY ALLOCATIONS TRIGGERED BY OPTCHA
            IF(ICONVFT(ITRAC).EQ.1.AND.OPTADV_TR(ITRAC).EQ.2) OPTCHA=2
          ENDDO
        ENDIF
      ENDIF
!
!-----------------------------------------------------------------------
!
!  WRITES OUT THE TITLE
!
      IF(LISTIN) THEN
        IF(LNG.EQ.1) WRITE(LU,3000) TITCAS
        IF(LNG.EQ.2) WRITE(LU,3001) TITCAS
3000    FORMAT(/1X,'SORTIE DE LECDON. TITRE DE L''ETUDE :',/,1X,A72,/)
3001    FORMAT(/1X,'EXITING LECDON. NAME OF THE STUDY:',/,1X,A72,/)
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
9000  CONTINUE
      IF(LNG.EQ.1)WRITE(LU,9001)NOM_CAS_WAQ,NOM_DIC_WAQ
      IF(LNG.EQ.2)WRITE(LU,9002)NOM_CAS_WAQ,NOM_DIC_WAQ
9001  FORMAT(/1X,'ERREUR DANS L OUVERTURE DU FICHIER WAQ OU DU DICO :',
     &       /,1X,A172,1X/A172)
9002  FORMAT(/1X,'PROBLEM IN OPENING WAQ STEERING FILE OR DICO :',
     &       /,1X,A172,1X/A172)
      CALL PLANTE(1)
      STOP
      END
