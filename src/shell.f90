SUBROUTINE shell
! . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
! .                                                                   .
! .   To set up storage and call the shell element subroutine         .
! .                                                                   .
! . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

  USE GLOBALS
  USE MEMALLOCATE

  IMPLICIT NONE
  INTEGER :: NUME, NUMMAT, MM, N101, N102, N103, N104, N105, N106,N107

  NUME = NPAR(2)
  NUMMAT = NPAR(3)

! Allocate storage for element group data
  IF (IND == 1) THEN
      MM = 4*NUMMAT*ITWO + 21*NUME + 12*NUME*ITWO
      CALL MEMALLOC(11,"ELEGP",MM,1)
  END IF

  NFIRST=NP(11)   ! Pointer to the first entry in the element group data array
                  ! in the unit of single precision (corresponding to A)

! Calculate the pointer to the arrays in the element group data
! N101: E(NUMMAT)
! N102: PR(NUMMAT)
! N103: LM(20,NUME)
! N104: XYZ(12,NUME)
! N105: MTAP(NUME)
  N101=NFIRST
  N102=N101+NUMMAT*ITWO
  N103=N102+NUMMAT*ITWO
  N104=N103+20*NUME
  N105=N104+12*NUME*ITWO
  N106=N105+NUME
  N107=N106+NUMMAT*ITWO
  NLAST=N107

  MIDEST=NLAST - NFIRST

  CALL hell(IA(NP(1)),DA(NP(2)),DA(NP(3)),DA(NP(4)),DA(NP(4)),IA(NP(5)),   &
       A(N101),A(N102),A(N106),A(N103),A(N104),A(N105))

  RETURN

END SUBROUTINE shell


SUBROUTINE hell(ID,X,Y,Z,U,MHT,E,PR,THICK,LM,XYZ,MATP)
! . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
! .                                                                   .
! .   SHELL element subroutine                                        .          !平面壳单元
! .                                                                   .
! . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

  USE GLOBALS
  USE MEMALLOCATE

  IMPLICIT NONE
  INTEGER :: ID(5,NUMNP),LM(20,NPAR(2)),MATP(NPAR(2)),MHT(NEQ)
  REAL(8) :: X(NUMNP),Y(NUMNP),Z(NUMNP),E(NPAR(3)),PR(NPAR(3)),  &
            THICK(NPAR(3)), XYZ(12,NPAR(2)),U(NEQ),UE(20)                           ! 在材料属性中添加了密度参数
  REAL(8) :: S(20,20),D(3,3),F,G,H,r,BS(2,20),alpha,Stemp(20,20)
!  REAL(8) :: 
  
  INTEGER :: NPAR1, NUME, NUMMAT, ND,P1,P2,P3,P4, L, N, I,J
  INTEGER :: MTYPE, IPRINT 
  REAL(8) ::  XM, XX, YY, STR4q(3), P4q(3),wcxy(3),mxy(2)
  REAL(8) :: GP(2), WGT(2),B(3,20),detJ,NL(2,8)
  REAL(8),parameter:: pi=3.141592654
  !GP =[-0.9061798459, -0.5384693101 ,0.0 ,0.5384693101,0.9061798459]                          !五点GAUSS积分
  !WGT=[ 0.2369268851,  0.4786286705 ,0.5688888889, 0.4786286705,0.2369268851]
  GP=[-0.5773502692 , 0.5773502692]
  WGT=[ 1          ,          1]
  
  NPAR1  = NPAR(1)
  NUME   = NPAR(2)
  NUMMAT = NPAR(3) 
 ! ITYPE  = NPAR(4)
  ND=20

! Read and generate element information
  IF (IND .EQ. 1) THEN

     WRITE (IOUT,"(' E L E M E N T   D E F I N I T I O N',//,  &
                   ' ELEMENT TYPE ',13(' .'),'( NPAR(1) ) . . =',I5,/,   &
                   '     EQ.1, QUADR ELEMENTS',/,      &
                   '     EQ.2, ELEMENTS CURRENTLY',/,  &
                   '     EQ.6, SHELL ELEMENTS',//,      &

                   ' NUMBER OF ELEMENTS.',10(' .'),'( NPAR(2) ) . . =',I5,/)") NPAR1,NUME

     IF (NUMMAT.EQ.0) NUMMAT=1

     WRITE (IOUT,"(' M A T E R I A L   D E F I N I T I O N',//,  &
                   ' NUMBER OF DIFFERENT SETS OF MATERIAL',/,  &
                   ' AND PROPETIES ',         &
                   4 (' .'),'( NPAR(3) ) . . =',I5,/)") NUMMAT

     WRITE (IOUT,"('  SET       YOUNG''S      POISSION     THICKNESS',/,  &
                   ' NUMBER     MODULUS',10X,'   RATIO         VALUE',/,  &
                   15 X,'E',14X,'A',14X,'ROU')")

     DO I=1,NUMMAT
        READ (IIN,'(I5,3F10.0)') N,E(N),PR(N),THICK(N)                      ! Read material information  
        WRITE (IOUT,"(I5,4X,E12.5,2X,E12.5,2X,E12.5)") N,E(N),PR(N),THICK(N)
     END DO

     WRITE (IOUT,"(//,' E L E M E N T   I N F O R M A T I O N',//,  &
                      ' ELEMENT     NODE     NODE      NODE      NODE      MATERIAL',/,   &
                      ' NUMBER-N      P1       P2       P3       P4       SET NUMBER')")

     N=0
     DO WHILE (N .NE. NUME)
        READ (IIN,'(7I5)') N,P1,P2,P3,P4,MTYPE  ! Read in element information

