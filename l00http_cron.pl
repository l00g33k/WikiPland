#::now::
#adb push D:\2\safe\gits\WikiPlandShadow\l00httpd\l00http_cron.pl /sdcard/sl4a/scripts/l00httpd/l00http_cron.pl
#adb push D:\2\safe\gits\WikiPlandShadow\l00httpd\l00httpd\l00_cron.txt /sdcard/l00httpd/l00_cron.txt

#adb push D:\2\safe\gits\WikiPlandShadow\l00httpd\l00httpd.pl /sdcard/sl4a/scripts/l00httpd/l00httpd.pl

#rsync -v -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:/sdcard/sl4a/scripts/l00httpd/l00http_cron.pl /cygdrive/D/2/safe/gits/WikiPlandShadow/l00httpd/l00http_cron.pl
#rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' /cygdrive/D/2/safe/gits/WikiPlandShadow/l00httpd/l00http_cron.pl 127.0.0.1:/sdcard/sl4a/scripts/l00httpd/l00http_cron.pl
#rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' /cygdrive/D/2/safe/gits/WikiPlandShadow/l00httpd/l00httpd/l00_cron.txt 127.0.0.1:/sdcard/l00httpd/l00_cron.txt

#md5sum l00http_cron.pl
#md5sum /sdcard/sl4a/scripts/l00httpd/l00http_cron.pl

#rsync -v -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:/sdcard/sl4a/scripts/l00httpd/l00http_cron.pl /cygdrive/D/x/ram/l00/l00http_cron.pl
#rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' /cygdrive/D/x/ram/l00/l00http_cron.pl 127.0.0.1:/sdcard/sl4a/scripts/l00httpd/l00http_cron.pl

use strict;
use warnings;

use l00mktime;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($percnt, $interval, $starttime, $filetime, $toggle);
my %config = (proc => "l00http_cron_proc",
              desc => "l00http_cron_desc",
              perio => "l00http_cron_perio");
$interval = 0;
$starttime = 0x7fffffff;
$percnt = 0;
$filetime = 0;
$toggle = 'Pause';

sub l00http_cron_j2now_string {
    my ($secs) = @_;
    my ($now_string);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($secs);

    $now_string = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);

    ($year + 1900, $mon+1, $mday, $hour, $min, $sec, $now_string, $wday);
}


