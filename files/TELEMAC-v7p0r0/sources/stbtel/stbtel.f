!                       *****************
                        SUBROUTINE STBTEL
!                       *****************
!
     &( NPOIN1 , TYPELE , NFOND , PRECIS , NSFOND , TITRE)
!
!***********************************************************************
! PROGICIEL : STBTEL  6.0           09/08/89    J.C. GALLAND
!                                    19/02/93    J.M. JANIN
!                                    09/11/94    P. LANG / LHF (TRIGRID)
!                                  07/96    P. CHAILLET / LHF (FASTTABS)
!                                  09/98    A. CABAL / P. LANG SOGREAH
!***********************************************************************
!
!     FONCTION  : PROGRAMME PRINCIPAL
!
!-----------------------------------------------------------------------
!                             ARGUMENTS
! .________________.____.______________________________________________
! |      NOM       |MODE|                   ROLE
! |________________|____|______________________________________________
! | X,Y            |<-- | COORDONNEES DES POINTS DU MAILLAGE
! | ZF             |<-- | COTES DU FOND
! | XR,YR          |<-- | COORDONNEES DES POINTS DE BATHY
! | ZR             |<-- | COTES DES POINTS DE BATHY
! | NBAT           | -->| NOMBRE DE POINTS DE BATHY
! | IKLE           |<-- | NUMEROS GLOBAUX DES NOEUDS DE CHAQUE ELEMENT
! | IFABOR         |<-- | NUMERO DE L'ELEMENT VOISIN DE CHAQUE FACE
! | NBOR           |<-- | NUMEROTATION DES ELEMENTS DE BORD
! | TRAV1,2        |<-->| TABLEAUX DE TRAVAIL
! | NCOLOR         |<-- | TABLEAU DES COULEURS DES NOEUDS
! | NCOLFR         |<-- | TABLEAU DES COULEURS DES NOEUDS FRONTIERES
! | NOP5           | -->| TABLEAU DE TRAVAIL POUR LA LECTURE DU FICHIER
! |                |    | GEOMETRIE DE SIMAIL
! | NPOIN1         | -->| NOMBRE REEL DE POINTS DU MAILLAGE
! |                |    | (NPOIN REPRESENTE L'INDICE MAX DES NOEUDS CAR
! |                |    | SUPERTAB LAISSE DES TROUS DANS LA NUMEROTATION
! | TYPELE         | -->| TYPE DES ELEMENTS
! | STD            | -->| STANDARD DE BINAIRE
! | DECTRI         | -->| DECOUPAGE OU NON DES TRIANGLES SURCONTRAINTS
! | FOND           | -->| TABLEAU DES NOMS DES FICHIERS BATHY
! | NFOND          | -->| TABLEAU DES CANAUX DES FICHIERS BATHY
! | EPSI           | -->| DISTANCE MINIMALE ENTRE 2 POINTS POUR DEFINIR
! |                |    | LES POINTS DE MAILLAGE CONFONDUS
! | COLOR          |<-- | COULEUR DES NOEUDS
! | ELIDEP         | -->| LOGIQUE POUR L'ELIMINATION DES MOTS-CLES
! | NBFOND         | -->| NOMBRE DE FICHIERS DE BATHY
! | MAILLE         | -->| NOM DU MAILLEUR UTILISE
! | DM             | -->| DISTANCE MINIMALE A LA FRONTIERE
! |                |    | POUR LA PROJECTION DES FONDS
! | PRECIS         | -->| FORMAT DE LECTURE DES COORDONNEES DES NOEUDS
! | FONTRI         | -->| INDICATEUR DE LECTURE DES FONDS DANS NGEO
! | CORTRI         | -->| CORRECTION DES FONDS POUR TRIGRID
! | TFAST1,2       | -->| TABLEAUX DE TRAVAIL (FASTTABS)
! | ADDFAS         | -->| INDICATEUR UTILISATION DES C.L. (FASTTABS)
! | VAR            | -->| TABLEAU DOUBLE PREC. SERVANT A LIRE LES RESULTATS
! | ELISEC         | -->| INDICATEUR ELIMINATION DES ELEMENTS SECS
! | ELPSEC         | -->| INDICATEUR ELIM DES ELEMENTS PARTIELLEMENT SECS
! | SEUSEC         | -->| VALEUR POUR LA DEFINITION SECHERESSE
! | ISDRY          | -->| TABLEAU D'INDICATEURS HAUTEUR NULLE
! | IHAUT          | -->| INDICE DE LA HAUTEUR_D_EAU DANS LA LISTE DES VARIABLES
! |________________|____|______________________________________________
! | COMMON:        |    |
! |  GEO:          |    |
! |    MESH        | -->| TYPE DES ELEMENTS DU MAILLAGE
! |    NDP         | -->| NOMBRE DE NOEUDS PAR ELEMENTS
! |    NPOIN       | -->| NOMBRE TOTAL DE NOEUDS DU MAILLAGE
! |    NELEM       | -->| NOMBRE TOTAL D'ELEMENTS DU MAILLAGE
! |    NPMAX       | -->| DIMENSION EFFECTIVE DES TABLEAUX X ET Y
! |                |    | (NPMAX = NPOIN + 0.1*NELEM)
! |    NELMAX      | -->| DIMENSION EFFECTIVE DES TABLEAUX CONCERNANT
! |                |    | LES ELEMENTS (NELMAX = NELEM + 0.2*NELEM)
! |  FICH:         |    |
! |    NRES        |--> | NUMERO DU CANAL DU FICHIER DE SERAFIN
! |    NGEO       |--> | NUMERO DU CANAL DU FICHIER MAILLEUR
! |    NLIM      |--> | NUMERO DU CANAL DU FICHIER DYNAM DE TELEMAC
! |    NFO1      |--> | NUMERO DU CANAL DU FICHIER TRIANGLE TRIGRID
! |  SECT:         |    |
! |    NSEC11      |--> | INDICATEUR DU SECTEUR CONTENANT LES NOEUDS
! |                |--> | (LECTURE EN SIMPLE PRECISION)
! |    NSEC12      |--> | INDICATEUR DU SECTEUR CONTENANT LES NOEUDS
! |                |--> | (LECTURE EN DOUBLE PRECISION)
! |    NSEC2       |--> | INDICATEUR DU SECTEUR CONTENANT LES ELEMENTS
! |    NSEC3       |--> | INDICATEUR DU SECTEUR CONTENANT LE TITRE
! |________________|____|______________________________________________
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE)
!-----------------------------------------------------------------------
! APPELE PAR : HOMERE
! APPEL DE : LECSIM, LECSTB, IMPRIM , VERIFI, VOISIN, RANBO, SURCON,
!            SHUFLE, CORDEP, DEPARR, PROJEC, PRESEL, FMTSEL, ECRSEL,
!            DYNAMI
!***********************************************************************
!
!     USE BIEF
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_STBTEL
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
      INTEGER NPOIN1 , NPOIN , NELEM , IELM
      INTEGER NELMAX , MESH , NPTFR , NITER
      INTEGER NDEPAR , NPMAX , NDP
