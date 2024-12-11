program SRTM3_draw

  use dcl
  use Dcl_Automatic

  implicit none

  character(5), parameter :: border='wldlo'
  character(70), parameter :: FONTNAME='Nimbus Sans 12'
  integer :: nx, ny
  real, allocatable, dimension(:) :: x, y, xd, yd
  integer, parameter :: nx1=4800, ny1=6000
  real, parameter, dimension(2) :: vx=(/0.1,0.9/), vy=(/0.1,0.9/)
  real :: dlon, dlat, gnum
  real :: shade_max
  real, allocatable, dimension(:,:) :: height, heightd
  real, dimension(2) :: vx_new, vy_new
  integer, dimension(2) :: nnx, nny
  integer :: IWS
  integer :: i, j, k
  integer :: lonmin, latmin
  integer :: ndx, ndy
  character(10) :: foot_name  ! dummy value
  character(80) :: trn_name, title
  integer :: fnumber_lon, fnumber_lat
  integer(8) :: byte

  namelist /set /lonmin,latmin,fnumber_lon,fnumber_lat,foot_name,trn_name
  namelist /domain /nnx,nny,shade_max,IWS,gnum,title

  read(5,nml=set)
  read(5,nml=domain)

  nx=nx1*fnumber_lon
  ny=ny1*fnumber_lat

  dlon=1.0/120.0
  dlat=1.0/120.0


  if(nnx(1)==nnx(2).and.nny(1)==nny(2))then
     ndx=nx/nnx(1)
     ndy=ny/nny(1)
     allocate(xd(ndx))
     allocate(yd(ndy))
     allocate(heightd(ndx,ndy))
  end if

  allocate(x(nx))
  allocate(y(ny))
  allocate(height(nx,ny))

  byte=4*nx*ny
write(*,*) 4*nx*ny, byte
  x=(/(real(lonmin)+dlon*(i-1),i=1,nx)/)
  y=(/(real(latmin)-dlat*(ny-i+1),i=1,ny)/)

  open(unit=11,file=trim(trn_name),access='direct',recl=byte,status='old')
     read(11,rec=1) ((height(i,j),i=1,nx),j=1,ny)
  close(unit=11,status='keep')

  do j=1,ny
     do i=1,nx
        if(height(i,j)==0.0)then
           height(i,j)=-0.1
        end if
        if(height(i,j)<-0.1)then
           height(i,j)=-1.e35
        end if
     end do
  end do

  call SGISET( 'IFONT', 1 )
  call SWLSET( 'LSYSFNT', .true. )
  call DclSetParm( 'ENABLE_CONTOUR_MESSAGE', .false. )

  call DclOpenGraphics(IWS)

  call color_setting( 20, (/0.0, shade_max/), col_tab=39,  &
  &                   min_tab=30999, max_tab=90999, col_min=40, col_max=60 )

  if(len_trim(FONTNAME)==0)then
     CALL SWSLFT(FONTNAME)
  end if
  CALL SWCSET('FONTNAME', FONTNAME)

  if(nnx(1)==nnx(2).and.nny(1)==nny(2))then
     do j=1,ndy
        do i=1,ndx
           heightd(i,j)=height(i*nnx(1),j*nny(1))
        end do
     end do
     xd=(/(real(lonmin)+dlon*(i-1)*nnx(1),i=1,ndx)/)
     yd=(/(real(latmin)-dlat*(ndy-i+1)*nny(1),i=1,ndy)/)

!     call Dcl_2d_Cont_Shade( 'test domain', xd, yd,  &
!     &    heightd, heightd,  &
!     &    (/-20.0, 0.0/), (/0.0, shade_max/), (/'x', 'y'/),  &
!     &    (/'(f6.1)', '(f6.1)'/), c_num=(/10, 20/) )

     call Dcl_2D_cont_shade_MapPro( 11, trim(adjustl(title)),  &
  &       xd(1:ndx), yd(1:ndy),  &
  &       heightd(1:ndx,1:ndy),  &
  &       heightd(1:ndx,1:ndy),  &
  &       (/-1000.0, -900.0/), (/0.0, shade_max/),  &
  &       (/'Longitude (deg)', 'Latitude  (deg)'/),  &
  &       (/'(f6.1)', 'b'/), c_num=(/10, 20/),  &
  &       viewx_int=vx, viewy_int=vy,  &
  &       coast=border(1:5), no_tone=.true., mlitv=gnum )
!  &          mlidx=mlidx, blidx=blidx, mlitv=gnum )

  else

!     call Dcl_2d_Cont_Shade( 'test domain', x(nnx(1):nnx(2)), y(nny(1):nny(2)),  &
!     &    height(nnx(1):nnx(2),nny(1):nny(2)),  &
!     &    height(nnx(1):nnx(2),nny(1):nny(2)),  &
!     &    (/-20.0, 0.0/), (/0.0, shade_max/), (/'x', 'y'/),  &
!     &    (/'(f6.1)', '(f6.1)'/), c_num=(/10, 20/) )

     call Dcl_2D_cont_shade_MapPro( 11, trim(adjustl(title)),  &
  &       x(nnx(1):nnx(2)), y(nny(1):nny(2)),  &
  &       height(nnx(1):nnx(2),nny(1):nny(2)),  &
  &       height(nnx(1):nnx(2),nny(1):nny(2)),  &
  &       (/-1000.0, -900.0/), (/0.0, shade_max/),  &
  &       (/'Longitude (deg)', 'Latitude  (deg)'/),  &
  &       (/'(f6.1)', 'b'/), c_num=(/10, 20/),  &
  &       viewx_int=vx, viewy_int=vy,  &
  &       coast=border(1:5), no_tone=.true., mlitv=gnum )
!  &          mlidx=mlidx, blidx=blidx, mlitv=gnum )

  end if

  call DclSetParm( "GRAPH:LCLIP", .false. )
  call DclDrawMarker( (/1.0/), (/1.0/) )

  CALL SGQVPT( vx_new(1), vx_new(2), vy_new(1), vy_new(2) )
  call tone_bar( 20, (/0.0, shade_max/),  &
  &              (/vx_new(2)+0.025, vx_new(2)+0.05/), vy_new,  &
  &              'b', trigle='u' )

  call DclSetParm( "GRAPH:LCLIP", .true. )

  call DclCloseGraphics

end program
