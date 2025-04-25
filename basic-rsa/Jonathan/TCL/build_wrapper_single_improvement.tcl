##################################
# Generate SystemVerilog wrapper #
##################################

#####################
# Set Module Config #
#####################

set wrapper_file "$module_name\_wrapper.sv"
set fp [open $script_path/$wrapper_file "w"]

puts $fp "// Auto-generated SystemVerilog Wrapper for $module_name"
puts $fp "`timescale 1ns/1ps\n"
if { $import_name != "" } {
    puts $fp "module ${module_name}_wrapper import $import_name #\("
} else {
    puts $fp "module ${module_name}_wrapper #\("
}
puts -nonewline $fp "    parameter int $width_name = $width"

# Parameters
set param_count 0
if {$param_names != ""} {
        foreach in_param $param_names {
        puts -nonewline $fp ",\n    parameter int $in_param = [lindex $param_values $param_count]"
        incr param_count
    }
}
puts $fp ""
puts $fp "\) \("

# Clock & Reset
puts $fp "    input  logic $clock_name,"
puts $fp "    input  logic $reset_name,"

# Interrupts
foreach in_int $interrupt_names {
    if {$in_int != ""} {
        puts $fp "    input  logic $in_int,"
    }
}

puts $fp ""

# Handshake
if {$valid_in != ""} {
    puts $fp "    input  logic $valid_in,"
}
if {$valid_out != ""} {
    puts $fp "    output logic $valid_out,"
}
if {$ready_in != ""} {
    puts $fp "    input  logic $ready_in,"
}
if {$ready_out != ""} {
    puts $fp "    output logic $ready_out,"
}
puts $fp ""



# Data-Inputs
foreach in_data $input_data_names len $input_data_length {
    if { $len == "" } {
        puts $fp "    input  logic $in_data,"
    } else {
    puts $fp "    input  logic \[$len\] $in_data,"
    }
}

foreach in_data $input_data_names {
    puts $fp "    input  logic $in_data\_label,"
}


puts $fp ""

# Operation
foreach in_op $input_operation_names len_op $input_operation_length {
    if { $in_op != "" } {
        if { $len_op == "" } {
            puts $fp "    input  logic $in_op,"
        } else {
            puts $fp "    input  logic \[$len_op\] $in_op,"
        }
    }
}


# Data-ID 
foreach in_id $input_data_id_names len $input_data_id_length {
    if { $len == "" } {
        puts $fp "    input  logic $in_id,"
    } else {
        puts $fp "    input  logic \[$len\] $in_id,"
    }
} 


#Output ID
foreach out $output_id_names len $output_id_length {
    if { $len == "" } {
        puts $fp "    output logic $out,"
    } else {
        puts $fp "    output logic \[$len\] $out,"
    }
}

# Output Data
foreach out $output_data_names len $output_data_length {
    if { $len == "" } {
        puts $fp "    output logic $out,"
    } else {
    puts $fp "    output logic \[$len\] $out,"
    }
}

set last_output_index [expr {[llength $output_data_names] - 1}]
foreach out $output_data_names len $output_data_length {
    set suffix [expr {0 == $last_output_index ? "" : ","}]
    puts $fp "    output logic $out\_label $suffix"
}

puts $fp "\);\n"



####################
# FSM - Typedef #
####################

puts $fp "  // FSM - Typedef"
puts $fp "  typedef enum logic \[1:0\] {"
puts $fp "    IDLE, RUN, DONE"
puts $fp "  } state_t;"
puts $fp "  state_t state_q, state_d;\n"



####################
# Internal signals #
####################

puts $fp "  // Internal signals"

foreach out $output_data_names len $output_data_length {
    puts $fp "  logic \[$len\] ${out}_q, ${out}_d;"
}

foreach out $output_data_names {
    puts $fp "  logic ${out}\_label\_q, ${out}\_label\_d;"
}

puts $fp ""

# Handshake
if {$valid_in != ""} {
    puts $fp "  logic ${valid_in}_q, ${valid_in}_d;"

}
if {$ready_in != ""} {
    puts $fp "  logic ${ready_in}_q, ${ready_in}_d;"
}
if {$valid_out != ""} {
    puts $fp "  logic ${valid_out}_q, ${valid_out}_d;"
}
if {$ready_out != ""} {
    puts $fp "  logic ${ready_out}_q, ${ready_out}_d;"
}

