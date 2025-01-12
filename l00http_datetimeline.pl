use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2020/02/04

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_datetimeline_proc",
              desc => "l00http_datetimeline_desc");
my ($yr, $mo, $da, $hr, $mi, $lastdate, $firstdate, $cal);

my @dayofweek = (
'Sun',
'Mon',
'Tue',
'Wed',
'Thu',
'Fri',
'Sat'
);

$lastdate = '';

sub print_travel_plan {
    my ($sock, $path, $lnno, $msg, $msg2) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
        gmtime (&l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0));
    my ($topln, $thisdate, $printdate, $hrline);

    $topln = $lnno - 10;

    if ($firstdate eq '') {
        $firstdate = sprintf ("%04d/%02d/%02d %s %2d:%02d is the starting time\n", 
            $yr, $mo, $da, $dayofweek[$wday], $hr, $mi);
        $firstdate .= "color keys: t - *a*from** -&gt; *S*dest** : remarks / s - *l*place** : remarks / h - *B*hotel** : remarks / r - *h*rest** : remarks\n";
        $firstdate .= "<a href=\"/cal.htm?prewk=0&lenwk=70&today=on&submit=S&path=l00://datetimeline.txt\" target=\"_blank\">calendar</a> - ";
        $firstdate .= "<a href=\"/view.htm?path=l00://dtline_blank.txt\" target=\"_blank\">blank template</a> - ";
        $firstdate .= "<a href=\"/view.htm?path=l00://dtline_org.txt\" target=\"_blank\">original</a> - ";
        $firstdate .= "<a href=\"/view.htm?path=l00://dtline_new.txt\" target=\"_blank\">date updated</a> - ";
        $firstdate .= "<a href=\"/diff.htm?compare=y&width=20&pathold=l00://dtline_org.txt&pathnew=l00://dtline_new.txt\" target=\"_blank\">diff org new</a>\n";
    }

    $thisdate = sprintf ("%02d/%02d %s", $mo, $da, $dayofweek[$wday], );
    if ($thisdate ne $lastdate) {
        $lastdate = $thisdate;
        $printdate = "<font style=\"color:black;background-color:silver\"><strong>$thisdate </strong><\/font>";
        $hrline = "<hr>";
    } else {
        $printdate = '<span>          </span>';
        $hrline = "";
    }

    # t - from - dest : remarks
         if ($msg =~ /^t - +(.+) - +(.+) : +(.+)$/) {
             $msg = "*a*$1** -&gt; *S*$2** : $3";
             $cal .= "$yr/$mo/$da,1,*S*$2**\n";
    # t - from - dest
    } elsif ($msg =~ /^t - +(.+) - +(.+)$/) {
             $msg = "*a*$1** -&gt; *S*$2** ";
             $cal .= "$yr/$mo/$da,1,*S*$2**\n";

    # s - place : remarks
    } elsif ($msg =~ /^s - +(.+?) : +(.+)$/) {
             $msg = "see: *l*$1** : $2";
             $cal .= "$yr/$mo/$da,1,*l*$1**\n";
    # s - place
    } elsif ($msg =~ /^s - +(.+)$/) {
             $msg = "see: *l*$1** ";
             $cal .= "$yr/$mo/$da,1,*l*$1**\n";

    # r - place : remarks
    } elsif ($msg =~ /^r - +(.+?) : +(.+)$/) {
             $msg = "rest *h*$1** : $2";
             $cal .= "$yr/$mo/$da,1,*h*$2**\n";
    # r - place
    } elsif ($msg =~ /^r - +(.+)$/) {
             $msg = "rest *h*$1** ";
             $cal .= "$yr/$mo/$da,1,*h*$1**\n";

    # h - hotel : remarks
    } elsif ($msg =~ /^h - +(.+?) : +(.+)$/) {
             $msg = "hotel: *B*$1** : $2";
             $cal .= "$yr/$mo/$da,1,*B*$1**\n";
    # h - hotel
    } elsif ($msg =~ /^h - +(.+)$/) {
             $msg = "hotel: *B*$1** ";
             $cal .= "$yr/$mo/$da,1,*B*$1**\n";
    # n - notes
    } elsif ($msg =~ /^n - +(.+)$/) {
             $msg = "notes *y*$1** ";
             $cal .= "$yr/$mo/$da,1,*y*$1**\n";
    }

    sprintf ("$hrline%s%2d:%02d  %s %s <a href=\"/edit.htm?path=%s&editline=on&blklineno=%d\" target=\"_blank\">%d</a>\n", 
        $printdate, $hr, $mi, $msg, $msg2, $path, $lnno, $lnno);
}

sub l00http_datetimeline_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " datetimeline: A tool to make date timeline, e.g. fro travel";
}

