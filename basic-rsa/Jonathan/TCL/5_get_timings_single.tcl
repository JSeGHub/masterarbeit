#############
# Loop WCET #
#############


set max_wcet [expr {$width * 2}]  ;# Startwert: 2 * width
set min_wcet 0
set t_wcet [expr {int(($min_wcet + $max_wcet))}]

while {$min_wcet <= $max_wcet} {
    puts "T_WCET: $t_wcet, min_wcet: $min_wcet, max_wcet: $max_wcet"
   
    exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/" $sva_file_path
    after 1000
    check -force [ list checker_bind.ops.wcet_p_a ]

    set status [get_check_info -status checker_bind.ops.wcet_p_a]

    if {[regexp {hold} $status]} {
        set T_WCET_EXE $t_wcet
        break
    } elseif {[regexp {fail} $status]} {
        set min_wcet $t_wcet
        puts "FAIL"
    } elseif {[regexp {vacuous} $status]} {
        set max_wcet $t_wcet
        puts "VACUOUS"
    }
     set t_wcet [expr {int(($min_wcet + $max_wcet) / 2)}]
     puts "t_wcet: $t_wcet"
}



#############
# Loop BCET #
#############

    # BCET Berechnung
set min_bcet 0  ;# Startwert für BCET
set max_bcet $width
set t_bcet [expr {int(($min_bcet + $max_bcet))}]

while {$min_bcet <= $max_bcet} {
    exec sed -i "s/localparam T_BCET = .*/localparam T_BCET = $t_bcet;/" $sva_file_path
    after 1000
    check -force [ list checker_bind.ops.bcet_p_a ]

    set status [get_check_info -status checker_bind.ops.bcet_p_a]

    if {[regexp {hold} $status]} {
        set T_BCET_EXE $t_bcet
        break
    } elseif {[regexp {fail} $status]} {
        set max_bcet $t_bcet
    } elseif {[regexp {vacuous} $status]} {
        set min_bcet $t_bcet
    }
    set t_bcet [expr {int(($min_bcet + $max_bcet) / 2)}]
}



#############################
# Loop input dependend WCET #
#############################

set input_values {}
for {set i 0} {$i < (1 << $granularity)} {incr i} {
    lappend input_values $i  ;# Store decimal values instead of binary strings
}


#exec sed -i "s/localparam WIDTH_IN = .*/localparam WIDTH_IN = $total_values;/"  $sva_file_path
exec sed -i "s/localparam T_BCET_IN = .*/localparam T_BCET_IN = $T_BCET_EXE;/"  $sva_file_path
exec sed -i "s/localparam T_WCET_IN = .*/localparam T_WCET_IN = [expr {$T_WCET_EXE+1}];/"  $sva_file_path

after 1000
check  -all -force [get_checks]
#check_assertion -force [get_assertions]

set te $T_WCET_EXE
set ts $T_BCET_EXE



