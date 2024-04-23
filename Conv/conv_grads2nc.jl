# Author: Satoki Tsujino (satoki@gfd-dennou.org)
# Date: 2024/04/17, 2024/04/23

using NCDatasets
using Dates

##### --- set your environments
ctlfile = "t1330haiyan_cress2km2013110500a_500m0718a.dmp.cut.ctl"  # CReSS ctl file
#geofile = "t1330haiyan_cress2km2013110500a_500m0718a.gepgraphy.united.bin"  # CReSS geography file
initime = "2013/11/07 18:00:00"  # YYYY/MM/DD HH:NN:SS
##### --- set your environments


fctl = open(ctlfile,"r")
fcont = readlines(fctl)

ctmin = ""
pdeflag = false

#-- Analysis of GrADS CTL file
for i in 1:size(fcont)[1]
    fline = split(fcont[i])
    if fline[1][1] != '*'  # check comment out
        if fline[1] == "dset"
            global file_template = replace(fline[2],"^" => "")
            tmpwork,tmpfoot = split(fline[2],"%y4")
            tmp_sep,tmpwork = split(tmpfoot,".")
            if tmp_sep[1] != '0'
                global time_separate = 0
            else
                global time_separate = parse(Int,'1' * tmp_sep)
            end
        elseif fline[1] == "undef"
            global miss_val = parse(Float32,fline[2])
        elseif fline[1] == "xdef"
            global nx = parse(Int,fline[2])
            global xmin = parse(Float64,fline[4])
            global dx = parse(Float64,fline[5])
        elseif fline[1] == "ydef"
            global ny = parse(Int,fline[2])
            global ymin = parse(Float64,fline[4])
            global dy = parse(Float64,fline[5])
        elseif fline[1] == "zdef"
            global nz = parse(Int,fline[2])
            global zax = zeros(Float64,nz)
            iz_count = 1
            for j in 4:size(fline)[1]
                global zax[iz_count] = parse(Float64,fline[j])
                iz_count = iz_count + 1
            end
            for j in i+1:size(fcont)[1]
                tmpline = split(fcont[j])
                if tmpline[1] == "tdef"
                    break
                else
                    global zax[iz_count:iz_count+size(tmpline)[1]-1] .= parse.(Float64,tmpline[1:end])
                    iz_count = iz_count + size(tmpline)[1]
                end
            end
        elseif fline[1] == "tdef"
            global nt = parse(Int,fline[2])
            if occursin("yr",fline[5]) == true
                if time_separate != 0  # replacing unit: year -> second
                    global dt = parse(Int,replace(fline[5],"yr"=>"")) * time_separate
                    global dt_inc = parse(Int,replace(fline[5],"yr"=>""))
                else  # unit is correct (no replace) and converting unit to second
                    global dt = parse(Int,replace(fline[5],"yr"=>"")) * 86400 * 365
                    global dt_inc = dt
                end
            else  # unit is correct (no replace) and converting unit to second
                if occursin("dy",fline[5]) == true
                    global dt = parse(Int,replace(fline[5],"dy"=>"")) * 86400
                elseif occursin("hr",fline[5]) == true
                    global dt = parse(Int,replace(fline[5],"hr"=>"")) * 3600
                elseif occursin("mn",fline[5]) == true
                    global dt = parse(Int,replace(fline[5],"mn"=>"")) * 60
                elseif occursin("sc",fline[5]) == true
                    global dt = parse(Int,replace(fline[5],"sc"=>""))
                end
                global dt_inc = dt
            end
            if time_separate != 0  # initial date and time is given from "initime"
                global curtime = replace(initime,"/"=>"-")
            else  # initial date and time is given from ctl file
                tmptime = replace(fline[4],r"[a-z]" => uppercase)  # convert lowercase to uppercase
                tmptime = replace(tmptime,"JAN" => "01")
                tmptime = replace(tmptime,"FEB" => "02")
                tmptime = replace(tmptime,"MAR" => "03")
                tmptime = replace(tmptime,"APR" => "04")
                tmptime = replace(tmptime,"MAY" => "05")
                tmptime = replace(tmptime,"JUN" => "06")
                tmptime = replace(tmptime,"JUL" => "07")
                tmptime = replace(tmptime,"AUG" => "08")
                tmptime = replace(tmptime,"SEP" => "09")
                tmptime = replace(tmptime,"OCT" => "10")
                tmptime = replace(tmptime,"NOV" => "11")
                tmptime = replace(tmptime,"DEC" => "12")
                tmp_utc = split(split(tmptime,"Z")[1],":")
                global curtime = tmptime[end-3:end] * '-' * tmptime[end-5:end-4] * '-' * tmptime[end-7:end-6] * ' ' * split(tmptime,"Z")[1]
                if size(tmp_utc)[1] == 1  # HHZ
                    global curtime = curtime * ":00:00"
                elseif size(tmp_utc)[1] == 2  # HH:NNZ
                    global curtime = curtime * ":00"
                end
            end
        elseif fline[1] == "vars"
            global nv = parse(Int,fline[2])
            global nvlev = zeros(Int,nv)
            tmpvar = ""
            tmpvarl = ""
            tmpvaru = ""
            it_count = 1
            for j in i+1:size(fcont)[1]
                tmpline = split(fcont[j])
                if tmpline[1] == "endvars"
                    global varname = split(tmpvar,"\n")
                    global varlname = split(tmpvarl,"\n")
                    global varuname = split(tmpvaru,"\n")
                    break
                else
                    tmpvar = tmpvar * tmpline[1] * "\n"
                    nvlev[it_count] = parse.(Int,tmpline[2])
                    tmpvarl = tmpvarl * join(tmpline[4:end-1],' ') * "\n"
                    tmpvaru = tmpvaru * replace(replace(tmpline[end],"[" => ""),"]" => "") * "\n"
                    it_count = it_count + 1
                end
            end
        elseif fline[1] == "pdef"  # currently not support
            pdeflag = true
        end
        println(fline)
    end
