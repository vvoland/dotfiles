function glog
    git log --pretty=format:"%C(bold)%C(yellow)%H%C(reset) %C(green)%an% C(blue)%ad%C(reset)%n%C(bold white)  %s  %C(reset)%C(cyan)%d%C(reset)%n---%n%w(0,2,2)%b%n" --date=format:"%y-%m-%d %H:%M:%S"
end
