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


###################################
# generate_wcet_signal_properties #
###################################

    proc generate_wcet_signal_properties {output_file module_name input_names } {

    # Open file for writing
    set fd [open $output_file w]
    
    puts $fd "// @lang=sva @ts=8"
    puts $fd ""
    puts $fd "module property_checker"
    puts $fd "  // Adjust this parameter before elaboration with"
    puts $fd "  // set_elaborate_option -golden -vhdl_generic {mpwid=4}"
    puts $fd "  #(parameter MPWID = 4)"
    puts $fd "  ("
    puts $fd "  input clk_i,"
    puts $fd "  input rst_i"
    puts $fd "  );"
    puts $fd ""
    puts $fd "  default clocking default_clk @(posedge clk_i); endclocking"
    puts $fd ""
    puts $fd "  \`include \"tidal.sv\""
    puts $fd ""
    puts $fd "\`begin_tda(ops)"
    puts $fd ""
    puts $fd "  localparam T_WCET = 5;"
    puts $fd "  localparam T_BCET = 1;"
    puts $fd ""
    puts $fd "  property bcet_p;"
    puts $fd "    t ##0 ($module_name.ds == 1'b1) and"
    puts $fd "    t ##0 ($module_name.ready == 1'b1) and"
    puts $fd "    t ##1 ($module_name.ds == 1'b0) \[*T_BCET+1\]"
    puts $fd "  implies"
    puts $fd "    t ##(T_BCET) ($module_name.ready == 1'b0);"
    puts $fd "  endproperty"
    puts $fd " bcet_p_a: assert property (disable iff (rst_i) bcet_p);"
    puts $fd ""
    puts $fd "  property wcet_p;"
    puts $fd "    t ##0 ($module_name.ds    == 1'b1) and"
    puts $fd "    t ##0 ($module_name.ready == 1'b1) and"
    puts $fd "    t ##1 ($module_name.ds    == 1'b0) \[*T_WCET+1\] and"
    puts $fd "    t ##1 ($module_name.ready == 1'b0) \[*T_WCET\]"
    puts $fd "  implies    "
    puts $fd "    t ##(T_WCET+1) ($module_name.ready == 1'b1);"
    puts $fd "  endproperty"
    puts $fd "  wcet_p_a: assert property (disable iff (rst_i) wcet_p);"
    puts $fd ""
    puts $fd "\`end_tda"
    puts $fd ""
    puts $fd ""
    puts $fd "  localparam WIDTH_IN = 6;"
    puts $fd "  localparam int INPUT_A\[WIDTH_IN\] = '{0,1,2,4,8,15};"
    puts $fd "  //localparam int INPUT_B\[WIDTH_IN\] = '{0,1,2,4,8,15};"
    puts $fd "  localparam T_WCET_IN = 6;"
    puts $fd "  localparam T_BCET_IN = 1;"
    puts $fd ""
    
    # Generate signal-specific properties
    foreach signal_name $input_names {
        puts $fd "  // Property for $module_name.$signal_name"
        puts $fd "  property wcet_in_${signal_name}_p(a, ts);"
        puts $fd "    t ##0 ($module_name.ds == 1'b1) and"
        puts $fd "    t ##0 ($module_name.ready == 1'b1) and"
        puts $fd "    t ##0 ($module_name.$signal_name == INPUT_A\[a\]) and"
        puts $fd "    t ##1 ($module_name.ds == 1'b0) \[*ts+1\] and"
        puts $fd "    t ##1 ($module_name.ready == 1'b0) \[*ts\]"
        puts $fd "  implies "
        puts $fd "    t ##(ts+1) ($module_name.ready == 1'b1);"
        puts $fd "  endproperty"
        puts $fd ""
        puts $fd " genvar a,ts;"
        puts $fd "  generate"
        puts $fd "      for (a = 0; a < \$size(INPUT_A); a++) begin"
        puts $fd "         for (ts = 1-T_BCET_IN; ts < T_WCET_IN; ts++) begin"
        puts $fd "            wcet_in_${signal_name}_p_a: assert property (disable iff (rst_i) wcet_in_${signal_name}_p (a,ts));"
        puts $fd "         end"
        puts $fd "      end"
        puts $fd "  endgenerate"
        puts $fd ""
    }
 
    
    # Close the module and TDA sections
    puts $fd "endmodule"
    puts $fd "bind $module_name property_checker #(.MPWID(MPWID)) checker_bind(.clk_i(clk), .rst_i(reset));"
    
    # Close the file
    close $fd
    puts "Generated SVA properties for signals: $input_names"
    puts "Output file: $output_file"
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

    edit_file $script_path/modmult.vhd
    edit_file $script_path/property_checker_generated.sva



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

############
# Read SVA #
############

    set_read_sva_option -loop_iter_threshold 1025
    generate_wcet_signal_properties "property_checker_generated.sva" $module_name $input_names
    set sva_file [file join $script_path "property_checker_generated.sva"]

    read_sva -version {sv2012} {$sva_file}

    set_check_option -local_processes 8

#######################################################################################################################
#######################################################################################################################


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



exec sed -i "s/localparam WIDTH_IN = .*/localparam WIDTH_IN = $total_values;/"  $sva_file
exec sed -i "s/localparam T_BCET_IN = .*/localparam T_BCET_IN = $T_BCET_EXE;/"  $sva_file
exec sed -i "s/localparam T_WCET_IN = .*/localparam T_WCET_IN = [expr {$T_WCET_EXE+1}];/"  $sva_file


foreach filename $input_names {
    set output_file [open "[file join $script_path "out_input_$filename.txt"]" w]



    
    # Update the SVA file with the generated values lists for INPUT_A and INPUT_B
    exec sed -i "s/localparam int\\\ INPUT_A\\\[WIDTH_IN\\\] = .*/localparam int\ INPUT_A\[WIDTH_IN\] = $sva_values_list;/" $sva_file
    #exec sed -i "s/localparam int\\\ INPUT_B\\\[WIDTH_IN\\\] = .*/localparam int\ INPUT_B\[WIDTH_IN\] = $sva_values_list;/" $sva_file
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
        for {set t $ts} {$t <= $te} {incr t} {
            
            #set query [get_check_info -status {checker_bind.genblk1[${i}].genblk1[${j}].genblk1[${t}].wcet_in_2_p_a}]
            set query "checker_bind.genblk1\[$i\].genblk1\[$t\].wcet_in_2_p_a"
            set query_results [get_check_info -status $query]

            # Get actual values from the list
            set a_val [lindex $values $i]

            # Write to file only if status is "hold"
            if {[string match "hold" $query_results]} {
                puts $output_file "$a_val, $b_val, $t, $query_results"
                flush $output_file
            }
        }
    }
    close $output_file
}


