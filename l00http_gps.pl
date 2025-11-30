use strict;
use warnings;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($lastcalled, $percnt, $thislog, $lastout);
my ($known0loc1, $knost, $locst, $lastres, $datename, $fname);
my %config = (proc => "l00http_gps_proc",
              desc => "l00http_gps_desc",
              perio => "l00http_gps_perio");
my ($interval, $trkhdr, $wake, $lastcoor, $toast, $nexttoast);
my ($lon, $lat, $lastgps, $lastpoll);
my ($dup, $dolog, $context);
$lon = 0;
$lat = 0;
$interval = 0;
$lastcalled = 0;
$percnt = 0;
$thislog = '';
$lastout = '';
$known0loc1 = 0;
$lastres = '';
$lastgps = 0;
$lastpoll = 0;
$wake = 0;
$lastcoor = '';
$dup = 0;
$dolog = 1;
$context = 20;
$toast = 0;
$nexttoast = 0xffffffff;
$datename = 0;
$fname = 'gps.trk';


$trkhdr = "\nH  LATITUDE    LONGITUDE    DATE      TIME     ALT    ;track\n";
my $filhdr = 
"H  SOFTWARE NAME & VERSION\n".
"I  PCX5 2.09\n".
"\n".
"H  R DATUM                IDX DA            DF            DX            DY            DZ\n".
"M  G WGS 84               121 +0.000000e+00 +0.000000e+00 +0.000000e+00 +0.000000e+00 +0.000000e+00\n".
"\n".
"H  COORDINATE SYSTEM\n".
"U  LAT LON DM\n";





sub l00http_gps_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "gps: Capture Garmin format track.  Click and change 'Run interval' to non zero";
}


