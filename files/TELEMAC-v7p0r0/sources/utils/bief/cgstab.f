!                    *****************
                     SUBROUTINE CGSTAB
!                    *****************
!
     &(X, A,B , MESH, P,Q,R,S,T,V, CFG,INFOGR,AUX)
!
!***********************************************************************
! BIEF   V6P1                                   21/08/2010
!***********************************************************************
!
!brief    SOLVES THE LINEAR SYSTEM A X = B
!+        USING THE SQUARED CONJUGATE GRADIENT METHOD STABILLISED.
!code
!+-----------------------------------------------------------------------
!+                        PRECONDITIONING
!+                        (ALSO SEE SOLV01)
!+-----------------------------------------------------------------------
!+    PRECON VALUE     I                  MEANING
!+-----------------------------------------------------------------------
!+        0            I  NO PRECONDITIONING
!+        2            I  DIAGONAL PRECONDITIONING WITH THE MATRIX
!+                     I  DIAGONAL
!+        3            I  DIAGONAL PRECONDITIONING WITH THE CONDENSED
!+                     I  MATRIX
!+        5            I  DIAGONAL PRECONDITIONING BUT ACCEPTS 0 OR
!+                     I  NEGATIVE VALUES ON THE DIAGONAL
!+        7            I  CROUT
!+-----------------------------------------------------------------------
!
!history  R RATKE (HANNOVER); A MALCHEREK (HANNOVER); J-M HERVOUET (LNH)    ; F  LEPEINTRE (LNH)
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
!| A              |-->| MATRIX OF THE SYSTEM
!| AUX            |-->| PRECONDITIONING MATRIX
!| B              |-->| RIGHT-HAND SIDE OF SYSTEM
!| CFG            |-->| CFG(1): STORAGE OF MATRIX 
!|                |   | CFG(2): MATRIX VECTOR PRODUCT
!| INFOGR         |-->| IF YES, INFORMATION PRINTED
!| MESH           |-->| MESH STRUCTURE
!| P              |<->| WORK STRUCTURE
!| Q              |<->| WORK STRUCTURE
!| R              |<->| WORK STRUCTURE
!| S              |<->| WORK STRUCTURE
!| T              |<->| WORK STRUCTURE
!| V              |<->| WORK STRUCTURE
!| X              |<--| VALEUR INITIALE, PUIS SOLUTION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF, EX_CGSTAB => CGSTAB
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      TYPE(BIEF_OBJ)  , INTENT(INOUT) :: X,P,Q,R,S,T,V
      TYPE(BIEF_OBJ)  , INTENT(IN)    :: AUX,A,B
      TYPE(BIEF_MESH) , INTENT(INOUT) :: MESH
      TYPE(SLVCFG)    , INTENT(INOUT) :: CFG
      LOGICAL         , INTENT(IN)    :: INFOGR
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      DOUBLE PRECISION ALFA,ALFA1,BETA,BETA1,OMEG,OMEG1,OMEG2
      DOUBLE PRECISION XL,TESTL,RMRM,C
!
      INTEGER M
!
      LOGICAL RELAT,CROUT
!
      INTRINSIC SQRT
!
!-----------------------------------------------------------------------
!
!   INITIALISES
      CROUT=.FALSE.
      IF(7*(CFG%PRECON/7).EQ.CFG%PRECON) CROUT=.TRUE.
!
!-----------------------------------------------------------------------
!   INITIALISES
!-----------------------------------------------------------------------
!
      M   = 0
!
!  NORM OF THE SECOND MEMBER TO COMPUTE THE RELATIVE ACCURACY:
!
      XL = P_DOTS(B,B,MESH)
      IF (XL.LT.1.D0) THEN
        XL = 1.D0
        RELAT = .FALSE.
      ELSE
        RELAT = .TRUE.
      ENDIF
!
! IF THE SECOND MEMBER IS 0, X=0 AND IT'S THE END
!
      IF(XL.LT.CFG%ZERO**2) THEN
        RMRM = 0.D0
        CALL OS( 'X=C     ' , X , X , X , 0.D0 )
        GOTO 900
      ENDIF
!
! COMPUTES THE INITIAL RESIDUAL AND EXITS IF RESIDUAL IS SMALL:
!
      CALL MATRBL( 'X=AY    ',V,A,X,C,  MESH)
!
      CALL OS( 'X=Y-Z   ' , R , B , V , C )
      RMRM   = P_DOTS(R,R,MESH)
!
      IF (RMRM.LT.CFG%EPS**2*XL) GO TO 900
!
!-----------------------------------------------------------------------
! PRECONDITIONING :
!-----------------------------------------------------------------------
!
      IF(CROUT) THEN
!       COMPUTES C R  = B
        CALL DOWNUP(R, AUX , B , 'D' , MESH)
        IF(NCSIZE.GT.1) CALL PARMOY(R,MESH)
      ELSE
        CALL OS( 'X=Y     ' , R , B , B , C )
      ENDIF
!
!-----------------------------------------------------------------------
! RESUMES INITIALISATIONS
!-----------------------------------------------------------------------
!
      IF(CROUT) THEN
        CALL DOWNUP(V, AUX , V , 'D' , MESH)
        IF(NCSIZE.GT.1) CALL PARMOY(V,MESH)
      ENDIF