sub l00http_cron_nextEventJ {
    my ($ctrl, $secs, $mnly, $hrly, $dyly, $mhly, $wkly) = @_;
    my ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday);
    my ($diff);

    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($secs);
    l00httpd::dbp($config{'desc'}, "  now      ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);

    # first future time event: minute roll over
    $secs += 60 - $se;
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($secs);
    l00httpd::dbp($config{'desc'}, "  next     ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);

    # does future time event met minutely spec?
    if ($mnly ne '*') {
        if ($mnly != $mi) {
            # minutely doesn't match, move time
            $diff = $mnly - $mi;
            if ($diff < 0) {
                # hour roll over
                $diff += 60;
            }
            $secs += $diff * 60;
        }
    }
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($secs);
    l00httpd::dbp($config{'desc'}, "  min      ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);
    

    # does future time event met hourly spec?
    if ($hrly ne '*') {
        if ($hrly != $hr) {
            # hourly doesn't match, need to move minute too?
            if ($mnly eq '*') {
                # minutely is * so move to minute 0 first
                $diff = 60 - $mi;
                $secs += $diff * 60;
                ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
                    &l00http_cron_j2now_string ($secs);
                l00httpd::dbp($config{'desc'}, "  min      ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);
            }

            # if hour still doesn't match
            if ($hrly != $hr) {
                # hourly doesn't match, move hour step 2
                $diff = $hrly - $hr;
                if ($diff < 0) {
                    # hour roll over
                    $diff += 24;
                }
                $secs += $diff * 3600;
            }
        }
    }
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($secs);
    l00httpd::dbp($config{'desc'}, "  hour     ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);
    

    # does future time event met weekly spec?
    if ($wkly ne '*') {
        if ($wkly != $wday) {
            # weekly doesn't match, need to move minute too?
            if ($mnly eq '*') {
                # minutely is * so move to minute 0 first
                $diff = 60 - $mi;
                $secs += $diff * 60;
                ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
                    &l00http_cron_j2now_string ($secs);
                l00httpd::dbp($config{'desc'}, "  min      ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);
            }
            # weekly doesn't match, move time
            $diff = $wkly - $wday;
            if ($diff < 0) {
                # weekday roll over
                $diff += 7;
            }
            $secs += $diff * 24 * 3600;
        }
    }
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($secs);
    l00httpd::dbp($config{'desc'}, "  week     ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);


    # does future time event met daily spec?
    if ($dyly ne '*') {
        if ($dyly != $da) {
            # hourly doesn't match, move time
            $diff = $dyly - $da;
            if ($diff < 0) {
                # hour roll over
                if (($mi == 1) ||
                    ($mi == 3) ||
                    ($mi == 5) ||
                    ($mi == 7) ||
                    ($mi == 8) ||
                    ($mi == 10) ||
                    ($mi == 12)) {
                    $diff += 31;
                } else {
                    $diff += 30;
                }
                if (($mi == 2) && (($yr % 4) == 0)) {
                    # leap year
                    $diff++;
                }
            }
            $secs += $diff * 24 * 3600;
        }
    }
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($secs);
    l00httpd::dbp($config{'desc'}, "  day      ($yr, $mo, $da, $hr, $mi, $nstring, $wday)\n"), if ($ctrl->{'debug'} >= 5);
    
    # does future time event met monthly spec?

    
    $secs;
}


sub l00http_cron_when_next {
    # find active cron (oldest)
    my $ctrl = pop;
    my ($st, $it, $mg, $st0, $it0, $mg0, $mgall);
    my ($vb, $vs, $vb0, $vs0, $secs, $lnno);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my ($yr, $mo, $da, $hr, $mi, $se, $nstring);
    my ($mnly, $hrly, $dyly, $mhly, $wkly, $cmd, $starttime0);


    &l00httpd::l00fwriteOpen($ctrl, 'l00://cron.htm');
    &l00httpd::l00fwriteBuf($ctrl, "# Visit <a href=\"/cron.htm\">cron</a> module.\n");
    $_ = time;
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($_);
    &l00httpd::l00fwriteBuf($ctrl, "# This page generated at: $_ / $nstring.\n");

    $starttime0 = 0x7fffffff;
    if (&l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}l00_cron.txt")) {
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
            = stat("$ctrl->{'workdir'}l00_cron.txt");
        # remember file mod time
        $filetime = $mtimea;

        # file format:
        # :# * * * * * cmd
        # :# m h d m w cmd
        # :1 * * * * cmd
        $lnno = 0;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $lnno++;
            chomp;
            if (/^#/) {
                next;
            }
            if (($mnly, $hrly, $dyly, $mhly, $wkly, $cmd) = 
                /^([0-9*]+) +([0-9*]+) +([0-9*]+) +([0-9*]+) +([0-9*]+) +(.+)$/) {
                l00httpd::dbp($config{'desc'}, "CRON: ($mnly, $hrly, $dyly, $mhly, $wkly, $cmd)\n"), if ($ctrl->{'debug'} >= 5);
                # starting with current time
                $secs = time;
                $secs = &l00http_cron_nextEventJ ($ctrl, $secs, $mnly, $hrly, $dyly, $mhly, $wkly);
                &l00httpd::l00fwriteBuf($ctrl, "# ORG($lnno):$_\n");

                ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
                    &l00http_cron_j2now_string ($secs);

                &l00httpd::l00fwriteBuf($ctrl, "TIME:$secs: $nstring dayofweek $wday\n");
                &l00httpd::l00fwriteBuf($ctrl, "CMD:$cmd\n");
                if ($starttime0 > $secs) {
                    $starttime0 = $secs;
                }

            }
        }
    }
    &l00httpd::l00fwriteClose($ctrl);

    $starttime0;
}


sub l00http_cron_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    $starttime = &l00http_cron_when_next ($ctrl);

    "cron: A cron task dispatcher. Add task in <a href=\"/view.htm?path=$ctrl->{'workdir'}l00_cron.txt\">l00_cron.txt</a>";
}

sub l00http_cron_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    my ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday, $timenow);

    if (defined ($form->{"reload"})) {
        # Force load and check
        $starttime = &l00http_cron_when_next ($ctrl);
    }

    if (defined ($form->{"toggle"})) {
        if ($toggle eq 'Pause') {
            $toggle = 'Resume';
        } else {
            $toggle = 'Pause';
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"/cron.htm\">Refresh</a> \n";
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<a href=\"/ls.htm?path=$ctrl->{'workdir'}l00_cron.txt\">$ctrl->{'workdir'}l00_cron.txt</a> \n";
    print $sock "<a href=\"/view.htm?path=$ctrl->{'workdir'}l00_cron.txt\">View</a><p> \n";

    print $sock "<form action=\"/cron.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"submit\" name=\"reload\" value=\"Reload\"></td>\n";
    print $sock "            <td><input type=\"submit\" name=\"toggle\" value=\"$toggle\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form></p>\n";
                                                
    print $sock "View scheduler: <a href=\"/view.htm?path=l00://cron.htm\">l00://cron.htm</a><p>\n";
    $timenow = time;
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($timenow);
    print $sock "Time is now $timenow, or $nstring and day of week $wday<p>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_cron_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($retval, $eventtime, $cmd);


    if ($toggle eq 'Resume') {
        # Next state is resume so current state must be paused
        $retval = 0;
    } else {
        if (time >= $starttime) {
            l00httpd::dbp($config{'desc'}, "Now ", time, 
                " is later than next start time ", $starttime, "\n"), if ($ctrl->{'debug'} >= 5);

            # do task
            if (&l00httpd::l00freadOpen($ctrl, 'l00://cron.htm')) {
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    s/\n//;
                    s/\r//;
                    if (/^#/) {
                        next;
                    }
                    if (/^TIME:(\d+):/) {
                        $eventtime = $1;
                    }
                    if (/^CMD:(.+)/) {
                        $cmd = $1;
                        if (time >= $eventtime) {
                            l00httpd::dbp($config{'desc'}, "Time is $eventtime; execute >$cmd<\n"), if ($ctrl->{'debug'} >= 5);
                        }
                    }
                }
            }


            # compute next task time
            $starttime = &l00http_cron_when_next ($ctrl);

            $percnt++;
        }
        # time not due yet, compute how much more
        $retval = $starttime - time;
    }

    $retval;
}


\%config;