sub l00http_gps_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, @countinglines, $out);

    $out = '';
    if (!defined($ctrl->{'gpsdir'})) {
        # if not defined
        $ctrl->{'gpsdir'} = $ctrl->{'workdir'};
    }

    if (defined ($form->{'stop'})) {
        $interval = 0;
        $lastcalled = 0;    # forces immediate periodic action
        $toast = 0;
        $nexttoast = 0xffffffff;
        if ($ctrl->{'os'} eq 'and') {
            $ctrl->{'droid'}->stopLocating();
            if ($wake != 0) {
                $wake = 0;
                $ctrl->{'droid'}->wakeLockRelease();
            }
        }
    } elsif (defined ($form->{'submit'})) {
        if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'known')) {
            $known0loc1 = 0;
        }
        if (defined ($form->{'mode'}) && ($form->{'mode'} eq 'loc')) {
            $known0loc1 = 1;
        }
        if (defined ($form->{'dup'}) && ($form->{'dup'} eq 'on')) {
            $dup = 1;
        } else {
            $dup = 0;
        }
        if (defined ($form->{'datename'}) && ($form->{'datename'} eq 'on')) {
            $datename = 1;
        } else {
            $datename = 0;
        }
        if (defined ($form->{'toast'}) && ($form->{'toast'} =~ /(\d+)/)) {
            $toast = $1;
        } else {
            $toast = 0;
        }
        if (defined ($form->{'dolog'}) && ($form->{'dolog'} eq 'on')) {
            # no logging checked
            $dolog = 0;
        } else {
            $dolog = 1;
        }
        # get submitted name and print greeting
        if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
            $interval = $form->{"interval"};
            $lastcalled = 0;    # forces immediate periodic action
            if ($toast > 0) {
                $nexttoast = 0;    # force first time
            }

            if ($interval > 0) {
                if ($ctrl->{'os'} eq 'and') {
                    if (defined ($form->{"wake"}) && ($form->{"wake"} eq 'on')) {
                        if ($wake == 0) {
                            $wake = 1;
                            $ctrl->{'droid'}->wakeLockAcquirePartial();
                        }
                    } else {
                        if ($wake != 0) {
                            $wake = 0;
                            $ctrl->{'droid'}->wakeLockRelease();
                        }
                    }
                }
                if (($known0loc1 == 1) && ($ctrl->{'os'} eq 'and')) {
                    $ctrl->{'droid'}->startLocating ($interval * 1000, 1);
                }
                if ($dolog) {
                    if ($datename) {
                        $fname = 'gps_' . 
                            substr($ctrl->{'now_string'}, 0, 8) . '.trk';
                    } else {
                        $fname = 'gps.trk';
                    }
                    $ctrl->{'gpsfname'} = $fname;
                    if (-f "$ctrl->{'gpsdir'}$fname") {
                        # exist
                        open (OUT, ">>$ctrl->{'gpsdir'}$fname");
                    } else {
                        # does not exist
                        open (OUT, ">$ctrl->{'gpsdir'}$fname");
                        print OUT "$filhdr\n";
                    }
                    print OUT "$trkhdr\n";
                    close (OUT);
                }
            } else {
                if ($ctrl->{'os'} eq 'and') {
                    $ctrl->{'droid'}->stopLocating();
                    if ($wake != 0) {
                        $wake = 0;
                        $ctrl->{'droid'}->wakeLockRelease();
                    }
                }
            }
        }
    } elsif (defined ($form->{"markloc"})) {
        if (!defined ($form->{"locremark"})) {
            $form->{"locremark"} = '';
	    }
        if ($ctrl->{'os'} eq 'and') {
            ($out, $lat, $lon, $lastcoor, $lastgps, $lastres)
                = &l00httpd::android_get_gps ($ctrl, $known0loc1, $lastgps);
            open (OUT, ">>$ctrl->{'gpsdir'}gps.way");
			print OUT "$lat,$lon $form->{'locremark'} $buf\n";
			close(OUT);
        } elsif ($ctrl->{'os'} eq 'tmx') {
            ($out, $lat, $lon, $lastcoor, $lastgps, $lastres)
                = &l00httpd::android_get_gps ($ctrl, $known0loc1, $lastgps);
            l00httpd::dbp($config{'desc'}, "got lat,lon $lat,$lon, $lastgps\n"), if ($ctrl->{'debug'} >= 5);
        }
    } elsif (defined ($form->{"getgps"})) {
        if ($ctrl->{'os'} eq 'and') {
            ($out, $lat, $lon, $lastcoor, $lastgps, $lastres)
                = &l00httpd::android_get_gps ($ctrl, $known0loc1, $lastgps);
            l00httpd::dbp($config{'desc'}, "got lat,lon $lat,$lon, $lastgps\n"), if ($ctrl->{'debug'} >= 5);
        } elsif ($ctrl->{'os'} eq 'tmx') {
            ($out, $lat, $lon, $lastcoor, $lastgps, $lastres)
                = &l00httpd::android_get_gps ($ctrl, $known0loc1, $lastgps);
            l00httpd::dbp($config{'desc'}, "got lat,lon $lat,$lon, $lastgps\n"), if ($ctrl->{'debug'} >= 5);
        }
        &l00httpd::l00setCB($ctrl, "$lat,$lon $ctrl->{'now_string'}");
    }
    if ($datename) {
        $fname = 'gps_' . 
            substr($ctrl->{'now_string'}, 0, 8) . '.trk';
    } else {
        $fname = 'gps.trk';
    }
    $ctrl->{'gpsfname'} = $fname;


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} - <a href=\"/gps.htm\">Refresh</a> -  $ctrl->{'HOME'} - ";
    print $sock "<a href=\"/view.htm?path=$ctrl->{'gpsdir'}$fname\">view log</a> - \n";
    print $sock "<a href=\"#mark\">mark</a> - \n";
    print $sock "<a href=\"#end\">Jump to end</a><br>\n";
    print $sock "<a name=\"top\"></a>\n";
 
    print $sock "<form action=\"/gps.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Interval (sec):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "        </tr>\n";
 
    if ($known0loc1 == 0) {
        $knost = "checked";
        $locst = "unchecked";
    } else {
        $knost = "unchecked";
        $locst = "checked";
    }
    print $sock "    <tr>\n";
    print $sock "        <td>".
      "<input type=\"radio\" name=\"mode\" value=\"known\" $knost>Last<br>".
      "<input type=\"radio\" name=\"mode\" value=\"loc\"   $locst>Loc<br>".
      "</td>\n";
    print $sock "        <td>GetLastKnownLocation<br>ReadLocation</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    if ($wake) {
        $buf = 'checked';
    } else {
        $buf = '';
    }
    print $sock "        <td><input type=\"checkbox\" name=\"wake\" $buf>Wake</td>\n";
    print $sock "        <td>Keep partial wake lock</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"stop\" value=\"Stop\"> Note: when phone sleeps, interval may be much longer than specified</td>\n";
    print $sock "    </tr>\n";

    if ($datename) {
        $buf = 'checked';
    } else {
        $buf = '';
    }
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"datename\" $buf>date name</td>\n";
    print $sock "        <td>Filename=gps_(date).trk (otherwise=gps.trk)</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";

    if ($dup) {
        $buf = 'checked';
    } else {
        $buf = '';
    }
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"dup\" $buf>Dup</td>\n";
    print $sock "        <td>Include duplicated coordinates</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";

    if ($dolog) {
        $buf = '';
    } else {
        $buf = 'checked';
    }
    print $sock "        <td><input type=\"checkbox\" name=\"dolog\" $buf>No logging</td>\n";
    print $sock "        <td>Check to prevent writing to log file $fname</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Toast MPH</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"toast\" value=\"$toast\"> at seconds interval. 0 disables.</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";


    print $sock "<p><a name=\"mark\"><form action=\"/gps.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"getgps\" value=\"Get GPS\"></td>\n";
    print $sock "        <td>pasted to clipboard ($lastcoor)</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<a name=\"mark\"></a>\n";
    print $sock "<p>Mark current location in ";
    print $sock "<a href=\"/view.htm?path=$ctrl->{'gpsdir'}gps.way\">$ctrl->{'gpsdir'}gps.way</a>:\n";
    print $sock "<form action=\"/gps.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"markloc\" value=\"Mark\"></td>\n";
    print $sock "        <td><input type=\"text\" size=\"12\" name=\"locremark\" value=\"\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";


    print $sock "<pre>", time - $lastgps, "s ago last GPS. ";
    print $sock time - $lastpoll, "s ago last poll\n";
    print $sock "$lastres$out</pre>\n";
    print $sock "Count: $percnt<br>\n";

