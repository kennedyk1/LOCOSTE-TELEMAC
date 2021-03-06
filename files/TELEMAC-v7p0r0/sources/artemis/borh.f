!                    ***************
                     SUBROUTINE BORH
!                    ***************
!
!
!***********************************************************************
! ARTEMIS   V6P1                                   21/08/2010
!***********************************************************************
!
!brief    TAKES INTO ACCOUNT USER-SPECIFIED BOUNDARY CONDITIONS.
!+              THEY ARE GIVEN BY SEGMENT.
!
!warning  MUST BE CODED BY THE USER
!code
!+ ---------------------------------------
!+ INITIALISES THE VARIABLES (DEFAULT)
!+ ---------------------------------------
!+      TETAB%R(:)=TETAH
!+      TETAP%R(:)=0.D0
!+      ALFAP%R(:)=0.D0
!+      RP%R(:)=0.D0
!+      HB%R(:)=0.D0
!
!history  J-M HERVOUET (LNH)
!+
!+
!+   LINKED TO BIEF 5.0
!
!history  D. AELBRECHT (LNH)
!+        21/08/2000
!+        V5P1
!+
!
!history  C. DENIS (SINETICS)
!+        18/03/2010
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
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_TELEMAC
      USE DECLARATIONS_ARTEMIS
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
      DOUBLE PRECISION PI
      PARAMETER( PI = 3.1415926535897932384626433D0)
!
      INTRINSIC COS,SIN
!
!-----------------------------------------------------------------------
!
! BOUNDARY CONDITIONS
! KLOG : 'SOLID' SEGMENT.
! KINC : 'INCIDENT WAVE' SEGMENT.
! KENT : 'ENTRY' SEGMENT.
! KSORT : 'EXIT' SEGMENT.
!
! ALL THE ANGLES ARE IN  DEGREES
!                         ------
! ---------------------------------------
! INITIALISES THE VARIABLES (DEFAULT)
! ---------------------------------------
!
      TETAB%R(:)=TETAH
      TETAP%R(:)=0.D0
      ALFAP%R(:)=0.D0
      RP%R(:)=0.D0
      HB%R(:)=0.D0
!
!-----------------------------------------------------------------------
!
      RETURN
      END