###############################
# Print Configuration Summary #
###############################


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

if {0} {
# Procedure to generate SVA properties for different signal names
proc generate_wcet_properties {signal_names output_file} {
    set fd [open $output_file w]
    
    # Write the SVA header
    puts $fd "// Auto-generated WCET properties"
    puts $fd "// Generated on [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fd ""
    
    # For each signal name, generate a specific property
    foreach signal_name $signal_names {
        puts $fd "property wcet_in_2_${signal_name}_p(a, ts);"
        puts $fd "    t ##0 (modmult.ds == 1'b1) and"
        puts $fd "    t ##0 (modmult.ready == 1'b1) and"
        puts $fd "    t ##0 (modmult.$signal_name == INPUT_A\[a\]) and"
        puts $fd "    t ##1 (modmult.ds == 1'b0) \[*ts+1\] and"
        puts $fd "    t ##1 (modmult.ready == 1'b0) \[*ts\]"
        puts $fd "  implies "
        puts $fd "    t ##(ts+1) (modmult.ready == 1'b1);"
        puts $fd "endproperty"
        puts $fd ""
        
        # Instance of the property
        puts $fd "// For modmult.$signal_name"
        puts $fd "wcet_in_2_${signal_name}_p(input_a, ts);"
        puts $fd ""
    }
    
    close $fd
    puts "Generated SVA properties for signals: $signal_names"
    puts "Output file: $output_file"
}

# Example usage:
# Define your signal names
set my_signals {mplier mpland modulus}

# Generate the SVA file
generate_wcet_properties $my_signals "generated_wcet_properties.sva"

# To use the generated file in your verification:
# source_sva generated_wcet_properties.sva
}
















# Example usage:
#generate_wcet_signal_properties "property_checker_generated.sva" $module_name $input_names
