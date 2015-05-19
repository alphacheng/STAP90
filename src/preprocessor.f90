!---------------------------------------------------------------
!           ��ANSYS������ļ�ת����STAP90.IN�ļ�
!  �����3T/4Q��Ԫ,ANSYS�����ļ���ANS.IN,����ļ�ΪSTAP90.IN
!---------------------------------------------------------------	
SUBROUTINE PREOPENFILES()
! . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
! .                                                                   .
! .   ����ǰ����ʱ�Ĵ��ļ����Ӻ���                                  .
! . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

  USE GLOBALS

  IMPLICIT NONE
  LOGICAL :: EX
  CHARACTER*80 FileInp
  
  CALL PREPROCESSOR

  INQUIRE(FILE = 'STAP90.IN', EXIST = EX)
  IF (.NOT. EX) THEN
     PRINT *, "*** STOP *** FILE STAP90.IN DOES NOT EXIST !"
     STOP
  END IF

  OPEN(IIN   , FILE = "STAP90.IN",  STATUS = "OLD")
  OPEN(IOUT  , FILE = "STAP90.OUT", STATUS = "REPLACE")
  OPEN(10  , FILE = "DATA.OUT", STATUS = "REPLACE")
  OPEN(IELMNT, FILE = "ELMNT.TMP",  FORM = "UNFORMATTED")
  OPEN(ILOAD , FILE = "LOAD.TMP",   FORM = "UNFORMATTED")
  
    END SUBROUTINE PREOPENFILES
    
    
SUBROUTINE PREPROCESSOR
!---------------------------------------------------------------
!           ��ANSYS������ļ�ת����STAP90.IN�ļ�
!  �����3T/4Q��Ԫ,ANSYS�����ļ���ANS.IN,����ļ�ΪSTAP90.IN
!---------------------------------------------------------------	
IMPLICIT NONE

INTEGER :: NUMP,NUME,NUMMAT,NUMEG
REAL(8),ALLOCATABLE :: POS(:,:)       !�ڵ��������
INTEGER,ALLOCATABLE :: IEN(:,:)       !��ԪIEN����
INTEGER :: ELETY                      !��Ԫ����
INTEGER,ALLOCATABLE :: ID(:,:)        !�������ɶ��Ƿ�Լ��
REAL(8),ALLOCATABLE :: F(:,:)         !�����ڵ�������Ƿ��м����غ�
INTEGER :: NPAR1
TYPE MATERIAL
    REAL(8)::E
    REAL(8)::P
    REAL(8)::DENS
    REAL(8)::AREA
END TYPE
TYPE(MATERIAL)::MAT
INTEGER::I,J
INTEGER::NUMC
REAL(8)::FORCE
CHARACTER(6)::P,P1,P2
INTEGER::IANS=1
INTEGER::IIN=2
OPEN(IIN,FILE="STAP90.IN",STATUS="UNKNOWN")
OPEN(IANS,FILE="ANS.IN",STATUS="OLD")
!���뵥Ԫ���ڵ㣬���ϣ���Ԫ�����
DO WHILE (.TRUE.)
	READ (IANS,'(A5)') P
	IF (P=='*ELSE') THEN
		READ (IANS,'(12X,I9)') NUMP
		READ (IANS,'(12X,I9)') NUME
		EXIT
	ELSE
		CYCLE
	ENDIF
ENDDO
!���뵥Ԫ����
DO WHILE (.TRUE.)
	READ (IANS,'(A3)') P
	IF (P=='DOF') THEN
	    READ (IANS,'(12X,I3)') ELETY
	    EXIT
	ELSE
	    CYCLE
	ENDIF		
ENDDO
!��������ڵ������
ALLOCATE(POS(3,NUMP))
DO WHILE (.TRUE.)
	READ (IANS,'(A6)') P
	IF (P=='(3i9,6') THEN
		DO I=1,NUMP
			READ (IANS,'(27X,3F20.13)') POS(1,I),POS(2,I),POS(3,I)
		ENDDO
		EXIT
	ELSE 
	    CYCLE
	ENDIF
ENDDO
!���뵥Ԫ�Ľڵ��ȫ�ֱ��
IF (ELETY==180) THEN
    ALLOCATE(IEN(2,NUME))
ELSEIF (ELETY==182) THEN
    ALLOCATE(IEN(4,NUME))
ENDIF
DO WHILE (.TRUE.)
	READ (IANS,'(A6)') P
	IF (P=='(19i9)') THEN
	    DO I=1,NUME
	        IF (ELETY==182) THEN
 			    READ (IANS,'(99X,4I9)') IEN(1,I),IEN(2,I),IEN(3,I),IEN(4,I)
 			ELSEIF (ELETY==180) THEN
 			    READ (IANS,'(99X,2I9)') IEN(1,I),IEN(2,I)
 			ENDIF
		ENDDO
		EXIT
	ELSE
		CYCLE
	ENDIF
ENDDO
!����߽�����
ALLOCATE(ID(3,NUMP),F(3,NUMP))
DO I=1,NUMP
    ID(1,I)=0;ID(2,I)=0;ID(3,I)=1
    F=0
