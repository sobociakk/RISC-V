file mkdir syn/out

set rtl_dirs {
    rtl/packages
    rtl/core
    rtl/memory
    rtl/bus
    rtl/peripherals
    rtl/top
}

foreach dir $rtl_dirs {
    set files [glob -nocomplain "$dir/*.sv"]
    if {[llength $files] > 0} {
        puts "Reading files from $dir: $files"
        read_verilog -sv $files
    } else {
        puts "No .sv files found in $dir, skipping..."
    }
}

# Read interfaces
set if_files [glob -nocomplain "rtl/interfaces/*.sv"]
if {[llength $if_files] > 0} {
    puts "Reading interfaces: $if_files"
    read_verilog -sv $if_files
}

set xdc_files [glob -nocomplain "constraints/*.xdc"]
if {[llength $xdc_files] > 0} {
    puts "Reading constraints: $xdc_files"
    read_xdc $xdc_files
} else {
    puts "Warning: No constraints (.xdc) found. Timing analysis will be skipped."
}

# TODO: Update -part to match your target FPGA
synth_design -top soc_top -part xc7a35tcpg236-1

report_utilization -file syn/out/utilization.txt
report_timing_summary -file syn/out/timing.txt
