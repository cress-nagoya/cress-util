program SRTM3
! NASA �� SRTM 3 �ǡ�������Ǥ�դζ����ɸ��ǡ������������ץ����.
! �����Ǥ�, �ɤ߹�����ǡ����ե�����ǤγʻҴֳ֤Ⱥ�������ե�����γʻҴֳ֤�
! Ʊ��Ȥ�������Ǻ������Ƥ���. �䴰�Ǥ���˳ʻҲ����٤��Ѥ���褦�ʤ��Ȥ�
! ���ڤ��ʤ�.
! SRTM 3 ���Ѥ����꤬�����Ĥ����ꤵ��Ƥ���Τ�, ¾��ž�Ѥ���ʤ�, 
! �����ͤ��Ѥ��뤳��.
! �ɤ߹����ΰ�ˤ�äƤ����˥������񤹤�Τ�,
! Segmentation fault ���������, stack �ξ���ͤ򳰤�����.
! $ ulimit -s unlimited (Linux �ξ��)

  implicit none

  integer, parameter :: nx=4800  ! ����ɸ��ǡ�����ʬ��ե������ lon ��ʬ��
  integer, parameter :: ny=6000  ! ����ɸ��ǡ�����ʬ��ե������ lat ��ʬ��
  integer, parameter :: ntx=4800  ! ��ʣ���򤱤��Ȥ��Υǡ�����
  integer, parameter :: nty=6000  ! ��ʣ���򤱤��Ȥ��Υǡ�����
  integer(2) :: undef  ! ocean mask value
  integer :: lonmin  ! ��������ǡ�������ü [deg]
  integer :: latmin  ! ��������ǡ�������ü [deg] (SRTM ����������Τ���)
  integer :: fnumber_lon  ! lon �������ɤ߽Ф�ʬ��ե������
  integer :: fnumber_lat  ! lat �������ɤ߽Ф�ʬ��ե������
  integer :: nax  ! �����ǡ����� x �������������
  integer :: nay  ! �����ǡ����� y �������������
  integer :: fnumber_all
  character(80) :: trn_name  ! ��������ե�����̾
  character(80) :: fullname  ! �ɤ߹���ե�����̾
  character(1) :: nsflag, weflag
  character(4) :: foot_name  ! �ե�����γ�ĥ��
  character(2) :: fname_lat
  character(3) :: fname_lon
  real, allocatable, dimension(:,:) :: height  ! ɸ��ǡ���������
  real, allocatable, dimension(:) :: lon  ! �����ե������ lon ����
  real, allocatable, dimension(:) :: lat  ! �����ե������ lat ����
  integer :: i, j, k, l, m, n
  integer(8) :: byte

  namelist /set /lonmin,latmin,fnumber_lon,fnumber_lat,foot_name,trn_name, undef
  read(5,set)

!-- �����ͤ�����
  fnumber_all=fnumber_lon*fnumber_lat  ! �ɤ߽Ф�ʬ��ե��������
  nax=ntx*fnumber_lon
  nay=nty*fnumber_lat
  byte=4*nax*nay

  write(*,*) "To run the program, the memory amount is needed more than",  &
  &   byte, "bytes."

  allocate(height(nax,nay))

!  write(*,*) "make file name is ", trim(trn_name), "."
!  call read_height_file( 'test', 1,1,2,height(1:1,1:1))
!  write(*,*) "make file array number is ", nax, nay, "."

  do j=1,fnumber_lat
     do i=1,fnumber_lon
        call fname_make( (lonmin+40*(i-1)), (latmin-50*(j-1)), foot_name, fullname )
        call read_height_file( trim(fullname), nx, ny, 2,  &
  &          height(((i-1)*ntx+1):(i*ntx),  &
  &          ((fnumber_lat-j)*nty+1):((fnumber_lat-j+1)*nty)) )
     end do
  end do

  open(unit=11,file=trim(trn_name),access='direct',recl=byte,status='unknown')
     write(11,rec=1) ((height(i,j),i=1,nax),j=1,nay)
  close(unit=11,status='keep')

  call output_ctl( nax, nay, real(lonmin), real(latmin)-nay/120.0, trn_name )

  deallocate(height)

