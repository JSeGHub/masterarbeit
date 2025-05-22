##########
#  Setup #
##########

# Restart Onespin
    source -signed "/import/usr/onespin/latest/etc/startup/onespin_startup.tcl.obf"
    restart

# Load subfiles
    if {[llength $subfile_names] != ""} {
        foreach subfile $subfile_names {
            if  {$file_type == "vhd" || $file_type == "vhdl"} {
                read_vhdl -golden -pragma_ignore {} -version 2008 $script_path/$subfile_folder$subfile
            } else {
                read_verilog -golden  -pragma_ignore {}  -version sv2012 $script_path/$subfile_folder$subfile
            }
        }
    }

# Load the design
    if  {$file_type == "vhd" || $file_type == "vhdl"} {
            read_vhdl -golden -pragma_ignore {} -version 2008 $script_path/$file_folder$file_name.$file_type
        } else {
            read_verilog -golden  -pragma_ignore {}  -version sv2012 $script_path/$file_folder$file_name.$file_type
        }

# Set the Width
    if  {$file_type == "vhd" || $file_type == "vhdl"} {
            set_elaborate_option -golden -vhdl_generic "$width_name=$width"
        } else {
            set_elaborate_option -golden -verilog_parameter "$width_name=$width"
        }
    

    elaborate -golden
    compile -golden
    set_mode mv
    set_check_option -local_processes 8