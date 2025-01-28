# @lang=tcl @ts=8

################
# WCET – SETUP #
################

set script_path [file dirname [file normalize [info script]]]

#############################
# HELPER-FUNCTIONS & PARAMS #
#############################


set min_latency 1
set max_latency [expr $WIDTH *2]
set max_latency_found 0

set var [list -1 0 1 [expr $WIDTH / 2] $WIDTH]

# Function to extract the WIDTH parameter from the Verilog file
proc get_width {file} {
    # Open the Verilog file and search for WIDTH parameter
    set fid [open $file r]
    set file_contents [read $fid]
    close $fid

    # Use regular expression to find WIDTH value
    if {[regexp {parameter WIDTH = (\d+)} $file_contents match width_value]} {
        return $width_value
    } else {
        error "WIDTH parameter not found in $file"
    }
}


#################################
# Design Setup and Verification #
#################################

read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cf_math_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/rvfi_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/riscv_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_dm_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cv64a6_imafdc_sv39_config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/lzc.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/serdiv.sv}

set_elaborate_option -golden -verilog_parameter {WIDTH=8}

elaborate -golden

compile -golden

set_mode mv

read_sva -version {sv2012} {$script_path/serdiv_no_tidal.sva}

#######
#######
# RUN #
#######
#######

#############
# Get WIDTH #
#############

# Define the path to the property_checker.sv file (adjust the file name if needed)
set sv_file [file join $script_path "property_checker.sv"]

# Extract WIDTH from the property_checker.sv file
set width [get_width $sv_file]


##########################
# Loop Witness Reachable #
##########################

HIER WEITERMACHEN


while {$latency <= $max_latency} {
    # Modify the property_checker module with the current MAX_LATENCY
    puts "Testing MAX_LATENCY = $latency"

    # Replace the MAX_LATENCY parameter in the property file
    exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency;/" $sv_file

    # Rerun the property check with updated MAX_LATENCY
    exec onespin --check $sv_file

    # Check the witness status using the get_check_info command
    if {[get_check_info -status -witness checker_bind.wcet_p_a] == "hold"} {
        puts "Witness is reachable at MAX_LATENCY = $latency"
        set max_latency_found $latency
    } elseif {[get_check_info -status -witness checker_bind.wcet_p_a] == "unreachable"} {
        puts "Witness becomes unreachable at MAX_LATENCY = $latency"
        break
    } else {
        puts "Unexpected result for MAX_LATENCY = $latency"
        break
    }

    # Increment latency for the next iteration
    incr latency
}





# check -all [get_checks]



Just some random things I could need
#get_counterexample_value
#get_counterexample_value -signals {serdiv.out_vld_o} checker_bind.wcet_p_a
#
#check -pass [ list checker_bind.bcet_p_a ]
#get_check_info -status checker_bind.upec_dit_unrolled_p_a
#get_check_info -status -witness checker_bind.wcet_p_a





# Loop through MAX_LATENCY values
for {set latency $min_latency} {$latency <= $max_latency} {incr latency} {
    # Modify the property_checker module with the current MAX_LATENCY
    puts "Testing MAX_LATENCY = $latency"

    # Replace the MAX_LATENCY parameter in the property file
    exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency;/" property_checker.sv

    # Run OnesSpin with the updated code
    set result [exec onespin --check property_checker.sv]
    
    # Analyze the result
    if {[string match *UNREACHABLE* $result]} {
        puts "Witness becomes unreachable at MAX_LATENCY = $latency"
        break
    } elseif {[string match *REACHABLE* $result]} {
        puts "Witness is reachable at MAX_LATENCY = $latency"
        set max_latency_found $latency
    } else {
        puts "Unexpected result for MAX_LATENCY = $latency"
        break
    }
}

# Print the result
if {$max_latency_found > 0} {
    puts "The maximum latency where the witness is reachable is: $max_latency_found"
} else {
    puts "No reachable witness found within the specified range."
}
