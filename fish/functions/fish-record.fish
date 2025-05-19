function fish-record
    fish -C 'function fish_preexec --on-event fish_preexec
    echo $argv >> fish-commands.log
end'
end
