!                    ****************************************
      SUBROUTINE CHECK_ALLOCATE
!                    ****************************************
!
     &(IERR, CHFILE)
!
!***********************************************************************
! BIEF   V6P3                                   21/08/2010
!***********************************************************************
!
!brief    GIVES THE EXTENSION FOR NAMING FILES IN PARALLEL
!+
!
!history  J-M HERVOUET (LNHE)
!+        11/07/2008
!+        V5P9
!+  
!
!history  J-M HERVOUET (LNHE)
!+        22/11/2012
!+        V6P3
!+   USE BIEF removed, IIPID and IPID changed into I.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| N              |-->| TOTAL NUMBER OF PROCESSORS
!| I              |-->| RANK OF THE PROCESSOR
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU

      INTEGER,       INTENT(IN) :: IERR
      CHARACTER*(*), INTENT(IN) :: CHFILE
!
!-----------------------------------------------------------------------
!
      IF(IERR.NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,*) 'ERROR DURING ALLOCATION OF ',CHFILE
        IF(LNG.EQ.2)WRITE(LU,*) 'ERREUR LORS DE L ALLOCATION DE ',CHFILE
        CALL PLANTE(-1)
      ENDIF
!
!-----------------------------------------------------------------------
!
      END SUBROUTINE CHECK_ALLOCATE
