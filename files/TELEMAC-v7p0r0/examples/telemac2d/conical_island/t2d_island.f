!                       **************************** 
                        DOUBLE PRECISION FUNCTION SL 
!                       **************************** 
! 
! 
     &( I , N ) 
! 
!*********************************************************************** 
!  TELEMAC 2D VERSION 5.0    17/08/94    J-M HERVOUET (LNH) 30 87 80 18 
! 
!*********************************************************************** 
! 
! FONCTION  : DONNE LA VALEUR DE LA COTE DE LA SURFACE LIBRE POUR TOUTES 
!             LES ENTREES A COTE IMPOSEE. 
! 
!----------------------------------------------------------------------- 
!                             ARGUMENTS 
! .________________.____.______________________________________________. 
! |      NOM       |MODE|                   ROLE                       | 
! |________________|____|______________________________________________| 
! |   I            | -->| RANG DE LA FRONTIERE A COTE IMPOSEE 
! |                |    | (1 S'IL N'Y EN A QU'UNE) 
! |   N            | -->| NUMERO GLOBAL DU POINT 
! |________________|____|_______________________________________________ 
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE) 
! 
!----------------------------------------------------------------------- 
! 
!  APPELE PAR : BORD 
! 
!*********************************************************************** 
! 
      USE BIEF 
      USE DECLARATIONS_TELEMAC 
      USE DECLARATIONS_TELEMAC2D 
! 
      IMPLICIT NONE 
      INTEGER LNG,LU 
      COMMON/INFO/LNG,LU 
      DOUBLE PRECISION A,WPLG,PER, PI, T0, WH, WD, K, C, G
! 
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
! 
      INTEGER, INTENT(IN) :: I,N 
! 
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
! 
      CHARACTER*8 FCT 
      INTEGER J 
      LOGICAL DEJA,OK(MAXFRO) 
      DATA    DEJA /.FALSE./ 
      SAVE    OK,DEJA 
! 
!     FIRST CALL, OK INITIALISED TO .TRUE. 
! 
      IF(.NOT.DEJA) THEN 
        DO J=1,MAXFRO 
          OK(J)=.TRUE. 
        ENDDO 
        DEJA=.TRUE. 
      ENDIF 
! 
!----------------------------------------------------------------------- 
! 
!     IF FILE OF LIQUID BOUNDARIES EXISTING, ATTEMPT TO FIND 
!     THE VALUE IN IT. IF YES, OK REMAINS TO .TRUE. FOR NEXT CALLS 
!                      IF  NO, OK SET     TO .FALSE. 
! 
      IF(OK(I).AND.T2D_FILES(T2DIMP)%NAME(1:1).NE.' ') THEN 
! 
!       FCT WILL BE SL(1), SL(2), ETC, SL(99), DEPENDING ON I 
        FCT(1:3)='SL(' 
        IF(I.LT.10) THEN  
          WRITE(FCT(4:4),FMT='(I1)') I 
          FCT(5:8)=')   ' 
        ELSEIF(I.LT.100) THEN 
          WRITE(FCT(4:5),FMT='(I2)') I 
          FCT(6:8)=')  ' 
        ELSE 
          STOP 'SL NOT PROGRAMMED FOR MORE THAN 99 BOUNDARIES' 
        ENDIF 
        CALL READ_FIC_FRLIQ(SL,FCT,AT,T2D_FILES(T2DIMP)%LU,ENTET,OK(I)) 
! 
      ENDIF 
! 
      IF(.NOT.OK(I).OR.T2D_FILES(T2DIMP)%NAME(1:1).EQ.' ') THEN 
!  
!     PROGRAMMABLE PART                               
!     SL IS TAKEN IN THE PARAMETER FILE, BUT MAY BE CHANGED  
!           
        PI = 3.141592653589D0 
        T0 = 10 
        WD=0.32D0 
        WH=WD*0.045D0 
! 
        K=SQRT((3*WH)/(4*(WD**3))) 
        G=9.8D0 
        C=SQRT(G*(WD+WH)) 
        SL= WD+ WH*(1/((COSH(K*(C*AT-T0)))**2)) 
 
      ENDIF            
! 
!----------------------------------------------------------------------- 
! 
      RETURN 
      END 
!                       *************************** 
                        SUBROUTINE PRERES_TELEMAC2D 
