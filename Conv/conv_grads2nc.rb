#!/usr/bin/ruby
# [USAGE]: $ ruby conv_grads2nc.rb
# To convert CReSS united binary files to NetCDF time series file
# Copyright: Satoki Tsujino (satoki@gfd-dennou.org)
# メモ: GPhys の機能を使っているのは見かけのみ
#       (time を unlimited で変換したかったので)

require "numru/netcdf"
require "numru/ggraph"
require "narray_miss"
include NumRu
include NMath

######### Set your environment #########
conf = "form_toyohashi-1.user.conf"  # CReSS configuration file
undefv = -1.0e35  # undefined value in CReSS (fixed number)
########################################

fconf = open(conf,"r").read

# set parameters from user.conf
fconf_nospace = fconf.gsub(" ","")
dx = fconf_nospace.split("\ndx=")[1].split("\n")[0].split("!")[0].to_f
dy = fconf_nospace.split("\ndy=")[1].split("\n")[0].split("!")[0].to_f
riu = fconf_nospace.split("\nriu=")[1].split("\n")[0].split("!")[0].to_f
rju = fconf_nospace.split("\nrju=")[1].split("\n")[0].split("!")[0].to_f
mpopt = fconf_nospace.split("\nmpopt=")[1].split("\n")[0].split("!")[0].to_i
dmplev = fconf_nospace.split("\ndmplev=")[1].split("\n")[0].split("!")[0].to_i
dmpmon = fconf_nospace.split("\ndmpmon=")[1].split("\n")[0].split("!")[0].to_i
nx = fconf_nospace.split("\nxdim=")[1].split("\n")[0].split("!")[0].to_i - 3
ny = fconf_nospace.split("\nydim=")[1].split("\n")[0].split("!")[0].to_i - 3
nz = fconf_nospace.split("\nzdim=")[1].split("\n")[0].split("!")[0].to_i - 3
ts = fconf_nospace.split("\nstime=")[1].split("\n")[0].split("!")[0].to_i
te = fconf_nospace.split("\netime=")[1].split("\n")[0].split("!")[0].to_i
start_time = fconf_nospace.split("\nsfcast=")[1].split("\n")[0].split("!")[0].gsub("'","")
dt3d = fconf_nospace.split("\ndmpitv=")[1].split("\n")[0].split("!")[0].to_i
dt2d = fconf_nospace.split("\nmonitv=")[1].split("\n")[0].split("!")[0].to_i
crsdir = fconf_nospace.split("\ncrsdir=")[1].split("\n")[0].split("!")[0].gsub("'","")
exprim = fconf_nospace.split("\nexprim=")[1].split("\n")[0].split("!")[0].gsub("'","")

nt3d = (te - ts) / dt3d + 1
nt2d = (te - ts) / dt2d + 1
geoctl = crsdir + '/' + exprim + '.geography.ctl'
dmpctl = crsdir + '/' + exprim + '.dmp.ctl'
monctl = crsdir + '/' + exprim + '.mon.ctl'
xmin = - dx * (riu - 2.5)
ymin = - dy * (rju - 2.5)

# output
puts "dx = #{dx}"
puts "dy = #{dy}"
puts "riu = #{riu}"
puts "rju = #{rju}"
puts "mpopt = #{mpopt}"
puts "dmplev = #{dmplev}"
puts "dmpmon = #{dmpmon}"
puts "nx = #{nx}"
puts "ny = #{ny}"
puts "nz = #{nz}"
puts "ts = #{ts}"
puts "te = #{te}"
puts "start_time = #{start_time[0..9]} #{start_time[10..-1]}"
puts "dt3d = #{dt3d}"
puts "dt2d = #{dt2d}"
puts "crsdir = #{crsdir}"
puts "exprim = #{exprim}"

puts "nt3d = #{nt3d}"
puts "nt2d = #{nt2d}"
puts "geoctl = #{geoctl}"
puts "dmpctl = #{dmpctl}"
puts "monctl = #{monctl}"
puts "xmin = #{xmin}"
puts "ymin = #{ymin}"

# set coordinates
if mpopt == 0 then  # lat-lon
   x = VArray.new( NArray.float(nx), {"long_name"=>"longitude", "units"=>"degrees_east"}, "longitude" )
   y = VArray.new( NArray.float(ny), {"long_name"=>"latitude", "units"=>"degrees_north"}, "latitude" )
else  # map projection
   x = VArray.new( NArray.float(nx), {"long_name"=>"X-coord", "units"=>"m"}, "x" )
   y = VArray.new( NArray.float(ny), {"long_name"=>"Y-coord", "units"=>"m"}, "y" )
end

for i in 0..nx-1
   x[i].val = xmin + dx * i.to_f
