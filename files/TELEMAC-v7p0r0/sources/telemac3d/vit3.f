!                    ******************************
                     DOUBLE PRECISION FUNCTION VIT3
!                    ******************************
!
     &( I , TIME , N , ENTET )
!
!***********************************************************************
! TELEMAC3D   V6P2                                   08/11/2011
!***********************************************************************
!
!brief    PRESCRIBES THE VELOCITY FOR VEL IMPOSED
!+                LIQUID BOUNDARIES.
!
!history  J-M HERVOUET (LNHE)
!+        08/04/09
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
!history  C. COULET (ARTELIA GROUP)
!+        08/11/2011
!+        V6P2
!+   Modification size FCT due to modification of TRACER numbering
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| ENTET          |-->| LOGICAL, IF YES INFORMATION IS PRINTED
!| I              |-->| NUMBER OF LIQUID BOUNDARY
!| N              |-->| GLOBAL NUMBER OF POINT
!|                |   | IN PARALLEL NUMBER OF POINT IN ORIGINAL MESH
!| TIME           |-->| TIME OF TIME STEP
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_TELEMAC3D
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER          , INTENT(IN) :: I,N
      DOUBLE PRECISION , INTENT(IN) :: TIME
      LOGICAL          , INTENT(IN) :: ENTET
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER*9 FCT
      INTEGER J
      LOGICAL, SAVE :: DEJA=.FALSE.
      LOGICAL, DIMENSION(MAXFRO), SAVE :: OK
!
!     FIRST CALL, INITIALISES OK TO .TRUE.
!
      IF(.NOT.DEJA) THEN
        DO J=1,MAXFRO
          OK(J)=.TRUE.
        ENDDO
        DEJA=.TRUE.
      ENDIF
!
!     IF LIQUID BOUNDARY FILE EXISTS, ATTEMPTS TO FIND
!     THE VALUE IN IT. IF YES, OK REMAINS TO .TRUE. FOR NEXT CALLS
!                      IF  NO, OK IS SET  TO .FALSE.
!
      IF(OK(I).AND.T3D_FILES(T3DIMP)%NAME(1:1).NE.' ') THEN
!
!       FCT WILL BE VIT(1), VIT(2), ETC, VIT(99), DEPENDING ON I
        FCT='VIT(     '
        IF(I.LT.10) THEN
          WRITE(FCT(5:5),FMT='(I1)') I
          FCT(6:6)=')'
        ELSEIF(I.LT.100) THEN
          WRITE(FCT(5:6),FMT='(I2)') I
          FCT(7:7)=')'
        ELSE
          IF (LNG.EQ.1) WRITE(LU,*) 'VIT3 NE PEUT PAS GERER PLUS 
     &                               DE 99 FRONTIERES'
          IF (LNG.EQ.2) WRITE(LU,*) 'VIT3 NOT PROGRAMMED FOR MORE 
     &                               THAN 99 BOUNDARIES'
          CALL PLANTE(1)
          STOP 
        ENDIF
        CALL READ_FIC_FRLIQ(VIT3,FCT,TIME,T3D_FILES(T3DIMP)%LU,
     &                      ENTET,OK(I))
!
      ENDIF
!
      IF(.NOT.OK(I).OR.T3D_FILES(T3DIMP)%NAME(1:1).EQ.' ') THEN
!
!     PROGRAMMABLE PART
!     SL IS TAKEN FROM THE STEERING FILE, BUT MAY BE CHANGED
!
        VIT3 = VITIMP(I)
!
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END