!       Save element information
        XYZ(1,N)=X(P1)     ! Coordinates of the element's first node
        XYZ(2,N)=Y(P1)
        XYZ(3,N)=Z(P1)
        XYZ(4,N)=X(P2)     ! Coordinates of the element's second node
        XYZ(5,N)=Y(P2)
        XYZ(6,N)=Z(P2)
        XYZ(7,N)=X(P3)     ! Coordinates of the element's third node
        XYZ(8,N)=Y(P3)
        XYZ(9,N)=Z(P3)
        XYZ(10,N)=X(P4)     ! Coordinates of the element's fourth node
        XYZ(11,N)=Y(P4)
        XYZ(12,N)=Z(P4)
        MATP(N)=MTYPE  ! Material type
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DO L=1,20
           LM(L,N)=0
        END DO

        DO L=1,NDF
           LM(L,N)=ID(L,P1)     ! Connectivity matrix
           LM(L+NDF,N)=ID(L,P2) 
           LM(L+2*NDF,N)=ID(L,P3) 
           LM(L+3*NDF,N)=ID(L,P4)
        END DO

     
!       Update column heights and bandwidth
        CALL COLHT (MHT,ND,LM(1,N))   

        WRITE (IOUT,"(I5,6X,I5,4X,I5,4X,I5,4X,I5,7X,I5)") N,P1,P2,P3,P4,MTYPE
        WRITE (10,"(I5,4X,I5,4X,I5,4X,I5)") P1,P2,P3,P4 
     END DO

     RETURN

! Assemble stucture stiffness matrix
  ELSE IF (IND .EQ. 2) THEN

!shell问题分解为平面板的弯曲，再加上4Q单元的拉伸
     DO N=1,NUME
        MTYPE=MATP(N)
        G =E(MTYPE)/(1.-PR(MTYPE)**2)                                                 
        F=G*PR(MTYPE)                                                
        H=(G-F)/2. 
        D(1,1)=G                                                          
        D(1,2)=F                                                          
        D(1,3)=0.
        D(2,1)=F                                                          
        D(2,2)=G                                                          
        D(2,3)=0. 
        D(3,1)=0.                                                         
        D(3,2)=0.                                                         
        D(3,3)=H                                                     
      
        alpha=E(MTYPE)*THICK(MTYPE)/(1.0+PR(MTYPE))/12.0*5.0    !按照剪切应变能等效原则取 k=6/5 alpha=G*t/2k

        ! print *,D  
        S = 0
   
        do i=1,2                                                      
            do j=1,2

                CAll BBmat_shell(gp(i),gp(j),XYZ(1,N),B,detJ)
            
                S=S+WGT(i)*WGT(j)*matmul(matmul(transpose(B),D),B)*detJ*THICK(MTYPE)**3/12.0  
            end do
        end do  

        !采用减缩积分

        CAll BSmat_shell(0,0,XYZ(1,N),BS,detJ)  
        S=S+matmul(transpose(BS),BS)*detJ*alpha 
  
        do i=1,2                                                      
            do j=1,2
                CAll Bmat4q(gp(i),gp(j),XYZ(1,N),B,detJ)
                S=S+WGT(i)*WGT(j)*matmul(matmul(transpose(B),D),B)*detJ*THICK(MTYPE)  
            end do
        end do
  
        ! write(*,"(20(e12.5,1X))") ((Stemp(i,j),j=1,20),i=1,20)
 
        CALL ADDBAN (DA(NP(3)),IA(NP(2)),S,LM(1,N),ND)
     
     END DO

     RETURN

