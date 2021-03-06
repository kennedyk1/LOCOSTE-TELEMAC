!                        *****************
                         SUBROUTINE CVSP_P
!                        *****************
!
     &(PATH_PRE,FILE_PRE,JG)
!
!***********************************************************************
! SISYPHE   V7P0                                   14/03/2013
!***********************************************************************
!
!brief   CSV-FILE OUTPUT OF A VERTICAL SORTING PROFILE IN POINT J
!
!history UWE MERKEL
!+        20/07/2011
!+        V6P3
!+
!
!history  P. A. TASSI (EDF R&D, LNHE)
!+        12/03/2013
!+        V6P3
!+   Cleaning, cosmetic
!
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        02/01/2014
!+        V7P0
!+   Use of KNOGL replaced by GLOBAL_TO_LOCAL_POINT.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| JG             |<--| GLOBAL POINT NUMBER
!| PATH_PRE       |<--| WHERE TO SAVE
!| FILE_PRE       |<--| FILENAMETRUNK
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_SISYPHE
      USE BIEF
      USE BIEF_DEF
      USE CVSP_OUTPUTFILES
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER     , INTENT(IN)  :: JG
      CHARACTER(*), INTENT(IN) :: PATH_PRE
      CHARACTER(*), INTENT(IN) :: FILE_PRE
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=100) DEBUGFILE
      CHARACTER(LEN=5) OCSTR
      INTEGER I, K, J
      DOUBLE PRECISION AT, BSUM
!
!----------------------------------------------------------------------- 
!
      AT = DT*LT/PERCOU
      J = JG
      OUTPUTCOUNTER = OUTPUTCOUNTER + 1
!      
!     GLOBAL NUMBERS TO GLOBAL NUMBERS
!
      IF(NCSIZE.GT.1) THEN
        J = GLOBAL_TO_LOCAL_POINT(JG,MESH)
      ENDIF
!      
      WRITE(UNIT=OCSTR, FMT='(I5)') OUTPUTCOUNTER
      DO I=1,5
        IF(OCSTR(I:I)==' ') OCSTR(I:I)='0'
      ENDDO
!      
      WRITE(UNIT=DEBUGFILE, FMT='(A,A,A,A,I8,A,G15.8,A)')
     &     PATH_PRE,OCSTR,'_',FILE_PRE,
     &     JG,'_T_',AT,'.VSP.CSV'

      DO I=1,LEN_TRIM(DEBUGFILE)
        IF(DEBUGFILE(I:I)==' ') DEBUGFILE(I:I)='_'
      ENDDO
!            
      IF(J > 0) THEN
        OPEN(81, FILE=DEBUGFILE, STATUS='UNKNOWN' )
        REWIND 81
        WRITE(81,*) 
     &       "J K FD50(I) AT PRO_D(K_I) PRO_F(K_I) X Y D50 ALT T H"
!         
        DO K=1,PRO_MAX(J)
          BSUM = 0.D0
          DO I=1,NSICLA
            BSUM = FDM(I)*PRO_F(J,PRO_MAX(J)+1-K,I) + BSUM
          ENDDO
!          
          DO I=1,NSICLA
            IF(K.EQ.1) THEN
! FULL OUTPUT WITH COORDINATES ETC. ON SURFACE
              WRITE (81,'(I8,1X,I4,1X,10(G20.12,1X))')
     &              JG,PRO_MAX(J)+1-K,FDM(I),AT,
     &              PRO_D(J,PRO_MAX(J)+1-K,I),
     &              PRO_F(J,PRO_MAX(J)+1-K,I),X(J),Y(J),
     &              BSUM,ES(J,1),TOB%R(J), Z%R(J)                  
            ELSE
! FOLLOWING SECTIONS
              WRITE (81,'(I8,1X,I4,1X,5(G20.12,1X))')
     &              JG,PRO_MAX(J)+1-K,FDM(I),AT,
     &              PRO_D(J,PRO_MAX(J)+1-K,I),
     &              PRO_F(J,PRO_MAX(J)+1-K,I)
            ENDIF
          ENDDO
        ENDDO
!       
        BSUM = 0.D0
        DO I=1,NSICLA
          BSUM = FDM(I)*PRO_F(J,1,I) + BSUM
        ENDDO
!        
        CLOSE(81)
!       
      ENDIF
!
!-----------------------------------------------------------------------
!
      RETURN
      END SUBROUTINE CVSP_P