end
for i in 0..ny-1
   y[i].val = ymin + dy * i.to_f
end

# read ctl file
# (1) geography file
fctl = open(geoctl,"r").read.split("\n")
for i in 0..fctl.size-1
   tmpc = fctl[i].split
   if tmpc[0] == "vars" then
      vnumgeo = tmpc[1].to_i
      vlin = i
      break
   end
end

geovname = Array.new(vnumgeo)
geolname = Array.new(vnumgeo)
geouname = Array.new(vnumgeo)

for i in 0..vnumgeo-1
   tmpc = fctl[vlin+1+i].split
   geovname[i] = tmpc[0]
   geouname[i] = tmpc[-1].gsub("[","").gsub("]","")
   geolname[i] = tmpc[3..-2].join(' ')  # split で分割した文字を再結合
end

# (2) dmp file
fctl = open(dmpctl,"r").read.split("\n")
for i in 0..fctl.size-1
   tmpc = fctl[i].split
   if tmpc[0] == "zdef" then
      nzctl = tmpc[1].to_i
      zval = NArray.float(nzctl).fill(0.0)
      if tmpc[2] == "linear" then
         for j in 1..nzctl
            zval[j-1] = tmpc[3].to_f + tmpc[4].to_f * (j - 1)
         end
      elsif tmpc[2] == "levels" then
         for j in 1..nzctl
            zval[j-1] = tmpc[j+2].to_f
         end
      end
   end
   if tmpc[0] == "vars" then
      vnumdmp = tmpc[1].to_i
      vlin = i
      break
   end
end

dmpvname = Array.new(vnumdmp)
dmplname = Array.new(vnumdmp)
dmpuname = Array.new(vnumdmp)
dmpnz = Array.new(vnumdmp)

for i in 0..vnumdmp-1
   tmpc = fctl[vlin+1+i].split
   dmpvname[i] = tmpc[0]
   dmpnz[i] = tmpc[1].to_i
   if (dmpnz[i] == 0) then dmpnz[i] = 1 end
   dmpuname[i] = tmpc[-1].gsub("[","").gsub("]","")
   dmplname[i] = tmpc[3..-2].join(' ')  # split で分割した文字を再結合
end

if dmpmon == 1 then
# (3) mon file
   fctl = open(monctl,"r").read.split("\n")
   for i in 0..fctl.size-1
      tmpc = fctl[i].split
      if tmpc[0] == "vars" then
         vnummon = tmpc[1].to_i
         vlin = i
         break
      end
   end

   monvname = Array.new(vnummon)
   monlname = Array.new(vnummon)
   monuname = Array.new(vnummon)

   for i in 0..vnummon-1
      tmpc = fctl[vlin+1+i].split
      monvname[i] = tmpc[0]
      monuname[i] = tmpc[-1].gsub("[","").gsub("]","")
      monlname[i] = tmpc[3..-2].join(' ')  # split で分割した文字を再結合
   end
end

# set z coordinate

if dmplev == 1 then
   z = VArray.new( NArray.float(nz), {"long_name"=>"Grid level", "units"=>"1"}, "z" )
else
   z = VArray.new( NArray.float(nz), {"long_name"=>"Height", "units"=>"m"}, "z" )
end

z.replace_val(zval)

stime = "#{start_time[0..3]}-#{start_time[5..6]}-#{start_time[8..9]} #{start_time[10..11]}:#{start_time[13..14]}:00"
t2d = VArray.new( NArray.float(nt2d), {"long_name"=>"seconds since #{stime}", "units"=>"s"}, "t" )
t3d = VArray.new( NArray.float(nt3d), {"long_name"=>"seconds since #{stime}", "units"=>"s"}, "t" )

for i in 0..nt2d-1
   t2d[i] = (ts + dt2d * i).to_f
end
for i in 0..nt3d-1
   t3d[i] = (ts + dt3d * i).to_f
end

# set NetCDF
xax = Axis.new().set_pos(x)
yax = Axis.new().set_pos(y)
zax = Axis.new().set_pos(z)
grid2d = Grid.new( xax, yax )
grid3d = Grid.new( xax, yax, zax )

# read binary files
# (1) geography file

geogrd = "#{crsdir}/#{exprim}.geography.united.bin"

fsize = File.size(geogrd)
fgeo = open(geogrd,"rb").read(fsize)
#val2d = NArray.sfloat(nx,ny).fill(0.0)
#clist = "g" + (nx*ny*vnumgeo).to_s
clist = "g" + (fsize/4).to_s

gpfingeo = Array.new(vnumgeo)

