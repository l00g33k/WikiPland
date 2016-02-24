use strict;
use warnings;
use IO::Socket;
use IO::Select;
use l00wget;

use l00mktime;

#use main;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($percnt, $interval, $starttime, $filetime, $toggle, $atboot, $atshutdown);
my %config = (proc => "l00http_cron_proc",
              desc => "l00http_cron_desc",
              perio => "l00http_cron_perio",
              shutdown => "l00http_cron_shutdown");
$interval = 0;
$starttime = 0x7fffffff;
$percnt = 0;
$filetime = 0;
$toggle = 'Pause';
$atboot = 1;
$atshutdown = 0;

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
    my ($mnly, $hrly, $dyly, $mhly, $wkly, $cmd, $starttime0, $skip, $skipfilter);

    &l00httpd::l00fwriteOpen($ctrl, 'l00://crontab.htm');
    &l00httpd::l00fwriteBuf($ctrl, "# Visit <a href=\"/cron.htm\">cron</a> module.\n");
    $_ = time;
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($_);
    &l00httpd::l00fwriteBuf($ctrl, "# This page was generated at: $_ / $nstring.\n");
    if ($toggle eq 'Pause') {
        &l00httpd::l00fwriteBuf($ctrl, "# cron is now running\n\n");
    } else {
        &l00httpd::l00fwriteBuf($ctrl, "# cron is now paused\n\n");
    }

    $starttime0 = 0x7fffffff;
    if (&l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}l00_cron.txt")) {
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
            = stat("$ctrl->{'workdir'}l00_cron.txt");
        # remember file mod time
        $filetime = $mtimea;

        # machine specific filter
        $skip = 0;
        $skipfilter = '.';

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
            if (/^machine=~\/(.+)\/ */) {
                # new machine filter
                $skipfilter = $1;
                if ($ctrl->{'machine'} =~ /$skipfilter/) {
                    # matched, don't skip
                    $skip = 0;
                } else {
                    # no match, skipping
                    $skip = 1;
                }
            }
            if ($skip) {
                next;
            }

            if (($atboot) && (($cmd) = (/^\@boot +(.+)$/))) {
                l00httpd::dbp($config{'desc'}, "CRON: (\@boot $cmd)\n"), if ($ctrl->{'debug'} >= 5);
                $secs = time + 0;
                &l00httpd::l00fwriteBuf($ctrl, "# ORG($lnno):$_\n");

                ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
                    &l00http_cron_j2now_string ($secs);

                &l00httpd::l00fwriteBuf($ctrl, "TIME:$secs: $nstring dayofweek $wday\n");
                &l00httpd::l00fwriteBuf($ctrl, "CMD:$cmd\n\n");
                if ($starttime0 > $secs) {
                    $starttime0 = $secs;
                }
            } elsif (($atshutdown) && (($cmd) = (/^\@shutdown +(.+)$/))) {
                l00httpd::dbp($config{'desc'}, "CRON: (\@shutdown $cmd)\n"), if ($ctrl->{'debug'} >= 5);
                $secs = time + 0;
                &l00httpd::l00fwriteBuf($ctrl, "# ORG($lnno):$_\n");

                ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
                    &l00http_cron_j2now_string ($secs);

                &l00httpd::l00fwriteBuf($ctrl, "TIME:$secs: $nstring dayofweek $wday\n");
                &l00httpd::l00fwriteBuf($ctrl, "CMD:$cmd\n\n");
                if ($starttime0 > $secs) {
                    $starttime0 = $secs;
                }
            } elsif (($mnly, $hrly, $dyly, $mhly, $wkly, $cmd) = 
                /^([0-9*]+) +([0-9*]+) +([0-9*]+) +([0-9*]+) +([0-9*]+) +(.+)$/) {
                l00httpd::dbp($config{'desc'}, "CRON: ($mnly, $hrly, $dyly, $mhly, $wkly, $cmd)\n"), if ($ctrl->{'debug'} >= 5);
                # starting with current time
                $secs = time;
                $secs = &l00http_cron_nextEventJ ($ctrl, $secs, $mnly, $hrly, $dyly, $mhly, $wkly);
                &l00httpd::l00fwriteBuf($ctrl, "# ORG($lnno):$_\n");

                ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
                    &l00http_cron_j2now_string ($secs);

                &l00httpd::l00fwriteBuf($ctrl, "TIME:$secs: $nstring dayofweek $wday\n");
                &l00httpd::l00fwriteBuf($ctrl, "CMD:$cmd\n\n");
                if ($starttime0 > $secs) {
                    $starttime0 = $secs;
                }
            }
        }
    }
    &l00httpd::l00fwriteBuf($ctrl, "# End of cronjob\n");
    &l00httpd::l00fwriteClose($ctrl);

    $starttime0;
}


