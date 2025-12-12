function glog
    git log --pretty=format:"%C(bold)%C(normal 1)  %s  %C(reset)%n%C(yellow)%H%C(reset) %C(green)%an% C(blue)%ad%C(reset)%n%C(reset) %n%w(0,2,2)%b%n" --date=format:"%y-%m-%d %H:%M:%S"
end