#    print $sock "<pre>$thislog</pre><p>\n";
    # print first 30 and last 30 lines of GPS log
    print $sock "<pre>\n";
    undef @countinglines;
    foreach $_ (split("\n", $thislog)) {
        push (@countinglines, $_);
    }
    for ($_ = 0; $_ <= $#countinglines; $_++) {
        if ($_ < $context) {
            print $sock "$countinglines[$_]\n";
        } elsif ($_ > ($#countinglines - $context)) {
            print $sock "$countinglines[$_]\n";
        } elsif ($_ == $context) {
            print $sock "\nskipping ",$#countinglines - $context * 2," lines\n\n";
        }
    }
    print $sock "</pre><p>\n";

    print $sock "launcher <a href=\"/ls.htm?path=$ctrl->{'gpsdir'}\">$ctrl->{'gpsdir'}</a>";
    print $sock "<a href=\"/launcher.htm?path=$ctrl->{'gpsdir'}$fname\">$fname</a><p>\n";

    print $sock "<a name=\"end\"></a><p>\n";
    print $sock "<a href=\"#top\">Jump to top</a><p>\n";

 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_gps_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($out, $brightness, $retval);

    $retval = 0x7fffffff;

    $lastpoll = time;
    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $retval = $interval;

        if ((((time - $lastpoll) <= $interval) ||
            ($lastcalled == 0)) &&
            (!defined($ctrl->{'iamsleeping'}) ||
             ($ctrl->{'iamsleeping'} ne 'yes'))
            ) {
            # polling could be more frequent than the period
            # e.g. running period.pl
            # if we slept for longer, the phone might be sleeping,
            # during which it is not safe(?) to make socket JSON call
            # as the phone might (?, will?) during the call?
            ($out, $lat, $lon, $lastcoor, $lastgps, $lastres)
                = &l00httpd::android_get_gps ($ctrl, $known0loc1, $lastgps);
            if ($out ne '') {
                if (($dup == 1) || ($out ne $lastout)) {
                    if ($dolog) {
                        if ($datename) {
                            $fname = 'gps_' . 
                                substr($ctrl->{'now_string'}, 0, 8) . '.trk';
                        } else {
                            $fname = 'gps.trk';
                        }
                        $ctrl->{'gpsfname'} = $fname;
                        if (-f "$ctrl->{'gpsdir'}$fname") {
                            # exist
                            open (OUT, ">>$ctrl->{'gpsdir'}$fname");
                        } else {
                            # does not exist
                            open (OUT, ">$ctrl->{'gpsdir'}$fname");
                            print OUT "$filhdr\n";
                            print OUT "$trkhdr\n";
                        }
                        printf OUT "$out\n";
                        close (OUT);
                    }
                    $thislog .= "$out\n";
                    $lastout = $out;
                    # toast mph
                    if (($toast > 0) &&
                        ($nexttoast <= $lastpoll)) {
# * x 30 == ' ' x 72
#".******************************.\n".
#".                                                                        .\n".


$_ = "toast $nexttoast";

$_ =
"  *****"    ."  *****"    ."  *****  \n".
"  *       *"."  *       *"."  *       *  \n".
"  *       *"."  *       *"."  *       *  \n".
"  *****"    ."  *****"    ."  *****  \n".
"  *       *"."  *       *"."  *       *  \n".
"  *       *"."  *       *"."  *       *  \n".
"  *****"    ."  *****"    ."  *****  \n".
"";

$_ = 
"    ***   ". ".      *     ".".  ****  .\n".
"  *       *".".    **     ". ".           *.\n".
"  *       *".".      *     ".".           *.\n".
"  *       *".".      *     ".".  *****.\n".
"  *       *".".      *     ".".           *.\n".
"  *       *".".      *     ".".           *.\n".
"    ***   ". ".   ***   "  . ".  ****  .\n".
"\n".
".*****. "     ."  *       *".  "  *****  \n".
".  ****. "    ."  *       *".  "  *       *  \n".
".     ***. "  ."  *       *".  "  *       *  \n".
".       **. " ."  *****".      "  *****  \n".
".         *. "."            *"."  *       *  \n".
".*       *. " ."            *"."  *       *  \n".
".*****. "     ."            *"."  *****  \n".
"\n".
"";






                        if ($ctrl->{'os'} eq 'and') {
                            $ctrl->{'droid'}->makeToast($_);
                        }
                        if ($toast > 0) {
                            $nexttoast = $lastpoll + $toast;
                        } else {
                            $nexttoast = 0;
                        }
                    }
                }
            }
        }
        $lastcalled = time;
        $percnt++;
    } elsif ($interval > 0) {
        # remaining time to firing
        $retval = ($lastcalled + $interval) - time;
    }

    if (($retval < 300) && (
        (defined($ctrl->{'iamsleeping'}) &&
         ($ctrl->{'iamsleeping'} eq 'yes')))) {
         # don't poll more than once every 5 minutes when sleeping
         $retval = 300;
    }


    $retval;
}


\%config;
