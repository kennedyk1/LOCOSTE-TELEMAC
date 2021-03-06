!                    *****************
                     SUBROUTINE MATRBL
!                    *****************
!
     &( OP , X , A , Y , C , MESH )
!
!***********************************************************************
! BIEF   V6P1                                   21/08/2010
!***********************************************************************
!
!brief    MATRIX VECTOR OPERATIONS.
!code
!+   OP IS A STRING OF 8 CHARACTERS, WHICH INDICATES THE OPERATION TO BE
!+   PERFORMED ON VECTORS X,Y AND MATRIX M.
!+
!+   THE RESULT IS VECTOR X (A NON-ASSEMBLED PART OF WHICH CAN BE IN
!+   ARRAY W IF LEGO = .FALSE.)
!+
!+   THESE OPERATIONS ARE DIFFERENTS DEPENDING ON THE DIAGONAL TYPE
!+   AND THE OFF-DIAGONAL TERMS TYPE.
!+
!+   IMPLEMENTED OPERATIONS :
!+
!+      OP = 'X=AY    '  : X = AY
!+      OP = 'X=X+AY  '  : X = X + AY
!+      OP = 'X=X-AY  '  : X = X - AY
!+      OP = 'X=X+CAY '  : X = X + C AY
!+      OP = 'X=TAY   '  : X = TA Y (TA: TRANSPOSE OF A)
!+      OP = 'X=X+TAY '  : X = X + TA Y
!+      OP = 'X=X-TAY '  : X = X - TA Y
!+      OP = 'X=X+CTAY'  : X = X + C TA Y
!
!history  J-M HERVOUET (LNH)    ; F LEPEINTRE (LNH)
!+        24/04/97
!+        V5P1
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
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| A              |-->| MATRIX OR BLOCK OF MATRICES
!| C              |-->| A GIVEN CONSTANT
!| MESH           |-->| MESH STRUCTURE
!| OP             |-->| THE OPERATION TO BE DONE
!| X              |<--| RESULTING VECTOR OR BLOCK OF VECTORS
!| Y              |-->| GIVEN VECTOR OR BLOCK OF VECTORS
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF, EX_MATRBL => MATRBL
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=8), INTENT(IN)   :: OP
      TYPE(BIEF_OBJ), INTENT(INOUT)  :: X
      TYPE(BIEF_OBJ), INTENT(IN)     :: A,Y
      DOUBLE PRECISION, INTENT(IN)   :: C
      TYPE(BIEF_MESH), INTENT(INOUT) :: MESH
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER S
!
!-----------------------------------------------------------------------
!
!     CASE WHERE THE STRUCTURES ARE BLOCKS
!
      IF(A%TYPE.EQ.4) THEN
!
        S = X%N
!
        IF(S.EQ.1) THEN
!
          CALL MATVEC( OP,X%ADR(1)%P,A%ADR(1)%P,Y%ADR(1)%P,C,MESH)
!
        ELSEIF(S.EQ.2) THEN
!
          IF(OP(1:8).EQ.'X=AY    ') THEN
            CALL MATVEC('X=AY    ',
     &      X%ADR(1)%P,A%ADR(1)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(1)%P,A%ADR(2)%P,Y%ADR(2)%P,C,MESH,LEGO=.TRUE.)
            CALL MATVEC('X=AY    ',
     &      X%ADR(2)%P,A%ADR(3)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(2)%P,A%ADR(4)%P,Y%ADR(2)%P,C,MESH,LEGO=.TRUE.)
          ELSEIF(OP(1:8).EQ.'X=TAY   ') THEN
            CALL MATVEC('X=TAY   ',
     &      X%ADR(1)%P,A%ADR(1)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(1)%P,A%ADR(3)%P,Y%ADR(2)%P,C,MESH,LEGO=.TRUE.)
            CALL MATVEC('X=TAY   ',
     &      X%ADR(2)%P,A%ADR(2)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(2)%P,A%ADR(4)%P,Y%ADR(2)%P,C,MESH,LEGO=.TRUE.)
!
          ELSE
            IF (LNG.EQ.1) WRITE(LU,10) OP
            IF (LNG.EQ.2) WRITE(LU,11) OP
            CALL PLANTE(1)
            STOP
          ENDIF
!
        ELSEIF(S.EQ.3) THEN