end
#-- Analysis of GrADS CTL file

#-- Define meta data for NetCDF file
xax = zeros(Float64,nx)
yax = zeros(Float64,ny)
tax = zeros(Float64,nt)
xax[1:nx] = [xmin + dx * (j - 1) for j in 1:nx]
yax[1:ny] = [ymin + dy * (j - 1) for j in 1:ny]
tax[1:nt] = [dt * (j - 1) for j in 1:nt]
time_format = Dates.DateFormat("y-m-d H:M:S")
#println(curtime)
idatetime = Dates.DateTime(curtime,time_format)
#println(idatetime)
#println(varlname)
r3val = zeros(Float32,nx*ny*nz)
rr3val = reshape(zeros(Float32,nx,ny,nz,1),nx,ny,nz,1)

#-- Initialize the NetCDF
ax_dim = ["", "", "", ""]
ax_long = ["", "", "", ""]
ax_unit = ["", "", "", ""]
if pdeflag == true
    ax_dim[1:2] = ["x", "y"]
    ax_long[1:2] = ["X-direction", "Y-direction"]
    ax_unit[1:2] = ["m", "m"]
else
    ax_dim[1:2] = ["lon", "lat"]
    ax_long[1:2] = ["longitude", "latitude"]
    ax_unit[1:2] = ["degree_east", "degree_north"]
end

ax_dim[3:4] = ["z", "time"]
ax_long[3:4] = ["height", "seconds since " * curtime]
ax_unit[3:4] = ["m", "s"]

#-- In/Output data
for i in 1:nt
    if time_separate != 0  # dt_inc != dt
        tmptime = (i - 1) * dt_inc
        ifile = replace(file_template,"%y4" => lpad(tmptime,4,"0"))
    else
        tmptime = idatetime + Second(dt_inc * (i - 1))
        ifile = replace(
                  replace(
                    replace(
                      replace(
                        replace(
                          replace(file_template,"%y4" => lpad(string(year(tmptime)),4,"0")),
                                                "%m2" => lpad(string(month(tmptime)),2,"0")),
                                                "%d2" => lpad(string(day(tmptime)),2,"0")),
                                                "%h2" => lpad(string(hour(tmptime)),2,"0")),
                                                "%n2" => lpad(string(minute(tmptime)),2,"0")),
                                                "%s2" => lpad(string(second(tmptime)),2,"0"))
    end
    println(ifile)
    ofile = ifile * ".nc"
    isfile(ofile) && println("*** Note ***: existed file $(ofile) is removed.")
    isfile(ofile) && rm(ofile)
    fi_io = open(ifile,"r")

    ds = NCDataset(ofile,"c")

    # Define the dimension "lon" and "lat" with the size 100 and 110 resp.
    defDim(ds,ax_dim[1],nx)
    defDim(ds,ax_dim[2],ny)
    defDim(ds,ax_dim[3],nz)
    defDim(ds,ax_dim[4],1)
    ds.attrib["title"] = "Automatically converted from CReSS simulation"

    vs = defVar(ds,ax_dim[1],Float64,(ax_dim[1],),attrib=Dict("long_name" => ax_long[1], "units" => ax_unit[1]))
    vs[:] = xax
    vs = defVar(ds,ax_dim[2],Float64,(ax_dim[2],),attrib=Dict("long_name" => ax_long[2], "units" => ax_unit[2]))
    vs[:] = yax
    vs = defVar(ds,ax_dim[3],Float64,(ax_dim[3],),attrib=Dict("long_name" => ax_long[3], "units" => ax_unit[3]))
    vs[:] = zax
    vs = defVar(ds,ax_dim[4],Float64,(ax_dim[4],),attrib=Dict("long_name" => ax_long[4], "units" => ax_unit[4]))
    vs[:] = tax[i:i]

    #NetCDF.create(ofile, [outvar1,outvar2,outvar3]) do nc
    for j in 1:nv
        #-- Read the GrADS data
        # this function will block repeatedly trying to read all requested bytes, until an error or end-of-file occurs. (<- from "read" in julia document)
        r3val[1:nx*ny*nvlev[j]] = reinterpret(Float32, read(fi_io, sizeof(Float32)*nx*ny*nvlev[j]))
        r3val[1:nx*ny*nvlev[j]] .= ntoh.(r3val[1:nx*ny*nvlev[j]])
        #if j < nv  # no need because "read" function automatically repeat to end-of-file
        #    skip(fi_io,sizeof(Float32)*nx*ny*nvlev[j])
        #end
        rr3val = reshape(r3val,nx,ny,nz,1)
        println(varname[j], ": ", rr3val[div(nx,2),div(ny,2),1,1])

        # Write to the NetCDF data
        vs = defVar(ds,varname[j],Float32,(ax_dim[1],ax_dim[2],ax_dim[3],ax_dim[4]),attrib=Dict("long_name" => varlname[j], "units" => varuname[j], "missing_value" => miss_val))
        vs[:,:,:,:] = rr3val[:,:,:,:]

    end

    close(ds)
    println("Output: ", ofile)
end
