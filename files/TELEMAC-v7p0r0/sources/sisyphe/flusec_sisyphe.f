!                    *************************
                     SUBROUTINE FLUSEC_SISYPHE
!                    *************************
!
     &(U,V,H,QSXC,QSYC,CHARR,QSXS,QSYS,SUSP,
     & IKLE,NELMAX,NELEM,X,Y,DT,NCP,CTRLSC,INFO,TPS)
!
!***********************************************************************
! SISYPHE   V7P0                                   21/07/2011
!***********************************************************************
!
!brief    COMPUTES FLUXES THROUGH CONTROL SECTIONS
!+                AND ADDS THEM UP TO OBTAIN OSCILLATING VOLUMES.
!+
!+            MESHES OF DIMENSION 2 AND CONSIDERED WATER DEPTH.
!
!history  J-M HERVOUET (LNHE)
!+        27/12/2006
!+        V5P7
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
!history  J-M HERVOUET (EDF R&D, LNHE)
!+        02/01/2014
!+        V7P0
!+   KNOGL removed.
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| CHARR          |-->| LOGICAL, BEDLOAD
!| CTRLSC         |-->| CONTROL SECTION
!| DT             |-->| TIME STEP
!| H              |-->| WATER DEPTH 
!| IKLE           |-->| CONNECTIVITY TABLE
!| INFO           |-->| IF YES, PRINT
!| NCP            |-->| TWO TIMES THE NUMBER OF CONTROL SECTIONS
!| NELEM          |-->| NUMBER OF ELEMENTS
!| NELMAX         |-->| MAXIMUM NUMBER OF ELEMENTS
!| QSXC           |<->| BEDLOAD TRANSPORT RATE X-DIRECTION 
!| QSXS           |<->| SUSPENSION TRANSPORT RATE X-DIRECTION 
!| QSYC           |<->| BEDLOAD TRANSPORT RATE Y-DIRECTION
!| QSYS           |<->| SUSPENSION TRANSPORT RATE Y-DIRECTION 
!| SUSP           |-->| LOGICAL, SUSPENSION 
!| TPS            |-->| TEMPS
!| U,V            |-->| VELOCITY FIELD COMPONENTS
!| X,Y            |-->| NODES COORDINATES
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE BIEF
      USE DECLARATIONS_SISYPHE, ONLY: CHAIN,MESH
      USE INTERFACE_SISYPHE, EX_FLUSEC_SISYPHE => FLUSEC_SISYPHE
!
      IMPLICIT NONE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, INTENT(IN)          :: NELMAX,NELEM,NCP
      INTEGER, INTENT(IN)          :: IKLE(NELMAX,*)
      INTEGER, INTENT(IN)          :: CTRLSC(NCP)
      DOUBLE PRECISION, INTENT(IN) :: X(*),Y(*),TPS,DT
      LOGICAL, INTENT(IN)          :: INFO,SUSP,CHARR
      TYPE(BIEF_OBJ), INTENT(IN)   :: U,V,H,QSXC,QSYC,QSXS,QSYS
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER NSEMAX,ERR
      PARAMETER(NSEMAX=100)
!
      INTEGER IELEM,I1,I2,I3,ELBEST,IGBEST,ILBEST
      INTEGER ILPREC,ISEG,ISEC,NSEC,PT,DEP,ARR
!
      DOUBLE PRECISION DIST,DIST1,DIST2,DIST3
      DOUBLE PRECISION H1,H2,X1,Y1,X2,Y2,UN1,UN2,NX,NY,SUR6
!
      DOUBLE PRECISION, ALLOCATABLE :: FLX(:),VOLNEG(:),VOLPOS(:)
      DOUBLE PRECISION, ALLOCATABLE :: FLXS(:),FLXC(:)
      DOUBLE PRECISION, ALLOCATABLE :: VOLNEGS(:),VOLPOSS(:)
      DOUBLE PRECISION, ALLOCATABLE :: VOLNEGC(:),VOLPOSC(:)
      INTEGER, ALLOCATABLE :: NSEG(:),LISTE(:,:,:)
