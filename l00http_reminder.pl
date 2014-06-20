use strict;
use warnings;

use l00mktime;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($lastcalled, $percnt, $interval, $starttime, $msg, $vibra, $vibracnt, 
    $utcoffsec, $wake, $vmsec, $pause);
my %config = (proc => "l00http_reminder_proc",
              desc => "l00http_reminder_desc",
              perio => "l00http_reminder_perio");
$interval = 0;
$starttime = 0x7fffffff;
$msg = '?';
$lastcalled = 0;
$percnt = 0;
$vibra = 0;
$vibracnt = 0;
$wake = 0;
$vmsec = 60;
$pause = 0;

sub l00http_reminder_date2j {
# convert from date to seconds
    my $temp = pop;
    my $secs = 0;
    my ($yr, $mo, $da, $hr, $mi, $se);

    $temp =~ s/ //g;
    $temp =~ s/\///g;
    $temp =~ s/://g;
    if (($yr, $mo, $da, $hr, $mi, $se) = ($temp =~ /(....)(..)(..)(..)(..)(..)/)) {
        $yr -= 1900;
        $mo--;
        $secs = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
    }
    
    $secs;
}

sub l00http_reminder_find {
# find active reminder (oldest)
    my $ctrl = pop;
    my ($st, $it, $mg, $st0, $it0, $mg0);
    my ($vb, $vs, $vb0, $vs0, $secs);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

    # compute UTC and localtime offset in seconds
	# Compute all times in UTC but the time to display is in local time
	# so we need to know the difference UTC and local time. Stackoverflow says 
	# to compute the difference between gmtime and localtime to avoid module 
	# dependency. We use noon today UTC to avoid rolling over midnight
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $secs = &l00mktime::mktime ($year, $mon, $mday, 12, 0, 0);
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($secs);
    $utcoffsec = $hour * 3600 + $min * 60;
    #print sprintf ("utc gmtime: %04d/%02d/%02d %2d:%02d:%02d<br>\n", $year+1900, $mon+1, $mday, $hour, $min, $sec);
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($secs);
    $utcoffsec -= $hour * 3600 + $min * 60;
    #print sprintf ("utc localtime: %04d/%02d/%02d %2d:%02d:%02d<br>\n", $year+1900, $mon+1, $mday, $hour, $min, $sec);
    #print "utcoffsec $utcoffsec\n";


    if (open (IN, "<$ctrl->{'workdir'}l00_reminder.txt")) {
        # "TIME:$form->{'starttime'}\nITV:$interval\nMSG:$msg\n";
        $st0 = 0;
        while (<IN>) {
            chop;
            if (($st, $it, $vb, $vs, $mg) = /^([ 0-9]+):([ 0-9]+):([ 0-9]+):([ 0-9]+):(.*)$/) {
                $st = &l00http_reminder_date2j ($st);
		        #print "st $st $_\n";
                if (($st0 == 0) || ($st < $st0)) {
                    ($st0, $it0, $vb0, $vs0, $mg0) = ($st, $it, $vb, $vs, $mg);
                }
            }
        }
        if ($st0 > 0) {
            $starttime = $st0;
            $interval = $it0;
            $msg = $mg0;
            $vibra = $vb0;
            $vmsec = $vs0;
        }
        close (IN);
    }
}


sub l00http_reminder_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    &l00http_reminder_find ($ctrl);

    "reminder: A reminder task demo.  Click and change 'Run interval' to non zero";
}

