# @lang=tcl @ts=8

#####################
# Loop WCET - Setup #
#####################

source -signed "/import/usr/onespin/latest/etc/startup/onespin_startup.tcl.obf"
restart

set script_path [file dirname [file normalize [info script]]]
set sv_file [file join $script_path "modmult.sva"]
set mpwid 4


read_vhdl -golden  -pragma_ignore {}  -version 2008 {$script_path/modmult.vhd}
set_elaborate_option -golden -vhdl_generic {mpwid=4}
elaborate -golden
compile -golden
set_mode mv

edit_file $script_path/modmult.vhd
edit_file $script_path/modmult.sva


set_read_sva_option -loop_iter_threshold 1025
read_sva -version {sv2012} {$sv_file}

set_check_option -local_processes 8
#check -verbose -all [get_checks]


##############################
# Loop WCET - Proof unvacous #
##############################

set max_wcet [expr {$mpwid * 2}]  ;# Define the maximum WCET value
set prev_status "vacuous" 
# Loop from 1 to max_wcet and generate assertions dynamically
for {set t_wcet 1} {$t_wcet <= $max_wcet} {incr t_wcet} {
    
    exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/" $sv_file
    after 1000
    check  [ list checker_bind.ops.wcet_p_a ]

    set status [get_check_info -status checker_bind.ops.wcet_p_a]

    if {[string match "vacuous" $status] && [ string match "hold" $prev_status]} {
                #puts "WCET is $t_wcet" ;#not true WCET (calculate the cycles really included)
                set T_WCET_EXE [expr {$t_wcet-1}]
    }
    set prev_status $status
}

#puts "WCET is $T_WCET_EXE Cycles"


##############################
# Loop BCET - Proof unvacous #
##############################

set min_bcet [expr {$mpwid * 2}]  ;# Define the maximum WCET value
set prev_status "vacuous" 
# Loop from 1 to min_bcet and generate assertions dynamically
for {set t_bcet 0} {$t_bcet <= $min_bcet} {incr t_bcet} {
    
    exec sed -i "s/localparam T_BCET = .*/localparam T_BCET = $t_bcet;/" $sv_file
    after 1000
    check  [ list checker_bind.ops.bcet_p_a ]

    set status [get_check_info -status checker_bind.ops.bcet_p_a]

    if {[string match "hold" $status] && ![ string match "hold" $prev_status]} {
                #puts "WCET is $t_bcet" ;#not true WCET (calculate the cycles really included)
                set T_BCET_EXE $t_bcet
                break
    }
    set prev_status $status
}

#puts "BCET is $T_BCET_EXE Cycles"

##############################################
# Loop input dependend WCET - Proof unvacous #
##############################################
if {0} {

set max_wcet [expr {$mpwid * 2 - 1}]  ;# Maximales WCET
#set values {0 1 2 [expr {pow(2,$mpwid)/4}] [expr {pow(2,$mpwid)/2}] [expr {pow(2,$mpwid)-2}] [expr {pow(2,$mpwid)-1}] [expr {pow(2,$mpwid)}]}
set values [list 1 2 \
    [expr {int(pow(2,$mpwid)-1)}] \
    [expr {int(pow(2,$mpwid))}]]

#set values [list 1 2 [expr {int(pow(2,$mpwid)/4)}] \
#    [expr {int(pow(2,$mpwid)/2)}] \
#    [expr {int(pow(2,$mpwid)-2)}] \
#    [expr {int(pow(2,$mpwid)-1)}] \
#    [expr {int(pow(2,$mpwid))}]]
puts $values
after 1000  ;# Wartezeit für Stabilität
set prev_status "vacuous"  ;# Letzter Status für Vergleich
set wcet_results {}  ;# Initialize the list to empty at the beginning

# Schleifen für mpand, mplier und modulus
foreach mpand $values {
    foreach mplier $values {
        foreach modulus $values {
            puts "mpand: $mpand, mplier: $mplier, modulus: $modulus"
            set prev_status "vacuous"
            set last_wcet_report -1  ;# Letzter ausgegebener WCET-Wert

            for {set t_wcet 3} {$t_wcet <= $max_wcet} {incr t_wcet} {
    
                exec sed -i "s/localparam T_WCET = .*/localparam T_WCET = $t_wcet;/"  $sv_file
                exec sed -i "s/localparam MPAND = .*/localparam MPAND = $mpand;/"   $sv_file
                exec sed -i "s/localparam MPLIER = .*/localparam MPLIER = $mplier;/"  $sv_file
                exec sed -i "s/localparam MODULUS = .*/localparam MODULUS = $modulus;/" $sv_file
    
                after 1000
                check  [list checker_bind.ops.wcet_in_p_a]

                set status [get_check_info -status checker_bind.ops.wcet_in_p_a]

                #if {[string match "vacuous" $status] && ![ string match "vacuous" $prev_status]} {
                #    puts "WCET is $t_wcet" ;#not true WCET (calculate the cycles really included)
                #}

                # Falls WCET validiert wurde und nicht doppelt gespeichert wird
                if {[string match "vacuous" $status] && ![string match "vacuous" $prev_status]} {
                    if {$last_wcet_report != $t_wcet} {
                        # Speichere Ergebnis in der Liste
                        lappend wcet_results [list $mpand $mplier $modulus  [expr {$t_wcet-1}]]
                        puts "WCET is [expr {$t_wcet-1}] with $mpand $mplier $modulus"
                        set last_wcet_report $t_wcet
                        break
                    }
                }
                set prev_status $status
            }
        }
    }
}

#Tabelle am Ende ausgeben
puts "\n=== WCET Ergebnisse ==="
puts "MPAND  | MPLIER | MODULUS | WCET"
puts "---------------------------------"
foreach row $wcet_results {
    foreach {mpand mplier modulus t_wcet} $row {}
    puts [format "%-6d | %-6d | %-7d | %-3d" $mpand $mplier $modulus $t_wcet]
}}





