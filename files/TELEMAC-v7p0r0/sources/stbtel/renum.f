!                       ****************
                        SUBROUTINE RENUM
!                       ****************
!
     &(X,Y,W,IKLE,NBOR,TRAV1,TRAV2,TAB,NCOLOR,COLOR,NPTFR)
!
!***********************************************************************
! PROGICIEL : STBTEL V5.2                   19/04/91  J-C GALLAND  (LNH)
!                                           19/02/93  J-M JANIN    (LNH)
!***********************************************************************
!
! FONCTION : DECOUPAGE DES TRIANGLES SURCONTRAINTS :
!            ILS SONT COUPES EN TROIS PAR AJOUT D'UN POINT A
!            LEUR BARYCENTRE
!
!
!-----------------------------------------------------------------------
!                             ARGUMENTS
! .________________.____.______________________________________________.
! |      NOM       |MODE|                   ROLE                       |
! |________________|____|______________________________________________|
! |   X,Y          |<-->| COORDONNEES DU MAILLAGE .
! |   IKLE         |<-->| LISTE DES POINTS DE CHAQUE ELEMENT
! |   TRAV1,2      |<-->| TABLEAUX DE TRAVAIL
! |   TAB          |<-->| TABLEAU DE TRAVAIL
! |   NCOLOR       |<-->| TABLEAU DES COULEURS DES POINTS
! |    COLOR       |<-->| STOCKAGE COULEURS DES NOEUDS SUR FICHIER GEO
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
! |                |    |
! |________________|____|______________________________________________|
! MODE : -->(DONNEE NON MODIFIEE), <--(RESULTAT), <-->(DONNEE MODIFIEE)
!-----------------------------------------------------------------------
! APPELE PAR : SURCON
! APPEL DE : -
!***********************************************************************
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
      DOUBLE PRECISION X(*) , Y(*) , W(*)
!
      INTEGER MESH , NDP , NPOIN , NELEM , NPMAX , NELMAX , NPTFR
      INTEGER TAB(*) , IPOIN , IELEM , IPTFR , I1 , I2 , TABMAX
      INTEGER TRAV1(*) , TRAV2(*) , IKLE(NELMAX,3) , NCOLOR(*) , NBOR(*)
!
      LOGICAL COLOR
!
      COMMON/GEO/ MESH , NDP , NPOIN , NELEM , NPMAX , NELMAX
!
!=======================================================================
! CALCUL DU NOMBRE DE POINTS ET ELEMENTS VOISINS
!=======================================================================
!
      DO IPOIN = 1,NPOIN
        TRAV1(IPOIN) = 0
      ENDDO
!
      DO IELEM = 1,NELEM
        TRAV1(IKLE(IELEM,1)) = TRAV1(IKLE(IELEM,1)) + 2
        TRAV1(IKLE(IELEM,2)) = TRAV1(IKLE(IELEM,2)) + 2
        TRAV1(IKLE(IELEM,3)) = TRAV1(IKLE(IELEM,3)) + 2
      ENDDO
!
      DO IPTFR = 1,NPTFR
        TRAV1(NBOR(IPTFR)) = TRAV1(NBOR(IPTFR)) + 1
      ENDDO
!
!=======================================================================
! RENUMEROTATIONS DES POINTS SUIVANT ORDRE CROISSANT DE VOISINS
!=======================================================================
!
      TABMAX = 0
!
      DO IPOIN = 1,NPOIN
!
        I1 = TRAV1(IPOIN)
!
        IF (I1.GT.TABMAX) THEN
          DO I2 = TABMAX+1,I1
            TAB(I2) = IPOIN - 1
          ENDDO
          TABMAX = I1
        ELSEIF (I1.LT.TABMAX) THEN
          DO I2 = TABMAX,I1+1,-1
            TAB(I2) = TAB(I2) + 1
            TRAV2(TAB(I2)) = TRAV2(TAB(I2-1)+1)
          ENDDO
        ENDIF
!
        TAB(I1) = TAB(I1) + 1
        TRAV2(TAB(I1)) = IPOIN
!
      ENDDO
!
      DO I1 = 1,TABMAX
        PRINT*,'TAB(',I1,')=',TAB(I1)
      ENDDO
!
!=======================================================================
! MODIFICATIONS CORRESPONDANTES DANS LES DIFFERENTES VARIABLES
!=======================================================================
!
      DO IPOIN = 1,NPOIN
        TRAV1(TRAV2(IPOIN)) = IPOIN
      ENDDO
!
      DO IELEM = 1,NELEM
        IKLE(IELEM,1) = TRAV1(IKLE(IELEM,1))
        IKLE(IELEM,2) = TRAV1(IKLE(IELEM,2))
        IKLE(IELEM,3) = TRAV1(IKLE(IELEM,3))
      ENDDO
!
      DO IPTFR = 1,NPTFR
        NBOR(IPTFR) = TRAV1(NBOR(IPTFR))
        NBOR(NPTFR+IPTFR) = TRAV1(NBOR(NPTFR+IPTFR))
      ENDDO
!
      DO IPOIN = 1,NPOIN
        W(IPOIN) = X(TRAV2(IPOIN))
      ENDDO
      DO IPOIN = 1,NPOIN
        X(IPOIN) = W(IPOIN)
      ENDDO
!
      DO IPOIN = 1,NPOIN
        W(IPOIN) = Y(TRAV2(IPOIN))
      ENDDO
      DO IPOIN = 1,NPOIN
        Y(IPOIN) = W(IPOIN)
      ENDDO
!
      IF (COLOR) THEN
!
        DO IPOIN = 1,NPOIN
          TRAV1(IPOIN) = NCOLOR(TRAV2(IPOIN))
        ENDDO
        DO IPOIN = 1,NPOIN
          NCOLOR(IPOIN) = TRAV1(IPOIN)
        ENDDO
!
      ENDIF
!
!=======================================================================
!
      RETURN
      END