sub l00http_datetimeline_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($delimiter, $history, $ii, $lastlast, $secondlast, $info);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my ($pname, $fname, $plantime, $phase, $msg, $hours, $html, $lnno);
    my ($dtline_blank, $dtline_org, $dtline_new, $printTimelineTmpl);
    my ($sec2,$mi2,$hr2,$da2,$mo2,$yr2,$wday2,$yday2,$isdst2);

    $dtline_blank = '';
    $dtline_org= '';
    $dtline_new = '';
    $printTimelineTmpl = 1;

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>datetimeline</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    if (defined($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
        print $sock "Path: <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\" target=\"_blank\">$fname</a> - \n";
        print $sock "<a href=\"/datetimeline.htm?path=$form->{'path'}\">refresh</a><p>\n";
    }
    print $sock "<p>\n";

    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        l00httpd::dbp($config{'desc'}, "Scanning $form->{'path'}\n"), if ($ctrl->{'debug'} >= 1);
        $phase = 0;
        $html = '';
        $info = '';
        $cal = '';
        $lnno = 0;
        $firstdate = '';

        $info .= "Searching for \%DATETIMELINE:START\%\n";

        # default to start on this year 1/1
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
        $yr = $year + 1900;
        $mo = $mon + 1;
        $da = 1;

        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $lnno++;

            if (/^\%DATETIMELINE:START\%/) {
                l00httpd::dbp($config{'desc'}, "Found \%DATETIMELINE:START\% tag\n"), if ($ctrl->{'debug'} >= 1);
                $phase = 1;
                $info .= "Found \%DATETIMELINE:START\%\n";
                next;
            }
            if ($phase == 0) {
                next;
            }
            if (/^\%DATETIMELINE:END\%/) {
                l00httpd::dbp($config{'desc'}, "Found \%DATETIMELINE:END\% tag\n"), if ($ctrl->{'debug'} >= 1);
                $info .= "\nFound \%DATETIMELINE:END\%\n";
                last;
            }

            s/\n//g;
            s/\r//g;
            $html .= "                                                      --> $_ ($lnno)\n", if ($ctrl->{'debug'} >= 3);

            # @2020/1/15 13:00
            if      (/^@(\d+)\/(\d+)\/(\d+)/ && ($printTimelineTmpl != 0)) {
                $printTimelineTmpl = 0;
                ($yr, $mo, $da) = ($1, $2, $3);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0);
                ($sec2,$mi2,$hr2,$da2,$mo2,$yr2,$wday2,$yday2,$isdst2) = gmtime ($plantime);
                $dtline_blank .= "# Generating a blank template for 30 days from the start date\n";
                $dtline_blank .= sprintf("\@%d/%d/%d 08:00\n", $yr2 + 1900, $mo2 + 1, $da2);
                $dtline_blank .= sprintf("#%d/%d/%d %s\n", $yr2 + 1900, $mo2 + 1, $da2, $dayofweek[$wday2]);
                $dtline_blank .= "+8              s - where\n";
                $dtline_blank .= "                h - where\n";
                $dtline_blank .= "\n";
                for ($ii = 1; $ii < 30; $ii++) {
                    ($sec2,$mi2,$hr2,$da2,$mo2,$yr2,$wday2,$yday2,$isdst2) = gmtime ($plantime + $ii * 3600 * 24);
                    $dtline_blank .= sprintf("#%d/%d/%d %s\n", $yr2 + 1900, $mo2 + 1, $da2, $dayofweek[$wday2]);
                    $dtline_blank .= "^11:00\n";
                    $dtline_blank .= "+8              s - where\n";
                    $dtline_blank .= "                h - where\n";
                    $dtline_blank .= "\n";
                }
                $dtline_new .= "# current version with updated date/day of week in #\n";
                $dtline_org .= "# original version\n";
            }

            if ($printTimelineTmpl == 0) {
                $dtline_org .= "$_\n";
            }

            if      (/@(\d+)\/(\d+)\/(\d+) +(\d+):(\d+)[ \t]*$/) {
                ($yr, $mo, $da, $hr, $mi) = ($1, $2, $3, $4, $5);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                # print $sock "    ## $_ == $plantime | $year $mon $mday $hour $min\n";
                $html .= "                                                      ".__LINE__." plantime \@year/time $plantime\n", if ($ctrl->{'debug'} >= 3);
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # @1/15 13:00
            } elsif (/@(\d+)\/(\d+) +(\d+):(\d+)[ \t]*$/) {
                ($mo, $da, $hr, $mi) = ($1, $2, $3, $4);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= "                                                      ".__LINE__." plantime \@month/time $plantime\n", if ($ctrl->{'debug'} >= 3);
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # @1/15 13:00 remarks
            } elsif (/@(\d+)\/(\d+) +(\d+):(\d+)[ \t]+(.+)$/) {
                ($mo, $da, $hr, $mi, $msg) = ($1, $2, $3, $4, $5);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= "                                                      ".__LINE__." plantime \@month/time/rem $plantime\n", if ($ctrl->{'debug'} >= 3);
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, '');
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # @2020/1/15
            } elsif (/^@(\d+)\/(\d+)\/(\d+)[ \t]*$/) {
                ($yr, $mo, $da, $hr, $mi) = ($1, $2, $3, 0, 0);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= "                                                      ".__LINE__." plantime \@year $plantime\n", if ($ctrl->{'debug'} >= 3);
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # @1/15
            } elsif (/^@(\d+)\/(\d+)[ \t]*$/) {
                ($mo, $da, $hr, $mi) = ($1, $2, 0, 0, 0);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= "                                                      ".__LINE__." plantime \@month $plantime\n", if ($ctrl->{'debug'} >= 3);
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # @13:00 remarks
            } elsif (/^@(\d+):(\d+)[ \t]+(.+)$/) {
                ($hr, $mi, $msg) = ($1, $2, $3);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= "                                                      ".__LINE__." plantime \@time/rem $plantime\n", if ($ctrl->{'debug'} >= 3);
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, '');
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # @13:00
            } elsif (/^@(\d+):(\d+)[ \t]*$/) {
                ($hr, $mi) = ($1, $2);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= "                                                      ".__LINE__." plantime \@time $plantime\n", if ($ctrl->{'debug'} >= 3);
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # ^13:00 remarks
            } elsif (/^\^(\d+):(\d+)[ \t]+(.+)$/) {
                ($hr, $mi, $msg) = ($1, $2, $3);
               #$html .= "<hr>\n";
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0) + 
                    24 * 3600 + $hr * 3600 + $mi * 60;
                $html .= "                                                      ".__LINE__." plantime ^time/rem $plantime\n", if ($ctrl->{'debug'} >= 3);
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, '');
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= sprintf("#%d/%d/%d %s\n", $yr, $mo, $da, $dayofweek[$wday]);
                    $dtline_new .= "$_\n";
                }
            # ^13:00
            } elsif (/^\^(\d+):(\d+)[ \t]*$/) {
               #$html .= "<hr>\n";
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0) + 
                    24 * 3600 + $1 * 3600 + $2 * 60;
                $html .= "                                                      ".__LINE__." plantime ^time $plantime\n", if ($ctrl->{'debug'} >= 3);
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= sprintf("#%d/%d/%d %s\n", $yr, $mo, $da, $dayofweek[$wday]);
                    $dtline_new .= "$_\n";
                }
            # +13 remarks
            } elsif (/^\+([.0-9]+)[ \t]+(.+)$/) {
                ($hours, $msg) = ($1, $2);
                # +(real number hours)
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, "*s*$hours hours**");
                $plantime += $hours * 3600;
                $html .= "                                                      ".__LINE__." plantime +time/rem $plantime\n", if ($ctrl->{'debug'} >= 3);
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # +13
            } elsif (/^\+([.0-9]+)/) {
                # +(real number hours)
                $plantime += $1 * 3600;
                $html .= "                                                      ".__LINE__." plantime +time $plantime\n", if ($ctrl->{'debug'} >= 3);
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # ---
            } elsif (/^---/) {
               #$html .= "<hr>\n";
            # !remarks
            } elsif (/^!(.*)$/) {
                $html .= "$1\n";
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            # everything else except # comments
            } elsif (/^[^#]/) {
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
                s/^ +//;
                if (!/^ *$/) {
                    $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $_, '');
                }
            } else {
                $html .= "                                                      ^^^ NO MATCHES FOUND\n", if ($ctrl->{'debug'} >= 3);
                if ($printTimelineTmpl == 0) {
                    $dtline_new .= "$_\n";
                }
            }
        }

        $html = "<pre>$firstdate\n\n$html</pre>\n$info";

        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $html, 0, $fname);

        &l00httpd::l00fwriteOpen($ctrl, "l00://datetimeline.txt");
        &l00httpd::l00fwriteBuf($ctrl, $cal);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00fwriteOpen($ctrl, "l00://dtline_blank.txt");
        &l00httpd::l00fwriteBuf($ctrl, $dtline_blank);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00fwriteOpen($ctrl, "l00://dtline_org.txt");
        &l00httpd::l00fwriteBuf($ctrl, $dtline_org);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00fwriteOpen($ctrl, "l00://dtline_new.txt");
        &l00httpd::l00fwriteBuf($ctrl, $dtline_new);
        &l00httpd::l00fwriteClose($ctrl);
    } else {
        print $sock "Unable to open '$form->{'path'}'<p>\n";
    }



    # send HTML footer and ends
    if (defined ($ctrl->{'FOOT'})) {
        print $sock "<p><a name=\"__end__\"></a><a href=\"#__top__\">Jump to top</a><br>$ctrl->{'FOOT'}\n";
    }
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