!                       *************************** 
! 
!*********************************************************************** 
!  TELEMAC 2D VERSION 5.0    17/08/94    J-M HERVOUET (LNH) 30 87 80 18 
! 
!*********************************************************************** 
! 
!     FONCTION  : PREPARATION DE VARIABLES QUI SERONT ECRITES SUR 
!                 LE FICHIER DE RESULTATS OU SUR LE LISTING. 
! 
!----------------------------------------------------------------------- 
!                             ARGUMENTS 
! .________________.____.______________________________________________. 
! |      NOM       |MODE|                   ROLE                       | 
! |________________|____|______________________________________________| 
! |      LT        | -->| NUMERO D'ITERATION 
! |________________|____|______________________________________________| 
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE) 
! 
!----------------------------------------------------------------------- 
! 
!  APPELE PAR : TELMAC 
! 
!  SOUS-PROGRAMME APPELE : OV 
! 
!*********************************************************************** 
! 
      USE BIEF 
      USE DECLARATIONS_TELEMAC2D 
! 
      IMPLICIT NONE 
      INTEGER LNG,LU 
      COMMON/INFO/LNG,LU 
! 
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
! 
! 
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
!      
      LOGICAL IMP,LEO 
! 
      INTEGER LTT,N,IMAX 
! 
      DOUBLE PRECISION HHPLG,XMAX 
      DOUBLE PRECISION PI, PER, WPLG, A, B, PHI 
! 
      INTRINSIC MAX,SQRT 
! 
!----------------------------------------------------------------------- 
! 
! LOGIQUES POUR DECIDER DES SORTIES 
! 
      IMP=.FALSE. 
      LEO=.FALSE. 
      LTT=(LT/LISPRD)*LISPRD 
      IF((LT.EQ.LTT.OR.LT.EQ.NIT).AND.LT.GE.PTINIL) IMP=.TRUE. 
      LTT=(LT/LEOPRD)*LEOPRD 
      IF((LT.EQ.LTT.OR.LT.EQ.NIT).AND.LT.GE.PTINIG) LEO=.TRUE. 
! 
!     PAS D'IMPRESSION, PAS DE SORTIE SUR FICHIER, ON RESSORT 
      IF(.NOT.(LEO.OR.IMP)) GO TO 1000 
! 
! 
!======================================================================= 
! CALCUL DE LA CELERITE (MISE DANS FU, VOIR LE BLOC VARSOR) 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(3)).OR.(IMP.AND.SORIMP(3))) THEN 
        DO N=1,NPOIN 
          FU%R(N) = SQRT ( GRAV * MAX(H%R(N),0.D0) ) 
        ENDDO 
      ENDIF 
! 
!======================================================================= 
! CALCUL DE LA SURFACE LIBRE (= H + ZF, MISE DANS FV) 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(5)).OR.(IMP.AND.SORIMP(5))) THEN 
        CALL OS( 'X=Y+Z   ' , FV , H , ZF , 0.D0 ) 
      ENDIF 
! 
!======================================================================= 
! CALCUL DU NOMBRE DE FROUDE 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(7)).OR.(IMP.AND.SORIMP(7))) THEN 
        DO N=1,NPOIN 
          HHPLG = MAX( H%R(N) , 1.D-8 ) 
          T2%R(N) = SQRT (( U%R(N)**2 + V%R(N)**2 ) / ( HHPLG*GRAV )) 
        ENDDO 
      ENDIF 
! 
!======================================================================= 
! CALCUL DU DEBIT SCALAIRE 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(8)).OR.(IMP.AND.SORIMP(8))) THEN 
        DO N=1,NPOIN 
          T3%R(N) = SQRT (U%R(N)**2 + V%R(N)**2) * H%R(N) 
        ENDDO 
      ENDIF 
! 
!======================================================================= 
! CALCUL DU DEBIT VECTORIEL , COMPOSANTE SUIVANT X 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(13)).OR.(IMP.AND.SORIMP(13))) THEN 
        CALL OS( 'X=YZ    ' , T4 , H , U , HHPLG ) 
      ENDIF 
! 
!======================================================================= 
! CALCUL DU DEBIT VECTORIEL , COMPOSANTE SUIVANT Y 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(14)).OR.(IMP.AND.SORIMP(14))) THEN 
        CALL OS( 'X=YZ    ' , T5 , H , V , HHPLG ) 
      ENDIF 
! 
!======================================================================= 
! CALCUL DE LA VITESSE SCALAIRE 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(15)).OR.(IMP.AND.SORIMP(15))) THEN 
        CALL OS( 'X=N(Y,Z)' , T6 , U , V , HHPLG ) 
      ENDIF 