!
          IF(OP(1:8).EQ.'X=AY    ') THEN
            CALL MATVEC('X=AY    ',
     &      X%ADR(1)%P,A%ADR(1)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(1)%P,A%ADR(2)%P,Y%ADR(2)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(1)%P,A%ADR(3)%P,Y%ADR(3)%P,C,MESH,LEGO=.TRUE.)
            CALL MATVEC('X=AY    ',
     &      X%ADR(2)%P,A%ADR(4)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(2)%P,A%ADR(5)%P,Y%ADR(2)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(2)%P,A%ADR(6)%P,Y%ADR(3)%P,C,MESH,LEGO=.TRUE. )
            CALL MATVEC('X=AY    ',
     &      X%ADR(3)%P,A%ADR(7)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(3)%P,A%ADR(8)%P,Y%ADR(2)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+AY  ',
     &      X%ADR(3)%P,A%ADR(9)%P,Y%ADR(3)%P,C,MESH,LEGO=.TRUE.)
          ELSEIF(OP(1:8).EQ.'X=TAY   ') THEN
            CALL MATVEC('X=TAY   ',
     &      X%ADR(1)%P,A%ADR(1)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(1)%P,A%ADR(4)%P,Y%ADR(2)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(1)%P,A%ADR(7)%P,Y%ADR(3)%P,C,MESH,LEGO=.TRUE.)
            CALL MATVEC('X=TAY   ',
     &      X%ADR(2)%P,A%ADR(2)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(2)%P,A%ADR(5)%P,Y%ADR(2)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(2)%P,A%ADR(8)%P,Y%ADR(3)%P,C,MESH,LEGO=.TRUE.)
            CALL MATVEC('X=TAY   ',
     &      X%ADR(3)%P,A%ADR(3)%P,Y%ADR(1)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(3)%P,A%ADR(6)%P,Y%ADR(2)%P,C,MESH,LEGO=.FALSE.)
            CALL MATVEC('X=X+TAY ',
     &      X%ADR(3)%P,A%ADR(9)%P,Y%ADR(3)%P,C,MESH,LEGO=.TRUE.)
!
          ELSE
            IF (LNG.EQ.1) WRITE(LU,10) OP
            IF (LNG.EQ.2) WRITE(LU,11) OP
10          FORMAT(1X,'MATRBL (BIEF) : OPERATION INCONNUE : ',A8)
11          FORMAT(1X,'MATRBL (BIEF) : UNKNOWN OPERATION  : ',A8)
            CALL PLANTE(0)
            STOP
          ENDIF
!
        ELSE
!
          IF (LNG.EQ.1) WRITE(LU,150) S
          IF (LNG.EQ.2) WRITE(LU,151) S
          IF (LNG.EQ.1) WRITE(LU,50) X%NAME,X%TYPE
          IF (LNG.EQ.1) WRITE(LU,51) Y%NAME,Y%TYPE
          IF (LNG.EQ.1) WRITE(LU,52) A%NAME,A%TYPE
          IF (LNG.EQ.1) WRITE(LU,53)
          IF (LNG.EQ.2) WRITE(LU,60) X%NAME,X%TYPE
          IF (LNG.EQ.2) WRITE(LU,61) Y%NAME,Y%TYPE
          IF (LNG.EQ.2) WRITE(LU,62) A%NAME,A%TYPE
          IF (LNG.EQ.2) WRITE(LU,63)
150       FORMAT(1X,'MATRBL (BIEF) : TROP DE VECTEURS INCONNUS :',1I6)
151       FORMAT(1X,'MATRBL (BIEF) : TOO MANY VECTORS          :',1I6)
          CALL PLANTE(1)
          STOP
!
        ENDIF
!
!-----------------------------------------------------------------------
!
!  CASE WHERE THE STRUCTURES ARE NOT BLOCKS
!
      ELSEIF(A%TYPE.EQ.3.AND.X%TYPE.EQ.4.AND.Y%TYPE.EQ.4) THEN
!
        CALL MATVEC( OP , X%ADR(1)%P , A , Y%ADR(1)%P , C , MESH )
!
!-----------------------------------------------------------------------
!
      ELSEIF(A%TYPE.EQ.3.AND.X%TYPE.EQ.2.AND.Y%TYPE.EQ.2) THEN
!
        CALL MATVEC( OP , X          , A , Y          , C , MESH )
!
!-----------------------------------------------------------------------
!
!  ERROR
!
      ELSE
!
        IF (LNG.EQ.1) WRITE(LU,50) X%NAME,X%TYPE
        IF (LNG.EQ.1) WRITE(LU,51) Y%NAME,Y%TYPE
        IF (LNG.EQ.1) WRITE(LU,52) A%NAME,A%TYPE
        IF (LNG.EQ.1) WRITE(LU,53)
        IF (LNG.EQ.2) WRITE(LU,60) X%NAME,X%TYPE
        IF (LNG.EQ.2) WRITE(LU,61) Y%NAME,Y%TYPE
        IF (LNG.EQ.2) WRITE(LU,62) A%NAME,A%TYPE
        IF (LNG.EQ.2) WRITE(LU,63)
50      FORMAT(1X,'MATRBL (BIEF) : NOM DE X : ',A6,'  TYPE : ',1I6)
51      FORMAT(1X,'                NOM DE Y : ',A6,'  TYPE : ',1I6)
52      FORMAT(1X,'                NOM DE A : ',A6,'  TYPE : ',1I6)
53      FORMAT(1X,'                CAS NON PREVU')
60      FORMAT(1X,'MATRBL (BIEF) : NAME OF X : ',A6,'  TYPE : ',1I6)
61      FORMAT(1X,'                NAME OF Y : ',A6,'  TYPE : ',1I6)
62      FORMAT(1X,'                NAME OF A : ',A6,'  TYPE : ',1I6)
63      FORMAT(1X,'                NOT IMPLEMENTED')
        CALL PLANTE(1)
        STOP
!
      ENDIF
!
!-----------------------------------------------------------------------
!
!  COMPLEMENTS THE VECTOR (PARALLEL MODE)
!
      IF(NCSIZE.GT.1) THEN
        CALL PARCOM(X,2,MESH)
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END
