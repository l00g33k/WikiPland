while [ 1 ]; do
busybox clear
echo a : l00httpd source codes aa: Part 2 aaa: ed aaaa: ed
echo b : l00http_cmdedit.sh edit same file
echo c : l00_tr.txt .......... cc: l00_reminder.txt
echo d : NtHappenings.txt .... dd: LgStopWatch.txt ddd: Phrases
echo e : l00_notify.txt
echo f : l00_cal.txt ......... ff: l00_reminder.txt
echo g : index.txt ........... gg: sl4a l00httpd script
echo h : TmpTodoInc.txt ...... hh: TmpMoreTodoInc.txt
echo i : l00httpd__readme.txt. ii: portfwrd.pl
echo j : l00httpd.cfg ........ jj: CutPasteCheat.txt
echo k : 0do.pl ..............
echo l : l00sh_l00httpcode.sh. ll: l00sh_l00httpcode2.sh
echo y : l00http_cmdedit.sh
echo z : l00http_cmdmain.sh
read sel
echo $sel

if [ $sel = "a" ]; then
source /sdcard/sl4a/scripts/l00httpd/l00sh_l00httpcode.sh; fi

if [ $sel = "aa" ]; then
source /sdcard/sl4a/scripts/l00httpd/l00sh_l00httpcode2.sh; fi

if [ $sel = "aaa" ]; then
vim /sdcard/sl4a/scripts/l00httpd/l00sh_l00httpcode.sh; fi

if [ $sel = "aaaa" ]; then
vim /sdcard/sl4a/scripts/l00httpd/l00sh_l00httpcode2.sh; fi

if [ $sel = "b" ]; then
#while [ 1 ]; do
#busybox sh /sdcard/sl4a/scripts/l00httpd/l00http_cmdedit.sh
source /sdcard/sl4a/scripts/l00httpd/l00http_cmdedit.sh
#done
fi

if [ $sel = "c" ]; then
vim /sdcard/l00httpd/l00_tr.txt; fi

if [ $sel = "cc" ]; then
vim /sdcard/l00httpd/l00_reminder.txt; fi

if [ $sel = "d" ]; then
vim /sdcard/l00httpd/NtHappenings.txt; fi

if [ $sel = "dd" ]; then
vim /sdcard/l00httpd/LgStopWatch.txt; fi

if [ $sel = "ddd" ]; then
vim /sdcard/l00httpd/NtStopWatchPhrases.txt; fi

if [ $sel = "e" ]; then
vim /sdcard/l00httpd/l00_notify.txt; fi

if [ $sel = "f" ]; then
vim /sdcard/l00httpd/l00_cal.txt; fi

if [ $sel = "ff" ]; then
vim /sdcard/l00httpd/l00_reminder.txt; fi

if [ $sel = "g" ]; then
vim /sdcard/l00httpd/index.txt; fi

if [ $sel = "gg" ]; then
sh /sdcard/sl4a.sh; fi

if [ $sel = "h" ]; then
vim /sdcard/l00httpd/TmpTodoInc.txt; fi

if [ $sel = "hh" ]; then
vim /sdcard/l00httpd/TmpMoreTodoInc.txt; fi

if [ $sel = "i" ]; then
vim /sdcard/sl4a/scripts/l00httpd/l00httpd__readme.txt; fi

if [ $sel = "ii" ]; then
vim /sdcard/sl4a/scripts/portfwrd.pl; fi

if [ $sel = "j" ]; then
vim /sdcard/sl4a/scripts/l00httpd/l00httpd.cfg; fi

if [ $sel = "jj" ]; then
vim /sdcard/l00httpd/CutPasteCheat.txt; fi

if [ $sel = "k" ]; then
vim /sdcard/sl4a/scripts/l00httpd/0do.pl; fi

if [ $sel = "l" ]; then
vim source /sdcard/sl4a/scripts/l00httpd/l00sh_l00httpcode.sh; fi

if [ $sel = "ll" ]; then
vim source /sdcard/sl4a/scripts/l00httpd/l00sh_l00httpcode2.sh; fi

if [ $sel = "y" ]; then
vim /sdcard/sl4a/scripts/l00httpd/l00http_cmdedit.sh; fi

if [ $sel = "z" ]; then
vim /sdcard/sl4a/scripts/l00httpd/l00http_cmdmain.sh; fi

done
fi