for k in 0..vnumgeo-1
   puts "Read #{geogrd}@#{geovname[k]}..."

   val2d = NArray.to_na(fgeo.unpack(clist)[nx*ny*k..nx*ny-1+nx*ny*k]).reshape(nx,ny).to_type(NArray::SFLOAT)
   rval2d = VArray.new( val2d, {"long_name"=>geolname[k], "units"=>geouname[k]}, geovname[k] )
   #rval2d.replace_val(NArray.to_na(fgeo.unpack(clist)[nx*ny*k..nx*ny-1+nx*ny*k]).reshape(nx,ny))
   ##for j in 0..ny-1
    #  #rval.val[0..nx-1,j] = fgeo.unpack(clist)[nx*j+nx*ny*k..nx*(j+1)-1+nx*ny*k]
   ##   puts "#{nx*j+nx*ny*k}, #{nx*(j+1)-1+nx*ny*k}\n"
   ##end

   gpfingeo[k] = GPhys.new( grid2d, rval2d )
   gpfingeo[k].set_att("missing_value", NArray.to_na([undefv]) )

   #GPhys::NetCDF_IO.write(ofile3d,gpfingeo)
   #if dmpmon == 1 then
   #   GPhys::NetCDF_IO.write(ofile2d,gpfingeo)
   #end
end

# (2) dmp file
# defined NetCDF file
ofilename3d = "#{crsdir}/#{exprim}.dmp.united.nc"
ofile3d = NetCDF.create(ofilename3d)

ofile3d.def_dim("x",nx)
ofile3d.def_dim("y",ny)
ofile3d.def_dim("z",nz)
ofile3d.def_dim("time",0)
x_nc = ofile3d.def_var("x","float",["x"])
y_nc = ofile3d.def_var("y","float",["y"])
z_nc = ofile3d.def_var("z","float",["z"])
t3d_nc = ofile3d.def_var("time","float",["time"])
x_nc.put_att("long_name",x.get_att("long_name"))
y_nc.put_att("long_name",y.get_att("long_name"))
z_nc.put_att("long_name",z.get_att("long_name"))
t3d_nc.put_att("long_name",t3d.get_att("long_name"))
x_nc.put_att("units",x.get_att("units"))
y_nc.put_att("units",y.get_att("units"))
z_nc.put_att("units",z.get_att("units"))
t3d_nc.put_att("units",t3d.get_att("units"))
vgeo_nc = Array.new(vnumdmp)
v3d_nc = Array.new(vnumdmp)

for k in 0..vnumgeo-1  # geography data
   vgeo_nc[k] = ofile3d.def_var(geovname[k],"sfloat",["x","y"])
   vgeo_nc[k].put_att("long_name",geolname[k])
   vgeo_nc[k].put_att("units",geouname[k])
   vgeo_nc[k].put_att("missing_value",undefv)
end
for k in 0..vnumdmp-1  # dmp data
   if dmpnz[k] == 1 then
      v3d_nc[k] = ofile3d.def_var(dmpvname[k],"sfloat",["x","y","time"])
   else
      v3d_nc[k] = ofile3d.def_var(dmpvname[k],"sfloat",["x","y","z","time"])
   end
   v3d_nc[k].put_att("long_name",dmplname[k])
   v3d_nc[k].put_att("units",dmpuname[k])
   v3d_nc[k].put_att("missing_value",undefv)
   p v3d_nc[k]
end
ofile3d.enddef
# end NetCDF definition

# write data
x_nc.put( x.val )
y_nc.put( y.val )
z_nc.put( z.val )

for k in 0..vnumgeo-1
   vgeo_nc[k].put(gpfingeo[k].val)
end

for i in 0..nt3d-1
   istr = 0
   for k in 0..vnumdmp-1
      ctime = (ts + i * dt3d).to_s.rjust(8,'0')
      dmpgrd = "#{crsdir}/#{exprim}.dmp#{ctime}.united.bin"
      fsize = File.size(dmpgrd)
      fdmp = open(dmpgrd,"rb").read(fsize)
      clist = "g" + (fsize/4).to_s
      puts "Read #{dmpgrd}@#{dmpvname[k]}..."

      if dmpnz[k] == 1 then
         val3d = NArray.to_na(fdmp.unpack(clist)[istr..istr+nx*ny*dmpnz[k]-1]).reshape(nx,ny).to_type(NArray::SFLOAT)
         rval3d = VArray.new( val3d, {"long_name"=>dmplname[k], "units"=>dmpuname[k]}, dmpvname[k] )
         ##rval3d.replace_val(NArray.to_na(fdmp.unpack(clist)[istr..istr+nx*ny*dmpnz[k]-1]).reshape(nx,ny))
         #gpfin = GPhys.new( grid2d, rval3d )
         v3d_nc[k].put(rval3d.val, "start"=>[0,0,i],"end"=>[-1,-1,i])
      else
         val3d = NArray.to_na(fdmp.unpack(clist)[istr..istr+nx*ny*dmpnz[k]-1]).reshape(nx,ny,dmpnz[k]).to_type(NArray::SFLOAT)
         rval3d = VArray.new( val3d, {"long_name"=>dmplname[k], "units"=>dmpuname[k]}, dmpvname[k] )