!
      LOGICAL DEJA
      DATA DEJA/.FALSE./
      LOGICAL :: OLD_METHOD=.FALSE.
!
      SAVE LISTE,DEJA,NSEG,VOLNEG,VOLPOS,FLX,FLXS,VOLNEGS,VOLPOSS
      SAVE FLXC,VOLNEGC,VOLPOSC,OLD_METHOD
!
!-----------------------------------------------------------------------
!
      SUR6 = 1.D0/6.D0
      NSEC = NCP/2
!
!  LOOKS FOR WAYS THAT JOIN THE POINT COUPLES:
!
      IF(.NOT.DEJA) THEN
!
!     DYNAMICALLY ALLOCATES FLX, VOLNEG, VOLPOS, ETC.
!
      ALLOCATE(FLX(NSEC)           ,STAT=ERR)
      ALLOCATE(VOLNEG(NSEC)        ,STAT=ERR)
      ALLOCATE(VOLPOS(NSEC)        ,STAT=ERR)
      ALLOCATE(NSEG(NCP)           ,STAT=ERR)
      ALLOCATE(LISTE(NCP,NSEMAX,2) ,STAT=ERR)
!     S FOR SUSPENSION, C FOR BEDLOAD
      ALLOCATE(FLXS(NSEC)          ,STAT=ERR)
      ALLOCATE(VOLNEGS(NSEC)       ,STAT=ERR)
      ALLOCATE(VOLPOSS(NSEC)       ,STAT=ERR)
      ALLOCATE(FLXC(NSEC)          ,STAT=ERR)
      ALLOCATE(VOLNEGC(NSEC)       ,STAT=ERR)
      ALLOCATE(VOLPOSC(NSEC)       ,STAT=ERR)
!
      IF(ERR.NE.0) THEN
        IF(LNG.EQ.1) WRITE(LU,100) ERR
        IF(LNG.EQ.2) WRITE(LU,200) ERR
100     FORMAT(1X,'FLUSEC : ERREUR A L''ALLOCATION DE MEMOIRE : ',/,1X,
     &            'CODE D''ERREUR : ',1I6)
200     FORMAT(1X,'FLUSEC: ERROR DURING ALLOCATION OF MEMORY: ',/,1X,
     &            'ERROR CODE: ',1I6)
      ENDIF
!
      IF (.NOT.ALLOCATED(CHAIN)) OLD_METHOD=.TRUE.
!
      DO ISEC=1,NSEC
        FLX(ISEC)=0.0D0
        VOLNEG(ISEC) =0.D0
        VOLPOS(ISEC) =0.D0
        VOLNEGS(ISEC)=0.D0
        VOLPOSS(ISEC)=0.D0
        VOLNEGC(ISEC)=0.D0
        VOLPOSC(ISEC)=0.D0
      ENDDO
!
      DO ISEC =1,NSEC
!
!!JAJ #### IN THE SERIAL CASE, OR "CLASSICAL" IN PARALLEL,
!     FOLLOW THE ALGORITHM OF FINDING SEGMENT CHAINS
!
! NOTE: IF YOU CHANGE THE ALGORITHM, CHANGE IT IN PARTEL AS WELL
!
        IF (NCSIZE.LE.1 .OR. OLD_METHOD) THEN
!
        DEP = CTRLSC(1+2*(ISEC-1))
        ARR = CTRLSC(2+2*(ISEC-1))
        IF(NCSIZE.GT.1) THEN
          DEP=GLOBAL_TO_LOCAL_POINT(DEP,MESH)
          ARR=GLOBAL_TO_LOCAL_POINT(ARR,MESH)
          IF(DEP.EQ.0.AND.ARR.EQ.0) THEN
            NSEG(ISEC)=0
            EXIT
          ENDIF
          IF((DEP.EQ.0.AND.ARR.NE.0).OR.(DEP.NE.0.AND.ARR.EQ.0)) THEN
            NSEG(ISEC)=-1
            EXIT
          ENDIF
        ENDIF
        PT = DEP
        ISEG = 0
        DIST=(X(DEP)-X(ARR))**2+(Y(DEP)-Y(ARR))**2
