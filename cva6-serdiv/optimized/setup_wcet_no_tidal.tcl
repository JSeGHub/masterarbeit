# @lang=tcl @ts=8

################
# WCET – SETUP #
################

set script_path [file dirname [file normalize [info script]]]

#################################
# Design Setup and Verification #
#################################

read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cf_math_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/rvfi_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/riscv_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_dm_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/ariane_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/cv64a6_imafdc_sv39_config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/../common/lzc.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {$script_path/serdiv.sv}

set_elaborate_option -golden -verilog_parameter {WIDTH=8}

elaborate -golden

compile -golden

set_mode mv

read_sva -version {sv2012} {$script_path/serdiv_no_tidal.sva}

# check -all [get_checks]



Just some random things I could need
#get_counterexample_value
#get_counterexample_value -signals {serdiv.out_vld_o} checker_bind.wcet_p_a
#
#check -pass [ list checker_bind.bcet_p_a ]


