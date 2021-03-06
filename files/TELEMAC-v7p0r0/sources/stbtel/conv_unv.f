      MODULE CONV_UNV
      CONTAINS
!                       ***************** 
                        SUBROUTINE READ_UNV 
!                       *****************
     &(UNVFILE,LOGFILE2)
!
!***********************************************************************
! STBTEL   V6P1                                   11/07/2011
!***********************************************************************
!
!BRIEF    READS A FILE OF UNV FORMAT AND FILL THE MESH OBJECT
!                        
!HISTORY  Y.AUDOUIN (EDF)
!+        11/07/2011
!+        V6P1
!+   CREATION OF THE FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| UNVFILE        |-->| NAME OF THE UNV FILE IN THE TEMPORARY FOLDER
!| LOGFILE2       |-->| NAME OF THE LOG FILE IN THE TEMPORARY FOLDER
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_STBTEL
!      
      IMPLICIT NONE
      ! LANGAE AND OUTPUT VALUE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=MAXLENHARD), INTENT(IN) :: UNVFILE
      CHARACTER(LEN=MAXLENHARD), INTENT(IN) :: LOGFILE2
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER :: IERR
      INTEGER :: IB(6),I,J,IDUM
      LOGICAL :: READ_NSEC1,READ_NSEC2,READ_NSEC3
      INTEGER :: ELEM, NSEC
      INTEGER, PARAMETER :: TITLE_SEC=151
      INTEGER, PARAMETER :: COOR_SEC=2411
      INTEGER, PARAMETER :: CONN_SEC=2412
      CHARACTER*200 :: LINE
      INTEGER :: POS
      INTEGER :: VALUES(MAXFAM)
      INTEGER :: IELEM, IELEM2, NELEMTOTAL
      INTEGER, ALLOCATABLE :: TEMPO(:)
      INTEGER, ALLOCATABLE :: TMP(:)
      INTEGER :: ICOLOR
      CHARACTER*4 :: BLANC
      CHARACTER*2 :: MOINS1
      INTEGER :: NFAMNODE,NFAMELEM
      CHARACTER*32, ALLOCATABLE :: TMP_NAMEFAM(:)
      INTEGER, ALLOCATABLE :: TMP_IDFAM(:)
      INTEGER, ALLOCATABLE :: TMP_VALFAM(:)
      INTEGER, ALLOCATABLE :: TMP_NGROUPFAM(:)
      CHARACTER(LEN=LNAME_SIZE), ALLOCATABLE :: TMP_GROUPFAM(:,:)
!      
      WRITE(LU,*) '----------------------------------------------------'
      IF(LNG.EQ.1) WRITE(LU,*) '------DEBUT LECTURE DU FICHIER UNV'
      IF(LNG.EQ.2) WRITE(LU,*) '------BEGINNING READING OF UNV FILE'
      WRITE(LU,*) '----------------------------------------------------'
