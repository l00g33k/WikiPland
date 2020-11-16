use strict;
use warnings;

use l00mktime;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($lastcalled, $interval, $starttime, $lifestart, $msgtoast, $vibra, $vibracnt, 
    $utcoffsec, $wake, $vmsec, $pause, $filetime, $bigbutton, $pausewant);
my %config = (proc => "l00http_reminder_proc",
              desc => "l00http_reminder_desc",
              perio => "l00http_reminder_perio");
$interval = 0;
$starttime = 0x7fffffff;
$msgtoast = '?';
$lastcalled = 0;
$vibra = 0;
$vibracnt = 0;
$wake = 0;
$vmsec = 60;
$pause = 0;
$filetime = 0;
$lifestart = 0;
$bigbutton = 'checked';
$pausewant = '30';

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
    my ($st, $it, $mg, $st0, $it0, $mg0, $mgall);
    my ($vb, $vs, $vb0, $vs0, $secs, $found);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my ($pathbase, $incpath, $bufinc);

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
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
            = stat("$ctrl->{'workdir'}l00_reminder.txt");
        # remember file mod time
        $filetime = $mtimea;

        # "TIME:$form->{'starttime'}\nITV:$interval\nMSG:$msg\n";
        $st0 = 0;
        $mgall = '';
        $bufinc = '';
        while (<IN>) {
            s/[\r\n]//g;
            if (/^%INCLUDE<(.+?)>%/) {
                $incpath = $1;
                $pathbase = '';
                if ($incpath =~ /^\.\//) {
                    # find base dir of input file
                    $pathbase = "$ctrl->{'workdir'}l00_reminder.txt";
                    $pathbase =~ s/([\\\/])[^\\\/]+$/$1/;
                }
                if ((!defined($ctrl->{'remBannerDisabled'})) ||
                    ($incpath =~ /l00:\/\//)) {
                    # include file if reminder not disable, or
                    # included file is a RAM file
                    if (&l00httpd::l00freadOpen($ctrl, "$pathbase$incpath")) {
                        $bufinc .= &l00httpd::l00freadAll($ctrl);
                    }
                }
            } elsif (!defined($ctrl->{'remBannerDisabled'})) {
                # ignore main file content when reminder disabled
                $bufinc .= "$_\n";
            }
        }

        foreach $_ (split ("\n", $bufinc)) {
            chomp;
            $found = 0;
            if (($st, $it, $vb, $vs, $mg) = /^([ 0-9]+):([ 0-9]+):([ 0-9]+):([ 0-9]+):(.*)$/) {
                $found = 1;
            } elsif (($st, $it, $vb, $vs, $mg) = /^#!([ 0-9]+):([ 0-9]+):([ 0-9]+):([ 0-9]+):(.*)$/) {
                $found = 1;
            }
            if ($found) {
                $st = &l00http_reminder_date2j ($st);
                if (/^#!/) {
                    $mg = "#!$mg";
                }
		        #print "st $st $_\n";
                if (($st0 == 0) || ($st < $st0)) {
                    ($st0, $it0, $vb0, $vs0, $mg0) = ($st, $it, $vb, $vs, $mg);
                }
                if (($st0 == 0) || (time - $utcoffsec >= $st)) {
                    l00httpd::dbp($config{'desc'}, "ON: $_\n"), if ($ctrl->{'debug'} >= 2);
                    # ' # ' marks start of comment to be dropped
                    $mg =~ s/ # .+$//;
                    if ($mgall eq '') {
                        $mgall = $mg;
                    } else {
                        $mgall = "$mgall -- $mg";
                    }
                }
            }
        }
        if ($st0 > 0) {
            $starttime = $st0;
            $interval = $it0;
            $msgtoast = $mgall;
            l00httpd::dbp($config{'desc'}, sprintf("Found: $msgtoast, starttime $starttime, NOW %d\n", time - $utcoffsec)), if ($ctrl->{'debug'} >= 2);
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
    my ($ii, $temp, $timstr, $selected, $formmsg);
    my ($yr, $mo, $da, $hr, $mi, $se);
    my ($pathbase, $incpath, $bufinc, $bufall);
    # see notes in l00http_reminder_find() about time + $utcoffsec
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime (time - $utcoffsec);
    my ($life, $f0, $f1);

    $formmsg = '';

    if (!defined($form->{'path'}) || (length($form->{'path'}) < 3)) {
        # 'path' not provided, use default.
        $form->{'path'} = "$ctrl->{'workdir'}l00_reminder.txt";
    }
    # get submitted name and print greeting
    if (defined ($form->{"vibra"})) {
        $vibra = $form->{"vibra"};
        $vibracnt = $vibra;
    }
    if (defined ($form->{"vmsec"})) {
        $vmsec = $form->{"vmsec"};
    }
    if (defined ($form->{"pause"}) && ($form->{"min"} >= 0)) {
        $pause = $form->{"min"} * 60;
        $pausewant = $form->{"min"};
        if ((defined ($form->{'bigbutton'})) && ($form->{'bigbutton'} eq 'on')) {
            $bigbutton = 'checked';
        } else {
            $bigbutton = '';
        }
    }
    if (defined ($form->{'paste'})) {
        $formmsg = &l00httpd::l00getCB($ctrl);
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
        if (defined ($form->{"msg"})) {
            $formmsg = $form->{"msg"};
        }
    }
    if (defined ($form->{"nowtime"})) {
        $form->{"starttime"} = $ctrl->{'now_string'};
    }
    if (defined ($form->{"set"})) {
        if ($wake != 0) {
            $wake = 0;
            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->wakeLockRelease();
            }
        }
        if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
            $interval = $form->{"interval"};
        }
        if (defined ($form->{"msg"})) {
            $formmsg = $form->{"msg"};
        }
        if (defined ($form->{"starttime"})) {
            $starttime = &l00http_reminder_date2j ($form->{"starttime"});
            if (($starttime != 0) && ($interval > 0)) {
                # see notes in l00http_reminder_find() about time + $utcoffsec
                $temp = $starttime - time + $utcoffsec;
                #print "Starting in $temp secs\n";
                if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                    $bufinc = &l00httpd::l00freadAll($ctrl);
                } else {
                    $bufinc = '';
                }
                $bufinc .= "$form->{'starttime'}:$interval:$vibra:$vmsec:$formmsg\n";
                if (&l00httpd::l00fwriteOpen($ctrl, $form->{'path'})) {
                    &l00httpd::l00fwriteBuf($ctrl, $bufinc);
                    &l00httpd::l00fwriteClose($ctrl);
                }
                #if (open (OU, ">>$ctrl->{'workdir'}l00_reminder.txt")) {
                #    print OU "$form->{'starttime'}:$interval:$vibra:$vmsec:$formmsg\n";
                #    close (OU);
                #}
            }
        }
        $formmsg = '';
        # find earlest reminder
        &l00http_reminder_find ($ctrl);
    }

    if (defined ($form->{"reload"})) {
        $interval = 0;
        $starttime = 0x7fffffff;
        undef $ctrl->{'reminder'};
        undef $ctrl->{'BANNER:reminder'};
        $lifestart = time - $utcoffsec;
        $lastcalled = 0;
        $pause = 0;
        if ($wake != 0) {
            $wake = 0;
            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->wakeLockRelease();
            }
        }
        # find earlest reminder
        &l00http_reminder_find ($ctrl);
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
        $starttime = 0x7fffffff;
        $lastcalled = 0;
        if ($wake != 0) {
            $wake = 0;
            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->wakeLockRelease();
            }
        }
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    if ($bigbutton eq 'checked') {
        $temp = '';
        if (!($msgtoast =~ /^ *$/)) {
            $_ = $starttime;
            if ($_ < $lifestart) {
                $_ = $lifestart;
            }
            $life = sprintf ("%d:%02d", 
                int (((time - $utcoffsec) - $_) / 60),
                ((time - $utcoffsec) - $_) % 60);
            #print $sock "timer $life";
            $temp = " - $life";
        }
        print $sock "<form action=\"/reminder.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"pause\" value=\"Pause${temp}\" style=\"height:7em; width:20em\">\n";
        print $sock "<input type=\"hidden\" name=\"min\" value=\"$pausewant\">\n";
        print $sock "<input type=\"hidden\" name=\"bigbutton\" value=\"on\">\n";
        print $sock "</form></p>\n";
    }
    print $sock "<a name=\"top\"></a>";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"/reminder.htm\">Refresh</a> \n";
    print $sock "<a href=\"#manage\">Manage</a> \n";
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><p> \n";

    print $sock "<li><a href=\"/recedit.htm?record1=%5E%5Cd%7B8%2C8%7D+%5Cd%7B6%2C6%7D%3A%5Cd%2B&path=$form->{'path'}&reminder=on\">Recedit</a> - \n";
    print $sock "<a href=\"/view.htm?path=$ctrl->{'FORM'}->{'path'}\">vw</a> - \n";
    print $sock "<a href=\"/reminder.htm?reload=on\">Reload</a></li><br>\n";

    print $sock "<form action=\"/reminder.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Start time:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"starttime\" value=\"$timstr\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Msg:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"msg\" value=\"$formmsg\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"stop\" value=\"Stop\"> <input type=\"submit\" name=\"paste\" value=\"Paste\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>\n";
    print $sock "        <select name=\"day\">\n";
    print $sock "        <option value=\"--d\">--</option>\n";
	for($ii = 1; $ii < 32; $ii++) {
        $selected = '';
        if ($ii == substr($timstr, 6, 2)) {
            $selected = 'selected';
        }
	    $temp = sprintf("%d", $ii);
        print $sock "        <option name=\"day\" value=\"$temp\" $selected>$temp</option>\n";
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
        $selected = '';
        if ($ii == 0) {
            $selected = 'selected';
        }
	    $temp = sprintf("%02d", $ii);
        print $sock "        <option value=\"$temp"."m\" $selected>$temp</option>\n";
	}
    print $sock "        </select>m\n";
    print $sock "        </td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"reload\" value=\"Reload\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"newtime\" value=\"New Time\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Path (opt):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"></td>\n";
    print $sock "        </tr>\n";

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
    print $sock "</form><p>\n";

    print $sock "<a name=\"manage\"></a>";
    print $sock "<form action=\"/reminder.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"submit\" name=\"pause\" value=\"Pause\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"4\" name=\"min\" value=\"$pausewant\">min.";
    print $sock "                <input type=\"checkbox\" name=\"bigbutton\" $bigbutton> Big button</td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form></p>\n";


    print $sock "<a name=\"pause\"></a>\n";
    print $sock "<li><a href=\"/recedit.htm?record1=%5E%5Cd%7B8%2C8%7D+%5Cd%7B6%2C6%7D%3A%5Cd%2B&path=$form->{'path'}&reminder=on\">Recedit</a> - \n";
    print $sock "<a href=\"/reminder.htm?reload=on\">Reload</a> - \n";
    print $sock "<a href=\"#top\">top</a></li>\n";
