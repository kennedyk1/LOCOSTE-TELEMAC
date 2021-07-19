!                       *******************************
                        SUBROUTINE GRETEL_CPIKLE2
!                       *******************************
     &(IKLE3,IKLES,NELEM2,NELMAX2,NPOIN2,NPLAN)
!
!***********************************************************************
! PARALLEL   V6P0                                   21/08/2010
!***********************************************************************
!
!brief       GRETEL_EXTENSION OF THE CONNECTIVITY TABLE.
!+                CASE OF GRETEL_EXTENSION TO A QUASI-BUBBLE ELEMENT.
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
!history  J-M HERVOUET (LNH)
!+        23/08/1999
!+        V5P1
!+
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| IKLE           |<->| TABLEAU DES CONNECTIVITES
!| IKLE3          |---|
!| IKLES          |---|
!| NELEM          |-->| NOMBRE D'ELEMENTS
!| NELEM2         |---|
!| NELMAX         |-->| NOMBRE MAXIMUM D'ELEMENTS
!| NELMAX2        |---|
!| NPLAN          |---|
!| NPOIN          |-->| NOMBRE DE SOMMETS DU MAILLAGE
!| NPOIN2         |---|
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)    :: NELEM2,NELMAX2,NPOIN2,NPLAN
      INTEGER, INTENT(INOUT) :: IKLES(3,NELEM2)
      INTEGER, INTENT(INOUT) :: IKLE3(NELMAX2,NPLAN-1,6)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER IELEM,I
!
!-----------------------------------------------------------------------
!
!     BOTTOM AND TOP OF ALL LAYERS
!
      IF(NPLAN.GE.2) THEN
        DO I = 1,NPLAN-1
          DO IELEM = 1,NELEM2
            IKLE3(IELEM,I,1) = IKLES(1,IELEM) + (I-1)*NPOIN2
            IKLE3(IELEM,I,2) = IKLES(2,IELEM) + (I-1)*NPOIN2
            IKLE3(IELEM,I,3) = IKLES(3,IELEM) + (I-1)*NPOIN2
            IKLE3(IELEM,I,4) = IKLES(1,IELEM) +  I   *NPOIN2
            IKLE3(IELEM,I,5) = IKLES(2,IELEM) +  I   *NPOIN2
            IKLE3(IELEM,I,6) = IKLES(3,IELEM) +  I   *NPOIN2
          ENDDO
        ENDDO
      ELSE
        IF(LNG.EQ.1) WRITE(LU,*) 
     &   'GRETEL_CPIKLE2 : IL FAUT AU MOINS 2 PLANS'
        IF(LNG.EQ.2) WRITE(LU,*) 
     &   'GRETEL_CPIKLE2 : MINIMUM OF 2 PLANES NEEDED'
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END SUBROUTINE GRETEL_CPIKLE2

