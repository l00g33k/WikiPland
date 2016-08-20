# powercfg /batteryreport /output C:\x\battery.html"

$report = 'C:\\x\\battery.html';

print $sock `powercfg /batteryreport /output \"$report\"`;
print $sock " <a href=\"/ls.htm?path=$report&raw=on\">$report</a>\n";
print $sock "<p>\n";

if (open(IN, "<C:\\x\\battery.html")) {
    $cnt = 0;

    # skip to Recent usage table
    while (<IN>) {
        if(/Recent usage/) {
            last;
        }
    }
    undef @graph;
    undef @battdiff;
    undef @interval;
    $lasttime = 0;
    $lastlevel = -1;
    $values = '';
    while (<IN>) {
        # stop at the end of table (start of next)
        if(/Battery usage/) {
            last;
        }
        # extract date
        # <span class="date">2016-08-17 </span>
        if (/class="date">(\d+)-(\d+)-(\d+) *</) {
            $yr = $1;
            $mo = $2;
            $da = $3;
        }
        # extract time
        # <span class="time">22:36:06</span></td>
        if (/class="time">(\d+):(\d+):(\d+) *</) {
            $hr = $1;
            $mi = $2;
            $se = $3;
        }
        # extract battery level
        # </td><td class="percent">64 %
        if (/<td class="percent">(\d+?) %/) {
            $cnt++;
            $level = $1;
            # convert date to seconds since 1970
            $time = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, $se);

            # make battery level graph
            push (@graph, "$time,$level");

            # make measurement interval graph
            if ($lasttime > 0) {
                $diff = $time - $lasttime;
                push (@interval, "$time,$diff");
            } else {
                push (@interval, "$time,0");
            }

            # make battery level delta per hour graph
            if ($lastlevel >= 0) {
                if ($time != $lasttime) {
                    $diff = int (($lastlevel - $level) * 3600 / ($time - $lasttime));
                } else {
                    $diff = 0;
                }
                push (@battdiff, "$time,$diff");
            } else {
                push (@battdiff, "$time,0");
            }
$diff2 = $lastlevel - $level;
$diff2 .= ' ';
$diff2 .= $time - $lasttime;
if ($time != $lasttime) {
    $diff = int (($lastlevel - $level) * 3600 / ($time - $lasttime));
} else {
    $diff = 0;
}
            $values .= "$cnt: $yr-$mo-$da $hr:$mi:$se : $level $diff2 $diff\n";
            $lasttime = $time;
            $lastlevel = $level;
        }
    }

    # plot graphs
    &l00svg::plotsvg ('winbatt', join (' ', sort (@graph)), 500, 300);
    &l00svg::plotsvg ('winintv', join (' ', sort (@interval)), 500, 300);
    &l00svg::plotsvg ('windiff', join (' ', sort (@battdiff)), 500, 300);

    # display graphs
    print $sock "Battery level<br>\n";
    print $sock "<a href=\"/svg.pl?graph=winbatt&view=\"><img src=\"/svg.pl?graph=winbatt\" alt=\"alt\"></a><p>\n";
    print $sock "Battery measurement interval<br>\n";
    print $sock "<a href=\"/svg.pl?graph=winintv&view=\"><img src=\"/svg.pl?graph=winintv\" alt=\"alt\"></a><p>\n";
    print $sock "Battery consumption per hour estimate<br>\n";
    print $sock "<a href=\"/svg.pl?graph=windiff&view=\"><img src=\"/svg.pl?graph=windiff\" alt=\"alt\"></a>\n";

    print $sock "<p>There are $cnt lines of battery readings:\n";
    print $sock "<pre>$values</pre>\n";
    close(IN);
}

1;
