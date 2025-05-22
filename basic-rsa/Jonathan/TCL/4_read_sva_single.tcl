# Read SVA 

    set_read_sva_option -loop_iter_threshold 5000
    set sva_file_path [file join $script_path $sva_file\_short.sva]
    read_sva -version {sv2012} $sva_file_path