10      CONTINUE
!
        DO IELEM =1,NELEM
!
          I1 = IKLE(IELEM,1)
          I2 = IKLE(IELEM,2)
          I3 = IKLE(IELEM,3)
!         IF THE ELEMENT CONTAINS THE CURRENT POINT:
          IF(PT.EQ.I1.OR.PT.EQ.I2.OR.PT.EQ.I3) THEN
            DIST1 = (X(I1)-X(ARR))**2 + (Y(I1)-Y(ARR))**2
            DIST2 = (X(I2)-X(ARR))**2 + (Y(I2)-Y(ARR))**2
            DIST3 = (X(I3)-X(ARR))**2 + (Y(I3)-Y(ARR))**2
            IF(DIST1.LT.DIST) THEN
              DIST = DIST1
              ELBEST = IELEM
              IGBEST = I1
              ILBEST = 1
              IF(I1.EQ.PT) ILPREC = 1
              IF(I2.EQ.PT) ILPREC = 2
              IF(I3.EQ.PT) ILPREC = 3
            ENDIF
            IF(DIST2.LT.DIST) THEN
              DIST = DIST2
              ELBEST = IELEM
              IGBEST = I2
              ILBEST = 2
              IF(I1.EQ.PT) ILPREC = 1
              IF(I2.EQ.PT) ILPREC = 2
              IF(I3.EQ.PT) ILPREC = 3
            ENDIF
            IF(DIST3.LT.DIST) THEN
              DIST = DIST3
              ELBEST = IELEM
              IGBEST = I3
              ILBEST = 3
              IF(I1.EQ.PT) ILPREC = 1
              IF(I2.EQ.PT) ILPREC = 2
              IF(I3.EQ.PT) ILPREC = 3
            ENDIF
          ENDIF
!
        ENDDO !IELEM
!
        IF(IGBEST.EQ.PT) THEN
          IF(LNG.EQ.1) WRITE(LU,32)
          IF(LNG.EQ.2) WRITE(LU,33)
32        FORMAT(1X,'FLUSEC : BLOCAGE DE L''ALGORITHME')
33        FORMAT(1X,'FLUSEC : ALGORITHM FAILED')
          CALL PLANTE(1)
          STOP
        ELSE
          PT = IGBEST
          ISEG = ISEG + 1
          IF(ISEG.GT.NSEMAX) THEN
            IF(LNG.EQ.1) THEN
              WRITE(LU,*) 'FLUSEC : TROP DE SEGMENTS DANS UNE'
              WRITE(LU,*) '         SECTION. AUGMENTER NSEMAX'
            ENDIF
            IF(LNG.EQ.2) THEN
              WRITE(LU,*) 'FLUSEC: TOO MANY SEGMENTS IN A   '
              WRITE(LU,*) '        SECTION. INCREASE  NSEMAX'
            ENDIF
            CALL PLANTE(1)
            STOP
          ENDIF
          LISTE(ISEC,ISEG,1) = IKLE(ELBEST,ILPREC)
          LISTE(ISEC,ISEG,2) = IKLE(ELBEST,ILBEST)
          IF(IGBEST.NE.ARR) GO TO 10
        ENDIF
!
        NSEG(ISEC) = ISEG
!
!JAJ #### THIS PART TO BE DONE IN THE PARALLEL CASE; FILL LISTE
! WITH READY SEGMENT CHAINS PROVIDED BY PARTEL: SEE READ_SECTIONS
! NOTE: FUTURE OPTIMISATION - USE CHAIN STRUCTURE IN THE WHOLE ROUTINE
!
        ELSE
!
          NSEG(ISEC) = CHAIN(ISEC)%NSEG
          LISTE(ISEC,:,:)=0
          DO ISEG=1,NSEG(ISEC)
            LISTE(ISEC,ISEG,1) = CHAIN(ISEC)%LISTE(ISEG,1)
            LISTE(ISEC,ISEG,2) = CHAIN(ISEC)%LISTE(ISEG,2)
          END DO
          WRITE(LU,*) 'CHAIN@SISYPHE -> LISTE@SISYPHE:'
          WRITE(LU,*) 'ISEC,NSEG(ISEC): ',ISEC,NSEG(ISEC)
          DO ISEG=1,NSEG(ISEC)
            WRITE(LU,*) LISTE(ISEC,ISEG,:)
          END DO
        ENDIF
