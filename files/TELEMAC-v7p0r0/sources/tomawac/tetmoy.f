!                    *****************
                     SUBROUTINE TETMOY
!                    *****************
!
     &( TETAM , F     , COSTET, SINTET, NPLAN , FREQ  , DFREQ , NF    ,
     &  NPOIN2, TAILF , COSMOY, SINMOY, TAUXC , TAUXS )
!
!***********************************************************************
! TOMAWAC   V6P1                                   28/06/2011
!***********************************************************************
!
!brief    COMPUTES THE MEAN DIRECTION OF A DIRECTIONAL SPECTRUM
!+               (BY COMPUTING THE ARC TANGENT OF THE MEAN SINE AND
!+                COSINE). THE RESULT IS IN RADIANS.
!
!history  P. THELIIER; M. BENOIT
!+        01/02/95
!+        V1P0
!+
!
!history  M. BENOIT
!+        05/07/96
!+        V1P2
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
!history  G.MATTAROLO (EDF - LNHE)
!+        28/06/2011
!+        V6P1
!+   Translation of French names of the variables in argument
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| COSMOY         |<->| WORK TABLE
!| COSTET         |-->| COSINE OF TETA ANGLE
!| DFREQ          |-->| FREQUENCY STEPS BETWEEN DISCRETIZED FREQUENCIES
!| F              |-->| VARIANCE DENSITY DIRECTIONAL SPECTRUM
!| FREQ           |-->| DISCRETIZED FREQUENCIES
!| NF             |-->| NUMBER OF FREQUENCIES
!| NPLAN          |-->| NUMBER OF DIRECTIONS
!| NPOIN2         |-->| NUMBER OF POINTS IN 2D MESH
!| SINMOY         |<->| WORK TABLE
!| SINTET         |-->| SINE OF TETA ANGLE
!| TAILF          |-->| FACTEUR DE QUEUE DU SPECTRE
!| TAUXC          |<->| WORK TABLE
!| TAUXS          |<->| WORK TABLE
!| TETAM          |<--| DIRECTIONAL SPECTRUM MEAN DIRECTION
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_TOMAWAC, ONLY : DEUPI
!
      IMPLICIT NONE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER  NF    , NPLAN , NPOIN2
      DOUBLE PRECISION TAILF
      DOUBLE PRECISION TETAM(NPOIN2) , DFREQ(NF)    , COSMOY(NPOIN2)
      DOUBLE PRECISION COSTET(NPLAN) , SINTET(NPLAN), SINMOY(NPOIN2)
      DOUBLE PRECISION TAUXC(NPOIN2) , TAUXS(NPOIN2)
      DOUBLE PRECISION F(NPOIN2,NPLAN,NF), FREQ(NF)
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER  IP    , JP    , JF
      DOUBLE PRECISION AUXC  , AUXS  ,SEUIL , COEFT , DFDTET
      DOUBLE PRECISION DTETAR
!
!-----------------------------------------------------------------------
!
      DTETAR=DEUPI/DBLE(NPLAN)
      SEUIL =1.D-10
!
      DO IP=1,NPOIN2
        COSMOY(IP)=0.D0
        SINMOY(IP)=0.D0
      ENDDO
!
!-----C-------------------------------------------------------C
!-----C  SUMS UP THE DISCRETISED PART OF THE SPECTRUM         C
!-----C-------------------------------------------------------C
!
      DO JF=1,NF
!
        DFDTET=DFREQ(JF)*DTETAR
!
        DO IP=1,NPOIN2
          TAUXC(IP)=0.D0
          TAUXS(IP)=0.D0
        ENDDO
!
        DO JP=1,NPLAN
          AUXC=COSTET(JP)*DFDTET
          AUXS=SINTET(JP)*DFDTET
          DO IP=1,NPOIN2
            TAUXC(IP)=TAUXC(IP)+F(IP,JP,JF)*AUXC
            TAUXS(IP)=TAUXS(IP)+F(IP,JP,JF)*AUXS
          ENDDO
        ENDDO
!
        DO IP=1,NPOIN2
          COSMOY(IP)=COSMOY(IP)+TAUXC(IP)
          SINMOY(IP)=SINMOY(IP)+TAUXS(IP)
        ENDDO
!
      ENDDO ! JF
!
!-----C-------------------------------------------------------------C
!-----C  TAKES THE HIGH FREQUENCY PART INTO ACCOUNT (OPTIONAL)      C
!-----C-------------------------------------------------------------C
!
      IF(TAILF.GT.1.D0) THEN
        COEFT=FREQ(NF)/((TAILF-1.D0)*DFREQ(NF))
        DO IP=1,NPOIN2
          COSMOY(IP)=COSMOY(IP)+TAUXC(IP)*COEFT
          SINMOY(IP)=SINMOY(IP)+TAUXS(IP)*COEFT
        ENDDO
      ENDIF
!
!-----C-------------------------------------------------------------C
!-----C  COMPUTES THE MEAN DIRECTION                                C
!-----C  (IN RADIANS BETWEEN 0 AND 2.PI)                            C
!-----C-------------------------------------------------------------C
!
      DO IP=1,NPOIN2
        IF(ABS(SINMOY(IP)).LT.SEUIL.AND.
     &      ABS(COSMOY(IP)).LT.SEUIL) THEN
          TETAM(IP) = 0.D0
        ELSE
          TETAM(IP)=ATAN2(SINMOY(IP),COSMOY(IP))
          IF(TETAM(IP).LT.0.D0) TETAM(IP)=TETAM(IP)+DEUPI
        ENDIF
      ENDDO
!
!-----------------------------------------------------------------------
!
      RETURN
      END
