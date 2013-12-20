use strict;
use warnings;
use l00backup;
use l00httpd;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_rptnetifcon_proc",
              desc => "l00http_rptnetifcon_desc");
my ($buffer, $lastbuf, $timeslot);
$lastbuf = '';
$timeslot = 60 * 1;

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
    my ($path, $fname, $tmp, $patt, $name);
    my (@flds, $output, $leading, $st, $en, $trailing);
    my ($rx, $tx, $rxtx, $now, $nowlast, $svgifdt, $svgifdtlin, $svgifacc);
    my ($yr, $mo, $da, $hr, $mi, $se, $data, $timestamp);
    my ($lip, $lpt, $rip, $rpt, $conn, %connections, %hosts);
    my ($timestart, $slotrxtx, %activeconn, $lnno, %alwayson, %poorwhois);
    my ($fpath, $bytespers);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
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
        $output = '';
        $output .= "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
        $output .= "<tr>\n";
        $output .= "<td>timestamp</td>\n";
        $output .= "<td>bytes</td>\n";
        $output .= "<td>bytes/s</td>\n";
        $output .= "<td>sock pairs</td>\n";
        $output .= "</tr>\n";
        $nowlast = 0;
        $bytespers = 0;
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
                    $output .= "<tr>\n";
                    $output .= "<td>$timestamp</td>\n";
                    $output .= "<td>$slotrxtx</td>\n";
                    $output .= "<td>". int($slotrxtx / ($now - $timestart)) ."</td>\n";
                    $output .= "<td>\n";
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
                    $output .= "</td>\n";
                    $output .= "</tr>\n";
                    $timestart = 0;
                }
                $nowlast = $now;
            }
        }
        # last (partial) time slot, print summary
        $output .= "<tr>\n";
        $output .= "<td>$timestamp</td>\n";
        $output .= "<td>$slotrxtx</td>\n";
        if (($now - $timestart) == 0) {
            $output .= "<td>$slotrxtx / 0 sec</td>\n";
        } else {
            $output .= "<td>". int($slotrxtx / ($now - $timestart)) ."</td>\n";
        }
        $output .= "<td>\n";
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
        $output .= "</td>\n";
        $output .= "</tr>\n";
        $output .= "</table>\n";
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
        # print always on socket pairs
        print $sock "Socket pairs always connected:<pre>\n";
        foreach $_ (sort keys %alwayson) {
            s/::ffff://g;
            print $sock "$_\n";
            # and remove from output
            $output =~ s/$_//g;
        }
        print $sock "</pre>\n";

        print $sock "Poor man's whois look-up: <a href=\"/ls.htm?path=$ctrl->{'workdir'}rptnetifcon.cfg\">$ctrl->{'workdir'}rptnetifcon.cfg</a><br>\n";
        if (open(IN, "<$ctrl->{'workdir'}rptnetifcon.cfg")) {
            undef %poorwhois;
            print $sock "<pre>\n";
#l00httpd::dbpclr();
            while (<IN>) {
                if (/^#/) {
                    next;
                }
                s/\r//;
                s/\n//;
                if (($patt, $name) = /(.*)=>(.*)/) {
                    print $sock "$patt is $name\n";
                    l00httpd::dbp($config{'desc'}, "$patt is $name\n");
                    #46.51.248-254.*=>AMAZON_AWS
                    if (($leading, $st, $en, $trailing) = ($patt =~ /(.+?)\.(\d+)-(\d+)\.(.*)/)) {
                        l00httpd::dbp($config{'desc'}, "range: $patt ($st, $en) is $name\n");
                        for ($st..$en) {
                            $patt = "$leading.$_.$trailing";
                            l00httpd::dbp($config{'desc'}, "expanded: $patt is $name\n");
                            $patt =~ s/\./\\./g;
                            $patt =~ s/\*/\\d+/g;
                            $poorwhois{$patt} = $name;
                        }
                    } else {
                        l00httpd::dbp($config{'desc'}, "full octet: $patt is $name\n");
                        $patt =~ s/\./\\./g;
                        $patt =~ s/\*/\\d+/g;
                        $poorwhois{$patt} = $name;
                    }
                }
            }
            print $sock "</pre>\n";
            close(IN);
        }
        if (defined($ctrl->{'myip'})) {
            $_ = $ctrl->{'myip'};
            s/\./\\./g;
            $output =~ s/$_/me/g;
        }
        foreach $_ (sort keys %poorwhois) {
            l00httpd::dbp($config{'desc'}, "subst: $_ is $poorwhois{$_}\n");
            $output =~ s/$_/$poorwhois{$_}/g;
        }

        if (defined($ctrl->{'myip'})) {
            $_ = $ctrl->{'myip'};
            s/\./\\./g;
            print $sock "My IP is $_ (me)\n";
        }

        print $sock "<br>Total traffic by time slot (${timeslot}s):<p>\n";
        print $sock "$output<p>\n";


        print $sock "<a name=\"graphs\"></a>\n";
        if ($svgifdt ne '') {
            &l00svg::plotsvg ('ifconfigdt', $svgifdt, 500, 300);
            print $sock "<a href=\"/svg.htm?graph=ifconfigdt&view=\"><img src=\"/svg.htm?graph=ifconfigdt\" alt=\"logarithmic bytes/sec over time\"></a>\n";
        }
        if ($svgifdtlin ne '') {
            &l00svg::plotsvg ('ifconfigdtlin', $svgifdtlin, 500, 300);
            print $sock "<a href=\"/svg.htm?graph=ifconfigdtlin&view=\"><img src=\"/svg.htm?graph=ifconfigdtlin\" alt=\"bytes/sec over time\"></a>\n";
        }
        if ($svgifdt ne '') {
            &l00svg::plotsvg ('ifconfigacc', $svgifacc, 500, 300);
            print $sock "<a href=\"/svg.htm?graph=ifconfigacc&view=\"><img src=\"/svg.htm?graph=ifconfigacc\" alt=\"cumulative bytes over time\"></a>\n";
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
		$tmp = 0;
        foreach $_ (sort keys %hosts) {
			$tmp++;
            print $sock "<tr><td>$tmp:</td><td>$_</td><td>$hosts{${_}}</td></tr>\n";
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
        foreach $_ (sort keys %connections) {
            print $sock "$connections{${_}},$_\n";
        }
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
