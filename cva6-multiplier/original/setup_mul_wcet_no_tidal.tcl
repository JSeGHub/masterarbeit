#################
# WCET - SETUP #
################
restart -force
set script_path [file dirname [file normalize [info script]]]
break

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

# Function to generate semi-random values
proc generate_values {width steps} {
    set values [list]
    set special_values [list -$width -[expr {$width / 2}] -1 0 1 [expr {$width / 2}] $width]

    # Step size based on the number of steps
    set step_size [expr {(2.0 * $width) / $steps}]

    for {set i 0} {$i < $steps} {incr i} {
        # Base value (evenly distributed)
        set base_value [expr {- $width + ($i * $step_size)}]

        # Random offset (max ? step_size / 2)
        set random_offset [expr {(rand() - 0.5) * $step_size}]

        # Final value
        set new_value [expr {$base_value + $random_offset}]

        lappend values [expr {round($new_value)}]  ;# Round to integer values
    }

    # Ensure the special values are always included
    foreach val $special_values {
        if {[lsearch -exact $values $val] == -1} {
            lappend values $val
        }
    }

     # Sort and remove duplicates to guarantee an increasing sequence
    set values [lsort -integer -unique $values]

    # Convert the generated list to the format needed for SystemVerilog
    set sv_list "["
    foreach val $values {
        append sv_list "$val, "
    }
    # Remove the trailing comma and space
    set sv_list [string trimright $sv_list ", "]
    append sv_list "]"

    return $sv_list
}



proc find_first_one { {signal "checker_bind.wcet_in_p_a"} } {
    # Retrieve the response from the command with a flexible signal name
    set response [get_counterexample_value -witness -signals serdiv.out_vld_o $signal]

    # Remove curly braces from the response
    set response [string trim $response "{}"]

    # Convert the response into a list
    set list [split $response " "]

    # Print the list
    puts "List: $list"

    # Find the position of the first occurrence of "1"
    set index -1
    for {set i 0} {$i < [llength $list]} {incr i} {
        if {[lindex $list $i] == "1"} {
            incr i ; # Start counting by 1 instead of 0
            set index $i
            break
        }
    }

    # Print the result
    puts "The position of the first '1' is: $index"

    # Return the index in case it's needed elsewhere
    return $index
}

#################################
# Design Setup and Verification #
#################################

# TODO 
# Auswahl treffen mit TCL Auswahlliste, welche Dateien aufgerufen werden sollen. Abh?ngig von Serdiv, multiplier und RSA

read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cf_math_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/rvfi_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/riscv_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_dm_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cv64a6_imafdc_sv39_config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/config_pkg.sv}
#read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/lzc.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/multiplier.sv}

set_elaborate_option -golden -verilog_parameter {WIDTH=8}

elaborate -golden

compile -golden

set_mode mv


# List all .sva files in the directory
#puts "Available SVA files in $script_path:"
#set sva_files [glob -nocomplain $script_path/*.sva]

#if {[llength $sva_files] == 0} {
#    puts "No SVA files found!"
#    exit
#}

#foreach f $sva_files { puts [file tail $f] }

# Ask the user to enter a file name
#puts "Enter the desired SVA filename (including extension):"
#flush stdout
#gets stdin sva_file

# Read the selected SVA file
#read_sva -version {sv2012} "$script_path/$sva_file"

#read_sva -version {sv2012} {$script_path/serdiv_no_tidal.sva}
#read_sva -version {sv2012} {$script_path/setup_input_wcet.sva}
read_sva -version {sv2012} {$script_path/multiplier_no_tidal_input.sva}

#######
#######
# RUN #
#######
#######

#############
# Get WIDTH #
#############

# Extract WIDTH from the serdiv_no_tidal_input.sva file
set sv_file [file join $script_path "serdiv_no_tidal_input.sva"]
set width [get_width $sv_file]
#puts $width

#################################
# Loop WCET - Witness Reachable #
#################################

# Initialize latency value
set latency_wcet 1
# Set stopping condition: twice the WIDTH
set max_latency [expr {$width * 2}]

# Update MAX_LATENCY in the property file
exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency_wcet;/" $sv_file

