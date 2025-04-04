use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# This module display a calendar

# What it does:
# 1) Read a description file
# 1.1) Each description is a single line with 2 comma separating 
#      3 fields:
#      Field 1 : year/month/day
#      Field 2 : number of days
#      Field 3 : description (no comma allowed)
# 2) Render an HTML table as well as an ASCII table of the calendar
# 3) Display form controls

use l00mktime;

my %config = (proc => "l00http_cal_proc",
              desc => "l00http_cal_desc");

my ($celllen, $date, $day, $dayofwk, $days, $finalweek);
my ($firstweek, $fullpathname, $gshour, $gsisdst);
my ($gsmday, $gsmin, $gsmon, $gssec, $gswday, $gsyday);
my ($gsyear, $hdr, $idx, $ii, $jj, $jj1, $jj2, $julian, $k, $ldate);
my ($len, $ln, $outsz, $thisweek, $todo, $wk, $wkce);
my ($wkln, $wkno, $wkos, $xx, $yy, %db);
my ($results, $daywkno);
my (%list, %tbl, @outs, $filter, $today);


# defaults
my $cellwd = 5;
my $cellht = 4;
my $lenwk = 10;
my $prewk =  0;
my $border = 0;        # text border on both sides of cell

$filter = '.';
$daywkno = '';
$today = 'on';

sub l00http_cal_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "cal: Displaying a calendar rendered from cal.txt";
}


