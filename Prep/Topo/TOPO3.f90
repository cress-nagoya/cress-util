program TOPO3
! Author: Satoki Tsujino (satoki_at_gfd-dennou.org)
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

  integer, parameter :: nx=1201  ! 元の標高データの分割ファイルの lon 成分数
  integer, parameter :: ny=1201  ! 元の標高データの分割ファイルの lat 成分数
  integer, parameter :: ntx=1200  ! 重複を避けたときのデータ数
  integer, parameter :: nty=1200  ! 重複を避けたときのデータ数
  real, parameter :: undef=-32768.0   ! SRTM3 未定義値
  integer :: lonmin  ! 作成するデータの西端 [deg]
  integer :: latmin  ! 作成するデータの南端 [deg] (SRTM3 が南西からのため)
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

  namelist /set /lonmin,latmin,fnumber_lon,fnumber_lat,foot_name,trn_name
  read(5,nml=set)

!-- 既定値の設定
  fnumber_all=fnumber_lon*fnumber_lat  ! 読み出す分割ファイル総数
  nax=ntx*fnumber_lon+1
  nay=nty*fnumber_lat+1

  write(*,*) "To run the program, the memory amount is needed more than",  &
  &   nax*nay*4*2, "bytes."

  allocate(height(nax,nay))

!  write(*,*) "make file name is ", trim(trn_name), "."
!  call read_height_file( 'test', 1 ,1 ,2 ,height(1:1,1:1) )
!  write(*,*) "make file array number is ", nax, nay, "."

  do j=1,fnumber_lat
     do i=1,fnumber_lon
        call fname_make( (lonmin+(i-1)), (latmin+(j-1)), foot_name, fullname )
        call read_height_file( trim(fullname), nx, ny, 2,  &
  &          height(((i-1)*ntx+1):(i*ntx+1),((j-1)*nty+1):(j*nty+1)) )
     end do
  end do

  call interpo_height( height, undef )

  open(unit=11,file=trim(trn_name),access='direct',recl=4*nax*nay,status='unknown')
     write(11,rec=1) ((height(i,j),i=1,nax),j=1,nay)
  close(unit=11,status='keep')

  call output_ctl( nax, nay, real(lonmin), real(latmin), trn_name )

  deallocate(height)

contains

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

  if(lonp<0.or.lonp>180)then
     weflag='W'
  else
     weflag='E'
  end if

  if(latp<0)then
     nsflag='S'
  else
     nsflag='N'
  end if

  make_file=nsflag//lat_name//weflag//lon_name//foot_name

  write(*,*) "reading file name is ", trim(make_file)

end subroutine

subroutine read_height_file( fname, nx, ny, byte, height )
  implicit none
  character(*), intent(in) :: fname  ! 読み込むファイル名
  integer, intent(in) :: nx  ! ファイルの経度格子数
  integer, intent(in) :: ny  ! ファイルの緯度格子数
  integer, intent(in) :: byte  ! 1 レコードのバイト数
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

  dl=1.0/1200.0

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
  write(*,'(a26)') "zdef      1 LINEAR 1.0 1.0"
  write(*,'(a36)') "tdef      1 LINEAR 00Z01JAN0000 01hr"
  write(*,'(a9)') "vars    1"
  write(*,'(a28)') "ht   0 99 terrain height (m)"
  write(*,'(a7)') "endvars"
  write(*,'(a52)') "----------------------------------------------------"

end subroutine


subroutine interpo_height( val, undef )
  implicit none
  real, intent(inout) :: val(:,:)
  real, intent(in) :: undef
  integer :: ix, jy, nnx, nny
  real :: tmpval, mcounter
  logical :: intfxmin, intfxmax, intfymin, intfymax
  logical :: intfxymin, intfxymax, intfxminymax, intfxmaxymin

  nnx=size(val,1)
  nny=size(val,2)

  do jy=1,nny
     do ix=1,nnx
        if(val(ix,jy)==undef)then
           intfxmin=.false.
           intfxmax=.false.
           intfymin=.false.
           intfymax=.false.
           intfxymin=.false.
           intfxymax=.false.
           intfxmaxymin=.false.
           intfxminymax=.false.
           tmpval=0.0
           mcounter=0.0

           if(ix>1)then
              if(val(ix-1,jy)/=undef)then
                 intfxmin=.true.
              end if
              if(jy>1)then
                 if(val(ix-1,jy-1)/=undef)then
                    intfxymin=.true.
                 end if
              else if(jy<nny)then
                 if(val(ix-1,jy+1)/=undef)then
                    intfxminymax=.true.
                 end if
              end if
           end if
           if(jy>1)then
              if(val(ix,jy-1)/=undef)then
                 intfymin=.true.
              end if
           end if
           if(ix<nnx)then
              if(val(ix+1,jy)/=undef)then
                 intfxmax=.true.
              end if
              if(jy>1)then
                 if(val(ix+1,jy-1)/=undef)then
                    intfxmaxymin=.true.
                 end if
              else if(jy<nny)then
                 if(val(ix+1,jy+1)/=undef)then
                    intfxymax=.true.
                 end if
              end if
           end if
           if(jy<nny)then
              if(val(ix,jy+1)/=undef)then
                 intfymax=.true.
              end if
           end if

           if(intfxmin.eqv..true.)then
              tmpval=tmpval+val(ix-1,jy)
              mcounter=mcounter+1.0
           end if
           if(intfxmax.eqv..true.)then
              tmpval=tmpval+val(ix+1,jy)
              mcounter=mcounter+1.0
           end if
           if(intfymin.eqv..true.)then
              tmpval=tmpval+val(ix,jy-1)
              mcounter=mcounter+1.0
           end if
           if(intfymax.eqv..true.)then
              tmpval=tmpval+val(ix,jy+1)
              mcounter=mcounter+1.0
           end if
           if(intfxymin.eqv..true.)then
              tmpval=tmpval+val(ix-1,jy-1)
              mcounter=mcounter+1.0
           end if
           if(intfxymax.eqv..true.)then
              tmpval=tmpval+val(ix+1,jy+1)
              mcounter=mcounter+1.0
           end if
           if(intfxmaxymin.eqv..true.)then
              tmpval=tmpval+val(ix+1,jy-1)
              mcounter=mcounter+1.0
           end if
           if(intfxminymax.eqv..true.)then
              tmpval=tmpval+val(ix-1,jy+1)
              mcounter=mcounter+1.0
           end if
           if(mcounter==0.0)then
              write(*,*) "[ERROR] : Detect all undef. ", mcounter
           end if
           val(ix,jy)=tmpval/mcounter
        end if
     end do
  end do


end subroutine

end program
