# Prep
Scripts and programs to prepare preprocess files in CReSS. 

To run programs in subdirectories, you need to edit `Mkinclude`, depending on your environment.

* `Topo/`: Make topography data (required in terrain.exe)
  * How to use
    1. Download GTOPO/SRTM30 "DEM" data from websites (ex., [NCAR](https://rda.ucar.edu/datasets/d758000/)). If the data are compressed, you need to decompress them after the download. 
    2. Specify the area required for your experiments in namelist files: `srtm30.nml` or `gtopo30.nml`
    3. Run `$ make` (if you specify a certain program, you run `$ make TOPO30`, for example)
    4. Run the script: `$ ./TOPO30 < [conf]`
    5. After normally finished the run, you can get the GrADS CTL file:
       ```
       ----------------------------------------------------
       dset ^data.terrain.bin
       title terrain height by SRTM30
       undef -1.0e35
       options big_endian template
       xdef   4800 LINEAR   6.00000000E+01   8.33333377E-03
       ydef  12000 LINEAR  -1.10000000E+02   8.33333377E-03
       zdef      1 LEVELS 1
       tdef      1 LINEAR 00Z01JAN0000 00hr
       vars    1
       ht   0 99 terrain height (m)
       endvars
       ----------------------------------------------------
       ```
  * Note
    * If you have an error `Segmentation fault`, you need to increase your memory stack: `$ ulimit -s unlimited`
