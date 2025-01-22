read_verilog -golden  -pragma_ignore {}  -version sv2012 {submodules/cf_math_pkg.sv submodules/riscv_pkg.sv submodules/config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {submodules/ariane_pkg.sv submodules/cv32a6_imac_sv0_config_pkg.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {submodules/lzc.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {rtl/original/serdiv.sv}
read_verilog -golden  -pragma_ignore {}  -version sv2012 {verification/serdiv_miter.sv}

set_elaborate_option -golden -verilog_parameter {WIDTH=8}

elaborate -golden

compile -golden

set_mode mv

read_sva -version {sv2012} {verification/serdiv_dit.sva}