end program

subroutine fname_make( lonp, latp, foot_name, make_file )
  implicit none
  integer, intent(in) :: lonp  ! �ե�����̾�η���
  integer, intent(in) :: latp  ! �ե�����̾�ΰ���
  character(*), intent(in) :: foot_name  ! �ե�����γ�ĥ��
  character(*), intent(inout) :: make_file  ! ���������ե�����̾
  character(1) :: nsflag, weflag
  character(3) :: lon_name
  character(2) :: lat_name

  write(lat_name,'(i2.2)') abs(latp)
  write(lon_name,'(i3.3)') abs(lonp)

  if(lonp<0.or.lonp>=180)then
     weflag='W'
  else
     weflag='E'
  end if

  if(latp<0)then
     nsflag='S'
  else
     nsflag='N'
  end if

  make_file=weflag//lon_name//nsflag//lat_name//foot_name

  write(*,*) "reading file name is ", trim(make_file)

end subroutine

subroutine read_height_file( fname, nx, ny, byte, undefv, height )
  implicit none
  character(*), intent(in) :: fname  ! �ɤ߹���ե�����̾
  integer, intent(in) :: nx  ! �ե�����η��ٳʻҿ�
  integer, intent(in) :: ny  ! �ե�����ΰ��ٳʻҿ�
  integer, intent(in) :: byte  ! 1 �쥳���ɤΥХ��ȿ�
  integer(2), intent(in) :: undefv  ! ocean mask value
  real, intent(inout) :: height(nx,ny)
  integer :: i, j, k, siz, stat
  integer(2) :: tmp(nx,ny)

  siz=byte*nx*ny

  open( unit=11, file=trim(fname), access='direct', recl=siz, iostat=stat, status='old' )
     if(stat/=0)then
        write(*,*) "There is no file. height=0. [filename is ", trim(fname), ".]"
        height=0.0
     else
        write(*,*) "Now reading file is ", trim(fname), "."
        read(11,rec=1) ((tmp(i,j),i=1,nx),j=1,ny)
!-- ��������Υǡ������������Ϥ��Ѵ�
        do j=1,ny
           do i=1,nx
              if(tmp(i,ny-j+1)==undefv)then
                 height(i,j)=0.0
              else
                 height(i,j)=real(tmp(i,ny-j+1))
           end do
        end do
     end if
  close( unit=11, status='keep' )


end subroutine

subroutine output_ctl( nax, nay, lonmin, latmin, trn_name )
  implicit none
  integer :: nax
  integer :: nay
  real :: lonmin
  real :: latmin
  character(80) :: trn_name

  real :: dl
  character(100) :: forma
  character(7) :: formb, formc
  character(16) :: formd, forme, formf

  dl=1.0/120.0

  write(forma,*) len_trim(adjustl(trn_name))+6
  forma='(a'//trim(adjustl(forma))//')'
  write(formb,'(i7)') nax
  write(formc,'(i7)') nay
  write(formd,'(1PE16.8)') lonmin
  write(forme,'(1PE16.8)') latmin
  write(formf,'(1PE16.8)') dl

  write(*,'(a52)') "----------------------------------------------------"
  write(*,trim(adjustl(forma))) "dset ^"//trim(adjustl(trn_name))
  write(*,'(a30)') "title terrain height by SRTM30"
  write(*,'(a13)') "undef -1.0e35"
  write(*,'(a27)') "options big_endian template"
  write(*,'(a52)') "xdef"//formb//' LINEAR '//formd//' '//formf
  write(*,'(a52)') "ydef"//formc//' LINEAR '//forme//' '//formf
  write(*,'(a20)') "zdef      1 LEVELS 1"
  write(*,'(a36)') "tdef      1 LINEAR 00Z01JAN0000 01hr"
  write(*,'(a9)') "vars    1"
  write(*,'(a28)') "ht   0 99 terrain height (m)"
  write(*,'(a7)') "endvars"
  write(*,'(a52)') "----------------------------------------------------"

end subroutine