!
      CALL OS( 'X=X-Y   ' , R , V , V , C    )
      CALL OS( 'X=Y     ' , P , R , R , C    )
      CALL OS( 'X=C     ' , V , V , V , 0.D0 )
      CALL OS( 'X=C     ' , Q , Q , Q , 0.D0 )
!
      ALFA  = 1.D0
      BETA  = 1.D0
      OMEG1 = 1.D0
!
!-----------------------------------------------------------------------
!  ITERATIONS:
!-----------------------------------------------------------------------
!
2     M  = M  + 1
!
      BETA1 = P_DOTS(R,P,MESH)
      OMEG2 = OMEG1*BETA1/BETA
      OMEG  = OMEG2/ALFA
      BETA  = BETA1
!
      CALL OS( 'X=Y+CZ  ' , Q , R    , Q ,  OMEG )
      CALL OS( 'X=X+CY  ' , Q , V    , V , -OMEG2)
!
      CALL MATRBL( 'X=AY    ',V,A,Q,C,  MESH)
!
      IF(CROUT) THEN
        CALL DOWNUP(V, AUX , V , 'D' , MESH)
        IF(NCSIZE.GT.1) CALL PARMOY(V,MESH)
      ENDIF
!
      OMEG1 = P_DOTS(P,V,MESH)
      OMEG1 = BETA1/OMEG1
!
      CALL OS( 'X=Y+CZ  ' , S , R    , V , -OMEG1)
!
      CALL MATRBL( 'X=AY    ',T,A,S,C,  MESH)
!
      IF(CROUT) THEN
        CALL DOWNUP(T, AUX , T , 'D' , MESH)
        IF(NCSIZE.GT.1) CALL PARMOY(T,MESH)
      ENDIF
!
      ALFA  = P_DOTS(T,S,MESH)
      ALFA1 = P_DOTS(T,T,MESH)
      ALFA  = ALFA/ALFA1
!
      CALL OS( 'X=X+CY  ' , X , Q , Q ,  OMEG1)
      CALL OS( 'X=X+CY  ' , X , S , S ,  ALFA )
!
      CALL OS( 'X=Y+CZ  ' , R , S , T , -ALFA )
!
      RMRM   = P_DOTS(R,R,MESH)
!
! TESTS CONVERGENCE :
!
      IF (RMRM.LE.XL*CFG%EPS**2) GO TO 900
!
      IF(M.LT.CFG%NITMAX) GO TO 2
!
!-----------------------------------------------------------------------
!
!     IF(INFOGR) THEN
        TESTL = SQRT( RMRM / XL )
        IF(RELAT) THEN
          IF (LNG.EQ.1) WRITE(LU,102) M,TESTL
          IF (LNG.EQ.2) WRITE(LU,104) M,TESTL
        ELSE
          IF (LNG.EQ.1) WRITE(LU,202) M,TESTL
          IF (LNG.EQ.2) WRITE(LU,204) M,TESTL
        ENDIF
!     ENDIF
      GO TO 1000
!
!-----------------------------------------------------------------------
!
900   CONTINUE
!
      IF(INFOGR) THEN
        TESTL = SQRT( RMRM / XL )
        IF(RELAT) THEN
          IF (LNG.EQ.1) WRITE(LU,101) M,TESTL
          IF (LNG.EQ.2) WRITE(LU,103) M,TESTL
        ELSE
          IF (LNG.EQ.1) WRITE(LU,201) M,TESTL
          IF (LNG.EQ.2) WRITE(LU,203) M,TESTL
        ENDIF
      ENDIF
!
1000  RETURN
!
!-----------------------------------------------------------------------
!
!   FORMATS
!
101   FORMAT(1X,'CGSTAB (BIEF) : ',1I8,' ITERATIONS',
     &          ' PRECISION RELATIVE: ',G16.7)
103   FORMAT(1X,'CGSTAB (BIEF) : ',1I8,' ITERATIONS',
     &          ' RELATIVE PRECISION: ',G16.7)
201   FORMAT(1X,'CGSTAB (BIEF) : ',1I8,' ITERATIONS',
     &          ' PRECISION ABSOLUE: ',G16.7)
203   FORMAT(1X,'CGSTAB (BIEF) : ',1I8,' ITERATIONS',
     &          ' ABSOLUTE PRECISION: ',G16.7)
102   FORMAT(1X,'CGSTAB (BIEF) : MAX D''ITERATIONS ATTEINT ',1I8,
     &          ' PRECISION RELATIVE: ',G16.7)
104   FORMAT(1X,'CGSTAB (BIEF) : EXCEEDING MAXIMUM ITERATIONS ',1I8,
     &          ' RELATIVE PRECISION: ',G16.7)
202   FORMAT(1X,'CGSTAB (BIEF) : MAX D''ITERATIONS ATTEINT ',1I8,
     &          ' PRECISION ABSOLUE: ',G16.7)
204   FORMAT(1X,'CGSTAB (BIEF) : EXCEEDING MAXIMUM ITERATIONS',1I8,
     &          ' ABSOLUTE PRECISION:',G16.7)
!
!-----------------------------------------------------------------------
!
      END