######################################
# Calc Inputs for Mplier and Modulus #
######################################

# Calculate values for testing based on mpwid
set values {}

# Add lowest value: 0 
lappend values 0

# Add lowest value: 1 
lappend values 1

# Add highest possible value based on mpwid: 2^mpwid - 1
lappend values [expr {(1 << $mpwid) - 1}]

# Add values with MSB set at different positions
for {set i 1} {$i < $mpwid} {incr i} {
    lappend values [expr {1 << $i}]
}

# Determine number of random values based on mpwid
set num_random [expr {max(1, int(ceil($mpwid / 2.0)))}]  ;# At least 1, scales with mpwid

# Add a few random values within the valid range
set max_val [expr {(1 << $mpwid) - 1}]
for {set i 0} {$i < $num_random} {incr i} {
    if {$mpwid > 2} {
        # Generate a random number between 2 and max_val-1
        lappend values [expr {2 + int(rand() * ($max_val - 2))}]
    }
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

# Update the SVA file with the generated values lists for INPUT_A and INPUT_B
exec sed -i "s/localparam INPUT_A\\\[WIDTH_IN\\\] = .*/localparam INPUT_A\[WIDTH_IN\] = $sva_values_list;/" $sv_file
exec sed -i "s/localparam INPUT_B\\\[WIDTH_IN\\\] = .*/localparam INPUT_B\[WIDTH_IN\] = $sva_values_list;/" $sv_file
exec sed -i "s/localparam WIDTH_IN = .*/localparam WIDTH_IN = $total_values;/"  $sv_file
exec sed -i "s/localparam T_BCET_IN = .*/localparam T_BCET_IN = $T_BCET_EXE;/"  $sv_file
exec sed -i "s/localparam T_WCET_IN = .*/localparam T_WCET_IN = [expr {$T_WCET_EXE+1}];/"  $sv_file
after 1000; # wait for stability/read-in of the new values
check -verbose -all [get_checks]; # run all assertions (generate loop of inputs)


set te $T_WCET_EXE
set ts $T_BCET_EXE

# Open a file for writing the query results
set output_file [open "[file join $script_path "query_output.txt"]" w]
puts $output_file "a b ts status"

#Read all assertions results
for {set i 0} {$i < $total_values} {incr i} {
    for {set j 0} {$j < $total_values} {incr j} {
        for {set t $ts} {$t <= $te} {incr t} {
            
            #set query [get_check_info -status {checker_bind.genblk1[${i}].genblk1[${j}].genblk1[${t}].wcet_in_p_a}]
            set query "checker_bind.genblk1\[$i\].genblk1\[$j\].genblk1\[$t\].wcet_in_p_a"
            set query_results [get_check_info -status $query]

            # Get actual values from the list
            set a_val [lindex $values $i]
            set b_val [lindex $values $j]
            
            # Print to console
            puts "a=$a_val, b=$b_val, t=$t, $query_results"
            
            # Write to file only if status is "hold"
            if {[string match "hold" $query_results]} {
                puts $output_file "$a_val $b_val $t $query_results"
                flush $output_file
            }
        }
    }
}

close $output_file
puts "Query results have been saved to [file join $script_path "query_output.txt"] (only 'hold' status values)"

puts "BCET is $T_BCET_EXE Cycles"
puts "WCET is $T_WCET_EXE Cycles"
puts "Values: $values"

# Print values in binary
foreach val $values {
    puts [format "%*b" $mpwid $val]
}