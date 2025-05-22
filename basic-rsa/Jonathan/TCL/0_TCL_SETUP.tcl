############################################################
# TCL Script to verify and build wrapper for secure design #
############################################################
set path [file dirname [file normalize [info script]]]
puts $path
set start_time [clock milliseconds]

    source $path/1_user_config_modmult.tcl
    source $path/2_onespin_config_without_sva.tcl
    source $path/3_generate_sva_single.tcl
    source $path/4_read_sva_single.tcl
    source $path/5_get_timings_single.tcl
    if {$operation_flag == 2} {
        source $path/6_generate_sva_overall.tcl
        source $path/7_get_timings_overall.tcl
        source $path/8_read_sva_overall.tcl
    }
    source $path/9_build_wrapper_improvement_new.tcl
set end_time [clock milliseconds]
    source $path/10_summary.tcl