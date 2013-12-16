
use strict;
use warnings;
use l00backup;

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
    my ($path, $fname, $tmp);
    my (@flds, $output);
    my ($rx, $tx, $rxtx, $now, $svgifdt, $svgifacc);
    my ($yr, $mo, $da, $hr, $mi, $se, $data, $timestamp);
    my ($lip, $lpt, $rip, $rpt, $conn, %connections, %hosts);
    my ($timestart, $slotrxtx, %activeconn, $lnno, %alwayson);


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
        print $sock "<a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }


    # get submitted name and print greeting
    if (open (IN, "<$form->{'path'}")) {
        $rx = 0;
        $tx = 0;
        $rxtx = 0;
        $svgifdt = '';
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
        $output .= "<td>sock pairs</td>\n";
        $output .= "</tr>\n";
        while (<IN>) {
            s/\r//;
            s/\n//;
            $lnno++;

            $timestamp = substr($_, 0, 15);
            if (($yr, $mo, $da, $hr, $mi, $se) = /^(\d\d\d\d)(\d\d)(\d\d) (\d\d)(\d\d)(\d\d),/) {
                #20131213 214805,net,tcp6,local,remote,::ffff:10.72.6.54,56079,::ffff:173.194.79.108,993,conn
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
                        $tmp = sprintf("%.2f", log($tmp) / log(10));
                        $svgifdt .= "$now,$tmp ";
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
            }
        }
        # last (partial) time slot, print summary
        $output .= "<tr>\n";
        $output .= "<td>$timestamp</td>\n";
        $output .= "<td>$slotrxtx</td>\n";
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
        print $sock "</pre>Total traffic by time slot (${timeslot}s):<p>\n";

        print $sock "$output<p>\n";


        if ($svgifdt ne '') {
            &l00svg::plotsvg ('ifconfigdt', $svgifdt, 500, 300);
            print $sock "<a href=\"/svg.pl?graph=ifconfigdt&view=\"><img src=\"/svg.pl?graph=ifconfigdt\" alt=\"alt\"></a>\n";
        }
        if ($svgifdt ne '') {
            &l00svg::plotsvg ('ifconfigacc', $svgifacc, 500, 300);
            print $sock "<a href=\"/svg.pl?graph=ifconfigacc&view=\"><img src=\"/svg.pl?graph=ifconfigacc\" alt=\"alt\"></a>\n";
        }

        print $sock "<a name=\"local\"></a>\n";
        print $sock "<hr><a href=\"#top\">Jump to top</a>,\n";
        print $sock "<a href=\"#sum\">summary</a>,\n";
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
    print $sock "<a href=\"#local\">local ip</a>,\n";
    print $sock "<a href=\"#remote\">remote ip</a>,\n";
    print $sock "<a href=\"#socket\">socket pairs</a>\n";
    print $sock "<p><a name=\"end\">end</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