! 
!======================================================================= 
! CALCUL DU NOMBRE DE COURANT 
!======================================================================= 
! 
      IF((LEO.AND.SORLEO(22)).OR.(IMP.AND.SORIMP(22))) THEN 
!                             IELM 
        CALL CFLPSI(T9,U,V,DT,11,MESH,MSK,MASKEL) 
        CALL MAXI(XMAX,IMAX,T9%R,NPOIN) 
        IF (LNG.EQ.1) WRITE(LU,78) XMAX 
        IF (LNG.EQ.2) WRITE(LU,79) XMAX 
78      FORMAT(1X,'PRERES : NOMBRE DE COURANT MAXIMUM :',G16.7) 
79      FORMAT(1X,'PRERES: MAXIMUM COURANT NUMBER: ',G16.7) 
      ENDIF 
!            
!======================================================================= 
! CALCUL DE LA SOLUTION ANALYTIQUE                                        
!======================================================================= 
!   
        PI = 3.141592653589D0
        PER=0.5                                            
        WPLG=2.*PI/PER 
        A=0.39     
!                                                                            
      IF((LEO.AND.SORLEO(23)).OR.(IMP.AND.SORIMP(23))) THEN  
        DO N = 1, NPOIN 
          PHI = X(N)/SQRT(9.81*10.) 
          B = (2.*PI*(AT-PHI))/PER 
          IF (AT.LE.PHI) THEN 
            PRIVE%ADR(1)%P%R(N) = 10. 
          ELSE 
            PRIVE%ADR(1)%P%R(N) = 10. + A*SIN(B) 
          ENDIF    
        ENDDO     
      ENDIF                                                          
! 
!======================================================================= 
! 
1000  CONTINUE 
      RETURN 
      END  
!                       *************************** 
                        SUBROUTINE NOMVAR_TELEMAC2D 
!                       *************************** 
! 
     &(TEXTE,TEXTPR,MNEMO,NPERIAF) 
! 
!*********************************************************************** 
!  TELEMAC 2D VERSION 5.2    17/08/94    J-M HERVOUET (LNH) 30 87 80 18 
! 
!*********************************************************************** 
! 
! FONCTION  :  FIXE LES NOMS DES VARIABLES DU CODE POUR LES FICHIERS 
!              DE RESULTAT ET DE GEOMETRIE (TEXTE) ET POUR LE FICHIER 
!              DE RESULTATS DU CALCUL PRECEDENT (TEXTPR) 
! 
!              EN GENERAL TEXTE ET TEXTPR SONT EGAUX SAUF SI ON FAIT 
!              UNE SUITE A PARTIR D'UN AUTRE LOGICIEL. 
! 
!----------------------------------------------------------------------- 
!                             ARGUMENTS 
! .________________.____.______________________________________________. 
! |      NOM       |MODE|                   ROLE | 
! |________________|____|______________________________________________| 
! |   TEXTE        |<-- | NOM DES VARIABLES 
! |   TEXTPR       |<-- | NOM DES VARIABLES DU CALCUL PRECEDENT 
! |________________|____|______________________________________________| 
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE) 
! 
!----------------------------------------------------------------------- 
! 
! APPELE PAR : PREDON 
! 
! SOUS-PROGAMME APPELE : NEANT 
! 
!********************************************************************** 
! 
      IMPLICIT NONE 
      INTEGER LNG,LU 
      COMMON/INFO/LNG,LU 
! 
      CHARACTER*32 TEXTE(*),TEXTPR(*) 
      CHARACTER*8  MNEMO(*) 
      INTEGER, INTENT(IN) :: NPERIAF 
! 
      CHARACTER(LEN=2) I_IN_2_LETTERS(32) 
      DATA I_IN_2_LETTERS /'1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ',
     &                     '10','11','12','13','14','15','16','17','18',
     &                     '19','20','21','22','23','24','25','26','27',
     &                     '28','29','30','31','32'/ 
      INTEGER I 
! 
!----------------------------------------------------------------------- 
! 
!  ENGLISH 
! 
      IF(LNG.EQ.2) THEN 
