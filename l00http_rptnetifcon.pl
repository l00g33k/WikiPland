use strict;
use warnings;
use l00backup;
use l00httpd;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_rptnetifcon_proc",
              desc => "l00http_rptnetifcon_desc");
my ($buffer, $lastbuf, $timeslot, $taillen);
$lastbuf = '';
$timeslot = 60 * 1; # seconds
$taillen = 20;

sub l00http_rptnetifcon_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "rptnetifcon: perionetifcon.pl reporter";
}

sub l00http_rptnetifcon_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $fname, $tmp, $patt, $name, $buf, $tablelen);
    my (@flds, $output, $leading, $st, $en, $trailing);
    my ($rx, $tx, $rxtx, $now, $nowlast, $svgifdt, $svgifdtlin, $svgifacc);
    my ($yr, $mo, $da, $hr, $mi, $se, $data, $timestamp);
    my ($lip, $lpt, $rip, $rpt, $conn, %connections, %hosts);
    my ($timestart, $slotrxtx, %activeconn, $lnno, %alwayson);
    my ($fpath, $bytespers, $ii, $hostip, $hostiporg);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }
    if ((defined ($form->{'taillen'})) && ($form->{'taillen'} =~ /(\d+)/)) {
        $taillen = $1;
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname rptnetifcon</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> <a href=\"#end\">Jump to end</a><br>\n";
    if (defined ($form->{'path'})) {
        $tmp = $path;
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Path</a>: ";
        ($fpath, $fname) = $form->{'path'} =~ /(.+\/)([^\/]+)/;
        print $sock "<a href=\"/ls.htm?path=$fpath\">$fpath</a>";
        print $sock "<a href=\"/view.htm?path=$form->{'path'}\">$fname</a>\n";
    }
    print $sock "<a href=\"/perionetifcon.htm\">perionetifcon</a><br>\n";


    # get submitted name and print greeting
    if (open (IN, "<$form->{'path'}")) {
        $rx = 0;
        $tx = 0;
        $rxtx = 0;
        $svgifdt = '';
        $svgifdtlin = '';
        $svgifacc = '';
        $timestart = 0;
        $lnno = 0;
        undef %activeconn;
        undef %alwayson;
#       $output = '';
#       $output .= "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
#       $output .= "<tr>\n";
#       $output .= "<td>timestamp</td>\n";
#       $output .= "<td>bytes</td>\n";
#       $output .= "<td>bytes/s</td>\n";
#       $output .= "<td>sock pairs</td>\n";
#       $output .= "</tr>\n";
        $output = "||timestamp ||bytes ||bytes/s ||sock pairs ||\n";
        $nowlast = 0;
        $bytespers = 0;
        $tablelen = 0;
        while (<IN>) {
            s/\r//;
            s/\n//;
            $lnno++;

            $timestamp = substr($_, 0, 15);
            if (($yr, $mo, $da, $hr, $mi, $se) = /^(\d\d\d\d)(\d\d)(\d\d) (\d\d)(\d\d)(\d\d),/) {
                #20131213 214805,net,tcp6,local,remote,::ffff:10.72.6.54,56079,::ffff:173.194.79.108,993,conn
                #0               1   2    3     4      5                 6     7                     8   9
                #20131213 214807,if,rx,tx,rmnet0,0,120
                # convert to seconds
                $yr -= 1900;
                $mo--;
                $now = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
                if ($timestart == 0) {
                    $timestart = $now;
                    $slotrxtx = 0;
                }
                # change : to ,
                s/(\.\d+):(\d+,)/$1,$2/g;
                @flds = split(',', $_);
                if ($flds[1] eq 'if') {
                    $rx += $flds[5];
                    $tx += $flds[6];
                    $rxtx += $flds[5] + $flds[6];
                    $tmp = $flds[5]+$flds[6];
                    if ($tmp > 0) {
                        $slotrxtx += $tmp;
                        $bytespers += $tmp;
                        if ($nowlast > 0) {
                            # compute bytes/sec
                            if (($now - $nowlast) != 0) {
                                $bytespers /= ($now - $nowlast);
                                $svgifdtlin .= "$now,$bytespers ";
                                $tmp = sprintf("%.2f", log($bytespers) / log(10));
                                $svgifdt .= "$now,$tmp ";
                                $bytespers = 0;
                            }
                        }
                    }
                    $svgifacc .= "$now,$rxtx ";
                } elsif ($flds[1] eq 'net') {
                    if (!defined($flds[9])) {
                        # unexpected
                        print $sock "$lnno: flds[9] not def &gt;$_ &lt;<br>\n";
                    } else {
                        if ($flds[9] eq 'conn') {
                            if (defined($connections{"$flds[7],$flds[8],<-,$flds[5],$flds[6]"})) {
                                $connections{"$flds[7],$flds[8],<-,$flds[5],$flds[6]"}++;
                            } else {
                                $connections{"$flds[7],$flds[8],<-,$flds[5],$flds[6]"} = 1;
                            }
                            $activeconn{"$flds[7]:$flds[8]<=$flds[5]:$flds[6]"} = 1;
                        }
                        if ($flds[9] eq 'disc') {
                            $activeconn{"$flds[7]:$flds[8]<=$flds[5]:$flds[6]"} = 0;
                        }
                        if ($flds[9] eq 'alwaysESTAB') {
                            $alwayson{"$flds[7]:$flds[8]<=$flds[5]:$flds[6]"} = 0;
                        }
                    }
                }
                # time slot
                if (($now - $timestart) >= $timeslot) {
                    # end of time slot, print summary
                    $output .= "||$timestamp ||$slotrxtx ||". int($slotrxtx / ($now - $timestart)) ."||";
                    foreach $conn (sort keys %activeconn) {
                        if (defined($activeconn{$conn})) {
                            if ($activeconn{$conn} == 0) {
                                # connect has been closed. forget it.
                                $activeconn{$conn} = undef;
                            }
                            $conn =~ s/::ffff://g;
                            $output .= "$conn ";
                        }
                    }
                    $output .= "||\n";
                    $tablelen++;
                    $timestart = 0;
                }
                $nowlast = $now;
            }
        }
        # last (partial) time slot, print summary
        $output .= "||$timestamp ||$slotrxtx ||";
        if (($now - $timestart) == 0) {
            $output .= "$slotrxtx / 0 sec ||";
        } else {
            $output .= "||". int($slotrxtx / ($now - $timestart)) ."||";
        }
        foreach $conn (sort keys %activeconn) {
            if (defined($activeconn{$conn})) {
                if ($activeconn{$conn} == 0) {
                    # connect has been closed. forget it.
                    $activeconn{$conn} = undef;
                }
                $conn =~ s/::ffff://g;
                $output .= "$conn ";
            }
        }
        $output .= "||\n";
        $tablelen++;
        close (IN);

        $tmp = $rx;
        $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        print $sock "<p>rx = $tmp, ";
        $tmp = $tx;
        $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        print $sock "tx = $tmp, ";
        $tmp = $rxtx;
        $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        print $sock "rx+tx = $tmp<p>\n";

        print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
        print $sock "<a name=\"sum\"></a>\n";
        print $sock "<a href=\"#sum\">summary</a>,\n";
        print $sock "<a href=\"#graphs\">graphs</a>,\n";
        print $sock "<a href=\"#local\">local ip</a>,\n";
        print $sock "<a href=\"#remote\">remote ip</a>,\n";
        print $sock "<a href=\"#socket\">socket pairs</a><p>\n";

        print $sock "<form action=\"/rptnetifcon.htm\" method=\"get\">\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

        print $sock "    <tr>\n";
        print $sock "        <td><input type=\"submit\" name=\"settail\" value=\"Set\"></td>\n";
        print $sock "        <td>Display <input type=\"text\" size=\"4\" name=\"taillen\" value=\"$taillen\"> lines head and tail and skip rest</td>\n";
        print $sock "    </tr>\n";

        print $sock "</table>\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "</form><p>\n";

        # print always on socket pairs
        print $sock "<p>Socket pairs always connected:<pre>\n";
        foreach $_ (sort keys %alwayson) {
            s/::ffff://g;
            print $sock "$_\n";
            # and remove from output
            $output =~ s/$_//g;
        }
        print $sock "</pre>\n";

        print $sock "Poor man's whois look-up: <a href=\"/ls.htm?path=$ctrl->{'workdir'}rptnetifcon.cfg\">$ctrl->{'workdir'}rptnetifcon.cfg</a><br>\n";

#l00httpd::dbpclr();
        $tmp = &l00httpd::l00npoormanrdns($ctrl, $config{'desc'}, "$ctrl->{'workdir'}rptnetifcon.cfg");
        if ($tmp ne '') {
            print $sock "<pre>\n";
            print $sock "$tmp";
            print $sock "</pre>\n";
        }
        if (defined($ctrl->{'myip'})) {
            $_ = $ctrl->{'myip'};
            s/\./\\./g;
            $output =~ s/$_/me/g;
        }
        $tmp = &l00httpd::l00npoormanrdnshash($ctrl);
        foreach $_ (sort keys %$tmp) {
            l00httpd::dbp($config{'desc'}, "subst: $_ is $tmp->{$_}\n");
            $output =~ s/$_/$tmp->{$_}/g;
        }

        if (defined($ctrl->{'myip'})) {
            $_ = $ctrl->{'myip'};
            s/\./\\./g;
            s/\\\././g;
            print $sock "My IP is $_ (me)\n";
        }

        print $sock "<br>Total traffic by time slot (${timeslot}s):<p>\n";

        $buf = '';
        $tmp = 0;
        foreach $_ (split("\n", $output)) {
            $tmp++;
            if ($tmp < $taillen) {
                $buf .= "$_\n";
            } elsif ($tmp == $taillen) {
                $buf .= "$_\n";
                $buf .= "\nskipping ".($tablelen - $taillen * 2)." lines\n\n";
            } elsif ($tmp > ($tablelen - $taillen)) {
                $buf .= "$_\n";
            }
        }
        print $sock &l00wikihtml::wikihtml ($ctrl, "", $buf, 0);


        print $sock "<a name=\"graphs\"></a>\n";
        print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
        print $sock "<a href=\"#sum\">summary</a>,\n";
        print $sock "<a href=\"#graphs\">graphs</a>,\n";
        print $sock "<a href=\"#local\">local ip</a>,\n";
        print $sock "<a href=\"#remote\">remote ip</a>,\n";
        print $sock "<a href=\"#socket\">socket pairs</a>\n";
        if ($svgifdt ne '') {
            &l00svg::plotsvg ('ifconfigdt', $svgifdt, 500, 300);
            print $sock "<p>Log scale bytes/sec:<br><a href=\"/svg.htm?graph=ifconfigdt&view=\"><img src=\"/svg.htm?graph=ifconfigdt\" alt=\"logarithmic bytes/sec over time\"></a>\n";
        }
        if ($svgifdtlin ne '') {
            &l00svg::plotsvg ('ifconfigdtlin', $svgifdtlin, 500, 300);
            print $sock "<p>Linear scale bytes/sec:<br><a href=\"/svg.htm?graph=ifconfigdtlin&view=\"><img src=\"/svg.htm?graph=ifconfigdtlin\" alt=\"bytes/sec over time\"></a>\n";
        }
        if ($svgifdt ne '') {
            &l00svg::plotsvg ('ifconfigacc', $svgifacc, 500, 300);
            print $sock "<p>Cumulative bytes total:<br><a href=\"/svg.htm?graph=ifconfigacc&view=\"><img src=\"/svg.htm?graph=ifconfigacc\" alt=\"cumulative bytes over time\"></a>\n";
        }

        print $sock "<a name=\"local\"></a>\n";
        print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
        print $sock "<a href=\"#sum\">summary</a>,\n";
        print $sock "<a href=\"#graphs\">graphs</a>,\n";
        print $sock "<a href=\"#local\">local ip</a>,\n";
        print $sock "<a href=\"#remote\">remote ip</a>,\n";
        print $sock "<a href=\"#socket\">socket pairs</a>\n";
        print $sock "<p>List of all local ip:<br>\n<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
        undef %hosts;
        foreach $_ (sort keys %connections) {
            @flds = split(',', $_);
			if (defined($hosts{$flds[3]})) {
				$hosts{$flds[3]}++;
			} else {
				$hosts{$flds[3]} = 1;
			}
        }
		$tmp = 0;
        foreach $_ (sort keys %hosts) {
			$tmp++;
            print $sock "<tr><td>$tmp:</td><td>$_</td><td>$hosts{${_}}</td></tr>\n";
        }
        print $sock "</table>\n";

        print $sock "<a name=\"remote\"></a>\n";
        print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
        print $sock "<a href=\"#sum\">summary</a>,\n";
        print $sock "<a href=\"#graphs\">graphs</a>,\n";
        print $sock "<a href=\"#local\">local ip</a>,\n";
        print $sock "<a href=\"#remote\">remote ip</a>,\n";
        print $sock "<a href=\"#socket\">socket pairs</a>\n";
        print $sock "<p>List of all remote ip:<br>\n<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
        undef %hosts;
        foreach $_ (sort keys %connections) {
            @flds = split(',', $_);
			if (defined($hosts{$flds[0]})) {
				$hosts{$flds[0]}++;
			} else {
				$hosts{$flds[0]} = 1;
			}
        }
		$ii = 0;
        foreach $hostip (sort keys %hosts) {
			$ii++;
            $hostiporg = $hostip;
            $hostip =~ s/::ffff://;
            $tmp = &l00httpd::l00npoormanrdnshash($ctrl);
            foreach $_ (sort keys %$tmp) {
                $hostip =~ s/$_/$tmp->{$_}($hostip)/g;
            }
            print $sock "<tr><td>$ii:</td><td>$hostip</td><td>$hosts{${hostiporg}}</td></tr>\n";
        }
        print $sock "</table>\n";

        print $sock "<a name=\"socket\"></a>\n";
        print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
        print $sock "<a href=\"#sum\">summary</a>,\n";
        print $sock "<a href=\"#graphs\">graphs</a>,\n";
        print $sock "<a href=\"#local\">local ip</a>,\n";
        print $sock "<a href=\"#remote\">remote ip</a>,\n";
        print $sock "<a href=\"#socket\">socket pairs</a>\n";
        print $sock "<p>List of all socket pairs:<br>\n<pre>\n";
        $output = '';
        $tablelen = 0;
        foreach $_ (sort keys %connections) {
            $tablelen++;
            $output .= "$connections{${_}},$_\n";
        }
        $buf = '';
        $tmp = 0;
        foreach $_ (split("\n", $output)) {
            $tmp++;
            if ($tmp < $taillen) {
                $buf .= "$_\n";
            } elsif ($tmp == $taillen) {
                $buf .= "$_\n";
                $buf .= "\nskipping ".($tablelen - $taillen * 2)." lines\n\n";
            } elsif ($tmp > ($tablelen - $taillen)) {
                $buf .= "$_\n";
            }
        }
        print $sock $buf;
        print $sock "</pre>\n";
    }

    print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
    print $sock "<a href=\"#graphs\">graphs</a>,\n";
    print $sock "<a href=\"#local\">local ip</a>,\n";
    print $sock "<a href=\"#remote\">remote ip</a>,\n";
    print $sock "<a href=\"#socket\">socket pairs</a>\n";
    print $sock "<p><a name=\"end\">end</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
