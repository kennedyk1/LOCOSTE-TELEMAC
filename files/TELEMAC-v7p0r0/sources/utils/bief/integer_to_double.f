!                    ****************************
                     SUBROUTINE INTEGER_TO_DOUBLE
!                    ****************************
!
     &(OP,IX,X,N,QT)
!
!***********************************************************************
! BIEF   V7P0                                   13/01/2014
!***********************************************************************
!
!brief    Retrieving a double precision array from an I8 integer.
!
!warning  See also double_to_integer.
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        13/01/2014
!+        V7P0
!+   First version.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| IX             |-->| INTEGER ARRAY CODING THE REAL ARRAY 
!| N              |-->| NUMBER OF POINTS IN THE ARRAYS X AND IX
!| OP             |-->| IF '=', X REINITIALISED, IF '+' ADDITION TO X
!| QT             |-->| THE QUANTUM USED FOR CODING
!| X              |<--| DOUBLE PRECISION ARRAY TO BE CODED
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SPECIAL
      USE BIEF, EX_INTEGER_TO_DOUBLE => INTEGER_TO_DOUBLE
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER         , INTENT(IN)    :: N
      INTEGER(KIND=K8), INTENT(IN)    :: IX(N)
      DOUBLE PRECISION, INTENT(IN)    :: QT
      DOUBLE PRECISION, INTENT(INOUT) :: X(N)
      CHARACTER(LEN=1), INTENT(IN)    :: OP
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER I
!
!-----------------------------------------------------------------------
!     RETRIEVING THE DOUBLE PRECISION VALUE
!-----------------------------------------------------------------------
!
      IF(OP.EQ.'=') THEN
        DO I=1,N
          X(I)=IX(I)*QT
        ENDDO
      ELSEIF(OP.EQ.'+') THEN
        DO I=1,N
          X(I)=X(I)+IX(I)*QT
        ENDDO
      ELSE
        IF(LNG.EQ.1) THEN
          WRITE(LU,*) 'INTEGER_TO_DOUBLE : OPERATION ',OP,' INCONNUE'
        ENDIF
        IF(LNG.EQ.2) THEN
          WRITE(LU,*) 'INTEGER_TO_DOUBLE: OPERATION ',OP,' UNKNOWN'
        ENDIF
        CALL PLANTE(1)
        STOP
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END