! 
      TEXTE (1 ) = 'VELOCITY U      M/S             ' 
      TEXTE (2 ) = 'VELOCITY V      M/S             ' 
      TEXTE (3 ) = 'CELERITY        M/S             ' 
      TEXTE (4 ) = 'WATER DEPTH     M               ' 
      TEXTE (5 ) = 'FREE SURFACE    M               ' 
      TEXTE (6 ) = 'BOTTOM          M               ' 
      TEXTE (7 ) = 'FROUDE NUMBER                   ' 
      TEXTE (8 ) = 'SCALAR FLOWRATE M2/S            ' 
      TEXTE (9 ) = 'TRACER                          ' 
      TEXTE (10) = 'TURBULENT ENERG.JOULE/KG        ' 
      TEXTE (11) = 'DISSIPATION     WATT/KG         ' 
      TEXTE (12) = 'VISCOSITY       M2/S            ' 
      TEXTE (13) = 'FLOWRATE ALONG XM2/S            ' 
      TEXTE (14) = 'FLOWRATE ALONG YM2/S            ' 
      TEXTE (15) = 'SCALAR VELOCITY M/S             ' 
      TEXTE (16) = 'WIND ALONG X    M/S             ' 
      TEXTE (17) = 'WIND ALONG Y    M/S             ' 
      TEXTE (18) = 'AIR PRESSURE    PASCAL          ' 
      TEXTE (19) = 'BOTTOM FRICTION                 ' 
      TEXTE (20) = 'DRIFT ALONG X   M               ' 
      TEXTE (21) = 'DRIFT ALONG Y   M               ' 
      TEXTE (22) = 'COURANT NUMBER                  ' 
      TEXTE (23) = 'SOLANAL                         '
      TEXTE (24) = 'VARIABLE 24     UNIT   ??       ' 
      TEXTE (25) = 'VARIABLE 25     UNIT   ??       ' 
      TEXTE (26) = 'VARIABLE 26     UNIT   ??       ' 
      TEXTE (27) = 'HIGH WATER MARK M               ' 
      TEXTE (28) = 'HIGH WATER TIME S               ' 
      TEXTE (29) = 'HIGHEST VELOCITYM/S             ' 
      TEXTE (30) = 'TIME OF HIGH VELS               ' 
! 
! TEXTPR IS USED FOR READING PREVIOUS COMPUTATION FILES. 
! IN GENERAL TEXTPR=TEXTE BUT YOU CAN FOLLOW UP A COMPUTATION 
! FROM ANOTHER CODE WITH DIFFERENT NAMES THAT YOU HAVE TO 
! WRITE HERE. 
! 
      TEXTPR (1 ) = 'VELOCITY U      M/S             ' 
      TEXTPR (2 ) = 'VELOCITY V      M/S             ' 
      TEXTPR (3 ) = 'CELERITY        M/S             ' 
      TEXTPR (4 ) = 'WATER DEPTH     M               ' 
      TEXTPR (5 ) = 'FREE SURFACE    M               ' 
      TEXTPR (6 ) = 'BOTTOM          M               ' 
      TEXTPR (7 ) = 'FROUDE NUMBER                   ' 
      TEXTPR (8 ) = 'SCALAR FLOWRATE M2/S            ' 
      TEXTPR (9 ) = 'TRACER                          ' 
      TEXTPR (10) = 'TURBULENT ENERG.JOULE/KG        ' 
      TEXTPR (11) = 'DISSIPATION     WATT/KG         ' 
      TEXTPR (12) = 'VISCOSITY       M2/S            ' 
      TEXTPR (13) = 'FLOWRATE ALONG XM2/S            ' 
      TEXTPR (14) = 'FLOWRATE ALONG YM2/S            ' 
      TEXTPR (15) = 'SCALAR VELOCITY M/S             ' 
      TEXTPR (16) = 'WIND ALONG X    M/S             ' 
      TEXTPR (17) = 'WIND ALONG Y    M/S             ' 
      TEXTPR (18) = 'AIR PRESSURE    PASCAL          ' 
      TEXTPR (19) = 'BOTTOM FRICTION                 ' 
      TEXTPR (20) = 'DRIFT ALONG X   M               ' 
      TEXTPR (21) = 'DRIFT ALONG Y   M               ' 
      TEXTPR (22) = 'COURANT NUMBER                  ' 
      TEXTPR (23) = 'VARIABLE 23     UNIT   ??       ' 
      TEXTPR (24) = 'VARIABLE 24     UNIT   ??       ' 
      TEXTPR (25) = 'VARIABLE 25     UNIT   ??       ' 
      TEXTPR (26) = 'VARIABLE 26     UNIT   ??       ' 
      TEXTPR (27) = 'HIGH WATER MARK M               ' 
      TEXTPR (28) = 'HIGH WATER TIME S               ' 
      TEXTPR (29) = 'HIGHEST VELOCITYM/S             ' 
      TEXTPR (30) = 'TIME OF HIGH VELS               ' 