!
!     TABLEAU BIDON UTILISE PAR VOISIN SEULEMENT EN PARALLELISME
      INTEGER NACHB(1)
!
      INTEGER NFOND(5)
      INTEGER STAND , NSFOND
      INTEGER NVAR , NVARCL
      INTEGER NPINIT , NEINIT
      INTEGER NUMPB(100), NBPB, I,IPARAM(10)
      DATA IPARAM/0,0,0,0,0,0,0,0,0,0/
!
      REAL, DIMENSION(:), ALLOCATABLE :: W
      DOUBLE PRECISION,DIMENSION(:)  ,ALLOCATABLE :: WORK,X,Y,ZF
      DOUBLE PRECISION,DIMENSION(:)  ,ALLOCATABLE :: XR,YR,ZR
      DOUBLE PRECISION,DIMENSION(:)  ,ALLOCATABLE :: XINIT,YINIT
      DOUBLE PRECISION,DIMENSION(:)  ,ALLOCATABLE :: VAINIT,VAR
      DOUBLE PRECISION,DIMENSION(:,:),ALLOCATABLE :: SHP
      INTEGER, DIMENSION(:)  , ALLOCATABLE :: TRAV1,TRAV2,TRAV3
      INTEGER, DIMENSION(:,:), ALLOCATABLE :: IKLE,IFABOR,IKINIT
      INTEGER, DIMENSION(:)  , ALLOCATABLE :: NBOR,KP1BOR,LIUBOR
      INTEGER, DIMENSION(:)  , ALLOCATABLE :: LIVBOR,LITBOR,LIHBOR
      INTEGER, DIMENSION(:)  , ALLOCATABLE :: ELT,NCOLOR,NCOLFR,NOP5
      INTEGER, DIMENSION(:),ALLOCATABLE :: TFAST1,TFAST2,ISDRY,IPOBO