# Initial Check to start
after 1000
check  -all [get_checks]
while {($latency_wcet <= $max_latency) && (![string match "unreachable" [get_check_info -status -witness checker_bind.wcet_in_p_a]])} {

    puts $latency_wcet
    # Update MAX_LATENCY in the property file
    exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency_wcet;/" $sv_file
    
    # Reload and rerun SVA - saving MAX_LATENCY takes time, because it's an extern action
    after 1000
    read_sva
    
    # Check witness
    compute_witness checker_bind.wcet_in_p_a
    #check -pass [ list checker_bind.wcet_p_a ]
    
    # Increment latency for the next iteration
    incr latency_wcet
    puts $latency_wcet
}

if {[string match "unreachable" [get_check_info -status -witness checker_bind.wcet_in_p_a]]} {
    # Output WCET: -3 because of: preparing cycle + unreachable cycle + incr latency_wcet
    puts "Loop finished. WCET is [expr {$latency_wcet - 3}]!"
    # Update MAX_LATENCY in the property file to actual max latency
    set adjusted_latency [expr {$latency_wcet - 2}]
    exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $adjusted_latency;/" $sv_file
} else {
    puts "Loop finished without solution!"
}


#############################
# Loop Input Dependend WCET #
#############################

#for calculate semi-random values
#set special_values [list -$width -[expr {$width / 2}] -1 0 1 [expr {$width / 2}] $width]
#set steps [expr {($width * $width) - 1}]

# Generate 'b' values with randomness
#set sv_list [generate_values $width $steps]
# Now update the SystemVerilog file by replacing the existing INPUT_A_LIST
#exec sed -i "s/localparam int INPUT_A_LIST\[\]\s*=\s*'.*/localparam int INPUT_A_LIST[] = $sv_list;/" $sv_file
# Output the generated values (optional)
#puts "Generated values: $sv_list"


# Set max_latency to calculate input-dependend latency
#exec sed -i "s/localparam MAX_LATENCY = .*/localparam MAX_LATENCY = $latency_wcet -3;/" $sv_file


# Iterate over each value
#foreach a $values {
#    foreach b $values {
#        puts "Testing with a=$a, b=$b"

        # Set inputs for formal verification
#        set_input_values $a $b  ;# Replace with actual command

          # Set inputs for formal verification
#        set_input_values $a $b  ;# Replace with actual command

        # Initialize latency value
#        set latency 1
        # Set stopping condition: twice the WIDTH
#        set max_latency [expr {$width * 2}]      

        # Initial Check to start
#        after 1000
#        check  -all [get_checks]

#        while {($latency <= $latency_wcet) && (![string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]])} {

            # Reload and rerun SVA - saving MAX_LATENCY takes time
            #after 500
#            read_sva

            # Check witness
#            check -pass [list checker_bind.wcet_p_a]

            # Increment latency for the next iteration
#            incr latency
#        }

#        if {[string match "unreachable" [get_check_info -status -witness checker_bind.wcet_p_a]]} {
#            set latency_calc = $latency - 3
#            puts "WCET for a=$a, b=$b is $latency_calc"
            # Store the result in the list
#            lappend wcet_results [list $a $b $latency_calc]
#        } else {
#            puts "No solution for a=$a, b=$b"
#        }
#    }
#}
#


# Antwort abrufen (Beispiel)
#set antwort [get_counterexample_value -witness -signals serdiv.out_vld_o checker_bind.wcet_p_a]

# Geschweifte Klammern entfernen
#set antwort [string trim $antwort "{}"]

# Antwort in eine Liste umwandeln
#set liste [split $antwort " "]

# Liste ausgeben
#puts "Liste: $liste"

# Position der 1 finden
#set index -1
#for {set i 0} {$i < [llength $liste]} {incr i} {
#    if {[lindex $liste $i] == "1"} {
#        set index $i
#        break
#    }
#}

# Ergebnis ausgeben
#puts "Die Position der 1 ist: $index"

######################################



# Call the procedure
#find_first_one "checker_bind.wcet_p_a"

#get_counterexample_value -witness -signals serdiv.out_vld_o checker_bind.wcet_p_a ---> {0 0 0 0 0 0 0 1}