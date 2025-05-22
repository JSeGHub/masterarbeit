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
puts $fp "module ${module_name}_wrapper #\("
puts $fp "    parameter int $width_name = $width"
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

foreach in_data $input_data_label_names {
    puts $fp "    input  logic $in_data,"
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


# Outputs
foreach out $output_names len $output_length {
    puts $fp "    output logic \[$len\] $out,"
}

set last_output_index [expr {[llength $output_names] - 1}]
foreach out $output_label_names {
    set suffix [expr {0 == $last_output_index ? "" : ","}]
    puts $fp "    output logic $out $suffix"
}

puts $fp "\);\n"



####################
# Internal signals #
####################

puts $fp "  // Internal signals"

foreach out $output_names len $output_length {
    puts $fp "  logic \[$len\] ${out}_internal;"
}

foreach out $output_label_names {
    puts $fp "  logic ${out}_internal;"
}

puts $fp ""

if {$valid_out != ""} {
    puts $fp "  logic ${valid_out}_internal;"
}

if {$ready_out != ""} {
    puts $fp "  logic ${ready_out}_internal;"
}


puts $fp "  logic running;"
puts $fp "  logic \[$width_name-1:0\] timer = 0;\n"

puts $fp " "
puts $fp "  // Timing array"
puts $fp "  logic \[$width_name-1:0\] t_array \[[llength $input_data_names]\];"
puts $fp " \n"




###########################
# Reset polarity handling #
###########################

set rst_cond ($reset_name)
if { $reset_type == 1 } {
    set rst_cond "!$reset_name"
}



########################
# DUT instantiation #
########################

puts $fp "  // Instantiate the DUT"
puts $fp "  $module_name #\("
puts $fp "    .$width_name\($width_name\)"
puts $fp "  \) dut \("
puts $fp "    .$clock_name\($clock_name\),"
puts $fp "    .$reset_name\($reset_name\),"

#Connect handshake

if {$valid_in != ""} {
    puts $fp "    .$valid_in\($valid_in\_internal\),"
}
if {$valid_out != ""} {
    puts $fp "    .$valid_out\($valid_out\_internal\),"
}
if {$ready_in != ""} {
    puts $fp "    .$ready_in\($ready_in\_internal\),"
}
if {$ready_out != ""} {
    puts $fp "    .$ready_out\($ready_out\_internal\),"
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

foreach in $input_data_label_names {
    puts $fp "    .$in\($in\),"
}


# Outputs
foreach out $output_names {
    puts $fp "    .$out\($out\_internal\),"
}

set last_output_index [expr {[llength $output_names] - 1}]
foreach out $output_label_names {
    set suffix [expr {0 == $last_output_index ? "" : ","}]
    puts $fp "    .$out\($out\_internal\) $suffix"
}



puts $fp "  \);\n"
puts $fp "  \n"



########################
# Combinatorial Timing #
########################
puts $fp "  // Combinatorial logic - Timing behavior"
puts $fp " "
puts $fp "  always_comb begin"
puts $fp "    // Default values"

for {set i 0} {$i < [llength $input_data_names]} {incr i} {
    puts $fp "    t_array\[$i\] = $T_WCET_EXE;"
}

puts $fp ""
puts $fp "    // Timing decision based on MSB"
for {set i 0} {$i < [llength $input_data_names]} {incr i} {
    if { $secure_data_input($i) == 1} {
        puts $fp "\n        // MUX for [lindex $input_data_names $i]"
        puts $fp "        case ([lindex $input_data_names $i]\[$width_name-1:$width_name-$granularity\])"
        for {set j 0} {$j < (1 << $granularity)} {incr j} {
            set a_val [lindex $input_values $j]
            set a_val_bin [format "%0${granularity}b" $a_val]
            puts $fp "          $granularity'b$a_val_bin: t_array\[$i\] = $data_max($i,$j);"
        }
        puts $fp "          default: t_array\[$i\] = $T_WCET_EXE;"
        puts $fp "        endcase\n"
    }
}

set secure_found 0
for {set i 0} {$i < [llength $input_data_names]} {incr i} {
    if {$secure_data_input($i) == 1 && $secure_found == 0} {
        puts $fp "        ${out}_internal <= 1;"
        set secure_found 1
    }
}

if {!$secure_found} {
    puts $fp "        ${out}_internal <= 0;"
}

puts $fp "  end"
puts $fp "\n"

########################
# Finite State Machine #
########################
puts $fp "  // Sequential logic - FSM"
puts $fp ""
puts $fp "  always_ff @(posedge clk or posedge reset) begin"
    puts $fp "      if ($rst_cond) begin"
        puts $fp "          timer = $T_WCET_EXE;"
        puts $fp "          running <= 0;"

        if {$valid_out != ""} {
            puts $fp "          $valid_out\_internal <= 0;"
        }

        if {$ready_out != ""} {
            puts $fp "          $ready_out\internal <= 0;"
        }

        # Outputs
        foreach out $output_names len $output_length {
            puts $fp "          $out <= 0;"
        }

        foreach out $output_label_names {
            puts $fp "          $out <= 1;"
        }

        puts $fp ""


        puts $fp "      end else begin"
            puts $fp "          if ($valid_in && !running) begin"
                puts $fp "              timer = 0;"
                puts $fp "              for (int i = 0; i < [llength $input_data_names]; i++) begin"
                    puts $fp "                  if (t_array\[i\] > timer) begin"
                        puts $fp "                     timer = t_array\[i\];"
                    puts $fp "                  end"
                puts $fp "                  end"
                puts $fp "                  running <= 1;"
                puts $fp "                  $ready_out <= 0;"
                puts $fp ""
            puts $fp "          end else if (running) begin"
                puts $fp "              if (timer > 0) begin"
                    puts $fp "                  timer = timer - 1;"
                    puts $fp ""
                puts $fp "              end else begin"
                    puts $fp "                  $ready_out <= ${ready_out}_internal;"
                    puts $fp "                  running <= 0;"

                    foreach out $output_names  {
                        puts $fp "                  $out <= ${out}_internal;"    
                    }

                    foreach out $output_label_names  {
                        puts $fp "                  $out <= ${out}_internal;"
                    }
                    puts $fp ""
                puts $fp "              end"
                puts $fp ""
            puts $fp "          end else begin"
                if {$valid_out != ""} {
                    puts $fp "              $valid_out\_internal <= 0;"
                }

                if {$ready_out != ""} {
                    puts $fp "              $ready_out\internal <= 0;"
                }
                puts $fp ""
        puts $fp "          end"
    puts $fp "      end"
puts $fp "  end\n"

puts $fp "endmodule"

close $fp

puts "Wrapper generated successfully in $wrapper_file"