puts $fp ""
puts $fp "  logic \[$width_name-1:0\] timer_q, timer_d;\n"

puts $fp " "
puts $fp "  // Timing array"
puts $fp "  logic \[$width_name-1:0\] t_array \[[llength $input_data_names]\];"
puts $fp " \n"




###########################
# Reset polarity handling #
###########################

set rst_cond $reset_name
if { $reset_type == 0 } {
    set rst_cond "!$reset_name"
}



########################
# DUT instantiation #
########################

puts $fp "  // Instantiate the DUT"
puts $fp "  $module_name #\("
puts -nonewline $fp "    .$width_name\($width_name\)"

# Parameters
if {$param_names != ""} {
        foreach in_param $param_names {
        puts -nonewline $fp ",\n    .$in_param\($in_param\)"
    }
} else {
    puts $fp ""
}

puts $fp ""
puts $fp "  \) dut \("
puts $fp "    .$clock_name\($clock_name\),"
puts $fp "    .$reset_name\($reset_name\),"

# Interrupts
foreach in_int $interrupt_names {
    if {$in_int != ""} {
        puts $fp "    .$in_int\($in_int\),"
    }
}

#Connect handshake

if {$valid_in != ""} {
    puts $fp "    .$valid_in\($valid_in\_q\),"
}
if {$valid_out != ""} {
    puts $fp "    .$valid_out\($valid_out\_q\),"
}
if {$ready_in != ""} {
    puts $fp "    .$ready_in\($ready_in\_q\),"
}
if {$ready_out != ""} {
    puts $fp "    .$ready_out\($ready_out\_q\),"
}




# Connect operation
foreach in $input_operation_names {
    puts $fp "    .$in\($in\),"
}


# Connect data ID
foreach in $input_data_id_names {
    puts $fp "    .$in\($in\),"
}

# Connect data inputs
foreach in $input_data_names {
    puts $fp "    .$in\($in\),"
}

#foreach in $input_data_names {
#    puts $fp "    .$in\_label\($in\_label\),"
#}


# Output ID
foreach out $output_id_names {
    puts $fp "    .$out\($out\),"
}

# Output Data
set last_output_index [expr {[llength $output_data_names] - 1}]
foreach out $output_data_names {
    set suffix [expr {0 == $last_output_index ? "" : ","}]
    puts $fp "    .$out\($out\_q\) $suffix"
}

#set last_output_index [expr {[llength $output_data_names] - 1}]
#foreach out $output_data_names {
#    set suffix [expr {0 == $last_output_index ? "" : ","}]
#    puts $fp "    .$out\_label\($out\_label\_q\) $suffix"
#}



puts $fp "  \);\n"
puts $fp "  \n"



########################
# Combinatorial Timing #
########################
puts $fp "  // Combinatorial logic - Timing behavior"
puts $fp " "
puts $fp "  always_comb begin"
#puts $fp "    // Default values"


#if { $input_operation_names != "" && $operation_flag == 1 } {
#    set op_count 0
#    foreach operation $input_operation_names {
#        # get length of opertion
#        set length_part [lindex $input_operation_length $op_count]
#        # Call the procedure
#        set number_before_colon [extract_number_before_colon $length_part]
#        puts $number_before_colon
#        set op_num [expr {int(pow($number_before_colon + 1, 2))}]
#        for {set l 0} {$l < $op_num} {incr l} {

#            for {set i 0} {$i < [llength $input_data_names]} {incr i} {
#                if {$secure_data_input($i,$l) == 1} {
#                    puts $fp "    t_array\[$i\]\[$l\] = $T_WCET_EXE;"
#                } else {
#                    puts $fp "    t_array\[$i\]\[$l\] = 0;"
#                }
#            }
#        }
#    }
#} else {
#    for {set i 0} {$i < [llength $input_data_names]} {incr i} {
#        if {$secure_data_input($i,0) == 1} {
#            puts $fp "    t_array\[$i\] = $T_WCET_EXE;"
#        } else {
#            puts $fp "    t_array\[$i\] = 0;"
#        }
#    }
#}




puts $fp ""
puts $fp "    // Timing decision based on MSB\n"




