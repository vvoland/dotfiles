function zp --wraps='sudo zypper' --description 'alias zp=sudo zypper'
    sudo zypper $argv
end