!
      CHARACTER*80 TITRE
      CHARACTER*11 TYPELE
!
      CHARACTER*6  PRECIS
      CHARACTER*32 TEXTE(26) , VARCLA(1)
!
      LOGICAL SORLEO(26)
      LOGICAL SUIT , ECRI , DEBU , LISTIN
!
      INTEGER DATE(3) , TIME(3)
      DOUBLE PRECISION TPSFIN(1)
      INTEGER NVARIN , NVAROU , NVAR2 ,ERR
      INTEGER NSOR , MXPTVS , MXELVS
!
      COMMON/GEO/ MESH , NDP , NPOIN , NELEM , NPMAX , NELMAX
!
!     ALLOCATION DYNAMIQUE DES TABLEAUX REELS
!
      ALLOCATE(W(NPOIN)       ,STAT=ERR)
      ALLOCATE(WORK(NPOIN)    ,STAT=ERR)
      ALLOCATE(X(NPMAX)       ,STAT=ERR)
      ALLOCATE(Y(NPMAX)       ,STAT=ERR)
      ALLOCATE(ZF(NPMAX)      ,STAT=ERR)
      ALLOCATE(XR(NBAT)       ,STAT=ERR)
      ALLOCATE(YR(NBAT)       ,STAT=ERR)
      ALLOCATE(ZR(NBAT)       ,STAT=ERR)
      ALLOCATE(XINIT(NPOIN)   ,STAT=ERR)
      ALLOCATE(YINIT(NPOIN)   ,STAT=ERR)
      ALLOCATE(VAINIT(NPOIN)  ,STAT=ERR)
      ALLOCATE(VAR(NPMAX)     ,STAT=ERR)
      ALLOCATE(SHP(NPMAX,3)   ,STAT=ERR)
      ALLOCATE(NOP5(INOP5)    ,STAT=ERR)
!
      IF(ERR.NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,7000) ERR
        IF(LNG.EQ.2) WRITE(LU,8000) ERR
7000    FORMAT(1X,'STBTEL : ERREUR A L''ALLOCATION DE MEMOIRE : ',/,1X,
     &            'CODE D''ERREUR : ',1I6)
8000    FORMAT(1X,'STBTEL: ERROR DURING ALLOCATION OF MEMORY: ',/,1X,
     &            'ERROR CODE: ',1I6)
        CALL PLANTE(1)
        STOP
      ENDIF
!
!     ALLOCATION DYNAMIQUE DES TABLEAUX ENTIERS
!
      ALLOCATE(TRAV1(4*NELMAX)  ,STAT=ERR)
      ALLOCATE(TRAV2(4*NELMAX)  ,STAT=ERR)
      ALLOCATE(TRAV3(NPMAX)     ,STAT=ERR)
      ALLOCATE(NCOLOR(NPMAX)    ,STAT=ERR)
      ALLOCATE(IKLE(NELMAX,4)   ,STAT=ERR)
      ALLOCATE(IKINIT(NELEM,3)  ,STAT=ERR)
      ALLOCATE(IFABOR(NELMAX,4) ,STAT=ERR)
      ALLOCATE(ELT(NPMAX)       ,STAT=ERR)
      ALLOCATE(TFAST1(NPMAX)    ,STAT=ERR)
      ALLOCATE(TFAST2(NPMAX)    ,STAT=ERR)
      ALLOCATE(ISDRY(NPMAX)     ,STAT=ERR)
!     NPTFR REMPLACE PAR NPMAX (VALEUR PAR EXCES)
      ALLOCATE(NBOR(NPMAX)      ,STAT=ERR)
      ALLOCATE(KP1BOR(NPMAX)    ,STAT=ERR)
      ALLOCATE(LIUBOR(NPMAX)    ,STAT=ERR)
      ALLOCATE(LIVBOR(NPMAX)    ,STAT=ERR)
      ALLOCATE(LITBOR(NPMAX)    ,STAT=ERR)
      ALLOCATE(LIHBOR(NPMAX)    ,STAT=ERR)
      ALLOCATE(NCOLFR(NPMAX)    ,STAT=ERR)