if { $opti_type == "esp" || $opti_type == "all" } {

    array set data {}
    set counter_input 0
    set count_array 0
    array set secure_data_input {}


    if { $input_operation_names != "" && $operation_flag == 1 } {
        set op_count 0
        foreach operation $input_operation_names {
            # get length of opertion
            set length_part [lindex $input_operation_length $op_count]
            # Call the procedure
            set number_before_colon [extract_number_before_colon $length_part]
            set op_num [expr {pow($number_before_colon + 1, 2)}]

            for {set i 0} {$i < $op_num} {incr i} {

                set counter_input 0
                foreach filename $input_data_names {
                    set output_file [open "[file join $script_path "out_input_$filename\_$i.txt"]" w]
                    set reachability 0
                    #Read all assertions results
                    for {set j 0} {$j < [expr {1 << $granularity}]} {incr j} {
                        for {set t $ts} {$t <= $te} {incr t} {
                                
                            set query "checker_bind.$filename\_$i\[$j\].$filename\_$i\[$t\].$filename\_$i\_p_a"
                            set query_results [get_check_info -status -witness $query]

                            #set query_results [get_check_info -status $query]

                            # Get actual values from the list
                            set a_val [lindex $input_values $j]

                            # Write to file only if status is "hold"
                            
                            if {[regexp {pass} $query_results]} {
                                #puts $output_file "$a_val, $t, $query_results"
                                puts $output_file "$a_val, $t"
                                flush $output_file
                                set data($counter_input,$a_val,$t,$i) 1;#pass
                            } else {
                                set data($counter_input,$a_val,$t,$i) 0; #unreachable
                            }
                            
                            if {[regexp {unreachable} $query_results] && $reachability == 0} {
                                set reachability 1
                            }
                        }
                    }

                    if {$reachability == 1} {

                        # Process results for this input
                        puts "Processing results for $filename\_$i"
                        set smallest_t [expr {$te + 1}] ;# Initialize to max possible value
                        set highest_t 0
                        set sum_t 0
                        set count_t 0

                        array set data_min {}
                        array set data_max {}
                        array set data_mean {}


                        # Collect data for all combinations of a_val and t
                        for {set a_val 0} {$a_val < [expr {1 << $granularity}]} {incr a_val} {
                            set min_t_for_a [expr {$te + 1}]
                            set max_t_for_a 0
                            set sum_t_for_a 0
                            set count_t_for_a 0
                            
                            for {set t $ts} {$t <= $te} {incr t} {
                                if {[info exists data($counter_input,$a_val,$t,$i)] && $data($counter_input,$a_val,$t,$i) == 1} {
                                    if {$t < $min_t_for_a} {set min_t_for_a $t}
                                    if {$t > $max_t_for_a} {set max_t_for_a $t}
                                    set sum_t_for_a [expr {$sum_t_for_a + $t}]
                                    incr count_t_for_a
                                }
                            }
                            
                            # Output statistics for this a_val if we have any data
                            if {$count_t_for_a > 0} {
                                set mean_t_for_a [expr {double($sum_t_for_a) / $count_t_for_a}]
                                set a_val_bin [format "%03b" $a_val]
                                set data_min($counter_input,$a_val,$i) $min_t_for_a
                                set data_max($counter_input,$a_val,$i) $max_t_for_a
                                set data_mean($counter_input,$a_val,$i) $mean_t_for_a
                                puts "$counter_input: Input $filename, Value $a_val_bin: Min t=$min_t_for_a, Max t=$max_t_for_a, Mean t=$mean_t_for_a"
                            }
                        }
                        
                        set secure_data_input($counter_input,$i) 1
                    } else {
                        set secure_data_input($counter_input,$i) 0
                    }

                    incr count_array
                    incr counter_input

                    puts $output_file
                    close $output_file
                }
            }
            incr op_count
        }

    } else {

        foreach filename $input_data_names {
            set output_file [open "[file join $script_path "out_input_$filename.txt"]" w]
            set reachability 0
            #Read all assertions results
            for {set i 0} {$i < [expr {1 << $granularity}]} {incr i} {
                for {set t $ts} {$t <= $te} {incr t} {
                        
                    set query "checker_bind.$filename\[$i\].$filename\[$t\].$filename\_p_a"
                    set query_results [get_check_info -status -witness $query]

                    #set query_results [get_check_info -status $query]

                    # Get actual values from the list
                    set a_val [lindex $input_values $i]

                    # Write to file only if status is "hold"
                    
                    if {[regexp {pass} $query_results]} {
                        #puts $output_file "$a_val, $t, $query_results"
                        puts $output_file "$a_val, $t"
                        flush $output_file
                        set data($counter_input,$a_val,$t) 1;#pass
                    } else {
                        set data($counter_input,$a_val,$t) 0; #unreachable
                    }
                    
                    if {[regexp {unreachable} $query_results] && $reachability == 0} {
                        set reachability 1
                    }
                }
            }

            if {$reachability == 1} {

                # Process results for this input
                puts "Processing results for $filename"
                set smallest_t [expr {$te + 1}] ;# Initialize to max possible value
                set highest_t 0
                set sum_t 0
                set count_t 0

                array set data_min {}
                array set data_max {}
                array set data_mean {}


                # Collect data for all combinations of a_val and t
                for {set a_val 0} {$a_val < [expr {1 << $granularity}]} {incr a_val} {
                    set min_t_for_a [expr {$te + 1}]
                    set max_t_for_a 0
                    set sum_t_for_a 0
                    set count_t_for_a 0
                    
                    for {set t $ts} {$t <= $te} {incr t} {
                        if {[info exists data($counter_input,$a_val,$t)] && $data($counter_input,$a_val,$t) == 1} {
                            if {$t < $min_t_for_a} {set min_t_for_a $t}
                            if {$t > $max_t_for_a} {set max_t_for_a $t}
                            set sum_t_for_a [expr {$sum_t_for_a + $t}]
                            incr count_t_for_a
                        }
                    }
                    
                    # Output statistics for this a_val if we have any data
                    if {$count_t_for_a > 0} {
                        set mean_t_for_a [expr {double($sum_t_for_a) / $count_t_for_a}]
                        set a_val_bin [format "%03b" $a_val]
                        set data_min($count_array,$a_val,0) $min_t_for_a
                        set data_max($count_array,$a_val,0) $max_t_for_a
                        set data_mean($count_array,$a_val,0) $mean_t_for_a
                        puts "$count_array: Input $filename, Value $a_val_bin: Min t=$min_t_for_a, Max t=$max_t_for_a, Mean t=$mean_t_for_a"
                    }
                }
                
                set secure_data_input($counter_input,0) 1
            } else {
                set secure_data_input($counter_input,0) 0
            }

            puts "$filename: secure $secure_data_input($counter_input,0) with counter: $counter_input"

            incr count_array
            incr counter_input

            puts $output_file
            close $output_file
        }
    }
}