#   print $sock "<li>Pause: <a href=\"/reminder.htm?pause=Pause&min=5\">5'</a> - \n";
    print $sock "<li>Pause: ";
    foreach $_ (1..29) {
        if (($_ % 5) == 0)  {
            $f0 = "<font style=\"color:black;background-color:aqua\">";
            $f1 = "</font>";
        } else {
            $f0 = '';
            $f1 = '';
        }
        print $sock "<a href=\"/reminder.htm?pause=Pause&min=$_\">$f0$_'$f1</a> - \n";
    }
    $f0 = "<font style=\"color:black;background-color:aqua\">";
    $f1 = "</font>";
#   print $sock "<a href=\"/reminder.htm?pause=Pause&min=10\">10'</a> - \n";
#   print $sock "<a href=\"/reminder.htm?pause=Pause&min=15\">15'</a> - \n";
#   print $sock "<a href=\"/reminder.htm?pause=Pause&min=20\">20'</a> - \n";
    print $sock " - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=30\">${f0}30'$f1</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=35\">35'</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=40\">40'</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=45\">45'</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=60\">1h</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=90\">1h5</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=120\">2h</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=150\">2h5</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=180\">3h</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=240\">4h</a> - \n";
    print $sock "<a href=\"/reminder.htm?pause=Pause&min=300\">5h</a></li>\n";
    print $sock "<p>";

    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"/reminder.htm\">Refresh</a><p>\n";

    print $sock "Interval: $interval Msg: $formmsg<br>\n";
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($starttime);
    print $sock sprintf ("Start: %04d/%02d/%02d %2d:%02d:%02d<br>\n", 
        $year+1900, $mon+1, $mday, $hour, $min, $sec);
    if (($lastcalled > 0) && ($lastcalled < 0x7fffffff)) {
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($lastcalled + $pause + $interval * 2);
        print $sock sprintf ("Next: %04d/%02d/%02d %2d:%02d:%02d<br>\n", $year+1900, $mon+1, $mday, $hour, $min, $sec);
		$_ = $starttime;
		if ($_ < $lifestart) {
			$_ = $lifestart;
		}
        print $sock sprintf("run time %dm %02ds<br>\n",
                    int (((time - $utcoffsec) - $_) / 60),
                    ((time - $utcoffsec) - $_) % 60);
    } else {
        print $sock sprintf ("Not running<br>\n");
    }
    # see notes in l00http_reminder_find() about time + $utcoffsec
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime (time - $utcoffsec);
    print $sock sprintf ("Now: %04d/%02d/%02d %2d:%02d:%02d<br>\n", 
        $year+1900, $mon+1, $mday, $hour, $min, $sec);

    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $bufall = &l00httpd::l00freadAll($ctrl);
        print $sock "<pre>\n";
        $bufinc = '';
        foreach $_ (split("\n", $bufall)) {
            s/[\r\n]//g;
            if (/^%INCLUDE<(.+?)>%/) {
                $incpath = $1;
                s/>/&gt;/g;
                s/</&lt;/g;
                $bufinc .= "$_\n";
                $pathbase = '';
                if ($incpath =~ /^\.\//) {
                    # find base dir of input file
                    $pathbase = "$ctrl->{'workdir'}l00_reminder.txt";
                    $pathbase =~ s/([\\\/])[^\\\/]+$/$1/;
                }
                if (&l00httpd::l00freadOpen($ctrl, "$pathbase$incpath")) {
                    $bufinc .= &l00httpd::l00freadAll($ctrl);
                }
            } else {
                $bufinc .= "$_\n";
            }
        }
        close (IN);
        print $sock $bufinc;
        print $sock "</pre>\n";
    }
    print $sock "<a name=\"end\"></a>\n";

    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_reminder_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($retval, $life);

    # see notes in l00http_reminder_find() about time + $utcoffsec
    if (time - $utcoffsec >= $starttime) {
        if (($interval > 0) && 
            (($lastcalled == 0) || (time - $utcoffsec >= ($lastcalled + $pause + $interval)))) {
            &l00http_reminder_find ($ctrl);
        }
        if (($interval > 0) && 
            (($lastcalled == 1) || (time - $utcoffsec >= ($lastcalled + $pause + $interval)))) {
            l00httpd::dbp($config{'desc'}, "\$interval=$interval \$lastcalled=$lastcalled (time=". time ." - \$utcoffsec=$utcoffsec)=". (time - $utcoffsec ) ."(\$lastcalled=$lastcalled + \$pause=$pause + \$interval=$interval)=". ($lastcalled + $pause + $interval)), if ($ctrl->{'debug'} >= 3);

            $lastcalled = time - $utcoffsec;
            $pause = 0; $ctrl->{'reminder'} = $msgtoast;

            # include 'remex' in banner
            $_ = '';
            if (defined($ctrl->{'remex'})) {
                $_ = $ctrl->{'remex'};
            }

            $ctrl->{'BANNER:reminder'} = "<center><a href=\"/recedit.htm?record1=%5E%5Cd%7B8%2C8%7D+%5Cd%7B6%2C6%7D%3A%5Cd%2B&path=/sdcard/l00httpd/l00_reminder.txt&reminder=on\">rem</a> - ".
                $_ .
                "<font style=\"color:yellow;background-color:red\">$msgtoast</font> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=1&bigbutton=on\">_1'_</a> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=5#pause\">5'</a> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=10#pause\">10'</a> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=20#pause\">20'</a> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=60#pause\">1h</a> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=120#pause\">2h</a> - ".
                "<a href=\"/reminder.htm?pause=Pause&min=180#pause\">3h</a> - ".
                "<a href=\"/reminder.htm#manage\">:::</a> </center>";

            if ((!($msgtoast =~ /^ *$/)) &&
                ($ctrl->{'bannermute'} <= time)) {
                $_ = $starttime;
                if ($_ < $lifestart) {
                    $_ = $lifestart;
                }
                $life = sprintf ("%d:%02d:", 
                    int (((time - $utcoffsec) - $_) / 60),
                    ((time - $utcoffsec) - $_) % 60);
                &l00httpd::l00PopMsg($ctrl, "$life $msgtoast");
                # if any message is a file ending in .pl, Perl do it
                foreach $_ (split(' -- ', $msgtoast)) {
                    if (/\.pl$/) {
                        if (-f $_) {
                            do $_;
                        } elsif (/\.[\\\/]/) {
                            # ./xxx or .\xxx
                            # try workdir
                            s/^\.[\\\/]//;
                            $_ = "$ctrl->{'workdir'}$_";
                            if (-f $_) {
                               do $_;
                            }
                        }
                    }
                }
            }

            if (($vibra > 0) && ($vibracnt >= $vibra)) {
                $vibracnt = 1;
                if ($wake == 0) {
                    $wake = 1;
                    if ($ctrl->{'os'} eq 'and') {
                        $ctrl->{'droid'}->wakeLockAcquirePartial();
                    }
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
        $bigbutton = '';
    }

    $retval;
}


\%config;