ENDDO
NUMC=0    !���������غɸ���
DO WHILE (.TRUE.)
	READ (IANS,'(A5)') P
	IF (P=='ERESX') THEN
	    !��ȡ��һ��Ҫ�Ȼ�һ��
	    READ (IANS,'(/,A1)',ADVANCE='NO') P2
		IF (P2=='D') THEN
			READ (IANS,'(X,I7,X,A2)') I,P1
			IF (P1=='UX') THEN
				ID(1,I)=1
			ELSEIF (P1=='UY') THEN
			    ID(2,I)=1
			ELSEIF (P1=='UZ') THEN
				ID(3,I)=1
			ENDIF
		ELSEIF (P2=='F') THEN
			READ (IANS,'(X,I7,X,A2,3X,F12.4)') I,P1,FORCE
			IF (FORCE/=0) NUMC=NUMC+1
			IF (P1=='FX') THEN
				F(1,I)=FORCE
			ELSEIF (P1=='FY') THEN
				F(2,I)=FORCE
			ELSEIF (P1=='FZ') THEN
				F(3,I)=FORCE
			ENDIF
		ENDIF
		DO WHILE (.TRUE.)
			READ (IANS,'(A1)',ADVANCE='NO') P2
			IF (P2=='D') THEN
				READ (IANS,'(X,I7,X,A2)') I,P1
				IF (P1=='UX') THEN
					ID(1,I)=1
				ELSEIF (P1=='UY') THEN
					ID(2,I)=1
				ELSEIF (P1=='UZ') THEN
					ID(3,I)=1
				ENDIF
			ELSEIF (P2=='F') THEN
				READ (IANS,'(X,I7,X,A2,3X,F16.9)') I,P1,FORCE
				IF (FORCE/=0) NUMC=NUMC+1
				IF (P1=='FX') THEN
					F(1,I)=FORCE
				ELSEIF (P1=='FY') THEN
					F(2,I)=FORCE
				ELSEIF (P1=='FZ') THEN
					F(3,I)=FORCE
				ENDIF
	        ELSE
				GOTO 1000
			ENDIF
		ENDDO
	ELSE
	    CYCLE
	ENDIF
ENDDO
!�˹������������
1000WRITE(*,*) '���뵥Ԫ���� NPAR1=:(truss=1,4Q=2,3T=3,8H=4,beam=5,plate=6,shell=7) '
READ(*,*) NPAR1
WRITE(*,*) '��������ģ�� E=: '
READ(*,*) MAT%E
WRITE(*,*) '�����ܶ� DENS=: '
READ(*,*) MAT%DENS
IF (ELETY==180) THEN
    WRITE(*,*) '�������� AREA=: '
    READ(*,*) MAT%AREA
ELSEIF (ELETY==182) THEN
    WRITE(*,*) '���벴�ɱ� PO=: '
    READ(*,*) MAT%P
ENDIF
!���STAP90.IN
!���������
WRITE (IIN,'(A40)') 'CESHI FOR YOUXIANYUAN---BY ZLX'     
!���������        
WRITE (IIN,'(5I5)') NUMP,1,1,1,3       
!����ڵ�����
DO I=1,NUMP
	WRITE (IIN,'(4I5,3F10.5)') I,ID(1,I),ID(2,I),ID(3,I),POS(1,I),POS(2,I),POS(3,I)
ENDDO
!����غ����ݿ�����
WRITE (IIN,'(2I5)') 1,NUMC
!�������������
DO I=1,NUMP
	DO J=1,3
		IF (F(J,I)/=0) THEN
			WRITE (IIN,'(2I5,F10.0)') I,J,F(J,I)
		ENDIF
	ENDDO
ENDDO
!�����Ԫ������
IF (ELETY==180) THEN
    WRITE (IIN,'(4I5)') 1,NUME,1,1
ELSEIF (ELETY==182) THEN
    IF (NPAR1==2) THEN
        WRITE (IIN,'(4I5)') 2,NUME,1,1
    ELSE
        WRITE (IIN,'(4I5)') 3,2*NUME,1,1
    ENDIF
ENDIF

!�����������
IF (ELETY==180) THEN
	WRITE (IIN,'(I5,E10.3,2F10.5)') 1,MAT%E,MAT%AREA,MAT%DENS
ELSEIF (ELETY==182) THEN
    WRITE (IIN,'(I5,E10.3,2F10.5)') 1,MAT%E,MAT%P,MAT%DENS
ENDIF
!�����Ԫ����
DO I=1,NUME
    IF (ELETY==180) THEN
	    WRITE (IIN,'(4I5)') I,IEN(1,I),IEN(2,I),1
    ELSEIF (ELETY==182) THEN
        IF (NPAR1==2) THEN
	        WRITE (IIN,'(6I5)') I,IEN(1,I),IEN(2,I),IEN(3,I),IEN(4,I),1
        ELSE
            WRITE (IIN,'(5I5)') 2*I-1,IEN(1,I),IEN(2,I),IEN(3,I),1
            WRITE (IIN,'(5I5)') 2*I,IEN(3,I),IEN(4,I),IEN(1,I),1
        ENDIF
	ENDIF
ENDDO

    END SUBROUTINE
    
