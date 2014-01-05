use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $battlog, $battcnt, $battpolls, $perltime);
my %config = (proc => "l00http_periobattery_proc",
              desc => "l00http_periobattery_desc",
              perio => "l00http_periobattery_perio");
my ($savedpath, $battperc, $battvolts, $batttemp, $battmA, $lasttimestamp);
my ($table, $tablehdr, $firstdmesg, $lastdmesg, $maxreclen, $skip, $len);
my ($graphwd, $graphht);
my $interval = 0, $lastcalled = 0;
$battcnt = 0;
$perltime = 0;
$savedpath = '';
$battlog = '';
$battpolls = 0;
$lasttimestamp = 0;
$battperc = 0;
$battvolts = 0;
$batttemp = 0;
$battmA = 0;
$table = '';
$tablehdr = "||#||level||vol||C||curr||chg src||chg en||over vchg||batt state||time stamp||\n";
$firstdmesg = '';
$lastdmesg = '';
$maxreclen = 60 * 24 * 7;
$skip = -1;
$len = 60 * 6;
$graphwd = 500;
$graphht = 300;


sub l00http_periobattery_suspend {
    my ($ctrl) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket

    # suspend to sdcard so it can be resumed after restart
    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved");
    &l00httpd::l00fwriteBuf($ctrl, "interval=$interval\n");
    &l00httpd::l00fwriteBuf($ctrl, "battcnt=$battcnt\n");
    &l00httpd::l00fwriteBuf($ctrl, "maxreclen=$maxreclen\n");
    &l00httpd::l00fwriteBuf($ctrl, "savedpath=$savedpath\n");
    &l00httpd::l00fwriteBuf($ctrl, "perltime=$perltime\n");
    &l00httpd::l00fwriteBuf($ctrl, "firstdmesg=$firstdmesg");
    &l00httpd::l00fwriteBuf($ctrl, "lastdmesg=$lastdmesg");
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved");
    &l00httpd::l00fwriteBuf($ctrl, $battlog);
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_table.saved");
    &l00httpd::l00fwriteBuf($ctrl, $table);
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_periobattery_table.saved'<p>\n";
    }

    l00httpd::dbp($config{'desc'}, "Suspend to sdcard:\n");
    l00httpd::dbp($config{'desc'}, "interval=$interval\n");
    l00httpd::dbp($config{'desc'}, "battcnt=$battcnt\n");
    l00httpd::dbp($config{'desc'}, "maxreclen=$maxreclen\n");
    l00httpd::dbp($config{'desc'}, "savedpath=$savedpath\n");
    l00httpd::dbp($config{'desc'}, "perltime=$perltime\n");
    l00httpd::dbp($config{'desc'}, "firstdmesg=$firstdmesg");
    l00httpd::dbp($config{'desc'}, "lastdmesg=$lastdmesg");
    l00httpd::dbp($config{'desc'}, "battlog:\n");
    l00httpd::dbp($config{'desc'}, $battlog);
    l00httpd::dbp($config{'desc'}, "table:\n");
    l00httpd::dbp($config{'desc'}, $table);
}

sub l00http_periobattery_resume {
    my ($ctrl) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my ($key, $val);

    # resume from sdcard after restart
    if (&l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved")) {
        $interval = 0;
        $battcnt = 0;
        $battlog = '';
        $battpolls = 0;
        $savedpath = '';
        $firstdmesg = '';
        $lastdmesg = '';
        $table = '';
        $maxreclen = 60 * 24 * 7;

        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            if (/interval=(\d+)/) {
                $interval = $1;
            }
            if (/battcnt=(\d+)/) {
                $battcnt = $1;
            }
            if (/maxreclen=(\d+)/) {
                $maxreclen = $1;
            }
            if (/savedpath=(.+)/) {
                $savedpath = $1;
            }

            if (/perltime=(\d+)/) {
                $perltime = $1;
            }
            if (/firstdmesg=(.+)/) {
                $firstdmesg = "$1\n";
            }
            if (/lastdmesg=(.+)/) {
                $lastdmesg = "$1\n";
            }
        }

        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved");
        $battlog = &l00httpd::l00freadAll($ctrl);
        if (!defined($battlog)) {
            $battlog = '';
        }

        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_table.saved");
        $table = &l00httpd::l00freadAll($ctrl);
        if (!defined($table)) {
            $table = '';
            $battcnt = 0;
        }

        l00httpd::dbp($config{'desc'}, "battlog:\n");
        l00httpd::dbp($config{'desc'}, $battlog);
        l00httpd::dbp($config{'desc'}, "table:\n");
        l00httpd::dbp($config{'desc'}, $table);
        l00httpd::dbp($config{'desc'}, "Resumed from sdcard:\n");
        l00httpd::dbp($config{'desc'}, "interval=$interval\n");
        l00httpd::dbp($config{'desc'}, "battcnt=$battcnt\n");
        l00httpd::dbp($config{'desc'}, "maxreclen=$maxreclen\n");
        l00httpd::dbp($config{'desc'}, "savedpath=$savedpath\n");
        l00httpd::dbp($config{'desc'}, "perltime=$perltime\n");
        l00httpd::dbp($config{'desc'}, "firstdmesg=$firstdmesg");
        l00httpd::dbp($config{'desc'}, "lastdmesg=$lastdmesg");

        # delete .saved once resumed
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_table.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_table.saved");
        &l00httpd::l00fwriteClose($ctrl);
    }
}

