###################################
# generate_wcet_signal_properties #
###################################
    set signal_var_list [list "a" "b" "c" "d" "e" "f" "g" "h"]

# Function to search for the timestamp based on signal name and value
    proc get_timestamp {sequence signal value} {
    set len [llength $sequence]
    for {set i 0} {$i < $len} {incr i 3} {
        set time [lindex $sequence $i]
        set sig [lindex $sequence [expr {$i+1}]]
        set val [lindex $sequence [expr {$i+2}]]
        
        # Check if the signal and value match
        if {$sig == $signal && $val == $value} {
            return $time
        }
    }
        return -1  # Return -1 if no match is found
    }

    # Define the procedure to extract the number before the colon
    proc extract_number_before_colon {input_string} {
        set colon_pos [string first ":" $input_string]
        if {$colon_pos != -1} {
            # Extract the part before the colon
            return [string range $input_string 0 [expr {$colon_pos - 1}]]
        } else {
            # If no colon is found, return the original string (or handle error)
            return $input_string
        }
    }



    

    set filtered_interrupts [lsearch -inline -not -exact $interrupt_names ""]

    # Generate the ready_sequence
    set seq ""
    # Iterate over the ready_sequence list
    for {set i 0} {$i < [llength $ready_sequence]} {incr i 3} {
        if {[expr {$i + 3}] < [llength $ready_sequence]} {
            # Append to the result variable with a newline
            append seq "    t ##[lindex $ready_sequence $i] \($module_name.[lindex $ready_sequence [expr {$i + 1}]] == 1'b[lindex $ready_sequence [expr {$i + 2}]]\) and\n"
        } else {
            # Append without a newline (to avoid extra line)
            append seq "    t ##[lindex $ready_sequence $i] \($module_name.[lindex $ready_sequence [expr {$i + 1}]] == 1'b[lindex $ready_sequence [expr {$i + 2}]]\)"
        }
    }

    # Open file for writing
    #set sva_file "property_checker_generated.sva"

    set fd [open $script_path/$sva_file\_long.sva w]
    
    puts $fd "// @lang=sva @ts=8test"
    puts $fd ""
    puts $fd "module property_checker"
    puts $fd "  #(parameter $width_name = $width )"
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
    puts $fd "  localparam T_WCET = [expr {$width*2}];"
    puts $fd "  localparam T_BCET = 0;"
    puts $fd ""

    puts $fd "  property bcet_p;"
    puts $fd "$seq \[*T_BCET+1\]"
    puts $fd "  implies"
    puts $fd "    t ##(T_BCET) ($module_name.$valid_out == 1'b0);"
    puts $fd "  endproperty"

    if {[llength $filtered_interrupts] == 0} {
        if { $reset_type == 1} {
            set interrupt_condition "rst_i"
        } else {
            set interrupt_condition "!rst_i"
        }
    } else {
        if { $reset_type == 1} {
            set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | rst_i"
        } else {
            set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | !rst_i"
        }
            
    }
    puts $fd "  bcet_p_a: assert property (disable iff ($interrupt_condition) bcet_p );"

    #puts $fd " bcet_p_a: assert property (disable iff (rst_i) bcet_p);"
    puts $fd ""
    puts $fd "  property wcet_p;"
    puts $fd "$seq \[*T_WCET+1\] and"
    puts $fd "    t ##1 ($module_name.$valid_out == 1'b0) \[*T_WCET\]"
    puts $fd "  implies    "
    puts $fd "    t ##(T_WCET+1) ($module_name.$valid_out == 1'b1);"
    puts $fd "  endproperty"

    if {[llength $filtered_interrupts] == 0} {
        if { $reset_type == 1} {
            set interrupt_condition "rst_i"
        } else {
            set interrupt_condition "!rst_i"
        }
    } else {
        if { $reset_type == 1} {
            set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | rst_i"
        } else {
            set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | !rst_i"
        }
    }
    puts $fd "  wcet_p_a: assert property (disable iff ($interrupt_condition) wcet_p );"



    #puts $fd "  wcet_p_a: assert property (disable iff (rst_i) wcet_p);"
    puts $fd ""
    puts $fd "\`end_tda"
    puts $fd ""
    puts $fd ""
    
    set input_list {}
    for {set i 0} {$i < (1 << $granularity)} {incr i} {
        lappend input_list $i  ;# Store decimal values instead of binary strings
    }
    # Format list as comma-separated values
    set input_a_values [join $input_list ", "]
    # Write to the file descriptor ($fd)
    puts $fd "  localparam int INPUT\[[expr {1 << $granularity}]\] = '{${input_a_values}};"


    puts $fd "  localparam T_WCET_IN = $width;"
    puts $fd "  localparam T_BCET_IN = 1;"
    puts $fd ""

    set sig_var_count 0
    puts -nonewline $fd " genvar "
    foreach signal_name $input_data_names {
        puts -nonewline $fd "[lindex $signal_var_list $sig_var_count],"
        set sig_var_count [expr {$sig_var_count + 1}] 
    }
    puts $fd "ts;"







      
    if { $input_operation_names != "" && $operation_flag == 1 } {
        set op_count 0
        foreach operation $input_operation_names {
                
        # get length of opertion
        set length_part [lindex $input_operation_length $op_count]
        # Call the procedure
        set number_before_colon [extract_number_before_colon $length_part]
        set op_num [expr {pow($number_before_colon + 1, 2)}]
        set op_root [expr {int(sqrt($op_num))}]
        set op_values {}
        for {set i 0} {$i < (1 << $op_root)} {incr i} {
            lappend op_values $i  ;# Store decimal values instead of binary strings
        }



        for {set i 0} {$i < $op_num} {incr i} {
            set a_val [lindex $op_values $i]
            set a_val_bin [format "%0${op_root}b" $a_val]

            foreach signal_name $input_data_names {
                puts $fd "  // Property for $module_name.$signal_name"
                puts $fd "  property $signal_name\_$i\_p(a, ts);"
                # puts $fd "    t ##$timestamp \($module_name.$operation\[[lindex $input_operation_length 0]\] == $i\) and"
                if { $granularity != 0} {
                    set timestamp [get_timestamp $ready_sequence "$valid_in" "1"]
                    puts $fd "    t ##$timestamp ($module_name.$signal_name\[$width_name-1:$width_name-$granularity\] == INPUT\[a\]) and"
                    puts $fd "    t ##$timestamp ($module_name.$operation\[[lindex $input_operation_length 0]\] == $op_root'b$a_val_bin) and"
                }
                puts $fd "$seq \[*ts+1\]"
                puts $fd "  implies "
                puts $fd "    t ##(ts) ($module_name.$valid_out == 1'b0) and"
                puts $fd "    t ##(ts+1) ($module_name.$valid_out == 1'b1);"
                puts $fd "  endproperty"
                puts $fd ""
                puts $fd "  generate"
                puts $fd "      for (a = 0; a < \$size(INPUT); a++) begin: $signal_name\_$i"
                puts $fd "         for (ts = T_BCET_IN; ts < T_WCET_IN; ts++) begin: $signal_name\_$i"
                
                if {[llength $filtered_interrupts] == 0} {
                    if { $reset_type == 1} {
                        set interrupt_condition "rst_i"
                    } else {
                        set interrupt_condition "!rst_i"
                    }
                } else {
                    if { $reset_type == 1} {
                        set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | rst_i"
                    } else {
                        set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | !rst_i"
                    }
                }
                puts $fd "            $signal_name\_$i\_p_a: assert property (disable iff ($interrupt_condition) $signal_name\_$i\_p (a,ts));"
                puts $fd "         end"
                puts $fd "      end"
                puts $fd "  endgenerate"
                puts $fd ""
                }
            }
        }
    } else {
        
        foreach signal_name $input_data_names {
            puts $fd "  // Property for $module_name.$signal_name"
            puts $fd "  property ${signal_name}_p(a, ts);"
            if { $granularity != 0} {
                set timestamp [get_timestamp $ready_sequence "$valid_in" "1"]
                puts $fd "    t ##$timestamp ($module_name.$signal_name\[$width_name-1:$width_name-$granularity\] == INPUT\[a\]) and"
            }
            puts $fd "$seq \[*ts+1\]"
            puts $fd "  implies "
            puts $fd "    t ##(ts) ($module_name.$valid_out == 1'b0) and"
            puts $fd "    t ##(ts+1) ($module_name.$valid_out == 1'b1);"
            puts $fd "  endproperty"
            puts $fd ""
            puts $fd "  generate"
            puts $fd "      for (a = 0; a < \$size(INPUT); a++) begin: $signal_name"
            puts $fd "         for (ts = T_BCET_IN; ts < T_WCET_IN; ts++) begin: $signal_name"
            
            if {[llength $filtered_interrupts] == 0} {
                if { $reset_type == 1} {
                    set interrupt_condition "rst_i"
                } else {
                    set interrupt_condition "!rst_i"
                }
            } else {
                if { $reset_type == 1} {
                    set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | rst_i"
                } else {
                    set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | !rst_i"
                }
            }
            puts $fd "            ${signal_name}_p_a: assert property (disable iff ($interrupt_condition) ${signal_name}_p (a,ts));"
            puts $fd "         end"
            puts $fd "      end"
            puts $fd "  endgenerate"
            puts $fd ""
        }
    }