!
      IF(ERR.NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,7000) ERR
        IF(LNG.EQ.2) WRITE(LU,8000) ERR
        CALL PLANTE(1)
        STOP
      ENDIF
!
!=======================================================================
! LECTURE DES COORDONNEES ET DE LA COULEUR DES POINTS , DES IKLE ET DU
! TITRE DU MAILLAGE
!=======================================================================
!
      NVARIN = 0
!
      IF (MAILLE.EQ.'SELAFIN') THEN
        ALLOCATE(IPOBO(NPOIN)     ,STAT=ERR)
        IF(ERR.NE.0) THEN
          IF(LNG.EQ.1) WRITE(LU,7000) ERR
          IF(LNG.EQ.2) WRITE(LU,8000) ERR
          CALL PLANTE(1)
          STOP
        ENDIF
        CALL LECSEL (XINIT,YINIT,IKINIT,NPINIT,NEINIT,X,Y,IKLE,TRAV1,
     &               W,TITRE,TEXTE,NVARIN,NVAR2,STD,NCOLOR,FUSION,
     &               NGEO,NFO1,IPOBO,IPARAM,DATE,TIME)
      ELSEIF (MAILLE.EQ.'ADCIRC') THEN
        CALL LECADC (X,Y,ZF,IKLE,NGEO)
        NSFOND=1
      ELSEIF (MAILLE.EQ.'SIMAIL') THEN
        CALL LECSIM (X,Y,IKLE,NCOLOR,TITRE,NOP5,NGEO)
      ELSEIF (MAILLE.EQ.'TRIGRID') THEN
        CALL LECTRI (X,Y,IKLE,NCOLOR,NGEO,NFO1)
        TITRE = 'MAILLAGE TRIGRID'
      ELSEIF (MAILLE.EQ.'FASTTABS') THEN
        CALL LECFAS (X,Y,IKLE, NCOLOR, TFAST1, TFAST2, ADDFAS,
     &               NGEO , NFO1)
        TITRE = 'MAILLAGE FASTTABS'
      ELSE
        CALL LECSTB (X,Y,IKLE,NCOLOR,TITRE,NPOIN1,
     &               NGEO,NSEC2,NSEC3,NSEC11,NSEC12)
      ENDIF
!
!=======================================================================
! EXTRACTION D'UN MAILLAGE
!=======================================================================
!
      IF(MESH.EQ.3.AND.NSOM.GE.3)
     &   CALL EXTRAC (X,Y,SOM,IKLE,TRAV1,NELEM,NELMAX,NPOIN,NSOM,PROJEX)
!
!=======================================================================
! IMPRESSION DES DONNEES GEOMETRIQUES
!=======================================================================
!
      CALL IMPRIM (NPOIN1,NPOIN,TYPELE,NELEM,TITRE,MAILLE,PRECIS)
!
!=======================================================================
! DIVISION PAR 4 DE TOUTE OU PARTIE DES MAILLES
!=======================================================================
!
      IF(MESH.EQ.3.AND.DIV4) THEN
        CALL DIVISE (X,Y,IKLE,NCOLOR,NPOIN,NELEM,NELMAX,NSOM2,SOM2,
     &               TRAV1,TRAV2)
      ELSE
        IF (DIV4.AND.LNG.EQ.1) WRITE(LU,901)
        IF (DIV4.AND.LNG.EQ.2) WRITE(LU,3901)
      ENDIF
!
!
!=======================================================================
! OPTION ELIMINATION DES ELEMENTS SECS OU PARTIELLEMENT SECS
!=======================================================================
!
      IF (ELISEC) THEN
        IF (MESH.EQ.3) THEN
          IF (LNG.EQ.1) WRITE(LU,3006)
          IF (LNG.EQ.2) WRITE(LU,3007)
          CALL ELMSEC ( ELPSEC, SEUSEC, TPSFIN, X, Y, IKLE,
     &    NCOLOR, ISDRY, IHAUT, NVARIN, VAR, W , TRAV2, STD ,NGEO)
