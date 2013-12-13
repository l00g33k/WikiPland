while [ 1 ]; do
busybox clear
echo a : table ......... aa: txtdopl .... aaa: cal
echo b : ls ............ bb: scratch .... bbb: jetlag
echo c : do ............ cc: filecrypt .. ccc: l00httpd.pm
echo d : l00httpd ...... dd: crypt ...... ddd: pe ifconfig
echo e : solver ........ ee: coorcalc ... eee: find
echo f : tr ............ ff: l00backup.pm fff: launcher
echo g : chart ......... gg: eval ....... ggg: l00_battery.pl
echo h : dirnotes ...... hh: l00_crypt_ex1.pl hhh:2
echo i : l00wikihtml.pm .ii: blog ....... iii: search
echo j : solver ........ jj: notify ..... jjj: recedit
echo k : l00crypt.pm ... kk: edit ....... kkk: tableedit
echo x : everything else xx: kml ........ xxx: reminder
echo y : temp blog ..... yy: gps ........ yyy: gpsmap
echo z : cmdl00http.sh . zz: !!vm!! ..... zzz: !!ad hoc2!!
read sel
echo $sel
 
 if [ $sel = "zz" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_clip.pl; fi
 if [ $sel = "zzz" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_periocam.pl; fi
 if [ $sel = "a" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_table.pl; fi
 if [ $sel = "aa" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_txtdopl.pl; fi
 if [ $sel = "aaa" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_cal.pl; fi
 if [ $sel = "b" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_ls.pl; fi
 if [ $sel = "bb" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_scratch.pl; fi
 if [ $sel = "bbb" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_jetlag.pl; fi
 if [ $sel = "c" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_do.pl; fi
 if [ $sel = "cc" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_filecrypt.pl; fi
 if [ $sel = "ccc" ]; then
 busybox vi /sdcard/com.googlecode.perlforandroid/extras/perl/site_perl/l00httpd.pm; fi
 if [ $sel = "d" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00httpd.pl; fi
 if [ $sel = "dd" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_crypt.pl; fi
 if [ $sel = "ddd" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_perioifconfig.pl; fi
 if [ $sel = "e" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/solver.pl; fi
 if [ $sel = "ee" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_coorcalc.pl; fi
 if [ $sel = "eee" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_find.pl; fi
 if [ $sel = "f" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_tr.pl; fi
 if [ $sel = "ff" ]; then
 busybox vi /sdcard/com.googlecode.perlforandroid/extras/perl/site_perl/l00backup.pm; fi
 if [ $sel = "fff" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_launcher.pl; fi
 if [ $sel = "g" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/chart.pl; fi
 if [ $sel = "gg" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_eval.pl; fi
 if [ $sel = "ggg" ]; then
 busybox vi /sdcard/l00httpd/l00_battery.pl; fi
 if [ $sel = "h" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_dirnotes.pl; fi
 if [ $sel = "hh" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00_crypt_ex_1.pl; fi
 if [ $sel = "hhh" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00_crypt_ex_2.pl; fi
 if [ $sel = "i" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00wikihtml.pm; fi
 if [ $sel = "ii" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_blog.pl; fi
 if [ $sel = "iii" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_search.pl; fi
 if [ $sel = "j" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_solver.pl; fi
 if [ $sel = "jj" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_notify.pl; fi
 if [ $sel = "jjj" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_recedit.pl; fi
 if [ $sel = "k" ]; then
 busybox vi /sdcard/com.googlecode.perlforandroid/extras/perl/site_perl/l00crypt.pm; fi
 #busybox vi /sdcard/sl4a/scripts/l00httpd/l00wikihtml.pl; fi
 if [ $sel = "kk" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_edit.pl; fi
 if [ $sel = "kkk" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_tableedit.pl; fi
 if [ $sel = "xx" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_kml.pl; fi
 if [ $sel = "xxx" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_reminder.pl; fi
 if [ $sel = "y" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_scratch.pl; fi
 if [ $sel = "yy" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_gps.pl; fi
 if [ $sel = "yyy" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_gpsmap.pl; fi
 if [ $sel = "z" ]; then
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_cmdl00http.sh; fi
 
 done
 fi
 
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_cmdl00http.sh
 #busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_scratch.pl
 #busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_twitter.pl
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_periodic.pl
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_edit.pl
 busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_cal.pl
 #busybox vi /sdcard/sl4a/scripts/l00httpd/l00http_tr.pl
 
 
 
