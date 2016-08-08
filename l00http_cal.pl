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
my ($results);
my (%list, %tbl, @outs, $filter);


# defaults
my $cellwd = 5;
my $cellht = 4;
my $lenwk = 10;
my $prewk =  0;
my $border = 0;        # text border on both sides of cell

$filter = '.';



sub l00http_cal_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "cal: Displaying a calendar rendered from cal.txt";
}


sub l00http_cal_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($rpt, $now, $buf, $tmp, $table, $pname, $fname, $lnno);

    # get current date/time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $mon++;
    # convert to week number
    ($thisweek, $now) = &l00mktime::weekno ($year, $mon, $mday);

    #: open input file and scan calendar inputs
    if (defined ($form->{'path'}) && length ($form->{'path'}) > 6) {
        $fullpathname = $form->{'path'};
    } else {
        $fullpathname = $ctrl->{'workdir'} . "l00_cal.txt";
    }
    print "cal: input file is >$fullpathname<\n", if ($ctrl->{'debug'} >= 3);
    ($pname, $fname) = $fullpathname =~ /^(.+\/)([^\/]+)$/;

    # handling moving lnno to moveto
    if (defined ($form->{'lnno'}) && defined ($form->{'moveto'})) {
        # redirect back to calendar
        $tmp = "<META http-equiv=\"refresh\" content=\"0;URL=/cal.htm?path=$fullpathname\">\r\n";
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $tmp . $ctrl->{'htmlhead2'};
        print $sock "$ctrl->{'home'} - $ctrl->{'HOME'} ";
        #            <a href=\"/ls.htm?path=$fullpathname\">$fullpathname</a>\n";
        print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a><a href=\"/ls.htm?path=$pname$fname\">$fname</a>\n";

        if (open (IN, "<$fullpathname")) {
            $buf = '';
            $lnno = 0;
            while (<IN>) {
			    $lnno++;
				if ($lnno == $form->{'lnno'}) {
                    ($date, $len, $todo) = split (',', $_);
			        $buf .= "$form->{'moveto'},$len,$todo\n";
				} else {
				    $buf .= $_;
				}
			}
            close (IN);
            &l00backup::backupfile ($ctrl, $fullpathname, 0, 0);
            open (OU, ">$fullpathname");
			print OU $buf;
			close (OU);
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
    if (defined ($form->{'filter'})) {
        $filter = $form->{'filter'};
        if ($filter =~ /^ *$/) {
            $filter = '.';
        }
    }


    # 1) Read a description file

    undef %db;
    if (open (IN, "<$fullpathname")) {
        $lnno = 0;
        while (<IN>) {
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
            ($date, $len, $todo) = split (',', $_);
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
                @db{"$date`$len`$todo"} = 'x';
            }
        }
        close (IN);
        if (defined ($form->{'today'}))  {
            @db{sprintf("%d/%d/%d",$year+1900,$mon,$mday)."`1`<font style=\"color:black;background-color:lime\">NOW</font>"} = 'x';
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
        ($date, $len, $todo) = split ('`', $k);
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
            } else {
                # else make a link to send text to clip.htm
                $tmp = $todo;
                $tmp =~ s/<.+?>//g;
                $tmp =~ s/^ +//;
                $tmp =~ s/ +$//;
                $todo = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=".&l00httpd::urlencode ($tmp)."\" target=newwin>$todo</a>";
            }
            if (defined ($list {"$wkno`$dayofwk"})) {
                $list {"$wkno`$dayofwk"} .= " ! $todo";
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
        }
    }
    foreach $wk (sort keys %list) {
        ($wkno, $dayofwk) = split ('`', $wk);
        $todo = $list {$wk};
        $wkos = $wkno - $firstweek;
        $idx = sprintf ("%02d%d", $wkos, $dayofwk);
        $tbl{"$idx"} .= "<br><small>$todo</small>";
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
    print $sock "<p><a href=\"#top\">Jump to top</a><be>\n";

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
    print $sock "            <td>Filter:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"12\" name=\"filter\" value=\"$filter\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"today\">Mark NOW</td>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"printascii\">Print ASCII</td>\n";
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
