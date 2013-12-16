use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_rptbattery_proc",
              desc => "l00http_rptbattery_desc");
my ($buffer, $lastbuf, $timeslot);
$lastbuf = '';
$timeslot = 60 * 1;

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
    my ($path, $fname, $tmp, $output, $table);
    my ($lnno, $svgperc, $svgvolt, $svgtemp, $svgmA, $battcnt);
    my ($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp);
    my ($yr, $mo, $da, $hr, $mi, $se, $now);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname rptbattery</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> <a href=\"#end\">Jump to end</a><br>\n";
    if (defined ($form->{'path'})) {
        $tmp = $path;
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: ";
        print $sock "<a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }


    # get submitted name and print greeting
    if (open (IN, "<$form->{'path'}")) {
        $svgperc = '';
        $svgvolt = '';
        $svgtemp = '';
        $svgmA = '';
        $lnno = 0;
        $output = "<pre>\n";
        $table = '';
        while (<IN>) {
            s/\r//;
            s/\n//;
            $output .= "$_\n";

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
                    $svgperc .= "$now,$level ";
                    $svgvolt .= "$now,$vol ";
                    $svgtemp .= "$now,$temp ";
                    $tmp = $curr + $dis_curr;
                    $svgmA .= "$now,$tmp ";
                    $lnno++;

                    $chg_src =~ s/0/0 (off)/;
                    $chg_src =~ s/1/1 (usb)/;
                    $chg_src =~ s/2/2 (wall)/;
                    $chg_en =~ s/0/0 (off)/;
                    $chg_en =~ s/1/1 (usb)/;
                    $chg_en =~ s/2/2 (wall)/;
                    $table = "||$lnno||$level||$vol||$temp||$curr||$dis_curr||$chg_src||$chg_en||$over_vchg||$batt_state||$timestamp||\n" . $table;
                }
            }
        }
        $output .= "</pre>\n";
        $table = "||#||level||vol||temp||curr||dis curr||chg src||chg en||over vchg||batt state||time stamp||\n" . $table;
        close (IN);

        if ($lnno > 1) {
            if ($svgperc ne '') {
                &l00svg::plotsvg ('battpercentage', $svgperc, 500, 300);
                print $sock "<p>Level %:<br><a href=\"/svg.htm?graph=battpercentage&view=\"><img src=\"/svg.htm?graph=battpercentage\" alt=\"alt\"></a>\n";
            }
            if ($svgvolt ne '') {
                &l00svg::plotsvg ('battvolt', $svgvolt, 500, 300);
                print $sock "<p>Volts:<br><a href=\"/svg.htm?graph=battvolt&view=\"><img src=\"/svg.htm?graph=battvolt\" alt=\"alt\"></a>\n";
            }
            if ($svgtemp ne '') {
                &l00svg::plotsvg ('batttemp', $svgtemp, 500, 300);
                print $sock "<p>Temp:<br><a href=\"/svg.htm?graph=batttemp&view=\"><img src=\"/svg.htm?graph=batttemp\" alt=\"alt\"></a>\n";
            }
            if ($svgmA ne '') {
                &l00svg::plotsvg ('battmA', $svgmA, 500, 300);
                print $sock "<p>mA:<br><a href=\"/svg.htm?graph=battmA&view=\"><img src=\"/svg.htm?graph=battmA\" alt=\"alt\"></a>\n";
            }
        }
    }

    print $sock "<p>\n";
    $table =~ s/(\.\d)\d+ UTC/ UTC/g;
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $table, 0);

    print $sock "$output<hr><a href=\"#top\">Jump to top</a>,\n";
    print $sock "<p><a name=\"end\">end</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
