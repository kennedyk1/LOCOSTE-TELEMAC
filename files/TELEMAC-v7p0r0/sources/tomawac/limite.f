!                       *****************
                        SUBROUTINE LIMITE
!                       *****************
     &( F     , DEPTH , FREQ  , NPOIN2, NPLAN , NF    )
!     
!***********************************************************************
! TOMAWAC   V7P0                                 30/07/2014
!***********************************************************************
!
!brief     EQUILIBRIUM RANGE SPECTRUM OF PHILLIPS APPLIED AS AN UPPER
!+         LIMIT FOR THE SPECTRUM : E(F)=ALFA*G**2/(2.PI)**4 F**(-5)
!
!
!history  E. GAGNAIRE-RENOU AND M.BENOIT (EDF/LNHE)
!+        09/2014
!+        V7P0
!+        NEW SUBROUTINE CREATED / IMPLEMENTED
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!| DEPTH          |-->| WATER DEPTH
!| F              |-->| DIRECTIONAL SPECTRUM
!| FREQ           |-->| DISCRETIZED FREQUENCIES
!| NF             |-->| NUMBER OF FREQUENCIES
!| NPLAN          |-->| NUMBER OF DIRECTIONS
!| NPOIN2         |-->| NUMBER OF POINTS IN 2D MESH
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!
!
      USE DECLARATIONS_TOMAWAC, ONLY : DEUPI,GRAVIT
!
      IMPLICIT NONE
!
      INTEGER LNG,LU
      COMMON/INFO/ LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!      
      INTEGER, INTENT(IN)             :: NF,NPLAN,NPOIN2
      DOUBLE PRECISION, INTENT(IN)    :: FREQ(NF),DEPTH(NPOIN2)
      DOUBLE PRECISION, INTENT(INOUT) :: F(NPOIN2,NPLAN,NF)      
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER          IP    , JP    , JF
      DOUBLE PRECISION EDEF  , COEF  , DTETAR, EMAX  , REDUC
!
!-----------------------------------------------------------------------
!
      DTETAR=DEUPI/DBLE(NPLAN)
      COEF=0.0081D0*GRAVIT**2/DEUPI**4
!
      DO IP=1,NPOIN2
        DO JF=1,NF
          EDEF=0.0D0
          DO JP=1,NPLAN
            EDEF=EDEF+F(IP,JP,JF)
          ENDDO
          EDEF=EDEF*DTETAR
          EMAX=COEF/FREQ(JF)**5
          IF (EDEF.GT.EMAX) THEN
            REDUC=EMAX/EDEF
            DO JP=1,NPLAN
              F(IP,JP,JF)=F(IP,JP,JF)*REDUC
            ENDDO
          ENDIF
        ENDDO
      ENDDO
!
      RETURN
      END
