#$csv = '/sdcard/battery_graph_Jun05-114824_to_Jun12-114031.csv';
#$csv = '';
#$csv = '/sdcard/battery_graph_Jun05-114824_to_Jun12-114031.csv';
undef $csv;

$fifosize = 7;
print $sock "Battery Graph export processor: average %fifosize timestamped battery % level readings to produce an average %/hour readings<br>\n";

# search for latest export
$path = "/sdcard/";
$newmtime = 0;
print $sock "<pre>\n";
print $sock "Searching for latest export\n";
if (opendir (DIR, $path)) {
    foreach $file (sort readdir (DIR)) {
        if (!(-d $path.$file)) {
            if ($file =~ /att/) {
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                  = stat($path.$file);
print $sock "$file $mtime\n";
                if ($mtime > $newmtime) {
                    $newmtime = $mtime;
                    $csv = $path . $file;
                }
            }
        }
    }
    closedir (DIR);
}
print $sock "</pre>\n";
#$csv = '/sdcard/battery_graph_Jun05-114824_to_Jun12-114031.csv';
#$csv = '/sdcard/battery_graph_Jul13-000321_to_Jul19-235821.csv';
# latest export is $cvs
print $sock "Processing: $csv<br>\n";


print $sock "<a href=\"/view.htm?path=$csv\">view $csv</a>\n\n";
#print $sock "<a href=\"/edit.htm?path=/sdcard/l00httpd/l00_battery.pl\">edit l00_battery.pl</a>\n\n";

print $sock "<pre>\n";


if (open (BATT, "<$csv")) {
# skip 2017 - 12 * 30
for ($ii = 0; $ii < 1500; $ii++) {
#      $_ = <BATT>;
}
    # put 3 in the FIFO
    undef @fifo;
    for ($ii = 0; $ii < $fifosize; $ii++) {
        $_ = <BATT>;
        push (@fifo, $_);
    }
    while (<BATT>) {
        # push newest into FIFO
        push (@fifo, $_);
        #sample_date, sample_date_in_seconds, battery_level
        #2010 May 03 00:14:06,1272870846,95
        s/\n//;
        s/\r//;
        # the newer for the delta calculation
        ($dtstamp, $secs, $batt) = split (',', $_);
        # pop from FIFO (FIFO has 3 again)
        $_ = shift (@fifo);
        s/\n//;
        s/\r//;
        # the older for the delta calculation
        ($dtstamp2, $secs2, $batt2) = split (',', $_);
        if ($secs2 > 0) {
            # calculate the delta
            $pct = int (($batt - $batt2) * 3600 / ($secs - $secs2));
            $pcttxt = sprintf ("%  3d", $pct);
            if ($pct > 0) {
                # crude bar graph of + for charging
                print $sock "$dtstamp $batt : $pcttxt " . "+" x int($pct/4) . "\n";
            } elsif ($pct < 0) {
                # crude bar graph of - for discharging
                print $sock "$dtstamp $batt : $pcttxt " . "-" x int(-$pct/4) . "\n";
            } else {
                print $sock "$dtstamp $batt :   0\n";
            }
        } else {
            print $sock "$_\n";
        }
    }
    close (BATT);
} else {
    print $sock "Failed to open $csv\n";
}

print $sock "</pre>\n";
1;
