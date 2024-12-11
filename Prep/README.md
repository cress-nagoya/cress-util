# Prep
Scripts and programs to prepare preprocess files in CReSS. 

* Prepare running of programs in subdirectories
To run programs in subdirectories, you need to edit `Mkinclude`, depending on your environment:
  ```
  FC      = gfortran
  FFLAGS  = -fconvert=big-endian

  # Options used in drawing by DCL-fortran
  DCLFC   = dclfrt
  AF90LIB = dclaf90
  AF90LD  = /usr/local
  STPKLIB = stpk
  STPKLD  = /usr/local
  ```

* `Topo/`: Make topography data (required in terrain.exe)
  * How to use
    1. Download GTOPO/SRTM30 "DEM" data from websites (ex., [NCAR](https://rda.ucar.edu/datasets/d758000/)). If the data are compressed, you need to decompress them after the download. 
    2. Specify the area required for your experiments in namelist files: `srtm30.nml` or `gtopo30.nml`
    3. Run `$ make` (if you specify certain programs, you specify the program names in running such as `$ make TOPO30`)
    4. Run the script: `$ ./TOPO30 < [conf]`
    5. After normally finished the run, you can get the GrADS CTL file as follows:
       ```
       ----------------------------------------------------
       dset ^data.terrain.bin
       title terrain height by SRTM30
       undef -1.0e35
       options big_endian template
       xdef   4800 LINEAR   6.00000000E+01   8.33333377E-03
       ydef  12000 LINEAR  -1.10000000E+02   8.33333377E-03
       zdef      1 LEVELS 1
       tdef      1 LINEAR 00Z01JAN0000 01hr
       vars    1
       ht   0 99 terrain height (m)
       endvars
       ----------------------------------------------------
       ```
  * Note
    * If you have an error `Segmentation fault`, you need to increase your memory stack: `$ ulimit -s unlimited`
    * **Caution for GTOPO30**: `TOPO30` is **NOT** supporting the conversion of data covered beyond 60 degreeN/degreeS .