!
      ENDDO
!
!     IF(.NOT.DEJA) THEN
      ENDIF
!
!-----------------------------------------------------------------------
!
      DEJA = .TRUE.
!
!-----------------------------------------------------------------------
!
      DO ISEC = 1 , NSEC
!
      FLX(ISEC)  = 0.D0
      FLXS(ISEC) = 0.D0
      FLXC(ISEC) = 0.D0
!
      IF(NSEG(ISEC).GE.1) THEN
!
!     COMPUTES THE FLUX DIRECTLY, REGARDLESS OF THE WEAK FORM
!     OF THE IMPERMEABILITY CONDITION
!
      DO ISEG = 1 , NSEG(ISEC)
        I1 = LISTE(ISEC,ISEG,1)
        I2 = LISTE(ISEC,ISEG,2)
        X1 = X(I1)
        X2 = X(I2)
        Y1 = Y(I1)
        Y2 = Y(I2)
        H1 = H%R(I1)
        H2 = H%R(I2)
        NX = Y1-Y2
        NY = X2-X1
        UN1= U%R(I1)*NX + V%R(I1)*NY
        UN2= U%R(I2)*NX + V%R(I2)*NY
        FLX(ISEC) = FLX(ISEC) + ((H1+H2)*(UN1+UN2)+H2*UN2+H1*UN1)*SUR6
        IF(SUSP) THEN
          UN1= QSXS%R(I1)*NX + QSYS%R(I1)*NY
          UN2= QSXS%R(I2)*NX + QSYS%R(I2)*NY
          FLXS(ISEC) = FLXS(ISEC) + 0.5D0*(UN1+UN2)
        ENDIF
        IF(CHARR) THEN
          UN1= QSXC%R(I1)*NX + QSYC%R(I1)*NY
          UN2= QSXC%R(I2)*NX + QSYC%R(I2)*NY
          FLXC(ISEC) = FLXC(ISEC) + 0.5D0*(UN1+UN2)
        ENDIF
      ENDDO
!
      IF(FLX(ISEC).GT.0.D0) THEN
        VOLPOS(ISEC) = VOLPOS(ISEC) + FLX(ISEC)*DT
      ELSE
        VOLNEG(ISEC) = VOLNEG(ISEC) + FLX(ISEC)*DT
      ENDIF
!
      IF(SUSP) THEN
        IF(FLXS(ISEC).GT.0.D0) THEN
          VOLPOSS(ISEC) = VOLPOSS(ISEC) + FLXS(ISEC)*DT
        ELSE
          VOLNEGS(ISEC) = VOLNEGS(ISEC) + FLXS(ISEC)*DT
        ENDIF
      ENDIF
!
      IF(CHARR) THEN
        IF(FLXC(ISEC).GT.0.D0) THEN
          VOLPOSC(ISEC) = VOLPOSC(ISEC) + FLXC(ISEC)*DT
        ELSE
          VOLNEGC(ISEC) = VOLNEGC(ISEC) + FLXC(ISEC)*DT
        ENDIF
      ENDIF
!
!     IF(NSEG(ISEC).GT.1)...
      ENDIF
!
      ENDDO
!
!-----------------------------------------------------------------------
!
!     PRINTS THE RESULTS / !JAJ HERE ALLREDUCES FOR VALUES
!
      CALL FLUXPR_SISYPHE(NSEC,CTRLSC,FLX,VOLNEG,VOLPOS,INFO,TPS,
     &                    NSEG,NCSIZE,
     &                    FLXS,VOLNEGS,VOLPOSS,SUSP,
     &                    FLXC,VOLNEGC,VOLPOSC,CHARR)
!
!-----------------------------------------------------------------------
!
!      WRITE(LU,*) '-> LEAVING FLUSEC_SISYPHE'
      RETURN
      END