if { $input_operation_names != "" && $operation_flag == 1 } {
    set op_count 0
    foreach operation $input_operation_names {
        # get length of opertion
        set length_part [lindex $input_operation_length $op_count]
        # Call the procedure
        set number_before_colon [extract_number_before_colon $length_part]
        set op_num [expr {int(pow($number_before_colon + 1, 2))}]
        set op_root [expr {int(sqrt($op_num))}]

        set op_values {}
        for {set i 0} {$i < (1 << $op_num)} {incr i} {
            lappend op_values $i  ;# Store decimal values instead of binary strings
        }
        puts $fp "    case ($operation\[$input_operation_length\])\n"
        for {set l 0} {$l < $op_num} {incr l} {
            set a_val [lindex $op_values $l]
            set a_val_bin [format "%0${op_root}b" $a_val]
            puts $fp "      $op_root'b$a_val_bin: begin"
        
            for {set i 0} {$i < [llength $input_data_names]} {incr i} {
                if { $secure_data_input($i,$l) == 1} {
                    puts $fp "            if ([lindex $input_data_names $i]\_label == 0) begin"
                    puts $fp "              case ([lindex $input_data_names $i]\[$width_name-1:$width_name-$granularity\])"
                    for {set j 0} {$j < (1 << $granularity)} {incr j} {
                        set a_val [lindex $input_values $j]
                        set a_val_bin [format "%0${granularity}b" $a_val]
                        puts $fp "                    $granularity'b$a_val_bin: t_array\[$i\] = $data_max($i,$j,$l);"
                    }
                    puts $fp "                default: t_array\[$i\] = $T_WCET_EXE;"
                    puts $fp "              endcase"
                    puts $fp "            end else t_array\[$i\] = 0;\n"
                } else {
                    puts $fp "            case ([lindex $input_data_names $i]\[$width_name-1:$width_name-$granularity\])"
                    puts $fp "                  default: t_array\[$i\] = 0;"
                    puts $fp "            endcase\n"
                }
                
            }
            puts $fp "        end\n"
        }
        puts $fp "    endcase\n"
        incr op_count
    }
} else {
    for {set i 0} {$i < [llength $input_data_names]} {incr i} {
        if { $secure_data_input($i,0) == 1} {
            puts $fp "      if ([lindex $input_data_names $i]\_label == 0) begin"
            puts $fp "        case ([lindex $input_data_names $i]\[$width_name-1:$width_name-$granularity\])"
            for {set j 0} {$j < (1 << $granularity)} {incr j} {
                set a_val [lindex $input_values $j]
                set a_val_bin [format "%0${granularity}b" $a_val]
                puts $fp "          $granularity'b$a_val_bin: t_array\[$i\] = $data_max($i,$j,0);"
            }
            puts $fp "          default: t_array\[$i\] = $T_WCET_EXE;"
            puts $fp "        endcase"
            puts $fp "      end else t_array\[$i\] = 0;\n"
        }
    }
}


puts $fp "end"
puts $fp "\n"






###################################


puts $fp "  // FSM combinatorial logic"
puts $fp "  always_comb begin"
puts $fp "    state_d = state_q;"
puts $fp "    timer_d = timer_q;"
foreach out $output_data_names {
    puts $fp "    ${out}\_label_d = ${out}\_label_q;"
}
#if {$valid_out != ""} {
#    puts $fp "    ${valid_out}_d = ${valid_out}_q;"
#}
#if {$ready_out != ""} {
#    puts $fp "    ${ready_out}_d = ${ready_out}_q;"
#}
#foreach out $output_data_names {
#    puts $fp "    ${out}_d = ${out}_q;"
#}


puts $fp ""
puts $fp "    case (state_q)"
puts $fp "      IDLE: begin"
puts $fp "        if ($valid_in\_q) begin" ;#Reicht $valid_in Abfrage?
puts $fp "          state_d = RUN;"
puts $fp "          timer_d = 0;"

set last_in [expr {[llength $input_data_names] - 1}]
puts -nonewline $fp "          if ("
for {set i 0} {$i < [llength $input_data_names]} {incr i} {
    set connector [expr {$i == $last_in ? "" : " && "}]
    puts -nonewline $fp "([lindex $input_data_names $i]\_label == 1)$connector"
}
puts $fp ") begin"
puts $fp "            timer_d = $T_WCET_EXE;"
puts -nonewline $fp "          end else if ("
for {set i 0} {$i < [llength $input_data_names]} {incr i} {
    set connector [expr {$i == $last_in ? "" : " && "}]
    puts -nonewline $fp "([lindex $input_data_names $i]\_label == 0)$connector"
}
puts $fp ") begin"
puts $fp "            timer_d = 0;"
puts  $fp "          end else begin"

