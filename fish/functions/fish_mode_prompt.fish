# The fish_mode_prompt function is prepended to the prompt
function fish_mode_prompt --description "Displays the current mode"
    if test -n "$SSH_CONNECTION"
        set -l ssh_red '#be123c'
        echo -n -s (set_color $ssh_red)
        #echo -n -s \uE0BE
        echo -n -s (set_color --background $ssh_red white)
        echo -n -s " $(hostname)"
        echo -n -s (set_color --background normal $ssh_red)
        echo -n -s \uE0B0
        echo -n -s (set_color normal)
        echo -n -s ' '
    end

    fish_default_mode_prompt
end