! Stress calculations
  ELSE IF (IND .EQ. 3) THEN

     IPRINT=0
     DO N=1,NUME
        IPRINT=IPRINT + 1
        IF (IPRINT.GT.50) IPRINT=1
        IF (IPRINT.EQ.1) WRITE (IOUT,"(//,' S T R E S S  C A L C U L A T I O N S  F O R  ',  &
                                           'E L E M E N T  G R O U P',I4,//,   &
                                           '  ELEMENT',5X,'GAUSS POINT',5X,'StressXX',5X,'StressYY',5X,'StressXY',/,&
                                          '  NUMBER')") NG
        MTYPE=MATP(N)
        DO L=1,4  
            Do J=1,5
                I=LM(5*L-J+1,N)
                if (I.GT.0)then
                    UE(5*L-J+1)=U(I)
                else
                    UE(5*L-J+1)=0
                endif 
            END DO
        END DO
        
        do i=1,2                                                      
            do j=1,2  
                CAll Bmat(gp(i),gp(j),XYZ(1,N),B,detJ)
                STR4q = matmul(B,UE)
                P4q   = matmul(D,STR4q)
                CAll Nmat_shell(0,0,BS)
                mxy = matmul(BS,UE)*E(MTYPE)*THICK(MTYPE)**3/12.0  
                WRITE (IOUT,"(I5,5X,f6.3,2X,f6.3,4X,E13.6,4X,E13.6,4X,E13.6,4X,E13.6,4X,E13.6)")N,gp(i),gp(j),P4q(1),P4q(2),P4q(3),mxy(1),mxy(2)
            end do
        end do
        
     END DO
  ELSE 
     STOP "*** ERROR *** Invalid IND value."
  END IF

END SUBROUTINE hell


subroutine Nmat_shell(eta,psi,N)
    implicit none
    real*8 ::psi,eta,N(2,12)
    N(1,2)=0.25*(1-psi)*(1-eta)
    N(2,3)=0.25*(1-psi)*(1-eta)
    N(1,5)=0.25*(1+psi)*(1-eta)
    N(2,6)=0.25*(1+psi)*(1-eta)
    N(1,8)=0.25*(1+psi)*(1+eta)
    N(2,9)=0.25*(1+psi)*(1+eta)
    N(1,11)=0.25*(1-psi)*(1+eta)
    N(2,12)=0.25*(1-psi)*(1+eta)
end subroutine Nmat_shell
   
    
subroutine Bmat4q(eta,psi,XY,B,detJ)
    implicit none
    real*8 :: eta,psi,XY(12),B(3,20),detJ,GN(2,4),J(2,2),JINV(2,2),DUM
    integer::K2,K,I

    GN(1,1)=0.25*(eta-1.0)
    GN(1,2)=-GN(1,1)
    GN(1,3)=0.25*(1.0+eta)
    GN(1,4)=-GN(1,3)
    GN(2,1)=0.25*(psi-1)
    GN(2,2)=-0.25*(psi+1)
    GN(2,3)=-GN(2,2)
    GN(2,4)=-GN(2,1)

    J(1,1)=GN(1,1)*xy(1)+GN(1,2)*xy(4)+GN(1,3)*xy(7)+GN(1,4)*xy(10)
    J(1,2)=GN(1,1)*xy(2)+GN(1,2)*xy(5)+GN(1,3)*xy(8)+GN(1,4)*xy(11)
    J(2,1)=GN(2,1)*xy(1)+GN(2,2)*xy(4)+GN(2,3)*xy(7)+GN(2,4)*xy(10)
    J(2,2)=GN(2,1)*xy(2)+GN(2,2)*xy(5)+GN(2,3)*xy(8)+GN(2,4)*xy(11)

    detJ=J(1,1)*J(2,2)-J(2,1)*J(1,2)
    DUM=1./detJ
    JINV(1,1)=J(2,2)*DUM
    JINV(1,2)=-J(1,2)*DUM
    JINV(2,1)=-J(2,1)*DUM
    JINV(2,2)=J(1,1)*DUM

    K2=0
    do K=1,4
        K2=K2+5
        do I=1,5
            B(1,K2-I+1) = 0.                                                    
            B(2,K2-I+1) = 0. 
        end do

        do I=1,2
            B(1,K2-4)=B(1,K2-4)+JINV(1,I)*GN(I,K)
            B(2,K2-3)=B(2,K2-3)+JINV(2,I)*GN(I,K)
        end do
        B(3,K2-3)  =B(1,K2-4)
        B(3,K2-4)  =B(2,K2-3)
        B(3,K2-2) = 0.
        B(3,K2-1) = 0.
        B(3,K2)   = 0.
    end do
