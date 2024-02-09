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

