# powercfg /batteryreport /output C:\x\battery.html"

$report = "$ctrl->{'tmp'}win_batt_rpt_$ctrl->{'now_string'}.txt";
$report =~ s/ /_/g;


print $sock `powercfg /batteryreport /output \"$report\"`;
print $sock " <a href=\"/ls.htm?path=$report&raw=on\" target=\"_blank\">$report</a>. \n";
print $sock "<p>\n";

if (open(IN, "<$report")) {
    $cnt = 0;

    # skip to Recent usage table
    while (<IN>) {
        if(/Recent usage/) {
            last;
        }
    }
    undef @graph;
    undef @battdiff;
    undef @battsrc;
    undef @interval;
    $lasttime = 0;
    $lastlevel = -1;
    $lastbattsrc = '';
    $values = '';
    $findstate = 0;
    $findsource = 0;
    while (<IN>) {
        s/\n//g;
        s/\r//g;
        # stop at the end of table (start of next)
        if(/Battery usage/) {
            last;
        }
        # </td></tr></thead><tr class="even dc 1"><td class="dateTime"><span class="date">2016-08-18 </span><span class="time">21:19:25</span></td><td class="state">
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
        # extract state
        #   Connected standby
        #   <td class="state">
        if ($findstate && 
            (length($_) > 4) &&
            (!/^ *$/)) {
            s/^ *//;
            s/ *$//;
            $state = $_;
            $findstate = 0;
        }
        if (/class="state"/) {
            $findstate = 1;
        }

        # extract source
        #  </td><td class="acdc">
        if ($findsource && 
            (length($_) > 4) &&
            (!/^ *$/)) {
            s/^ *//;
            s/ *$//;
            $source = $_;
            $findsource = 0;
        }
        if (/class="acdc"/) {
            $findsource = 1;
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

            # make charging graph
            if ($source eq 'AC') {
                if ($lastbattsrc ne $source) {
                    push (@battsrc, "$time,0");
                }
                push (@battsrc, "$time,1");
            } else {
                if ($lastbattsrc ne $source) {
                    push (@battsrc, "$time,1");
                }
                push (@battsrc, "$time,0");
            }

            # make battery level delta per hour graph
            if ($lastlevel >= 0) {
                if ($time != $lasttime) {
                    $diff = $lastlevel - $level;
                } else {
                    $diff = 0;
                }
                push (@battdiff, "$time,$diff");
            } else {
                push (@battdiff, "$time,0");
            }
            $values .= 
                sprintf("$cnt: $yr-$mo-$da $hr:$mi:$se : %3d % 3d   %-20s %-10s\n",
                $level, $diff, $state, $source);
            $lasttime = $time;
            $lastlevel = $level;
            $lastbattsrc = $source;
        }
    }

    # plot graphs
    &l00svg::plotsvg ('winbatt', join (' ', @graph), 500, 300);
    &l00svg::plotsvg ('winintv', join (' ', @interval), 500, 300);
    &l00svg::plotsvg ('windsrc', join (' ', @battsrc), 500, 300);
    &l00svg::plotsvg ('windiff', join (' ', @battdiff), 500, 300);

    # display graphs
    print $sock "Battery level<br>\n";
    print $sock "<a href=\"/svg.pl?graph=winbatt&view=\"><img src=\"/svg.pl?graph=winbatt\" alt=\"alt\"></a><p>\n";
    print $sock "Battery charging<br>\n";
    print $sock "<a href=\"/svg.pl?graph=windsrc&view=\"><img src=\"/svg.pl?graph=windsrc\" alt=\"alt\"></a><p>\n";
    print $sock "Battery measurement interval<br>\n";
    print $sock "<a href=\"/svg.pl?graph=winintv&view=\"><img src=\"/svg.pl?graph=winintv\" alt=\"alt\"></a><p>\n";
    print $sock "Battery level delta<br>\n";
    print $sock "<a href=\"/svg.pl?graph=windiff&view=\"><img src=\"/svg.pl?graph=windiff\" alt=\"alt\"></a>\n";

    print $sock "<p>There are $cnt lines of battery readings:\n";
    print $sock "<pre>$values</pre>\n";
    close(IN);
}

1;
