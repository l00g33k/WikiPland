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
my ($tr_clockhtml, $tr_clockjs);
my ($lineproc);

$blanks = 0;
$lineproc = '';

my (%colorlu, %colorfg, $colorlukeys);
$colorlukeys = 'rylsafgodGDbSpLTBhu';
$colorlu{'r'} = 'red';              $colorfg{'r'} = 'yellow';
$colorlu{'y'} = 'yellow';           $colorfg{'y'} = 'black';
$colorlu{'l'} = 'lime';             $colorfg{'l'} = 'black';
$colorlu{'s'} = 'silver';           $colorfg{'s'} = 'black';
$colorlu{'a'} = 'aqua';             $colorfg{'a'} = 'black';
$colorlu{'f'} = 'fuchsia';          $colorfg{'f'} = 'yellow';
$colorlu{'g'} = 'gray';             $colorfg{'g'} = 'black';
$colorlu{'o'} = 'olive';            $colorfg{'o'} = 'black';
$colorlu{'d'} = 'gold';             $colorfg{'d'} = 'black';
$colorlu{'G'} = 'green';            $colorfg{'G'} = 'LightGray';
$colorlu{'D'} = 'DeepPink';         $colorfg{'D'} = 'black';
$colorlu{'b'} = 'Brown';            $colorfg{'b'} = 'black';
$colorlu{'S'} = 'DeepSkyBlue';      $colorfg{'S'} = 'black';
$colorlu{'p'} = 'Purple';           $colorfg{'p'} = 'black';
$colorlu{'L'} = 'LightGray';        $colorfg{'L'} = 'black';
$colorlu{'T'} = 'Teal';             $colorfg{'T'} = 'LightGray';
$colorlu{'B'} = 'SandyBrown';       $colorfg{'B'} = 'black';
$colorlu{'h'} = 'HotPink';          $colorfg{'h'} = 'black';
$colorlu{'u'} = 'blue';             $colorfg{'u'} = 'black';


$tr_clockjs = <<EOB;
<style type="text/css">
#clock   { font-family: Arial, Helvetica, sans-serif; font-size: 0.9em; color: white; background-color: black; border: 2px solid purple; padding: 2px; }
#swatch   { font-family: Arial, Helvetica, sans-serif; font-size: 0.9em; color: white; background-color: black; border: 2px solid purple; padding: 2px; }
</style>

<script Language="JavaScript">
var timerID = null;
var timerRunning = false;
var startsec;
var nowidx, nows;
var itvmin;
var countAstat = 1;
var countAtime = 0;

function stopclock (){
    if(timerRunning)
        clearTimeout(timerID);
    timerRunning = false;
}

function startclock () {
    // Make sure the clock is stopped
    stopclock();
    var currentTime = new Date ( );

    var currentHours = currentTime.getHours ( );
    var currentMinutes = currentTime.getMinutes ( );
    var currentSeconds = currentTime.getSeconds ( );
    startsec = currentSeconds + currentMinutes * 60 + currentHours * 3600;

    countAtime = (currentTime.getTime () -
                  currentTime.getTime () % 1000) / 1000;
    countAstat = 1;

    updateClock();
}