!
! APRES ELIMINATION, ON RECHERCHE LES POINTS FRONTIERES POSANT PROBLEME
!
          CALL VERIFI (X,Y,IKLE,NCOLOR,TRAV1,EPSI)
          IELM = 11
          CALL VOISIN(IFABOR,NELEM,NELMAX,IELM,IKLE,NELMAX,NPOIN,
     &                       NACHB,NBOR,NPTFR,TRAV1,TRAV2)
          CALL VERIFS (IFABOR,IKLE,TRAV1,NPTFR,NUMPB,NBPB)
          IF (NBPB.GT.0) THEN
            DO I=1,NBPB
              IF (LNG.EQ.1) WRITE(LU,3000) NUMPB(I)
              IF (LNG.EQ.2) WRITE(LU,3001) NUMPB(I)
            ENDDO
            CALL ELMPB (NBPB, NUMPB, X,Y,IKLE,NCOLOR,ISDRY,TRAV2)
           ELSE
            IF (LNG.EQ.1) WRITE(LU,3008)
            IF (LNG.EQ.2) WRITE(LU,3009)
          ENDIF
        ELSE
          IF (LNG.EQ.1) WRITE(LU,2002)
          IF (LNG.EQ.2) WRITE(LU,4002)
        ENDIF
      ENDIF
!
!=======================================================================
! MISE AU FORMAT TELEMAC DU MAILLAGE
!=======================================================================
!
      CALL VERIFI(X,Y,IKLE,NCOLOR,TRAV1,EPSI)
!
!=======================================================================
! CONSTRUCTION DU TABLEAU IFABOR
!=======================================================================
!
      IELM = 21
      IF (MESH.EQ.3) IELM = 11
!
      CALL VOISIN(IFABOR,NELEM,NELMAX,IELM,IKLE,NELMAX,NPOIN,
     &                   NACHB,NBOR,NPTFR,TRAV1,TRAV2)