#p rval3d, dmpnz[k], istr, istr+nx*ny*dmpnz[k]-1
         ##rval3d.replace_val(NArray.to_na(fdmp.unpack(clist)[istr..istr+nx*ny*dmpnz[k]-1]).reshape(nx,ny,dmpnz[k]))
         #gpfin = GPhys.new( grid3d, rval3d )
         v3d_nc[k].put(rval3d.val, "start"=>[0,0,0,i],"end"=>[-1,-1,-1,i])
      end

      istr = istr + nx*ny*dmpnz[k]

      #gpfin.set_att("missing_value", NArray.to_na([undefv]) )
      #GPhys::NetCDF_IO.write(ofile3d,gpfin)
   end

   t3d_nc.put( t3d.val[i], "index"=>[i] )  # 時間を逐次入力
end

ofile3d.close
puts "Output NetCDF file: #{ofilename3d}"

if dmpmon == 1 then
   # (3) mon file
   # defined NetCDF file
   ofilename2d = "#{crsdir}/#{exprim}.mon.united.nc"
   ofile2d = NetCDF.create(ofilename2d)

   ofile2d.def_dim("x",nx)
   ofile2d.def_dim("y",ny)
   ofile2d.def_dim("time",0)
   x_nc = ofile2d.def_var("x","float",["x"])
   y_nc = ofile2d.def_var("y","float",["y"])
   t2d_nc = ofile2d.def_var("time","float",["time"])
   x_nc.put_att("long_name",x.get_att("long_name"))
   y_nc.put_att("long_name",y.get_att("long_name"))
   t2d_nc.put_att("long_name",t2d.get_att("long_name"))
   x_nc.put_att("units",x.get_att("units"))
   y_nc.put_att("units",y.get_att("units"))
   t2d_nc.put_att("units",t2d.get_att("units"))
   v2d_nc = Array.new(vnummon)

   for k in 0..vnumgeo-1  # geography data
      vgeo_nc[k] = ofile2d.def_var(geovname[k],"sfloat",["x","y"])
      vgeo_nc[k].put_att("long_name",geolname[k])
      vgeo_nc[k].put_att("units",geouname[k])
      vgeo_nc[k].put_att("missing_value",undefv)
   end
   for k in 0..vnummon-1  # mon data
      v2d_nc[k] = ofile2d.def_var(monvname[k],"sfloat",["x","y","time"])
      v2d_nc[k].put_att("long_name",monlname[k])
      v2d_nc[k].put_att("units",monuname[k])
      v2d_nc[k].put_att("missing_value",undefv)
   end
   ofile2d.enddef
   # end NetCDF definition

   # write data
   x_nc.put( x.val )
   y_nc.put( y.val )

   for k in 0..vnumgeo-1
      vgeo_nc[k].put(gpfingeo[k].val)
   end

   for i in 0..nt2d-1
      istr = 0
      for k in 0..vnummon-1
         ctime = (ts + i * dt2d).to_s.rjust(8,'0')
         mongrd = "#{crsdir}/#{exprim}.mon#{ctime}.united.bin"
         fsize = File.size(mongrd)
         fmon = open(mongrd,"rb").read(fsize)
         clist = "g" + (fsize/4).to_s
         puts "Read #{mongrd}@#{monvname[k]}..."

         val2d = NArray.to_na(fmon.unpack(clist)[istr..istr+nx*ny-1]).reshape(nx,ny).to_type(NArray::SFLOAT)
         rval2d = VArray.new( val2d, {"long_name"=>monlname[k], "units"=>monuname[k]}, monvname[k] )
         ##rval2d.replace_val(NArray.to_na(fmon.unpack(clist)[istr..istr+nx*ny-1]).reshape(nx,ny))
         #gpfin = GPhys.new( grid2d, rval2d )
         v2d_nc[k].put(rval2d.val, "start"=>[0,0,i],"end"=>[-1,-1,i])

         istr = istr + nx*ny

         #gpfin.set_att("missing_value", NArray.to_na([undefv]) )
         #GPhys::NetCDF_IO.write(ofile2d,gpfin)
      end

      t2d_nc.put( t2d.val[i], "index"=>[i] )  # 時間を逐次入力
   end

   ofile2d.close
   puts "Output NetCDF file: #{ofilename2d}"

end

puts "Stopped normally."
