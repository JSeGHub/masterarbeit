############################################################
# TCL Script to verify and build wrapper for secure design #
############################################################
set path [file dirname [file normalize [info script]]]
puts $path
set start_time [clock milliseconds]

    source $path/user_config_serdiv.tcl
    source $path/onespin_config_without_sva.tcl
    source $path/generate_sva.tcl
    source $path/read_sva.tcl
    source $path/get_timings.tcl
    source $path/build_wrapper_single_improvement.tcl

set end_time [clock milliseconds]

source $path/summary.tcl