sub l00http_reminder_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($ii, $temp, $timstr);
    my ($yr, $mo, $da, $hr, $mi, $se, $pausewant);
    # see notes in l00http_reminder_find() about time + $utcoffsec
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime (time - $utcoffsec);
#   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);

    # get submitted name and print greeting
    if (defined ($form->{"vibra"})) {
        $vibra = $form->{"vibra"};
        $vibracnt = $vibra;
    }
    if (defined ($form->{"vmsec"})) {
        $vmsec = $form->{"vmsec"};
    }
    $pausewant = '30';
    if (defined ($form->{"pause"}) && ($form->{"min"} >= 0)) {
        $pause = $form->{"min"} * 60;
        $pausewant = $form->{"min"};
    }
    if ((defined ($form->{'paste'})) && ($ctrl->{'os'} eq 'and')) {
        $msg = $ctrl->{'droid'}->getClipboard()->{'result'};
    }
    if (defined ($form->{"set"})) {
        if ($wake != 0) {
            $wake = 0;
            $ctrl->{'droid'}->wakeLockRelease();
        }
        $percnt = 0;
        if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
            $interval = $form->{"interval"};
        }
        if (defined ($form->{"msg"})) {
            $msg = $form->{"msg"};
        }
        if (defined ($form->{"starttime"})) {
            $starttime = &l00http_reminder_date2j ($form->{"starttime"});
            if (($starttime != 0) && ($interval > 0)) {
                # see notes in l00http_reminder_find() about time + $utcoffsec
                $temp = $starttime - time + $utcoffsec;
                #print "Starting in $temp secs\n";
                if (open (OU, ">>$ctrl->{'workdir'}l00_reminder.txt")) {
                    print OU "$form->{'starttime'}:$interval:$vibra:$vmsec:$msg\n";
                    close (OU);
                }
            }
        }
        # find earlest reminder
        &l00http_reminder_find ($ctrl);
    }

    if (defined ($form->{"reload"})) {
        $percnt = 0;
        $interval = 0;
        $starttime = 0x7fffffff;
        $lastcalled = 0;
        $pause = 0;
        if ($wake != 0) {
            $wake = 0;
            $ctrl->{'droid'}->wakeLockRelease();
        }
        # find earlest reminder
        &l00http_reminder_find ($ctrl);
    }
    if (defined ($form->{"stop"})) {
        $percnt = 0;
        $interval = 0;
        $starttime = 0x7fffffff;
        $lastcalled = 0;
        if ($wake != 0) {
            $wake = 0;
            $ctrl->{'droid'}->wakeLockRelease();
        }
    }
    $timstr = $ctrl->{'now_string'};
    if (defined ($form->{"newtime"})) {
        if (defined ($form->{"day"})) {
            if ($form->{"day"} =~ /(\d+)/) {
			    substr($timstr, 6, 2) = sprintf("%02d", $1);
			    substr($timstr, 13, 2) = '00';
            }
		}
        if (defined ($form->{"hour"})) {
            if ($form->{"hour"} =~ /(\d+)/) {
			    substr($timstr, 9, 2) = sprintf("%02d", $1);
			    substr($timstr, 13, 2) = '00';
            }
		}
        if (defined ($form->{"min"})) {
            if ($form->{"min"} =~ /(\d+)/) {
			    substr($timstr, 11, 2) = sprintf("%02d", $1);
			    substr($timstr, 13, 2) = '00';
            }
		}
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> <a href=\"/reminder.htm\">Refresh</a> \n";
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<a href=\"/ls.htm?path=$ctrl->{'workdir'}l00_reminder.txt\">$ctrl->{'workdir'}l00_reminder.txt</a><p> \n";

    print $sock "<form action=\"/reminder.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"submit\" name=\"pause\" value=\"Pause\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"4\" name=\"min\" value=\"$pausewant\">min.</td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form></p>\n";
                                                
    print $sock "<form action=\"/reminder.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Start time:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"starttime\" value=\"$timstr\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Msg:</td>\n";
#   print $sock "            <td><input type=\"text\" size=\"16\" name=\"msg\" value=\"$msg\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"msg\" value=\"\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"> <input type=\"submit\" name=\"paste\" value=\"Paste\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>\n";
    print $sock "        <select name=\"day\">\n";
    print $sock "        <option value=\"--d\">--</option>\n";
	for($ii = 1; $ii < 32; $ii++) {
	    $temp = sprintf("%d", $ii);
        print $sock "        <option name=\"day\" value=\"$temp\">$temp</option>\n";
	}
    print $sock "        </select>d\n";
    print $sock "        </td>\n";
    print $sock "        <td>\n";
    print $sock "        <select name=\"hour\">\n";
    print $sock "        <option value=\"--m\">--</option>\n";
	for($ii = 0; $ii < 24; $ii++) {
        if ($ii + 7 < 24) {
            $temp = sprintf("%d", $ii + 7);
        } else {
            $temp = sprintf("%d", $ii - 24 + 7);
        }
        print $sock "        <option value=\"$temp"."m\">$temp</option>\n";
	}
    print $sock "        </select>h\n";
    print $sock "        <select name=\"min\">\n";
    print $sock "        <option value=\"--m\">--</option>\n";
	for($ii = 0; $ii < 60; $ii += 5) {
	    $temp = sprintf("%02d", $ii);
        print $sock "        <option value=\"$temp"."m\">$temp</option>\n";
	}
    print $sock "        </select>m\n";
    print $sock "        </td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"reload\" value=\"Reload\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"newtime\" value=\"New Time\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Interval (sec):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"10\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Vibrate every:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"vibra\" value=\"0\"> times</td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>For:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"vmsec\" value=\"60\">mSec</td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<br>Interval: $interval Msg: $msg<br>\n";
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($starttime);
    print $sock sprintf ("Start: %04d/%02d/%02d %2d:%02d:%02d<br>\n", 
        $year+1900, $mon+1, $mday, $hour, $min, $sec);
    if (($lastcalled > 0) && ($lastcalled < 0x7fffffff)) {
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($lastcalled + $pause + $interval * 2);
        print $sock sprintf ("Next: %04d/%02d/%02d %2d:%02d:%02d<br>\n", $year+1900, $mon+1, $mday, $hour, $min, $sec);
    } else {
        print $sock sprintf ("Not running<br>\n");
    }
    # see notes in l00http_reminder_find() about time + $utcoffsec
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime (time - $utcoffsec);
    print $sock sprintf ("Now: %04d/%02d/%02d %2d:%02d:%02d<br>\n", 
        $year+1900, $mon+1, $mday, $hour, $min, $sec);
    print $sock "Count: $percnt<br>\n";

    if (open (IN, "<$ctrl->{'workdir'}l00_reminder.txt")) {
        print $sock "<pre>\n";
        while (<IN>) {
            print $sock $_;
        }
        close (IN);
        print $sock "</pre>\n";
    }
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_reminder_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($retval);

    # see notes in l00http_reminder_find() about time + $utcoffsec
    if ((!defined($ctrl->{'remBannerDisabled'})) &&
        (time - $utcoffsec>= $starttime)) {
        if (($interval > 0) && 
            (($lastcalled == 0) || (time - $utcoffsec >= ($lastcalled + $pause + $interval)))) {
            $lastcalled = time - $utcoffsec;
            $pause = 0;

            $ctrl->{'reminder'} = $msg;
            $ctrl->{'BANNER:reminder'} = "<center><a href=\"/recedit.htm?record1=%5E%5Cd%7B8%2C8%7D+%5Cd%7B6%2C6%7D%3A%5Cd%2B&path=/sdcard/l00httpd/l00_reminder.txt&reminder=on\">rem</a>: <font style=\"color:yellow;background-color:red\">$msg</font></center>";

            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->makeToast("$percnt: $msg");
            }
            $percnt++;

            if (($vibra > 0) && ($vibracnt >= $vibra)) {
                $vibracnt = 1;
                if ($wake == 0) {
                    $wake = 1;
                    $ctrl->{'droid'}->wakeLockAcquirePartial();
                }
                if ($ctrl->{'os'} eq 'and') {
                    $ctrl->{'droid'}->vibrate($vmsec);
                }
            } else {
                $vibracnt++;
            }
        }
        $retval = $interval;
    } else {
        $retval = $starttime - time + $utcoffsec;
        # time not due yet, clear title banner message
        undef $ctrl->{'reminder'};
        undef $ctrl->{'BANNER:reminder'};
    }

    $retval;
}


\%config;
