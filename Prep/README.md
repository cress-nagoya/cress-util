# Prep
Scripts and programs to prepare preprocess files in CReSS. 

To run programs in subdirectories, you need to edit `Mkinclude`, depending on your environment.

* `Topo/`: Make topography data (required in terrain.exe)
  * How to use
    1. Download GTOPO/SRTM30 "DEM" data from websites (ex., [NCAR](https://rda.ucar.edu/datasets/d758000/)). 
    2. Specify the area required for your experiments in namelist files: `srtm30.nml` or `gtopo30.nml`
    3. Run `$ make` (if you specify a certain program, you run `$ make TOPO30`, for example)
    4. Run the script: `$ ./Topo < [conf]`

