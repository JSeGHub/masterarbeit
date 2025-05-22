# @lang=tcl @ts=8

####################
# Helper Functions #
####################

#######################
# Insert files #    
#######################

proc select_files {script_path extensions} {
    # Ensure extensions is a list
    if {[string is list $extensions] == 0} {
        set extensions [list $extensions]
    }
    
    # List all files matching the given extensions
    set files {}
    foreach ext $extensions {
        set files [concat $files [glob -nocomplain "$script_path/*$ext"]]
    }
    
    if {[llength $files] == 0} {
        puts "No matching files found!"
        return {}
    }
    
    puts "Available files in $script_path:"
    puts "Select file(s) by entering the corresponding number(s)."
    puts "For multiple files, separate numbers with spaces (e.g., '1 3 5')."
    puts "---------------------------------------------------------------"
    
    set i 1
    foreach f $files {
        puts "$i: [file tail $f]"
        incr i
    }
    puts "---------------------------------------------------------------"
    
    # Ask the user for selection
    flush stdout
    gets stdin selection
    
    # Process the selection
    set selected_files {}
    foreach idx [split $selection] {
        if {[string is integer $idx] && $idx > 0 && $idx < $i} {
            lappend selected_files [lindex $files [expr {$idx - 1}]]
        } else {
            puts "Warning: Invalid selection number: $idx"
        }
    }
    
    # Show what was selected
    if {[llength $selected_files] > 0} {
        puts "\nSelected file(s):"
        foreach f $selected_files {
            puts "- [file tail $f]"
        }
    } else {
        puts "No valid files selected!"
    }
    
    return $selected_files
}


#####################
# Insert Granularity #
#####################

    proc input_granularity {prompt default_value min max} {
        while {1} {
            puts -nonewline "$prompt \[$default_value\]: "
            flush stdout
            
            set input [gets stdin]
            if {$input eq ""} {
                set input $default_value
            }
            
            # Check if it's an integer
            if {![string is integer -strict $input]} {
                puts "Error: Please enter a valid integer."
                continue
            }
            
            # Check if the value is within the valid range
            if {$input < $min || $input > $max} {
                puts "Error: Granularity must be between $min and $max."
                continue
            }
            
            return $input
        }
    }


#############################
# Insert Inputs and Outputs #
#############################

    # Function for integer input with validation
    proc input_number {prompt default_value min max} {
        while {1} {
            puts -nonewline "$prompt \[$default_value\]: "
            flush stdout
            
            set input [gets stdin]
            if {$input eq ""} {
                set input $default_value
            }
            
            # Check if it's an integer
            if {![string is integer -strict $input]} {
                puts "Error: Please enter a valid integer."
                continue
            }
            
            # Check if the value is within the valid range
            if {$input < $min || $input > $max} {
                puts "Error: Value must be between $min and $max."
                continue
            }
            
            return $input
        }
    }

    # Function for text input with validation
    proc input_text {prompt {default ""}} {
        while {1} {
            if {$default ne ""} {
                puts -nonewline "$prompt \[$default\]: "
            } else {
                puts -nonewline "$prompt: "
            }
            flush stdout
            
            set input [gets stdin]
            if {$input eq "" && $default ne ""} {
                set input $default
            }
            
            # Check if input is not empty
            if {$input eq ""} {
                puts "Error: Input cannot be empty."
                continue
            }
            
            # Check if input contains only valid characters (letters, numbers, underscore)
            if {![regexp {^[a-zA-Z0-9_]+$} $input]} {
                puts "Error: Name may only contain letters, numbers, and underscores."
                continue
            }
            
            return $input
        }
    }

#####################################################################################################################################
#####################################################################################################################################

#####################
# Loop WCET - Setup #
#####################

    source -signed "/import/usr/onespin/latest/etc/startup/onespin_startup.tcl.obf"
    restart

    set script_path [file dirname [file normalize [info script]]]

    #set selected_files [select_files $script_path [list ".sva"]]
    #if {[llength $selected_files] > 0} {
    #    foreach f $selected_files {
    #        read_sva -version {sv2012} $f
    #    }
    #}

    set sva_file [file join $script_path "modmult.sva"]

    #clear_screen
    #puts "Insert WIDTH:"
    #flush stdout
    #set mpwid [gets stdin]
    set mpwid 4

    #set selected_files [select_files $script_path [list ".vhd" ".vhdl"]]
    #if {[llength $selected_files] > 0} {
    #    foreach f $selected_files {
    #        read_vhdl -golden -pragma_ignore {} -version 2008 $f
    #    }
    #}
    
    #set selected_files [select_files $script_path [list ".sv" ".v" ".vlog" ".svlog" ".inc" ".vo" ".vm" ".vlib"]]
    #if {[llength $selected_files] > 0} {
    #    foreach f $selected_files {
    #        read_verilog -golden  -pragma_ignore {}  -version sv2012  $f
    #    }
    #}

    read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult.vhd}
    set_elaborate_option -golden -vhdl_generic "mpwid=$mpwid"
    #set_elaborate_option -golden -vhdl_generic {mpwid=4}
    elaborate -golden
    compile -golden
    set_mode mv

    edit_file $script_path/../modmult.vhd
    edit_file $script_path/../modmult.sva


    set_read_sva_option -loop_iter_threshold 1025
    read_sva -version {sv2012} {$sva_file}

    set_check_option -local_processes 8
    #check -verbose -all [get_checks]