sub l00http_periobattery_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket

    # auto resume
    &l00http_periobattery_resume($ctrl);

    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: periobattery: Periodic logging of battery by dmesg";
}


sub l00http_periobattery_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp, $lnno, $keep, $noln);
    my ($svgperc, $svgvolt, $svgtemp, $svgmA);
    my ($yr, $mo, $da, $hr, $mi, $se, $now);
    my ($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"restore"})) {
        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_battlog.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_periobattery_table.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_periobattery_table.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);
    }
    if ((defined ($form->{'skip'})) && ($form->{'skip'} =~ /([0-9\-]+)/)) {
        $skip = $1;
    }
    if ((defined ($form->{'len'})) && ($form->{'len'} =~ /(\d+)/)) {
        $len = $1;
    }
    if ((defined ($form->{'graphwd'})) && ($form->{'graphwd'} =~ /(\d+)/)) {
        $graphwd = $1;
    }
    if ((defined ($form->{'graphht'})) && ($form->{'graphht'} =~ /(\d+)/)) {
        $graphht = $1;
    }
    if (defined ($form->{"suspend"})) {
        &l00http_periobattery_suspend($ctrl);
    }
    if (defined ($form->{"resume"})) {
        &l00http_periobattery_resume($ctrl);
    }
    if ((defined ($form->{"maxreclen"})) && ($form->{"maxreclen"} =~ /(\d+)/)) {
        $maxreclen = $1;
        # trim if necessary
        $noln = $table =~ s/\n/\n/g;
        print "periobattery: trimming ", $noln - $maxreclen, " lines\n";
        while ($noln > $maxreclen) {
            $table   =~ s/\n.*?$//;   # trim from the end, oldest
            $battlog =~ s/^.*?\n//;   # trim from the start, oldest
            $noln = $table =~ s/\n/\n/g;
        }
    }
    if ((defined ($form->{"keep"})) && ($form->{"keep"} =~ /(\d+)/)) {
        $keep = $1;
        $tmp = '';
        $lnno = 0;
        $noln = $table =~ s/\n/\n/g;
        foreach $_ (split("\n", $table)) {
            if ($lnno > ($noln - $keep)) {
                $tmp .= "$_\n";
            }
            $lnno++;
        }
        $table = $tmp;

        $tmp = '';
        $lnno = 0;
        foreach $_ (split("\n", $battlog)) {
            if ($lnno > ($noln - $keep)) {
                $tmp .= "$_\n";
            }
            $lnno++;
        }
        $battlog = $tmp;
    }
    if (defined ($form->{"clear"})) {
        $interval = 0;
        $battcnt = 0;
        $battlog = '';
        $battpolls = 0;
        $savedpath = '';
        $firstdmesg = '';
        $lastdmesg = '';
        $table = '';
    }
    # save path
    if (defined ($form->{"save"}) && defined ($form->{'savepath'}) && (length ($form->{'savepath'}) > 0)) {
        if (open (OU, ">$form->{'savepath'}")) {
            print OU $battlog;
            close (OU);
            $savedpath = $form->{'savepath'};
        }
    }
    if (defined ($form->{"overwrite"}) && defined ($form->{'owpath'}) && (length ($form->{'owpath'}) > 0)) {
        if (open (OU, ">$form->{'owpath'}")) {
            print OU $battlog;
            close (OU);
            $savedpath = $form->{'owpath'};
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/periobattery.htm\">Refresh</a> ";
    print $sock "<a href=\"/periobattery.htm?graphs=\">graphs</a><br>\n";

    print $sock "${battperc}% ${battvolts}V ${batttemp}C ${battmA}mA. ($battcnt) <a href=\"#end\">end</a>\n";


    if (defined ($form->{"graphs"})) {
        $svgperc = '';
        $svgvolt = '';
        $svgtemp = '';
        $svgmA = '';
        $lnno = 0;
        $noln = $battlog =~ s/\n/\n/g;
        foreach $_ (split("\n", $battlog)) {
            if (($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp) 
                = /level=(\d+), vol=(\d+), temp=(\d+), curr=(-*\d+), dis_curr=(\d+), chg_src=(\d+), chg_en=(\d+), over_vchg=(\d+), batt_state=(\d+) at \d+ \((.+? UTC)\)/) {
                $vol /= 1000;
                $temp /= 10;
                if (($yr, $mo, $da, $hr, $mi, $se) = $timestamp =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\./) {
                    # 2013-12-16 14:08:37.807146248 UTC
                    # convert to seconds
                    $yr -= 1900;
                    $mo--;
                    $now = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                    $lnno++;
                    if ((($skip >= 0) && ($lnno >= $skip) && ($lnno <= $skip + $len))  ||
					    # $skip >= 0: skip $skip and plot $len
                        (($skip <  0) && ($lnno > ($noln - $len)))) {
						# $skip < 0: plot last $len
					    # within skip and len (poor man's zoom in)
                        $svgperc .= "$now,$level ";
                        $svgvolt .= "$now,$vol ";
                        $svgtemp .= "$now,$temp ";
                        $tmp = $curr + $dis_curr;
                        $svgmA .= "$now,$tmp ";
                    }
                }
            }
        }
        if ($svgvolt ne '') {
            &l00svg::plotsvg ('battvolt', $svgvolt, $graphwd, $graphht);
            $timestamp =~ s/(\.\d)\d+ UTC/ UTC/g;
            print $sock "<p>$vol V $temp C $tmp mA $timestamp\n";
            print $sock "<p>Volts:<br><a href=\"/svg.htm?graph=battvolt&view=\"><img src=\"/svg.htm?graph=battvolt\" alt=\"voltage over time\"></a>\n";
        }
        if ($svgperc ne '') {
            &l00svg::plotsvg ('battpercentage', $svgperc, $graphwd, $graphht);
            print $sock "<p>Level %:<br><a href=\"/svg.htm?graph=battpercentage&view=\"><img src=\"/svg.htm?graph=battpercentage\" alt=\"level % over time\"></a>\n";
        }
        if ($svgmA ne '') {
            &l00svg::plotsvg ('battmA', $svgmA, $graphwd, $graphht);
            print $sock "<p>mA:<br><a href=\"/svg.htm?graph=battmA&view=\"><img src=\"/svg.htm?graph=battmA\" alt=\"charge/discharge current over time\"></a>\n";
        }
        if ($svgtemp ne '') {
            &l00svg::plotsvg ('batttemp', $svgtemp, $graphwd, $graphht);
            print $sock "<p>Temp:<br><a href=\"/svg.htm?graph=batttemp&view=\"><img src=\"/svg.htm?graph=batttemp\" alt=\"temperature over time\"></a>\n";
        }
    }

    print $sock "<form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec, e.g. 30):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td>Max record length:</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"maxreclen\" value=\"$maxreclen\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"> \n";
    print $sock "         <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"save\" value=\"Save new\"></td>\n";
    $tmp = "$ctrl->{'workdir'}tmp/$ctrl->{'now_string'}_battery.csv";
    $tmp =~ s/ /_/g;
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"savepath\" value=\"$tmp\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"overwrite\" value=\"Overwrite\"></td>\n";
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"owpath\" value=\"$savedpath\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"suspend\" value=\"Save\"></td>\n";
    if (-e "$ctrl->{'workdir'}tmp/l00_periobattery_vals.saved") {
        print $sock "        <td><input type=\"submit\" name=\"resume\" value=\"Resume\"> from sdcard</td>\n";
    } else {
        print $sock "        <td>Not Saved</td>\n";
    }
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    if (length ($savedpath) > 5) {
        #print $sock "Report generator: <a href=\"/rptbattery.htm?path=$savedpath\">$savedpath</a><br>\n";
        $savedpath =~ /^(.+\/)([^\/]+)$/;
        print $sock "Report generator: <a href=\"/ls.htm?path=$1\">$1</a><a href=\"/rptbattery.htm?path=$savedpath\">$2</a><p>\n";
    }
    print $sock "<pre>$lastdmesg$firstdmesg</pre>\n";

    # print table
    $tmp = $tablehdr;
    $lnno = 0;
    $noln = $table =~ s/\n/\n/g;
    foreach $_ (split("\n", $table)) {
        $lnno++;
        if ($lnno < 60) {
            $tmp .= "$_\n";
        } elsif ($lnno == 60) {
            $tmp .= "\nskipping ".($noln - 60 * 2)." lines\n";
            $tmp .= $tablehdr;
        } elsif ($lnno > ($noln - 60)) {
            $tmp .= "$_\n";
        }
    }

    $tmp =~ s/(\.\d)\d+ UTC/ UTC/g;
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $tmp, 0);

    print $sock "<pre>\n";
    $tmp = 0;
    foreach $_ (split("\n", $battlog)) {
        $tmp++;
        if ($tmp < 60) {
            printf $sock ("%3d: $_\n", $tmp);
        } elsif ($tmp == 60) {
            printf $sock ("%3d: $_\n", $tmp);
            print $sock "\nskipping ".($noln - 60 * 2)." lines\n\n";
        } elsif ($tmp > ($noln - 60)) {
            printf $sock ("%3d: $_\n", $tmp);
        }
    }
    print $sock "</pre>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";

    print $sock "<form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"restore\" value=\"Restore\"></td>\n";
    print $sock "        <td>Restore *.saved from *.saved.-.bak</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";


    print $sock "<br><form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"trim\" value=\"Trim\"></td>\n";
    print $sock "        <td>and keep last <input type=\"text\" size=\"6\" name=\"keep\" value=\"$noln\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<br><form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"graphsz\" value=\"Set\"> \n";
    print $sock "        <td>Graph width: <input type=\"text\" size=\"6\" name=\"graphwd\" value=\"$graphwd\">\n";
    print $sock "                 height: <input type=\"text\" size=\"6\" name=\"graphht\" value=\"$graphht\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Skip</td>\n";
    print $sock "        <td>first <input type=\"text\" size=\"6\" name=\"skip\" value=\"$skip\"> points and use up to \n";
    print $sock "        <input type=\"text\" size=\"6\" name=\"len\" value=\"$len\">\n";
    print $sock "        samples. Skip -1 to use record tail.</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";


    print $sock "<p>Lines: $noln. Polls: $battpolls\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periobattery_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($tempe, $bstat, $noln);
    my ($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        $tempe = '';
        if ($ctrl->{'os'} eq 'and') {
            # This SL4A call doesn't work for my Slide:(
            #$tmp = $ctrl->{'droid'}->batteryGetLevel();
            #print $sock "batteryGetLevel $tmp\n";
            #&l00httpd::dumphash ("tmp", $tmp);
            #$tmp = $ctrl->{'droid'}->batteryGetStatus();
            #print $sock "batteryGetStatus $tmp\n";
            #&l00httpd::dumphash ("tmp", $tmp);

            # On Slide, dmesg contains battery status:
            #<6>[ 7765.397493] [BATT] ID=2, level=89, vol=4209, temp=326, curr=-214, dis_curr=0, chg_src=1, chg_en=1, over_vchg=0, batt_state=1 at 7765326083644 (2013-12-11 12:08:08.239292486 UTC)
            $bstat = 'Only my Slide, dmesg contains a line with battery level: [BATT] ID=2, level=89, vol=4209, temp=326... If you see this line, either dmesg did not work, or the line format is different. Contact me to support it.';
            foreach $_ (split("\n", `dmesg`)) {
                if (/\[BATT\] ID=2/) {
                    $bstat = $_;
                }
            }
            if (($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp) 
                 = $bstat =~ /level=(\d+), vol=(\d+), temp=(\d+), curr=(-*\d+), dis_curr=(\d+), chg_src=(\d+), chg_en=(\d+), over_vchg=(\d+), batt_state=(\d+) at \d+ \((.+? UTC)\)/) {
                if ($lasttimestamp ne $timestamp) {
                    $lasttimestamp = $timestamp;
                    $battperc = $level;
                    $battvolts = $vol / 1000;
                    $batttemp = $temp / 10;
                    $battmA = $curr + $dis_curr;
                    $tempe = "$ctrl->{'now_string'}: $bstat\n";
                    $battcnt++;

                    if ($firstdmesg eq '') {
                        $firstdmesg = $tempe;
					}
                    $lastdmesg = $tempe;

                    # populate no save table
                    $chg_src =~ s/0/0\/off/;
                    $chg_src =~ s/1/1\/usb/;
                    $chg_src =~ s/2/2\/wall/;
                    $chg_en =~ s/0/0\/off/;
                    $chg_en =~ s/1/1\/usb/;
                    $chg_en =~ s/2/2\/wall/;
                    $table = "||$battcnt||$level||$vol||$temp||$battmA||$chg_src||$chg_en||$over_vchg||$batt_state||$timestamp||\n" . $table;
                    # trim if too long
                    $noln = $table =~ s/\n/\n/g;
                    while ($noln > $maxreclen) {
                        $table   =~ s/\n.*?$//;   # trim from the end, oldest
                        $noln = $table =~ s/\n/\n/g;
                    }
                }
            }
        }
        if ($perltime != 0) {
            # subsequently
            $battlog .= $tempe;
        } else {
            # first time
            $battlog = $tempe;
        }
        $noln = $battlog =~ s/\n/\n/g;
        while ($noln > $maxreclen) {
            $battlog =~ s/^.*?\n//;   # trim from the start, oldest
            $noln = $battlog =~ s/\n/\n/g;
        }
        $perltime = time;
        $battpolls++;
    }

    $interval;
}


\%config;
