#################
# WCET ? SETUP #
################

set script_path [file dirname [file normalize [info script]]]

#############################
# HELPER-FUNCTIONS & PARAMS #
#############################



#set var [list -1 0 1 [expr $WIDTH / 2] $WIDTH]

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

# Extract WIDTH from the serdiv_no_tidal.sva file
set sv_file [file join $script_path "serdiv_no_tidal.sva"]
set width [get_width $sv_file]

##########################
# Loop Witness Reachable #
##########################

# Initialize latency value
set latency 1
puts $latency
# Set stopping condition: twice the WIDTH
set max_latency [expr {$width * 2}]

# Initial Check to start
exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency;/" $sv_file
puts $latency
check  -all [get_checks]
while {($latency <= $max_latency) && (![string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]])} {


    puts "Testing MAX_LATENCY = $latency"

    # Update MAX_LATENCY in the property file
    exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency;/" $sv_file

    # Reload and rerun SVA
    after 1000
    read_sva
    check  -all [get_checks]

    # Increment latency for the next iteration
    incr latency
}


if {[string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]]} {
    puts "Loop finished. WCET is [expr {$latency - 3}]"
} else {
    puts "Loop finished without solution?"
}




# check -all [get_checks]



#Just some random things I could need
#get_counterexample_value
#get_counterexample_value -signals {serdiv.out_vld_o} checker_bind.wcet_p_a
#
#check -pass [ list checker_bind.wcet_p_a ]
#get_check_info -status checker_bind.upec_dit_unrolled_p_a
#get_check_info -status -witness checker_bind.wcet_p_a