!
!=======================================================================
! CONSTRUCTION DE LA TABLE DES POINTS DE BORD
!    (RANGES DANS L'ORDRE TRIGONOMETRIQUE POUR LE CONTOUR
!     ET L'ORDRE INVERSE POUR LES ILES)
!=======================================================================
!
      CALL RANBO (NBOR,KP1BOR,IFABOR,IKLE,NCOLOR,TRAV1,NPTFR,X,Y,NCOLFR)
!
!=======================================================================
! ELIMINATION DES TRIANGLES SURCONTRAINTS
!=======================================================================
!
      IF(MESH.EQ.3.AND.DECTRI) THEN
!
        CALL SURCON (X,Y,IKLE,TRAV1,NBOR,NPTFR,NCOLOR,IFABOR,COLOR)
!
      ELSE
        IF (DECTRI.AND.LNG.EQ.1) WRITE(LU,900)
        IF (DECTRI.AND.LNG.EQ.2) WRITE(LU,3900)
      ENDIF
!
!=======================================================================
! RENUMEROTATION DES NOEUDS POUR OPTIMISATION D'ASSEMBLAGE
!=======================================================================
!
      IF(OPTASS) THEN
        CALL RENUM
     &  (X,Y,WORK,IKLE,NBOR,TRAV1,TRAV2,TRAV3,NCOLOR,COLOR,NPTFR)
      ENDIF
!
!=======================================================================
! RENUMEROTATION DES ELEMENTS POUR EVITER LES DEPENDENCES ARRIERES
!=======================================================================
!
      IF (ELIDEP) THEN
!
        IF (LNG.EQ.1) WRITE(LU,3010)
        IF (LNG.EQ.2) WRITE(LU,3011)
        CALL SHUFLE (IKLE,X)
!
        NITER = 0
!
10      CONTINUE
!
        CALL CORDEP (IKLE,LGVEC)
!
!=======================================================================
! VERIFICATION DES DEPENDANCES ARRIERES
!=======================================================================
!
        CALL DEPARR (IKLE,NDEPAR,LGVEC)
        IF(NDEPAR.NE.0) THEN
           NITER = NITER + 1
           IF (NITER.GT.50) THEN
              IF (LNG.EQ.1) WRITE(LU,1000)
              IF (LNG.EQ.2) WRITE(LU,4000)
              CALL PLANTE(1)
              STOP
           ENDIF
           GOTO 10
        ENDIF
!
        IF (LNG.EQ.1) WRITE(LU,1100) NITER
        IF (LNG.EQ.2) WRITE(LU,4100) NITER
!
      ENDIF
!
!=======================================================================
! PROJECTION DES FONDS SUR LE MAILLAGE
!=======================================================================
!
      IF(NBFOND.NE.0) THEN
        CALL PROJEC (X,Y,ZF,XR,YR,ZR,NBAT,NBOR,NPTFR,NFOND,NBFOND,
     &               FOND,DM,FONTRI,CORTRI,MAILLE,NGEO,KP1BOR)
      ENDIF
!
!=======================================================================
! CONSTRUCTION DU FICHIER DE GEOMETRIE AU FORMAT SELAFIN :
!=======================================================================
!
      IF (LNG.EQ.1) WRITE(LU,3002)
      IF (LNG.EQ.2) WRITE(LU,3003)
      STAND = 3
      NVARCL= 0
      DEBU  = .FALSE.
      SUIT  = .FALSE.
      ECRI  = .TRUE.
      LISTIN= .TRUE.
!
      NSOR = 26
!     SI LA DATE MANQUE
      IF(IPARAM(10).EQ.0) THEN
        DATE(1) = 0
        DATE(2) = 0
        DATE(3) = 0
        TIME(1) = 0
        TIME(2) = 0
        TIME(3) = 0
      ENDIF
!
      CALL PRESEL(IKLE,TRAV1,NELEM,NELMAX,NDP,TEXTE,NBFOND,SORLEO,
     &            COLOR,NSFOND,NVARIN,NVAROU,MAILLE)
!
!  ATTENTION DANS L'APPEL A FM3SEL, LE VRAI IKLE EST TRAV1
!  ET IKLE EST EMPLOYE COMME TABLEAU DE TRAVAIL.
!
      CALL FM3SEL(X,Y,NPOIN,NBOR,NRES,STD,NVAR,TEXTE,TEXTE,
     &            VARCLA,NVARCL,TITRE,SORLEO,NSOR,W,TRAV1,IKLE,
     &            TRAV2,NELEM,NPTFR,NDP,MXPTVS,MXELVS,DATE,TIME,
     &            DEBU,SUIT,ECRI,LISTIN,IPARAM,IPOBO)
!
!  INTERPOLATION DES VARIABLES DU FICHIER D'ENTREE
!
      IF (MAILLE.EQ.'SELAFIN') CALL INTERP
     &   (XINIT,YINIT,IKINIT,NPINIT,NEINIT,X,Y,NPOIN,NPMAX,SHP,ELT)
!
      IF (ELISEC) THEN
!       ECRITURE DES VARIABLES DE SORTIE AU FORMAT RESULTAT TELEMAC-2D
!
        CALL ECRRES (VAINIT,IKINIT,NPINIT,NEINIT,SHP,ELT,NPOIN,NPOIN1,
     &             NPMAX,W,X,ZF,NSFOND,NCOLOR,COLOR,VAR,NVARIN,NVAROU,
     &             STD, NDP, TRAV1, STOTOT, TPSFIN,NGEO,NRES)
      ELSE
!
!       ECRITURE DES VARIABLES DE SORTIE AU FORMAT SELAFIN
!
        CALL ECRSEL(VAINIT,IKINIT,NPINIT,NEINIT,SHP,ELT,NPOIN,NPOIN1,
     &             NPMAX,W,X,ZF,NSFOND,NCOLOR,COLOR,VAR,NVARIN,NVAROU,
     &             NVAR2,STD,FUSION,NRES,NGEO,NFO1,MAILLE)
      ENDIF
!
!=======================================================================
! CONSTRUCTION DU FICHIER DYNAM DE TELEMAC
!=======================================================================
!
      IF (LNG.EQ.1) WRITE(LU,3004)
      IF (LNG.EQ.2) WRITE(LU,3005)
      CALL DYNAMI (NPTFR,NBOR,LIHBOR,LIUBOR,LIVBOR,LITBOR,
     &            NCOLFR,MAILLE,NLIM)
!
  900 FORMAT(//,'********************************************',/,
     &          'L''ELIMINATION DES ELEMENTS SURCONTRAINTS EST',/,
     &          'PREVU UNIQUEMENT DANS LE CAS DES TRIANGLES',/,
     &          '********************************************',/)
 3900 FORMAT(//,'********************************************',/,
     &          'OVERSTRESSED ELEMENTS ARE CANCELLED ONLY IN',/,
     &          'THE CASE OF TRIANGLES                     ',/,
     &          '********************************************',/)
  901 FORMAT(//,'********************************************',/,
     &          'LA DIVISION PAR 4 DE TOUTES LES MAILLES EST',/,
     &          'PREVU UNIQUEMENT DANS LE CAS DES TRIANGLES',/,
     &          '********************************************',/)
 3901 FORMAT(//,'********************************************',/,
     &          'ELEMENTS CAN BE CUT IN FOUR ONLY IN',/,
     &          'THE CASE OF TRIANGLES                     ',/,
     &          '********************************************',/)
 1000 FORMAT(//,'***********************************************',/,
     &          'ECHEC DANS L''ELIMINATION DES DEPENDANCES     ',/,
     &          'ARRIERES (NOMBRE DE TENTATIVES : 50)           ',/,
     &          'IL DOIT Y AVOIR TROP PEU DE NOEUDS DE MAILLAGE ',/,
     &          '***********************************************')
 4000 FORMAT(//,'***********************************************',/,
     &          'FAILURE IN CANCELLING BACKWARD DEPENDENCIES    ',/,
     &          '         (NUMBER OF ATTEMPTS : 50)             ',/,
     &          'THERE MUST BE TOO FEW NODES IN THE MESH        ',/,
     &          '***********************************************')
 1100 FORMAT(1X,'ELIMINATION DES DEPENDANCES ARRIERES APRES ',I2,
     &          ' TENTATIVE(S)')
 4100 FORMAT(1X,'BACKWARD DEPENDENCIES ARE CANCELLED AFTER ',I2,
     &          ' ATTEMPTS')
!
 2002 FORMAT(//,'***********************************************',/,
     &          'ELIMINATION DES ELEMENTS SECS DU MAILLAGE ',/,
     &          'NON IMPLANTEE SUR MAILLAGE NON TRIANGULAIRE. ',/,
     &          '***********************************************')
 4002 FORMAT(//,'***********************************************',/,
     &          'MESH DRY ELEMENT SUPPRESION NOT AVAILABLE FOR ',
     &          'NON TRIANGULAR MESH.',/,
     &          '***********************************************')
!
 3000 FORMAT(1X,'LE POINT NUMERO ',I6,' EST A ELIMINER')
 3001 FORMAT(1X,'THE POINT NUMBER ',I6,' HAS TO BE REMOVED')
 3002 FORMAT(//,1X,'GENERATION DU FICHIER DE GEOMETRIE',/,
     &         1X,'----------------------------------')
 3003 FORMAT(//,1X,'GENERATING GEOMETRY FILE',/,
     &         1X,'------------------------')
 3004 FORMAT(//,1X,'TRAITEMENT DES CONDITIONS AUX LIMITES',/,
     &         1X,'-------------------------------------')
 3005 FORMAT(//,1X,'TREATMENT OF BOUNDARY CONDITIONS',/,
     &         1X,'--------------------------------')
 3006 FORMAT(//,1X,'ELIMINATION DES ELEMENTS SECS DU MAILLAGE',
     &        /,1X,'-----------------------------------------',/)
 3007 FORMAT(//,1X,'MESH DRY ELEMENT SUPPRESSION',
     &        /,1X,'----------------------------',/)
 3008 FORMAT(/,1X,'AUCUNE ILE CONNECTEE')
 3009 FORMAT(/,1X,'NO CONNECTED ISLAND')
 3010 FORMAT(//,1X,'ELIMINATION DES DEPENDANCES ARRIERES',
     &        /,1X,'------------------------------------',/)
 3011 FORMAT(//,1X,'ELIMINATION OK BACKWARDS DEPENDENCIES',
     &        /,1X,'------------------------------------',/)
!
      DEALLOCATE(W)
      DEALLOCATE(WORK)
      DEALLOCATE(TRAV1)
      DEALLOCATE(TRAV2)
      DEALLOCATE(TRAV3)
!
!-----------------------------------------------------------------------
!
      RETURN
      END
