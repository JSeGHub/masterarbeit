# @lang=tcl @ts=8

######################################
# Manual Input / Output Declarations #
######################################

#Fill in the following variables with the real names of the module, inputs, outputs, and control signals from your design.
#If not needed, just comment the line with a `#`.

#Module Name - Inserts here the real name of the module like in your code
    set module_name "modmult"

#Data Input - Inserts here the real names of Data-Inputs like in your code
    set input_names [list "mpand" "mplier" "modulus"]
    
#Data Output - Inserts here the real names of Data-Outputs like in your code
    #set output_names [list "product"]

#Handshake Signals - Inserts here the real names of Handshake Signals like in your code
    set read_in "ds" ; #start
    set ready_out "ready" ; #end/ready
    #set interrupt_names [list "flush"]

#Clock and Reset - Inserts here the real names of Clock and Reset like in your code
    set clock_name "clk"
    set reset_name "reset"

#Set the name and maximum of width of the inputs
    set mpwid_name "MPWID"
    set mpwid 4    

#Set Granularity - Inserts here the real value of the granularity max. width
    set granularity 4
    if { $granularity > $mpwid } {
        set granularity $mpwid
    }

#Set file options
    set file_type "vhd" ; #".sv" ".v" ".vlog" ".svlog" ".inc" ".vo" ".vm" ".vlib" ".vhd" ".vhdl"
    set file_name "modmult" ; #Inserts here the real name of the file like in your code
    set sva_file "property_checker_generated.sva"
    

    



###################################
# generate_wcet_signal_properties #
###################################

    proc generate_wcet_signal_properties {script_path output_file module_name input_names read_in ready_out clock_name reset_name mpwid_name mpwid} {

    # Open file for writing
    set fd [open $script_path/$output_file w]
    
    puts $fd "// @lang=sva @ts=8test"
    puts $fd ""
    puts $fd "module property_checker"
    puts $fd "  // Adjust this parameter before elaboration with"
    puts $fd "  // set_elaborate_option -golden -vhdl_generic {mpwid=4}"
    puts $fd "  #(parameter $mpwid_name = 4)"
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
    puts $fd "  localparam T_WCET = [expr {$mpwid*2}];"
    puts $fd "  localparam T_BCET = 0;"
    puts $fd ""
    puts $fd "  property bcet_p;"
    puts $fd "    t ##0 ($module_name.$read_in == 1'b1) and"
    puts $fd "    t ##0 ($module_name.$ready_out == 1'b1) and"
    puts $fd "    t ##1 ($module_name.$read_in == 1'b0) \[*T_BCET+1\]"
    puts $fd "  implies"
    puts $fd "    t ##(T_BCET) ($module_name.$ready_out == 1'b0);"
    puts $fd "  endproperty"
    puts $fd " bcet_p_a: assert property (disable iff (rst_i) bcet_p);"
    puts $fd ""
    puts $fd "  property wcet_p;"
    puts $fd "    t ##0 ($module_name.$read_in    == 1'b1) and"
    puts $fd "    t ##0 ($module_name.$ready_out == 1'b1) and"
    puts $fd "    t ##1 ($module_name.$read_in    == 1'b0) \[*T_WCET+1\] and"
    puts $fd "    t ##1 ($module_name.$ready_out == 1'b0) \[*T_WCET\]"
    puts $fd "  implies    "
    puts $fd "    t ##(T_WCET+1) ($module_name.$ready_out == 1'b1);"
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
        puts $fd "    t ##0 ($module_name.$read_in == 1'b1) and"
        puts $fd "    t ##0 ($module_name.$ready_out == 1'b1) and"
        puts $fd "    t ##0 ($module_name.$signal_name == INPUT_A\[a\]) and"
        puts $fd "    t ##1 ($module_name.$read_in == 1'b0) \[*ts+1\] and"
        puts $fd "    t ##1 ($module_name.$ready_out == 1'b0) \[*ts\]"
        puts $fd "  implies "
        puts $fd "    t ##(ts+1) ($module_name.$ready_out == 1'b1);"
        puts $fd "  endproperty"
        puts $fd ""
        puts $fd " genvar a,ts;"
        puts $fd "  generate"
        puts $fd "      for (a = 0; a < \$size(INPUT_A); a++) begin: $signal_name"
        puts $fd "         for (ts = 1-T_BCET_IN; ts < T_WCET_IN; ts++) begin: $signal_name"
        puts $fd "            wcet_in_${signal_name}_p_a: assert property (disable iff (rst_i) wcet_in_${signal_name}_p (a,ts));"
        puts $fd "         end"
        puts $fd "      end"
        puts $fd "  endgenerate"
        puts $fd ""
    }
 
    
    # Close the module and TDA sections
    puts $fd "endmodule"
    puts $fd "bind $module_name property_checker #(.MPWID($mpwid_name)) checker_bind(.clk_i($clock_name), .rst_i($reset_name));"
    
    # Close the file
    close $fd
    puts "Generated SVA properties for signals: $input_names"
    puts "Output file: $output_file"

    after 1000
}


