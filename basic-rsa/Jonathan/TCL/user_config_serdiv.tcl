# @lang=tcl @ts=8
set start_time [clock milliseconds]
######################################
# Manual Input / Output Declarations #
######################################

#Set script path without subfiles
    #set script_path [file dirname [file normalize [info script]]]
    set script_path "/import/lab/users/seckinger/Master-Thesis/masterarbeit/cva6-serdiv"

#Set file options
    set file_type "sv" ; #".sv" ".v" ".vlog" ".svlog" ".inc" ".vo" ".vm" ".vlib" ".vhd" ".vhdl"
    set file_name "serdiv" ; #Inserts here the real name of the file like in your code
    set file_folder "optimized/" ; #Inserts here the real name of the folder
    set sva_file "property_checker_generated.sva"

#Set needed Subfiles:
    set subfile_names [list "ariane_dm_pkg.sv" "cf_math_pkg.sv" "rvfi_pkg.sv" "riscv_pkg.sv" "ariane_pkg.sv" "cv64a6_imafdc_sv39_config_pkg.sv" "lzc.sv"]
    set subfile_folder "common/"

#Module Name - Inserts here the real name of the module like in your code
    set module_name "serdiv"

#Set the name and maximum of width of the inputs
    set width_name "WIDTH"
    set width 8

#Set parameter
    set param_names [list ]
    set param_values [list]
#Set imports
    set import_name "ariane_pkg::*;"
    
#Clock and Reset - Inserts here the real names of Clock and Reset like in your code
    set clock_name "clk_i"
    set reset_name "rst_ni"
    set reset_type 0 ; #active_low = 1 or active_high = 0

#Interrupt / Flush
    set interrupt_names [list "flush_i"]

#Data Input - Inserts here the real names of Data-Inputs like in your code
    set input_operation_names [list "opcode_i"]
    set input_operation_length [list "1:0"]
    set operation_flag 0; # 0 = global check, 1 = each operation seperate

    set input_data_id_names [list "id_i"]
    set input_data_id_length [list "TRANS_ID_BITS-1:0"]

    set input_data_names [list "op_a_i" "op_b_i"] 
    set input_data_length [list "$width_name-1:0" "$width_name-1:0"]

#Handshake Signals
    set valid_in "in_vld_i" ; #start/input valid
    set valid_out "out_vld_o" ; #output valid

    set ready_in "out_rdy_i" ; #signal: output ready, new input possible
    set ready_out "in_rdy_o" ; #signal: input ready, new input possible
    set input_hs_names [list $valid_in $valid_out $ready_in $ready_out] ;
   
#Data Output - Inserts here the real names of Data-Outputs like in your code
    set output_id_names [list "id_o" ]
    set output_id_length [list "TRANS_ID_BITS-1:0"]

    set output_data_names [list "res_o" ]
    set output_data_length [list "$width_name-1:0"]

#Set Granularity - Inserts here the real value of the granularity max. width
    set granularity 3
    if { $granularity > $width} {
        set granularity $width
	}

#Set start sequence
    set ready_sequence [list \
    "0" "$ready_out" "1" \
    "0" "$valid_in" "0" \
    "1" "$valid_in" "1" \
    "2" "$valid_in" "0" \
    ]
    