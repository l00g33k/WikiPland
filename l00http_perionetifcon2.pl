use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_perionetifcon2_proc",
              desc => "l00http_perionetifcon2_desc",
              perio => "l00http_perionetifcon2_perio");
my ($lastcalled, $interval, $cnt, $history);
my (%iftx0, %iftx1, %ifrx0, %ifrx1);
$interval = 0, 
$lastcalled = 0;
$cnt = 0;
$history = '';


sub l00http_perionetifcon2_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    $ctrl->{'l00file'}->{'l00://perionetifcon2.txt'} = '';

    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: perionetifcon2: Periodic logging of netstat";
}


sub l00http_perionetifcon2_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, $key, $val, $poorwhois);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"clear"})) {
        undef %iftx0;
        undef %iftx1;
        undef %ifrx0;
        undef %ifrx1;
        $history = '';
        $cnt = 0;
        $ctrl->{'l00file'}->{'l00://perionetifcon2.txt'} = '';
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'};
    if (defined ($form->{"refresh"})) {
        print $sock "<meta http-equiv=\"refresh\" content=\"2\"> ";
    }
    print $sock $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">HOME</a> <a href=\"/perionetifcon2.htm\">Reload</a><br>\n";

    print $sock "<form action=\"/perionetifcon2.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec, e.g. 2):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Set\"> \n";
    print $sock "         <input type=\"submit\" name=\"refresh\" value=\"Refresh\">\n";
    print $sock "         <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"clear\" value=\"Clr\"> ";
    print $sock "            <input type=\"submit\" name=\"mark\" value=\"Mk\"> </td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "View: <a href=\"/view.htm?path=l00://perionetifcon2.txt\" target=\"_blank\">l00://perionetifcon2.txt</a><br>\n";

    $cnt++;
    $buf = "$cnt ($ctrl->{'now_string'}) Rx/Tx:\n";
    foreach $_ (sort keys %ifrx0) {
        $buf .= sprintf ("%6.3fM/%6.3fM %8d/%8d %-12s\n", 
                    ($ifrx1{$_} - $ifrx0{$_}) / 1000000,
                    ($iftx1{$_} - $iftx0{$_}) / 1000000,
                    $ifrx1{$_} - $ifrx0{$_},
                    $iftx1{$_} - $iftx0{$_},
                    $_);
    }
    printf $sock "\n";

    if (defined ($form->{"mark"})) {
        $history = "$buf$history";
        $ctrl->{'l00file'}->{'l00://perionetifcon2.txt'} .= $buf;
        foreach $_ (sort keys %ifrx0) {
            $ifrx0{$_} = $ifrx1{$_};
            $iftx0{$_} = $iftx1{$_};
        }
    }
    printf $sock "<pre>$buf\n$history</pre>\n";

    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_perionetifcon2_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe, $proto, $RxQ, $TxQ, $local, $remote, $sta, $key);
    my ($thisif, $rxb, $txb, $if, $vals, @val, $total, $ifoutput, $retval);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;
        $retval = $interval;

        if (($ctrl->{'os'} eq 'and') ||
            ($ctrl->{'os'} eq 'lin') ||
            ($ctrl->{'os'} eq 'tmx')) {
            $tempe = "TIME,$lastcalled,$ctrl->{'now_string'}\n";
            # netstat
#netstat
#Proto Recv-Q Send-Q Local Address          Foreign Address        State
# tcp       0      0 127.0.0.1:55555        0.0.0.0:*              LISTEN
# tcp       0      0 0.0.0.0:20337          0.0.0.0:*              LISTEN
# tcp       0      0 10.10.10.18:46869      64.4.61.208:443        ESTABLISHED
# tcp       0      0 127.0.0.1:53033        127.0.0.1:53171        ESTABLISHED
#tcp6       0      0 :::20339               :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:8182  :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:53171 ::ffff:127.0.0.1:53033 ESTABLISHED
#            $buf = `netstat`;
if(0){
            foreach $_ (split ("\n", `netstat`)) {
                if (/UNIX domain sockets/) {
                    # Active UNIX domain sockets (w/o servers)
                    # ignore UNIX sockets
                    last;
                }
                if (/Active Internet/ || /Proto /) {
                    # ignore header
                    next;
                }
                if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = split (' ', $_)) {
                    if (!(($local =~ /^localhost:/) &&
                         ($remote =~ /^localhost:/)) && 
                        !(($local =~ /127\.0\.0\.\d+:/) &&
                         ($remote =~ /127\.0\.0\.\d+:/))) {
                        $tempe .= "netstat,$proto, $RxQ, $TxQ, $local, $remote, $sta\n";
                    }
                } else {
                    $tempe .= "netstat,can't split: $_\n";
                }
            }
}

            # ifconfig
            $thisif = '';
            if (open (IN, "</proc/net/dev")) {
#Inter-|   Receive                                                |  Transmit
#    if        0       1    2    3    4     5          6         7        8       9   10   11   12    13      14         15
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#    lo:51918626  105904    0    0    0     0          0         0 51918626  105904    0    0    0     0       0          0
#dummy0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet0:  983996     826    0    0    0     0          0         0    54607     563    0    0    0     0       0          0
#rmnet1:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet2:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet3:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet4:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet5:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet6:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet7:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  usb0:  762160    2508    0    0    0     0          0         0   752385    1835    0    0    0     0       0          0
#  sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#ip6tnl0:      0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#gannet0:      0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#   tun:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  eth0:32919217  366817    0    0    0     0          0         0 49776541  544949    0    0    0     0       0          0

                while (<IN>) {
                    if (($if, $vals) = /^ *(\w+): *(.+)$/) {
                        if ($if eq 'lo') {
                            next;
                        }
                        @val = split (' ', $vals);
                        if (($val[0] > 0) && ($val[8] > 0)) {
                            $tempe .=
                               sprintf("net,%s: %.0f,%.0f,%.0f,%.0f\n", 
                                   $if, $val[0], $val[1], $val[8], $val[9]);
                            if (!defined($ifrx0{$if})) {
                                $ifrx0{$if} = $val[0];
                            }
                            if (!defined($iftx0{$if})) {
                                $iftx0{$if} = $val[8];
                            }
                            $ifrx1{$if} = $val[0];
                            $iftx1{$if} = $val[8];
                        }
                    }
                }
                close (IN);
            }
            $ctrl->{'l00file'}->{'l00://perionetifcon2.txt'} .= $tempe;
        }
    } elsif ($interval > 0) {
        # remaining time to firing
        $retval = ($lastcalled + $interval) - time;
    } else {
        $retval = 0x7fffffff;
    }

    $retval;
}


\%config;
