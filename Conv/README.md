# Conv
Scripts to convert the original CReSS format to other formats.

* `conv_grads2nc.rb`: GrADS to NetCDF in Ruby
  * Required libraries
    * [GPhys](https://rubygems.org/gems/gphys/)
  * How to use
    1. Edit the variables depending on your environment
    ```
    conf = "user.conf.Peng"  # CReSS configuration file
    ```
    2. Run the script: `$ ruby conv_grads2nc.rb`

* `conv_grads2nc.jl`: GrADS to NetCDF in JuliaLang
  * Required packages
    * [NCDatasets](https://alexander-barth.github.io/NCDatasets.jl/stable/)
    * [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/)
  * How to use
    1. Edit the variables depending on your environment
    ```
    ctlfile = "XXX.dmp.ctl"  # CReSS control file
    ```
    2. Run the script: `$ julia conv_grads2nc.jl`

