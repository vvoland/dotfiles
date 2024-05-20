function set-governor --argument governor
 for gov in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
echo "$governor" | sudo tee "$gov"
end; 
end
