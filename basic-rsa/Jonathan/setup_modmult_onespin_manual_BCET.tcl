# @lang=tcl @ts=8
set start_time [clock milliseconds]
######################################
# Manual Input / Output Declarations #
######################################

#Fill in the following variables with the real names of the module, inputs, outputs, and control signals from your design.


#Module Name - Inserts here the real name of the module like in your code
    set module_name "modmult"

#Set the name and maximum of width of the inputs
    set mpwid_name "MPWID"
    set mpwid 8        

#Data Input - Inserts here the real names of Data-Inputs like in your code
    set input_names [list "mpand" "modulus" "mplier"]
    set input_length [list "$mpwid_name-1" "$mpwid_name-1" "$mpwid_name-1"]; #number of inputs
    
#Data Output - Inserts here the real names of Data-Outputs like in your code
    set output_names [list "product"]
    set output_length [list "$mpwid_name-1"]; #number of outputs

#Handshake Signals - Inserts here the real names of Handshake Signals like in your code
    set read_in "ds" ; #start
    set ready_out "ready" ; #end/ready
    set interrupt_names [list ""]
    set filtered_interrupts [lsearch -inline -not -exact $interrupt_names ""]

#Clock and Reset - Inserts here the real names of Clock and Reset like in your code
    set clock_name "clk"
    set reset_name "reset"
    set reset_type 1 ; #active_low = 1 or active_high = 0



#Set Granularity - Inserts here the real value of the granularity max. width
    set granularity 3
    if { $granularity > $mpwid} {
        set granularity $mpwid
	}

#Set file options
    set file_type "vhd" ; #".sv" ".v" ".vlog" ".svlog" ".inc" ".vo" ".vm" ".vlib" ".vhd" ".vhdl"
    set file_name "modmult" ; #Inserts here the real name of the file like in your code
    set sva_file "property_checker_generated.sva"
    
#Set ready sequence
    #sequence ready_seq;
    #t ##0 (modmult.ds == 1'b1) and
    #t ##0 (modmult.ready == 1'b1) and
    #t ##1 (modmult.ds == 1'b0);
  #endsequence

    