############## TEST LZP ############




if { $opti_type == "lzp" || $opti_type == "all" } {
    set input_values_zero {}
    for {set i 0} {$i < (1 << $granularity)} {incr i} {
        lappend input_values_zero $i  ;# Store decimal values instead of binary strings
    }

    array set data_zero {}
    set counter_input_zero 0
    set count_array_zero 0
    array set secure_data_input_zero {}


    if { $input_operation_names != "" && $operation_flag == 1 } {
        set op_count 0
        foreach operation $input_operation_names {
            # get length of opertion
            set length_part [lindex $input_operation_length $op_count]
            # Call the procedure
            set number_before_colon [extract_number_before_colon $length_part]
            set op_num [expr {pow($number_before_colon + 1, 2)}]

            for {set i 0} {$i < $op_num} {incr i} {

                set counter_input 0
                foreach filename $input_data_names {
                    set output_file [open "[file join $script_path "out_input_$filename\_$i\_zero.txt"]" w]
                    set reachability 0
                    #Read all assertions results
                    for {set j 0} {$j < [expr {1 << $granularity}]} {incr j} {
                        for {set t $ts} {$t <= $te} {incr t} {
                                
                            set query "checker_bind.$filename\_$i\[$j\].$filename\_$i\[$t\].$filename\_$i\_p_a"
                            set query_results [get_check_info -status -witness $query]

                            #set query_results [get_check_info -status $query]

                            # Get actual values from the list
                            set a_val [lindex $input_values_zero $j]

                            # Write to file only if status is "hold"
                            
                            if {[regexp {pass} $query_results]} {
                                #puts $output_file "$a_val, $t, $query_results"
                                puts $output_file "$a_val, $t"
                                flush $output_file
                                set data($counter_input,$a_val,$t,$i) 1;#pass
                            } else {
                                set data($counter_input,$a_val,$t,$i) 0; #unreachable
                            }
                            
                            if {[regexp {unreachable} $query_results] && $reachability == 0} {
                                set reachability 1
                            }
                        }
                    }

                    if {$reachability == 1} {

                        # Process results for this input
                        puts "Processing results for $filename\_$i"
                        set smallest_t [expr {$te + 1}] ;# Initialize to max possible value
                        set highest_t 0
                        set sum_t 0
                        set count_t 0

                        array set data_min {}
                        array set data_max {}
                        array set data_mean {}


                        # Collect data for all combinations of a_val and t
                        for {set a_val 0} {$a_val < [expr {1 << $granularity}]} {incr a_val} {
                            set min_t_for_a [expr {$te + 1}]
                            set max_t_for_a 0
                            set sum_t_for_a 0
                            set count_t_for_a 0
                            
                            for {set t $ts} {$t <= $te} {incr t} {
                                if {[info exists data($counter_input,$a_val,$t,$i)] && $data($counter_input,$a_val,$t,$i) == 1} {
                                    if {$t < $min_t_for_a} {set min_t_for_a $t}
                                    if {$t > $max_t_for_a} {set max_t_for_a $t}
                                    set sum_t_for_a [expr {$sum_t_for_a + $t}]
                                    incr count_t_for_a
                                }
                            }
                            
                            # Output statistics for this a_val if we have any data
                            if {$count_t_for_a > 0} {
                                set mean_t_for_a [expr {double($sum_t_for_a) / $count_t_for_a}]
                                set a_val_bin [format "%03b" $a_val]
                                set data_min($counter_input,$a_val,$i) $min_t_for_a
                                set data_max($counter_input,$a_val,$i) $max_t_for_a
                                set data_mean($counter_input,$a_val,$i) $mean_t_for_a
                                puts "$counter_input: Input $filename, Value $a_val_bin: Min t=$min_t_for_a, Max t=$max_t_for_a, Mean t=$mean_t_for_a"
                            }
                        }
                        
                        set secure_data_input($counter_input,$i) 1
                    } else {
                        set secure_data_input($counter_input,$i) 0
                    }

                    incr count_array
                    incr counter_input

                    puts $output_file
                    close $output_file
                }
            }
            incr op_count
        }

    } else {
        foreach filename $input_data_names {
            set output_file [open "[file join $script_path "out_input_$filename\_zero.txt"]" w]
            set reachability 0
            #Read all assertions results
            for {set i 0} {$i < [expr {1 << $granularity}]} {incr i} {
                for {set t $ts} {$t <= $te} {incr t} {
                        
                    set query "checker_bind.$filename\_$i\_zero\[$t\].$filename\_$i\_zero\_p_a"
                    set query_results [get_check_info -status -witness $query]

                    #set query_results [get_check_info -status $query]

                    # Get actual values from the list
                    set a_val_zero [lindex $input_values_zero $i]

                    # Write to file only if status is "hold"
                    
                    if {[regexp {pass} $query_results]} {
                        #puts $output_file "$a_val, $t, $query_results"
                        puts $output_file "$a_val_zero, $t"
                        flush $output_file
                        set data_zero($counter_input_zero,$a_val_zero,$t) 1;#pass
                    } else {
                        set data_zero($counter_input_zero,$a_val_zero,$t) 0; #unreachable
                    }
                    
                    if {[regexp {unreachable} $query_results] && $reachability == 0} {
                        set reachability 1
                    }
                }
            }

            if {$reachability == 1} {

                # Process results for this input
                puts "Processing results for $filename"
                set smallest_t_zero [expr {$te + 1}] ;# Initialize to max possible value
                set highest_t_zero 0
                set sum_t_zero 0
                set count_t_zero 0

                array set data_min_zero {}
                array set data_max_zero {}
                array set data_mean_zero {}


                # Collect data for all combinations of a_val and t
                for {set a_val_zero 0} {$a_val_zero < [expr {1 << $granularity}]} {incr a_val_zero} {
                    set min_t_for_a_zero [expr {$te + 1}]
                    set max_t_for_a_zero 0
                    set sum_t_for_a_zero 0
                    set count_t_for_a_zero 0
                    
                    for {set t $ts} {$t <= $te} {incr t} {
                        if {[info exists data($counter_input_zero,$a_val_zero,$t)] && $data_zero($counter_input_zero,$a_val_zero,$t) == 1} {
                            if {$t < $min_t_for_a_zero} {set min_t_for_a_zero $t}
                            if {$t > $max_t_for_a_zero} {set max_t_for_a_zero $t}
                            set sum_t_for_a_zero [expr {$sum_t_for_a_zero + $t}]
                            incr count_t_for_a_zero
                        }
                    }
                    
                    # Output statistics for this a_val if we have any data
                    if {$count_t_for_a_zero > 0} {
                        set mean_t_for_a_zero [expr {double($sum_t_for_a_zero) / $count_t_for_a_zero}]
                        set a_val_bin_zero [format "%03b" $a_val_zero]
                        set data_min_zero($count_array_zero,$a_val_zero,0) $min_t_for_a_zero
                        set data_max_zero($count_array_zero,$a_val_zero,0) $max_t_for_a_zero
                        set data_mean_zero($count_array_zero,$a_val_zero,0) $mean_t_for_a_zero
                        puts "$count_array_zero: Input $filename, Value $a_val_bin_zero: Min t=$min_t_for_a_zero, Max t=$max_t_for_a_zero, Mean t=$mean_t_for_a_zero"
                    }
                }
                
                set secure_data_input_zero($counter_input_zero,0) 1
            } else {
                set secure_data_input_zero($counter_input_zero,0) 0
            }

            puts "$filename: secure $secure_data_input_zero($counter_input_zero,0) with counter: $counter_input_zero"

            incr count_array_zero
            incr counter_input_zero

            puts $output_file
            close $output_file
        }
    }
}




########### END TEST LZP