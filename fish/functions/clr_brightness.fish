function clr_brightness
set bg_color $argv
set r (echo (string sub -s 1 -l 2 $bg_color) | awk '{print toupper($0)}')
set g (echo (string sub -s 3 -l 2 $bg_color) | awk '{print toupper($0)}')
set b (echo (string sub -s 5 -l 2 $bg_color) | awk '{print toupper($0)}')

set r_dec (printf "%d" 0x$r)
set g_dec (printf "%d" 0x$g)
set b_dec (printf "%d" 0x$b)

echo (math "($r_dec * 299 + $g_dec * 587 + $b_dec * 114) / 1000 ")
end