puts $fp "            for (int i = 0; i < [llength $input_data_names]; i++) begin"
puts $fp "              if (t_array\[i\] > timer_d) timer_d = t_array\[i\];"
puts $fp "            end"
puts $fp "        end"




if {$valid_out != ""} {
    puts $fp "          ${valid_out}_d = 1'b0;"
}
if {$ready_out != ""} {
    puts $fp "          ${ready_out}_d = 1'b0;"
}

set label_marker 0
set label_counter 0


foreach out_data $output_data_names {
    puts -nonewline $fp "          ${out_data}\_label\_d ="

    for {set i 0} {$i < [llength $input_data_names]} {incr i} {
        if {$label_marker == 0} {
            puts -nonewline $fp " [lindex $input_data_names $i]\_label"
            set label_marker 1
        } else {
            puts -nonewline $fp " | [lindex $input_data_names $i]\_label"
        }
        set label_counter 1
    }
}
puts $fp ";"
puts $fp "        end"
puts $fp "      end"
puts $fp "      RUN: begin"
puts $fp "        if (timer_q > 0)"
puts $fp "          timer_d = timer_q - 1;"
puts $fp "        else"
puts $fp "          state_d = DONE;"
puts $fp "      end"
puts $fp "      DONE: begin"
foreach out $output_data_names {
    puts $fp "        ${out}_d = ${out}_q;"
}
foreach out $output_data_names {
    puts $fp "        ${out}\_label_d = ${out}\_label_q;"
}
if {$valid_out != ""} {
    puts $fp "        ${valid_out}_d = 1'b1;"
}
if {$ready_out != ""} {
    puts $fp "        ${ready_out}_d = 1'b1;"
}
puts $fp "        state_d = IDLE;"
puts $fp "      end"
puts $fp "    endcase"
puts $fp ""
puts $fp "  end\n"


########################
# Finite State Machine #
########################
puts $fp "\n"

puts $fp "  // FSM sequential logic"
if {$reset_type == 0} {
    puts $fp "  always_ff @(posedge $clock_name or negedge $reset_name) begin"
} else {
    puts $fp "  always_ff @(posedge $clock_name or posedge $reset_name) begin"
}
puts $fp "    if ($rst_cond) begin"
puts $fp "      state_q <= IDLE;"
puts $fp "      timer_q <= $T_WCET_EXE;"
#if {$valid_out != ""} {
#    puts $fp "      ${valid_out}_q <= 1'b0;"
#}
#if {$ready_out != ""} {
#    puts $fp "      ${ready_out}_q <= 1'b0;"
#}
#foreach out $output_data_names {
#    puts $fp "      $out\_q <= '0;"
#}
foreach out $output_data_names {
    puts $fp "      $out\_label\_q <= 1'b1;"
}
puts $fp "    end else begin"
puts $fp "      state_q <= state_d;"
puts $fp "      timer_q <= timer_d;"
if {$ready_out != ""} {
    puts $fp "      ${ready_out}_q <= ${ready_out}_d;"
}
if {$valid_out != ""} {
    puts $fp "      ${valid_out}_q <= ${valid_out}_d;"
}
#foreach out $output_data_names {
#    puts $fp "      ${out}_q <= ${out}_d;"
#}
foreach out $output_data_names {
    puts $fp "      ${out}\_label_q <= ${out}\_label_d;"
}

puts $fp "    end"
puts $fp "  end\n"


##############
# Assignment #
##############

puts $fp "  // Assignments"

if {$valid_in != ""} {
    puts $fp "  assign $valid_in\_q = (state_q == IDLE) ? $valid_in : 1'b0;"
}
if {$ready_in != ""} {
    puts $fp "  assign $ready_in\_q = (state_q == IDLE) ? $ready_in : 1'b0;"
}
if {$valid_out != ""} {
    puts $fp "  assign ${valid_out} = ${valid_out}_d;"
}
if {$ready_out != ""} {
    puts $fp "  assign ${ready_out} = ${ready_out}_q;"
}


foreach out $output_data_names {
    puts $fp "  assign $out = ${out}_d;"
}
foreach out $output_data_names {
    puts $fp "  assign $out\_label = ${out}\_label_q;"
}

puts $fp ""
puts $fp "endmodule"

close $fp

puts "Wrapper generated successfully in $wrapper_file"

