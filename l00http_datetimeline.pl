use strict;
use warnings;

# test
<<CMT;
%DATETIMELINE:START%
# comment
\@5/8
\@8:30

\@5/9
\@8:30   depart
+4      driving
        hotel checkin
+1      unpack
+3      dinner
        internet
\@23:00  sleep

^11:00  hotel checkout
+1      food
+4      drive
        checkin

@2020/6/8

%DATETIMELINE:END%
CMT


# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_datetimeline_proc",
              desc => "l00http_datetimeline_desc");
my ($yr, $mo, $da, $hr, $mi, $lastdate, $firstdate);

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
    my ($sock, $path, $lnno, $msg) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
        gmtime (&l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0));
    my ($topln, $thisdate, $printdate);

#    printf $sock ("%04d/%02d/%02d %2d:%02d %s: %s\n", $yr, $mo, $da, $hr, $mi, $dayofweek[$wday], $msg);

#print $sock "date ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)\n";
#    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
#        gmtime (time);
#print $sock "time ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)\n";

    $topln = $lnno - 10;

    if ($firstdate eq '') {
        $firstdate = sprintf ("%04d/%02d/%02d %s %2d:%02d is the starting time", 
            $yr, $mo, $da, $dayofweek[$wday], $hr, $mi);
    }

    $thisdate = sprintf ("%02d/%02d %s", $mo, $da, $dayofweek[$wday], );
    if ($thisdate ne $lastdate) {
        $lastdate = $thisdate;
        $printdate = $thisdate;
    } else {
        $printdate = '         ';
    }

    sprintf ("%s %2d:%02d: %s <a href=\"/view.htm?path=%s&hiliteln=%d&lineno=on#line%d\" target=\"_blank\">(%d)</a>\n", 
        $printdate, $hr, $mi, $msg, $path, $lnno, $topln, $lnno);
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
        print $sock "<a href=\"/view.htm?path=$form->{'path'}\" target=\"_blank\">$fname</a><p>\n";
    }
    print $sock "<p>\n";

    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $phase = 0;
        $html = '';
        $info = '';
        $lnno = 0;
        $firstdate = '';

        $info .= "Searching for \%DATETIMELINE:START\%<br>\n";

        # default to start on this year 1/1
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
        $yr = $year + 1900;
        $mo = $mon + 1;
        $da = 1;

        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $lnno++;

            if (/^\%DATETIMELINE:START\%/) {
                $phase = 1;
                $info .= "Found \%DATETIMELINE:START\%<br>\n";
                next;
            }
            if ($phase == 0) {
                next;
            }
            if (/^\%DATETIMELINE:END\%/) {
                $info .= "\nFound \%DATETIMELINE:END\%<br>\n";
                last;
            }

            s/\n//g;
            s/\r//g;
            $html .= "                                                      --> $_\n", if ($ctrl->{'debug'} >= 3);

                 if (/@(\d+)\/(\d+)\/(\d+) +(\d+):(\d+)$/) {
                ($yr, $mo, $da, $hr, $mi) = ($1, $2, $3, $4, $5);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";
            } elsif (/@(\d+)\/(\d+) +(\d+):(\d+)$/) {
                ($mo, $da, $hr, $mi) = ($1, $2, $3, $4);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";
            } elsif (/@(\d+)\/(\d+) +(\d+):(\d+) +(.+)$/) {
                ($mo, $da, $hr, $mi, $msg) = ($1, $2, $3, $4, $5);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";

            } elsif (/^@(\d+)\/(\d+)\/(\d+)$/) {
                ($yr, $mo, $da, $hr, $mi) = ($1, $2, $3, 0, 0);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";
            } elsif (/^@(\d+)\/(\d+)$/) {
                ($mo, $da, $hr, $mi) = ($1, $2, 0, 0, 0);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";
            } elsif (/^@(\d+):(\d+) +(.+)$/) {
                ($hr, $mi, $msg) = ($1, $2, $3);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";

            } elsif (/^@(\d+):(\d+)$/) {
                ($hr, $mi) = ($1, $2);
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, $hr, $mi, 0);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";

            } elsif (/^\^(\d+):(\d+) +(.+)$/) {
                ($hr, $mi, $msg) = ($1, $2, $3);
                $html .= "<hr>\n";
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0) + 
                    24 * 3600 + $hr * 3600 + $mi * 60;
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $msg);
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";

            } elsif (/^\^(\d+):(\d+)$/) {
                $html .= "<hr>\n";
                $plantime = &l00mktime::mktime ($yr - 1900, $mo - 1, $da, 0, 0, 0) + 
                    24 * 3600 + $1 * 3600 + $2 * 60;
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";

           } elsif (/^\+([.0-9]+) +(.+)$/) {
               ($hours, $msg) = ($1, $2);
               # +(real number hours)
               $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, "$msg -- *s*$hours hours**");
               $plantime += $hours * 3600;
               ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
               $yr += 1900;
               $mo++;
#                                                                            ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
#                                                                            print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";
            } elsif (/^\+([.0-9]+)/) {
                # +(real number hours)
                $plantime += $1 * 3600;
                ($sec,$mi,$hr,$da,$mo,$yr,$wday,$yday,$isdst) = gmtime ($plantime);
                $yr += 1900;
                $mo++;
                                                                            # ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($plantime);
                                                                            # print $sock "                                                          ## $_ == $plantime | $year $mon $mday $hour $min\n";
            } elsif (/^---/) {
                $html .= "<hr>\n";
            } elsif (/^!(.*)$/) {
                $html .= "$1\n";
            } elsif (/^[^#]/) {
                s/^ +//;
                if (!/^ *$/) {
                    $html .= print_travel_plan ($sock, $form->{'path'}, $lnno, $_);
                }
               #printf $sock ("%04d/%02d/%02d %2d:%02d: %s\n", $yr, $mo, $da, $hr, $mi, $_);
            }
        }

        $html = "<pre>$firstdate\n\n$html</pre>\n$info";

        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $html, 0, $fname);
    } else {
        print $sock "Unable to open '$form->{'path'}'<p>\n";
    }



    # send HTML footer and ends
    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
