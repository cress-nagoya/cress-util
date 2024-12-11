# Prep
Scripts and programs to prepare preprocess files in CReSS. 

* `Topo/`: Make topography data (required in terrain.exe)
  * How to use
    1. Download GTOPO/SRTM30 "DEM" data from websites (ex., [NCAR](https://rda.ucar.edu/datasets/d758000/)). 
    2. Specify the area required for your experiments in namelist files
    ```
    conf = "srtm30.nml" or "gtopo30.nml"  # CReSS configuration file
    ```
    3. Run the script: `$ ./Topo.exe < [conf]`