end subroutine Bmat4q
      
    
subroutine BBmat_shell(eta,psi,XY,BB,detJ)
    implicit none
    real*8 :: eta,psi,XY(12),BB(3,20),detJ,GN(2,4),J(2,2),JINV(2,2),DUM
    integer::K2,K,I

    GN(1,1)=0.25*(eta-1.0)
    GN(1,2)=-GN(1,1)
    GN(1,3)=0.25*(1.0+eta)
    GN(1,4)=-GN(1,3)
    GN(2,1)=0.25*(psi-1)
    GN(2,2)=-0.25*(psi+1)
    GN(2,3)=-GN(2,2)
    GN(2,4)=-GN(2,1)

    J(1,1)=GN(1,1)*xy(1)+GN(1,2)*xy(4)+GN(1,3)*xy(7)+GN(1,4)*xy(10)
    J(1,2)=GN(1,1)*xy(2)+GN(1,2)*xy(5)+GN(1,3)*xy(8)+GN(1,4)*xy(11)
    J(2,1)=GN(2,1)*xy(1)+GN(2,2)*xy(4)+GN(2,3)*xy(7)+GN(2,4)*xy(10)
    J(2,2)=GN(2,1)*xy(2)+GN(2,2)*xy(5)+GN(2,3)*xy(8)+GN(2,4)*xy(11)

    detJ=J(1,1)*J(2,2)-J(2,1)*J(1,2)
    DUM=1./detJ
    JINV(1,1)=J(2,2)*DUM
    JINV(1,2)=-J(1,2)*DUM
    JINV(2,1)=-J(2,1)*DUM
    JINV(2,2)=J(1,1)*DUM

    K2=0
    do K=1,4
        K2=K2+5
        do I=1,5
            BB(1,K2-I+1) = 0.                                                    
            BB(2,K2-I+1) = 0. 
            BB(3,K2-I+1) = 0.
        end do

        do I=1,2
            BB(1,K2)  =BB(1,K2)  + JINV(1,I)*GN(I,K)
            BB(2,K2-1)=BB(2,K2-1)- JINV(2,I)*GN(I,K)
        end do
        BB(3,K2-1)  = -BB(1,K2)
        BB(3,K2)   = -BB(2,K2-1)
    end do

end subroutine BBmat_shell
    
subroutine BSmat_shell(eta,psi,XY,BS,detJ)
    implicit none
    real*8 :: eta,psi,XY(12),BS(2,20),detJ,GN(2,4),J(2,2),JINV(2,2),DUM,N(4)
    integer::K2,K,I

    GN(1,1)=0.25*(eta-1.0)
    GN(1,2)=-GN(1,1)
    GN(1,3)=0.25*(1.0+eta)
    GN(1,4)=-GN(1,3)
    GN(2,1)=0.25*(psi-1)
    GN(2,2)=-0.25*(psi+1)
    GN(2,3)=-GN(2,2)
    GN(2,4)=-GN(2,1)
    N(1)=0.25*(1-psi)*(1-eta)
    N(2)=0.25*(1+psi)*(1-eta)
    N(3)=0.25*(1+psi)*(1+eta)
    N(4)=0.25*(1-psi)*(1+eta)

    J(1,1)=GN(1,1)*xy(1)+GN(1,2)*xy(4)+GN(1,3)*xy(7)+GN(1,4)*xy(10)
    J(1,2)=GN(1,1)*xy(2)+GN(1,2)*xy(5)+GN(1,3)*xy(8)+GN(1,4)*xy(11)
    J(2,1)=GN(2,1)*xy(1)+GN(2,2)*xy(4)+GN(2,3)*xy(7)+GN(2,4)*xy(10)
    J(2,2)=GN(2,1)*xy(2)+GN(2,2)*xy(5)+GN(2,3)*xy(8)+GN(2,4)*xy(11)

    detJ=J(1,1)*J(2,2)-J(2,1)*J(1,2)
    DUM=1./detJ
    JINV(1,1)=J(2,2)*DUM
    JINV(1,2)=-J(1,2)*DUM
    JINV(2,1)=-J(2,1)*DUM
    JINV(2,2)=J(1,1)*DUM

    K2=0
    do K=1,4
        K2=K2+5
        do I=1,5
            BS(1,K2-I+1) = 0.                                                    
            BS(2,K2-I+1) = 0. 
        end do

        do I=1,2
            BS(1,K2-2)=BS(1,K2-2)+JINV(2,I)*GN(I,K)
            BS(2,K2-2)=BS(2,K2-2)+JINV(1,I)*GN(I,K)
        end do
        BS(1,K2-1)  =-N(K)
        BS(2,K2)    = N(K)
    end do   

end subroutine BSmat_shell
    
