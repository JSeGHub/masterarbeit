# @lang=tcl @ts=8
set start_time [clock milliseconds]
######################################
# Manual Input / Output Declarations #
######################################

#Set script path without subfiles
    set script_path [file dirname [file normalize [info script]]]
    set script_path "/import/lab/users/seckinger/Master-Thesis/masterarbeit/basic-rsa/Jonathan/"
    
#Set file options
    set file_type "vhd" ; #".sv" ".v" ".vlog" ".svlog" ".inc" ".vo" ".vm" ".vlib" ".vhd" ".vhdl"
    set file_name "modmult" ; #Inserts here the real name of the file like in your code
    set file_folder "" ; #Inserts here the real name of the folder
    set sva_file "property_checker_generated.sva"

#Set needed Subfiles:
    set subfile_names "" ; # [list]
    set subfile_folder ""

#Module Name - Inserts here the real name of the module like in your code
    set module_name "modmult"

#Set the name and maximum of width of the inputs
    set width_name "MPWID"
    set width 8

#Clock and Reset - Inserts here the real names of Clock and Reset like in your code
    set clock_name "clk"
    set reset_name "reset"
    set reset_type 1 ; #active_low = 0 or active_high = 1

#Interrupt / Flush
    set interrupt_names "" ; # [list]

#Data Input - Inserts here the real names of Data-Inputs like in your code
    set input_operation_names "" ; # [list]
    set input_operation_length "" ; # [list]
    set operation_flag 0; # 0 = global check, 1 = each operation seperate

    set input_data_id_names "" ; # [list]
    set input_data_id_length "" ; # [list]

    set input_data_names [list "mpand" "mplier" "modulus"] 
    set input_data_length [list "$width_name-1:0" "$width_name-1:0"]

#Handshake Signals
    set valid_in "ds" ; #start/input valid
    set ready_in "" ; #signal: output ready, new input possible

    set valid_out "ready" ; #output valid
    set ready_out "" ; #signal: input ready, new input possible
    set input_hs_names [list $valid_in $ready_in $valid_out $ready_out] ;
   
#Data Output - Inserts here the real names of Data-Outputs like in your code
    set output_id_names [list "product" ]
    set output_id_length [list "$width_name-1:0"]

    set output_data_names [list "product" ]
    set output_data_length [list "$width_name-1:0"]

#Set Granularity - Inserts here the real value of the granularity max. width
    set granularity 3
    if { $granularity > $width} {
        set granularity $width
	}

#Set start sequence
    set ready_sequence [list \
    "0" "$valid_in" "1" \
    "0" "$valid_out" "1" \
    "1" "$valid_in" "0" \
    ]

    set num_setup_cycles 0
