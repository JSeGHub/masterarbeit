#################
# WCET - SETUP #
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
puts $width

##########################
# Loop Witness Reachable #
##########################

# Initialize latency value
set latency 1
# Set stopping condition: twice the WIDTH
set max_latency [expr {$width * 2}]


# Update MAX_LATENCY in the property file
exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency;/" $sv_file

# Initial Check to start
after 1000
check  -all [get_checks]
while {($latency <= $max_latency) && (![string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]])} {

    # Update MAX_LATENCY in the property file
    exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency;/" $sv_file

    # Reload and rerun SVA - saving MAX_LATENCY takes time, because it's an extern action
    after 500
    read_sva
    
    # Check witness
    check -pass [ list checker_bind.wcet_p_a ]

    # Increment latency for the next iteration
    incr latency
}


if {[string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]]} {
    # Output WCET: -3 because of preparing cycle + unreachable cycle + incr latency
    puts "Loop finished. WCET is [expr {$latency - 3}]"
} else {
    puts "Loop finished without solution!"
}







