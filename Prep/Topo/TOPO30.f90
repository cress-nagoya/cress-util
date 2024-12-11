program SRTM3
! NASA の SRTM 3 データから任意の矩形の標高データを作成するプログラム.
! ここでは, 読み込んだデータファイルでの格子間隔と作成するファイルの格子間隔は
! 同一という前提で作成している. 補完でさらに格子解像度を変えるようなことは
! 一切しない.
! SRTM 3 専用の設定がいくつか設定されているので, 他に転用するなら, 
! その値を変えること.
! 読み込む領域によっては非常にメモリを消費するので,
! Segmentation fault で落ちる場合, stack の上限値を外すこと.
! $ ulimit -s unlimited (Linux の場合)

  implicit none

  integer, parameter :: nx=4800  ! 元の標高データの分割ファイルの lon 成分数
  integer, parameter :: ny=6000  ! 元の標高データの分割ファイルの lat 成分数
  integer, parameter :: ntx=4800  ! 重複を避けたときのデータ数
  integer, parameter :: nty=6000  ! 重複を避けたときのデータ数
  integer(2) :: undef  ! ocean mask value
  integer :: lonmin  ! 作成するデータの西端 [deg]
  integer :: latmin  ! 作成するデータの北端 [deg] (SRTM が北西からのため)
  integer :: fnumber_lon  ! lon 方向に読み出す分割ファイル数
  integer :: fnumber_lat  ! lat 方向に読み出す分割ファイル数
  integer :: nax  ! 作成データの x 方向の総配列数
  integer :: nay  ! 作成データの y 方向の総配列数
  integer :: fnumber_all
  character(80) :: trn_name  ! 作成するファイル名
  character(80) :: fullname  ! 読み込むファイル名
  character(1) :: nsflag, weflag
  character(4) :: foot_name  ! ファイルの拡張子
  character(2) :: fname_lat
  character(3) :: fname_lon
  real, allocatable, dimension(:,:) :: height  ! 標高データ用配列
  real, allocatable, dimension(:) :: lon  ! 作成ファイルの lon 情報
  real, allocatable, dimension(:) :: lat  ! 作成ファイルの lat 情報
  integer :: i, j, k, l, m, n
  integer(8) :: byte

  namelist /set /lonmin,latmin,fnumber_lon,fnumber_lat,foot_name,trn_name, undef
  read(5,set)

!-- 既定値の設定
  fnumber_all=fnumber_lon*fnumber_lat  ! 読み出す分割ファイル総数
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
  integer, intent(in) :: lonp  ! ファイル名の経度
  integer, intent(in) :: latp  ! ファイル名の緯度
  character(*), intent(in) :: foot_name  ! ファイルの拡張子
  character(*), intent(inout) :: make_file  ! 作成されるファイル名
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
  character(*), intent(in) :: fname  ! 読み込むファイル名
  integer, intent(in) :: nx  ! ファイルの経度格子数
  integer, intent(in) :: ny  ! ファイルの緯度格子数
  integer, intent(in) :: byte  ! 1 レコードのバイト数
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
!-- 北西からのデータを南西開始に変換
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