#####################################################################################################################################
#####################################################################################################################################

#####################
# Loop WCET - Setup #
#####################

    source -signed "/import/usr/onespin/latest/etc/startup/onespin_startup.tcl.obf"
    restart

    set script_path [file dirname [file normalize [info script]]]
  
    if  {$file_type == "vhd" || $file_type == "vhdl"} {
            read_vhdl -golden -pragma_ignore {} -version 2008 $script_path/$file_name.$file_type
        } else {
            read_verilog -golden  -pragma_ignore {}  -version sv2012 $script_path/$file_name.$file_type
        }
    read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult.vhd}
    set_elaborate_option -golden -vhdl_generic "$mpwid_name=$mpwid"

    elaborate -golden
    compile -golden
    set_mode mv

    generate_wcet_signal_properties $script_path "property_checker_generated.sva"  $module_name $input_names $read_in $ready_out $clock_name $reset_name $mpwid_name $mpwid

    edit_file $script_path/modmult.vhd
    edit_file $script_path/property_checker_generated.sva


############
# Read SVA #
############

    set_read_sva_option -loop_iter_threshold 1025
    set sva_file_path [file join $script_path $sva_file]
    read_sva -version {sv2012} $sva_file_path

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
        exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/" $sva_file_path
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
        exec sed -i "s/localparam T_BCET = .*/localparam T_BCET = $t_bcet;/" $sva_file_path
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



exec sed -i "s/localparam WIDTH_IN = .*/localparam WIDTH_IN = $total_values;/"  $sva_file_path
exec sed -i "s/localparam T_BCET_IN = .*/localparam T_BCET_IN = $T_BCET_EXE;/"  $sva_file_path
exec sed -i "s/localparam T_WCET_IN = .*/localparam T_WCET_IN = [expr {$T_WCET_EXE+1}];/"  $sva_file_path


foreach filename $input_names {
    set output_file [open "[file join $script_path "out_input_$filename.txt"]" w]



    
    # Update the SVA file with the generated values lists for INPUT_A and INPUT_B
    exec sed -i "s/localparam int\\\ INPUT_A\\\[WIDTH_IN\\\] = .*/localparam int\ INPUT_A\[WIDTH_IN\] = $sva_values_list;/" $sva_file_path
    #exec sed -i "s/localparam int\\\ INPUT_B\\\[WIDTH_IN\\\] = .*/localparam int\ INPUT_B\[WIDTH_IN\] = $sva_values_list;/" $sva_file_path
    after 1000; # wait for stability/read-in of the new values
    #check -verbose -all [get_checks]; # run all assertions (generate loop of inputs)
    check_assertion -force [get_assertions]

    set te $T_WCET_EXE
    set ts $T_BCET_EXE

    # Open a file for writing the query results
    #set output_file [open "[file join $script_path "query_output.txt"]" w]
    #puts $output_file "a b ts status"

    #Read all assertions results
    for {set i 0} {$i < $total_values} {incr i} {
        for {set t $ts} {$t <= $te} {incr t} {
            
            #set query [get_check_info -status {checker_bind.genblk1[${i}].genblk1[${j}].genblk1[${t}].wcet_in_2_p_a}]
            set query "checker_bind.$filename\[$i\].$filename\[$t\].wcet_in_$filename\_p_a"
            set query_results [get_check_info -status $query]

            # Get actual values from the list
            set a_val [lindex $values $i]

            # Write to file only if status is "hold"
            if {[string match "hold" $query_results]} {
                puts $output_file "$a_val, $t, $query_results"
                flush $output_file
            }
        }
    }
    puts $output_file
    close $output_file
    puts "Query results have been saved to [file join $script_path "query_output.txt"] (only 'hold' status values)"
}


###############################
# Print Configuration Summary #
###############################


puts "\n===== Configuration Summary =====\n"
puts "SVA file: $sva_file"
puts "Granularity: $granularity"
puts "Module name: $module_name"
puts "MPWID: $mpwid"
puts "Input names:$input_names"
puts "BCET is $T_BCET_EXE Cycles"
puts "WCET is $T_WCET_EXE Cycles"
puts "Values: $values"
# Print values in binary
foreach val $values {
    puts [format "%*b" $mpwid $val]
}




# Example usage:
#generate_wcet_signal_properties "property_checker_generated.sva" $module_name $input_names
