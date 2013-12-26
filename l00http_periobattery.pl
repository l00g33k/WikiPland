use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $battlog, $battcnt, $battpolls, $perltime);
my %config = (proc => "l00http_periobattery_proc",
              desc => "l00http_periobattery_desc",
              perio => "l00http_periobattery_perio");
my ($savedpath, $battperc, $battvolts, $batttemp, $battmA, $lasttimestamp);
my ($table, $tablehdr, $firstdmesg, $lastdmesg);
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

sub l00http_periobattery_suspend {
    my ($ctrl) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket

    # suspend to sdcard so it can be resumed after restart
    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_vals.saved");
    &l00httpd::l00fwriteBuf($ctrl, "interval=$interval\n");
    &l00httpd::l00fwriteBuf($ctrl, "battcnt=$battcnt\n");
    &l00httpd::l00fwriteBuf($ctrl, "battpolls=$battpolls\n");
    &l00httpd::l00fwriteBuf($ctrl, "savedpath=$savedpath\n");
    &l00httpd::l00fwriteBuf($ctrl, "perltime=$perltime\n");
    &l00httpd::l00fwriteBuf($ctrl, "firstdmesg=$firstdmesg");
    &l00httpd::l00fwriteBuf($ctrl, "lastdmesg=$lastdmesg");
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}del/l00_periobattery_vals.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_battlog.saved");
    &l00httpd::l00fwriteBuf($ctrl, $battlog);
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}del/l00_periobattery_battlog.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_table.saved");
    &l00httpd::l00fwriteBuf($ctrl, $table);
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}del/l00_periobattery_table.saved'<p>\n";
    }

    l00httpd::dbp($config{'desc'}, "Suspend to sdcard:\n");
    l00httpd::dbp($config{'desc'}, "interval=$interval\n");
    l00httpd::dbp($config{'desc'}, "battcnt=$battcnt\n");
    l00httpd::dbp($config{'desc'}, "battpolls=$battpolls\n");
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
    if (&l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_vals.saved")) {
        $interval = 0;
        $battcnt = 0;
        $battlog = '';
        $battpolls = 0;
        $savedpath = '';
        $firstdmesg = '';
        $lastdmesg = '';
        $table = '';

        $_ = &l00httpd::l00freadLine($ctrl);
        ($interval) = /interval=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($battcnt) = /battcnt=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($battpolls) = /battpolls=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        if (!(($savedpath) = /savedpath=(.+)/)) {
            $savedpath = '';
        }
        $_ = &l00httpd::l00freadLine($ctrl);
        ($perltime) = /perltime=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($firstdmesg) = /firstdmesg=(.+)/;
        $firstdmesg .= "\n";
        $_ = &l00httpd::l00freadLine($ctrl);
        ($lastdmesg) = /lastdmesg=(.+)/;
        $lastdmesg .= "\n";

        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_battlog.saved");
        $battlog = &l00httpd::l00freadAll($ctrl);
        if (!defined($battlog)) {
            $battlog = '';
        }

        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_table.saved");
        $table = &l00httpd::l00freadAll($ctrl);
        if (!defined($table)) {
            $table = '';
        }

        l00httpd::dbp($config{'desc'}, "Resumed from sdcard:\n");
        l00httpd::dbp($config{'desc'}, "interval=$interval\n");
        l00httpd::dbp($config{'desc'}, "battcnt=$battcnt\n");
        l00httpd::dbp($config{'desc'}, "battpolls=$battpolls\n");
        l00httpd::dbp($config{'desc'}, "savedpath=$savedpath\n");
        l00httpd::dbp($config{'desc'}, "perltime=$perltime\n");
        l00httpd::dbp($config{'desc'}, "firstdmesg=$firstdmesg");
        l00httpd::dbp($config{'desc'}, "lastdmesg=$lastdmesg");
        l00httpd::dbp($config{'desc'}, "battlog:\n");
        l00httpd::dbp($config{'desc'}, $battlog);
        l00httpd::dbp($config{'desc'}, "table:\n");
        l00httpd::dbp($config{'desc'}, $table);

        # delete .saved once resumed
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_vals.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_vals.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_battlog.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_battlog.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_table.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}del/l00_periobattery_table.saved");
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
    my ($tmp);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"suspend"})) {
        &l00http_periobattery_suspend($ctrl);
    }
    if (defined ($form->{"resume"})) {
        &l00http_periobattery_resume($ctrl);
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
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/periobattery.htm\">Refresh</a><br>\n";

    print $sock "${battperc}% ${battvolts}V ${batttemp}C ${battmA}mA. ($battcnt) <a href=\"#end\">end</a>\n";

    print $sock "<form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec, e.g. 30):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
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
    $tmp = "$ctrl->{'workdir'}del/$ctrl->{'now_string'}_battery.csv";
    $tmp =~ s/ /_/g;
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"savepath\" value=\"$tmp\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"overwrite\" value=\"Overwrite\"></td>\n";
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"owpath\" value=\"$savedpath\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"suspend\" value=\"Save\"></td>\n";
    if (-e "$ctrl->{'workdir'}del/l00_periobattery_vals.saved") {
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
    $tmp = $tablehdr . $table;
    $tmp =~ s/(\.\d)\d+ UTC/ UTC/g;
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $tmp, 0);

    print $sock "<pre>\n";
    $tmp = 0;
    foreach $_ (split("\n", $battlog)) {
        $tmp++;
        if ($tmp < 100) {
            printf $sock ("%3d: $_\n", $tmp);
        } elsif ($tmp == 100) {
            printf $sock ("%3d: $_\n", $tmp);
            print $sock "\nskipping ".($battcnt - 100 * 2)." lines\n\n";
        } elsif ($tmp > ($battcnt - 100)) {
            printf $sock ("%3d: $_\n", $tmp);
        }
    }
    print $sock "</pre>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";
    print $sock "<p>Lines: $battcnt. Polls: $battpolls\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periobattery_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($tempe, $bstat);
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
        $perltime = time;
        $battpolls++;
    }

    $interval;
}


\%config;
