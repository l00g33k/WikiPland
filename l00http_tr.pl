use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# This module display a timeline of tasks planned.  It makes it 
# easy to see how the delay on one task affect the completion 
# of everything else following it.

# What it does:
# 1) Make 36 hours worth of time slots
# 2) Read in a description file (you can specify a different one):
#    in column 0:
#    . : start skipping
#    , : stop skipping
#    ! : a comment line
#    @1430 : start time in 24 hour format
#    =30 : a 30 minute tasks
# 3) Display the time slots
# 4) Display a control table

my %config = (proc => "l00http_tr_proc",
              desc => "l00http_tr_desc");

my ($blanks, $desc, $hr, $ii, $iien, $iist, $len, $minoff);
my ($mn, $now, $prefix, $skip, $suffix);
my (@db, @outs);
my $itvmin = 5;     # length of each time slot

sub l00http_tr_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "tr: Displaying a timeline of the tasks to be done today";
}


sub l00http_tr_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($blkln, $citydiff);

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);

    if ((!defined ($form->{'fname'})) || (length ($form->{'fname'}) < 6)) {
        $form->{'fname'} = "$ctrl->{'workdir'}l00_tr.txt";
    }

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>tr</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>";
    print $sock "$ctrl->{'home'} Input: <a href=\"/ls.htm?path=$form->{'fname'}\">$form->{'fname'}</a> \n";
    print $sock "$ctrl->{'HOME'} \n";
    print $sock "<a href=\"#__end__\">end</a><br>\n";

    # 1) Make 36 hours worth of time slots

    #: create blank output table
    undef @outs;
    for ($ii = 0; $ii < (60 * 36) / $itvmin; $ii++) {
        # indent hour mark to make it easy to see
        if (($itvmin * $ii) % 60 == 0) {
            $prefix = " ";
            $suffix = "";
        } else {
            $prefix = "";
            $suffix = " ";
        }
        $outs [$ii] = sprintf ("$prefix%02d%02d$suffix", int ((($itvmin * $ii) % (24 * 60)) / 60), ($itvmin * $ii) % 60);
        if (defined ($form->{'diff'})) {
            if (($citydiff) = $form->{'diff'} =~ /(\d+)/) {
                if (($citydiff > -24) && 
                    ($citydiff < 24) && 
                    ($citydiff != 0)) {
                    # display a second column of time in a different timezone, nice for timezone crossing flight
                    $outs [$ii] .= sprintf ("$prefix%02d%02d$suffix", int ((($itvmin * $ii + $citydiff * 60) % (24 * 60)) / 60), ($itvmin * $ii) % 60);
                }
            }
        }
    }


    # 2) Read in a description file:

    #: open input file and scan calendar inputs
    undef @db;
    $minoff = 0;
    $skip = 0;
    if ((defined ($form->{'fname'}) && (open (IN, "<$form->{'fname'}")))) {
        while (<IN>) {
            s/\r//g;     # get rid of CR/LF
            s/\n//g;
            if (/^\./) {
                #    . : start skipping
                $skip = 1;
                next;
            }
            if (/^,/) {
                #    , : stop skipping
                $skip = 0;
                next;
            }
            if (/^#/) {
                #    # : a comment line
                next;
            }
            if (($skip) || (/^\*/)) {
                # skip
                next;
            }
            if (/^@ *$/) {
                $minoff = $hour * 60 + int ($min / 5) * 5;
            } elsif (($hr,$mn) = /^@(\d\d)(\d\d)/) {
                #    @1430 : start time in 24 hour format
                if ($hr < 4) {
                    # assume 4 am is the 4 am of the following day
                    $hr += 24;
                }
                $minoff = $hr * 60 + $mn;
            } elsif (($len,$desc) = /^=(\d+) +(.+)/) {
                # append task descriptions to time slot spanning the length
                for ($ii = $minoff; $ii < $minoff + $len; $ii += $itvmin) {
                    $outs [int ($ii / $itvmin)] .= " $desc ($len)";
                }
                $minoff = $ii;
            } elsif (($desc) = / *(.+) */) {
                # default to 5 min
                $outs [int ($minoff / $itvmin)] .= " $desc (5)";
                $minoff += $itvmin;
            }
        }
        close (IN);
    }

    # assume 4 am is the 4 am of the following day
    $now = $hour * 60 + $min;
    if ($hour < 4) {
        $now += 24 * 60;
    }
    $now = int ($now / $itvmin);

    # calculate spacing for dual timezone display
    $blanks = 5;
    if (defined ($form->{'diff'})) {
        if (($citydiff) = $form->{'diff'} =~ /(\d+)/) {
            if (($citydiff > -24) && 
                ($citydiff < 24) && 
                ($citydiff != 0)) {
                # display a second column of time in a different timezone, nice for timezone crossing flight
                $blanks = 10;
            }
        }
    }

    if (!defined ($form->{'allhours'}) || ($form->{'allhours'} ne 'on')) {
        # search for the first non blank time slot
        for ($iist = 0; $iist < (60 * 36) / $itvmin; $iist++) {
            if ((length ($outs[$iist]) > $blanks) || ($iist == $now)) {
                last;
            }
        }
        # search for the last non blank time slot
        for ($iien = (60 * 36) / $itvmin - 1; $iien >= 0; $iien--) {
            if (length ($outs[$iien]) > $blanks) {
                last;
            }
        }
    } else {
        # full times
        $iist = 0;
        $iien = (60 * 36) / $itvmin - 1;
    }

    # make an anchor to jump to current time    
    print $sock "<a href=\"#now\">now</a><br>\n";
    print $sock "<pre>\n";

    # 3) Display the time slots

    # display the time slot
    $blkln = 0;
    for ($ii = $iist; $ii <= $iien; $ii++) {
        if ($ii == $now) {
            print $sock "</pre><a name=\"now\">now</a> <a href=\"#__end__\">end</a> <a href=\"#__top__\">top</a> <pre>";
            $blkln = 0; # force time display for time 'now'
        }
        $blkln++;
        if (defined ($form->{'allhours'}) && ($form->{'allhours'} eq 'on')) {
            print $sock "$outs[$ii]\n";
        } elsif (length ($outs[$ii]) != $blanks) {
            print $sock "$outs[$ii]\n";
            $blkln = 0;
        } elsif ($blkln < 2) {
            print $sock "$outs[$ii]\n\n\n";
        }
    }
    print $sock "</pre>\n";
    if ($now >= $iien) {
        print $sock "<a name=\"now\">now</a>\n";
    }


    # 4) Display a control table
    my ($fname, $diff, $lcity, $rcity);
    if (defined ($form->{'fname'})) {
        $fname = $form->{'fname'};
    } else {
        $fname = "";
    }
    if (defined ($form->{'diff'})) {
        $diff = $form->{'diff'};
    } else {
        $diff = "";
    }
    if (defined ($form->{'lcity'})) {
        $lcity = $form->{'lcity'};
    } else {
        $lcity = "";
    }
    if (defined ($form->{'rcity'})) {
        $rcity = $form->{'rcity'};
    } else {
        $rcity = "";
    }

    print $sock "<hr>\n";
    print $sock "<a href=\"#now\">now</a> \n";
    print $sock "<a name=\"__end__\"></a>";
    print $sock "<a href=\"#__top__\">top</a>";
    print $sock "<form action=\"/tr.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "<tr>\n";
    print $sock "<td>Full filename:</td>\n";
    print $sock "<td><input type=\"text\" size=\"12\" name=\"fname\" value=\"$fname\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "<td>Time difference:</td>\n";
    print $sock "<td><input type=\"text\" size=\"3\" name=\"diff\" value=\"$diff\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "<td>Left city:\n</td>";
    print $sock "<td><input type=\"text\" size=\"5\" name=\"lcity\" value=\"$lcity\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "<td>Right city:</td>\n";
    print $sock "<td><input type=\"text\" size=\"5\" name=\"rcity\" value=\"$rcity\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "<td>Hours without events:</td>\n";
    print $sock "<td><input type=\"checkbox\" name=\"allhours\">List all hours</td></td>\n";
    print $sock "</tr>\n";

                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
