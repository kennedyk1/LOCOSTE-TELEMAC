!                    ***************************
                     MODULE DECLARATIONS_PARTEL
!                    ***************************
!
!
!***********************************************************************
! PARTEL                                             09/05/2014
!***********************************************************************
!
!brief    Defining parameters that need to be created first because they
!+        could be used by any other library.
!
!history  Y. AUDOUIN & J-M HERVOUET (EDF LAB, LNHE)
!+        09/05/2014
!+        V7P0
!+   First version.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      IMPLICIT NONE
!----------------------------------------------------------------------
!
!     MAXIMUM NUMBER OF HALO, IN THE PARALLEL VERSION THE NUMBER OF HALO WILL BE DIRECTLY COMPUTED
      INTEGER, PARAMETER :: NBMAXHALO=100000
!
      INTEGER, PARAMETER :: MAXNPROC = 100000 ! MAX PARTITION NUMBER [00000..99999]
      INTEGER, PARAMETER :: MAXLENSOFT = 144 ! SOFT MAX FILE NAME LENGTH
      INTEGER, PARAMETER :: MAXLENHARD = 250 ! HARD MAX FILE NAME LENGTH
      INTEGER, PARAMETER :: MAXADDCH = 10 ! MAX ADDED SUFFIX LENGTH
      INTEGER, PARAMETER :: MAXVAR = 100  ! MAX NUMBER OF VARIABLES
!
!-----------------------------------------------------------------------
!
      END MODULE DECLARATIONS_PARTEL