#############################
# Insert Inputs and Outputs #
#############################

    puts "\n===== Module Configuration =====\n"

    # 1. Ask for module name
    puts "insert module name"
    set module_name [input_text "Enter the module name" "modmult"]

    # 2. Query for the number of inputs (max. 5)
    puts "insert number of inputs"
    set num_inputs [input_number "How many inputs would you like to configure? (max. 5)" 3 1 5]

    # 3. Array for storing input names
    set input_names {}

    # 4. Query each input name
    puts "\nPlease enter names for the $num_inputs inputs:"
    for {set i 1} {$i <= $num_inputs} {incr i} {
        set default_name "input_$i"
        set name [input_text "Name for input $i" $default_name]
        lappend input_names $name
    }

    # 5. Ask for output name
    puts "insert output name"
    set output_name [input_text "Enter the output name" "result"]


##############################
# Loop WCET - Proof unvacous #
##############################

    set max_wcet [expr {$mpwid * 2}]  ;# Define the maximum WCET value
    set prev_status "vacuous" 
    # Loop from 1 to max_wcet and generate assertions dynamically
    for {set t_wcet $max_wcet} {$t_wcet >= 0} {incr t_wcet -1} {
        
        exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/" $sva_file
        after 1000
        check -force [ list checker_bind.ops.wcet_p_a ]

        set status [get_check_info -status checker_bind.ops.wcet_p_a]

        if {[string match "hold" $status] && ![ string match "hold" $prev_status]} {
                    #puts "WCET is $t_wcet" ;#not true WCET (calculate the cycles really included)
                    set T_WCET_EXE [expr {$t_wcet}]
                    break
        }
        set prev_status $status
    }

##############################
# Loop BCET - Proof unvacous #
##############################

    set min_bcet [expr {$mpwid * 2}]  ;# Define the maximum WCET value
    set prev_status "vacuous" 
    # Loop from 1 to min_bcet and generate assertions dynamically
    for {set t_bcet 0} {$t_bcet <= $min_bcet} {incr t_bcet} {
        
        exec sed -i "s/localparam T_BCET = .*/localparam T_BCET = $t_bcet;/" $sva_file
        after 1000
        check -force [ list checker_bind.ops.bcet_p_a ]

        set status [get_check_info -status checker_bind.ops.bcet_p_a]

        if {[string match "hold" $status] && ![ string match "hold" $prev_status]} {
                    #puts "WCET is $t_bcet" ;#not true WCET (calculate the cycles really included)
                    set T_BCET_EXE $t_bcet
                    break
        }
        set prev_status $status
    }



##############################################
# Loop input dependend WCET - Proof unvacous #
##############################################
if {0} {

set max_wcet [expr {$mpwid * 2 - 1}]  ;# Maximales WCET
#set values {0 1 2 [expr {pow(2,$mpwid)/4}] [expr {pow(2,$mpwid)/2}] [expr {pow(2,$mpwid)-2}] [expr {pow(2,$mpwid)-1}] [expr {pow(2,$mpwid)}]}
set values [list 1 2 \
    [expr {int(pow(2,$mpwid)-1)}] \
    [expr {int(pow(2,$mpwid))}]]

#set values [list 1 2 [expr {int(pow(2,$mpwid)/4)}] \
#    [expr {int(pow(2,$mpwid)/2)}] \
#    [expr {int(pow(2,$mpwid)-2)}] \
#    [expr {int(pow(2,$mpwid)-1)}] \
#    [expr {int(pow(2,$mpwid))}]]
puts $values
after 1000  ;# Wartezeit für Stabilität
set prev_status "vacuous"  ;# Letzter Status für Vergleich
set wcet_results {}  ;# Initialize the list to empty at the beginning

# Schleifen für mpand, mplier und modulus
foreach mpand $values {
    foreach mplier $values {
        foreach modulus $values {
            puts "mpand: $mpand, mplier: $mplier, modulus: $modulus"
            set prev_status "vacuous"
            set last_wcet_report -1  ;# Letzter ausgegebener WCET-Wert

            for {set t_wcet 3} {$t_wcet <= $max_wcet} {incr t_wcet} {
    
                exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/"  $sva_file
                exec sed -i "s/localparam MPAND = .*/localparam MPAND = $mpand;/"   $sva_file
                exec sed -i "s/localparam MPLIER = .*/localparam MPLIER = $mplier;/"  $sva_file
                exec sed -i "s/localparam MODULUS = .*/localparam MODULUS = $modulus;/" $sva_file
    
                after 1000
                check  [list checker_bind.ops.wcet_in_p_a]

                set status [get_check_info -status checker_bind.ops.wcet_in_p_a]

                #if {[string match "vacuous" $status] && ![ string match "vacuous" $prev_status]} {
                #    puts "WCET is $t_wcet" ;#not true WCET (calculate the cycles really included)
                #}

                # Falls WCET validiert wurde und nicht doppelt gespeichert wird
                if {[string match "vacuous" $status] && ![string match "vacuous" $prev_status]} {
                    if {$last_wcet_report != $t_wcet} {
                        # Speichere Ergebnis in der Liste
                        lappend wcet_results [list $mpand $mplier $modulus  [expr {$t_wcet-1}]]
                        puts "WCET is [expr {$t_wcet-1}] with $mpand $mplier $modulus"
                        set last_wcet_report $t_wcet
                        break
                    }
                }
                set prev_status $status
            }
        }
    }
}

#Tabelle am Ende ausgeben
puts "\n=== WCET Ergebnisse ==="
puts "MPAND  | MPLIER | MODULUS | WCET"
puts "---------------------------------"
foreach row $wcet_results {
    foreach {mpand mplier modulus t_wcet} $row {}
    puts [format "%-6d | %-6d | %-7d | %-3d" $mpand $mplier $modulus $t_wcet]
}}