! 
!----------------------------------------------------------------------- 
! 
!  FRANCAIS OU AUTRE 
! 
      ELSE 
! 
      TEXTE (1 ) = 'VITESSE U       M/S             ' 
      TEXTE (2 ) = 'VITESSE V       M/S             ' 
      TEXTE (3 ) = 'CELERITE        M/S             ' 
      TEXTE (4 ) = 'HAUTEUR D''EAU   M               ' 
      TEXTE (5 ) = 'SURFACE LIBRE   M               ' 
      TEXTE (6 ) = 'FOND            M               ' 
      TEXTE (7 ) = 'FROUDE                          ' 
      TEXTE (8 ) = 'DEBIT SCALAIRE  M2/S            ' 
      TEXTE (9 ) = 'TRACEUR                         ' 
      TEXTE (10) = 'ENERGIE TURBUL. JOULE/KG        ' 
      TEXTE (11) = 'DISSIPATION     WATT/KG         ' 
      TEXTE (12) = 'VISCOSITE TURB. M2/S            ' 
      TEXTE (13) = 'DEBIT SUIVANT X M2/S            ' 
      TEXTE (14) = 'DEBIT SUIVANT Y M2/S            ' 
      TEXTE (15) = 'VITESSE SCALAIREM/S             ' 
      TEXTE (16) = 'VENT X          M/S             ' 
      TEXTE (17) = 'VENT Y          M/S             ' 
      TEXTE (18) = 'PRESSION ATMOS. PASCAL          ' 
      TEXTE (19) = 'FROTTEMENT                      ' 
      TEXTE (20) = 'DERIVE EN X     M               ' 
      TEXTE (21) = 'DERIVE EN Y     M               ' 
      TEXTE (22) = 'NBRE DE COURANT                 ' 
      TEXTE (23) = 'VARIABLE 23     UNITES ??       ' 
      TEXTE (24) = 'VARIABLE 24     UNITES ??       ' 
      TEXTE (25) = 'VARIABLE 25     UNITES ??       ' 
      TEXTE (26) = 'VARIABLE 26     UNITES ??       ' 
      TEXTE (27) = 'COTE MAXIMUM    M               ' 
      TEXTE (28) = 'TEMPS COTE MAXI S               ' 
      TEXTE (29) = 'VITESSE MAXIMUM M/S             ' 
      TEXTE (30) = 'T VITESSE MAXI  S               ' 
! 
! TEXTPR SERT A LA LECTURE DES FICHIERS DE CALCULS PRECEDENTS 
! A PRIORI TEXTPR=TEXTE MAIS ON PEUT ESSAYER DE FAIRE UNE SUITE 
! DE CALCUL A PARTIR D'UN AUTRE CODE. 
! 
      TEXTPR (1 ) = 'VITESSE U       M/S             ' 
      TEXTPR (2 ) = 'VITESSE V       M/S             ' 
      TEXTPR (3 ) = 'CELERITE        M/S             ' 
      TEXTPR (4 ) = 'HAUTEUR D''EAU   M               ' 
      TEXTPR (5 ) = 'SURFACE LIBRE   M               ' 
      TEXTPR (6 ) = 'FOND            M               ' 
      TEXTPR (7 ) = 'FROUDE                          ' 
      TEXTPR (8 ) = 'DEBIT SCALAIRE  M2/S            ' 
      TEXTPR (9 ) = 'TRACEUR                         ' 
      TEXTPR (10) = 'ENERGIE TURBUL. JOULE/KG        ' 
      TEXTPR (11) = 'DISSIPATION     WATT/KG         ' 
      TEXTPR (12) = 'VISCOSITE TURB. M2/S            ' 
      TEXTPR (13) = 'DEBIT SUIVANT X M2/S            ' 
      TEXTPR (14) = 'DEBIT SUIVANT Y M2/S            ' 
      TEXTPR (15) = 'VITESSE SCALAIREM/S             ' 
      TEXTPR (16) = 'VENT X          M/S             ' 
      TEXTPR (17) = 'VENT Y          M/S             ' 
      TEXTPR (18) = 'PRESSION ATMOS. PASCAL          ' 
      TEXTPR (19) = 'FROTTEMENT                      ' 
      TEXTPR (20) = 'DERIVE EN X     M               ' 
      TEXTPR (21) = 'DERIVE EN Y     M               ' 
      TEXTPR (22) = 'NBRE DE COURANT                 ' 
      TEXTPR (23) = 'VARIABLE 23     UNITES ??       ' 
      TEXTPR (24) = 'VARIABLE 24     UNITES ??       ' 
      TEXTPR (25) = 'VARIABLE 25     UNITES ??       ' 
      TEXTPR (26) = 'VARIABLE 26     UNITES ??       ' 
      TEXTPR (27) = 'COTE MAXIMUM    M               ' 
      TEXTPR (28) = 'TEMPS COTE MAXI S               ' 
      TEXTPR (29) = 'VITESSE MAXIMUM M/S             ' 
      TEXTPR (30) = 'T VITESSE MAXI  S               ' 