sub l00http_cal_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($rpt, $now, $buf, $tmp, $tmp2, $table, $pname, $fname, $lnno);
    my ($day1, $dayno, $wkno, $dayno2, $wkno2, @todos, $lastdate, $rel,
        @includes, $incpath, $pathbase, $includefn, %calfilters);

    undef %calfilters;

    # get current date/time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $mon++;
    # convert to week number
    ($thisweek, $now) = &l00mktime::weekno ($year, $mon, $mday);

    $day1 = &l00mktime::mktime ($year, 0, 1, 0, 0, 0) / (24 * 3600) - 1;

    #: open input file and scan calendar inputs
    if (defined ($form->{'path'}) && length ($form->{'path'}) > 6) {
        $fullpathname = $form->{'path'};
    } else {
        $fullpathname = $ctrl->{'workdir'} . "l00_cal.txt";
    }
    print "cal: input file is >$fullpathname<\n", if ($ctrl->{'debug'} >= 3);
    l00httpd::dbp($config{'desc'}, "input file is >$fullpathname<\n"), if ($ctrl->{'debug'} >= 3);
    ($pname, $fname) = $fullpathname =~ /^(.+\/)([^\/]+)$/;

    # handling moving lnno to moveto
    if (defined ($form->{'lnno'}) && defined ($form->{'moveto'})) {
        # redirect back to calendar
        $tmp = "<META http-equiv=\"refresh\" content=\"0;URL=/cal.htm?path=$fullpathname\">\r\n";
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $tmp . $ctrl->{'htmlhead2'};
        print $sock "$ctrl->{'home'} - $ctrl->{'HOME'} ";
        #            <a href=\"/ls.htm?path=$fullpathname\">$fullpathname</a>\n";
        print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a><a href=\"/ls.htm?path=$pname$fname\">$fname</a>\n";

        if (&l00httpd::l00freadOpen($ctrl, $fullpathname)) {
            $buf = '';
            $lnno = 0;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $lnno++;
                if ($lnno == $form->{'lnno'}) {
                    ($date, $len, @todos) = split (',', $_);
                    $todo = join(',', @todos);
                    $buf .= "$form->{'moveto'},$len,$todo\n";
                } else {
                    $buf .= $_;
                }
            }
            &l00backup::backupfile ($ctrl, $fullpathname, 0, 0);
            &l00httpd::l00fwriteOpen($ctrl, $fullpathname);
            &l00httpd::l00fwriteBuf($ctrl, $buf);
            &l00httpd::l00fwriteClose($ctrl);
        }
        print $sock "<p><a href=\"/cal.htm?path=$fullpathname\">Return to calendar</a>\n";
        print $sock $ctrl->{'htmlfoot'};
        return;
    }

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a href=\"/recedit.htm?record1=^\\d%2B\\%2F\\d%2B\\%2F\\d%2B\\%2B%2A\\d%2A,\\d%2B,&path=$fullpathname\">Recedit</a> - \n";
    print $sock "<a href=\"/ls.htm?path=$fullpathname\">$fullpathname</a>\n";
    print $sock "<a name=\"top\"></a>\n";
    print $sock " - <a href=\"#__end__\">Jump to end</a>\n";
    print $sock " - <a href=\"/cal.htm?path=$fullpathname&today=on#__now__\">NOW</a><p>\n";

    # remember parameters if new ones are provided
    if (defined ($form->{'cellwd'}) && ($form->{'cellwd'} =~ /(\d+)/)) {
        $cellwd = $1;
    }
    if (defined ($form->{'cellht'}) && ($form->{'cellht'} =~ /(\d+)/)) {
        $cellht = $1;
    }
    if (defined ($form->{'lenwk'}) && ($form->{'lenwk'} =~ /(\d+)/)) {
        $lenwk = $1;
    }
    if (defined ($form->{'prewk'}) && ($form->{'prewk'} =~ /(\d+)/)) {
        $prewk = $1;
    }
    if (defined ($form->{'today'}) && ($form->{'today'} eq 'on')) {
        $today = 'on';
    } else {
        $today = 'off';
    }
    if (defined ($form->{'filter'})) {
        $filter = $form->{'filter'};
        if ($filter =~ /^ *$/) {
            $filter = '.';
        }
    }

    $daywkno = '';
    if (defined ($form->{'daywkno'}) && ($form->{'daywkno'} eq 'on')) {
        $daywkno = 'checked';
    }

    # 1) Read a description file

    undef %db;
    undef @includes;
    if (&l00httpd::l00freadOpen($ctrl, $fullpathname)) {
        $lnno = 0;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/[\r\n]//g;
            $lnno++;
            if (/^#/) {
                # # in column 1 is remark
                next;
            }

            # include file
            if (/^%INCLUDE<(.+?)>%/) {
                $incpath = $1;
                $pathbase = '';
                if ($incpath =~ /^\.\//) {
                    # find base dir of input file
                    $pathbase = $fullpathname;
                    $pathbase =~ s/([\\\/])[^\\\/]+$/$1/;
                }
                push (@includes, "$pathbase$incpath");
            }

            # filters
            # %CALFILTER~name~regex%
            if (/^%CALFILTER~(.+?)~(.+)%$/) {
                $calfilters{$1} = $2;
            }


            if (!/^[0-9\$]/) {
                # must start with numeric
                next;
            }
            if (!/$filter/i) {
                # not matching filter
                next;
            }

            # 2021/9/17,4,todo
            # 2010/10/14+7,1,trash
            l00httpd::dbp($config{'desc'}, "line >$_<\n"), if ($ctrl->{'debug'} >= 4);
            if (/^20\d\d\/\d\d*\/\d\d*,\d+,/ ||
                /^20\d\d\/\d\d*\/\d\d*\+\d+,\d+,/) {
                ($date, $len, @todos) = split (',', $_);
                if ($date !~ /\+/) {
                    # save last date
                    @_ = split('/', $date);
                    $tmp = l00httpd::time2now_string(l00httpd::now_string2time(sprintf("%04d%02d%02d 000000", $_[0], $_[1], $_[2])) + (3600 * 24 * ($len - 1)));
                    @_ = $tmp =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
                    $lastdate = sprintf("%d/%d/%d", $_[0], $_[1], $_[2]);
                    l00httpd::dbp($config{'desc'}, "absolute lastdate >$lastdate<\n"), if ($ctrl->{'debug'} >= 4);
                }
                $todo = join(',', @todos);
                if (defined ($date) && defined ($len) && defined ($todo)) {
                    if (defined ($form->{'movefrom'})) {
                        # selected movefrom date, list items for picking
                        if ($date eq $form->{'movefrom'}) {
                            print $sock "<br>Choose to move: <a href=\"/cal.htm?path=$fullpathname&movelnno=$lnno\">$_</a>\n";
                        }
                    }
                    if (defined ($form->{'movelnno'})) {
                        # Announce item to move picked
                        if ($lnno == $form->{'movelnno'}) {
                            print $sock "<br>Moving: $_<br>Pick 'to' date on left half of date<br>\n";
                        }
                    }
                    print "cal: >$todo<>$len<>$date<\n", if ($ctrl->{'debug'} >= 3);
                    if ($len <= -1) {
                        # negative length means given date is the last day.
                        # adjust $date backward so duration ends on the given date
                        $len = -$len;
                        ($year,$mon, $mday,) = split ('/', $date);
                        $year -= 1900;
                        ($thisweek, $julian) = &l00mktime::weekno ($year, $mon, $mday);
                        ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                       gmtime (($julian - $len + 1) * 3600 * 24);
                        $gsmon++;
                        $gsyear += 1900;
                        $date = "$gsyear/$gsmon/$gsmday";
                    }
                    @db{"$date`$len`$todo"} = 'x';
                }
            }
            if (/^\$([+-]\d+),\d+,/) {
                $rel = $1;
                ($date, $len, @todos) = split (',', $_);
                $todo = join(',', @todos);
                if (defined ($date) && defined ($len) && defined ($todo)) {
                    @_ = split('/', $lastdate);
                    $tmp = l00httpd::time2now_string(l00httpd::now_string2time(sprintf("%04d%02d%02d 000000", $_[0], $_[1], $_[2])) + (3600 * 24 * ($rel)));
                    @_ = $tmp =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
                    $date = sprintf("%d/%d/%d", $_[0], $_[1], $_[2]);
                    l00httpd::dbp($config{'desc'}, "relative start $tmp; $date`$len`$todo\n"), if ($ctrl->{'debug'} >= 4);
                    @db{"$date`$len`$todo"} = 'x';
                    $tmp = l00httpd::time2now_string(l00httpd::now_string2time(sprintf("%04d%02d%02d 000000", $_[0], $_[1], $_[2])) + (3600 * 24 * ($len - 1)));
                    @_ = $tmp =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
                    $lastdate = sprintf("%d/%d/%d", $_[0], $_[1], $_[2]);
                    l00httpd::dbp($config{'desc'}, "relative lastdate: $tmp; $lastdate $len\n"), if ($ctrl->{'debug'} >= 4);
                }
            }
        }
        if (defined ($form->{'today'}))  {
            @db{sprintf("%d/%d/%d",$year+1900,$mon,$mday)."`1`<font style=\"color:black;background-color:lime\">NOW</font><a name=\"__now__\"></a>"} = 'x';
        }
    }
    foreach $includefn (@includes) {
        if (&l00httpd::l00freadOpen($ctrl, $includefn)) {
            $lnno = 0;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                chomp;
                $lnno++;
                if (/^#/) {
                # # in column 1 is remark
                    next;
                }
                if (!/^\d/) {
                # must start with numeric
                    next;
                }
                if (!/$filter/i) {
                    # not matching filter
                    next;
                }

                if (/^20\d\d\/\d\d*\/\d\d*,\d+,/ ||
                    /^20\d\d\/\d\d*\/\d\d*\+\d+,\d+,/) {
                    ($date, $len, @todos) = split (',', $_);
                    $todo = join(',', @todos);
                    if (defined ($date) && defined ($len) && defined ($todo)) {
                        print "cal: >$todo<>$len<>$date<\n", if ($ctrl->{'debug'} >= 3);
                        if ($len <= -1) {
                            # negative length means given date is the last day.
                            # adjust $date backward so duration ends on the given date
                            $len = -$len;
                            ($year,$mon, $mday,) = split ('/', $date);
                            $year -= 1900;
                            ($thisweek, $julian) = &l00mktime::weekno ($year, $mon, $mday);
                            ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                           gmtime (($julian - $len + 1) * 3600 * 24);
                            $gsmon++;
                            $gsyear += 1900;
                            $date = "$gsyear/$gsmon/$gsmday";
                        }
                        @db{"$date`$len`$todo"} = 'x';
                    }
                }
            }
        }
    }

    undef $todo;
    undef $hour;
    undef $date;
    #: create cell content

    $ldate = "";
    $firstweek = $thisweek;
    $finalweek = $thisweek;

    undef  %list;
    foreach $k (sort keys %db) {
        ($date, $len, @todos) = split ('`', $k);
        $todo = join(',', @todos);
        # repeating
        $rpt = 0;
        if ($date =~ /^(.+)\+(.+)$/) {
            $date = $1;
            $rpt = $2;
        } elsif ($len <= 3) {
            # color $todo
            $todo = "<font style=\"color:black;background-color:aqua\">$todo</font>";
        } else {
            # color $todo
            $todo = "<font style=\"color:black;background-color:silver\">$todo</font>";
        }
        if ($ldate ne $date) {
            ($year,$mon, $mday,) = split ('/', $date);
            $year -= 1900;
            ($thisweek, $julian) = &l00mktime::weekno ($year, $mon, $mday);
            #print __LINE__ . " ($thisweek, $julian) ($year, $mon, $mday)\n";
            $ldate = $date;
        }
        #print "cal: $date $rpt; j $julian ", $julian - $now, "\n";
        if ($rpt > 0) {
            while ($julian < $now) {
                $julian += $rpt;
            }
            $ldate = ''; # force weekno calc
        }
        $jj = $julian;
        for ($days = 1; $days <= $len; $days++) {
            ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                                gmtime ($jj * 3600 * 24);
            $gsmon++;
            $dayofwk =   ($jj + 3) % 7;
            $wkno = int (($jj + 3) / 7);
            if ($firstweek > $wkno) {
                $firstweek = $wkno;
            }
            if ($finalweek < $wkno) {
                $finalweek = $wkno;
            }
            if ($todo =~ /\[\[.+\]\]/) {
                # if it is a link, put in [link]
                $todo = "&#91;$todo&#93;";
            } elsif (($tmp, $tmp2) = $todo =~ /^(.+?)\|\|(.+)$/) {
                # send tmp2 to clipboard
                $todo = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=".&l00httpd::urlencode ($tmp2)."\" target=newwin>$tmp</a>";
            } else {
                # else make a link to send text to clip.htm
                $tmp = $todo;
                $tmp =~ s/<.+?>//g;
                $tmp =~ s/^ +//;
                $tmp =~ s/ +$//;
                $todo = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=".&l00httpd::urlencode ($tmp)."\" target=newwin>$todo</a>";
            }
            if (defined ($list {"$wkno`$dayofwk"})) {
                if (defined ($form->{'newline'}))  {
                    $list {"$wkno`$dayofwk"} .= "<br>$todo";
                } else {
                    $list {"$wkno`$dayofwk"} .= " ! $todo";
                }
            } else {
                $list {"$wkno`$dayofwk"} = $todo;
            }

            if ($ctrl->{'debug'} >= 5) {
                ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                                gmtime (($wkno * 7 + $dayofwk - 3) * 3600 * 24);
                $gsmon++;
                printf ("$date %3d/%02d/%02d ", $gsyear + 1900, $gsmon, $gsmday);
                print "\$list{\"$wkno`$dayofwk\"} = $todo;\n";
            }
            $jj++;
        }
    }
    if ($lenwk > 0) {
        $firstweek -= $prewk;
        $finalweek = $firstweek + $lenwk + $prewk;
    }



    $wkln = "+" . "-" x ($cellwd - 1);
    $wkln = $wkln x 7 . "+";
    substr ($wkln, 0, 1) = "+";
    $wkce = $wkln;
    $wkce =~ s/-/ /g;
    $wkce =~ s/\+/|/g;


    # 2) Render an HTML table as well as an ASCII table of the calendar

    #: create output table
    #html table
    undef %tbl;
    for ($wk = $firstweek; $wk <= $finalweek; $wk++) {
        for ($day = 0; $day < 7; $day++) {
            ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                          gmtime (($wk * 7 + $day - 3) * 3600 * 24);
            $gsmon++;
            $gsyear += 1900;
            $jj1 = sprintf ("%x", $gsmon);
            $jj2 = sprintf ("%2d", $gsmday);
            $buf = "$gsyear%2F$gsmon%2F$gsmday";
            if (defined ($form->{'movelnno'})) {
                $jj = "<font style=\"color:black;background-color:lime\"><a href=\"/cal.htm?path=$fullpathname&lnno=$form->{'movelnno'}&moveto=$buf\">mv$jj1</a></font>";
            } else {
                $jj = "<a href=\"/cal.htm?path=$fullpathname&movefrom=$buf\">$jj1</a>";
            }
            $buf = "$gsyear%2F$gsmon%2F$gsmday,1,";
            $jj .= "<a href=\"/blogtag.htm?path=$fullpathname&buffer=$buf&blog=\">$jj2</a>";
            $idx = sprintf ("%02d%d", $wk - $firstweek, $day);
            if ($day < 5) {
                $tbl{"$idx"} = "<i><small>$jj</small></i>";
            } else {
                $tbl{"$idx"} = "<small>$jj</small>";
            }
            if ($daywkno eq 'checked') {
                $dayno = ($wk * 7 + $day - 3) - $day1;
                $wkno = int($wk - $day1 / 7) + 1;
                if ($dayno > 365) {
                    # cheating, simpler
                    $dayno -= 365;
                    $wkno -= 52;
                }
                $dayno2 = 366 - $dayno;
                $wkno2 = 53 - $wkno;
                $tbl{"$idx"} .= " <small>$dayno-$dayno2/$wkno-$wkno2</small>";
            }
        }
    }
    foreach $wk (sort keys %list) {
        ($wkno, $dayofwk) = split ('`', $wk);
        $todo = $list {$wk};
        $wkos = $wkno - $firstweek;
        $idx = sprintf ("%02d%d", $wkos, $dayofwk);
        $tbl{"$idx"} .= "<br><small>$todo</small>";
    }

    # make calfilter links
    $buf = '';
    foreach $_ (sort keys %calfilters) {
        $buf .= " - <a href=\"/cal.htm?path=$fullpathname&lenwk=$lenwk&prewk=$prewk&today=$today&filter=".&l00httpd::urlencode ($calfilters{$_})."\">$_</a>\n";
    }
    if ($buf ne '') {
        print $sock "CALFILTER: $buf - <a href=\"/cal.htm?path=$fullpathname&lenwk=$lenwk&prewk=$prewk&today=$today&filter=.\">All</a>\<p>\n";
    }



    $table = "||Mon||Tues||Wed||Thu||Fri||Sat||Sun||\n";
    for ($wk = $firstweek; $wk <= $finalweek; $wk++) {
        for ($day = 0; $day < 7; $day++) {
            $idx = sprintf ("%02d%d", $wk - $firstweek, $day);
            $tmp = $tbl{$idx};
            $tmp =~ s/\[\[(.+?)\|(.+?)\]\]/<a href=\"$1\">$2<\/a>/g;
            $tmp =~ s/\[\[(.+?)\|(.+?)\]\]/<a href=\"$1\">$2<\/a>/g;
            $tmp =~ s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm?path=$pname$2.txt\">$2</a>|g;
            # For http(s) not preceeded by =" becomes whatever [[http...]]
            $tmp =~ s|([^="][^">])(https*://[^ ]+)|$1 <a href=\"$2\">$2<\/a> |g;
            # convert \n to <br>
            $tmp =~ s/\\n/<br>/g;
            # print $sock "<td align=\"left\" valign=\"top\">$tmp</td>\n";
            $table .= "||$tmp";
            l00httpd::dbp($config{'desc'}, "||$tmp"), if ($ctrl->{'debug'} >= 5);
        }
        $table .= "||\n";
        l00httpd::dbp($config{'desc'}, "||\n"), if ($ctrl->{'debug'} >= 5);
    }
    $table .= "<p>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $table, 0, $fname);


    undef @outs;
    $outsz = 0;
    for ($wk = $firstweek; $wk <= $finalweek; $wk++) {
        $outs [$outsz++] = $wkln;
        for ($ii = 1; $ii < $cellht; $ii++) {
            $outs [$outsz] = $wkce;
            if ($ii == 1) {
                for ($day = 0; $day < 7; $day++) {
                    ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                                      gmtime (($wk * 7 + $day - 3) * 3600 * 24);
                    $gsmon++;
                    $jj = sprintf ("%x%2d", $gsmon, $gsmday);
                    #print "y$jj\n";
                    substr ($outs [$outsz], $cellwd * $day, 3) = $jj;
                }
            }
            $outsz++;
        }
    }
    $outs [$outsz++] = $wkln;



    $hdr = 2;
    $celllen = ($cellht - $hdr) * ($cellwd - 1);
    if ($ctrl->{'debug'} >= 5) {
        print ">wkos<>dayofwk<>todo<\n";
    }
    foreach $wk (sort keys %list) {
        ($wkno, $dayofwk) = split ('`', $wk);
        $todo = $list {$wk};
        $wkos = $wkno - $firstweek;
        if ($ctrl->{'debug'} >= 5) {
            print ">$wkos<>$dayofwk<>$todo<\n";
        }
        $yy = $wkos * $cellht + $hdr;
        $xx = $dayofwk * $cellwd + 1;
        if (length ($todo) <= $celllen) {
            $todo .= " " x ($celllen - length ($todo) + 1);
        }
        for ($ii = 0; $ii < $cellht - $hdr; $ii++) {
            if (($yy >= 0) && (($yy + $ii) < $outsz)) {
                substr ($outs [$yy + $ii], $xx + $border, $cellwd - 1 - 2 * $border) = 
                    substr ($todo, ($cellwd - 1 - 2 * $border) * $ii, $cellwd - 1 - 2 * $border);
            }
        }    
    }

    # print ASCII table
    if (defined ($form->{'printascii'}) && ($form->{'printascii'} eq 'on')) {
        print $sock "<pre>\n";
        foreach $ln (@outs) {
            print $sock "$ln\n";
        }
        print $sock "</pre>\n";
    }



    # 3) Display form controls
    print $sock "<a name=\"__end__\"></a>\n";
    print $sock " - <a href=\"#top\">Jump to top</a><br>\n";


    print $sock "<form action=\"/cal.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Weeks preceeding:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"3\" name=\"prewk\" value=\"$prewk\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Length in weeks:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"3\" name=\"lenwk\" value=\"$lenwk\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Full input file path and name:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"12\" name=\"path\" value=\"$fullpathname\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Filte&#818;r:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"12\" name=\"filter\" value=\"$filter\" accesskey=\"e\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"today\">Mark NOW</td>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"S&#818;ubmit\" accesskey=\"s\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"printascii\">Print ASCII</td>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"newline\">Newline between items</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"daywkno\" $daywkno>Print day/week number</td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>ASCII cell width:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"3\" name=\"cellwd\" value=\"$cellwd\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>ASCII cell height:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"3\" name=\"cellht\" value=\"$cellht\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "</table>\n";
    print $sock "</form>\n";


    print $sock $ctrl->{'htmlfoot'};
}


\%config;
