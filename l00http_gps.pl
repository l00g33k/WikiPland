use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($lastcalled, $percnt, $thislog, $lastout);
my ($known0loc1, $knost, $locst, $lastres, $datename, $fname);
my %config = (proc => "l00http_gps_proc",
              desc => "l00http_gps_desc",
              perio => "l00http_gps_perio");
my ($interval, $trkhdr, $wake, $lastcoor, $toast, $nexttoast);
my ($lon, $lat, $EW, $NS, $lastgps, $lastpoll);
my ($buf, $coor, $src, $dup, $dolog, $context);
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

my @mname = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
"Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

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


sub android_get_gps {
    my ($ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($tim, $out, $tmp, $lons, $lats);

    if ($ctrl->{'os'} eq 'and') {
        if ($known0loc1 == 0) {
            $buf = $ctrl->{'droid'}->getLastKnownLocation();
        } else {
            $buf = $ctrl->{'droid'}->readLocation();
        }
    }
#&l00httpd::dumphash ("buf", $buf);
    if (ref $buf->{'result'}->{'network'} eq 'HASH') {
        $lastres = "        $lastgps";
        $coor = $buf->{'result'}->{'network'};
        $src = 'network';
    }
    # 'network' is always available whenever phone is on GSM network
    # put 'gps' second so as to always use gps even when network 
    # is available.
    if (ref $buf->{'result'}->{'gps'} eq 'HASH') {
        $lastres = "    $lastgps";
        $coor = $buf->{'result'}->{'gps'};
        $src = 'gps';
    }
    if (defined ($coor)) {
        $lastgps = time;
        $lastres .= " = $ctrl->{'now_string'}\n";

        $tmp = $lastgps - ($coor->{'time'} / 1000);
        $lastres .= "$coor->{'provider'}@"."$coor->{'time'} diff=$tmp s\n";

        $lon = $coor->{'longitude'};
        $lat = $coor->{'latitude'};
        $lastcoor = sprintf ("%14.10f,%15.10f", $lon, $lat);
        $tim = substr ($coor->{'time'}, 0, 10);
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($tim);
        if ($lon > 0) {
            $EW = "E";
            $lons = $lon;
        } else {
            $EW = "W";
            $lons = -$lon;
        }
        if ($lat > 0) {
            $NS = "N";
            $lats = $lat;
        } else {
            $NS = "S";
            $lats = -$lat;
        }
        #T  N2226.76139 E11354.35311 30-Dec-89 23:00:00 -9999
        $out = sprintf ("T  %s%02d%08.5f %s%03d%08.5f %02d-%s-%02d %02d:%02d:%02d % 4d ; $src $ctrl->{'now_string'}",
            $NS, int ($lats), ($lats - int ($lats)) * 60,
            $EW, int ($lons), ($lons - int ($lons)) * 60,
            $mday, $mname [$mon], $year % 100, $hour, $min, $sec, $coor->{'altitude'});
    }
}



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
    my ($buf, @countinglines);


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
                    if (-f "$ctrl->{'workdir'}$fname") {
                        # exist
                        open (OUT, ">>$ctrl->{'workdir'}$fname");
                    } else {
                        # does not exist
                        open (OUT, ">$ctrl->{'workdir'}$fname");
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
            $buf = &android_get_gps ($ctrl);
            open (OUT, ">>$ctrl->{'workdir'}gps.way");
			print OUT "$lon,$lat $buf $form->{'locremark'}\n";
			close(OUT);
        }
    } elsif (defined ($form->{"getgps"})) {
        &l00httpd::l00setCB($ctrl, "$lon,$lat\n$buf");
    }
    if ($datename) {
        $fname = 'gps_' . 
            substr($ctrl->{'now_string'}, 0, 8) . '.trk';
    } else {
        $fname = 'gps.trk';
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} - <a href=\"/gps.htm\">Refresh</a> -  $ctrl->{'HOME'} - ";
    print $sock "<a href=\"/view.htm?path=$ctrl->{'workdir'}$fname\">log</a> - \n";
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
    print $sock "        <td>paste to clipboard ($lastcoor)</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<p>Mark current location in ";
    print $sock "<a href=\"/view.htm?path=$ctrl->{'workdir'}gps.way\">$ctrl->{'workdir'}gps.way</a>:\n";
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
    print $sock "$lastres</pre>\n";
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

    print $sock "launcher <a href=\"/ls.htm?path=$ctrl->{'workdir'}\">$ctrl->{'workdir'}</a>";
    print $sock "<a href=\"/launcher.htm?path=$ctrl->{'workdir'}$fname\">$fname</a><p>\n";

    print $sock "<a name=\"end\"></a><p>\n";
    print $sock "<a href=\"#top\">Jump to top</a><p>\n";

 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_gps_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($out, $brightness);

    $lastpoll = time;
    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {

        if (((time - $lastpoll) <= $interval) ||
            ($lastcalled == 0)) {
            # polling could be more frequent than the period
            # e.g. running period.pl
            # if we slept for longer, the phone might be sleeping,
            # during which it is not safe(?) to make socket JSON call
            # as the phone might (?, will?) during the call?
            $out = &android_get_gps ($ctrl);
            if ($out ne '') {
                if (($dup == 1) || ($out ne $lastout)) {
                    if ($dolog) {
                        if ($datename) {
                            $fname = 'gps_' . 
                                substr($ctrl->{'now_string'}, 0, 8) . '.trk';
                        } else {
                            $fname = 'gps.trk';
                        }
                        if (-f "$ctrl->{'workdir'}$fname") {
                            # exist
                            open (OUT, ">>$ctrl->{'workdir'}$fname");
                        } else {
                            # does not exist
                            open (OUT, ">$ctrl->{'workdir'}$fname");
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
    }


    $interval;
}


\%config;