###################################
# generate_wcet_signal_properties #
###################################

    proc generate_wcet_signal_properties {script_path output_file module_name input_names read_in ready_out clock_name reset_name mpwid_name mpwid filtered_interrupts granularity reset_type} {

    # Open file for writing
    set fd [open $script_path/$output_file w]
    
    puts $fd "// @lang=sva @ts=8test"
    puts $fd ""
    puts $fd "module property_checker"
    puts $fd "  // Adjust this parameter before elaboration with"
    puts $fd "  // set_elaborate_option -golden -vhdl_generic {$mpwid_name = 4}"
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

    if {[llength $filtered_interrupts] == 0} {
        if { $reset_type == 1} {
            set interrupt_condition "rst_i"
        } else {
            set interrupt_condition "!rst_i"
        }
    } else {
        if { $reset_type == 1} {
            set interrupt_condition "[join $filtered_interrupts " | "] | rst_i"
        } else {
            set interrupt_condition "[join $filtered_interrupts " | "] | !rst_i"
        }
            
    }
    puts $fd "  bcet_p_a: assert property (disable iff ($interrupt_condition) bcet_p );"

    #puts $fd " bcet_p_a: assert property (disable iff (rst_i) bcet_p);"
    puts $fd ""
    puts $fd "  property wcet_p;"
    puts $fd "    t ##0 ($module_name.$read_in    == 1'b1) and"
    puts $fd "    t ##0 ($module_name.$ready_out == 1'b1) and"
    puts $fd "    t ##1 ($module_name.$read_in    == 1'b0) \[*T_WCET+1\] and"
    puts $fd "    t ##1 ($module_name.$ready_out == 1'b0) \[*T_WCET\]"
    puts $fd "  implies    "
    puts $fd "    t ##(T_WCET+1) ($module_name.$ready_out == 1'b1);"
    puts $fd "  endproperty"

    if {[llength $filtered_interrupts] == 0} {
        if { $reset_type == 1} {
            set interrupt_condition "rst_i"
        } else {
            set interrupt_condition "!rst_i"
        }
    } else {
        if { $reset_type == 1} {
            set interrupt_condition "[join $filtered_interrupts " | "] | rst_i"
        } else {
            set interrupt_condition "[join $filtered_interrupts " | "] | !rst_i"
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
    puts $fd "  localparam int INPUT_A\[[expr {1 << $granularity}]\] = '{${input_a_values}};"


    puts $fd "  localparam T_WCET_IN = $mpwid;"
    puts $fd "  localparam T_BCET_IN = 1;"
    puts $fd ""
    puts $fd " genvar a,ts;"
    # Generate signal-specific properties
    foreach signal_name $input_names {
        puts $fd "  // Property for $module_name.$signal_name"
        puts $fd "  property ${signal_name}_p(a, ts);"
        puts $fd "    t ##0 ($module_name.$read_in == 1'b1) and"
        puts $fd "    t ##0 ($module_name.$ready_out == 1'b1) and"
	if { $granularity != 0} {
        puts $fd "    t ##0 ($module_name.$signal_name\[$mpwid_name-1:$mpwid_name-$granularity\] == INPUT_A\[a\]) and"
	}
        puts $fd "    t ##1 ($module_name.$read_in == 1'b0) \[*ts+1\]"
        puts $fd "  implies "
        puts $fd "    t ##(ts) ($module_name.$ready_out == 1'b0) and"
        puts $fd "    t ##(ts+1) ($module_name.$ready_out == 1'b1);"
        puts $fd "  endproperty"
        puts $fd ""
        puts $fd "  generate"
        puts $fd "      for (a = 0; a < \$size(INPUT_A); a++) begin: $signal_name"
        puts $fd "         for (ts = T_BCET_IN; ts < T_WCET_IN; ts++) begin: $signal_name"
        
        if {[llength $filtered_interrupts] == 0} {
            if { $reset_type == 1} {
                set interrupt_condition "rst_i"
            } else {
                set interrupt_condition "!rst_i"
            }
        } else {
            if { $reset_type == 1} {
                set interrupt_condition "[join $filtered_interrupts " | "] | rst_i"
            } else {
                set interrupt_condition "[join $filtered_interrupts " | "] | !rst_i"
            }
    }
        puts $fd "            ${signal_name}_p_a: assert property (disable iff ($interrupt_condition) ${signal_name}_p (a,ts));"
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


####################
# Generate Wrapper #
####################

# Generate SystemVerilog wrapper for modmult
proc generate_wrapper { script_path module_name input_names input_length output_names output_length read_in ready_out clock_name reset_name mpwid_name mpwid reset_type data_min data_max data_mean} { 
    set wrapper_file "$module_name\_wrapper.sv"
    set fp [open $script_path/$wrapper_file "w"]

    puts $fp "// Auto-generated SystemVerilog Wrapper for $module_name"
    puts $fp "`timescale 1ns/1ps\n"
    puts $fp "module ${module_name}_wrapper #\("
    puts $fp "    parameter int $mpwid_name = $mpwid"
    puts $fp "\) \("

    # Clock & Reset
    puts $fp "    input logic $clock_name,"
    puts $fp "    input logic $reset_name,"

    # Handshake
    puts $fp "    input logic $read_in,"
    puts $fp "    output logic $ready_out,"

    # Inputs
    foreach in $input_names len $input_length {
        puts $fp "    input logic \[$len:0\] $in,"
    }

    foreach in $input_names len $input_length {
        puts $fp "    input logic $in\_label,"
    }

    # Outputs
    set last_output_index [expr {[llength $output_names] - 1}]
    foreach out $output_names len $output_length {
        puts $fp "    output logic \[$len:0\] $out,"
    }

    set last_output_index [expr {[llength $output_names] - 1}]
    foreach out $output_names len $output_length {
        set suffix [expr {0 == $last_output_index ? "" : ","}]
        puts $fp "    output logic $out\_label $suffix"
    }

    puts $fp "\);\n"

    # Reset polarity handling
    set rst_cond ($reset_name)
    if { $reset_type == 1 } {
        set rst_cond "!$reset_name"
    }

    # Module instantiation
    puts $fp "  // Instantiate the DUT"
    puts $fp "  $module_name #\("
    puts $fp "    .$mpwid_name\($mpwid_name\)"
    puts $fp "  \) dut \("
    puts $fp "    .$clock_name\($clock_name\),"
    puts $fp "    .$reset_name\($reset_name\),"
    puts $fp "    .$read_in\($read_in\),"
    puts $fp "    .$ready_out\($ready_out\),"

    # Connect inputs
    foreach in $input_names {
        puts $fp "    .$in\($in\),"
    }

    # Connect outputs
    set last_output_index [expr {[llength $output_names] - 1}]
    foreach out $output_names  {
        set suffix [expr {0 == $last_output_index ? "" : ","}]
        puts $fp "    .$out\($out\)$suffix"
    }

    puts $fp "  \);\n"



    # End module
    puts $fp "endmodule"

    close $fp

    puts "Wrapper generated successfully in $wrapper_file"
}


#####################################################################################################################################
#####################################################################################################################################

##########
#  Setup #
##########

    source -signed "/import/usr/onespin/latest/etc/startup/onespin_startup.tcl.obf"
    restart

    set script_path [file dirname [file normalize [info script]]]
  
    if  {$file_type == "vhd" || $file_type == "vhdl"} {
            read_vhdl -golden -pragma_ignore {} -version 2008 $script_path/$file_name.$file_type
        } else {
            read_verilog -golden  -pragma_ignore {}  -version sv2012 $script_path/$file_name.$file_type
        }
    #read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult.vhd}
    set_elaborate_option -golden -vhdl_generic "$mpwid_name=$mpwid"

    elaborate -golden
    compile -golden
    set_mode mv

    generate_wcet_signal_properties $script_path "property_checker_generated.sva"  $module_name $input_names $read_in $ready_out $clock_name $reset_name $mpwid_name $mpwid $filtered_interrupts $granularity $reset_type

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
if {0} {
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
    }

set max_wcet [expr {$mpwid * 2}]  ;# Startwert: 2 * mpwid
set min_wcet 0
set t_wcet [expr {int(($min_wcet + $max_wcet))}]

while {$min_wcet <= $max_wcet} {
   
    exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/" $sva_file_path
    after 1000
    check -force [ list checker_bind.ops.wcet_p_a ]

    set status [get_check_info -status checker_bind.ops.wcet_p_a]

    if {[regexp {hold} $status]} {
        set T_WCET_EXE $t_wcet
        break
    } elseif {[regexp {fail} $status]} {
        set min_wcet $t_wcet
    } elseif {[regexp {vacuous} $status]} {
        set max_wcet $t_wcet
    }
     set t_wcet [expr {int(($min_wcet + $max_wcet) / 2)}]
}

##############################
# Loop BCET - Proof unvacous #
##############################
if {0} {
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
}

    # BCET Berechnung
set min_bcet 0  ;# Startwert für BCET
set max_bcet $mpwid
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



######################################
# Calc Inputs for Mplier and Modulus #
######################################

    # Calculate values for testing based on mpwid
    #set values {}

    # Add lowest value: 0 
    #lappend values 0

    # Add highest possible value based on mpwid: 2^mpwid - 1
    #lappend values [expr {(1 << $mpwid) - 1}]

    # Add values with MSB set at different positions
    #for {set i 0} {$i < $mpwid} {incr i} {
    #    lappend values [expr {1 << $i}]
    #}

    # Sort the list and remove duplicates
    #set values [lsort -unique -integer $values]

    # Get total number of generated values
    #set total_values [llength $values]



######################################################################
# Loop input dependend WCET - Proof transition from hold to not hold #
######################################################################

# Witness first pass is BCET
# Witness last pass is WCET

# Generate SVA-formatted parameter lists for INPUT_A and INPUT_B arrays
#set sva_values_list "'{"
#set first 1
#foreach val $values {
#    if {$first} {
#        set first 0
#    } else {
#        append sva_values_list ","
#    }
#    append sva_values_list "$val"
#}
#append sva_values_list "}"

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
array set data {}
set counter_input 0
set count_array 0
array set secure_data_input {}



foreach filename $input_names {
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
                set data_min($count_array,$a_val) $min_t_for_a
                set data_max($count_array,$a_val) $max_t_for_a
                set data_mean($count_array,$a_val) $mean_t_for_a
                puts "Input $filename = $count_array, Value $a_val_bin: Min t=$min_t_for_a, Max t=$max_t_for_a, Mean t=$mean_t_for_a"
            }
        }
        
        set secure_data_input($counter_input) 1
    } else {
        set secure_data_input($counter_input) 0
    }

    incr count_array
    incr counter_input

    puts $output_file
    close $output_file
}


##################################
# Generate SystemVerilog wrapper #
##################################


# Generate SystemVerilog wrapper for modmult

set wrapper_file "$module_name\_wrapper.sv"
set fp [open $script_path/$wrapper_file "w"]

puts $fp "// Auto-generated SystemVerilog Wrapper for $module_name"
puts $fp "`timescale 1ns/1ps\n"
puts $fp "module ${module_name}_wrapper #\("
puts $fp "    parameter int $mpwid_name = $mpwid"
puts $fp "\) \("

# Clock & Reset
puts $fp "    input  logic $clock_name,"
puts $fp "    input  logic $reset_name,"

# Handshake
puts $fp "    input  logic $read_in,"
puts $fp "    output logic $ready_out,"

# Inputs
foreach in $input_names len $input_length {
    puts $fp "    input  logic \[$len:0\] $in,"
}

foreach in $input_names len $input_length {
    puts $fp "    input  logic $in\_label,"
}

# Outputs
set last_output_index [expr {[llength $output_names] - 1}]
foreach out $output_names len $output_length {
    puts $fp "    output logic \[$len:0\] $out,"
}

set last_output_index [expr {[llength $output_names] - 1}]
foreach out $output_names len $output_length {
    set suffix [expr {0 == $last_output_index ? "" : ","}]
    puts $fp "    output logic $out\_label $suffix"
}

puts $fp "\);\n"

puts $fp "  // Internal signals"

foreach out $output_names len $output_length {
    puts $fp "  logic \[$len:0\] ${out}_internal,"
    puts $fp "  logic ${out}_label_internal;"
}

puts $fp "  logic \[$mpwid_name-1:0\] product_internal;"
puts $fp "  logic ready_internal;"
puts $fp "  logic running;"
puts $fp "  logic \[$mpwid_name-1:0\] timer = 0;\n"

# Reset polarity handling
set rst_cond ($reset_name)
if { $reset_type == 1 } {
    set rst_cond "!$reset_name"
}

# Module instantiation
puts $fp "  // Instantiate the DUT"
puts $fp "  $module_name #\("
puts $fp "    .$mpwid_name\($mpwid_name\)"
puts $fp "  \) dut \("
puts $fp "    .$clock_name\($clock_name\),"
puts $fp "    .$reset_name\($reset_name\),"
puts $fp "    .$read_in\(${read_in}_internal\),"
puts $fp "    .$ready_out\(${ready_out}_internal\),"

# Connect inputs
foreach in $input_names {
    puts $fp "    .$in\(${in}\),"
}

# Connect outputs
set last_output_index [expr {[llength $output_names] - 1}]
foreach out $output_names  {
    set suffix [expr {0 == $last_output_index ? "" : ","}]
    puts $fp "    .$out\($out\)$suffix"
}

puts $fp "  \);\n"

puts $fp "  always_ff @(posedge clk or posedge reset) begin"
puts $fp "    if ($rst_cond) begin"
puts $fp "      running <= 0;"
puts $fp "      $ready_out <= 0;"
# Outputs
foreach out $output_names len $output_length {
    puts $fp "      $out <= 0;"
}
foreach out $output_names len $output_length {
    puts $fp "      $out\_label <= 0;"
}
puts $fp "      timer = $T_WCET_EXE;"
puts $fp "    end else begin"
puts $fp "      if ($read_in && !running) begin"

puts $fp "        timer = 0;"

for {set i 0} {$i < [llength $input_names]} {incr i} {
    puts $fp "        t_array\[$i\] = 0;"
}

for {set i 0} {$i < [llength $input_names]} {incr i} {
    if { $secure_data_input($i) == 1} {
        foreach out $output_names  {
            puts $fp "        ${out}_label_internal <= 1;"
        }
        puts $fp "\n        // MUX for [lindex $input_names $i]"
        puts $fp "        case ([lindex $input_names $i]\[$mpwid_name-1:$mpwid_name-$granularity\])"
        for {set j 0} {$j < (1 << $granularity)} {incr j} {
            set a_val [lindex $input_values $j]
            set a_val_bin [format "%0${granularity}b" $a_val]
            puts $fp "          $granularity'b$a_val_bin: t_array\[$i\] = $data_max($i,$j);"
        }
        puts $fp "          default: t_array\[$i\] = $T_WCET_EXE;"
        puts $fp "        endcase\n"
    }
}


puts $fp "        for (int i = 0; i < [llength $input_names]; i++) begin"
puts $fp "          if (t_array\[i\] > timer)"
puts $fp "             timer = t_array\[i\];"
puts $fp "        end\n"

puts $fp "        running <= 1;"
puts $fp "        $ready_out <= 0;"
puts $fp "      end else if (running) begin"
puts $fp "        if (timer > 0) begin"
puts $fp "          timer = timer - 1;"
puts $fp "        end else begin"
puts $fp "          $ready_out <= ${ready_out}_internal;"
puts $fp "          running <= 0;"

foreach out $output_names  {
    puts $fp "          $out <= ${out}_internal;"    
    puts $fp "          ${out}_label <= ${out}_label_internal;"
}

puts $fp "        end"
puts $fp "      end else begin"
puts $fp "        $ready_out <= 0;"
puts $fp "      end"
puts $fp "    end"
puts $fp "  end\n"

puts $fp "endmodule"

close $fp

puts "Wrapper generated successfully in $wrapper_file"







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

set end_time [clock milliseconds]
set elapsed_ms [expr {$end_time - $start_time}]

set minutes [expr {$elapsed_ms / 60000}]
set seconds [expr {($elapsed_ms % 60000) / 1000}]

puts "Laufzeit: $minutes:$seconds"



# Example usage:
#generate_wcet_signal_properties "property_checker_generated.sva" $module_name $input_names
