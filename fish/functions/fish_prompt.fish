function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status --background=red white

    # Color the prompt differently when we're root
    set -l color_cwd '#AFB42B'

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    echo -n -s (whoami)' ' (set_color $color_cwd)

    set -l color (random choice fce4ec f8bbd0 f48fb1 f06292 ec407a e91e63 d81b60 c2185b ad1457 880e4f ff80ab ff4081 f50057 c51162 f3e5f5 e1bee7 ce93d8 ba68c8 ab47bc 9c27b0 8e24aa 7b1fa2 6a1b9a 4a148c ea80fc e040fb d500f9 aa00ff ede7f6 d1c4e9 b39ddb 9575cd 7e57c2 673ab7 5e35b1 512da8 4527a0 311b92 b388ff 7c4dff 651fff 6200ea e8eaf6 c5cae9 9fa8da 7986cb 5c6bc0 3f51b5 3949ab 303f9f 283593 1a237e 8c9eff 536dfe 3d5afe 304ffe e3f2fd bbdefb 90caf9 64b5f6 42a5f5 2196f3 1e88e5 1976d2 1565c0 0d47a1 82b1ff 448aff 2979ff 2962ff e1f5fe b3e5fc 81d4fa 4fc3f7 29b6f6 03a9f4 039be5 0288d1 0277bd 01579b 80d8ff 40c4ff 00b0ff 0091ea e0f7fa b2ebf2 80deea 4dd0e1 26c6da 00bcd4 00acc1 0097a7 00838f 006064 84ffff 18ffff 00e5ff 00b8d4 e0f2f1 b2dfdb 80cbc4 4db6ac 26a69a 009688 00897b 00796b 00695c 004d40 a7ffeb 64ffda 1de9b6 00bfa5 f9fbe7 f0f4c3 e6ee9c dce775 d4e157 cddc39 c0ca33 afb42b 9e9d24 827717 f4ff81 eeff41 c6ff00 aeea00 fffde7 fff9c4 fff59d fff176 ffee58 ffeb3b fdd835 fbc02d f9a825 f57f17 ffff8d ffff00 ffea00 ffd600 fff8e1 ffecb3 ffe082 ffd54f ffca28 ffc107 ffb300 ffa000 ff8f00 ff6f00 ffe57f ffd740 ffc400 ffab00 fff3e0 ffe0b2 ffcc80 ffb74d ffa726 ff9800 fb8c00 f57c00 ef6c00 e65100 ffd180 ffab40 ff9100 ff6d00 fbe9e7 ffccbc ffab91 ff8a65 ff7043 ff5722 f4511e e64a19 d84315 bf360c ff9e80 ff6e40 ff3d00 dd2c00 efebe9 d7ccc8 bcaaa4 a1887f 8d6e63 795548 6d4c41 5d4037 4e342e 3e2723 fafafa f5f5f5 eeeeee e0e0e0 bdbdbd 9e9e9e 757575 616161 424242 212121 eceff1 cfd8dc b0bec5 90a4ae 78909c 607d8b 546e7a 455a64 37474f 263238)
    set -l brightness (clr_brightness $color)

	echo -n -s $prompt_status " "

    echo -n -s (set_color \#$color) 

    echo -n -s \uE0BE

    if test $brightness -gt 150
        echo -n -s (set_color -o black)
    else
        echo -n -s (set_color -o normal) 
    end
    echo -n -s (set_color -b \#$color) 

    echo -n -s " "(prompt_pwd)" "

    echo -n -s (set_color -b normal) 
    echo -n -s (set_color \#$color) 
    echo -n -s \uE0B0


    echo -n -s ' '
    set_color normal
end