###########TEST


    if { $input_operation_names != "" && $operation_flag == 1 } {
        set op_count 0
        foreach operation $input_operation_names {
                
        # get length of opertion
        set length_part [lindex $input_operation_length $op_count]
        # Call the procedure
        set number_before_colon [extract_number_before_colon $length_part]
        set op_num [expr {pow($number_before_colon + 1, 2)}]
        set op_root [expr {int(sqrt($op_num))}]
        set op_values {}
        for {set i 0} {$i < (1 << $op_root)} {incr i} {
            lappend op_values $i  ;# Store decimal values instead of binary strings
        }



        for {set i 0} {$i < $op_num} {incr i} {
            set a_val [lindex $op_values $i]
            set a_val_bin [format "%0${op_root}b" $a_val]

            foreach signal_name $input_data_names {
                puts $fd "  // Property for $module_name.$signal_name"
                puts $fd "  property $signal_name\_$i\_p(a, ts);"
                # puts $fd "    t ##$timestamp \($module_name.$operation\[[lindex $input_operation_length 0]\] == $i\) and"
                if { $granularity != 0} {
                    set timestamp [get_timestamp $ready_sequence "$valid_in" "1"]
                    puts $fd "    t ##$timestamp ($module_name.$signal_name\[$width_name-1:$width_name-$granularity\] == INPUT\[a\]) and"
                    puts $fd "    t ##$timestamp ($module_name.$operation\[[lindex $input_operation_length 0]\] == $op_root'b$a_val_bin) and"
                }
                puts $fd "$seq \[*ts+1\]"
                puts $fd "  implies "
                puts $fd "    t ##(ts) ($module_name.$valid_out == 1'b0) and"
                puts $fd "    t ##(ts+1) ($module_name.$valid_out == 1'b1);"
                puts $fd "  endproperty"
                puts $fd ""
                puts $fd "  generate"
                puts $fd "      for (a = 0; a < \$size(INPUT); a++) begin: $signal_name\_$i"
                puts $fd "         for (ts = T_BCET_IN; ts < T_WCET_IN; ts++) begin: $signal_name\_$i"
                
                if {[llength $filtered_interrupts] == 0} {
                    if { $reset_type == 1} {
                        set interrupt_condition "rst_i"
                    } else {
                        set interrupt_condition "!rst_i"
                    }
                } else {
                    if { $reset_type == 1} {
                        set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | rst_i"
                    } else {
                        set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | !rst_i"
                    }
                }
                puts $fd "            $signal_name\_$i\_p_a: assert property (disable iff ($interrupt_condition) $signal_name\_$i\_p (a,ts));"
                puts $fd "         end"
                puts $fd "      end"
                puts $fd "  endgenerate"
                puts $fd ""
                }
            }
        }
    } else {
            puts $fd "  // Property for $module_name\_all"
            set sig_var_count 0
            puts -nonewline $fd "  property $module_name\_all_p("
            foreach sig_var $input_data_names {
                puts -nonewline $fd "[lindex $signal_var_list $sig_var_count],"
                set sig_var_count [expr {$sig_var_count + 1}]    
            }
            puts $fd "ts);"
        
        set sig_var_count 0
        foreach signal_name $input_data_names {

            if { $granularity != 0} {
                set timestamp [get_timestamp $ready_sequence "$valid_in" "1"]
                puts $fd "    t ##$timestamp ($module_name.$signal_name\[$width_name-1:$width_name-$granularity\] == INPUT\[[lindex $signal_var_list $sig_var_count]\]) and"
                set sig_var_count [expr {$sig_var_count + 1}]    
            }
        }
            puts $fd "$seq \[*ts+1\]"
            puts $fd "  implies "
            puts $fd "    t ##(ts) ($module_name.$valid_out == 1'b0) and"
            puts $fd "    t ##(ts+1) ($module_name.$valid_out == 1'b1);"
            puts $fd "  endproperty"
            puts $fd ""
            puts $fd "  generate"

            set sig_var_count 0
        foreach signal_name $input_data_names {
            puts -nonewline $fd [string repeat " " $sig_var_count]
            puts $fd "    for ([lindex $signal_var_list $sig_var_count] = 0; [lindex $signal_var_list $sig_var_count] < \$size(INPUT); [lindex $signal_var_list $sig_var_count]++) begin: $module_name"
            set sig_var_count [expr {$sig_var_count + 1}] 
        }
        puts -nonewline $fd [string repeat " " $sig_var_count]
        puts $fd "    for (ts = T_BCET_IN; ts < T_WCET_IN; ts++) begin: $module_name"
        
        if {[llength $filtered_interrupts] == 0} {
            if { $reset_type == 1} {
                set interrupt_condition "rst_i"
            } else {
                set interrupt_condition "!rst_i"
            }
        } else {
            if { $reset_type == 1} {
                set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | rst_i"
            } else {
                set interrupt_condition "[join $module_name.$filtered_interrupts " | "] | !rst_i"
            }
        }

        puts -nonewline $fd [string repeat " " $sig_var_count]
        puts -nonewline $fd "      $module_name\_all_p_a: assert property (disable iff ($interrupt_condition) $module_name\_all_p ("
        set sig_var_count 0
        foreach signal_name $input_data_names {
            puts -nonewline $fd "[lindex $signal_var_list $sig_var_count],"
            set sig_var_count [expr {$sig_var_count + 1}] 
        }
        puts $fd "ts));"





        puts -nonewline $fd [string repeat " " $sig_var_count]
        puts $fd "    end"
        set sig_var_count 0
        foreach signal_name $input_data_names {
            set spaces_to_output [expr {max(0, [llength $input_data_names]  - $sig_var_count)}]
            puts -nonewline $fd [string repeat " " $spaces_to_output]
            puts $fd "   end"
            set sig_var_count [expr {$sig_var_count + 1}]
        }

            puts $fd "  endgenerate"
            puts $fd ""
        
    }




#############'TEST ENDE






    
    # Close the module and TDA sections
    puts $fd "endmodule"
    puts $fd "bind $module_name property_checker #(.$width_name\($width_name\)) checker_bind(.clk_i($clock_name), .rst_i($reset_name));"
    
    # Close the file
    close $fd
    puts "Generated SVA properties for signals: $input_data_names"
    puts "Output file: $sva_file"

    after 1000

    #generate_wcet_signal_properties $script_path "property_checker_generated.sva"  $module_name $input_data_names $read_in $ready_out $clock_name $reset_name $width_name $width $filtered_interrupts $granularity $reset_type $seq $input_operation_names $ready_sequence
