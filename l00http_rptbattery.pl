use strict;
use warnings;
use l00backup;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_rptbattery_proc",
              desc => "l00http_rptbattery_desc");
my ($buffer, $lastbuf, $timeslot, $skip, $len, $taillen, $graphwd, $graphht);
my ($mAAvgLen);
$lastbuf = '';
$timeslot = 60 * 1;
$skip = 0;
$len = 100000;
$taillen = 60;
$graphwd = 500;
$graphht = 300;
$mAAvgLen = 7;

sub l00http_rptbattery_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "rptbattery: periobattery.pl reporter";
}

sub l00http_rptbattery_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $fname, $tmp, $output, $table, $buf);
    my ($lnno, $svgperc, $svgvolt, $svgtemp, $svgmA, $battcnt);
    my ($svgmAAvg, $svgsleep, $svgscr, $scrbrgt);
    my ($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp);
    my ($yr, $mo, $da, $hr, $mi, $se, $now, $fpath, $lastnow);
    my (@svgmAAvgBuf, $mAsum);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }
    if ((defined ($form->{'skip'})) && ($form->{'skip'} =~ /(\d+)/)) {
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
    if ((defined ($form->{'mAAvgLen'})) && ($form->{'mAAvgLen'} =~ /(\d+)/)) {
        $mAAvgLen = $1;
    }
    if ((defined ($form->{'taillen'})) && ($form->{'taillen'} =~ /(\d+)/)) {
        $taillen = $1;
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname rptbattery</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">Jump to end</a><br>\n";
    if (defined ($form->{'path'})) {
        $tmp = $path;
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: ";
        ($fpath, $fname) = $form->{'path'} =~ /(.+\/)([^\/]+)/;
        print $sock "<a href=\"/ls.htm?path=$fpath\">$fpath</a>";
        print $sock "<a href=\"/view.htm?path=$form->{'path'}\">$fname</a>\n";
    }
    print $sock "<a href=\"/periobattery.htm\">periobattery</a><p>\n";


    # get submitted name and print greeting
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $svgperc = '';
        $svgvolt = '';
        $svgtemp = '';
        $svgmA = '';
        $svgmAAvg = '';
        $svgsleep = '';
        $svgscr = '';
        undef @svgmAAvgBuf;
        $lnno = 0;
        $output = "<pre>\n";
        $table = '';
        $lastnow = 0;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/\r//;
            s/\n//;
            $output .= "$_\n";

            if (($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $scrbrgt, $timestamp) 
                = /level=(\d+), vol=(\d+), temp=(\d+), curr=(-*\d+), dis_curr=(\d+), chg_src=(\d+), chg_en=(\d+), over_vchg=(\d+), batt_state=(\d+), scr_brgt=(\d+) at \d+ \((.+? UTC)\)/) {
                $vol /= 1000;
                $temp /= 10;
                if (($yr, $mo, $da, $hr, $mi, $se) = $timestamp =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\./) {
                    # 2013-12-16 14:08:37.807146248 UTC
                    # convert to seconds
                    $yr -= 1900;
                    $mo--;
                    $now = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                    $lnno++;
                    if (($lnno >= $skip) && ($lnno <= $skip + $len)) {
					    # within skip and len (poor man's zoom in)
                        $svgperc .= "$now,$level ";
                        $svgvolt .= "$now,$vol ";
                        $svgtemp .= "$now,$temp ";
                        $tmp = $curr + $dis_curr;
                        $svgmA .= "$now,$tmp ";
                        push (@svgmAAvgBuf, $tmp);
                        if ($#svgmAAvgBuf >= $mAAvgLen) {
                            # trim history buffer to $mAAvgLen
                            shift (@svgmAAvgBuf);
                        }
                        $mAsum = 0;
                        foreach $tmp (@svgmAAvgBuf) {
                            $mAsum += $tmp;
                        }
                        $mAsum /= ($#svgmAAvgBuf + 1);
                        $svgmAAvg .= "$now,$mAsum ";
                        if ($lastnow == 0) {
                            $tmp = 0;
                        } else {
                            $tmp = $now - $lastnow;
                        }
                        $svgsleep .= "$now,$tmp ";
                        $svgscr .= "$now,$scrbrgt ";
                        $lastnow = $now;

                        $chg_src =~ s/0/0 (off)/;
                        $chg_src =~ s/1/1 (usb)/;
                        $chg_src =~ s/2/2 (wall)/;
                        $chg_en =~ s/0/0 (off)/;
                        $chg_en =~ s/1/1 (usb)/;
                        $chg_en =~ s/2/2 (wall)/;
                        $table = "||$lnno||$level||$vol||$temp||$curr||$dis_curr||$chg_src||$chg_en||$over_vchg||$batt_state||$scrbrgt||$timestamp||\n" . $table;
                    }
                }
            }
        }
        $output .= "</pre>\n";
        $table = "||#||level||vol||temp||curr||dis curr||chg src||chg en||over vchg||batt state||$scrbrgt||time stamp||\n" . $table;

        if ($lnno > 1) {
            print $sock "<form action=\"/rptbattery.htm\" method=\"get\">\n";
            print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

            print $sock "    <tr>\n";
            print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Skip\"> \n";
            print $sock "        <td><input type=\"text\" size=\"6\" name=\"skip\" value=\"$skip\"></td>\n";
            print $sock "        <td>length <input type=\"text\" size=\"6\" name=\"len\" value=\"$len\"></td>\n";
            print $sock "    </tr>\n";

            print $sock "</table>\n";
            print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
            print $sock "</form>\n";

            if ($svgperc ne '') {
                &l00svg::plotsvg2 ('battpercentage', $svgperc, $graphwd, $graphht);
                print $sock "<p>$vol V $temp C $tmp mA $timestamp\n";
                print $sock "<p>Level %:<br><a href=\"/svg.htm?graph=battpercentage&view=\"><img src=\"/svg.htm?graph=battpercentage\" alt=\"level % over time\"></a>\n";
            }
            if ($svgsleep ne '') {
                &l00svg::plotsvg2 ('battsleep', $svgsleep, $graphwd, $graphht);
                $timestamp =~ s/(\.\d)\d+ UTC/ UTC/g;
                print $sock "<p>Interval:<br><a href=\"/svg.htm?graph=battsleep&view=\"><img src=\"/svg.htm?graph=battsleep\" alt=\"Interval between batt readings\"></a>\n";
            }
            if ($svgvolt ne '') {
                &l00svg::plotsvg2 ('battvolt', $svgvolt, $graphwd, $graphht);
                $timestamp =~ s/(\.\d)\d+ UTC/ UTC/g;
                print $sock "<p>Volts:<br><a href=\"/svg.htm?graph=battvolt&view=\"><img src=\"/svg.htm?graph=battvolt\" alt=\"voltage over time\"></a>\n";
            }
            if ($svgmA ne '') {
                &l00svg::plotsvg2 ('battmA', $svgmA, $graphwd, $graphht);
                print $sock "<p>mA:<br><a href=\"/svg.htm?graph=battmA&view=\"><img src=\"/svg.htm?graph=battmA\" alt=\"charge/discharge current over time\"></a>\n";
            }
            if ($svgmAAvg ne '') {
                &l00svg::plotsvg2 ('battmAavg', $svgmAAvg, $graphwd, $graphht);
                print $sock "<p>mAavg (len: $mAAvgLen):<br><a href=\"/svg.htm?graph=battmAavg&view=\"><img src=\"/svg.htm?graph=battmAavg\" alt=\"charge/discharge current over time\"></a>\n";
            }
            if ($svgscr ne '') {
                &l00svg::plotsvg2 ('battScr', $svgscr, $graphwd, $graphht);
                print $sock "<p>screen :<br><a href=\"/svg.htm?graph=battScr&view=\"><img src=\"/svg.htm?graph=battScr\" alt=\"screen brightness over time\"></a>\n";
            }
            if ($svgtemp ne '') {
                &l00svg::plotsvg2 ('batttemp', $svgtemp, $graphwd, $graphht);
                print $sock "<p>Temp:<br><a href=\"/svg.htm?graph=batttemp&view=\"><img src=\"/svg.htm?graph=batttemp\" alt=\"temperature over time\"></a>\n";
            }
        }
    }

    print $sock "<p>\n";

    print $sock "<form action=\"/rptbattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"settail\" value=\"Set\"></td>\n";
    print $sock "        <td>Display <input type=\"text\" size=\"4\" name=\"taillen\" value=\"$taillen\"> lines head and tail and skip rest</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form><p>\n";

    $table =~ s/(\.\d)\d+ UTC/ UTC/g;
    $tmp = 0;
    $buf = '';
    foreach $_ (split("\n", $table)) {
        $tmp++;
        if ($tmp < $taillen) {
            $buf .= "$_\n";
        } elsif ($tmp == $taillen) {
            $buf .= "$_\n";
            $buf .= "\nskipping ".($lnno - $taillen * 2)." lines\n\n";
        } elsif ($tmp > ($lnno - $taillen)) {
            $buf .= "$_\n";
        }
    }
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $buf, 0);

    $tmp = 0;
    $buf = '';
    foreach $_ (split("\n", $output)) {
        $tmp++;
        if ($tmp < $taillen) {
            $buf .= "$_\n";
        } elsif ($tmp == $taillen) {
            $buf .= "$_\n";
            $buf .= "\nskipping ".($lnno - $taillen * 2)." lines\n\n";
        } elsif ($tmp > ($lnno - $taillen)) {
            $buf .= "$_\n";
        }
    }
    print $sock "$buf<hr><a href=\"#top\">Jump to top</a>,\n";

    print $sock "<p><form action=\"/rptbattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"graphsz\" value=\"Set\"> \n";
    print $sock "        <td>Graph width: <input type=\"text\" size=\"6\" name=\"graphwd\" value=\"$graphwd\">\n";
    print $sock "                 height: <input type=\"text\" size=\"6\" name=\"graphht\" value=\"$graphht\">\n";
    print $sock "                 mA avg len: <input type=\"text\" size=\"6\" name=\"mAAvgLen\" value=\"$mAAvgLen\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";
    print $sock "<p><a name=\"end\">end</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
