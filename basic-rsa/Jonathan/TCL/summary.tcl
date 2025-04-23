puts "\n===== Configuration Summary =====\n"
puts "SVA file: $sva_file"
puts "Granularity: $granularity"
puts "Module name: $module_name"
puts "WIDTH: $width"
puts "Input names:$input_data_names"
puts "BCET is $T_BCET_EXE Cycles"
puts "WCET is $T_WCET_EXE Cycles"

set elapsed_ms [expr {$end_time - $start_time}]

set minutes [expr {$elapsed_ms / 60000}]
set seconds [format "%02d" [expr {($elapsed_ms % 60000) / 1000}]]

puts "Laufzeit: $minutes:$seconds min"