! 
      ENDIF 
! 
!----------------------------------------------------------------------- 
! 
!   ALIAS DES NOMS DE VARIABLES POUR LE FICHIER DES PARAMETRES 
! 
!     UVCHSBFQTKEDIJMXYPWAGLNORZ 
!     VITESSE U 
      MNEMO(1)   = 'U       ' 
!     VITESSE V 
      MNEMO(2)   = 'V       ' 
!     CELERITE 
      MNEMO(3)   = 'C       ' 
!     HAUTEUR D'EAU 
      MNEMO(4)   = 'H       ' 
!     SURFACE LIBRE 
      MNEMO(5)   = 'S       ' 
!     FOND 
      MNEMO(6)   = 'B       ' 
!     FROUDE 
      MNEMO(7)   = 'F       ' 
!     DEBIT SCALAIRE 
      MNEMO(8)   = 'Q       ' 
!     TRACEUR 
      MNEMO(9)   = 'T       ' 
!     ENERGIE TURBUL. 
      MNEMO(10)   = 'K       ' 
!     DISSIPATION 
      MNEMO(11)   = 'E       ' 
!     VISCOSITE TURB. 
      MNEMO(12)   = 'D       ' 
!     DEBIT SUIVANT X 
      MNEMO(13)   = 'I       ' 
!     DEBIT SUIVANT Y 
      MNEMO(14)   = 'J       ' 
!     VITESSE SCALAIRE 
      MNEMO(15)   = 'M       ' 
!     VENT X 
      MNEMO(16)   = 'X       ' 
!     VENT Y 
      MNEMO(17)   = 'Y       ' 
!     PRESSION ATMOS. 
      MNEMO(18)   = 'P       ' 
!     FROTTEMENT 
      MNEMO(19)   = 'W       ' 
!     DERIVE EN X 
      MNEMO(20)   = 'A       ' 
!     DERIVE EN Y 
      MNEMO(21)   = 'G       ' 
!     NBRE DE COURANT 
      MNEMO(22)   = 'L       ' 
!     VARIABLE 23 
      MNEMO(23)   = 'N       ' 
!     VARIABLE 24 
      MNEMO(24)   = 'O       ' 
!     VARIABLE 25 
      MNEMO(25)   = 'R       ' 
!     VARIABLE 26 
      MNEMO(26)   = 'Z       ' 
!     VARIABLE 27 
      MNEMO(27)   = 'MAXZ    ' 
!     VARIABLE 28 
      MNEMO(28)   = 'TMXZ    ' 
!     VARIABLE 29 
      MNEMO(29)   = 'MAXV    ' 
!     VARIABLE 30 
      MNEMO(30)   = 'TMXV    ' 
! 
!----------------------------------------------------------------------- 
! 
!     ANALYSES DE FOURIERS 
! 
      IF(NPERIAF.GT.0) THEN 
        DO I=1,NPERIAF 
          TEXTE(31+2*(I-1)) =  'AMPLI PERIODE ' 
     &                       //I_IN_2_LETTERS(I) 
     &                       //'M               ' 
          MNEMO(31+2*(I-1)) = 'AMPL'//I_IN_2_LETTERS(I)//'  ' 
          TEXTE(32+2*(I-1)) =  'PHASE PERIODE ' 
     &                       //I_IN_2_LETTERS(I) 
     &                       //'DEGRES          ' 
          MNEMO(32+2*(I-1)) = 'PHAS'//I_IN_2_LETTERS(I)//'  ' 
        ENDDO  
      ENDIF 
! 
!----------------------------------------------------------------------- 
! 
      RETURN 
      END 
        
        