sub l00http_cron_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    $starttime = &l00http_cron_when_next ($ctrl);

    $ctrl->{'l00file'}->{"l00://cronlog.txt"} = "* cron.htm log file:\n\n";


    "cron: A cron task dispatcher. Add task in <a href=\"/view.htm?path=$ctrl->{'workdir'}l00_cron.txt\">l00_cron.txt</a>";
}

sub l00http_cron_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    my ($yr, $mo, $da, $hr, $mi, $se, $nstring, $timenow);

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
                                                
    print $sock "View scheduler: <a href=\"/view.htm?path=l00://crontab.htm\">l00://crontab.htm</a><p>\n";
    $timenow = time;
    ($yr, $mo, $da, $hr, $mi, $se, $nstring, $wday) = 
        &l00http_cron_j2now_string ($timenow);
    print $sock "Time is now $timenow, or $nstring and day of week $wday<p>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_cron_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($retval, $eventtime, $cmd, $lnno, $cronspec, $l00name, $hdr, $bdy);
    my ($tmp, $urlpath, %FORM, $modcalled, $urlparams, @cmd_param_pairs);
    my ($cmd_param_pair, $name, $param, $subname, $socknul, $crontab);
    my ($savehome, $savehttphead, $savehtmlhead, $savehtmlttl, $savehtmlhead2, $saveclient_ip);



    if ($toggle eq 'Resume') {
        # Next state is resume so current state must be paused
        $retval = 0;
    } else {
        if (time >= $starttime) {
            $_ = time;
            l00httpd::dbp($config{'desc'}, "Now $_ is later than next start time $starttime\n"), if ($ctrl->{'debug'} >= 4);

            # do task
            if (&l00httpd::l00freadOpen($ctrl, 'l00://crontab.htm')) {
#               while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $crontab = &l00httpd::l00freadAll($ctrl);
                foreach $_ (split("\n", $crontab)) {
                    s/\n//;
                    s/\r//;
                    l00httpd::dbp($config{'desc'}, "crontab.htm: >$_<\n"), if ($ctrl->{'debug'} >= 4);

                    if (($lnno, $cronspec) = /# ORG\((\d+)\):([^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+) /) {
                        # make l00 filename
                        $l00name = "cron${lnno}_$cronspec";
                        $l00name =~ s/ /_/g;
                        $l00name =~ s/\*/x/g;
                    }
                    if (/^#/) {
                        next;
                    }
                    if (/^TIME:(\d+):/) {
                        $eventtime = $1;
                    }
                    if (/^CMD:(.+)/) {
                        $cmd = $1;
                        if (time >= $eventtime) {
                            # 3 kinds of commands are supported
                            $ctrl->{'l00file'}->{"l00://cronlog.txt"} .= "$ctrl->{'now_string'} ";
                            if (($tmp, $urlpath) = $cmd =~ m!^http://(localhost|127\.0\.0\.1):$ctrl->{'ctrl_port_first'}(.+)!) {
                                # 1) wget self. Since we aren't multi-thread, we have to simulate by 
                                # creating the %FORM and call the module directly
                                l00httpd::dbp($config{'desc'}, "Time is $eventtime; Simulate wget self >$urlpath<\n"), if ($ctrl->{'debug'} >= 4);
                                # http://localhost:20337/shell.htm?buffer=msg+%25USERNAME%25+%2FTIME%3A1+WikiPland+says+ello&exec=Exec
                                undef %FORM;
                                if ($urlpath =~ /^\/(\w+)\.(pl|htm)[^?]*\?*(.*)$/) {
                                    $ctrl->{'l00file'}->{"l00://cronlog.txt"} .= "wget self: $_";

                                    # of form: http://localhost:20337/ls.htm?path=/sdcard
                                    $modcalled = $1;
                                    $urlparams = $3;
                                    #print "CRON self: >$modcalled< >$urlparams<\n";

                                    @cmd_param_pairs = split ('&', $urlparams);
                                    foreach $cmd_param_pair (@cmd_param_pairs) {
                                        ($name, $param) = split ('=', $cmd_param_pair);
                                        if (defined ($name) && defined ($param)) {
                                            $param =~ tr/+/ /;
                                            $param =~ s/\%([a-fA-F0-9]{2})/pack("C", hex($1))/seg;
                                            $FORM{$name} = $param;
                                            # convert \ to /
                                            if ($name eq 'path') {
                                                $FORM{$name} =~ tr/\\/\//;
                                            }
                                            #print "CRON self: >$name< >$param<\n";
                                        }
                                    }
                                    # invoke module
                                    if (defined ($ctrl->{'modsinfo'}->{"$modcalled:fn:proc"})) {

                                        $subname = $ctrl->{'modsinfo'}->{"$modcalled:fn:proc"};
                                        print "CRON: callmod $subname\n", if ($ctrl->{'debug'} >= 4);
                                        $ctrl->{'FORM'} = \%FORM;

                                        $savehome = $ctrl->{'home'};
                                        $savehttphead = $ctrl->{'httphead'};
                                        $savehtmlhead = $ctrl->{'htmlhead'};
                                        $savehtmlttl = $ctrl->{'htmlttl'};
                                        $savehtmlhead2 = $ctrl->{'htmlhead2'};
                                        $saveclient_ip = $ctrl->{'client_ip'};

                                        $ctrl->{'home'} = '';
                                        $ctrl->{'httphead'} = '';
                                        $ctrl->{'htmlhead'} = '';
                                        $ctrl->{'htmlttl'} = '';
                                        $ctrl->{'htmlhead2'} = '';
                                        $ctrl->{'client_ip'} = 0;
                                        if ($ctrl->{'os'} eq 'win') {
                                            open ($socknul, ">nul");
                                        } else {
                                            open ($socknul, ">/dev/null");
                                        }
                                        $ctrl->{'sock'} = $socknul;

                                        $ctrl->{'msglog'} = "";

                                        __PACKAGE__->$subname($ctrl);

                                        close ($socknul);
                                        &dlog  ($ctrl->{'msglog'}."\n");

                                        $ctrl->{'home'} = $savehome;
                                        $ctrl->{'httphead'} = $savehttphead;
                                        $ctrl->{'htmlhead'} = $savehtmlhead;
                                        $ctrl->{'htmlttl'} = $savehtmlttl;
                                        $ctrl->{'htmlhead2'} = $savehtmlhead2;
                                        $ctrl->{'client_ip'} = $saveclient_ip;
                                    }

                                }

                            } elsif ($cmd =~ m!^http://!) {
                                $ctrl->{'l00file'}->{"l00://cronlog.txt"} .= "wget http: $_";

                                # 2) a normal HTTP. use l00http_wget.pl
                                l00httpd::dbp($config{'desc'}, "Time is $eventtime; wget >$cmd<\n"), if ($ctrl->{'debug'} >= 4);
                                # http://wikipland-l00g33k.rhcloud.com/httpd.htm
                                ($hdr, $bdy) = &l00wget::wget ($cmd);
                                &l00httpd::l00fwriteOpen($ctrl, "l00://$l00name.wget.hdr");
                                &l00httpd::l00fwriteBuf($ctrl, "shell >$cmd<; output:\n");
                                &l00httpd::l00fwriteBuf($ctrl, "$hdr");
                                &l00httpd::l00fwriteClose($ctrl);

                                &l00httpd::l00fwriteOpen($ctrl, "l00://$l00name.wget.htm");
                                &l00httpd::l00fwriteBuf($ctrl, "$bdy");
                                &l00httpd::l00fwriteClose($ctrl);
                            } else {
                                $ctrl->{'l00file'}->{"l00://cronlog.txt"} .= "shell command: $_";

                                # 3) assume to be a shell command. user be warned
                                l00httpd::dbp($config{'desc'}, "Time is $eventtime; shell >$cmd<\n"), if ($ctrl->{'debug'} >= 4);
                                # msg %USERNAME% /TIME:1 Shell says hello
                                $_ =`$cmd`;
                                &l00httpd::l00fwriteOpen($ctrl, "l00://$l00name.shell.htm");
                                &l00httpd::l00fwriteBuf($ctrl, "shell >$cmd<; output:\n");
                                &l00httpd::l00fwriteBuf($ctrl, "$_");
                                &l00httpd::l00fwriteClose($ctrl);
                            }
                            $ctrl->{'l00file'}->{"l00://cronlog.txt"} .= "\n";
                        }
                    }
                }
                $atboot = 0;
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

sub l00http_cron_shutdown {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket

    # scan in atshutdown tasks
    $atshutdown = 1;
    $starttime = &l00http_cron_when_next ($ctrl);

    if (&l00httpd::l00freadOpen($ctrl, 'l00://crontab.htm')) {
        print $sock "'cron' module \@shutdown tasks:<p>\n<pre>\n";
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            print $sock "$_";
        }
        print $sock "</pre>\n";
    }

    # call perio to service atshutdown tasks
    $toggle = 'Pause';
    &l00http_cron_perio($main, $ctrl);

    0;
}


\%config;