######################################
# Calc Inputs for Mplier and Modulus #
######################################

    # Calculate values for testing based on mpwid
    set values {}

    # Add lowest value: 0 
    lappend values 0

    # Add highest possible value based on mpwid: 2^mpwid - 1
    lappend values [expr {(1 << $mpwid) - 1}]

    # Add values with MSB set at different positions
    for {set i 0} {$i < $mpwid} {incr i} {
        lappend values [expr {1 << $i}]
    }

    # Sort the list and remove duplicates
    set values [lsort -unique -integer $values]

    # Get total number of generated values
    set total_values [llength $values]



######################################################################
# Loop input dependend WCET - Proof transition from hold to not hold #
######################################################################


# Generate SVA-formatted parameter lists for INPUT_A and INPUT_B arrays
set sva_values_list "'{"
set first 1
foreach val $values {
    if {$first} {
        set first 0
    } else {
        append sva_values_list ","
    }
    append sva_values_list "$val"
}
append sva_values_list "}"

# Update the SVA file with the generated values lists for INPUT_A and INPUT_B
exec sed -i "s/localparam int\\\ INPUT_A\\\[WIDTH_IN\\\] = .*/localparam int\ INPUT_A\[WIDTH_IN\] = $sva_values_list;/" $sva_file
exec sed -i "s/localparam int\\\ INPUT_B\\\[WIDTH_IN\\\] = .*/localparam int\ INPUT_B\[WIDTH_IN\] = $sva_values_list;/" $sva_file
exec sed -i "s/localparam WIDTH_IN = .*/localparam WIDTH_IN = $total_values;/"  $sva_file
exec sed -i "s/localparam T_BCET_IN = .*/localparam T_BCET_IN = $T_BCET_EXE;/"  $sva_file
exec sed -i "s/localparam T_WCET_IN = .*/localparam T_WCET_IN = [expr {$T_WCET_EXE+1}];/"  $sva_file
after 1000; # wait for stability/read-in of the new values
#check -verbose -all [get_checks]; # run all assertions (generate loop of inputs)
check_assertion -force [get_assertions]

set te $T_WCET_EXE
set ts $T_BCET_EXE

# Open a file for writing the query results
set output_file [open "[file join $script_path "query_output.txt"]" w]
#puts $output_file "a b ts status"

#Read all assertions results
for {set i 0} {$i < $total_values} {incr i} {
    for {set j 0} {$j < $total_values} {incr j} {
        for {set t $ts} {$t <= $te} {incr t} {
            
            #set query [get_check_info -status {checker_bind.genblk1[${i}].genblk1[${j}].genblk1[${t}].wcet_in_p_a}]
            set query "checker_bind.genblk1\[$i\].genblk1\[$j\].genblk1\[$t\].wcet_in_p_a"
            set query_results [get_check_info -status $query]

            # Get actual values from the list
            set a_val [lindex $values $i]
            set b_val [lindex $values $j]
            
            # Print to console
            #puts "a=$a_val, b=$b_val, t=$t, $query_results"
            
            # Write to file only if status is "hold"
            if {[string match "hold" $query_results]} {
                puts $output_file "$a_val, $b_val, $t, $query_results"
                flush $output_file
            }
        }
    }
}


###############################
# Print Configuration Summary #
###############################

close $output_file
puts "Query results have been saved to [file join $script_path "query_output.txt"] (only 'hold' status values)"

puts "Selected granularity: $granularity test points"
puts "BCET is $T_BCET_EXE Cycles"
puts "WCET is $T_WCET_EXE Cycles"
puts "Values: $values"
# Print values in binary
foreach val $values {
    puts [format "%*b" $mpwid $val]
}

puts "\n===== Configuration Summary =====\n"
puts "Module name: $module_name"
puts "Number of inputs: $num_inputs"
puts "Input names:"
for {set i 0} {$i < $num_inputs} {incr i} {
    puts "  [expr {$i + 1}]. [lindex $input_names $i]"
}
puts "Output name: $output_name"



#Check only assertions, proof not witness: check_assertion -force [get_assertions]
#same for properties:check_property [get_properties]