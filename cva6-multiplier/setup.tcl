################
# WCET - SETUP #
################
source -signed "/import/usr/onespin/latest/etc/startup/onespin_startup.tcl.obf"
restart

set script_path [file dirname [file normalize [info script]]]
puts $script_path
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/include/riscv_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/include/ariane_pkg.sv} 
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/include/config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/include/cv32a6_imac_sv0_config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/original/multiplier_no_packages.sv}

set_elaborate_option -golden -verilog_parameter {WIDTH=8}
elaborate -golden
compile -golden
set_mode mv

read_sva -version {sv2012} {$script_path/original/multiplier_no_tidal_input.sva}

#############################
# HELPER-FUNCTIONS & PARAMS #
#############################

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

#######
# RUN #
#######

# Get WIDTH # Extract WIDTH from the multiplier_no_tidal_input.sva file
set sv_file [file join $script_path "original" "multiplier_no_tidal_input.sva"]
set width [get_width $sv_file]


# Loop WCET - Witness Reachable #


# Initialize latency value
set latency_wcet 0
puts "latency: $latency_wcet"
# Set stopping condition: twice the WIDTH
set max_latency [expr {$width * 2}]

# Update MAX_LATENCY in the property file
exec sed -i "s/localparam MIN_LATENCY = .*/localparam MIN_LATENCY = $latency_wcet;/" $sv_file

# Initial Check to start
after 1000
check  -all [get_checks]
#while {($latency_wcet <= $max_latency) && (![string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]])} {


while {($latency_wcet <= $max_latency) && ([string match "hold" [get_check_info -status checker_bind.wcet_p_a]])} {

    puts $latency_wcet
    # Update MAX_LATENCY in the property file
    exec sed -i "s/localparam MIN_LATENCY = .*/localparam MIN_LATENCY = $latency_wcet;/" $sv_file
    
    # Reload and rerun SVA - saving MAX_LATENCY takes time, because it's an extern action
    after 1000
    read_sva
    
    # Check witness
    check  [ list checker_bind.wcet_p_a ]
    #compute_witness checker_bind.wcet_p_a
    #check -pass [ list checker_bind.wcet_p_a ]
    
    # Increment latency for the next iteration
    incr latency_wcet
    puts "latency: $latency_wcet"
}


if {![string match "hold" [get_check_info -status checker_bind.wcet_p_a]]} {
    # Output WCET
    puts "Loop finished. WCET is [expr {$latency_wcet-2}]!"
    # Update MAX_LATENCY in the property file to actual max latency
    #set adjusted_latency [expr {$latency_wcet - 2}]
    #exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $adjusted_latency;/" $sv_file
} else {
    puts "Loop finished without solution!"
}