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
        $firstdate .= "<a href=\"/cal.htm?prewk=0&lenwk=70&today=on&submit=S&path=l00://datetimeline.txt\" target=\"_blank\">calendar</a>\n";
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
                $phase = 1;
                $info .= "Found \%DATETIMELINE:START\%\n";
                next;
            }
            if ($phase == 0) {
                next;
            }
            if (/^\%DATETIMELINE:END\%/) {
                $info .= "\nFound \%DATETIMELINE:END\%\n";
                last;
            }

            s/\n//g;
            s/\r//g;
            $html .= "                                                      --> $_\n", if ($ctrl->{'debug'} >= 3);

            # @2020/1/15 13:00
                 if (/@(\d+)\/(\d+)\/(\d+) +(\d+):(\d+) *$/) {
                ($yr, $mo, $da, $hr, $mi) = ($1, $2, $3, $4, $5);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                # print $sock "    ## $_ == $plantime | $year $mon $mday $hour $min\n";
            # @1/15 13:00
            } elsif (/@(\d+)\/(\d+) +(\d+):(\d+) *$/) {
                ($mo, $da, $hr, $mi) = ($1, $2, $3, $4);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
            # @1/15 13:00 remarks
            } elsif (/@(\d+)\/(\d+) +(\d+):(\d+) +(.+)$/) {
                ($mo, $da, $hr, $mi, $msg) = ($1, $2, $3, $4, $5);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, '');
            # @2020/1/15
            } elsif (/^@(\d+)\/(\d+)\/(\d+) *$/) {
                ($yr, $mo, $da, $hr, $mi) = ($1, $2, $3, 0, 0);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
            # @1/15
            } elsif (/^@(\d+)\/(\d+) *$/) {
                ($mo, $da, $hr, $mi) = ($1, $2, 0, 0, 0);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
            # @13:00 remarks
            } elsif (/^@(\d+):(\d+) +(.+)$/) {
                ($hr, $mi, $msg) = ($1, $2, $3);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, '');
            # @13:00
            } elsif (/^@(\d+):(\d+) *$/) {
                ($hr, $mi) = ($1, $2);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
            # ^13:00 remarks
            } elsif (/^\^(\d+):(\d+) +(.+)$/) {
                ($hr, $mi, $msg) = ($1, $2, $3);
#               $html .= "<hr>\n";
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0) + 
                    24 * 3600 + $hr * 3600 + $mi * 60;
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, '');
            # ^13:00
            } elsif (/^\^(\d+):(\d+) *$/) {
#               $html .= "<hr>\n";
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0) + 
                    24 * 3600 + $1 * 3600 + $2 * 60;
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
            # +13 remarks
            } elsif (/^\+([.0-9]+) +(.+)$/) {
               ($hours, $msg) = ($1, $2);
               # +(real number hours)
               $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg, "*s*$hours hours**");
               $plantime += $hours * 3600;
               ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
               $yr += 1900;
               $mo++;
            # +13
            } elsif (/^\+([.0-9]+)/) {
                # +(real number hours)
                $plantime += $1 * 3600;
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
            # ---
            } elsif (/^---/) {
#               $html .= "<hr>\n";
            # !remarks
            } elsif (/^!(.*)$/) {
                $html .= "$1\n";
            # everything else except # comments
            } elsif (/^[^#]/) {
                s/^ +//;
                if (!/^ *$/) {
                    $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $_, '');
                }
            }
        }

        $html = "<pre>$firstdate\n\n$html</pre>\n$info";

        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $html, 0, $fname);

        &l00httpd::l00fwriteOpen($ctrl, "l00://datetimeline.txt");
        &l00httpd::l00fwriteBuf($ctrl, $cal);
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