!      
!-----------------------------------------------------------------------
!
      IDUM=0
      ! READING THE LOG FILE FIRST IT CONTAINS THE GENERIC INFORMATIONS
      OPEN(NLOG,IOSTAT=IERR,FILE=LOGFILE2,FORM='FORMATTED')
      CALL FNCT_CHECK(IERR,'OPEN '//TRIM(LOGFILE2))
!
      ! THE FIRST LINE CONTAINS THE NUMBER OF NODES AFTER A TEXT DESCRIPTOR.
      ! WE READ A LINE, LOCATE THE COLON ':' TO THEN READ THE NUMBER.
      READ(NLOG,'(A200)') LINE
      POS =INDEX(LINE,':') + 1
      READ(UNIT=LINE(POS:),FMT=*) MESH2%NPOIN
      IF(DEBUG.AND.(LNG.EQ.1)) WRITE(LU,*) 'NOMBRE DE POINTS : ',
     &         MESH2%NPOIN
      IF(DEBUG.AND.(LNG.EQ.2)) WRITE(LU,*) 'NUMBER OF POINT: ',
     &         MESH2%NPOIN
!
      ! THE SECOND LINE CONTAINS THE NUMBER OF ELEMENTS AFTER A TEXT DESCRIPTOR.
      ! WE READ A LINE, LOCATE THE COLON ':' AND THEN READ THE NUMBER.
      READ(NLOG,'(A200)') LINE
      POS =INDEX(LINE,':') + 1
      READ(UNIT=LINE(POS:),FMT=*) NELEMTOTAL
      IF(DEBUG.AND.(LNG.EQ.1)) WRITE(LU,*) 'NOMBRE D ELEMENTS : ',
     &         NELEMTOTAL
      IF(DEBUG.AND.(LNG.EQ.2)) WRITE(LU,*) 'NUMBER OF ELEMENTS: ',
     &         NELEMTOTAL
!
      CLOSE(NLOG,IOSTAT=IERR)
      CALL FNCT_CHECK(IERR,'CLOSE '//TRIM(LOGFILE2))
!      
      ! READING THE UNV FILE
      OPEN(NINP,IOSTAT=IERR,FILE=UNVFILE,FORM='FORMATTED')
      CALL FNCT_CHECK(IERR,'OPEN '//TRIM(UNVFILE))
      READ_NSEC1=.FALSE.
      READ_NSEC2=.FALSE.
      READ_NSEC3=.FALSE.
!
      DO WHILE (.NOT. (READ_NSEC1.AND.READ_NSEC2.AND.READ_NSEC3))
        ! READING UNTIL WE FIND A SECTION
        MOINS1 = '  '
        BLANC  = '1111'
        DO WHILE (MOINS1.NE.'-1' .OR. BLANC.NE.'    ')
          READ(NINP,'(A4,A2)') BLANC,MOINS1 
        ENDDO
        ! READING THE SECTION NUMBER
        NSEC=-1
        DO WHILE (NSEC.EQ.-1)
          READ(NINP,*) NSEC
        ENDDO
        ! DEPENDING OF THE SECTION
        SELECT CASE(NSEC)
        CASE(TITLE_SEC)
          IF(LNG.EQ.1) WRITE(LU,*) '---SECTION TITRE'
          IF(LNG.EQ.2) WRITE(LU,*) '---TITLE SECTION'
          ! READING THE MESH TITLE
          READ(NINP,'(A80)') LINE
          LINE=ADJUSTL(LINE)
          MESH2%TITLE = LINE(1:72)
          IF(DEBUG.AND.(LNG.EQ.1)) WRITE(LU,*) 'TITRE : ',MESH2%TITLE
          IF(DEBUG.AND.(LNG.EQ.2)) WRITE(LU,*) 'TITLE : ',MESH2%TITLE
          READ_NSEC1=.TRUE.
        CASE(COOR_SEC)
          IF(LNG.EQ.1) WRITE(LU,*) '---SECTION COORDONNEES'
          IF(LNG.EQ.2) WRITE(LU,*) '---COORDINATES SECTION'
          ! READING THE COORDINATES AND THE COLOR OF THE NODES
          ALLOCATE(MESH2%X(MESH2%NPOIN),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%X')
          ALLOCATE(MESH2%Y(MESH2%NPOIN),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%Y')
          ALLOCATE(MESH2%Z(MESH2%NPOIN),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%Z')
          ALLOCATE(MESH2%COLOR(MESH2%NPOIN),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%COLOR')
          ALLOCATE(TEMPO(MESH2%NPOIN),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE TEMPO')
          NFAMNODE = 0
          VALUES = 0
          DO I=1,MESH2%NPOIN
            READ(NINP,*) J,IDUM,IDUM,MESH2%COLOR(I)
            TEMPO(J) = I
            IF(MESH2%COLOR(I).NE.0) THEN
              ! TEST IF IT'S A NEW COLOR
              IF(COUNT(VALUES.EQ.MESH2%COLOR(I)).EQ.0) THEN
                NFAMNODE = NFAMNODE + 1
                VALUES(NFAMNODE) = MESH2%COLOR(I)
              ENDIF
            ENDIF
            READ(NINP,*) MESH2%X(I), MESH2%Y(I), MESH2%Z(I) 
          ENDDO
          ! BUIDING THE FAMILIES IN TEMPORARY TABLES
          ! BECAUSE WE HAVE TO WANT FOR THE FAMILIES ON ELEMENTS
          IF(DEBUG.AND.(LNG.EQ.1)) WRITE(LU,*) 
     &          'NOMBRE DE FAMILLES SUR LES NOEUDS : ',NFAMNODE
          IF(DEBUG.AND.(LNG.EQ.2)) WRITE(LU,*) 
     &          'NUMBER OF NODES FAMILIES: ',NFAMNODE
          ALLOCATE(TMP_IDFAM(NFAMNODE),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE TMP_IDFAM')
          ALLOCATE(TMP_NAMEFAM(NFAMNODE),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE TMP_NAMEFAM')
          ALLOCATE(TMP_VALFAM(NFAMNODE),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE TMP_VALFAM')
          ALLOCATE(TMP_NGROUPFAM(NFAMNODE),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE TMP_NGROUPFAM')
          ALLOCATE(TMP_GROUPFAM(NFAMNODE,10),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE TMP_GROUPFAM')
          DO I=1,NFAMNODE
            TMP_IDFAM(I) = I
            TMP_VALFAM(I) = VALUES(I)
            TMP_NAMEFAM(I) = 'FAM_COLOR_NODES_'//TRIM(I2CHAR(VALUES(I)))
            TMP_NGROUPFAM(I) = 1
            TMP_GROUPFAM(I,1) = 'COLOR_NODES_'//TRIM(I2CHAR(VALUES(I)))
            IF(DEBUG) WRITE(LU,*) 'NAMEFAM: ',TMP_NAMEFAM(I)
            IF(DEBUG) WRITE(LU,*) 'IDFAM  : ',TMP_IDFAM(I)
            IF(DEBUG) WRITE(LU,*) 'VALFAM : ',TMP_VALFAM(I)
            IF(DEBUG) WRITE(LU,*) 'NGROUP : ',TMP_NGROUPFAM(I)
            IF(DEBUG) WRITE(LU,*) 'GROUPS : ',TRIM(TMP_GROUPFAM(I,1))
          ENDDO
          READ_NSEC2=.TRUE.
        CASE(CONN_SEC)
          IF(LNG.EQ.1) WRITE(LU,*) '---SECTION CONNECTIVITE'
          IF(LNG.EQ.2) WRITE(LU,*) '---CONNECTIVITY SECTION'
          ! READING THE CONNECTIVITY TABLE (IKLES)
          ! DEPENDING OF THE TYPE OF THE ELEMENT WE ARE FILLING IKLES
          ! OR IKLES2
          ! WE HAVE TO ALLOCATE THE TABLE TO THEIR MAXIMUN SIZE BECAUSE
          ! WE DON'T KNOW THE REAL SIZE
          ALLOCATE(MESH2%IKLES(NELEMTOTAL*6),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IKLES')
          ALLOCATE(MESH2%IKLES2(NELEMTOTAL*6),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IKLES2')
          ALLOCATE(MESH2%NCOLOR(NELEMTOTAL),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NCOLOR')
          ALLOCATE(MESH2%NCOLOR2(NELEMTOTAL),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NCOLOR2')
          ! READING THE CONNECTIVITY
          IELEM = 0
          IELEM2 = 0
          DO I=1,NELEMTOTAL
            READ(NINP,*) NSEC,ELEM,IDUM,IDUM,ICOLOR,IDUM
            ! IF WE ARE AT THE END OF THE CONNECTIVITY INFORMATIONS
            IF(NSEC.EQ.-1) THEN
              IF(LNG.EQ.2) THEN
                WRITE(LU,*) 'NUMBER OF ELEMENTS NON VALID IN LOG FILE'
                WRITE(LU,*) 'IS:',NELEMTOTAL
                WRITE(LU,*) 'SHOULD BE:',IELEM+IELEM2
              ENDIF
              IF(LNG.EQ.2) THEN
                WRITE(LU,*) 'NOMBRE ELEMENT ERRONEE DANS LE FICHIER LOG'
                WRITE(LU,*) 'IL YA :',NELEMTOTAL, 'ELEMENTS'
                WRITE(LU,*) 'DEVRAIT Y AVOIR :',IELEM+IELEM2
              ENDIF
              READ_NSEC3 = .TRUE.
              CYCLE
            ENDIF
            SELECT CASE (ELEM) 
            ! TRIANGLE
            CASE (91,41)
              IELEM2 = IELEM2 + 1
              MESH2%TYPE_ELEM2 = TYPE_TRIA3
              MESH2%NDP2 = 3
              READ(NINP,*)(IB(J),J=1,MESH2%NDP2)
              DO J=1,MESH2%NDP2
                MESH2%IKLES2((IELEM2-1)*MESH2%NDP2+J) = TEMPO(IB(J))
              ENDDO
              MESH2%NCOLOR2(IELEM2) = ICOLOR
            ! SQUARE
            CASE (44,94)
              IELEM2 = IELEM2 + 1
              MESH2%TYPE_ELEM2 = TYPE_QUAD4
              MESH2%NDP2 = 4
              READ(NINP,*)(IB(J),J=1,MESH2%NDP2)
              DO J=1,MESH2%NDP2
                MESH2%IKLES2((IELEM2-1)*MESH2%NDP2+J) = TEMPO(IB(J))
              ENDDO
              MESH2%NCOLOR2(IELEM2) = ICOLOR
            ! TETRAEDRON
            CASE (111)
              IELEM = IELEM + 1
              MESH2%TYPE_ELEM = TYPE_TETRA4
              MESH2%NDP = 4
              READ(NINP,*)(IB(J),J=1,MESH2%NDP)
              DO J=1,MESH2%NDP
                MESH2%IKLES((IELEM-1)*MESH2%NDP+J) = TEMPO(IB(J))
              ENDDO
              MESH2%NCOLOR(IELEM) = ICOLOR
            ! PRISM
            CASE (112)
              IELEM = IELEM + 1
              MESH2%TYPE_ELEM = TYPE_PRISM6
              MESH2%NDP = 6
              READ(NINP,*)(IB(J),J=1,MESH2%NDP)
              DO J=1,MESH2%NDP
                MESH2%IKLES((IELEM-1)*MESH2%NDP+J) = TEMPO(IB(J))
              ENDDO
              MESH2%NCOLOR(IELEM) = ICOLOR
            CASE DEFAULT
              IF(LNG.EQ.1) WRITE(LU,*) 'TYPE UNV INCONNU :',ELEM
              IF(LNG.EQ.2) WRITE(LU,*) 'UNKNOWN UNV TYPE:',ELEM
              CALL PLANTE(1)
            END SELECT
          ENDDO
          DEALLOCATE(TEMPO)
          ! IF NO 3D ELEMENTS
          IF(IELEM.EQ.0) THEN
            ! IT MEANS WE ARE IN 2D 
            MESH2%NDIM = 2
            ! WE DON'T NEED Z
            DEALLOCATE(MESH2%Z)
            ! RECOPY 
            MESH2%NELEM = IELEM2
            MESH2%TYPE_ELEM = MESH2%TYPE_ELEM2
            MESH2%NDP = MESH2%NDP2
            DEALLOCATE(MESH2%NCOLOR)
            ALLOCATE(MESH2%NCOLOR(MESH2%NELEM),STAT=IERR)
            CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NCOLOR BIS')
            MESH2%NCOLOR = MESH2%NCOLOR2(1:MESH2%NELEM)
            DEALLOCATE(MESH2%IKLES)
            ALLOCATE(MESH2%IKLES(MESH2%NELEM*MESH2%NDP),STAT=IERR)
            CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IKLES BIS')
            MESH2%IKLES = MESH2%IKLES2(1:MESH2%NELEM*MESH2%NDP)
            ! DESTROY
            DEALLOCATE(MESH2%IKLES2)
            DEALLOCATE(MESH2%NCOLOR2)
            MESH2%NDP2 = 0
            MESH2%TYPE_ELEM2 = 0
            MESH2%NELEM2 = 0
          ELSE
            MESH2%NELEM = IELEM
            MESH2%NELEM2 = IELEM2
            MESH2%NDIM = 3
            MESH2%IB(7) = 1
            ! IF WE HAVE 2D ELEMENTS
            IF(IELEM2.NE.0) THEN
              ! RESIZE THE IKLES AND COLOR TABLE TABLES
              ALLOCATE(TMP(MAX(MESH2%NELEM2*MESH2%NDP2,
     &                 MESH2%NELEM*MESH2%NDP)),STAT=IERR)
              CALL FNCT_CHECK(IERR,'ALLOCATE TMP')
              !IKLES
              TMP(1:MESH2%NELEM*MESH2%NDP) = 
     &            MESH2%IKLES(1:MESH2%NELEM*MESH2%NDP)
              DEALLOCATE(MESH2%IKLES)
              ALLOCATE(MESH2%IKLES(MESH2%NELEM*MESH2%NDP),STAT=IERR)
              CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IKLES BIS')
              MESH2%IKLES = TMP(1:MESH2%NELEM*MESH2%NDP)
              ! IKLES2
              TMP(1:MESH2%NELEM2*MESH2%NDP2) = 
     &            MESH2%IKLES2(1:MESH2%NELEM2*MESH2%NDP2)
              DEALLOCATE(MESH2%IKLES2)
              ALLOCATE(MESH2%IKLES2(MESH2%NELEM2*MESH2%NDP2),STAT=IERR)
              CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IKLES2 BIS')
              MESH2%IKLES2 = TMP(1:MESH2%NELEM2*MESH2%NDP2)
              ! NCOLOR
              TMP(1:MESH2%NELEM) = MESH2%NCOLOR(1:MESH2%NELEM)
              DEALLOCATE(MESH2%NCOLOR)
              ALLOCATE(MESH2%NCOLOR(MESH2%NELEM),STAT=IERR)
              CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NCOLOR BIS')
              MESH2%NCOLOR = TMP(1:MESH2%NELEM)
              ! NCOLOR2
              TMP(1:MESH2%NELEM2) = MESH2%NCOLOR2(1:MESH2%NELEM2)
              DEALLOCATE(MESH2%NCOLOR2)
              ALLOCATE(MESH2%NCOLOR2(MESH2%NELEM2),STAT=IERR)
              CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NCOLOR2 BIS')
              MESH2%NCOLOR2 = TMP(1:MESH2%NELEM2)
              DEALLOCATE(TMP)
            ENDIF
          ENDIF
          IF(DEBUG) WRITE(LU,*) 'NDIM : ',MESH2%NDIM
          ! FINDING THE NEW FAMILIES
          NFAMELEM = 0
          VALUES(:) = 0
          DO I=1,MESH2%NELEM
            ! TEST IF IT'S A NEW COLOR
            IF(COUNT(VALUES.EQ.MESH2%NCOLOR(I)).EQ.0) THEN
              NFAMELEM = NFAMELEM + 1
              VALUES(NFAMELEM) = MESH2%NCOLOR(I)
            ENDIF
          ENDDO
          IF(MESH2%NELEM2.NE.0) THEN
            DO I=1,MESH2%NELEM2
              ! TEST IF IT'S A NEW COLOR
              IF(COUNT(VALUES.EQ.MESH2%NCOLOR2(I)).EQ.0) THEN
                NFAMELEM = NFAMELEM + 1
                VALUES(NFAMELEM) = MESH2%NCOLOR2(I)
              ENDIF
            ENDDO
          ENDIF
          MESH2%NFAM = NFAMNODE + NFAMELEM
          ! ALLOCATAING THE TABLE
          ALLOCATE(MESH2%IDFAM(MESH2%NFAM),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IDFAM')
          ALLOCATE(MESH2%NAMEFAM(MESH2%NFAM),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NAMEFAM')
          ALLOCATE(MESH2%VALFAM(MESH2%NFAM),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%VALFAM')
          ALLOCATE(MESH2%NGROUPFAM(MESH2%NFAM),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%VALFAM')
          ALLOCATE(MESH2%GROUPFAM(MESH2%NFAM,1),STAT=IERR)
          CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%VALFAM')
          ! COPYING NODES FAMILY FROM THE TMP TABLES
          DO I=1,NFAMNODE
            MESH2%IDFAM(I) = TMP_IDFAM(I)
            MESH2%NAMEFAM(I) = TMP_NAMEFAM(I)
            MESH2%VALFAM(I) = TMP_VALFAM(I)
            MESH2%NGROUPFAM(I) = TMP_NGROUPFAM(I)
            MESH2%GROUPFAM(I,1) = TMP_GROUPFAM(I,1)
          ENDDO
          DEALLOCATE(TMP_GROUPFAM,TMP_NGROUPFAM,TMP_IDFAM,
     &               TMP_VALFAM,TMP_NAMEFAM)
          ! ADDING HE ELEMENTS FAMILIES
          DO I=1,NFAMELEM
            MESH2%IDFAM(I+NFAMNODE) = -I
            MESH2%NAMEFAM(I+NFAMNODE) =
     &            'FAM_COLOR_FACES_'//TRIM(I2CHAR(VALUES(I)))
            MESH2%VALFAM(I+NFAMNODE) = VALUES(I)
            MESH2%NGROUPFAM(I+NFAMNODE) = 1
            MESH2%GROUPFAM(I+NFAMNODE,1) = 
     &            'COLOR_FACES_'//TRIM(I2CHAR(VALUES(I)))
            IF(DEBUG) WRITE(LU,*) 'NAMEFAM: ',MESH2%NAMEFAM(I+NFAMNODE)
            IF(DEBUG) WRITE(LU,*) 'IDFAM : ',MESH2%IDFAM(I+NFAMNODE)
            IF(DEBUG) WRITE(LU,*) 'VALFAM: ',MESH2%VALFAM(I+NFAMNODE)
            IF(DEBUG) WRITE(LU,*)'NGROUP : ',MESH2%NGROUPFAM(I+NFAMNODE)
            IF(DEBUG) WRITE(LU,*)'GROUP : ',MESH2%GROUPFAM(I+NFAMNODE,1)
          ENDDO
          READ_NSEC3=.TRUE.
        CASE DEFAULT
          IF(LNG.EQ.1) WRITE(LU,*) 'SECTION UNV INCONNUE :',NSEC
          IF(LNG.EQ.2) WRITE(LU,*) 'UNKNOWN UNV SECTION:',NSEC
        END SELECT
      ENDDO
      ! FILLING THE MISSING INFORMATIONS
      ALLOCATE(MESH2%IPOBO(MESH2%NPOIN),STAT=IERR)
      CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%IPOBO')
      MESH2%IPOBO(:) = 0
      ALLOCATE(MESH2%NAMECOO(MESH2%NDIM),STAT=IERR)
      CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%NAMECOO')
      ALLOCATE(MESH2%UNITCOO(MESH2%NDIM),STAT=IERR)
      CALL FNCT_CHECK(IERR,'ALLOCATE MESH2%UNITCOO')
      MESH2%NAMECOO(1) = 'X'
      MESH2%UNITCOO(1) = 'M'
      MESH2%NAMECOO(2) = 'Y'
      MESH2%UNITCOO(2) = 'M'
      IF(MESH2%NDIM.EQ.3) THEN
        MESH2%NAMECOO(3) = 'Z'
        MESH2%UNITCOO(3) = 'M'
        ! CHANGING IB IF IN 3D
        MESH2%IB(7) = 1
      ENDIF
      DO I=1,MESH2%NDIM
        CALL BLANC2USCORE(MESH2%NAMECOO(I),16)
        CALL BLANC2USCORE(MESH2%UNITCOO(I),16)
      ENDDO
!      
      CLOSE(NINP,IOSTAT=IERR)
      CALL FNCT_CHECK(IERR,'CLOSE '//TRIM(UNVFILE))
!      
!-----------------------------------------------------------------------
!
      WRITE(LU,*) '----------------------------------------------------'
      IF(LNG.EQ.1) WRITE(LU,*) '------FIN LECTURE DU FICHIER UNV'
      IF(LNG.EQ.2) WRITE(LU,*) '------ENDING READING OF UNV FILE'
      WRITE(LU,*) '----------------------------------------------------'
      END SUBROUTINE
!                       ***************** 
                        SUBROUTINE WRITE_UNV 
!                       *****************
     &(UNVFILE,LOGFILE2)
!
!***********************************************************************
! STBTEL   V6P1                                   11/07/2011
!***********************************************************************
!
!BRIEF    WRITE A FILE OF UNV FORMAT AND WITH THE MESH OBJECT
!+        INFORMATIONS
!                        
!HISTORY  Y.AUDOUIN (EDF)
!+        11/07/2011
!+        V6P1
!+   CREATION OF THE FILE
!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!| UNVFILE        |-->| NAME OF THE UNV FILE
!| LOGFILE2       |-->| NAME OF THE LOG FILE
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      USE DECLARATIONS_STBTEL
!      
      IMPLICIT NONE
      ! LANGAE AND OUTPUT VALUE
      INTEGER LNG,LU
      COMMON/INFO/LNG,LU
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      CHARACTER(LEN=MAXLENHARD), INTENT(IN) :: UNVFILE
      CHARACTER(LEN=MAXLENHARD), INTENT(IN) :: LOGFILE2
!
!+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
!
      INTEGER, PARAMETER :: TITLE_SEC=151
      INTEGER, PARAMETER :: COOR_SEC=2411
      INTEGER, PARAMETER :: CONN_SEC=2412
      INTEGER :: IB(6),I,J,IERR
      DOUBLE PRECISION :: XB(3)
      CHARACTER*80 :: TITLE2
      INTEGER, ALLOCATABLE :: NCOLOR(:)
      INTEGER, ALLOCATABLE :: MYVALFAM(:)
      INTEGER, ALLOCATABLE :: SORT(:)
      INTEGER :: ELEM
      INTEGER :: TEMPMIN
      INTEGER :: POS(1)
!      
      WRITE(LU,*) '----------------------------------------------------'
      IF(LNG.EQ.1) WRITE(LU,*) '------DEBUT ECRITURE DU FICHIER UNV'
      IF(LNG.EQ.2) WRITE(LU,*) '------BEGINNING WRITTING OF UNV FILE'
      WRITE(LU,*) '----------------------------------------------------'
!      
!-----------------------------------------------------------------------
!
      NOUT = 666
      OPEN(NOUT,IOSTAT=IERR,FILE=LOGFILE2,STATUS='NEW',FORM='FORMATTED')
      CALL FNCT_CHECK(IERR,'OPEN '//TRIM(LOGFILE2))
      WRITE(NOUT,*) 'TOTAL NO. OF NODES                   :',MESH2%NPOIN
      WRITE(NOUT,*) 'TOTAL NO. OF ELEMENTS                :',
     &              MESH2%NELEM+MESH2%NELEM2
      IF(MESH2%NFAM.NE.0) THEN
        WRITE(NOUT,*)'TOTAL NO. OF FAMILIES                :',MESH2%NFAM
        WRITE(NOUT,*) 'LIST OF FAMILIES, FAMILY_ID, COLOR_ID :'
        DO I=1,MESH2%NFAM
          WRITE(NOUT,'(A,A2,I4,A1,I4)') MESH2%NAMEFAM(I),' :',
     &                 MESH2%IDFAM(I),',',MESH2%VALFAM(I)
        ENDDO
        ALLOCATE(MYVALFAM(MESH2%NFAM))
        ALLOCATE(SORT(MESH2%NFAM))
        MYVALFAM = MESH2%VALFAM
        SORT = -1
        I = 0
        TEMPMIN = MINVAL(MYVALFAM)
        DO WHILE (TEMPMIN.LT.100)
          I = I + 1
          SORT(I) = TEMPMIN
          POS = MINLOC(MYVALFAM)
          DO WHILE (MYVALFAM(POS(1)).EQ.TEMPMIN)
            MYVALFAM(POS(1)) = 100
            POS = MINLOC(MYVALFAM)
          ENDDO
          TEMPMIN = MINVAL(MYVALFAM)
        ENDDO
        WRITE(NOUT,*) 'NUMBER OF EXTERNAL FACES         :',
     &                I-1
        WRITE(NOUT,*) 'PRIORITY FOR THE EXTERNAL FACES  :',
     &     (SORT(J),J=2,I)
        DEALLOCATE(MYVALFAM)
        DEALLOCATE(SORT)
      ELSE
        WRITE(NOUT,*) 'TOTAL NO. OF FAMILIES                :  0'
        WRITE(NOUT,*) 'LIST OF FAMILIES, FAMILY_ID, COLOR_ID :'
        WRITE(NOUT,*) 'NUMBER OF EXTERNAL FACES         :'
        WRITE(NOUT,*) 'PRIORITY FOR THE EXTERNAL FACES  :'
      ENDIF

      CLOSE(NOUT,IOSTAT=IERR)
      CALL FNCT_CHECK(IERR,'CLOSE '//TRIM(LOGFILE2))

      OPEN(NOUT,IOSTAT=IERR,FILE=UNVFILE,STATUS='NEW',FORM='FORMATTED')
      CALL FNCT_CHECK(IERR,'OPEN '//TRIM(UNVFILE))
!      
      ! WRITTING SECTION 1 TITLE
      IF(LNG.EQ.1) WRITE(LU,*) '---ECRITURE DE LA SECTION TITRE'
      IF(LNG.EQ.2) WRITE(LU,*) '---WRITTING TITLE SECTION'
      WRITE(NOUT,'(I6)') -1
      WRITE(NOUT,'(I6)') TITLE_SEC
      ! WRINTNG THE TITLE
      TITLE2 = MESH2%TITLE
      WRITE(NOUT,*) TITLE2
      ! END OF SECTION
      WRITE(NOUT,'(I6)') -1
!
      ! WRITTING SECTION 2 COORDINATES AND COLOR
      IF(LNG.EQ.1) WRITE(LU,*) '---ECRITURE DE LA SECTION COORDONEES'
      IF(LNG.EQ.2) WRITE(LU,*) '---WRITTING COORDINATES SECTION'
      WRITE(NOUT,'(I6)') -1
      WRITE(NOUT,'(I6)') COOR_SEC
      ! REBUILDING THE NCOLOR TABLE
      ALLOCATE(NCOLOR(MESH2%NPOIN),STAT=IERR)
      CALL FNCT_CHECK(IERR,'ALLOCATE NCOLOR POINT')
      ! IF COLOR EXIST THEN WE COPY ELSE SET TO 1
      IF(ALLOCATED(MESH2%COLOR)) THEN
        NCOLOR = MESH2%COLOR
      ELSE
        NCOLOR(:) = 1
      ENDIF
      ! WRITTING INFORMATIONS FOR EACH POINT
      DO I=1,MESH2%NPOIN
        WRITE(NOUT,'(4I10)') I,1,1,NCOLOR(I)
        XB(1) = MESH2%X(I)
        XB(2) = MESH2%Y(I)
        IF(MESH2%NDIM.EQ.2) THEN
          XB(3) = 0.D0
        ELSE
          XB(3) = MESH2%Z(I)
        ENDIF
        WRITE(NOUT,'(3D25.16)') XB(1),XB(2),XB(3)
      ENDDO
      DEALLOCATE(NCOLOR)
      ! END OF SECTION
      WRITE(NOUT,'(I6)') -1
!
      ! WRITTING SECTION 3 CONNECTIVITY TABLE
      IF(LNG.EQ.1) WRITE(LU,*) '---ECRITURE DE LA SECTION CONNECTIVITE'
      IF(LNG.EQ.2) WRITE(LU,*) '---WRITTING CONNECTIVITY SECTION'
      WRITE(NOUT,'(I6)') -1
      WRITE(NOUT,'(I6)') CONN_SEC
      ! IDENTIFY THE UNV TYPE NUMBER
      SELECT CASE(MESH2%TYPE_ELEM)
      CASE(TYPE_TRIA3)
        ELEM = 91
      CASE(TYPE_QUAD4)
        ELEM = 94
      CASE(TYPE_TETRA4)
        ELEM = 111
      CASE(TYPE_PRISM6)
        ELEM = 112
      END SELECT
      ALLOCATE(NCOLOR(MESH2%NELEM),STAT=IERR)
      CALL FNCT_CHECK(IERR,'ALLOCATE NCOLOR ELEM')
      ! IF COLOR EXIST THEN WE COPY ELSE SET TO 1
      IF(ALLOCATED(MESH2%NCOLOR)) THEN
        NCOLOR = MESH2%NCOLOR
      ELSE
        NCOLOR(:) = 1
      ENDIF
      DO I=1,MESH2%NELEM
        WRITE(NOUT,'(6I10)') I,ELEM,1,1,NCOLOR(I),MESH2%NDP
        DO J=1,MESH2%NDP
          IB(J) = MESH2%IKLES((I-1)*MESH2%NDP+J)
        ENDDO
        ! Estel 3d convention we need to swap order 1 and 2 for tetrahedron
        IF (ELEM.EQ.111) THEN
          IERR = IB(1)
          IB(1) = IB(2)
          IB(2) = IERR
        ENDIF
        WRITE(NOUT,'(6I10)') (IB(J),J=1,MESH2%NDP)
      ENDDO
      DEALLOCATE(NCOLOR)
      ! DOING IT FOR THE 2D ELEMENTS IF THEY EXIST
      IF(MESH2%NELEM2.NE.0) THEN
        SELECT CASE(MESH2%TYPE_ELEM2)
        CASE(TYPE_TRIA3)
          ELEM = 91
        CASE(TYPE_QUAD4)
          ELEM = 94
        CASE(TYPE_TETRA4)
          ELEM = 111
        CASE(TYPE_PRISM6)
          ELEM = 112
        END SELECT
        ALLOCATE(NCOLOR(MESH2%NELEM2),STAT=IERR)
        CALL FNCT_CHECK(IERR,'ALLOCATE NCOLOR ELEM2')
        ! IF COLOR EXIST THEN WE COPY ELSE SET TO 1
        IF(ALLOCATED(MESH2%NCOLOR2)) THEN
          NCOLOR = MESH2%NCOLOR2
        ELSE
          NCOLOR(:) = 1
        ENDIF
        DO I=1,MESH2%NELEM2
          WRITE(NOUT,'(6I10)') I+MESH2%NELEM,ELEM,1,1,
     &                         NCOLOR(I),MESH2%NDP2
          DO J=1,MESH2%NDP2
            IB(J) = MESH2%IKLES2((I-1)*MESH2%NDP2+J)
          ENDDO
          WRITE(NOUT,'(6I10)') (IB(J),J=1,MESH2%NDP2)
        ENDDO
        DEALLOCATE(NCOLOR)
      ENDIF
      ! END OF SECTION
      WRITE(NOUT,'(I6)') -1
!
      CLOSE(NOUT,IOSTAT=IERR)
      CALL FNCT_CHECK(IERR,'CLOSE '//TRIM(UNVFILE))
!      
!-----------------------------------------------------------------------
!
      WRITE(LU,*) '----------------------------------------------------'
      IF(LNG.EQ.1) WRITE(LU,*) '------FIN ECRITURE DU FICHIER UNV'
      IF(LNG.EQ.2) WRITE(LU,*) '------ENDING WRITTING OF UNV FILE'
      WRITE(LU,*) '----------------------------------------------------'
      END SUBROUTINE
      END MODULE