function updateClock () {
    var currentTime = new Date ( );

    var currentHours = currentTime.getHours ( );
    var currentMinutes = currentTime.getMinutes ( );
    var currentSeconds = currentTime.getSeconds ( );

    // calculate nowidx before padding leading 0
    nowidx = Math.floor ((currentHours * 60 + currentMinutes) / itvmin); 
    if (currentHours < 4) {
        nowidx += 24 * 60 / itvmin;
    }
    nowidx = 'ln' + ( nowidx < 10 ? "0" : "") + 
                    ( nowidx < 100 ? "0" : "") + 
                    ( nowidx < 1000 ? "0" : "") + 
                    nowidx;
    //console.log(currentHours, ':', currentMinutes, ' nowidx = ', nowidx, ' itvmin = ', itvmin);

    // Pad the minutes and seconds with leading zeros, if required
    currentHours   = ( currentHours < 10 ? "0" : "" ) + currentHours;
    currentMinutes = ( currentMinutes < 10 ? "0" : "" ) + currentMinutes;
    currentSeconds = ( currentSeconds < 10 ? "0" : "" ) + currentSeconds;
    // Compose the string for display
    var currentTimeString = currentHours + ":" + currentMinutes + ":" + currentSeconds;
    // Update the time display
    document.getElementById("clock").firstChild.nodeValue = currentTimeString;


    // search all element list for current time id
    var el, ii, text;
    //nows.forEach((now)=> { // Palm doesn't support forEach/=> ??
    for (ii = 0; ii <= nows.length; ii++) {
        now = nows[ii];
        el = document.getElementById(now);
        if (el) {
            text = el.firstChild.nodeValue;
            if (now == nowidx) {
                // still doesn't work on Palm
                el.setAttribute("style","background:cyan;");
                // append * if not already; find/search failed on Palm
                if (text.length < 6) {
                    el.firstChild.nodeValue = '-- ' + text;
                }
            } else {
                el.setAttribute("style","background:white;");
                if (text.length > 6) {
                    el.firstChild.nodeValue = text.substr(4, 5);
                }
            }
        }
    //});
    }

    timerID = setTimeout("updateClock()",1000);
    timerRunning = true;

    var tmp = (currentTime.getTime () -
               currentTime.getTime () % 1000) / 1000;
    if (countAstat) {
        tmp = tmp - countAtime;
    } else {
        tmp = countAtime;
    }
    currentSeconds = tmp % 60;

    tmp = (tmp - currentSeconds) / 60;

    currentMinutes = tmp;



    // Pad the minutes and seconds with leading zeros, if required

    currentMinutes = ( currentMinutes < 10 ? "0" : "" ) + currentMinutes;

    currentSeconds = ( currentSeconds < 10 ? "0" : "" ) + currentSeconds;

    // Compose the string for display

    var currentTimeString = currentMinutes + ":" + currentSeconds;

    // Update the stopwatch display
    document.getElementById("swatch").firstChild.nodeValue = currentTimeString;
}

</script>
EOB

$tr_clockhtml = <<EOB;
<table border=1 cellpadding=5 cellspacing=0>
    <tr><td>
        <span id="clock">00:00:00</span>
    </td><td>
        <form name="clock" onSubmit="0">
            <input type="button" name="start" value="&gt;&gt;"  onClick="startclock()" accesskey=\"r\">
            <input type="button" name="stop"  value="&nbsp;||&nbsp;" onClick="stopclock()">
        </form>
    </td><td>
        <span id="swatch">00:00</span>
    </td></tr>
</table>
EOB


sub l00http_tr_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "tr: Displaying a timeline of the tasks to be done today";
}


sub l00http_tr_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($blkln, $citydiff, $buffer, $bufinc, $incpath, $pathbase);
    my ($filter, $filter_hide, $clocknotshown, $notbare);

    $filter = '';

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);

    if ((defined ($form->{'itvmin'})) && ($form->{'itvmin'} =~ /(\d+)/)) {
        $itvmin = $1;
    }
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        $form->{'fname'} = $form->{'path'};
    }
    if ((!defined ($form->{'fname'})) || (length ($form->{'fname'}) < 6)) {
        $form->{'fname'} = "$ctrl->{'workdir'}l00_tr.txt";
    }

    if ((defined ($form->{'filter'})) && (length ($form->{'filter'}) > 0)) {
        $filter = $form->{'filter'};
    }
    if ((defined ($form->{'lineproc'})) && (length ($form->{'lineproc'}) > 0)) {
        $lineproc = $form->{'lineproc'};
    }
    if ((defined ($form->{'bare'})) && ($form->{'bare'} eq 'on')) {
        $notbare = 0;
    } else {
        $notbare = 1;
    }

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>tr</title>\n$tr_clockjs" . "</head>\x0D\x0A<body onload=\"startclock();\">\n";
    if ($notbare) {
        print $sock "<a name=\"__top__\"></a>";
        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
        print $sock "<a href=\"#__end__\">end</a> - \n";
        print $sock "Input: <a href=\"/ls.htm?path=$form->{'fname'}\">$form->{'fname'}</a><br>\n";
    }

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
#       $outs [$ii] = sprintf ("$prefix%02d%02d$suffix", int ((($itvmin * $ii) % (24 * 60)) / 60), ($itvmin * $ii) % 60);
        $outs [$ii] = sprintf ("<span id=\"ln%04d\">$prefix%02d%02d$suffix</span>", $ii, int ((($itvmin * $ii) % (24 * 60)) / 60), ($itvmin * $ii) % 60);
        if ($blanks == 0) {
            $blanks = length($outs [$ii]);
        }
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
    if ((defined ($form->{'fname'}) && (&l00httpd::l00freadOpen($ctrl, $form->{'fname'})))) {
        $bufinc = '';
        $buffer = &l00httpd::l00freadAll($ctrl);
        foreach $_ (split ("\n", $buffer)) {
            s/[\r\n]//g;
            if (/^%INCLUDE<(.+?)>%/) {
                $incpath = $1;
                $pathbase = '';
                if ($incpath =~ /^\.\//) {
                    # find base dir of input file
                    $pathbase = $form->{'fname'};
                    $pathbase =~ s/([\\\/])[^\\\/]+$/$1/;
                }
                if (&l00httpd::l00freadOpen($ctrl, "$pathbase$incpath")) {
                    $bufinc .= &l00httpd::l00freadAll($ctrl);
                }
            } else {
                $bufinc .= "$_\n";
            }
        }
        $filter_hide = 1;
        foreach $_ (split ("\n", $bufinc)) {
            s/\r//g;     # get rid of CR/LF
            s/\n//g;
            # filter
            if ($filter ne '') {
                if (/$filter/) {
                    $filter_hide = !$filter_hide;
                    next;
                }
                if ($filter_hide) {
                    next;
                }
            }
            if ($lineproc ne '') {
                eval $lineproc;
            }
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
                $minoff = $hour * 60 + int ($min / $itvmin) * $itvmin;
            } elsif (($hr,$mn, $desc) = /^@(\d\d)(\d\d) *(.*)$/) {
                #    @1430 : start time in 24 hour format
                if ($hr < 4) {
                    # assume 4 am is the 4 am of the following day
                    $hr += 24;
                }
                $minoff = $hr * 60 + $mn;
                if (defined($desc) && (length($desc) > 0) && ($desc !~ /^#/)) {
                    $outs [int ($minoff / $itvmin)] .= " $desc ";
                }
            } elsif (($len,$desc) = /^=(\d+) +(.+)/) {
                # append task descriptions to time slot spanning the length
                for ($ii = $minoff; $ii < $minoff + $len; $ii += $itvmin) {
                    $outs [int ($ii / $itvmin)] .= " $desc ($len) ";
                }
                $minoff = $ii;
            } elsif (($desc) = / *(.+) */) {
                # default to $itvmin min
                $outs [int ($minoff / $itvmin)] .= " $desc ($itvmin) ";
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
#   $blanks = 5;
    if (defined ($form->{'diff'})) {
        if (($citydiff) = $form->{'diff'} =~ /(\d+)/) {
            if (($citydiff > -24) && 
                ($citydiff < 24) && 
                ($citydiff != 0)) {
                # display a second column of time in a different timezone, nice for timezone crossing flight
#               $blanks = 10;
                $blanks *= 2;
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
    if ($notbare) {
        print $sock "<a href=\"#now\">now</a>\n";
        print $sock " - <a href=\"/tr.htm?path=$form->{'fname'}\">refresh</a>\n";
        if ($filter ne '') {
            print $sock " - filter '$filter' in effect\n";
        }
        print $sock "<br><pre>\n";
    } else {
        print $sock "<pre>\n";
    }

    # 3) Display the time slots

    # display the time slot
    $blkln = 0;
    $clocknotshown = 1;
    if ($notbare) {
        printf $sock ("<script Language=\"JavaScript\">nows = []; itvmin = $itvmin;</script>", $now);
    }
    for ($ii = $iist; $ii <= $iien; $ii++) {
        # *l*color bold**
        $outs[$ii] =~       s/ \*([$colorlukeys])\*([^*]+?)\*\*$/ <strong><font style="color:$colorfg{$1};background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
        $outs[$ii] =~       s/^\*([$colorlukeys])\*([^*]+?)\*\* / <strong><font style="color:$colorfg{$1};background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
        $outs[$ii] =~       s/^\*([$colorlukeys])\*([^*]+?)\*\*$/ <strong><font style="color:$colorfg{$1};background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
        $outs[$ii] =~ s/([ >|])\*([$colorlukeys])\*([^*]+?)\*\*([ <\]])/$1<strong><font style="color:$colorfg{$2};background-color:$colorlu{$2}">$3<\/font><\/strong>$4/g;

        if ($ii == $now) {
            $clocknotshown = 1;
            if ($notbare) {
                print $sock "</pre><a name=\"now\"></a>$tr_clockhtml\nnow - " .substr($ctrl->{'now_string'}, 9, 4)." - <a href=\"#__end__\">end</a> - <a href=\"#__top__\">top</a>";
                print $sock " - <a href=\"/tr.htm?path=$form->{'fname'}\">refresh</a> <pre>\n";
            }
            $blkln = 0; # force time display for time 'now'
            #print "$now $outs[$ii]\n";
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
        if ($notbare) {
            printf $sock ("<script Language=\"JavaScript\">nows.push('ln%04d');</script>", $ii);
        }
    }
    if ($notbare) {
        if ($clocknotshown) {
            print $sock "</pre><a name=\"now\"></a>$tr_clockhtml\nnow - " .substr($ctrl->{'now_string'}, 9, 4)." - <a href=\"#__end__\">end</a> - <a href=\"#__top__\">top</a>";
            print $sock " - <a href=\"/tr.htm?path=$form->{'fname'}\">refresh</a> <pre>\n";
        }
    }
    print $sock "</pre>\n";

    if ($notbare) {
        if ($now >= $iien) {
            print $sock "<a name=\"now\">now</a> ".substr($ctrl->{'now_string'}, 9, 4)."\n";
        }
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

    if ($notbare) {
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
        print $sock "<td><input type=\"checkbox\" name=\"allhours\">List all hours</td>\n";
        print $sock "</tr>\n";
    
                                                    
        print $sock "    <tr>\n";
        print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"S&#818;ubmit\" accesskey=\"s\"></td>\n";
        print $sock "        <td><input type=\"checkbox\" name=\"bare\" accesskey=\"b\">b&#818;are without form</td>\n";
        print $sock "    </tr>\n";
    
        print $sock "<tr>\n";
        print $sock "<td>Slot length (min.):</td>\n";
    #   print $sock "<td><input type=\"text\" size=\"5\" name=\"rcity\" value=\"$rcity\"></td>\n";
        print $sock "<td><input type=\"text\" size=\"3\" name=\"itvmin\" value=\"$itvmin\"></td>\n";
        print $sock "</tr>\n";
    
        print $sock "<tr>\n";
        print $sock "<td>Active line marker:</td>\n";
        print $sock "<td><input type=\"text\" size=\"12\" name=\"filter\" value=\"$filter\"></td>\n";
        print $sock "</tr>\n";
    
        print $sock "<tr>\n";
        print $sock "<td>Line processor:</td>\n";
        print $sock "<td><input type=\"text\" size=\"12\" name=\"lineproc\" value=\"$lineproc\"></td>\n";
        print $sock "</tr>\n";
    
    
        print $sock "</table>\n";
        print $sock "</form>\n";
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
